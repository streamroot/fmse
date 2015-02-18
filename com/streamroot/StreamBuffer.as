package com.streamroot {
    
    import com.streamroot.Segment;
    import com.streamroot.StreamBufferController;
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
        private var _sourceBufferList:Array = new Array();
        private var _streamrootMSE:StreamrootMSE;
        
        private var VIDEO:String = "video";
        private var AUDIO:String = "audio";
        
        public function StreamBuffer(streamrootMSE:StreamrootMSE):void {
            _streamrootMSE = streamrootMSE;
            _streamBufferController = new StreamBufferController(this, _streamrootMSE); 
        }
    
        public function addSourceBuffer(type:String):void {
            _sourceBufferList.push(new SourceBuffer(_streamrootMSE, type));  
        }
        
        private function getSourceBufferByType(type:String):SourceBuffer {
            for(var i:int = 0; i < _sourceBufferList.length; i++){
                if(_sourceBufferList[i].getType() == type){
                    return _sourceBufferList[i];
                }
            }
            return null;
        }
        
        public function areBuffersReady():Boolean {
            var ready:Boolean = true;
            for(var i:int =0; i < _sourceBufferList.length; i++){
                ready = ready && _sourceBufferList[i].isReady();
            }
            return (ready && _sourceBufferList.length);
        } 
        
           
    
        
        /*
         * 
         */
        public function getDiffBetweenBuffers():Number{
            switch(_sourceBufferList.length){
                case 0:
                    return 0;            
                case 1:
                    return 0;
                case 2:
                    return Math.abs(_sourceBufferList[0].getAppendedEndTime() - _sourceBufferList[1].getAppendedEndTime())/1000;
                default:
                    _streamrootMSE.error("Wrong number of source buffer in flash StreamBuffer (should be 1 or 2) : " + _sourceBufferList.length);
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
        
        /*
         * Remove data between start and end time in the sourceBuffer corresponding the type
         */    
        public function removeDataFromSourceBuffer(start:uint, end:uint, type:String):uint {
            return getSourceBufferByType(type).remove(start, end);
        }
        
                
        /*
         * Remove all data in every buffer
         */
        public function flushAllSourceBuffer():void{
            for(var i:int = 0; i < _sourceBufferList.length; i++){
                _sourceBufferList[i].flush();
            }
        }

        /*
         * Each sourceBuffer has an attribute appendedEndTime that correspond to the endTime of the last segment appended in NetStream
         * Because audio and video segment can have different length, audio and video sourceBuffer may have diffrent appendedEndTime
         * This function return the minimum appendedEndTime of all sourceBuffer. 
         * We know that before appendedEndTime we have both audio and video, but after it we may have only video or only audio appended in NetStream
         */
        public function getAppendedEndTime():uint {
            var appendedEndTime:uint = 0;
            var isInit:Boolean = false;
            for(var i:int = 0; i < _sourceBufferList.length; i++){
                if(!isInit){
                    appendedEndTime = _sourceBufferList[i].getAppendedEndTime();
                    isInit = true;
                }else{
                    appendedEndTime = Math.min(appendedEndTime, _sourceBufferList[i].getAppendedEndTime());
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
            var appendedEndTime:uint = getAppendedEndTime();
            for(var i:int = 0; i < _sourceBufferList.length; i++){
                if(appendedEndTime == _sourceBufferList[i].getAppendedEndTime()){
                    var segmentBytes:ByteArray = _sourceBufferList[i].getNextSegmentBytes();
                    if(segmentBytes != null){
                        array.push(segmentBytes);
                    }
                }
            }
            return array;  
        }
    }
}