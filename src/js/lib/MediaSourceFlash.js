"use strict";

var SourceBuffer = require('./SourceBuffer');
var B64Encoder = require('./B64Encoder');
var EventEmitter = require('eventemitter3');

var MediaSourceFlash = function() {
    var self = this,

        _videoExtension,

        _swfobj,

        _b64Encoder = new B64Encoder(),

        _READY_STATE = {
            OPEN: 'open',
            CLOSED: 'closed'
        },

        _readyState = _READY_STATE.CLOSED,

        //TODO: is duration realy an attribute of MSE, or of video?
        _duration = 0,

        _ee = new EventEmitter(),

        _sourceBuffers = [],

        _addEventListener = function(type, listener) {
            _ee.on(type, listener);
        },

        _removeEventListener = function(type, listener) {
            _ee.off(type, listener);
        },

        _trigger = function(event) {
            _ee.emit(event.type, event);
        },

        _addSourceBuffer = function(type) {
            var sourceBuffer;
            sourceBuffer = new SourceBuffer(type, _videoExtension, _b64Encoder);
            _sourceBuffers.push(sourceBuffer);
            _videoExtension.registerSourceBuffer(sourceBuffer);
            _swfobj.addSourceBuffer(type);
            return sourceBuffer;
        },

        _removeSourceBuffer = function() {

        },

        _endOfStream = function() {

        },

        _initialize = function(videoExtension) {

            _videoExtension = videoExtension;
            _swfobj = _videoExtension.getSwf();

            _videoExtension.createSrc(self);

            _readyState = _READY_STATE.OPEN;
            _trigger({type: "sourceopen"});

            window.fMSE.callbacks.transcodeError = function(message) {
                console.error(message);
                if (window.onPlayerError) {
                    window.onPlayerError(message);
                }
            };

            _swfobj.jsReady();

            if (window.fMSE.debug.bufferDisplay) {
                window.fMSE.debug.bufferDisplay.attachMSE(self);
            }
        };

    this.addSourceBuffer = _addSourceBuffer;
    this.addEventListener = _addEventListener;
    this.removeEventListener = _removeEventListener;
    this.endOfStream = _endOfStream;
    this.initialize = _initialize;

    Object.defineProperty(this, "readyState", {
        get: function() {
            return _readyState;
        },
        set: undefined
    });

    //Duration is set in Buffer._initBuffer.
    Object.defineProperty(this, "duration", {
        get: function() {
            return _duration;
        },
        set: function(newDuration) {
            _duration = newDuration;
            _swfobj.onMetaData(newDuration, 320, 240);
        }
    });

    Object.defineProperty(this, "sourceBuffers", {
        get: function () {
            return _sourceBuffers;
        }
    });
};

MediaSourceFlash.isTypeSupported = function (type) {
    return type.indexOf('video/mp4') > -1;
};

module.exports = MediaSourceFlash;
