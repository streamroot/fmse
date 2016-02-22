package com.streamroot.buffer {

import com.streamroot.MSEPolyfill;

import flash.utils.ByteArray;

/**
 * This class is an intermediate buffer before NetStream
 * It has been created because we can't remove data from NetStream.
 * To fix that we first store data in StreamBuffer, and at the last moment the minimum amount of needed data is appended in streambuffer
 * StreamBufferController regulary check the buffer length in NetStream and if need append new data from StreamBuffer
 *
 * This class manages the different buffer. There are one buffer per track type (ie audio, video)
 *
 */
public class StreamBuffer {

    private var _streamBufferController:StreamBufferController;
    private var _sourceBufferList:Array = [];
    private var _streamrootMSE:MSEPolyfill;

    public function StreamBuffer(streamrootMSE:MSEPolyfill):void {
        _streamrootMSE = streamrootMSE;
        _streamBufferController = new StreamBufferController(this, _streamrootMSE);
    }

    public function addSourceBuffer(type:String):void {
        if (getSourceBufferByType(type) == null) {
            _sourceBufferList.push(new SourceBuffer(type));
        } else {
            _streamrootMSE.error('SourceBuffer for this type already exists : ' + type, this);
        }
    }

    private function getSourceBufferByType(type:String):SourceBuffer {
        if (type == null) {
            _streamrootMSE.error("No buffer for type null", this);
        } else {
            var sourceBuffer:SourceBuffer;
            for (var i:int = 0; i < _sourceBufferList.length; i++) {
                sourceBuffer = _sourceBufferList[i] as SourceBuffer;
                if (sourceBuffer.type == type) {
                    return _sourceBufferList[i];
                }
            }
        }
        return null;
    }

    public function isBufferReady():Boolean {
        var ready:Boolean = true;
        var sourceBuffer:SourceBuffer;
        for (var i:int = 0; i < _sourceBufferList.length; i++) {
            sourceBuffer = _sourceBufferList[i] as SourceBuffer;
            ready = ready && sourceBuffer.ready;
        }
        return (ready && _sourceBufferList.length);
    }

    public function getDiffBetweenBuffers():Number {
        switch (_sourceBufferList.length) {
            case 0:
            case 1:
                return 0;
            case 2:
                var firstSB:SourceBuffer = _sourceBufferList[0] as SourceBuffer;
                var secondSB:SourceBuffer = _sourceBufferList[1] as SourceBuffer;

                return Math.abs(firstSB.appendedEndTime - secondSB.appendedEndTime);
            default:
                _streamrootMSE.error("Wrong number of source buffer in flash StreamBuffer (should be 1 or 2) : " + _sourceBufferList.length, this);
                return 0;
        }
    }

    /*
     * Append a decoded segment in the corresponding sourceBuffer
     */
    public function appendSegment(segment:Segment, type:String):void {
        var sb:SourceBuffer = getSourceBufferByType(type);
        if (sb != null) {
            _streamrootMSE.appendedSegment(segment.startTime, segment.endTime);
            sb.appendSegment(segment);
        } else {
            _streamrootMSE.error("BufferSource for type " + type + " not found");
        }
    }

    public function getBufferEndTime():Number {
        var bufferEndTime:Number = 0;
        var isInit:Boolean = false;
        var sourceBuffer:SourceBuffer;
        for (var i:int = 0; i < _sourceBufferList.length; i++) {
            sourceBuffer = _sourceBufferList[i] as SourceBuffer;
            if (!isInit) {
                bufferEndTime = sourceBuffer.getBufferEndTime();
                isInit = true;
            } else {
                bufferEndTime = Math.min(bufferEndTime, sourceBuffer.getBufferEndTime());
            }
        }
        return bufferEndTime;
    }

    /*
     * Remove data between start and end time in the sourceBuffer corresponding the type
     */
    public function removeDataFromSourceBuffer(start:Number, end:Number, type:String):Number {
        var sb:SourceBuffer = getSourceBufferByType(type);
        if (sb != null) {
            return sb.remove(start, end);
        } else {
            return 0;
        }
    }

    /*
     * Each sourceBuffer has an attribute appendedEndTime that correspond to the endTime of the last segment appended in NetStream
     * Because audio and video segment can have different length, audio and video sourceBuffer may have diffrent appendedEndTime
     * This function return the minimum appendedEndTime of all sourceBuffer.
     * We know that before appendedEndTime we have both audio and video, but after it we may have only video or only audio appended in NetStream
     */
    public function getAppendedEndTime():Number {
        var appendedEndTime:Number = 0;
        var sourceBuffer:SourceBuffer;
        var isInit:Boolean = false;
        for (var i:int = 0; i < _sourceBufferList.length; i++) {
            sourceBuffer = _sourceBufferList[i] as SourceBuffer;
            if (!isInit) {
                appendedEndTime = sourceBuffer.appendedEndTime;
                isInit = true;
            } else {
                appendedEndTime = Math.min(appendedEndTime, sourceBuffer.appendedEndTime);
            }
        }
        return appendedEndTime;
    }

    /*
     * This function return the next segment that need to be appended in NetStream
     * It may be only video or audio data, or both at the same time
     */
    public function getNextSegmentBytes():Array {
        var array:Array = [];
        var appendedEndTime:Number = getAppendedEndTime();
        var sourceBuffer:SourceBuffer;
        for (var i:int = 0; i < _sourceBufferList.length; i++) {
            sourceBuffer = _sourceBufferList[i] as SourceBuffer;
            if (appendedEndTime == sourceBuffer.appendedEndTime) {
                var segmentBytes:ByteArray = sourceBuffer.getNextSegmentBytes();
                if (segmentBytes != null) {
                    array.push(segmentBytes);
                }
            }
        }
        return array;
    }

    public function onSeek():void {
        var sourceBuffer:SourceBuffer;
        for (var i:int = 0; i < _sourceBufferList.length; i++) {
            sourceBuffer = _sourceBufferList[i] as SourceBuffer;
            sourceBuffer.onSeek();
        }
    }

    public function bufferEmpty():void {
        var sourceBuffer:SourceBuffer;
        for (var i:int = 0; i < _sourceBufferList.length; i++) {
            sourceBuffer = _sourceBufferList[i] as SourceBuffer;
            sourceBuffer.bufferEmpty(getAppendedEndTime());
        }
        _streamrootMSE.bufferEmpty();
    }

    public function setDuration(duration:Number):void {
        _streamBufferController.duration = duration;
    }
}
}
