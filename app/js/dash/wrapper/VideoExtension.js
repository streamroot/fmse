"use strict";

var VideoExtension = function (video) {

	var _createSrc = function(mediaSource){
		if (window.URL !== null) {
			this.src = window.URL.createObjectURL(_mediaSource);
		} else if (window.webkitURL = window.webkitURL || window.WebKitURL) {
			this.src = window.webkitURL.createObjectURL(_mediaSource);
		}else{
			this.src = '';
			this._swfobject 	= mediaSource.swfobject;
		}
		return;
	};

	if (window.MediaSource !== null) {
		video.createSrc = _createSrc
		return video
	} else if(window.webkitMediaSource = window.WebKitMediaSource || window.webkitMediaSource || window.MozMediaSource) {
		video.createSrc = _createSrc
		return video
	} else {
	}	

	var self=this,
	_init = function(){
		self.createSrc 	= createSrc;
	},
	
	_currentTime = 0.0,
	_swfobject,
	_play = function(){
		_swfobject.play();
	},
	_pause= function(){
		_swfobject.pause()
	},
	_stop = function(){
		_swfobject.stop()
	},
	_seek = function(){
		_swfobject.seek()
	},
	
	_canPlayType	= function(){},
	_currentTime 	= function(time){
		_currentTime = time
	};
    
    Object.defineProperty(this, "currentTime", {
        get: function () { return _currentTime; },
        set: function (time) { _currentTime = time; }
    });
	
	this.createSrc = _createSrc;
}

module.exports = VideoExtension;