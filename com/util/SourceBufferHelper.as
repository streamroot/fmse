package com.util {

public class SourceBufferHelper{
        private static const VIDEO:String = "video";
        private static const AUDIO:String = "audio";
        private static const hls:String = "apple";
        private static const audio:String = "audio";
        private static const video:String = "video";
        
        public static function getType(type:String):String {
            if(type.indexOf(hls) >= 0){
                return VIDEO;
            }else if(type.indexOf(video) >= 0){
                return VIDEO;
            }else if(type.indexOf(audio) >= 0){
                return AUDIO;
            }else{
                return null;
            }
        }
        
        public static function isHLS(type:String):Boolean{
            if(type.indexOf(hls) >= 0){
                return true;
            }else{
                return false;
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