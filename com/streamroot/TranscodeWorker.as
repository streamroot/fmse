package com.streamroot {

import flash.system.Worker;
//import flash.system.WorkerDomain;
import flash.system.MessageChannel;

import flash.events.Event;
import flash.display.Sprite;
import flash.utils.ByteArray;

import com.streamroot.Transcoder;

/**
 * WARN : don't get lose between second and millisecond !
 * Basically what is named timestamp or pts is in millisecond, what is name something_time is in second
 * Make sure everything that goes out from Transcoder to StreamrootMSE is in second
 */
public class TranscodeWorker extends Sprite {

	private var _mainToWorker:MessageChannel;
	private var _workerToMain:MessageChannel;
	private var _commChannel:MessageChannel;

    private var _startTime:Number;//second
	private var _endTime:Number;//second

	private var _transcoder:Transcoder;

	public function TranscodeWorker() {
		_mainToWorker = Worker.current.getSharedProperty("mainToWorker");
		_mainToWorker.addEventListener(Event.CHANNEL_MESSAGE, onMainToWorker);

		_workerToMain = Worker.current.getSharedProperty("workerToMain");

		_commChannel = Worker.current.getSharedProperty("commChannel");

		var object:Object = {command:'init'}
		_commChannel.send(object);
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
		var timestamp:Number = message.startTime * 1000;//message.startTime in seocnd and timestamp in millisecond
		var offset:Number = message.offset * 1000;
        _startTime = message.startTime;
		_endTime = message.endTime;

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
            
            answer = {type: type, isInit: isInit};
            debug("sending back message");
            _workerToMain.send(answer);
            debug("message sent");

        } else {
        	debug("transcoding media");
            try {
                _transcoder.asyncTranscode(data, type, timestamp, offset, isInit);
            } catch (e:Error) {
                error(e.toString(), type);
                return;
            }
        }
	}

	/**
	 * min_pts and max_pts are in millisecond
	 * Make sure everything that goes out from Transcoder to StreamrootMSE is in second
	 */
    public function asyncTranscodeCB(type:String, isInit:Boolean, segmentBytes:ByteArray, min_pts:Number = 0, max_pts:Number = 0, width = 0, height = 0):void {
        /** If type is HLS we return PTS as well as segment bytes, startTime and endTime to be able to check if it's the right segment in HlsSegmentValidator **/
        CONFIG::LOGGING_PTS {
            debug("asyncTranscodeCB");
        }
		var answer:Object;
        if(type.indexOf("apple") >= 0) {
            answer = {type: type, isInit: isInit, segmentBytes: segmentBytes, startTime:_startTime, endTime: _endTime, min_pts: min_pts / 1000, max_pts: max_pts / 1000, width: width, height: height};
        } else {
            answer = {type: type, isInit: isInit, segmentBytes: segmentBytes, startTime:_startTime, endTime: _endTime};
        }

        debug("sending back message");
        _workerToMain.send(answer);
        debug("message sent");
    }

	public function debug(message:String):void {
		var object:Object = {command:'debug', message: message};
		_commChannel.send(object);
	}

	/**
	 * min_pts and max_pts are in millisecond
	 * Make sure everything that goes out from Transcoder to StreamrootMSE is in second
 	 */
	public function error(message:String, type:String):void {
		var object:Object = {command:'error', message: message, type: type};
		_commChannel.send(object);
	}
}

}
