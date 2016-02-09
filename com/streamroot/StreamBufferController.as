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
        private var _canPlay:Boolean = false;

        private var _duration:Number;

        private const TIMEOUT_LENGTH:int = 100;
        private const EVENT_TIMEOUT_LENGTH:int = 1;
        private const BUFFER_EMPTY: Number = 0.1;

        public function StreamBufferController(streamBuffer:StreamBuffer, streamrootMSE:StreamrootMSE):void {
            _streamBuffer = streamBuffer;
            _streamrootMSE = streamrootMSE;

            setInterval(bufferize, TIMEOUT_LENGTH);
            setInterval(triggerEvent, EVENT_TIMEOUT_LENGTH);

        }

        public function set duration(duration:Number):void {
            _duration = duration;
        }

        private function triggerEvent():void {
            if(_streamBuffer.isBufferReady() && !_canPlay) {
                _canPlay = true;
                _streamrootMSE.triggerCanplay()
            } else if (!_streamBuffer.isBufferReady()) {
                _canPlay = false;
            }
        }

        /**
         * This method is call at fixed interval to check the time length of Netstream
         * If the time left is less than a fixed value (BUFFER_EMPTY) we call streambuffer to get the next segment to append
         *
         * It also check if buffer is empty or not, and call bufferEmpty and bufferFull is needed
         */
        private function bufferize():void {
            //this is because _streamrootMSE.getBufferLength return the max length of audio and video track
            // but we want the length of the buffer for which we have both audio and video

            var bufferLength:Number = _streamrootMSE.getBufferLength(); // return -1 is NetStream is not ready
            if(bufferLength >= 0){
                var trueBufferLength:Number = bufferLength - _streamBuffer.getDiffBetweenBuffers();
                if(trueBufferLength < Conf.NETSTREAM_BUFFER_LENGTH){
                    var array:Array = _streamBuffer.getNextSegmentBytes();

                    //check for buffer empty
                    if (array.length == 0 && trueBufferLength < BUFFER_EMPTY && !_needData){
                        _streamBuffer.bufferEmpty();
                        _needData = true;
                    }

                    for(var i:uint = 0; i < array.length; i++){
                        _streamrootMSE.appendNetStream(array[i]);
                    }
                }

                //check for buffer full
                if(_needData && _streamBuffer.isBufferReady()){
                    _streamrootMSE.bufferFull();
                    _needData = false;
                }

                if(_duration && _streamrootMSE.currentTime() + 0.3 >= _duration ) {
                    _streamrootMSE.triggerStopped();
                }


            }
        }
    }
}