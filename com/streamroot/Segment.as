package com.streamroot {

    import flash.utils.ByteArray;
    
    public class Segment {
        private var _type:String;
        
        private var _startTime:uint;
        
        private var _endTime:uint;
        
        private var _segmentBytes:ByteArray;
                        
        public function Segment(bytes:ByteArray, type:String, startTime:uint, endTime:uint):void {
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
        
        public function get startTime():uint {
            return _startTime;
        }
        
        public function get endTime():uint {
            return _endTime;
        }        
    }
}