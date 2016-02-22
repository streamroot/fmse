package com.streamroot.buffer {

import flash.utils.ByteArray;

public class Segment {
    private var _type:String;
    private var _startTime:Number;
    private var _endTime:Number;
    private var _segmentBytes:ByteArray;

    public function Segment(bytes:ByteArray, type:String, startTime:Number, endTime:Number):void {
        _type = type;
        _segmentBytes = bytes;
        _startTime = startTime;
        _endTime = endTime;
    }

    public function get bytes():ByteArray {
        return _segmentBytes;
    }

    public function get type():String {
        return _type;
    }

    public function get startTime():Number {
        return _startTime;
    }

    public function get endTime():Number {
        return _endTime;
    }
}
}
