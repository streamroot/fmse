package com.streamroot {

import flash.external.ExternalInterface;
import flash.net.NetStreamAppendBytesAction;

import flash.utils.ByteArray;

import com.streamroot.StreamrootMSE;

public interface IStreamrootInterface {

    function loaded():void;

    function appendBuffer(bytes:ByteArray):void;

    function areBuffersReady():Boolean;

    function play():void;

    function pause():void;

    function stop():void;

    function seek(time:Number):void;

    function onTrackList(trackList:String):void;
    
    function onMetaData(duration:Number, width:Number=0, height:Number=0):void;
    
    function bufferEmpty():void;
    
    function bufferFull():void;
    
    //GETTERS
    function currentTime():Number;

    function paused():Boolean;
    
    //EVENTS
    function triggerSeeked():void;

    function triggerLoadStart():void;

    function triggerPlaying():void;

    function triggerStopped():void;
    
    function getBufferLength():uint;

    //LOGGING
    function debug(message:Object):void;
    
	function error(message:Object):void;

}
}
