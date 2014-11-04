"use strict";

var B64MainThread = function(segmentAppender) {


    var _bytes,
        _b64Data,
        _offset,
        _segmentAppender = segmentAppender,
        PIECE_SIZE = 65535, //TODO: check if PIECE_SIZE should be (2^n)-1, to ensure that tempString is the right length to go through btoa

        _arrayBufferToBase64 = function(){
            var i,
                len = _bytes.byteLength,
                end = Math.min(_offset + PIECE_SIZE, len),
                tempString = "";
            for (i = _offset; i < end; i++) {
                tempString += String.fromCharCode( _bytes[i] );
            }
            _b64Data += btoa(tempString);
            if (end === len) {
                _segmentAppender.onDecoded(_b64Data);
            } else {
                _offset = end;
                setTimeout(_arrayBufferToBase64, 5);
            }
        },

        _startDecoding = function (segmentData) {
            _bytes = segmentData;
            _b64Data = '';
            _offset = 0;
            
            _arrayBufferToBase64();
        };

    this.startDecoding = _startDecoding;
};

module.exports = B64MainThread;