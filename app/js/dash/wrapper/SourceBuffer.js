"use strict";

var CustomTimeRange = require('../CustomTimeRange');
var SegmentAppender = require('./SegmentAppender');

var SourceBuffer = function (mediaSource, type, swfobj) {

	var self = this,
    
    _listeners 		= [],
	_swfobj = swfobj,
        
    _segmentAppender = new SegmentAppender(self, _swfobj),

	_updating 		= false, //true , false
	_type 			= type,
	
    
    _startTime = 0, //TODO: Remove startTime hack
    _endTime = 0,
    _pendingEndTime = 0,
	
	_addEventListener 	= function(type, listener){
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
	
	_trigger 			= function(event){
		//updateend, updatestart
		var listeners = _listeners[event.type] || [],
			i = listeners.length;
		while (i--) {
			listeners[i](event);
		}
	},

	_appendBuffer     		= function (arraybuffer_data, startTimeMs, endTime){
        _updating = true; //Do this at the very first
        _trigger({type:'updatestart'});
        
        _segmentAppender.appendBuffer(arraybuffer_data, _type, startTimeMs, endTime);
        _pendingEndTime = endTime;
        
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
	_arrayBufferToBase64 	= function(buffer){
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
        setTimeout(_triggerUpdateend, 20);  //trigger updateend to launch next job. Needs the setTimeout to be called 
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
        
    _triggerUpdateend = function (error) {
        _updating=false;
        //If _pendingEndTime < _endTime, it means a segment has arrived late (MBR?), and we don't want to reduce our buffered.end
        //(that would trigger other late downloads and we would add everything to flash in double, which is not good for
        //performance)
        if (!error && _pendingEndTime > _endTime) {
            _endTime = _pendingEndTime;
        }
        _trigger({type: 'updateend'});
    },

    _seekTime = function(time) {
        //Sets both startTime and endTime to seek time.
        _startTime = time;
        _endTime = time;
    },
        
    _initialize = function() {        
        if (_type.match(/video/)) {
            window.sr_flash_updateend_video = _triggerUpdateend;
        } else if (_type.match(/audio/)) {
            window.sr_flash_updateend_audio = _triggerUpdateend;
        }
    };
    
    //TODO: remove endTime hack
    this.appendBuffer = function (arraybuffer_data, startTimeMs, endTime) {
        _appendBuffer(arraybuffer_data, startTimeMs, endTime);
    };
    
    this.remove = function (start, end) {
        _remove(start, end);
    };
    
    this.addEventListener = function (type, listener) {
        _addEventListener(type, listener);
    };
    
    this.trigger = function (event) {
        _trigger(event);
    };
    
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
    
    this.seeking = function (time) {
        _seekTime(time);
        _segmentAppender.seeking();
    };
    
    this.seeked = function() {
        _segmentAppender.seeked();
    };

    this.seekTime = function (time) {
        _seekTime(time);
    };
    
    this.segmentFlushed = function () {
        _triggerUpdateend(true);
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