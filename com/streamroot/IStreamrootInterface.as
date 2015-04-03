package com.streamroot {

import flash.external.ExternalInterface;
import flash.net.NetStreamAppendBytesAction;

import flash.utils.ByteArray;

import com.streamroot.StreamrootMSE;

public interface IStreamrootInterface {

    function loaded():void;
    
    function appendBytesAction(action:String):void;

    function appendBytes(bytes:ByteArray):void;

    function play():void;

    function pause():void;

    function stop():void;

    function seek(time:Number):void;

    function onTrackList(trackList:String):void;
    
    function onMetaData(duration:Number, width:Number=0, height:Number=0):void;
    
    function bufferEmpty():void;
    
    function bufferFull():void;
        
    //Should return NetStream buffer length, ie the max length of the different buffers, or -1 if NetStream is not yet initialized
    function getBufferLength():Number;
    
    //GETTERS
    function currentTime():Number;

    function paused():Boolean;
    
    //EVENTS
    function triggerSeeked():void;

    function triggerLoadStart():void;
    
    function triggerPause():void;

    function triggerPlay():void;

    function triggerStopped():void;

    //NOTIFICATIONS

    function onStop():void;

    //LOGGING
    function debug(message:Object):void;
    
	function error(message:Object):void;

}
}
