"use strict";
var SourceBuffer = require('./SourceBuffer');

var MediaSourceWrapper = function () {

	if (window.MediaSource !== null) {
		_mediaSource = new MediaSource();
		console.log("unprefixed MSE");
		return _mediaSource
	} else if(window.webkitMediaSource = window.WebKitMediaSource || window.webkitMediaSource || window.MozMediaSource) {
		_mediaSource = new webkitMediaSource();
		return _mediaSource
	} else {
		throw("Media Source Not available");
	}

	var self = this,
	_init 		= function(){
		_readyState 	= 'open'
		this.readyState = _readyState;
		this.swfobject 	= _swfobject;
		this.trigger({{type:'sourceopen'}})
	},
	
	_listeners 	= {},

	_duration 	= NaN, //
	_readyState = 'close', //close, open, ended
	_sourceBuffers = [],

	_addEventListener 	= function(type, listener){
		if (!this._listeners[type]){
			this._listeners[type] = [];
		}
		this._listeners[type].unshift(listener);
	},
	
	_removeEventListener = function(type, listener){
		var listeners = this._listeners[type],
			i = listeners.length;
		while (i--) {
			if (listeners[i] === listener) {
				return listeners.splice(i, 1);
			}
		}
	},
	
	_trigger 			= function(event){
		//updateend, updatestart
		var listeners = this._listeners[event.type] || [],
			i = listeners.length;
		while (i--) {
			listeners[i](event);
		}
	},

	_addSourceBuffer 		= function(type){
		var sourceBuffer;
		sourceBuffer = new SourceBuffer(this, type, swfobj);
		_sourceBuffers.push(sourceBuffer);
		return sourceBuffer;
	},
	_removeSourceBuffer 	= function(){},
	_endOfStream 			= function(){};
	
	_callback 	= function (e){
		_swfobj = e.ref;
		setTimeout(function(){
			init();
		},1500);
	}
	swfobject.embedSWF("pluginPlayer.swf", "video", "100%", "100%", "10.0.0", false, false, false, false, _callback);

	
	return self;

}

module.exports = MediaSourceWrapper;