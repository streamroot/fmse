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

    private var _timestamp:Number;
	private var _endTime:uint;

	private var _transcoder:Transcoder;

	public function TranscodeWorker() {
		_mainToWorker = Worker.current.getSharedProperty("mainToWorker");
		_mainToWorker.addEventListener(Event.CHANNEL_MESSAGE, onMainToWorker);

		_workerToMain = Worker.current.getSharedProperty("workerToMain");

		_debugChannel = Worker.current.getSharedProperty("debugChannel");

		var object:Object = {command:'init'}
		_debugChannel.send(object);
		_transcoder = new Transcoder(this, asyncTranscodeCB);
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
		var endTime:uint = message.endTime;
		var offset:Number = message.offset;
        _timestamp = timestamp;
		_endTime = endTime;

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

            answer = {type: type, isInit: isInit};
            debug("sending back message");
            _workerToMain.send(answer);
            debug("message sent");

        } else {
        	debug("transcoding media");
            try {
                //var segmentBytes:ByteArray = _transcoder.transcode(data, type, timestamp, offset);
                _transcoder.asyncTranscode(data, type, timestamp, offset, isInit);
            } catch (e:Error) {
                error(e.toString(), type);
                return;
            }

            //answer = {type: type, isInit: isInit, segmentBytes: segmentBytes};
        }
	}


    public function asyncTranscodeCB(type:String, isInit:Boolean, segmentBytes:ByteArray, min_pts:Number = 0, max_pts:Number = 0):void {
        /** If type is HLS we return timestamp and PTS as well as segment bytes to be able to check if it's the right segment in HlsSegmentValidator **/
        CONFIG::LOGGING_PTS {
            debug("asyncTranscodeCB");
        }
		var answer:Object;
        if(type.indexOf("apple") >= 0) {
            answer = {type: type, isInit: isInit, segmentBytes: segmentBytes, timestamp:_timestamp, endTime: _endTime, min_pts: min_pts, max_pts: max_pts};
        } else {
            answer = {type: type, isInit: isInit, segmentBytes: segmentBytes, timestamp: _timestamp, endTime: _endTime};
        }

        debug("sending back message");
        _workerToMain.send(answer);
        debug("message sent");
    }

	public function debug(message:String):void {
		var object:Object = {command:'debug', message: message};
		_debugChannel.send(object);
	}

	public function error(message:String, type:String, min_pts:Number = 0, max_pts:Number = 0):void {
		var object:Object = {command:'error', message: message, type: type, min_pts:min_pts, max_pts:max_pts};
        CONFIG::LOGGING_PTS {
            debug("Transcodeworker.error min_pts: " + min_pts/1000);
            debug("TranscodeWorker.error max_pts: " + max_pts/1000);
        }
		_debugChannel.send(object);
	}

}

}
