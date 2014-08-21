"use strict";
var SourceBuffer 	= require('./SourceBuffer');


var MediaSourceWrapper = function () {
	var
	_mediasourceflash = {
		srcUrl :'http://flash',
		readyState: 'close',
		swfobject:{},
		duration:0,
		_listeners:[],
		_sourceBuffers:[],
		_addEventListener:function(type, listener){
			if (!this._listeners[type]){
				this._listeners[type] = [];
			}
			this._listeners[type].unshift(listener);
		},
		_removeEventListener: function(type, listener){
			var listeners = this._listeners[type],
				i = listeners.length;
			while (i--) {
				if (listeners[i] === listener) {
					return listeners.splice(i, 1);
				}
			}
		},
		trigger :function(event){
			//updateend, updatestart
			var listeners = this._listeners[event.type] || [],
				i = listeners.length;
			while (i--) {
				listeners[i](event);
			}
		},
		addSourceBuffer: function(type){
			var sourceBuffer;
			sourceBuffer = new SourceBuffer(this, type);
			_sourceBuffers.push(sourceBuffer);
			return sourceBuffer;
		},
		removeSourceBuffer:function(){},
		endOfStream: function(){},
		initCallback:function (e){
			swfobject = e.ref;
			setTimeout(function(){
				init();
			},1500);
		},
		init:function(){
			this.readyState = 'open'; 
			//swfobject.embedSWF("pluginPlayer.swf", "video", "100%", "100%", "10.0.0", false, false, false, false, initCallback);
			//to trigger when the flash shim is loaded
			//this.trigger({{type:'sourceopen'}})
			},
		

		
	};
	
	if (window.MediaSource !== null) {
		console.log("unprefixed MSE 111");
		_mediasourceflash.init();
		return _mediasourceflash;
		
	} else if(window.webkitMediaSource = window.WebKitMediaSource || window.webkitMediaSource || window.MozMediaSource) {
		console.log("window.webkitMediaSource");
		return {}
	} else {
		console.log("Media Source Not available");
		return {}
	}
}

module.exports = MediaSourceWrapper;
