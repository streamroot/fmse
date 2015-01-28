package com.streamroot {

import flash.external.ExternalInterface;
import flash.net.NetStreamAppendBytesAction;

import flash.utils.ByteArray;

import com.streamroot.StreamrootMSE;

public interface StreamrootInterface {

    function StreamrootInterface(provider):void;

    function loaded():void;

    function appendBuffer(bytes:ByteArray):void;

    function areBuffersReady():Boolean;

    function play():void;

    function pause():void;

    function stop():void;

    function seek(time:Number):void;

    function onTrackList(trackList:String):void;

    //GETTERS
    function currentTime():Number;

    //EVENTS
    function triggerSeeked():void;

    function triggerLoadStart():void;

    function triggerPlaying():void;

    function triggerStopped():void;

    //LOGGING
    function debug(message):void;
    function error(message):void;

}
}
