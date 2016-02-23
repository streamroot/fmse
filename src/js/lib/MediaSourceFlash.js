"use strict";

var SourceBuffer = require('./SourceBuffer');
var B64Encoder = require('./B64Encoder');

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

    _listeners = [],

    _sourceBuffers = [],

    _addEventListener = function(type, listener) {
        if (!_listeners[type]) {
            _listeners[type] = [];
        }
        _listeners[type].unshift(listener);
    },

    _removeEventListener = function(type, listener) {
        //TODO: I don't think that works. Why return? Should transform _listeners property of this class. UPDATE: see comment in SourceBuffer. Shouldn't the event bus be a class on its own?
        var listeners = _listeners[type],
            i = listeners.length;
        while (i--) {
            if (listeners[i] === listener) {
                return listeners.splice(i, 1);
            }
        }
    },

    _trigger = function(event) {
        //updateend, updatestart
        var listeners = _listeners[event.type] || [],
            i = listeners.length;
        while (i--) {
            listeners[i](event);
        }
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
            // if (conf.REPORT_ERROR) {
                if (window.onPlayerError) {
                    window.onPlayerError(message);
                }
            // }
        };

        _swfobj.jsReady();
    };

    this.addSourceBuffer = _addSourceBuffer;
    this.addEventListener = _addEventListener;
    this.removeEventListener = _removeEventListener;
    this.endOfStream = _endOfStream;
    this.trigger = _trigger;
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
