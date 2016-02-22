package com.streamroot.events {

import flash.events.Event;

public class PlaybackEvent extends Event {

    public static const ON_META_DATA:String = "VideoPlaybackEvent.ON_META_DATA";
    public static const ON_NETSTREAM_STATUS:String = "VideoPlaybackEvent.ON_NETSTREAM_STATUS";
    public static const ON_NETCONNECTION_STATUS:String = "VideoPlaybackEvent.ON_NETCONNECTION_STATUS";
    public static const ON_STREAM_READY:String = "VideoPlaybackEvent.ON_STREAM_READY";
    public static const ON_STREAM_START:String = "VideoPlaybackEvent.ON_STREAM_START";
    public static const ON_STREAM_CLOSE:String = "VideoPlaybackEvent.ON_STREAM_CLOSE";
    public static const ON_STREAM_SEEK_COMPLETE:String = "VideoPlaybackEvent.ON_STREAM_SEEK_COMPLETE";
    public static const ON_VIDEO_DIMENSION_UPDATE:String = "VideoPlaybackEvent.ON_VIDEO_DIMENSION_UPDATE";

    // a flexible container object for whatever data needs to be attached to any of these events
    private var _data:Object;

    public function PlaybackEvent(pType:String, pData:Object = null) {
        super(pType, true, false);
        _data = pData;
    }

    public function get data():Object {
        return _data;
    }

}
}
