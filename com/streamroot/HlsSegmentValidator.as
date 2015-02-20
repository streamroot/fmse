package com.streamroot {

import com.streamroot.IStreamrootInterface;

public class HlsSegmentValidator {

    /** 1s margin because we compare manifest timestamp and pts **/
    private static const _TIMESTAMP_MARGIN:Number = 1 * 1000;
    /** Average duration of 1 frame **/
    private static const _FRAME_TIME:Number = (1/30) * 1000;

    //Remember pts/dts have been converted to ms from the start in pes parsing
    
    /** Know if we're in a seek process or not **/
    private var _isSeeking:Boolean = false;

    private var _streamrootInterface:IStreamrootInterface;

    public function HlsSegmentValidator(streamrootInterface:IStreamrootInterface) {
        _streamrootInterface = streamrootInterface;
    }

    /** Set by StreamrootMSE whenever we seek **/
    public function setIsSeeking(value:Boolean):void {
        CONFIG::LOGGING_PTS {
            _streamrootInterface.debug("VALIDATOR _isSeeking set to: " + value);
        }
        _isSeeking = value;
    }

    /** Check if this segment is the right one and if its pts is consistent with its map timestamp **/
    public function checkSegmentPTS(min_pts:Number, max_pts:Number, timestamp:Number, previousPTS:Number):String {
        CONFIG::LOGGING_PTS { 
            _streamrootInterface.debug("VALIDATOR timestamp: " + timestamp/1000);
            _streamrootInterface.debug("VALIDATOR previousPTS: " + previousPTS/1000);
            _streamrootInterface.debug("VALIDATOR min_pts: " + min_pts/1000);
            _streamrootInterface.debug("VALIDATOR max_pts: " + max_pts/1000);
        }

        if(Math.abs(min_pts - (timestamp + _FRAME_TIME)) > _TIMESTAMP_MARGIN) {
            return "apple_error_timestamp";
        } else if(!_isSeeking && previousPTS != 0 && Math.abs(min_pts - (previousPTS + _FRAME_TIME)) > _TIMESTAMP_MARGIN) {      
            return "apple_error_previousPTS";
        } else {
        //    previousPTS = max_pts;
            return "true";
        }
    }
}
}