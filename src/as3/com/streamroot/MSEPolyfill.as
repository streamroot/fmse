package com.streamroot {

import com.streamroot.buffer.Segment;
import com.streamroot.buffer.StreamBuffer;
import com.streamroot.util.TrackTypeHelper;

import flash.events.Event;
import flash.external.ExternalInterface;
import flash.net.NetStreamAppendBytesAction;
import flash.system.MessageChannel;
import flash.system.Worker;
import flash.system.WorkerDomain;
import flash.utils.ByteArray;
import flash.utils.getQualifiedClassName;
import flash.utils.setTimeout;

public class MSEPolyfill {

    private static const TIMEOUT_LENGTH:uint = 5;

    [Embed(source="transcoder/TranscodeWorker.swf", mimeType="application/octet-stream")]
    private static var WORKER_SWF:Class;

    private var _netStreamWrapper:NetStreamWrapper;
    private var _streamBuffer:StreamBuffer;
    private var _jsReady:Boolean = false;
    private var _loaded:Boolean = false;

    private var _seek_offset:Number = 0;
    private var _ended:Boolean = false;

    private var _lastWidth:Number = 0;
    private var _lastHeight:Number = 0;
    private var _lastDuration:Number = 0;

    private var _worker:Worker;

    private var _mainToWorker:MessageChannel;
    private var _workerToMain:MessageChannel;
    private var _commChannel:MessageChannel;

    private var _isWorkerReady:Boolean = false;

    private var _isWorkerBusy:Boolean = false;
    private var _pendingAppend:Object;
    private var _discardAppend:Boolean = false; //Used to discard data from worker in case we were seeking during transcoding

    public function MSEPolyfill(netStreamWrapper:NetStreamWrapper) {
        _netStreamWrapper = netStreamWrapper;

        //StreamrootMSE callbacks
        ExternalInterface.addCallback("addSourceBuffer", addSourceBuffer);
        ExternalInterface.addCallback("appendBuffer", appendBuffer);
        //ExternalInterface.addCallback("buffered", buffered);

        //StreamBuffer callbacks
        ExternalInterface.addCallback("remove", remove);

        ExternalInterface.addCallback("jsReady", jsReady);

        //StreamrootInterface callbacks
        //METHODS
        ExternalInterface.addCallback("onMetaData", onMetaData);
        ExternalInterface.addCallback("play", play);
        ExternalInterface.addCallback("pause", pause);
        ExternalInterface.addCallback("seek", seek);
        ExternalInterface.addCallback("bufferEmpty", bufferEmpty);
        //GETTERS
        ExternalInterface.addCallback("currentTime", currentTime);
        ExternalInterface.addCallback("paused", paused);
        ExternalInterface.addCallback("readyState", readyState);

        _streamBuffer = new StreamBuffer(this);

        setupWorker();
    }

    private function setupWorker():void {
        var workerBytes:ByteArray = new WORKER_SWF() as ByteArray;
        _worker = WorkerDomain.current.createWorker(workerBytes);

        // Send to worker
        _mainToWorker = Worker.current.createMessageChannel(_worker);
        _worker.setSharedProperty("mainToWorker", _mainToWorker);

        // Receive from worker
        _workerToMain = _worker.createMessageChannel(Worker.current);
        _workerToMain.addEventListener(Event.CHANNEL_MESSAGE, onWorkerToMain);
        _worker.setSharedProperty("workerToMain", _workerToMain);

        // Receive startup message from worker
        _commChannel = _worker.createMessageChannel(Worker.current);
        _commChannel.addEventListener(Event.CHANNEL_MESSAGE, onCommChannel);
        _worker.setSharedProperty("commChannel", _commChannel);

        _worker.start();
    }

    private function setSeekOffset(timeSeek:Number):void {
        debug("Set seek offset", this);
        _seek_offset = timeSeek;

        if (_pendingAppend) {
            //remove pending append job to avoid appending it after seek
            debug("Discarding _pendingAppend " + _pendingAppend.type, this);
            sendSegmentFlushedMessage(_pendingAppend.type);
            _pendingAppend = null;
        }

        //If worker is appending a segment during seek, discard it as we don't want to append it
        if (_isWorkerBusy) {
            debug("Setting discard to true", this);
            _discardAppend = true
        }
        _streamBuffer.onSeek();
        _mainToWorker.send('seeking');
    }

    private function addSourceBuffer(type:String):void {
        var key:String = TrackTypeHelper.getType(type);
        if (key) {
            _streamBuffer.addSourceBuffer(key);
        } else {
            error("Error: Type not supported: " + type);
        }
    }

    //timestampStart and timestampEnd in second
    private function appendBuffer(data:String, type:String, isInit:Boolean, startTime:Number = 0, endTime:Number = 0):void {
        debug("AppendBuffer", this);
        var message:Object = {data: data, type: type, isInit: isInit, startTime: startTime, endTime: endTime, offset: _seek_offset};// - offset + 100};
        appendOrQueue(message);
    }

    private function appendOrQueue(message:Object):void {
        if (!_isWorkerBusy) {
            _isWorkerBusy = true;
            setTimeout(sendWorkerMessage, TIMEOUT_LENGTH, message);
            //_mainToWorker.send(message);
        } else if (!_pendingAppend) {
            _pendingAppend = message; //TODO: clear this job when we seek
        } else {
            error("Error: not supporting more than one pending job for now", this);
            sendSegmentFlushedMessage(message.type);
        }
    }

    private function sendWorkerMessage():void {
        _mainToWorker.send(arguments[0]);
    }

    public function getFileHeader():ByteArray {
        var output:ByteArray = new ByteArray();
        output.writeByte(0x46); // 'F'
        output.writeByte(0x4c); // 'L'
        output.writeByte(0x56); // 'V'
        output.writeByte(0x01); // version 0x01

        var flags:uint = 0;

        flags |= 0x01;

        output.writeByte(flags);

        var offsetToWrite:uint = 9; // minimum file header byte count

        output.writeUnsignedInt(offsetToWrite);

        var previousTagSize0:uint = 0;

        output.writeUnsignedInt(previousTagSize0);

        return output;
    }

    private function onWorkerToMain(event:Event):void {
        var message:* = _workerToMain.receive();

        var type:String = message.type;
        var isInit:Boolean = message.isInit;
        var width:Number = message.width;
        var height:Number = message.height;

        var segment:Segment = new Segment(message.segmentBytes, message.type, message.startTime, message.endTime);

        _isWorkerBusy = false;

        if (!_discardAppend) {

            if (!isInit) {
                debug("Appending segment in StreamBuffer", this);
                if (_lastHeight === 0 && width > 0 && height > 0) {
                    debug("setting video size: " + width + " - " + height);
                    onMetaData(0, width, height);
                }

                _streamBuffer.appendSegment(segment, TrackTypeHelper.getType(segment.type));
            }

            if (_pendingAppend) {
                debug("Unqueing", this);
                appendOrQueue(_pendingAppend);
                _pendingAppend = null;
            }

            if (TrackTypeHelper.isAudio(type)) {
                setTimeout(updateendAudio, TIMEOUT_LENGTH);
            } else if (TrackTypeHelper.isVideo(type)) {
                setTimeout(updateendVideo, TIMEOUT_LENGTH);
            } else {
                error("no type matching");
            }
        } else {
            sendSegmentFlushedMessage(type);
            _discardAppend = false;
        }
    }

    private function sendSegmentFlushedMessage(type:String):void {
        debug("Discarding segment    " + type, this);

        if (TrackTypeHelper.isAudio(type)) {
            setTimeout(updateendAudio, TIMEOUT_LENGTH, true);
        } else if (TrackTypeHelper.isVideo(type)) {
            setTimeout(updateendVideo, TIMEOUT_LENGTH, true);
        }
    }

    private function updateendAudio(error:Boolean = false):void {
        ExternalInterface.call("sr_flash_updateend_audio", error);
    }

    private function updateendVideo(error:Boolean = false):void {
        ExternalInterface.call("sr_flash_updateend_video", error);
    }

    private function onCommChannel(event:Event):void {
        var message:* = _commChannel.receive();
        _isWorkerReady = true;

        if (message.command == "debug") {
            debug(message.message, this);
        } else if (message.command == "error") {
            transcodeError(message.message);
            flush(message);
        }
    }

    private function jsReady():void {
        _jsReady = true;
    }

    //StreamBuffer function
    public function appendNetStream(bytes:ByteArray):void {
        _netStreamWrapper.appendBuffer(bytes);
    }

    public function remove(start:Number, end:Number, type:String):Number {
        return _streamBuffer.removeDataFromSourceBuffer(start, end, TrackTypeHelper.getType(type));
    }

    public function getBufferLength():Number {
        return _netStreamWrapper.getBufferLength();
    }

    //StreamrootInterface function
    private function onMetaData(duration:Number, width:Number = 0, height:Number = 0):void {
        if (_lastDuration === 0) {
            if (duration > 0) {
                _lastDuration = duration;
                _streamBuffer.setDuration(duration);
            }
        } else if (duration === 0) {
            duration = _lastDuration;
        }
        if (_lastHeight === 0) {
            _lastWidth = width;
            _lastHeight = height;
            _netStreamWrapper.onMetaData(duration, width, height);
        }
    }

    private function play():void {
        _netStreamWrapper.play();
    }

    private function pause():void {
        _netStreamWrapper.pause();
    }

    private function seek(time:Number):void {
        setSeekOffset(time);
        _netStreamWrapper.seekBySeconds(time);
    }

    public function currentTime():Number {
        return _netStreamWrapper.time;
    }

    private function paused():Boolean {
        return _netStreamWrapper.paused;
    }

    private function readyState():Number {
        return _netStreamWrapper.readyState;
    }

    public function bufferEmpty():void {
        _netStreamWrapper.onBufferEmpty(true);
        triggerWaiting();
    }

    public function bufferFull():void {
        _netStreamWrapper.onBuffersReady();
        triggerPlaying();
    }

    public function loaded():void {
        //append the FLV Header to the provider, using appendBytesAction
        _netStreamWrapper.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
        _netStreamWrapper.appendBuffer(getFileHeader());

        if (!_loaded) {
            _loaded = true;
        }

        //Tell our Javascript library to start loading video segments
        triggerLoadStart();
    }

    //StreamrootInterface events
    public function triggerSeeked():void {
        //Trigger event when seek is done
        ExternalInterface.call("sr_flash_seeked");
    }

    public function triggerLoadStart():void {
        //Trigger event when we want to start loading data (at the beginning of the video or on replay)
        if (_jsReady) {
            ExternalInterface.call("sr_flash_loadstart");
        } else {
            setTimeout(triggerLoadStart, 10);
        }
    }

    public function triggerPlay():void {
        _ended = false;

        if (_jsReady) {
            //Trigger event when video starts playing.
            ExternalInterface.call("sr_flash_play");
            if (_streamBuffer.isBufferReady()) {
                triggerPlaying();
            }
            //_firstPlayEventSent = true;
        } else {
            setTimeout(triggerPlay, 10);
        }
    }

    public function triggerPause():void {
        //Trigger event when video starts playing. Not used for now
        if (_jsReady) {
            ExternalInterface.call("sr_flash_pause");
        } else {
            setTimeout(triggerPause, 10);
        }
    }

    public function triggerPlaying():void {
        _ended = false;

        //Trigger event when media is playing
        if (_jsReady) {
            ExternalInterface.call("sr_flash_playing");
        } else {
            setTimeout(triggerPlaying, 10);
        }
    }

    public function triggerWaiting():void {
        //Trigger event when video has been paused but is expected to resume (ie on buffering or manual paused)
        if (_jsReady) {
            ExternalInterface.call("sr_flash_waiting");
        } else {
            setTimeout(triggerWaiting, 10);
        }
    }

    public function triggerStopped():void {
        //Trigger event when video ends.
        if (!_ended) {
            _netStreamWrapper.onStop();
            ExternalInterface.call("sr_flash_stopped");
            _ended = true;
        }
    }

    public function triggerCanplay():void {
        //trigger event xhen there is enough stat in buffer to play
        ExternalInterface.call("sr_flash_canplay");
    }

    public function triggerDurationChange(duration:Number):void {
        //trigger event xhen there is enough stat in buffer to play
        ExternalInterface.call("sr_flash_durationChange", duration);
    }

    public function triggerVolumeChange(volume:Number):void {
        //trigger event when there is enough stat in buffer to play
        ExternalInterface.call("sr_flash_volumeChange", volume);
    }

    public function appendedSegment(startTime:Number, endTime:Number):void {
        //trigger event when there is enough stat in buffer to play
        ExternalInterface.call("sr_flash_appended_segment", startTime, endTime);
    }

    public function error(message:Object, obj:Object = null):void {
        if (_jsReady && CONFIG::LOG_ERROR) {
            if (obj != null) {
                var textMessage:String = getQualifiedClassName(obj) + ".as : " + String(message);
                ExternalInterface.call("console.error", textMessage);
            } else {
                ExternalInterface.call("console.error", String(message));
            }
        } else {
            setTimeout(error, 10, message, obj);
        }
    }

    public function transcodeError(message:Object):void {
        if (_jsReady && CONFIG::LOG_ERROR) {
            ExternalInterface.call("sr_flash_transcodeError", String(message));
        } else {
            setTimeout(transcodeError, 10, message);
        }
    }

    public function debug(message:Object, obj:Object = null):void {

        if (_jsReady && CONFIG::LOG_DEBUG) {
            if (obj != null) {
                var textMessage:String = getQualifiedClassName(obj) + ".as : " + String(message);
                ExternalInterface.call("console.debug", textMessage);
            } else {
                ExternalInterface.call("console.debug", String(message));
            }
        } else {
            setTimeout(debug, 10, message, obj);
        }
    }

    public function flush(message:Object):void {
        if (message.type) {
            //If worker sent back an attribute "type", we want to set _isWorkerBusy to false and trigger
            //a segment flushed message to notify the JS that append didn't work well, in order not to
            //block the append pipeline
            _isWorkerBusy = false;
            debug("Error type: " + message.type, this);
            sendSegmentFlushedMessage(message.type);
        }
    }
}
}
