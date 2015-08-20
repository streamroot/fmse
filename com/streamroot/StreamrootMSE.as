package com.streamroot {

import flash.external.ExternalInterface;
import flash.net.NetStream;
import flash.net.NetStreamAppendBytesAction;

import flash.events.Event;

import flash.system.Worker;
import flash.system.WorkerDomain;
import flash.system.MessageChannel;
import flash.system.WorkerState;

import com.dash.boxes.Muxer;

import com.dash.utils.Base64;

import flash.utils.ByteArray;
import flash.utils.setTimeout;
import flash.utils.Timer;
import flash.utils.getQualifiedClassName;

import com.streamroot.IStreamrootInterface;
import com.streamroot.StreamrootInterfaceBase;
import com.streamroot.StreamBuffer;
import com.streamroot.Segment;
import com.streamroot.Transcoder;
import com.streamroot.HlsSegmentValidator;

import com.streamroot.util.TrackTypeHelper;
import com.streamroot.util.TranscoderHelper;
import com.streamroot.util.Conf;

public class StreamrootMSE {

    private var _streamrootInterface:IStreamrootInterface;

    private var _streamBuffer:StreamBuffer;

    private var _muxer:Muxer;

    private var _jsReady:Boolean = false;

    private var _loaded:Boolean = false;

//    private var _initHandlerAudio:InitializationAudioSegmentHandler;
//    private var _initHandlerVideo:InitializationVideoSegmentHandler;

    private var _seek_offset:Number = 0;

    private var _ended:Boolean = false;

    private var _lastWidth:Number = 0;
    private var _lastHeight:Number = 0;
    private var _lastDuration:Number = 0;


    private static const TIMEOUT_LENGTH:uint = 5;


    [Embed(source="TranscodeWorker.swf", mimeType="application/octet-stream")]
    private static var WORKER_SWF:Class;

    private var _worker:Worker;

    private var _mainToWorker:MessageChannel;
    private var _workerToMain:MessageChannel;
    private var _commChannel:MessageChannel;

    private var _isWorkerReady:Boolean = false;

    private var _isWorkerBusy:Boolean = false;
    private var _pendingAppend:Object;
    private var _discardAppend:Boolean = false; //Used to discard data from worker in case we were seeking during transcoding

    private var _hlsSegmentValidator:HlsSegmentValidator;




    public function StreamrootMSE(streamrootInterface:IStreamrootInterface) {
        _streamrootInterface = streamrootInterface;

        _muxer = new Muxer();
        _hlsSegmentValidator = new HlsSegmentValidator(this);

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
        ExternalInterface.addCallback("onTrackList", onTrackList);
        //GETTERS
        ExternalInterface.addCallback("currentTime", currentTime);
        ExternalInterface.addCallback("paused", paused);

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

        //_buffered = timeSeek*1000000;
        //_buffered_audio = timeSeek*1000000;

        // Set isSeeking to skip _previousPTS check in HlsSegmentValidator.as
        _hlsSegmentValidator.setIsSeeking(true);

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
        if(key){
            _streamBuffer.addSourceBuffer(key);
        }else{
            error("Error: Type not supported: " + type);
        }
    }

    //timestampStart and timestampEnd in second
    private function appendBuffer(data:String, type:String, isInit:Boolean, startTime:Number = 0, endTime:Number = 0 ):void {
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

    public function appendFileHeader(ns:NetStream):void {
        var flv_header:ByteArray = this.getFileHeader();
        ns.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
        ns.appendBytes(flv_header);
    }

    private function onWorkerToMain(event:Event):void {
        var message:* = _workerToMain.receive();

        var type:String = message.type;
        var isInit:Boolean = message.isInit;
        var min_pts:Number = message.min_pts;//second
        var max_pts:Number = message.max_pts;//second
        var startTime:Number = message.startTime;
        var width:Number = message.width;
        var height:Number = message.height;

        var segment:Segment = new Segment(message.segmentBytes, message.type, message.startTime, message.endTime);

        _isWorkerBusy = false;

        if (!_discardAppend) {

            if (!isInit) {
                // CLIEN-19: check if it's the right hls segment before appending it.

                if (TrackTypeHelper.isHLS(segment.type)) {
                    var previousPTS:Number = _streamBuffer.getBufferEndTime();
                    var segmentChecked:String = _hlsSegmentValidator.checkSegmentPTS(min_pts, max_pts, startTime, previousPTS);
                }

                if (TrackTypeHelper.isHLS(segment.type) && TranscoderHelper.isPTSError(segmentChecked)) {
                    // We just call an error that will discard the segment and send an updateend with error:true and min_pts to download the right segment
                    debug("Timestamp and min_pts don't match", this)
                    sendSegmentFlushedMessage(TranscoderHelper.PTS_ERROR, min_pts, max_pts);
                    return;
                } else if (TrackTypeHelper.isHLS(segment.type) && TranscoderHelper.isPreviousPTSError(segmentChecked)) {
                    // No need to send back min and max pts in this case since media map doesn't need to be updated
                    debug("previousPTS and min_pts don't match", this)
                    sendSegmentFlushedMessage(TranscoderHelper.PREVIOUS_PTS_ERROR);
                    return;
                } else {
                    // Append DASH || Smooth || Validated HLS segment
                    CONFIG::LOGGING_PTS {
                        debug("Appending segment in StreamBuffer", this);
                    }
                    if (_lastHeight === 0 && width > 0 && height > 0) {
                        debug("setting video size: " + width + " - " + height);
                        onMetaData(0, width, height);
                    }

                    _streamBuffer.appendSegment(segment, TrackTypeHelper.getType(segment.type));
                }
            }

            if (_pendingAppend) {
                debug("Unqueing", this);
                appendOrQueue(_pendingAppend);
                _pendingAppend = null;
            }


            if (TrackTypeHelper.isHLS(type)) {
                _hlsSegmentValidator.setIsSeeking(false);
                setTimeout(updateendVideoHls, TIMEOUT_LENGTH, min_pts, max_pts);
            } else if (TrackTypeHelper.isAudio(type)) {
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

    private function sendSegmentFlushedMessage(type:String, min_pts:Number = 0, max_pts:Number = 0):void {
        CONFIG::LOGGING {
            debug("Discarding segment    " + type, this);
        }
        if(TranscoderHelper.isPTSError(type)) {
            CONFIG::LOGGING_PTS {
                debug("sendSegmentFlushedMessage min_pts: " + min_pts, this);
                debug("sendSegmentFlushedMessage max_pts: " + max_pts, this);
            }
            setTimeout(updateendVideoHls, TIMEOUT_LENGTH, min_pts, max_pts, true);
        } else if (TrackTypeHelper.isHLS(type)) {    // This case includes PREVIOUS_PTS_ERROR case
            CONFIG::LOGGING_PTS {
                debug("Inside case discarding but no min/max pts returned to js", this);
            }
            setTimeout(updateendVideo, TIMEOUT_LENGTH, true);
        } else if (TrackTypeHelper.isAudio(type)) {
            setTimeout(updateendAudio, TIMEOUT_LENGTH, true);
        } else if (TrackTypeHelper.isVideo(type)) {
            setTimeout(updateendVideo, TIMEOUT_LENGTH, true);
        }
    }

    private function updateendVideoHls(min_pts:Number, max_pts:Number, error:Boolean = false):void {
        CONFIG::LOGGING_PTS {
            debug("updateendVideoHls min_pts: " + min_pts, this);
            debug("updateendVideoHls max_pts: " + max_pts, this);
        }
        ExternalInterface.call("sr_flash_updateend_video", error, min_pts, max_pts);
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
        _streamrootInterface.appendBytes(bytes);
    }

    public function remove(start:Number, end:Number, type:String):Number {
        return _streamBuffer.removeDataFromSourceBuffer(start, end, TrackTypeHelper.getType(type));
    }

    public function getBufferLength():Number{
        return _streamrootInterface.getBufferLength();
    }

    //StreamrootInterface function
    private function onMetaData(duration:Number, width:Number=0, height:Number=0):void {
        if (_lastDuration === 0) {
            if (duration >0) {
                _lastDuration = duration;
                _streamBuffer.setDuration(duration);
            }
        } else if (duration === 0) {
            duration = _lastDuration;
        }
        if (_lastHeight === 0) {
            _lastWidth = width;
            _lastHeight = height;
            _streamrootInterface.onMetaData(duration, width, height);
        }
    }

    private function play():void {
        _streamrootInterface.play();
    }

    private function pause():void {
        _streamrootInterface.pause();
    }

    private function seek(time:Number):void {
        setSeekOffset(time);
        _streamrootInterface.seek(time);
    }

    public function currentTime():Number {
        return _streamrootInterface.currentTime();
    }

    private function paused():Boolean {
        return _streamrootInterface.paused();
    }

    public function requestSeek(time:Number):void {
        ExternalInterface.call("sr_request_seek", time);
    }

    public function requestQualityChange(quality:Number):void {
        ExternalInterface.call('sr_request_quality_change', quality);
    }

    public function bufferEmpty():void {
        _streamrootInterface.bufferEmpty();
        triggerWaiting();
    }

    public function bufferFull():void {
        _streamrootInterface.bufferFull();
        triggerPlaying();
    }

    private function onTrackList(trackList:String):void {
        _streamrootInterface.onTrackList(trackList);
    }

    public function loaded():void {
        //append the FLV Header to the provider, using appendBytesAction
        _streamrootInterface.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
        _streamrootInterface.appendBytes(getFileHeader());

        if (!_loaded) {
            //Call javascript callback (implement window.sr_flash_ready that will initialize our JS library)
            //Do not call on replay, as it would initialize a second instance of our JS library (that's why the
            //_loaded Boolean is for here)
            ExternalInterface.call('sr_flash_ready');
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
        if(_jsReady){
            ExternalInterface.call("sr_flash_loadstart");
        }else{
            setTimeout(triggerLoadStart, 10);
        }
        
    }

    public function triggerPlay():void {
        _ended = false;

        if(_jsReady){
            //Trigger event when video starts playing.
            ExternalInterface.call("sr_flash_play");
            if (_streamBuffer.isBufferReady() /*&& _firstPlayEventSent*/) {
                triggerPlaying();
            }
            //_firstPlayEventSent = true;
        }else{
            setTimeout(triggerPlay, 10);
        }
    }

    public function triggerPause():void {
        //Trigger event when video starts playing. Not used for now
        if(_jsReady){
            ExternalInterface.call("sr_flash_pause");
        }else{
            setTimeout(triggerPause, 10);
        }
    }

    public function triggerPlaying():void {
        _ended = false;

        //Trigger event when media is playing
        if(_jsReady){
            ExternalInterface.call("sr_flash_playing");
        }else{
            setTimeout(triggerPlaying, 10);
        }
    }

    public function triggerWaiting():void {
        //Trigger event when video has been paused but is expected to resume (ie on buffering or manual paused)
        if(_jsReady){
            ExternalInterface.call("sr_flash_waiting");
        }else{
            setTimeout(triggerWaiting, 10);
        }
    }

    public function triggerStopped():void {
        //Trigger event when video ends.
        if (!_ended) {
            _streamrootInterface.onStop();
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
        //trigger event xhen there is enough stat in buffer to play
        ExternalInterface.call("sr_flash_volumeChange", volume);
    }

    public function error(message:Object, obj:Object = null):void {
        if(_jsReady){
            if (Conf.LOG_ERROR) {
                if(obj != null){
                    var textMessage:String = getQualifiedClassName(obj) + ".as : " + String(message);
                    ExternalInterface.call("console.error", textMessage);
                }else{
                    ExternalInterface.call("console.error", String(message));
                }
            }
        }else{
            setTimeout(error, 10, message, obj);
        }
    }

    public function transcodeError(message:Object):void{
        if(_jsReady){
            ExternalInterface.call("sr_flash_transcodeError", String(message));
        }else{
            setTimeout(transcodeError, 10, message);
        }
    }

    public function debug(message:Object, obj:Object = null):void {
        if(_jsReady){
            if (Conf.LOG_DEBUG) {
                if(obj != null){
                    var textMessage:String = getQualifiedClassName(obj) + ".as : " + String(message);
                    ExternalInterface.call("console.debug", textMessage);
                }else{
                    ExternalInterface.call("console.debug", String(message));
                }
            }
        }else{
            setTimeout(debug, 10, message, obj);
        }
    }

    public function flush(message:Object):void{
        if(message.type){
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
