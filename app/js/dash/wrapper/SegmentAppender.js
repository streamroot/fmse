"use strict";

var b64Worker = './B64Worker.js'

var SegmentAppender = function (sourceBuffer, swfobj) {
    var _b64Worker = new Worker(b64Worker),
        
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
        
        _onWorkerMessage = function (e) {
            _doAppend(e.data.b64Data);
        },
        
        _appendBuffer = function (data, type, startTimeMs, endTime) {
            _type = type;
            _startTimeMs = startTimeMs;
            _endTime = endTime;
            
            //var uint8Data = new Uint8Array(data);
            //var abData = data.buffer;
            
            _b64Worker.postMessage({data: data.buffer}, [ data.buffer ]);
        },
        
        _initialize = function () {
            _b64Worker.onmessage = _onWorkerMessage;
        };
    
    this.appendBuffer = function (data, type, startTimeMs, endTime) {
        _appendBuffer(data, type, startTimeMs, endTime);
    };
    
    
    
    _initialize();
};

module.exports = SegmentAppender;