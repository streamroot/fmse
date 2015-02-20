package com.streamroot {

import flash.external.ExternalInterface;
import flash.net.NetStreamAppendBytesAction;

import flash.utils.ByteArray;

import com.streamroot.StreamrootMSE;
import com.streamroot.IStreamrootInterface;


public class StreamrootInterfaceBase implements IStreamrootInterface{

    protected var _provider:Object;//your provider - must be an IProvider implementation;
    protected var _streamrootMSE:StreamrootMSE;

    protected var _loaded:Boolean = false;

    protected var _needData:Boolean = true;

    protected var _LOG_DEBUG:Boolean = false;
    protected var _LOG_ERROR:Boolean = true;


    public function StreamrootInterfaceBase(provider:Object):void {
        //Your provider. You'll need to change the type in variable and argument definition
        _provider = provider;

        //Initializing Streamroot stack
        _streamrootMSE = new StreamrootMSE(this);
        
        //Some of following methods are called from javascript through ExternalInterface callback.
        //All these callbacks are set in StreamRootMSE
    }
    
    public function getBufferLength():Number {
        //Should call method in provider that return NetStream.bufferLength
        throw new Error("Methode getTimeLeftToPlay isn't implemented");
    }

    public function loaded():void {
        //Method to call when provider is initialized and ready

        //you need to append the FLV Header to your provider, using appendBytesAction
        appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN)
        appendBuffer(_streamrootMSE.getFileHeader());

        if (!_loaded) {
            //Call javascript callback (implement window.sr_flash_ready that will initialize our JS library)
            //Do not call on replay, as it would initialize a second instance of our JS library (that's why the
            //_loaded Boolean is for here)
            ExternalInterface.call('sr_flash_ready');
            _loaded = true;
        }

        //Tell our Javascript library to start loading video segments
        triggerLoadStart();
    }

    protected function appendBytesAction(action:String):void {
      //Should call method in provider that calls NetStream.appendBytesAction
      throw new Error("Method appendBytesAction isn't implemented");
    }

    public function appendBuffer(bytes:ByteArray):void {
        //Should call method in provider that calls NetStream.appendBytes
        throw new Error("Method appendBuffer is not implemented");
    }

    public function onMetaData(duration:Number, width:Number=0, height:Number=0):void {
        //Call method in provider that uses the metaData
        throw new Error("Method onMetaData isn't implemented");
    }

    /*public function areBuffersReady():Boolean {
        //Asks streamrrot stack if we have data in buffer for both audio and video
        return (_streamrootMSE.areBuffersReady());
    }*/

    public function bufferEmpty():void {
      //Calls methods in provider that deals with empty buffer. It should be what you call in "NetStream.Buffer.Empty" NetStream status event,
      //or in the case the buffer is low if you check buffer level at a regular interval
      throw new Error("Method bufferEmpty isn't implemented");
    }

    public function bufferFull():void {
        //Calls the provider method to be executed in case of full buffer. It should be what you used to
        //call in "NetStream.Buffer.Full" NetStream status event, or your equivalent if you check buffer
        //level using a timer.
        //This provider method should not be executed in any other situation, and "NetStream.Buffer.Full"
        //should call netStream.pause(), because in case of separate audio / video tracks it will fire
        //when only one of the two tracks will have be bufferized enough.
        
        throw new Error("Method bufferFull is not implemented");
        //You should call your provider's onBufferFull method after super
    }

    public function play():void {
      //Call provider's play method that wrapps NetStream's resume method. Shouldn't be needed if controls are in flash
      throw new Error("Method play isn't implemented");

    }

    public function pause():void {
       //Call provider's pause method that wrapps NetStream's pause method. Shouldn't be needed if controls are in flash
      throw new Error("Method pause isn't implemented");
    }

    public function stop():void {
        //Call provider's stop method that wrapps NetStream's stop method. Shouldn't be needed for now
        throw new Error("Method stop isn't implemented");
    }

    public function seek(time:Number):void {
        //Call provider's seek method that wrapps NetStream's seek method. Is needed even if controls are in flash. Flash controls
        //must call requestSeek below, and Javascript will in turn call the seek method. It is necessary to do it like this because
        //Javascript has the information to seek at a video KeyFrame

        //Tell streamrrot stack we've seeked, and pass the time.
        _streamrootMSE.setSeekOffset(time);

        //You should call provider's seek method that wrapps NetStream's seek method, after super. Shouldn't be needed if controls are in flash
    }

    public function onTrackList(trackList:String):void {
        //Received track list from JS, to use for MBR button.
        //For now, we only implemented MBR for video track.
        //
        //@tracklist: String of the form "auto,720p,*540p,360p" (here *540p means track with label 540p
        //is currently selected).
        
        throw new Error("Method onTrackList isn't implemented");
    }


    //GETTERS

    public function currentTime():Number {
        //Getter for current time. This time must be the actual playback time, not just netStream.time which will be offseted if we seek
        throw new Error("Method currentTime isn't implemented");
    }

    public function paused():Boolean {
        //Getter for paused property. It isn't a NetStream property, but you probably have implemented player states in your provider
        throw new Error("Method paused isn't implemented");
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
    public function debug(message:Object):void {
        if (_LOG_DEBUG) {
            ExternalInterface.call("console.debug", String(message));
        }
    }

    public function error(message:Object):void {
        if (_LOG_ERROR) {
            ExternalInterface.call("sr_flash_transcodeError", String(message));
        }
    }

}
}
