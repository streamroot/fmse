"use strict";

var MediaSourceFlash = require('./MediaSourceFlash');

var MediaSourceWrapper = function (video) {
    return new MediaSourceFlash(video);
    
    //TODO: return real MSE if chrome, and flash instead. Implement conf parameter to use flash only.
    /*
    if (window.MediaSource !== null) {
		console.log("unprefixed MSE 111");
		_mediasourceflash.init();
		return _mediasourceflash;
		
	} else if(window.webkitMediaSource = window.WebKitMediaSource || window.webkitMediaSource || window.MozMediaSource) {
		console.log("window.webkitMediaSource");
		return new webkitMediaSource();
	} else {
		console.log("Media Source Not available");
		return {}
	}
    */
};

module.exports = MediaSourceWrapper;
