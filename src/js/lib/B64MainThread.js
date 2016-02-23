"use strict";

var B64MainThread = function(segmentAppender) {


    var _bytes,
        _b64Data,
        _offset,
        _segmentAppender = segmentAppender,
        PIECE_SIZE = 10000 * 3, //PIECE_SIZE needs to be a multiple of 3, since we call btoa on it

        _arrayBufferToBase64 = function() {
            var i,
                len = _bytes.byteLength,
                end = Math.min(_offset + PIECE_SIZE, len),
                tempString = "";
            for (i = _offset; i < end; i++) {
                tempString += String.fromCharCode(_bytes[i]);
            }
            _b64Data += btoa(tempString);
            if (end === len) {
                setTimeout(function() {
                    _segmentAppender.onDecoded(_b64Data);
                }, 5);
            } else {
                _offset = end;
                setTimeout(_arrayBufferToBase64, 5);
            }
        },

        _startDecoding = function(segmentData) {
            _bytes = segmentData;
            _b64Data = '';
            _offset = 0;

            _arrayBufferToBase64();
        };

    this.startDecoding = _startDecoding;
};

module.exports = B64MainThread;