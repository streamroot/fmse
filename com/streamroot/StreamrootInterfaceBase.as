package com.streamroot {

  import flash.net.NetStreamAppendBytesAction;

  import flash.utils.ByteArray;

  import com.streamroot.StreamrootMSE;
  import com.streamroot.IStreamrootInterface;

  public class StreamrootInterfaceBase implements IStreamrootInterface{

    protected var _provider:Object;//your provider - must be an IProvider implementation;
    protected var _streamrootMSE:StreamrootMSE;


    /**
    * StreamrootInterfaceBase constructor
    *
    * @param  {Object} provider - Your provider. You'll need to change the type in variable and argument definition
    */
    public function StreamrootInterfaceBase(provider:Object):void {
      _provider = provider;
      _streamrootMSE = new StreamrootMSE(this);
    }

    //METHOD YOU NEED TO IMPLEMENT

    /**
    * getBufferLength
    * Should call method in provider that return NetStream.bufferLength, or -1 if NetStream is not yet initialized
    *
    * @return {Number}  - Netstream.bufferLength, or -1 if NetStream is not yet initialized
    */
    public function getBufferLength():Number {
        throw new Error("Method getBufferLength isn't implemented");
    }

    /**
    * appendBytesAction
    * Should call method in provider that calls NetStream.appendBytesAction
    *
    * @param  {String} action - The NetStream action that need to be appended
    */
    public function appendBytesAction(action:String):void {
        throw new Error("Method appendBytesAction isn't implemented");
    }

    /**
    * appendBytes
    * Should call method in provider that calls NetStream.appendBytes
    *
    * @param  {ByteArray} bytes - The bytes you want to append in NetStream
    */
    public function appendBytes(bytes:ByteArray):void {
        throw new Error("Method appendBytes is not implemented");
    }

    /**
    * onMetaData
    * Call method in provider that uses the metaData
    *
    * @param  {Number} duration - Duraiton of your video
    * @param  {Number} width - Optional : width of your video, or 0 if not specify
    * @param  {Number} height - Optional : height of your video, or 0 if not specify
    */
    public function onMetaData(duration:Number, width:Number=0, height:Number=0):void {
        throw new Error("Method onMetaData isn't implemented");
    }

    /**
    * bufferEmpty
    * Replace "NetStream.Buffer.Empty" event
    */
    public function bufferEmpty():void {
        throw new Error("Method bufferEmpty isn't implemented");
    }

    /**
    * bufferFull
    * Replace the event "NetStream.Buffer.Full"
    * Please note that "NetStream.Buffer.Full" event will be triggered when AT LEAST ONE buffer (ie video/audio) has data,
    * where as this method will be executed when ALL buffers have data
    * As a consequence, on the event "NetStream.Buffer.Full" you should called NetStream.pause(),
    * and play the video only when this method is executed
    */
    public function bufferFull():void {
        throw new Error("Method bufferFull is not implemented");
    }

    /**
    * play
    * Call provider's play method that wrapps NetStream's resume method, or NetStream's play method if you launch the video for the first time
    * NOT NEEDED IF CONTROLS ARE IN FLASH
    */
    public function play():void {
        throw new Error("Method play isn't implemented");
    }

    /**
    * pause
    * Call provider's pause method that wrapps NetStream's pause method
    * NOT NEEDED IF CONTROLS ARE IN FLASH
    */
    public function pause():void {
        throw new Error("Method pause isn't implemented");
    }

    /**
    * stop
    * Not used for now
    */
    public function stop():void {
        throw new Error("Method stop isn't implemented");
    }

    /**
    * seek
    * Call provider's seek method that wrapps NetStream's seek method.
    * Is needed even if controls are in flash. Indeed, before you seek you need to get the first keyframe after the time you want to seek on.
    * This operation can only be done in javascript. So if your control are in flash, you first need to trigger requestSeek method (see below)
    * and then the seek will be trigger from javascript with this method.
    *
    * @see requestSeek(time:Number)
    * @param  {Number} time - time (in second) of the keyframe you need to seek on
    */
    public function seek(time:Number):void {
        throw new Error("Method seek isn't implemented");
    }

    /**
    * requestSeek
    * NEEDED ONLY IF CONTROLS ARE IN FLASH
    * Before seeking at a specific time, you first need to get the first keyframe after that time. This operation must be done in javascript.
    * (We don't have keyframe information in flash).
    * So if your control are in flash, you need to ask for the seek to the javascript with this method.
    * Javascript will then trigger the flash seek method with the time corresponding to the first keyframe
    * after the time you want to seek on.
    *
    * @see seek(time:Number)
    * @param  {Number} time - time (in second) where you want to seek on
    */
    public function requestSeek(time:Number):void {
        _streamrootMSE.requestSeek(time);
    }

    /**
    * onTrackList
    * Received track list from JS, to use for MBR button.
    * For now, we only implemented MBR for video track.
    *
    * @see requestQualityChange(quality:Number)
    * @param  {String} trackList - String of the form "auto,720p,*540p,360p", where *540p means track with label 540p is currently selected
    */
    public function onTrackList(trackList:String):void {
        throw new Error("Method onTrackList isn't implemented");
    }

    /**
    * requestQualityChange
    * NEEDED ONLY IF CONTROLS ARE IN FLASH
    * Call this method when quality change has been requested manually from the MBR button.
    * It will change the selected track in our javascript module
    *
    * @see onTrackList(trackList:String)
    * @param  {Number} quality - Number matching the index of the track in the tracklist passed in onTrackedList.
    *                            The example above we would pass 0 for auto, 1 for 720p, 2 for 540p and so on.
    */
    public function requestQualityChange(quality:Number):void {
        _streamrootMSE.requestQualityChange(quality);
    }

    //GETTERS

    /**
    * currentTime
    * Getter for current time
    * This time must be the actual playback time, not just netStream.time which will be offseted if we seek
    *
    * @return {Number} - playback time
    */
    public function currentTime():Number {
        throw new Error("Method currentTime isn't implemented");
    }

    /**
    * paused
    * Getter for paused property
    * It isn't a NetStream property, but you probably have implemented player states in your provider
    *
    * @return {Boolean} - true if the video is paused, false if not
    */
    public function paused():Boolean {
        throw new Error("Method paused isn't implemented");
    }

    //EVENTS

    /**
    * loaded
    * Trigger this event when your provider is initialized and ready
    */
    public function loaded():void {
        _streamrootMSE.loaded();
    }

    /**
    * triggerSeeked
    * Trigger this event when you catch the code NetStream.Seek.Notify of your NetStream object
    */
    public function triggerSeeked():void {
        _streamrootMSE.triggerSeeked();
    }

    /**
    * triggerLoadStart
    * Trigger this event only when you replay the video
    * DEPRECATED - You should use loaded method instead
    *
    * @see loaded()
    */
    public function triggerLoadStart():void {
        _streamrootMSE.triggerLoadStart();
    }

    /**
    * triggerPlay
    * Trigger this event when video starts playing for the first time or when the video resume after it has been paused
    */
    public function triggerPlay():void {
        _streamrootMSE.triggerPlay();
    }

    /**
    * triggerPause
    * Trigger this event when video pauses. Used for analytics
    */
    public function triggerPause():void {
        _streamrootMSE.triggerPause();
    }

    /**
    * triggerStopped
    * Trigger this event when video ends.
    */
    public function triggerStopped():void {
        _streamrootMSE.triggerStopped();
    }

    //NOTIFICATIONS

    /**
     * onStop
     * Your event handler for the Stop notification
     */
    public function onStop():void {
        throw new Error("Method onStop isn't implemented");
    };

    //LOGGING

    /**
    * debug
    * Use to print debug message in your browser console
    * It is not compulsory to pass a string, but the object will be converted in a string (so you can pass a Number for example)
    * If you pass the object "this" to the second argument, it will also print the name of the class that emitted the message.
    *
    * @param  {Object} message - Message you want to display
    * @param  {Object} class   - Optional : the object that emmitted the message
    */
    public function debug(message:Object, emitter:Object = null):void {
      _streamrootMSE.debug(message);
    }

    /**
    * error
    * Use to print error message in your browser console
    * It is not compulsory to pass a string, but the object will be converted in a string (so you can pass a Number for example)
    * If you pass the object "this" to the second argument, it will also print the name of the class that emitted the message.
    *
    * @param  {Object} message - Message you want to display
    * @param  {Object} class   - Optional : the object that emmitted the message
    */
    public function error(message:Object, emitter:Object = null):void {
      _streamrootMSE.error(message);
    }

  }
}
