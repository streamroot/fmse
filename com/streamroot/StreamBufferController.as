package com.streamroot {
    
    import flash.utils.setInterval;
    import flash.utils.ByteArray;
    
    import com.streamroot.StreamBuffer;
    import com.streamroot.IStreamrootInterface;
    import com.streamroot.StreamrootInterfaceBase;
    
    public class StreamBufferController{
        
        private var _streamBuffer:StreamBuffer;
        private var _streamrootInterface:IStreamrootInterface;
        
        private var TIMEOUT_LENGTH:uint = 100;
        private var EMERGENCY_TIME:int = 3;
        
        public function StreamBufferController(streamBuffer:StreamBuffer, streamrootInterface:IStreamrootInterface):void {
            _streamBuffer = streamBuffer;
            _streamrootInterface = streamrootInterface;
            
            setInterval(bufferize, TIMEOUT_LENGTH);
            
            
        }
        
        private function bufferize():void {
            //this is because _streamrootInterface.getBufferLength return the max length of audio and video track
            // but we want the lenght of the buffer for which we have both audio and video
            var trueBufferLength:int = _streamrootInterface.getBufferLength() - _streamBuffer.getDiffBetweenBuffers();
            
            if(trueBufferLength < EMERGENCY_TIME){
                var array:Array = _streamBuffer.getNextSegmentBytes();
                for(var i:uint = 0; i < array.length; i++){
                    _streamrootInterface.appendBuffer(array[i]);
                }
            }
        }
    
    }
}