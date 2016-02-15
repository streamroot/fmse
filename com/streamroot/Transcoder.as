package com.streamroot {

import com.dash.utils.Base64;
import flash.utils.ByteArray;

import com.dash.handlers.InitializationAudioSegmentHandler;
import com.dash.handlers.InitializationVideoSegmentHandler;
import com.dash.handlers.VideoSegmentHandler;
import com.dash.handlers.AudioSegmentHandler;

import com.dash.boxes.Muxer;

public class Transcoder {

    private var _initHandlerAudio:InitializationAudioSegmentHandler;
    private var _initHandlerVideo:InitializationVideoSegmentHandler;

    private var _muxer:Muxer;

    private var _transcodeWorker:TranscodeWorker;
    private var _asyncTranscodeCB:Function;

    public function Transcoder(transcodeWorker:TranscodeWorker, asyncTranscodeCB:Function) {
        _muxer = new Muxer();
        _transcodeWorker = transcodeWorker;
        _asyncTranscodeCB = asyncTranscodeCB;
    }

    //TODO: transcode init in separate method (problem with return type?), return bytes to worker, that will send message back to MSE.
    //Call this method from MSE instead of fake Async with loop ( keep that on the side in different class)
    //We might want to take turns between appending audio and video though (if argument problems, or if simplifies the workflow)
    //timestamp must already take seek offset into account

    public function transcodeInit(data:String, type:String):void {
        var bytes_event:ByteArray = Base64.decode(data);
        if (isAudio(type)) {
            _initHandlerAudio = new InitializationAudioSegmentHandler(bytes_event);
        } else if (isVideo(type)) {
            _initHandlerVideo = new InitializationVideoSegmentHandler(bytes_event);
        }
        //TODO: switch for HLS + send error if no matching type
    }

    public function asyncTranscode(data:String, type:String, timestamp:Number, offset:Number, isInit:Boolean):void {
        var bytes_event:ByteArray = Base64.decode(data);
        CONFIG::LOGGING {
            _transcodeWorker.debug('FLASH transcoder.asyncTranscode');
        }

        if(isAudio(type)) {
            var bytes_append_audio:ByteArray = new ByteArray();
            var audioSegmentHandler:AudioSegmentHandler = new AudioSegmentHandler(bytes_event, _initHandlerAudio.messages, _initHandlerAudio.defaultSampleDuration, _initHandlerAudio.timescale, timestamp - offset + 100, _muxer);
            bytes_append_audio.writeBytes(audioSegmentHandler.bytes);

            _asyncTranscodeCB(type, isInit, bytes_append_audio);
        } else if (isVideo(type)) {
            var bytes_append:ByteArray = new ByteArray();
            var videoSegmentHandler:VideoSegmentHandler = new VideoSegmentHandler(bytes_event, _initHandlerVideo.messages, _initHandlerVideo.defaultSampleDuration, _initHandlerVideo.timescale, timestamp - offset + 100, _muxer);
            bytes_append.writeBytes(videoSegmentHandler.bytes);

            _asyncTranscodeCB(type, isInit, bytes_append);
        } else {
            //TODO: switch for HLS + send error if no matching type
        }
    }

    public function seeking():void {
    }

    private static function isAudio(type:String):Boolean {
        return type.indexOf("audio") >= 0;
    }

    private static function isVideo(type:String):Boolean {
        return type.indexOf("video") >= 0;
    }

}
}
