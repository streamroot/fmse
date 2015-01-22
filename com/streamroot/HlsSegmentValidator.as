package com.streamroot {

import com.streamroot.StreamrootInterfaceBase;

public class HlsSegmentValidator {

    /** 1s margin because we compare manifest timestamp and pts **/
    private static const _TIMESTAMP_MARGIN:Number = 1 * 1000;
    /** Average duration of 1 frame **/
    private static const _FRAME_TIME:Number = (1/30) * 1000;

    //Remember pts/dts have been converted to ms from the start in pes parsing
    
    /** max_pts of the last appended segment **/
    private var _previousPTS:Number;
    /** Know if we're in a seek process or not **/
    private var _isSeeking:Boolean = false;

    /** Debugging only **/
    private var _streamrootInterface:StreamrootInterfaceBase;

    public function HlsSegmentValidator(streamrootInterface:StreamrootInterfaceBase) {
        _streamrootInterface = streamrootInterface;
    }


    /** Set by StreamrootMSE whenever we seek **/
    public function setIsSeeking(value:Boolean):void {
        _streamrootInterface.debug("VALIDATOR _isSeeking set to: " + value);
        _isSeeking = value;
    }

    /** Check if this segment is the right one and if its pts is consistent with its map timestamp **/
    public function checkSegmentPTS(min_pts:Number, max_pts:Number, timestamp:Number):String {
        _streamrootInterface.debug("VALIDATOR timestamp: " + timestamp/1000);
        _streamrootInterface.debug("VALIDATOR _previousPTS: " + _previousPTS/1000);
        _streamrootInterface.debug("VALIDATOR min_pts: " + min_pts/1000);
        _streamrootInterface.debug("VALIDATOR max_pts: " + max_pts/1000);

        if(Math.abs(min_pts - (timestamp + _FRAME_TIME)) > _TIMESTAMP_MARGIN) {
            return "apple_error_timestamp";
        } else if(!_isSeeking && _previousPTS && Math.abs(min_pts - (_previousPTS + _FRAME_TIME)) > _TIMESTAMP_MARGIN) {      
            return "apple_error_previousPTS";
        } else {
            _previousPTS = max_pts;
            return "true";
        }
    }
}
}