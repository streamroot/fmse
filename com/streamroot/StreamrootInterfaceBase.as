package com.streamroot {

import flash.external.ExternalInterface;
import flash.net.NetStreamAppendBytesAction;

import flash.utils.ByteArray;

import com.streamroot.StreamrootMSE;

public class StreamrootInterfaceBase {

    private var _provider;
    private var _streamrootMSE:StreamrootMSE;

    private var _needData:Boolean = true;
    //private var _wantToPlay:Boolean = false; //Always false as autoplay is handled in JS

    private var _LOG_DEBUG:Boolean = false;
    private var _LOG_ERROR:Boolean = true;


    public function StreamrootInterface(provider):void {
        //Your provider. You'll need to change the type in variable and argument definition
        _provider = provider;

        //Adding external interface for Javascript. Exposed method names need to stay the same

        //METHODS
        ExternalInterface.addCallback("onMetaData", onMetaData)

        ExternalInterface.addCallback("play", play);
        ExternalInterface.addCallback("pause", pause);
        ExternalInterface.addCallback("stop", stop);
        ExternalInterface.addCallback("seek", seek);

        ExternalInterface.addCallback("bufferEmpty", bufferEmpty);
        ExternalInterface.addCallback("bufferFull", bufferFull);

        ExternalInterface.addCallback("onTrackList", onTrackList);


        //GETTERS
        ExternalInterface.addCallback("currentTime", currentTime);
        ExternalInterface.addCallback("paused", paused);


        //Initializing Streamroot stack
        _streamrootMSE = new StreamrootMSE(this);
    }

    public function loaded():void {
      throw new Error("Method isn't implemented");
    }

    private function appendBytesAction(action:String):void {
      throw new Error("Method isn't implemented");
    }

    public function appendBuffer(bytes:ByteArray):void {
      throw new Error("Method isn't implemented");
    }

    private function onMetaData(duration:Number, width:Number=0, height:Number=0):void {
      throw new Error("Method isn't implemented");
    }

    public function areBuffersReady():Boolean {
        //Asks streamrrot stack if we have data in buffer for both audio and video
        return (_streamrootMSE.areBuffersReady())
    }

    private function bufferEmpty():void {
      throw new Error("Method isn't implemented");
    }

    private function bufferFull():void {
      throw new Error("Method isn't implemented");
    }

    public function play():void {
      throw new Error("Method isn't implemented");

    }

    public function pause():void {
      throw new Error("Method isn't implemented");
    }

    public function stop():void {

    }

    public function seek(time:Number):void {
      throw new Error("Method isn't implemented");
    }

    public function onTrackList(trackList:String):void {
      throw new Error("Method isn't implemented");
    }


    //GETTERS

    public function currentTime():Number {
        throw new Error("Method isn't implemented");
    }

    private function paused():Boolean {
        throw new Error("Method isn't implemented");
    }

    //EVENTS
    public function triggerSeeked():void {
        //Trigger event when seek is done. Not used for now
        ExternalInterface.call("sr_flash_seeked");
    }

    public function triggerLoadStart():void {
        //Trigger event when we want to start loading data (at the beginning of the video or on replay)
        ExternalInterface.call("sr_flash_loadstart");
    }

    public function triggerPlaying():void {
        //Trigger event when video starts playing. Not used for now
        ExternalInterface.call("sr_flash_playing");
    }

    public function triggerStopped():void {
        //Trigger event when video ends.
        ExternalInterface.call("sr_flash_stopped");
    }


    //LOGGING
    public function debug(message):void {
        if (_LOG_DEBUG) {
            ExternalInterface.call("console.debug", String(message));
        }
    }

    public function error(message):void {
        if (_LOG_ERROR) {
            ExternalInterface.call("sr_flash_transcodeError");
        }
    }

}
}
