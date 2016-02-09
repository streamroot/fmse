package com.streamroot.util {

public class Conf {
    //StreamBufferController
    public static const NETSTREAM_BUFFER_LENGTH:Number = 3; //seconds

    //HLSSegmentValidator
    public static const TIMESTAMP_MARGIN:Number = 1;
    public static const FRAME_TIME:Number = 1/30;

    //StreamrootInterfaceBase
    public static const LOG_DEBUG:Boolean = false;
    public static const LOG_ERROR:Boolean = true;
    public static const LOG_TRANSCODE_ERROR:Boolean = true;
}

}