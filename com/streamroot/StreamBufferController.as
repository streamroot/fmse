package com.streamroot {
    
    import flash.utils.setInterval;
    import flash.utils.ByteArray;
    
    import com.streamroot.StreamrootMSE; 
    import com.streamroot.StreamBuffer;
    
    import com.streamroot.util.Conf;

    
    public class StreamBufferController{
        
        private var _streamBuffer:StreamBuffer;
        private var _streamrootMSE:StreamrootMSE;
        private var _needData:Boolean = true;    

        public function StreamBufferController(streamBuffer:StreamBuffer, streamrootMSE:StreamrootMSE):void {
            _streamBuffer = streamBuffer;
            _streamrootMSE = streamrootMSE;
            
            setInterval(bufferize, 100);
            
            
        }
        
        private function bufferize():void {
            //this is because _streamrootMSE.getBufferLength return the max length of audio and video track
            // but we want the lenght of the buffer for which we have both audio and video
            var trueBufferLength:Number = _streamrootMSE.getBufferLength() - _streamBuffer.getDiffBetweenBuffers();
            if(trueBufferLength < Conf.NETSTREAM_BUFFER_LENGTH){
                var array:Array = _streamBuffer.getNextSegmentBytes();
                for(var i:uint = 0; i < array.length; i++){
                    _streamrootMSE.appendIntoNetStream(array[i]);
                    if(_needData && _streamBuffer.isBufferReady()){
                        _streamrootMSE.bufferFull();
                        _needData = false;
                    }
                    
                }
            }
        }
        
        public function onSeek():void{
            _needData = true;
        }
    
    }
}