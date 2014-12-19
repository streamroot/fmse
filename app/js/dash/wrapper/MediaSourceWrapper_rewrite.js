"use strict";

var MediaSourceFlash = require('./MediaSourceFlash');

var MediaSourceWrapper = function (video) {
    if (typeof video.getSwf !== "undefined") {
        
        //Flash shim
        return new MediaSourceFlash(video);
        
    } else {
        
        //Using real media source. (case where MediaSource is not defined should be handled in wrapper. here it will not fallback to flash
        //since SWF is not initialized in our library).
        var mediaSource;
        if (window.MediaSource !== null) {
            //Unprefixed MSE
            console.log("unprefixed MSE");
            mediaSource = new MediaSource();
        } else if(window.webkitMediaSource = window.WebKitMediaSource || window.webkitMediaSource || window.MozMediaSource) {
            //Prefixed MSE
            console.log("window.webkitMediaSource");
            mediaSource = new webkitMediaSource();
        } else {
            throw new Error("Media Source is not supported in this browser");
        }
        
        //mediaSource is defined here, we already called return if if doesn't exist
        //Set video.src BEFORE returning MSE
        if (window.URL !== null) {
            video.src = window.URL.createObjectURL(mediaSource);
        } else if (window.webkitURL = window.webkitURL || window.WebKitURL) {
            video.src = window.webkitURL.createObjectURL(mediaSource);
        }
        
        return mediaSource;
    }
};

module.exports = MediaSourceWrapper;
