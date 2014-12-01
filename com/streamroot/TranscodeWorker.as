package com.streamroot {

import flash.system.Worker;
//import flash.system.WorkerDomain;
import flash.system.MessageChannel;

import flash.events.Event;
import flash.display.Sprite;
import flash.utils.ByteArray;

import com.streamroot.Transcoder;

public class TranscodeWorker extends Sprite {

	private var _mainToWorker:MessageChannel;
	private var _workerToMain:MessageChannel;
	private var _debugChannel:MessageChannel;

	private var _transcoder:Transcoder;

	public function TranscodeWorker() {
		_mainToWorker = Worker.current.getSharedProperty("mainToWorker");
		_mainToWorker.addEventListener(Event.CHANNEL_MESSAGE, onMainToWorker);

		_workerToMain = Worker.current.getSharedProperty("workerToMain");

		_debugChannel = Worker.current.getSharedProperty("debugChannel");

		var object:Object = {command:'init'}
		_debugChannel.send(object);
		_transcoder = new Transcoder(this);
	}

	private function onMainToWorker(event:Event):void {
		var message:* = _mainToWorker.receive();

        if (message == "seeking") {
            _transcoder.seeking();
            return;
        }

		var data:String = message.data;
		var type:String = message.type;
		var isInit:Boolean = message.isInit;
		var timestamp:Number = message.timestamp;
		var offset:Number = message.offset;

		var answer:Object = {type: type, isInit: isInit}; //Need to initialize answer here (didn't work if I only declared it)




		if (isInit) {
			debug("transcoding init");
			debug("CHECK MODIFS");
            try {
               _transcoder.transcodeInit(data, type);
            } catch (e:Error) {
                error(e.toString(), type);
                return;
            }
            //Check better way to check type here as well
            /*
            if (type.indexOf("audio") >= 0) {
                ExternalInterface.call("sr_flash_updateend_audio");
            } else if (type.indexOf("video") >= 0) {
                ExternalInterface.call("sr_flash_updateend_video");
            } else {
                _streamrootInterface.error("no type matching");
            }
            */

            answer = {type: type, isInit: isInit}

        } else {
        	debug("transcoding media");
            try {
                //var segmentBytes:ByteArray = _transcoder.transcode(data, type, timestamp, offset);
                _transcoder.asyncTranscode(data, type, timestamp, offset, asyncTranscodeCB, isInit);
            } catch (e:Error) {
                error(e.toString(), type);
                return;
            }

            //answer = {type: type, isInit: isInit, segmentBytes: segmentBytes};
        }

        /*debug("sending back message");
        _workerToMain.send(answer);
        debug("message sent");*/
	}

    public function asyncTranscodeCB(type:String, isInit:Boolean, segmentBytes:ByteArray, seqnum:Number, min_pts:Number, max_pts:Number):void {
        var answer:Object = {type: type, isInit: isInit, segmentBytes: segmentBytes};
        debug("sending back message");
        _workerToMain.send(answer);
        debug("message sent");
    }

	public function debug(message:String):void {
		var object:Object = {command:'debug', message: message};
		_debugChannel.send(object);
	}

	public function error(message:String, type:String):void {
		var object:Object = {command:'error', message: message, type: type};
		_debugChannel.send(object);
	}

}

}
