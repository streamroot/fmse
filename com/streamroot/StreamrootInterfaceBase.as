package com.streamroot {

import flash.external.ExternalInterface;
import flash.net.NetStreamAppendBytesAction;

import flash.utils.ByteArray;

import com.streamroot.StreamrootMSE;

public class StreamrootInterfaceBase {

    private var _provider;//your provider
    private var _streamrootMSE:StreamrootMSE;

    private var _loaded:Boolean = false;

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
        //Method to call when provider is initialized and ready

        //you need to append the FLV Header to your provider, using appendBytesAction
        appendBuffer(_streamrootMSE.getFileHeader());

        if (!_loaded) {
            //Call javascript callback (implement window.sr_flash_ready that will initialize our JS library)
            ExternalInterface.call('sr_flash_ready');
            _loaded = true;
        }

        //Reset NetStream to the beginning of the stream (mostly useful on replay)

        triggerLoadStart();
    }

    private function appendBytesAction(action:String):void {
      //Calls method in provider that calls NetStream.appendBytesAction
      throw new Error("Method isn't implemented");
    }

    public function appendBuffer(bytes:ByteArray):void {
        //Calls method in provider that calls NetStream.appendBytes

        //If data needed, check if we have data in both video and audio buffer
        if (_needData && _streamrootMSE.areBuffersReady()) {
            bufferFull()
        }
    }

    private function onMetaData(duration:Number, width:Number=0, height:Number=0):void {
        //Called from JS. Passes metaData to flash player.
        var metaData:Object = new Object();
        metaData.duration = duration;
        if (width > 0 && height > 0) {
            metaData.width = width;
            metaData.height = height;
        }

        //Call method in provider that uses the metaData
    }

    public function areBuffersReady():Boolean {
        //Asks streamrrot stack if we have data in buffer for both audio and video
        return (_streamrootMSE.areBuffersReady())
    }

    private function bufferEmpty():void {
      //Calls methods in provider that deals with empty buffer. It should be what you call in "NetStream.Buffer.Empty" NetStream status event,
      //or in the case the buffer is low if you check buffer level at a regular interval
      throw new Error("Method isn't implemented");
    }

    private function bufferFull():void {
        //Calls methods in provider that deals with full buffer. It should be what you call in "NetStream.Buffer.Full" NetStream status event,
        //or in the case the buffer is full if you check buffer level at a regular interval
        //Also, the methods cited above should not be executed, and "NetStream.Buffer.Full" should call netStream.pause(), because it will fire when
        //one of the two tracks (audio/video) will have be bufferized enough

        //Set needData to false, as we don't want to check bufferReady at each append
        _needData = false;

        //Call provider method
      throw new Error("Method isn't implemented");
    }

    public function play():void {
      //Call provider's play method that wrapps NetStream's resume method. Shouldn't be needed if controls are in flash
      throw new Error("Method isn't implemented");

    }

    public function pause():void {
       //Call provider's pause method that wrapps NetStream's pause method. Shouldn't be needed if controls are in flash
      throw new Error("Method isn't implemented");
    }

    public function stop():void {
        //Call provider's stop method that wrapps NetStream's stop method. Shouldn't be needed for now
    }

    public function seek(time:Number):void {
        //Call provider's seek method that wrapps NetStream's seek method. Is needed even if controls are in flash. Flash controls
        //must call requestSeek below, and Javascript will in turn call the seek method. It is necessary to do it like this because
        //Javascript has the information to seek at a video KeyFrame

        //Set needData to true, because we'll need both audio and video data.
        _needData = true;

        //Tell streamrrot stack we've seekd, and pass the time.
        _streamrootMSE.setSeekOffset(time);

        //Call provider's seek method that wrapps NetStream's seek method. Shouldn't be needed if controls are in flash
      throw new Error("Method isn't implemented");
    }

    public function onTrackList(trackList:String):void {
        //Received track list from JS, to use for MBR button.
        //For now, we only implemented MBR for video track.
        //arg: tracklist is a String of the form "auto,720p,*540p,360p" (here *540p means track with label 540p is
        //currently selected).
        var trackListArray:Array = trackList.split(',');
        //need to be passed to the provider
      throw new Error("Method isn't implemented");
    }


    //GETTERS

    public function currentTime():Number {
        //Getter for current time. This time must be the actual playback time, not just netStream.time which will be offseted if we seek
        throw new Error("Method isn't implemented");
    }

    private function paused():Boolean {
        //Getter for paused property. It isn't a NetStream property, but you probably have implemented player states in your provider
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
