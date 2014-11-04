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
        
        _doAppend = function (data) {
            var isInit = (typeof _endTime !== 'undefined') ? 0 : 1;
            
            _swfobj.appendBuffer(data, _type, isInit, _startTimeMs, Math.floor(_endTime*1000000));
            
            //TODO: call updateend on sourceBuffer
        },
        
        _onDecoded = function (decodedData) {
            _doAppend(decodedData);
        },
        
        _appendBuffer = function (data, type, startTimeMs, endTime) {
            _type = type;
            _startTimeMs = startTimeMs;
            _endTime = endTime;
            
            //var uint8Data = new Uint8Array(data);
            //var abData = data.buffer;
            
            _b64MT.startDecoding(data);
        },
        
        _initialize = function () {
            //_b64MT.communication = _onWorkerMessage;
        };
    
    self.appendBuffer = function (data, type, startTimeMs, endTime) {
        _appendBuffer(data, type, startTimeMs, endTime);
    };
    
    self.onDecoded = function(e) {
        _onDecoded(e);
    };
    
    
    _initialize();
};

module.exports = SegmentAppender;