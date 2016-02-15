package com.streamroot.util {

public class TrackTypeHelper{
        private static const VIDEO:String = "video";
        private static const AUDIO:String = "audio";
        private static const audio:String = "audio";
        private static const video:String = "video";

        public static function getType(type:String):String {
            if(type.indexOf(video) >= 0){
                return VIDEO;
            }else if(type.indexOf(audio) >= 0){
                return AUDIO;
            }else{
                return null;
            }
        }

        public static function isVideo(type:String):Boolean{
            if(type.indexOf(video) >= 0){
                return true;
            }else{
                return false;
            }
        }

        public static function isAudio(type:String):Boolean{
            if(type.indexOf(audio) >= 0){
                return true;
            }else{
                return false;
            }
        }
    }

}