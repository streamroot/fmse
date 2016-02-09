package com.streamroot.util {

    public class TranscoderHelper{
        public static const PREVIOUS_PTS_ERROR:String = "apple_error_previousPTS";
        public static const PTS_ERROR:String = "apple_error_timestamp";

        public static const TRANSCODE_ERROR:String="transcode_error";
        public static const DEBUG:String="debug";
        public static const FLUSH:String="flush";

        public static function isPreviousPTSError(type:String):Boolean{
            if(type.indexOf(PREVIOUS_PTS_ERROR) >= 0){
                return true;
            }else{
                return false;
            }
        }

        public static function isPTSError(type:String):Boolean{
            if(type.indexOf(PTS_ERROR) >= 0){
                return true;
            }else{
                return false;
            }
        }
    }

}