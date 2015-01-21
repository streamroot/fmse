"use strict";

var CustomTimeRange = require('../CustomTimeRange');
var SegmentAppender = require('./SegmentAppender');
var EventEmitter = require('eventemitter3');

var SourceBuffer = function (mediaSource, type, swfobj, mediaController) {

    var self = this,
    
    _listeners = [],
	_swfobj = swfobj,
        
    _segmentAppender = new SegmentAppender(self, _swfobj),

    _updating = false, //true , false
    _type = type,
	
    
    _startTime = 0, //TODO: Remove startTime hack
    _endTime = 0,
    _pendingEndTime = -1,
    /** Keep in memory the id of the segment we're currently appending into the flash **/
    _appendingSeqnum,
	/** _switchingTrack is set to true when we change rep and until the first segment of the new rep is appended in the Flash. It avoids fatal blocking at _isTimestampConsistent **/
    _switchingTrack = false,

	_onTrackSwitch = function() {
        _switchingTrack = true;
    },

    _addEventListener = function(type, listener){
		if (!_listeners[type]){
			_listeners[type] = [];
		}
		_listeners[type].unshift(listener);
	},
	
	_removeEventListener = function(type, listener){
        //Same thing as MediaSourceFlash. Though splice should modify in place, and it should wok. But why return? Get out of the loop?
		var listeners = _listeners[type],
			i = listeners.length;
		while (i--) {
			if (listeners[i] === listener) {
				return listeners.splice(i, 1);
			}
		}
	},
	
	_trigger = function(event){
		//updateend, updatestart
		var listeners = _listeners[event.type] || [],
			i = listeners.length;
		while (i--) {
			listeners[i](event);
		}
	},
        
    _isTimestampConsistent = function (startTimeMs) {
        console.debug("_isTimestampConsistent _switchingTrack: " + _switchingTrack);
        if(Math.abs(startTimeMs/1000 - _endTime) >= 1 /*|| Math.abs(startTimeMs/1000 - _endTime) > 60*/) {
            console.debug("_isTimestampConsistent FALSE");
            console.debug("_isTimestampConsistent startTime: " + startTimeMs/1000);
            console.debug("_isTimestampConsistent _endTime: " + _endTime);
        }
        return (Math.abs(startTimeMs/1000 - _endTime) < 1);
    },

    //NOTE: starting from here in the chain seqnum will only be defined in the case of hls
    _appendBuffer = function (arraybuffer_data, startTimeMs, endTime, seqnum){
        _updating = true; //Do this at the very first
        _trigger({type:'updatestart'});
        
        if (_isTimestampConsistent(startTimeMs) || _switchingTrack || typeof startTimeMs === "undefined") { //Test if discontinuity. Always pass test for initSegment (startTimeMs unefined)
            _appendingSeqnum = seqnum;
            _segmentAppender.appendBuffer(arraybuffer_data, _type, startTimeMs, endTime);
            _pendingEndTime = endTime;
        } else {
            //There's a discontinuity
            var firstSegmentBool = (_startTime === _endTime);
            console.debug('timestamp not consistent. First segment after seek: ' + firstSegmentBool +".   " +  (startTimeMs/1000));
            _onUpdateend(true); //trigger updateend with error bool to true
        }
        
        /*
		var isInit = (typeof endTime !== 'undefined') ? 0 : 1,
            data = _arrayBufferToBase64( arraybuffer_data );
		
        console.debug('IS INIT: ' + isInit);
        
        _trigger({type:'updatestart'});
        
        setTimeout(function() {
            _swfobj.appendBuffer(data, _type, isInit, startTimeMs, Math.floor(endTime*1000000));
            _endTime = endTime;
        }, 50);
        */
        
        //HACK: can't get event updateend from flash
        /*
        setTimeout(function () {
            _trigger({type:'updateend'});
            if (isInit) {
                _endTime = endTime;
            }
        }, 200);
        */
	},
        /*
	_arrayBufferToBase64 = function(buffer){
		var binary = '';
		var bytes = new Uint8Array( buffer );
		var len = bytes.byteLength;
		for (var i = 0; i < len; i++) {
			binary += String.fromCharCode( bytes[ i ] )
		}
		return window.btoa(binary);
	},	
    */

	_remove = function (start,end){
        //TODO: implement remove method in sourceBuffer
		//_swfobj.removeBuffer(start,end);
        _updating = true;
        //CLIEN-111: in case of Flash we should set the end time to make sure the rest of the buffer is flushed when we change rep in force mode
        //_pendingEndTime = start;
        _onUpdateend();  //trigger updateend to launch next job. Needs the setTimeout to be called 
                                            //asynchronously and avoid error with Max call stack size (infinite recursive loop)   
	},
        
    _buffered = function() {
        //TODO: remove endTime hack
        /*
        var endTime = parseInt(_swfobj.buffered(_type)),
            bufferedArray = [{start: 0, end: endTime}];
        */
        //var endTime = _swfobj.buffered(_type) / 1000000;
        var bufferedArray = [];
        if (_endTime > _startTime) {
            bufferedArray.push({start:_startTime, end: _endTime});
        }
        return new CustomTimeRange(bufferedArray);
    },
        
    _triggerUpdateend = function (error, min_pts, max_pts) {
        _updating = false;
        if(!error) {
            console.debug("updateend, appended segment: " + _appendingSeqnum);
        }
        //If _pendingEndTime < _endTime, it means a segment has arrived late (MBR?), and we don't want to reduce our buffered.end
        //(that would trigger other late downloads and we would add everything to flash in double, which is not good for
        //performance)
        console.debug('updateend ' + _type);
        if (!error && _pendingEndTime > _endTime) {
            console.debug('setting end time to ' + _pendingEndTime);
            _endTime = _pendingEndTime;
            // Wait until we're sure the right segment was appended to netStream before setting _switchingTrack to false to avoid perpetual blocking at _isTimestampConsistent
            _switchingTrack = false;
        } else if (error) {
            console.debug("Wrong segment. Update map then bufferize OR discontinuity at sourceBuffer.appendBuffer");
        }
        if(min_pts > 0 && max_pts > 0) {    // Check that we are not in an apple_error_previousPTS (in which case 0 and 0 are returned but map mustn't be updated)
            mediaSource.updateMapPTS(_appendingSeqnum, min_pts, max_pts);
        }
        _trigger({type: 'updateend'});
    },
        
    _onUpdateend = function (error, min_pts, max_pts) {
        console.debug("_onUpdateend js: " + min_pts + " / " + max_pts);
        setTimeout(function () {
            _triggerUpdateend(error, min_pts, max_pts);
        }, 5);
    },

    _seekTime = function(time, audioEndTime) {
        //Sets both startTime and endTime to seek time.
        _startTime = time;
        _endTime = time;
        
        if (_type.match(/audio/) && typeof audioEndTime !== "undefined") {
            _endTime = audioEndTime;
        }
        
        //set _pendingEndTime to -1, because update end is triggered 20ms after end of append in NetStream, so if a seek happens in the meantime we would set _endTime to _pendingEndTime wrongly.
        //This won't happen if we set _pendingEndTime to -1, since we need _pendingEndTime > _endTime.
        _pendingEndTime = -1;
    },
        
    _initialize = function() {
        if (_type.match(/video/)) {
            window.sr_flash_updateend_video = _onUpdateend;
        } else if (_type.match(/audio/)) {
            window.sr_flash_updateend_audio = _onUpdateend;
        } else if (_type.match(/vnd/)) {
			window.sr_flash_updateend_video = _onUpdateend;
        }
        mediaController.ee.on('rep switch', _onTrackSwitch);
    };
    
    //TODO: remove endTime hack
    this.appendBuffer = _appendBuffer;
    this.remove = _remove;
    this.addEventListener = _addEventListener;
    this.trigger = _trigger;

    this.seekTime = _seekTime;
        
    Object.defineProperty(this, "updating", {
        get: function () { return _updating; },
        set: undefined
    });
    
    Object.defineProperty(this, "buffered", {
        get: _buffered,
        set: undefined
    });
    
    this.appendWindowStart = 0;
    
    //
    //TODO: a lot of methods not in sourceBuffer spec. is there an other way?
    //
    
    this.seeking = function (time, audioEndTime) {
        _seekTime(time, audioEndTime);
        _segmentAppender.seeking();
    };
    
    this.seeked = function() {
        _segmentAppender.seeked();
    };
    
    this.segmentFlushed = function () {
        _onUpdateend(true);
    };
    
    Object.defineProperty(this, "isFlash", {
        get: function () {
            return true;
        },
        set: undefined
    });
    
    _initialize();
    
};

module.exports = SourceBuffer;