package com.streamroot {

import com.streamroot.StreamrootMSE;
import com.streamroot.util.Conf;


public class HlsSegmentValidator {


    //Remember pts/dts have been converted to ms from the start in pes parsing

    /** Know if we're in a seek process or not **/
    private var _isSeeking:Boolean = false;

    private var _streamrootMSE:StreamrootMSE;

    public function HlsSegmentValidator(streamrootMSE:StreamrootMSE) {
        _streamrootMSE = streamrootMSE;
    }

    /** Set by StreamrootMSE whenever we seek **/
    public function setIsSeeking(value:Boolean):void {
        CONFIG::LOGGING_PTS {
            _streamrootMSE.debug("_isSeeking set to: " + value);
        }
        _isSeeking = value;
    }

    /**
     * Check if this segment is the right one and if its pts is consistent with its map timestamp
     * Everything is in second
     */
    public function checkSegmentPTS(min_pts:Number, max_pts:Number, startTime:Number, previousPTS:Number):String {
        CONFIG::LOGGING_PTS {
            _streamrootMSE.debug("startTime: " + startTime, this);
            _streamrootMSE.debug("previousPTS: " + previousPTS, this);
            _streamrootMSE.debug("min_pts: " + min_pts, this);
            _streamrootMSE.debug("max_pts: " + max_pts, this);
        }

        if(Math.abs(min_pts - (startTime + Conf.FRAME_TIME)) > Conf.TIMESTAMP_MARGIN) {
            return "apple_error_timestamp";
        } else if(!_isSeeking && previousPTS != 0 && Math.abs(min_pts - (previousPTS + Conf.FRAME_TIME)) > Conf.TIMESTAMP_MARGIN) {
            return "apple_error_previousPTS";
        } else {
            return "true";
        }
    }
}
}