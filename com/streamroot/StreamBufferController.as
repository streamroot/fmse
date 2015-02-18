package com.streamroot {
    
    import flash.utils.setInterval;
    import flash.utils.ByteArray;
    
    import com.streamroot.StreamrootMSE; 
    import com.streamroot.StreamBuffer;

    
    public class StreamBufferController{
        
        private var _streamBuffer:StreamBuffer;
        private var _streamrootMSE:StreamrootMSE;
        
        private const TIMEOUT_LENGTH:uint = 100;
        private const EMERGENCY_TIME:Number = 3;
        
        public function StreamBufferController(streamBuffer:StreamBuffer, streamrootMSE:StreamrootMSE):void {
            _streamBuffer = streamBuffer;
            _streamrootMSE = streamrootMSE;
            
            setInterval(bufferize, TIMEOUT_LENGTH);
            
            
        }
        
        private function bufferize():void {
            //this is because _streamrootMSE.getBufferLength return the max length of audio and video track
            // but we want the lenght of the buffer for which we have both audio and video
            var trueBufferLength:Number = _streamrootMSE.getBufferLength() - _streamBuffer.getDiffBetweenBuffers();
            if(trueBufferLength < EMERGENCY_TIME){
                var array:Array = _streamBuffer.getNextSegmentBytes();
                for(var i:uint = 0; i < array.length; i++){
                    _streamrootMSE.appendIntoNetStream(array[i]);
                }
            }
        }
    
    }
}