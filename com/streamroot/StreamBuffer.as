package com.streamroot {
    
    import com.streamroot.Segment;
    import com.streamroot.StreamBufferController;
    import com.streamroot.IStreamrootInterface;
    import com.streamroot.StreamrootInterfaceBase;
    import com.streamroot.StreamrootMSE;
    
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    
    import flash.external.ExternalInterface;
    
    
    /**
     * This class is an intermediate buffer before NetStream
     * It has been created because we can't remove data from NetStream.
     * To fix that we first store data in StreamBuffer, and at the last moment the minimum amount of needed data is appended in streambuffer
     * StreamBufferController regulary check the buffer length in NetStream and if need append new data from StreamBuffer
     *
     * This class manages the different buffer. There are one buffer per track type (ie audio, video, or just one buffer for both audio and video in hls) 
     * 
     */
    public class StreamBuffer{
        
        private var _streamBufferController:StreamBufferController;
        private var _streamrootInterface:IStreamrootInterface;
        private var _sourceBufferList:Dictionary = new Dictionary();
        private var _sourceBufferNumber:uint = 0;
        
        private var VIDEO:String = "video";
        private var AUDIO:String = "audio";
        
        private function addSourceBuffer(type:String):void {
            
            var key:String;
            if (type.indexOf("apple") >=0) {
                key = VIDEO;
            }else if (type.indexOf("audio") >= 0) {
                key = AUDIO;
            }else if (type.indexOf("video") >= 0) {
                key = VIDEO;
            }else {
                _streamrootInterface.error("Error: Type not supported: " + type);
            }
                    
            if (key) {
                if (!_sourceBufferList.hasOwnProperty(key)) {
                    _sourceBufferList[key] = new SourceBuffer(_streamrootInterface, key);
                    _sourceBufferNumber++;
                }
           }
        }
        
        public function areBuffersReady():Boolean {
            var ready:Boolean = true;
            for(var k:String in _sourceBufferList){
                ready = ready && _sourceBufferList[k].isReady();
            }
            return (ready && _sourceBufferNumber);
        } 
        
           
        public function StreamBuffer(streamrootInterface:IStreamrootInterface):void {
            _streamrootInterface = streamrootInterface;
            _streamBufferController = new StreamBufferController(this, _streamrootInterface); 
            
            ExternalInterface.addCallback("addSourceBuffer", addSourceBuffer);
            
        }
        
        /*
         * 
         */
        public function getDiffBetweenBuffers():uint{
            if(_sourceBufferNumber == 0){
                return 0;              
            }
            if(_sourceBufferNumber == 1){
                return 0;
            }else if(_sourceBufferNumber == 2){
                return Math.abs(_sourceBufferList[VIDEO].getCurrentTimestamp() - _sourceBufferList[AUDIO].getCurrentTimestamp())/1000;
            }else{
                _streamrootInterface.error("Wrong number of source buffer in flash StreamBuffer (should be 1 or 2) : " + _sourceBufferNumber);
                return 0;
            }
        }
        
        /*
         * Append a decoded segment in the corresponding sourceBuffer
         */
        public function appendSegment(segment:Segment):void {
            var type:String = segment.getType();
            var key:String;
            if (type.indexOf("apple") >=0) {
                key = VIDEO;
            }else if (type.indexOf("audio") >= 0) {
                key = AUDIO;
            }else if (type.indexOf("video") >= 0) {
                key = VIDEO;
            }else {
                _streamrootInterface.error("Error: Type not supported: " + type);
            }
            
            if (key) {
                if (_sourceBufferList.hasOwnProperty(key)) {
                    _sourceBufferList[key].appendSegment(segment);
                }else{
                    _streamrootInterface.error("Missing a BufferSource : " + type);                    
                }
            }    
        }
        
        /*
         * Remove data between start and end time in the sourceBuffer corresponding the key
         */    
        public function removeDataFromSourceBuffer(start:uint, end:uint, key:String):uint {
            return _sourceBufferList[key].remove(start, end);
        }
        
        /*
         * Remove all data in the buffer corresponding to the key
         */
        public function flushSourceBuffer(key:String):uint{
            return _sourceBufferList[key].flush();
        }
        
        /*
         * Remove all data in every buffer
         */
        public function flushAllSourceBuffer():void{
            for(var k:String in _sourceBufferList){
                _sourceBufferList[k].flush();
            }
        }

        /*
         * Each sourceBuffer has an attribute timestamp that correspond to the endTime of the last segment appended in NetStream
         * Because audio and video segment can have different length, audio and video sourceBuffer may have diffrent timestamp
         * This function return the minimum timestamp of all sourceBuffer. 
         * We know that after that timestamp we have both audio and video, but after it we may have only video or only audio appended in NetStream
         */
        public function getMinTimestampAppended():uint {
            var timestamp:uint = 0;
            var isInit:Boolean = false;
            for(var k:String in _sourceBufferList){
                if(!isInit){
                    timestamp = _sourceBufferList[k].getCurrentTimestamp();
                    isInit = true;
                }else{
                    timestamp = Math.min(timestamp, _sourceBufferList[k].getCurrentTimestamp());
                }
            } 
            return timestamp;   
        }
        
        /*
         * This function return the next segment that need to be appended in NetStream
         * It may be only video or audio data, or both at the same time
         */
        public function getNextSegmentBytes():Array{
            var array:Array = new Array();
            var minTimestamp:uint = getMinTimestampAppended();

            for(var k:String in _sourceBufferList){
                if(minTimestamp == _sourceBufferList[k].getCurrentTimestamp()){
                    var tempArray:ByteArray = _sourceBufferList[k].getNextSegmentBytes();
                    if(tempArray != null){
                        array.push(tempArray);
                    }
                }
            }
            minTimestamp = getMinTimestampAppended();
            return array;  
        }
    }
}