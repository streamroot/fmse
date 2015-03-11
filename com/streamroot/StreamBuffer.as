package com.streamroot {
    
    import com.streamroot.Segment;
    import com.streamroot.StreamBufferController;
    import com.streamroot.StreamrootMSE;
    
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    
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
        private var _sourceBufferList:Array = new Array();
        private var _streamrootMSE:StreamrootMSE;
        
        public function StreamBuffer(streamrootMSE:StreamrootMSE):void {
            _streamrootMSE = streamrootMSE;
            _streamBufferController = new StreamBufferController(this, _streamrootMSE); 
        }
    
        public function addSourceBuffer(type:String):void {
            if(getSourceBufferByType(type) == null){
                _sourceBufferList.push(new SourceBuffer(_streamrootMSE, type)); 
            }else{
                _streamrootMSE.error('SourceBuffer for this type already exists : ' + type, this);
            }
        }
        
        private function getSourceBufferByType(type:String):SourceBuffer {
            if(type == null){
                _streamrootMSE.error("No buffer for type null", this);
            }else{            
                for(var i:int = 0; i < _sourceBufferList.length; i++){
                    if(_sourceBufferList[i].type == type){
                        return _sourceBufferList[i];
                    }
                }
            }
            return null;
        }
        
        public function isBufferReady():Boolean {
            var ready:Boolean = true;
            for(var i:int =0; i < _sourceBufferList.length; i++){
                ready = ready && _sourceBufferList[i].ready;
            }
            return (ready && _sourceBufferList.length);
        } 
        
           
    
        
        /*
         * 
         */
        public function getDiffBetweenBuffers():Number{
            switch(_sourceBufferList.length){
                case 0:
                case 1:
                    return 0;
                case 2:
                    return Math.abs(_sourceBufferList[0].appendedEndTime - _sourceBufferList[1].appendedEndTime);
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
            if(sb != null) {
                sb.appendSegment(segment);
            }else{
                _streamrootMSE.error("BufferSource for type " + type + " not found");                    
            }    
        }
        
        public function getBufferEndTime():Number{
            var bufferEndTime:Number = 0;
            var isInit:Boolean = false;
            for(var i:int = 0; i < _sourceBufferList.length; i++){
                if(!isInit){
                    bufferEndTime = _sourceBufferList[i].getBufferEndTime();
                    isInit = true;
                }else{
                    bufferEndTime = Math.min(bufferEndTime, _sourceBufferList[i].getBufferEndTime());
                }
            }
            return bufferEndTime;  
        }
        
        /*
         * Remove data between start and end time in the sourceBuffer corresponding the type
         */    
        public function removeDataFromSourceBuffer(start:Number, end:Number, type:String):Number {
            var sb:SourceBuffer = getSourceBufferByType(type);
            if(sb != null){
                return sb.remove(start, end);
            }else{
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
            var isInit:Boolean = false;
            for(var i:int = 0; i < _sourceBufferList.length; i++){
                if(!isInit){
                    appendedEndTime = _sourceBufferList[i].appendedEndTime;
                    isInit = true;
                }else{
                    appendedEndTime = Math.min(appendedEndTime, _sourceBufferList[i].appendedEndTime);
                }
            } 
            return appendedEndTime;   
        }
        
        /*
         * This function return the next segment that need to be appended in NetStream
         * It may be only video or audio data, or both at the same time
         */
        public function getNextSegmentBytes():Array{
            var array:Array = new Array();
            var appendedEndTime:Number = getAppendedEndTime();
            for(var i:int = 0; i < _sourceBufferList.length; i++){
                if(appendedEndTime == _sourceBufferList[i].appendedEndTime){
                    var segmentBytes:ByteArray = _sourceBufferList[i].getNextSegmentBytes();
                    if(segmentBytes != null){
                        array.push(segmentBytes);
                    }
                }
            }
            return array;  
        }
        
        public function onSeek():void{
            for(var i:int = 0; i < _sourceBufferList.length; i++){
                _sourceBufferList[i].onSeek();    
            }   
        }
        
        public function bufferEmpty():void{
            for(var i:int = 0; i < _sourceBufferList.length; i++){
                _sourceBufferList[i].bufferEmpty(getAppendedEndTime());    
            } 
            _streamrootMSE.bufferEmpty();
        }
    }
}