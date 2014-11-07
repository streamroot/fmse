"use strict";

var SourceBuffer = require('./SourceBuffer');

var MediaSourceFlash = function (videoExtension) {
	var	self = this,
        
        _videoExtension = videoExtension,
        
        _swfobj = _videoExtension.getSwf(),
        
        _READY_STATE = {
            OPEN: 'open',
            CLOSED: 'closed'
        },
        
        _readyState = _READY_STATE.CLOSED,
            
        //TODO: is duration realy an attribute of MSE, or of video?
		_duration = 0,
        
		_listeners = [],
        
		_sourceBuffers= [],
        
		_addEventListener = function(type, listener){
			if (!_listeners[type]){
				_listeners[type] = [];
			}
			_listeners[type].unshift(listener);
		},
        
		_removeEventListener = function(type, listener){
            //TODO: I don't think that works. Why return? Should transform _listeners property of this class. UPDATE: see comment in SourceBuffer. Shouldn't the event bus be a class on its own?
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
        
		_addSourceBuffer = function(type){
			var sourceBuffer;
			sourceBuffer = new SourceBuffer(self, type, _swfobj);
			_sourceBuffers.push(sourceBuffer);
			_videoExtension.registerSourceBuffer(sourceBuffer);
			return sourceBuffer;
		},
            
		_removeSourceBuffer = function(){
            
        },
            
		_endOfStream =  function(){
            
        },
        
		_initialize = function(){
            _videoExtension.createSrc(self);
            
            //TODO: for VJS, flash is already ready, shouldn't need a timeout
            setTimeout(function() {_readyState = _READY_STATE.OPEN;}, 100);
        };
    
    this.addSourceBuffer = function (type) {
        return _addSourceBuffer(type);
    };
    
    this.addEventListener = function (type, listener) {
        _addEventListener(type, listener);
    };
    
    this.trigger = function (event) {
        _trigger(event);
    };
    
    
    Object.defineProperty(this, "readyState", {
        get: function () { return _readyState; },
        set: undefined
    });
    
    _initialize();
};

module.exports = MediaSourceFlash;