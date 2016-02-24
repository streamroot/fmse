"use strict";

var CustomTimeRange = require('./utils/CustomTimeRange');
var SegmentAppender = require('./SegmentAppender');
var EventEmitter = require('eventemitter3');

var SourceBuffer = function(type, videoExtension, b64Encoder) {

    var self = this,

        _swfobj = videoExtension.getSwf(),

        _segmentAppender = new SegmentAppender(self, _swfobj, b64Encoder),

        _updating = false, //true , false
        _type = type,

        _startTime = 0, //TODO: Remove startTime hack
        _endTime = 0,
        _pendingEndTime = -1,
        /** _switchingTrack is set to true when we change rep and until the first segment of the new rep is appended in the Flash. It avoids fatal blocking at _isTimestampConsistent **/
        _switchingTrack = false,

        _onTrackSwitch = function() {
            _switchingTrack = true;
        },

        _ee = new EventEmitter(),

        _addEventListener = function(type, listener) {
            _ee.on(type, listener);
        },

        _removeEventListener = function(type, listener) {
            _ee.off(type, listener);
        },

        _trigger = function(event) {
            _ee.emit(event.type, event);
        },

        _isTimestampConsistent = function(startTime) {
            if (Math.abs(startTime - _endTime) >= 1 /*|| Math.abs(startTime - _endTime) > 60*/ ) {
                console.info("_isTimestampConsistent FALSE. startTime=", startTime, "_endTime=", _endTime);
            }

            return isNaN(startTime) || (Math.abs(startTime - _endTime) < 1);
        },

        _appendBuffer = function(arraybuffer_data, startTime, endTime) {
            _updating = true; //Do this at the very first
            _trigger({
                type: 'updatestart'
            });

            // that's dash.js segment descriptor
            if (startTime && startTime.segmentType) {
                var descriptor = startTime;
                startTime = descriptor.start;
                endTime = descriptor.end;
                var segmentType = descriptor.segmentType;
            }

            if (_isTimestampConsistent(startTime) || _switchingTrack || typeof startTime === "undefined") { //Test if discontinuity. Always pass test for initSegment (startTime unefined)
                _segmentAppender.appendBuffer(arraybuffer_data, _type, startTime, endTime, segmentType);
                _pendingEndTime = endTime;
            } else {
                //There's a discontinuity
                var firstSegmentBool = (_startTime === _endTime);
                console.info('timestamp not consistent. First segment after seek: ' + firstSegmentBool + ".   " + (startTime));
                _onUpdateend(true); //trigger updateend with error bool to true
            }
        },

        /**
     * This method remove data from the buffer.
     * WARN: all data between start and end time are not really removed from the buffer
     * Indeed we can't remove data from NetStream. To fix that an intermediate buffer has been implemented in flash (StreamBuffer.as)
     * Data is first stored in the streamBuffer, and then at the last moment, the minimum amount of data is inserted in NetStream
     * The methods _swfobj.flushSourceBuffer and _swfobj.remove clear data from the streamBuffer, but there will
     * always be a small amount of data in NetStream that can't be removed.
     *
     * @param  {int} start - Start of the removed interval, in seconds
     * @param  {int} end   - End of the removed interval, in seconds
     * @return - no returned value
     */
        _remove = function(start, end) {
            if (start < 0 || end == Infinity || start > end) {
                throw new Error("Invalid Arguments: cannot call SourceBuffer.remove");
            }

            _updating = true;
            if (start >= _endTime || end <= _startTime) {
                //we don't remove anything
            } else if (start <= _startTime && end >= _endTime) {
                //we remove the whole buffer
                //we should set _endTime = _startTime;
                //however all data that have been inserted into NetStream can't be removed. Method flushSourceBuffer return the true endTime, ie the endTime of NetSteam
                _endTime = _swfobj.remove(start, end, _type);
            } else if (start > _startTime) {
                //we should set _endTime = start;
                //however all data that have been inserted into NetStream can't be removed. Method _swfobj.remove return the true endTime, ie the endTime of NetSteam
                _endTime = _swfobj.remove(start, end, _type);
            } else if (start <= _startTime) {
                //in that case we can't remove data from NetStream
                console.warn('Buffer is virtually removed but data still exist in NetStream object');
                _startTime = end;
            }
            //it is important to set _pendingEndTime to -1 so that _endTime is not reassigned when flash will trigger onUpdateend when decoding of the current segment is finished
            _pendingEndTime = -1;
            //trigger updateend to launch next job. Needs the setTimeout to be called asynchronously and avoid error with Max call stack size (infinite recursive loop)
            _onUpdateend();
        },

        _buffered = function() {
            var bufferedArray = [];
            if (_endTime > _startTime) {
                bufferedArray.push({
                    start: _startTime,
                    end: _endTime
                });
            }
            return new CustomTimeRange(bufferedArray);
        },

        _debugBuffered = function() {
            var buffered = _buffered();
            if (_pendingEndTime > _endTime) {
                buffered.add({
                    start: _endTime,
                    end: _pendingEndTime
                });
            }
            return buffered;
        },

        _triggerUpdateend = function(error) {
            _updating = false;

            //If _pendingEndTime < _endTime, it means a segment has arrived late (MBR?), and we don't want to reduce our buffered.end
            //(that would trigger other late downloads and we would add everything to flash in double, which is not good for
            //performance)
            console.info('updateend ' + _type);
            if (!error && _pendingEndTime > _endTime) {
                console.info('setting end time to ' + _pendingEndTime);
                _endTime = _pendingEndTime;
                // Wait until we're sure the right segment was appended to netStream before setting _switchingTrack to false to avoid perpetual blocking at _isTimestampConsistent
                _switchingTrack = false;
            } else if (error) {
                console.info("Wrong segment. Update map then bufferize OR discontinuity at sourceBuffer.appendBuffer");
            }

            _trigger({
                type: 'updateend'
            });
        },

        _onUpdateend = function(error) {
            setTimeout(function() {
                _triggerUpdateend(error);
            }, 5);
        },

        _seekTime = function(time) {
            //Sets both startTime and endTime to seek time.
            _startTime = time;
            _endTime = time;

            //set _pendingEndTime to -1, because update end is triggered 20ms after end of append in NetStream, so if a seek happens in the meantime we would set _endTime to _pendingEndTime wrongly.
            //This won't happen if we set _pendingEndTime to -1, since we need _pendingEndTime > _endTime.
            _pendingEndTime = -1;
        },

        _initialize = function() {
            if (_type.match(/video/)) {
                window.fMSE.callbacks.updateend_video = _onUpdateend;
            } else if (_type.match(/audio/)) {
                window.fMSE.callbacks.updateend_audio = _onUpdateend;
            } else if (_type.match(/vnd/)) {
                window.fMSE.callbacks.updateend_video = _onUpdateend;
            }
            videoExtension.addEventListener('trackSwitch', _onTrackSwitch);

            if (window.fMSE.debug.bufferDisplay) {
                var debugSourceBuffer = {
                    buffered: _buffered,
                    type: _type
                };

                Object.defineProperty(debugSourceBuffer, "debugBuffered", {
                    get: _debugBuffered,
                    set: undefined
                });

                window.fMSE.debug.bufferDisplay.attachSourceBuffer(debugSourceBuffer);
            }
        };

    this.appendBuffer = _appendBuffer;
    this.remove = _remove;
    this.addEventListener = _addEventListener;
    this.removeEventListener = _removeEventListener;

    Object.defineProperty(this, "updating", {
        get: function() {
            return _updating;
        },
        set: undefined
    });

    Object.defineProperty(this, "buffered", {
        get: _buffered,
        set: undefined
    });

    this.appendWindowStart = 0;

    //
    //TODO: a lot of methods not in sourceBuffer spec. is there an other way?
    //

    this.seeking = function(time) {
        _seekTime(time);
        _segmentAppender.seeking();
    };

    this.seeked = function() {
        _segmentAppender.seeked();
    };

    this.segmentFlushed = function() {
        _onUpdateend(true);
    };

    Object.defineProperty(this, "isFlash", {
        get: function() {
            return true;
        },
        set: undefined
    });

    _initialize();
};

module.exports = SourceBuffer;
