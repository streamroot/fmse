package com.streamroot {

import com.streamroot.events.VideoPlaybackEvent;

import flash.events.EventDispatcher;
import flash.events.NetStatusEvent;
import flash.events.TimerEvent;
import flash.media.Video;
import flash.net.NetConnection;
import flash.net.NetStream;
import flash.net.NetStreamAppendBytesAction;
import flash.utils.ByteArray;
import flash.utils.Timer;
import flash.utils.getTimer;

public class NetStreamWrapper extends EventDispatcher {

    private var _nc:NetConnection;
    private var _ns:NetStream;
    private var _throughputTimer:Timer;
    private var _currentThroughput:int = 0; // in B/sec
    private var _loadStartTimestamp:int;
    private var _loadStarted:Boolean = false;
    private var _loadCompleted:Boolean = false;
    private var _loadErrored:Boolean = false;
    private var _pauseOnStart:Boolean = false;
    private var _pausePending:Boolean = false;
    /**
     * The number of seconds between the logical start of the stream and the current zero
     * playhead position of the NetStream. During normal, file-based playback this value should
     * always be zero. When the NetStream is in data generation mode, seeking during playback
     * resets the zero point of the stream to the seek target. To recover the playhead position
     * in the logical stream, this value can be added to the NetStream reported time.
     *
     * @see http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/net/NetStream.html#play()
     */
    private var _startOffset:Number = 0;
    /**
     * If true, an empty NetStream buffer should be interpreted as the end of the video. This
     * is probably the case because the video data is being fed to the NetStream dynamically
     * through appendBuffer, not for traditional file download video.
     */
    private var _ending:Boolean = false;
    private var _videoReference:Video;

    /**
     * When the player is paused, and a seek is executed, the NetStream.time property will NOT update until the decoder encounters a new time tag,
     * which won't happen until playback is resumed. This wrecks havoc with external scrubber logic, so when the player is paused and a seek is requested,
     * we cache the intended time, and use it IN PLACE OF NetStream's time when the time accessor is hit.
     */
    private var _pausedSeekValue:Number = -1;

    private var _metadata:Object;
    private var _isPlaying:Boolean = false;
    private var _isPaused:Boolean = true;
    private var _isBuffering:Boolean = true;
    private var _isSeeking:Boolean = false;
    private var _isLive:Boolean = false;
    private var _canSeekAhead:Boolean = false;
    private var _hasEnded:Boolean = false;
    private var _canPlayThrough:Boolean = false;
    private var _durationOverride:Number;

    private var _fMSE:MSEPolyfill;

    public function NetStreamWrapper() {
        _metadata = {};
        _throughputTimer = new Timer(250, 0);
        _throughputTimer.addEventListener(TimerEvent.TIMER, onThroughputTimerTick);

        _fMSE = new MSEPolyfill(this);
    }

    public function get time():Number {
        if (_ns != null) {
            if (_pausedSeekValue != -1) {
                return _pausedSeekValue;
            }
            else {
                return _startOffset + _ns.time;
            }
        }
        else {
            return 0;
        }
    }

    public function getBufferLength():Number {
        if (_ns) {
            return _ns.bufferLength;
        } else {
            return -1;
        }
    }

    public function get duration():Number {
        if (_metadata != null && _metadata.duration != undefined) {
            return Number(_metadata.duration);
        } else if (_durationOverride && _durationOverride > 0) {
            return _durationOverride;
        }
        else {
            return 0;
        }
    }

    public function set duration(value:Number):void {
        _durationOverride = value;
    }

    public function get readyState():int {
        // if we have metadata and a known duration
        if (_metadata != null && _metadata.duration != undefined) {
            // if playback has begun
            if (_isPlaying) {
                // if the asset can play through without rebuffering
                if (_canPlayThrough) {
                    return 4;
                }
                // if we don't know if the asset can play through without buffering
                else {
                    // if the buffer is full, we assume we can seek a head at least a keyframe
                    if (_ns.bufferLength >= _ns.bufferTime) {
                        return 3;
                    }
                    // otherwise, we can't be certain that seeking ahead will work
                    else {
                        return 2;
                    }
                }
            }
            // if playback has not begun
            else {
                return 1;
            }
        }
        // if we have no metadata
        else {
            return 0;
        }
    }

    public function appendBytesAction(action:String):void {
        if (_ns) {
            _ns.appendBytesAction(action);
        }
    }

    public function appendBuffer(bytes:ByteArray):void {
        if (_ns) {
            _ns.appendBytes(bytes);
        } else {
            _fMSE.error("Error: netStream not ready")
        }
    }

    public function abort():void {
        // flush the netstream buffers
        _ns.seek(time);
    }

    public function get buffered():Number {
        if (_ns == null) {
            return _startOffset + _ns.bufferLength + _ns.time;
        } else if (duration > 0) {
            return (_ns.bytesLoaded / _ns.bytesTotal) * duration;
        } else {
            return 0;
        }
    }

    public function get playing():Boolean {
        return _isPlaying;
    }

    public function get paused():Boolean {
        return _isPaused;
    }

    public function get ended():Boolean {
        return _hasEnded;
    }

    public function get seeking():Boolean {
        return _isSeeking;
    }

    public function get metadata():Object {
        return _metadata;
    }

    public function load():void {
        _pauseOnStart = true;
        _isPlaying = false;
        _isPaused = true;

        initNetConnection();
    }

    public function play():void {
        // if this is a fresh playback request
        _fMSE.debug("entering play");
        if (!_loadStarted) {
            _pauseOnStart = false;
            _isPlaying = false;
            _isPaused = false;
            _metadata = {};
            initNetConnection();
            _fMSE.triggerPlay();
            _fMSE.loaded();
        }
        // if the asset is already loading
        else {
            _fMSE.loaded();
            if (_hasEnded) {
                _hasEnded = false;
                _ns.seek(0);
            }
            _pausePending = false;
            _ns.resume();
            _isPaused = false;
        }

        dispatchEvent(new VideoPlaybackEvent(VideoPlaybackEvent.ON_STREAM_START, {}));
    }

    public function pause():void {
        if (!_ns) {
            return;
        }

        _ns.pause();
        _fMSE.triggerPause();

        if (_isPlaying && !_isPaused) {
            _isPaused = true;
            if (_isBuffering) {
                _pausePending = true;
            }
        } else if (_hasEnded) {
            _fMSE.debug("pause: hasEnded");
            _hasEnded = false;
            _ns.seek(0);
        }
    }

    public function resume():void {
        if (_ns) {
            _fMSE.debug("entering resume");
            if (_isPlaying && _isPaused) {
                _fMSE.debug("resume");
                _ns.resume();
                _isPaused = false;
                _fMSE.triggerPlay();
            }
        } else {
            play();
        }
    }

    public function seekBySeconds(pTime:Number):void {
        _fMSE.debug('seek (flash)');
        _fMSE.debug(pTime);

        if (_isPlaying) {
            _isSeeking = true;
            _throughputTimer.stop();
            if (_isPaused) {
                _pausedSeekValue = pTime;
            }
        }
        else if (_hasEnded) {
            _isPlaying = true;
            _hasEnded = false;
        }

        _isBuffering = true;

        _startOffset = pTime;
        _fMSE.debug(_startOffset);
        _fMSE.debug(pTime);
        _ns.seek(pTime);
        _ns.appendBytesAction(NetStreamAppendBytesAction.RESET_SEEK);

    }

    public function stop():void {
        if (_isPlaying) {
            _ns.close();
            _isPlaying = false;
            _hasEnded = true;
            dispatchEvent(new VideoPlaybackEvent(VideoPlaybackEvent.ON_STREAM_CLOSE, {}));
            _throughputTimer.stop();
            _throughputTimer.reset();
        }
    }

    public function attachVideo(pVideo:Video):void {
        _videoReference = pVideo;
    }

    public function die():void {
        if (_videoReference) {
            _videoReference.attachNetStream(null);
        }

        if (_ns) {
            try {
                _ns.close();
                _ns = null;
            } catch (err:Error) {

            }
        }

        if (_nc) {
            try {
                _nc.close();
                _nc = null;
            } catch (err:Error) {

            }
        }

        if (_throughputTimer) {
            try {
                _throughputTimer.stop();
                _throughputTimer = null;
            } catch (err:Error) {

            }
        }
    }

    private function initNetConnection():void {
        // the video element triggers loadstart as soon as the resource selection algorithm selects a source
        // this is somewhat later than that moment but relatively close
        _loadStarted = true;

        if (_nc != null) {
            try {
                _nc.close();
            } catch (err:Error) {

            }
            _nc.removeEventListener(NetStatusEvent.NET_STATUS, onNetConnectionStatus);
            _nc = null;
        }

        _nc = new NetConnection();
        _nc.client = this;
        _nc.addEventListener(NetStatusEvent.NET_STATUS, onNetConnectionStatus);
        _nc.connect(null);
    }

    private function initNetStream():void {
        if (_ns != null) {
            _ns.close();
            _ns.removeEventListener(NetStatusEvent.NET_STATUS, onNetStreamStatus);
            _ns = null;
        }
        _ns = new NetStream(_nc);
        _ns.inBufferSeek = true;
        _ns.addEventListener(NetStatusEvent.NET_STATUS, onNetStreamStatus);
        _ns.client = this;
        _ns.bufferTime = .5;

        _ns.play(null);

        _videoReference.attachNetStream(_ns);

//        _pausePending = true;

        dispatchEvent(new VideoPlaybackEvent(VideoPlaybackEvent.ON_STREAM_READY, {ns: _ns}));
    }

    private function calculateThroughput():void {
        // if it's finished loading, we can kill the calculations and assume it can play through
        if (_ns.bytesLoaded == _ns.bytesTotal) {
            _canPlayThrough = true;
            _loadCompleted = true;
            _throughputTimer.stop();
            _throughputTimer.reset();
        }
        // if it's still loading, but we know its duration, we can check to see if the current transfer rate
        // will sustain uninterrupted playback - this requires the duration to be known, which is currently
        // only accessible via metadata, which isn't parsed until the Flash Player encounters the metadata atom
        // in the file itself, which means that this logic will only work if the asset is playing - preload
        // won't ever cause this logic to run :(
        else if (_ns.bytesTotal > 0 && _metadata != null && _metadata.duration != undefined) {
            _currentThroughput = _ns.bytesLoaded / ((getTimer() - _loadStartTimestamp) / 1000);
            var __estimatedTimeToLoad:Number = (_ns.bytesTotal - _ns.bytesLoaded) * _currentThroughput;
            if (__estimatedTimeToLoad <= _metadata.duration) {
                _throughputTimer.stop();
                _throughputTimer.reset();
                _canPlayThrough = true;
            }
        }
    }

    private function onNetConnectionStatus(e:NetStatusEvent):void {
        switch (e.info.code) {
            case "NetConnection.Connect.Success":
                initNetStream();
                break;
            case "NetConnection.Connect.Failed":

                break;
        }
        dispatchEvent(new VideoPlaybackEvent(VideoPlaybackEvent.ON_NETCONNECTION_STATUS, {info: e.info}));
    }

    private function onNetStreamStatus(e:NetStatusEvent):void {
        switch (e.info.code) {
            case "NetStream.Play.Start":
                _fMSE.debug("NetStream.Play.Start");
                _pausedSeekValue = -1;
                _metadata = null;
                _canPlayThrough = false;
                _hasEnded = false;
                _isBuffering = true;
                _currentThroughput = 0;
                _loadStartTimestamp = getTimer();
                _throughputTimer.reset();
                _throughputTimer.start();
                if (_pauseOnStart && _loadStarted == false) {
                    _ns.pause();
                    _isPaused = true;
                }
                else {
                    dispatchEvent(new VideoPlaybackEvent(VideoPlaybackEvent.ON_STREAM_START, {info: e.info}));
                }
                break;

            case "NetStream.SeekStart.Notify":
                appendBytesAction(NetStreamAppendBytesAction.RESET_SEEK);
                break;

            case "NetStream.Buffer.Full":
                //Now handled by function onBuffersReady, called by StreamrootInterface. NetStream would trigger this as soon as
                //audio OR video had been appended
                if (_isBuffering) {
                    _ns.pause();
                }
                break;

            case "NetStream.Buffer.Empty":
                // should not fire if ended/paused. issue #38
                onBufferEmpty(false);
                break;

            case "NetStream.Play.Stop":
                _isPlaying = false;
                _isPaused = true;
                _hasEnded = true;
                dispatchEvent(new VideoPlaybackEvent(VideoPlaybackEvent.ON_STREAM_CLOSE, {info: e.info}));

                _throughputTimer.stop();
                _throughputTimer.reset();
                break;

            case "NetStream.Seek.Notify":
                _isPlaying = true;
                _isSeeking = false;
                dispatchEvent(new VideoPlaybackEvent(VideoPlaybackEvent.ON_STREAM_SEEK_COMPLETE, {info: e.info}));
                _fMSE.triggerSeeked();
                _currentThroughput = 0;
                _loadStartTimestamp = getTimer();
                _throughputTimer.reset();
                _throughputTimer.start();
                break;

            case "NetStream.Play.StreamNotFound":
                _loadErrored = true;
                break;

            case "NetStream.Video.DimensionChange":
                dispatchEvent(new VideoPlaybackEvent(VideoPlaybackEvent.ON_VIDEO_DIMENSION_UPDATE, {videoWidth: _videoReference.videoWidth, videoHeight: _videoReference.videoHeight}));
                if (_metadata && _videoReference) {
                    _metadata.width = _videoReference.videoWidth;
                    _metadata.height = _videoReference.videoHeight;
                }
                break;
        }
        dispatchEvent(new VideoPlaybackEvent(VideoPlaybackEvent.ON_NETSTREAM_STATUS, {info: e.info}));
    }

    private function onThroughputTimerTick(e:TimerEvent):void {
        calculateThroughput();
    }

    public function onMetaData(duration:Number, width:Number = 0, height:Number = 0):void {
        _metadata = {};
        _metadata.duration = duration;
        if (width > 0 && height > 0) {
            _metadata.width = width;
            _metadata.height = height;
        }

        if (_metadata.duration) {
            _isLive = false;
            _canSeekAhead = true;
        }
        else {
            _isLive = true;
            _canSeekAhead = false;
        }
        dispatchEvent(new VideoPlaybackEvent(VideoPlaybackEvent.ON_META_DATA, {metadata: _metadata}));
    }

    //ADDED METHODS
    public function onBuffersReady():void {
        _pausedSeekValue = -1;
        _isPlaying = true;
        if (_pausePending) {
            _pausePending = false;
            _ns.pause();
            _isPaused = true;
        } else if (/*_isBuffering &&*/ !_isPaused) {
            _ns.resume();
        }
        _isBuffering = false;
    }

    public function onBufferEmpty(fromJS:Boolean):void {
        if (!_isPlaying) {
            return;
        }

        // reaching the end of the buffer after endOfStream has been called means we've
        // hit the end of the video
        if (_ending) {
            _ending = false;
            _isPlaying = false;
            _isPaused = true;
            _hasEnded = true;
            //TODO: commented next line because of argument e. Will probably cause issue at the end of video. Pass e
            //dispatchEvent(new VideoPlaybackEvent(VideoPlaybackEvent.ON_STREAM_CLOSE, {info: e.info}));

            _startOffset = 0;
            _pausedSeekValue = 0;
            return;
        }

        _isBuffering = true;

        if (fromJS) {
            _ns.pause();
        }
    }

    public function onStop():void {
        throw new Error("Method onStop isn't implemented");
    }
}
}
