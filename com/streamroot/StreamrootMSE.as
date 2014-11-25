package com.streamroot {

import flash.external.ExternalInterface;
import flash.net.NetStream;
import flash.net.NetStreamAppendBytesAction;

import flash.events.TimerEvent;
import flash.utils.Timer;
import flash.events.Event;

import flash.system.Worker;
import flash.system.WorkerDomain;
import flash.system.MessageChannel;
import flash.system.WorkerState;

import com.dash.handlers.InitializationAudioSegmentHandler;
import com.dash.handlers.InitializationVideoSegmentHandler;
import com.dash.handlers.VideoSegmentHandler;
import com.dash.handlers.AudioSegmentHandler;

import com.dash.boxes.Muxer;

import com.dash.utils.Base64;
import flash.utils.ByteArray;
import flash.utils.setTimeout;
import flash.utils.Dictionary;

import com.streamroot.StreamrootInterfaceBase;

import com.streamroot.Transcoder;

public class StreamrootMSE {

    private var _streamrootInterface;

    private var _muxer:Muxer;

    private var _initHandlerAudio:InitializationAudioSegmentHandler;
    private var _initHandlerVideo:InitializationVideoSegmentHandler;

    private var _seek_offset:Number = 0;
    private var _audio_offset:Number = 0;

    private var _buffered:uint = 0;
    private var _buffered_audio:uint = 0;

    private var _hasData:Dictionary = new Dictionary();
    private static const VIDEO:String = "video";
    private static const AUDIO:String = "audio";

    private var _pendingOffsetVideo:Number;
    private var _pendingOffsetAudio:Number;

    private var _pendingTimestampVideo:Number;
    private var _pendingTimestampAudio:Number;

    private var _pendingIsInitVideo:Boolean;
    private var _pendingIsInitAudio:Boolean;

    private var _pendingDataVideo:String = "";
    private var _pendingDataAudio:String = "";

    private var _readPositionVideo:uint;
    private var _readPositionAudio:uint;

    private var _decodedDataVideo:ByteArray = new ByteArray();
    private var _decodedDataAudio:ByteArray = new ByteArray();

    private var _decodedCompleteVideo : Boolean = false;
    private var _decodedCompleteAudio : Boolean = false;

    private static const TIMER_IDLE : String = "Idle";
    private static const TIMER_REQUESTING : String = "Requesting";
    private static const TIMER_ACTIVE : String = "Active";

    private var _timerVideo:Timer;
    private var _timerAudio:Timer;

    private var _timerStateVideo:String = TIMER_IDLE;
    private var _timerStateAudio:String = TIMER_IDLE;

    private static const DECODE_CHUNK_SIZE : uint = 64 * 1024;
    private static const DECODE_INTERVAL : uint = 0;


    [Embed(source="TranscodeWorker.swf", mimeType="application/octet-stream")]
    private static var WORKER_SWF:Class;

    private var _worker:Worker;

    private var _mainToWorker:MessageChannel;
    private var _workerToMain:MessageChannel;
    private var _debugChannel:MessageChannel;

    private var _isWorkerReady:Boolean = false;

    private var _isWorkerBusy:Boolean = false;
    private var _pendingAppend:Object;
    private var _discardAppend:Boolean = false; //Used to discard data from worker in case we were seeking during transcoding





    public function StreamrootMSE(streamrootInterface:StreamrootInterfaceBase) {
        _streamrootInterface = streamrootInterface;

        _muxer = new Muxer();

        ExternalInterface.addCallback("addSourceBuffer", addSourceBuffer);
        ExternalInterface.addCallback("appendBuffer", appendBuffer);
        ExternalInterface.addCallback("buffered", buffered);

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
        _debugChannel = _worker.createMessageChannel(Worker.current);
        _debugChannel.addEventListener(Event.CHANNEL_MESSAGE, onDebugChannel);
        _worker.setSharedProperty("debugChannel", _debugChannel);

        _worker.start();
    }

    public function setSeekOffset(timeSeek:Number):void {
        _streamrootInterface.debug("FLASH: set seek offset");
        _seek_offset = timeSeek;

        _buffered = timeSeek*1000000;
        _buffered_audio = timeSeek*1000000;

        setHasData(false);

        if (_pendingAppend) {
            //remove pending append job to avoid appending it after seek
            _streamrootInterface.debug("FLASH: discarding _pendingAppend " + _pendingAppend.type);
            sendSegmentFlushedMessage(_pendingAppend.type);
            _pendingAppend = undefined;
        }

        //If worker is appending a segment during seek, discard it as we don't want to append it
        if (_isWorkerBusy) {
            _streamrootInterface.debug("FLASH: setting discard to true");
            _discardAppend = true
        }

        _mainToWorker.send('seeking');
    }

    private function addSourceBuffer(type:String):void {

        //TODO: this _hasData should live in a different class, and we would just have to pass the type everytime
        var key:String;
        if (type.indexOf("apple") >=0) {
            key = VIDEO;
        }else if (type.indexOf("audio") >= 0) {
            key = AUDIO;
        } else if (type.indexOf("video") >= 0) {
            key = VIDEO;
        } else {
            _streamrootInterface.error("Error: Type not supported: " + type);
        }

        if (key) {
            if (!_hasData.hasOwnProperty(key)) {
                _streamrootInterface.debug("FLASH: daaing sourceBuffer " + type);
                _hasData[key] = false;
            } else {
                _streamrootInterface.error("Error: source buffer with this type already exists: " + type);
            }
        }
    }

    private function setHasData(value:Boolean, key:String = null):void {
        if (key) {
            _streamrootInterface.debug("FLASH: setHasData: " + key + " - " + String(value));
            _hasData[key] = value;
        } else {
            //If no key specified, set all entries in _hasData to value
            for (var k in _hasData) {
                _streamrootInterface.debug("FLASH: setHasData: " + k + " - " + String(value));
                _hasData[k] = value;
            }
        }
    }

    private function appendBuffer(data:String, type:String, isInit:Boolean, timestamp:Number = 0, buffered:uint = 0 ):void {
        _streamrootInterface.debug("FLASH: appendBuffer");
        var offset :Number = _seek_offset * 1000;
        var message:Object = {data: data, type: type, isInit: isInit, timestamp: timestamp, offset: offset};// - offset + 100};

        appendOrQueue(message);


        /*
        if (isInit) {
            _transcoder.transcodeInit(data, type);
            //Check better way to check type here as well
            if (type.indexOf("audio") >= 0) {
                ExternalInterface.call("sr_flash_updateend_audio");
            } else if (type.indexOf("video") >= 0) {
                ExternalInterface.call("sr_flash_updateend_video");
            } else {
                _streamrootInterface.error("no type matching");
            }
        } else {

            var offset = _seek_offset * 1000;

            var segmentBytes = _transcoder.transcode(data, type, timestamp - offset);

            _streamrootInterface.appendBuffer(segmentBytes)


            //Check better way to check type here as well
            if (type.indexOf("audio") >= 0) {
                _hasAudio = true;
                ExternalInterface.call("sr_flash_updateend_audio");
            } else if (type.indexOf("video") >= 0) {
                _hasVideo = true;
                ExternalInterface.call("sr_flash_updateend_video");
            } else {
                _streamrootInterface.error("no type matching");
            }
        }
        */

        /*
        var timestamp:Number = 0;
        var buffered:uint = 0;
        if (!isInit) {
            timestamp = Number(args[3]);
            buffered = int(args[4]);
        }
        asyncAppend(data, type, isInit, timestamp, buffered);
        */
    }

    private function appendOrQueue(message:Object):void {
        if (!_isWorkerBusy) {
            _isWorkerBusy = true;
            setTimeout(sendWorkerMessage, 100, message);
            //_mainToWorker.send(message);
        } else if (!_pendingAppend) {
            _pendingAppend = message; //TODO: clear this job when we seek
        } else {
            _streamrootInterface.error("error: not supporting more than one pending job for now");
            sendSegmentFlushedMessage(message.type);
        }
    }

    private function sendWorkerMessage():void {
        _mainToWorker.send(arguments[0]);
    }

    private function asyncAppend(data:String, type:String, isInit:Boolean, timestamp:Number = 0, buffered:uint = 0):void {
        //var bytes_event:ByteArray = Base64.decode(data);

        _streamrootInterface.debug("ASYNC APPEND");

        var offset :Number = _seek_offset * 1000;

        if (type.indexOf("audio") >= 0){
            _pendingOffsetAudio = offset;
            _pendingIsInitAudio = isInit;
            _pendingDataAudio = data;

            if (!isInit) {
                _pendingTimestampAudio = timestamp;
                _buffered_audio = buffered; //TODO: should remove buffered from flash
            }

            //_pendingDataAudio = "";
            //_decodedDataAudio = new ByteArray();
            //_readPositionAudio = 0;

            if (_timerStateVideo !== TIMER_ACTIVE) {
                startTimerAudio();
            } else {
                _timerStateAudio = TIMER_REQUESTING;
            }

        } else if (type.indexOf("video") >= 0) {
            _pendingOffsetVideo = offset;
            _pendingIsInitVideo = isInit;
            _pendingDataVideo = data;

            if (!isInit) {
                _pendingTimestampVideo = timestamp;
                _buffered = buffered; //TODO: should remove buffered from flash
            }

            //_pendingDataVideo = "";
            //_decodedDataVideo = new ByteArray();
            //_readPositionVideo = 0;
            if (_timerStateAudio !== TIMER_ACTIVE) {
                startTimerVideo();
            } else {
                _timerStateVideo = TIMER_REQUESTING;
            }
        }
    }

    private function startTimerAudio():void {
        _timerStateAudio = TIMER_ACTIVE;
        _timerAudio = new Timer (DECODE_INTERVAL, 0);
        _timerAudio.addEventListener(TimerEvent.TIMER, decodeAudio);
        _timerAudio.start();
    }

    private function startTimerVideo():void {
        _timerStateVideo = TIMER_ACTIVE;
        _timerVideo = new Timer (DECODE_INTERVAL, 0);
        _timerVideo.addEventListener(TimerEvent.TIMER, decodeVideo);
        _timerVideo.start();
    }

    private function decodeAudio(e : Event):void {
        if (_decodedCompleteAudio) {
            _timerAudio.stop();

            appendAudio(_decodedDataAudio);

            _pendingDataAudio = "";
            _decodedDataAudio = new ByteArray();
            //_decodedDataAudio.position = 0;
            _readPositionAudio = 0;
            _decodedCompleteAudio = false
        } else {
            var beginTS:Number = new Date().valueOf();

            var startPos : uint = _readPositionAudio;
            var endPos : uint;

            if (_pendingDataAudio.length <= startPos + DECODE_CHUNK_SIZE) {
                endPos = _pendingDataAudio.length;
                _decodedCompleteAudio = true;
            } else {
                endPos = startPos + DECODE_CHUNK_SIZE;
            }
            var tmpString : String = _pendingDataAudio.substring(startPos, endPos);
            _decodedDataAudio.writeBytes(Base64.decode(tmpString));

            _readPositionAudio = endPos;

            var decodedTS:Number = new Date().valueOf();
            var decoded:Number = decodedTS - beginTS;
            _streamrootInterface.debug('DECODED (ms): ' + decoded);
        }
    }

    private function decodeVideo(e : Event):void {
        if (_decodedCompleteVideo) {
            _timerVideo.stop();

            appendVideo(_decodedDataVideo);

            _pendingDataVideo = "";
            _decodedDataVideo = new ByteArray();
            _readPositionVideo = 0;
            _decodedCompleteVideo = false;
        } else {
            var beginTS:Number = new Date().valueOf();

            var startPos : uint = _readPositionVideo;
            var endPos : uint;

            if (_pendingDataVideo.length <= startPos + DECODE_CHUNK_SIZE) {
                endPos = _pendingDataVideo.length;
                _decodedCompleteVideo = true;
            } else {
                endPos = startPos + DECODE_CHUNK_SIZE;
            }
            var tmpString : String = _pendingDataVideo.substring(startPos, endPos);
            _decodedDataVideo.writeBytes(Base64.decode(tmpString));

            _readPositionVideo = endPos;


            var decodedTS :Number = new Date().valueOf();
            var decoded :Number = decodedTS - beginTS;
            _streamrootInterface.debug('DECODED (ms): ' + decoded);
        }
    }

    private function appendAudio(bytes_event:ByteArray):void {
        if(_pendingIsInitAudio==true){
            _initHandlerAudio = new InitializationAudioSegmentHandler(bytes_event);
        } else {
            var decodedTS :Number = new Date().valueOf();

            var bytes_append_audio:ByteArray = new ByteArray();
            var audioSegmentHandler = new AudioSegmentHandler(bytes_event, _initHandlerAudio.messages, _initHandlerAudio.defaultSampleDuration, _initHandlerAudio.timescale, _pendingTimestampAudio - _pendingOffsetAudio, _muxer);
            bytes_append_audio.writeBytes(audioSegmentHandler.bytes);

            if (_isWorkerReady){
                _mainToWorker.send(true)
            }


            var transcodedTS:Number = new Date().valueOf();
            var transcoded:Number = transcodedTS - decodedTS;
            _streamrootInterface.debug('TRANSCODED (ms): ' + transcoded);

            _streamrootInterface.appendBuffer(bytes_append_audio);

            var appendedTS:Number = new Date().valueOf();
            var appended:Number = appendedTS - transcodedTS;
            _streamrootInterface.debug('APPENDED (ms): ' + appended);

            setHasData(true, AUDIO);
        }

        //Set audio timer state to idle and start timer video if it was waiting
        _timerStateAudio = TIMER_IDLE;
        if (_timerStateVideo === TIMER_REQUESTING) {
            startTimerVideo();
        }

        ExternalInterface.call("sr_flash_updateend_audio");
        return;
    }

    private function appendVideo(bytes_event:ByteArray):void {
        if(_pendingIsInitVideo==true){
            _initHandlerVideo = new InitializationVideoSegmentHandler(bytes_event);
        }else{
            var decodedTS :Number = new Date().valueOf();

            var bytes_append:ByteArray = new ByteArray();
            var videoSegmentHandler = new VideoSegmentHandler(bytes_event, _initHandlerVideo.messages, _initHandlerVideo.defaultSampleDuration, _initHandlerVideo.timescale, _pendingTimestampVideo - _pendingOffsetVideo, _muxer);
            bytes_append.writeBytes(videoSegmentHandler.bytes);

            if (_isWorkerReady){
                _mainToWorker.send(true)
            }

            var transcodedTS:Number = new Date().valueOf();
            var transcoded:Number = transcodedTS - decodedTS;
            _streamrootInterface.debug('TRANSCODED (ms): ' + transcoded);

            _streamrootInterface.appendBuffer(bytes_append)

            var appendedTS:Number = new Date().valueOf();
            var appended:Number = appendedTS - transcodedTS;
            _streamrootInterface.debug('APPENDED (ms): ' + appended);

            //_streamrootInterface.debug('media appended');
            setHasData(true, VIDEO);
        }

        //Set video timer state to idle and start timer audio if it was waiting
        _timerStateVideo = TIMER_IDLE;
        if (_timerStateAudio === TIMER_REQUESTING) {
            startTimerAudio();
        }

        ExternalInterface.call("sr_flash_updateend_video");
        return;
    }

    private function buffered(type:String):Number{
            if (type.indexOf("audio") >= 0){
                return _buffered_audio;
            }
            if (type.indexOf("video") >= 0){
                return _buffered;
            }
            return _buffered;
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

    public function appendFileHeader(ns:NetStream):void {
        var flv_header:ByteArray = this.getFileHeader();
        ns.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
        ns.appendBytes(flv_header);
    }

    public function areBuffersReady():Boolean {
        var flag:Boolean = true;
        var sourceBufferNumber:Number = 0;

        for (var k in _hasData) {
            flag = flag && _hasData[k];
            sourceBufferNumber++;
        }

        return (flag && (sourceBufferNumber > 0));
    }

    private function onWorkerToMain(event:Event):void {
        var message:* = _workerToMain.receive();

        var type:String = message.type;
        var isInit:Boolean = message.isInit;

        if (!_discardAppend) {

            if (!isInit) {
                _streamrootInterface.debug("FLASH: appending segment");
                var segmentBytes:ByteArray = message.segmentBytes;
                _streamrootInterface.appendBuffer(segmentBytes);
            }

            _isWorkerBusy = false;

            if (_pendingAppend != undefined) {
                _streamrootInterface.debug("FLASH: unqueing");
                appendOrQueue(_pendingAppend);
                _pendingAppend = undefined;
            }


            //Check better way to check type here as well
            if (type.indexOf("apple") >=0) {
                setHasData(true, VIDEO);
                setTimeout(updateendVideo, 20);
            }else if (type.indexOf("audio") >= 0) {
                if (!isInit) {
                    setHasData(true, AUDIO);
                }
                setTimeout(updateendAudio, 20);
            } else if (type.indexOf("video") >= 0) {
                if (!isInit) {
                    setHasData(true, VIDEO);
                }
                setTimeout(updateendVideo, 20);
            } else {
                _streamrootInterface.error("no type matching");
            }
        } else {
            sendSegmentFlushedMessage(type);
            _discardAppend = false;
            _isWorkerBusy = false;
        }
    }

    private function sendSegmentFlushedMessage(type:String):void {
        _streamrootInterface.debug("FLASH: discarding segment    " + type);
        if (type.indexOf("apple") >= 0) {
            updateendVideo(true);
        } else if (type.indexOf("audio") >= 0) {
            updateendAudio(true);
        } else if (type.indexOf("video") >= 0) {
            updateendVideo(true);
        }
    }

    private function updateendAudio(error:Boolean = false):void {
        ExternalInterface.call("sr_flash_updateend_audio", error);
    }

    private function updateendVideo(error:Boolean = false):void {
        ExternalInterface.call("sr_flash_updateend_video", error);
    }

    private function onDebugChannel(event:Event):void {
        var message:* = _debugChannel.receive();
        _isWorkerReady = true;

        if (message.command == "debug") {
            _streamrootInterface.debug(message.message);
        } else if (message.command == "error") {
            _streamrootInterface.error(message.message);
            if (message.type) {
                //If worker sent back an attribute "type", we want to set _isWorkerBusy to false and trigger 
                //a segment flushed message to notify the JS that append didn't work well, in order not to 
                //block the append pipeline
                _isWorkerBusy = false;
                sendSegmentFlushedMessage(message.type);
            }
        }
    }




}
}
