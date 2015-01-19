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

    private var _lastPTS:Number;
    private var _previousPTS:Number;    // Remember pts has been converted to ms from the start in pes parsing
    private var _timestamp:Number;
    private var _TIMESTAMP_MARGIN:Number = 1 * 1000; // 1s margin because we compare manifest timestamp and pts.
    private var _FRAME_TIME:Number = (1/30) * 1000;  // average duration of 1 frame

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
		var offset:Number = message.offset;
        _timestamp = timestamp;

		var answer:Object = {type: type, isInit: isInit}; //Need to initialize answer here (didn't work if I only declared it)
        _lastPTS = message.lastPTS;

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
        /** If type is HLS we return sequence number and PTS as well as segment bytes **/
        debug("asyncTranscodeCB");

        //debug("TranscodeWorker _lastPTS: " + _lastPTS);
        debug("TranscodeWorker timestamp: " + _timestamp/1000);
        debug("TranscodeWorker min_pts: " + min_pts/1000);
        debug("TranscodeWorker max_pts: " + max_pts/1000);
        debug("TranscodeWorker _previousPTS: " + _previousPTS/1000);
        if(type.indexOf("apple") >= 0 && (Math.abs(min_pts - (_timestamp + _FRAME_TIME)) > _TIMESTAMP_MARGIN)) {
            // We just call an error that will discard the segment and send an updateend with error:true and min_pts to download
            // the right segment
            debug("TRANSCODEWORKER apple_error_timestamp: " + min_pts + " / " + timestamp);
            error("Timestamp and min_pts don't match", "apple_error_timestamp", min_pts, max_pts);
        } else if(type.indexOf("apple") >= 0 && _previousPTS && Math.abs(min_pts - (_previousPTS + _FRAME_TIME)) > _TIMESTAMP_MARGIN) {
            // No need to send back min and max pts in this case since media map doesn't need to be updated
            debug("TRANSCODEWORKER apple_error_previousPTS: " + min_pts + " / " + timestamp);
            error("previousPTS and min_pts don't match", "apple_error_previousPTS");
        } else if(type.indexOf("apple") >= 0) {
            var answer:Object = {type: type, isInit: isInit, segmentBytes: segmentBytes, min_pts: min_pts, max_pts: max_pts};
            _previousPTS = max_pts;
        } else {
            var answer:Object = {type: type, isInit: isInit, segmentBytes: segmentBytes};
        }
        
        if(answer) {
            debug("sending back message");
            _workerToMain.send(answer);
            debug("message sent");
        }
        
    }

	public function debug(message:String):void {
		var object:Object = {command:'debug', message: message};
		_debugChannel.send(object);
	}

	public function error(message:String, type:String, min_pts:Number = 0, max_pts:Number = 0):void {
		var object:Object = {command:'error', message: message, type: type, min_pts:min_pts, max_pts:max_pts};
        //debug("Transcodeworker.error min_pts: " + min_pts/1000);
        //debug("TranscodeWorker.error max_pts: " + max_pts/1000);
		_debugChannel.send(object);
	}

}

}
