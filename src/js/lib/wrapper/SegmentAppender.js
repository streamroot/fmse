"use strict";

var SegmentAppender = function(sourceBuffer, swfObj, b64Encoder) {
    var self = this,

    _b64Encoder = b64Encoder,

    _sourceBuffer = sourceBuffer,
    _swfObj = swfObj,

    _type,
    _startTime,
    _endTime,
    _segmentType,
    _discard = false, //prevent from appending decoded segment to swf obj during seeking (segment was already in B64 when we seeked)
    _seeking = false, //prevent an appendBuffer during seeking (segment arrived after having seeked)
    _isDecoding = false,

    //Before sending segment to flash we check first if we are seeking. If so, we don't append the decoded data.
    _doAppend = function (data) {
        _isDecoding = false;
        if (!_discard) {
            console.info("SegmentApender: DO append " + _type + "_startTime=" + _startTime);

            var isInit = _segmentType !== undefined
                            ? _segmentType == "InitializationSegment"
                            : isNaN(_startTime) || (typeof _endTime !== 'undefined');

            _swfObj.appendBuffer(data, _type, isInit, _startTime, _endTime);
        } else {
            console.info("SegmentApender: discard data " + _type);
            _discard = false;
            _sourceBuffer.segmentFlushed();
        }
    },

    _appendBuffer = function(data, type, startTime, endTime, segmentType) {

        if (!_seeking) {
            _type = type;
            _startTime = startTime;
            _endTime = endTime;
            _segmentType = segmentType;

            console.info("SegmentApender: start decoding " + _type);
            _isDecoding = true;
            _b64Encoder.encodeData(data, _doAppend);
        } else {
            _sourceBuffer.segmentFlushed();
        }
    },

    _initialize = function() {};

    self.appendBuffer = _appendBuffer;

    self.seeking = function() {
        if (_isDecoding) {
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
