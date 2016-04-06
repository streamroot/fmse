package com.streamroot.transcoder {

import com.dash.boxes.Muxer;
import com.dash.handlers.AudioSegmentHandler;
import com.dash.handlers.InitializationAudioSegmentHandler;
import com.dash.handlers.InitializationVideoSegmentHandler;
import com.dash.handlers.VideoSegmentHandler;
import com.dash.utils.Base64;

import flash.utils.ByteArray;

public class Transcoder {

    private var _initHandlerAudio:InitializationAudioSegmentHandler;
    private var _initHandlerVideo:InitializationVideoSegmentHandler;

    private var _muxer:Muxer;

    private var _transcodeWorker:TranscodeWorker;
    private var _asyncTranscodeCB:Function;
	
	private var _isSeeking:Boolean = false;
    private var _seekTarget:Number = 0;

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
    }

    public function asyncTranscode(data:String, type:String, timestamp:Number, offset:Number, isInit:Boolean):void {
        _transcodeWorker.debug('FLASH transcoder.asyncTranscode');

        var bytes_event:ByteArray = Base64.decode(data);
        if (isAudio(type)) {
            var bytes_append_audio:ByteArray = new ByteArray();
            var audioSegmentHandler:AudioSegmentHandler = new AudioSegmentHandler(bytes_event, _initHandlerAudio.messages, _initHandlerAudio.defaultSampleDuration, _initHandlerAudio.timescale, timestamp, _muxer);
            bytes_append_audio.writeBytes(audioSegmentHandler.bytes);

            _asyncTranscodeCB(type, isInit, bytes_append_audio);
        } else if (isVideo(type)) {
            var bytes_append:ByteArray = new ByteArray();
            var videoSegmentHandler:VideoSegmentHandler = new VideoSegmentHandler(bytes_event, _initHandlerVideo.messages, _initHandlerVideo.defaultSampleDuration, _initHandlerVideo.timescale, timestamp, _muxer);
            bytes_append.writeBytes(videoSegmentHandler.bytes);

            _asyncTranscodeCB(type, isInit, bytes_append);
        }
    }
	
	public function seeking(target:Number):void {
		_isSeeking =true;
		_seekTarget = target;
		_muxer.seekTarget = target;
	}

	public function seeked(): void {
		_isSeeking = false;
        //_seekTarget = 0;
	}

    private static function isAudio(type:String):Boolean {
        return type.indexOf("audio") >= 0;
    }

    private static function isVideo(type:String):Boolean {
        return type.indexOf("video") >= 0;
    }

}
}
