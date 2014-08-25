"use strict";

var CustomTimeRange = require('../CustomTimeRange');

var SourceBuffer = function (mediaSource, type, swfObj) {

	var _listeners 		= [],
	_swfobj = swfObj,
	_audioTracks 	= [], 
	_videoTracks 	= [], 
	_nb_call 		= 0,
	_updating 		= false, //true , false
	_type 			= type,
	_bufferedArray = [],
	
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

	_appendBuffer     		= function (arraybuffer_data){
		var data = _arrayBufferToBase64( arraybuffer_data );
		_nb_call +=1;
		_swfobj.appendBufferPlayed(data,_type);
		_trigger({type:'updatestart'});
        
        //HACK: can't get event updateend from flash
        setTimeout(function () {
            _trigger({type:'updateend'});
        }, 500);
        
		_updating = true;
	},

	_arrayBufferToBase64 	= function(buffer){
		var binary = '';
		var bytes = new Uint8Array( buffer );
		var len = bytes.byteLength;
		for (var i = 0; i < len; i++) {
			binary += String.fromCharCode( bytes[ i ] )
		}
		return window.btoa(binary);
	},	

	_remove     		  = function (start,end){
        //TODO: implement remove method in sourceBuffer
		//_swfobj.removeBuffer(start,end);
	},
        
    _initialize = function() {
        _addEventListener('updateend',function(){ 
            _updating=false; 
        });
        
        _addEventListener('updatebuffered', function(event){
            _bufferedArray = [{start: 0, end: event.endTime}];
        });
    };
    
    this.appendBuffer = function (arraybuffer_data) {
        _appendBuffer(arraybuffer_data);
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
        get: function () {
            return new CustomTimeRange(_bufferedArray);
        },
        set: undefined
    });
    
    _initialize();
    
};

module.exports = SourceBuffer;