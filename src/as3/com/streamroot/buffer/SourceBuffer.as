package com.streamroot.buffer {

import flash.utils.ByteArray;

/**
 * This class represent a buffer of audio or video data
 * When segment are appended in NetStream they are deleted from the SourceBuffer
 */
public class SourceBuffer {

    private var _buffer:Array = [];
    private var _appendedEndTime:Number = 0;
    private var _type:String;
    private var _ready:Boolean = false;

    public function SourceBuffer(type:String):void {
        _type = type;
    }

    /**
     * _appendedEndTime is the endTime of the last segment appended in NetStream
     * If no segment has been appended, it is 0
     */
    public function get appendedEndTime():Number {
        return _appendedEndTime;
    }

    public function get type():String {
        return _type;
    }

    /**
     * _ready is true if at least one segment has been appended, false if not
     * It is set a false only at the intialization and after a seek
     */
    public function get ready():Boolean {
        return _ready;
    }

    /**
     * Return bufferEndTime, ie that endTime of the last segment in the buffer, in second
     * If buffer is empty, it return the _appendedEndTime, which may be 0 if nothing has been appended in Netstream
     */
    public function getBufferEndTime():Number {
        if (_buffer.length == 0) {
            return _appendedEndTime;
        } else {
            return (_buffer[_buffer.length - 1] as Segment).endTime;
        }
    }

    /**
     * Return the next segment to be appended in NetStream
     */
    public function getNextSegmentBytes():ByteArray {
        var bytes:ByteArray = null;
        var segment:Segment;
        if (_buffer.length > 0) {
            segment = _buffer[0] as Segment;
            bytes = segment.bytes;
            _appendedEndTime = segment.endTime;
            _buffer.splice(0, 1);
            _ready = true;
        }
        return bytes;
    }

    public function appendSegment(segment:Segment):void {
        _buffer.push(segment);
    }

    /**
     * Remove data between start and end time from the buffer
     * Return bufferEndTime, ie that endTime of the last segment in the buffer, in second
     * (don't be mistaken, it is not the _appendedEndTime which is the endTime of the last segment APPENDED in NetStream)
     */
    public function remove(start:Number, end:Number):Number {
        if (start == 0) {
            _buffer = [];
        } else {
            while (_buffer.length > 0 && (_buffer[_buffer.length - 1] as Segment).startTime >= start) {
                _buffer.pop();
            }
        }
        return getBufferEndTime();
    }

    /**
     * Clear all data in the buffer
     */
    private function flush():Number {
        _buffer = [];
        return getBufferEndTime();
    }

    public function onSeek():Number {
        _ready = false;
        _appendedEndTime = 0;
        return flush();
    }

    public function bufferEmpty(appendedEndTime:Number):void {
        if (_appendedEndTime == appendedEndTime) {
            _ready = false;
        }
    }
}
}
