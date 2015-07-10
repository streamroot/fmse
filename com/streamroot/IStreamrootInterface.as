package com.streamroot {

import flash.utils.ByteArray;

public interface IStreamrootInterface {

    function loaded():void;

    function appendBytesAction(action:String):void;

    function appendBytes(bytes:ByteArray):void;

    function play():void;

    function pause():void;

    function seek(time:Number):void;

    function onTrackList(trackList:String):void;

    function onMetaData(duration:Number, width:Number=0, height:Number=0):void;

    function bufferEmpty():void;

    function bufferFull():void;

    function getBufferLength():Number;

    //GETTERS
    function currentTime():Number;

    function paused():Boolean;

    //EVENTS
    function triggerSeeked():void;

    function triggerPause():void;

    function triggerPlay():void;

    function triggerStopped():void;

    //NOTIFICATIONS
    function onStop():void;

    //LOGGING
    function debug(message:Object, emitter:Object = null):void;

    function error(message:Object, emitter:Object = null):void;
}
}
