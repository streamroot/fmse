"use strict";

//var b64Worker = './B64Worker.js'
var B64MainThread = require('./B64MainThread.js');

var SegmentAppender = function (sourceBuffer, swfobj) {
    var self = this,
        _b64MT = new B64MainThread(self),
        
        _sourceBuffer = sourceBuffer,
        _swfobj = swfobj,
        
        _type,
        _startTimeMs,
        _endTime,
        _discard = false, //prevent from appending decoded segment to swf obj during seeking (segment was already in B64 when we seeked)
        _seeking = false, //prevent an appendBuffer during seeking (segment arrived after having seeked)
        _isDecoding = false,
        
        _doAppend = function (data) {
            var isInit = (typeof _endTime !== 'undefined') ? 0 : 1;
            setTimeout(function() {
                _swfobj.appendBuffer(data, _type, isInit, _startTimeMs, Math.floor(_endTime*1000000));
            }, 5);
        },
        
        //Here we check first if we are seeking. If so, we don't append the decoded data.
        _onDecoded = function (decodedData) {
            _isDecoding = false;
            if(!_discard) { 
                console.debug("SegmentApender: DO append " + _type + "   " +  Math.floor(_startTimeMs/1000));
                _doAppend(decodedData);
            } else {
                console.debug("SegmentApender: discard data " + _type);
                _discard = false;
                _sourceBuffer.segmentFlushed();
            }
        },
        
        _appendBuffer = function (data, type, startTimeMs, endTime) {
            if(!_seeking) {
                _type = type;
                _startTimeMs = startTimeMs;
                _endTime = endTime;
                
                //var uint8Data = new Uint8Array(data);
                //var abData = data.buffer;
                
                console.debug("SegmentApender: start decoding " + _type);
                _isDecoding = true;
                _b64MT.startDecoding(data);
            } else {
                _sourceBuffer.segmentFlushed();
            }
        },
        
        _initialize = function () {
        };
    
    self.appendBuffer = function (data, type, startTimeMs, endTime) {
        _appendBuffer(data, type, startTimeMs, endTime);
    };
    
    self.onDecoded = function(e) {
        _onDecoded(e);
    };
    self.seeking = function() {
        if(_isDecoding) {
            _discard = true;
        }
        _seeking = true;
    };
    self.seeked = function() {
        _seeking = false;
    };
    
    
    _initialize();
};

module.exports = SegmentAppender;