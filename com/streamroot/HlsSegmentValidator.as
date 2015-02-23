package com.streamroot {

import com.streamroot.IStreamrootInterface;
import com.util.Conf;


public class HlsSegmentValidator {


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

    /**
     * Check if this segment is the right one and if its pts is consistent with its map timestamp
     * Everything is in second
     */
    public function checkSegmentPTS(min_pts:Number, max_pts:Number, startTime:Number, previousPTS:Number):String {
        CONFIG::LOGGING_PTS { 
            _streamrootInterface.debug("VALIDATOR startTime: " + startTime);
            _streamrootInterface.debug("VALIDATOR previousPTS: " + previousPTS);
            _streamrootInterface.debug("VALIDATOR min_pts: " + min_pts);
            _streamrootInterface.debug("VALIDATOR max_pts: " + max_pts);
        }

        if(Math.abs(min_pts - (startTime + Conf._FRAME_TIME)) > Conf._TIMESTAMP_MARGIN) {
            return "apple_error_timestamp";
        } else if(!_isSeeking && previousPTS != 0 && Math.abs(min_pts - (previousPTS + Conf._FRAME_TIME)) > Conf._TIMESTAMP_MARGIN) {      
            return "apple_error_previousPTS";
        } else {
            return "true";
        }
    }
}
}