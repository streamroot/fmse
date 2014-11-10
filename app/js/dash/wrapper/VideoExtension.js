"use strict";

var conf = require('../../../conf');
var FlashMBR = require('./FlashMBR');

var VideoExtension = function (mediaController, swfObj) {

    var self = this,
        
        //TODO: remove _currentTime property stuff
        //_currentTime = 0,

        _swfObj = swfObj,

        _mediaSource,
        _sourceBuffers = [],
        
        _eventHandlers, //Event handlers for wrappers
        
        _currentTime = 0,
        _fixedCurrentTime = 0,  //In case of video paused or buffering
        _seekTarget,    // Using another variable for seeking, because seekTarget can be set to undefined by "playing" event (TODO: triggered during seek, which is a separate issue) 
        _lastCurrentTimeTimestamp,
        _REFRESH_INTERVAL = 500,    //Max interval until we look up flash to get real value of currentTime


        _listeners = [],
        
        _ended = false,
        _seekedTimeout,

        _isInitialized = function () {
            return (typeof _swfObj !== 'undefined');
        },

        _seeking = false, //TODO: still in use?


        _addEventListener 	= function(type, listener){
            if (!_listeners[type]){
                _listeners[type] = [];
            }
            _listeners[type].unshift(listener);
        },

        _removeEventListener = function(type, listener){
            //Same thing as MediaSourceFlash. Though splice should modify in place, and it should wok. But why return? Get out of the loop?
            var listeners = _listeners[type],
                i = listeners.length;
            while (i--) {
                if (listeners[i] === listener) {
                    return listeners.splice(i, 1);
                }
            }
        },

        _trigger 			= function(event){
            //updateend, updatestart
            var listeners = _listeners[event.type] || [],
                i = listeners.length,
                onName = 'on' + event.type;
            while (i--) {
                listeners[i](event);
            }
            //Experimental. for onseeked, etc...
            //TODO: put in all classes / encapsulate eventBus
            if (self[onName] && getClass.call(self[onName]) == '[object Function]') {
                self[onName](event);
            }
        },
        
        _addMetaData = function () {
            //Sends meta data to flash player
            
            //TODO: here, durqtion for period[0]. Should maybe have method getDuration() (same method, without arg) returning the sum of all period's durations.
            var duration = mediaController.manifestManager.getDuration(0),
                videoDimensions = mediaController.getVideoDimensions();
            
            //TODO: could send width, height, too
            _swfObj.onMetaData(duration, videoDimensions.width, videoDimensions.height);         
        },
        
        _setEventHandlers = function (eventHandlers) {
            var onMetaData = eventHandlers.onMetaData,
                onBuffering = eventHandlers.onBuffering,
                newOnMetaData,
                newOnBuffering;
            
            if (typeof onMetaData === "undefined") {
                var flashMBR = new FlashMBR(mediaController, _swfObj);
                onMetaData = flashMBR.addTrackList;
            }
                
            newOnMetaData = function (tracklist) {
                onMetaData(tracklist);
                _addMetaData();
            };

            newOnBuffering = function () {
                onBuffering();
                _bufferEmpty();
            };
            
            
            eventHandlers.onMetaData = newOnMetaData;
            eventHandlers.onBuffering = newOnBuffering;
            //eventHandlers.onPlaying = newOnPlaying;
            _eventHandlers = eventHandlers;
        },    

        _play = function () {
            if (_isInitialized()) {
                _fixedCurrentTime = undefined;                
                _swfObj.play();
            } else {
                //TODO: implement exceptions similar to HTML5 one, and handle them correctly in the code
                new Error('Flash video is not initialized'); //TODO: should be "throw new Error(...)" but that would stop the execution
            }
        },

        _pause= function () {
            if (_isInitialized()) {
                if (typeof _fixedCurrentTime === "undefined") { //Don't override _fixedCurrentTime if it already exists (case of a seek for example);
                    _fixedCurrentTime = _getCurrentTimeFromFlash();
                }
                _swfObj.pause();
            } else {
                //TODO: implement exceptions similar to HTML5 one, and handle them correctly in the code
                new Error('Flash video is not initialized'); //TODO: should be "throw new Error(...)" but that would stop the execution
            }
        },

        _stop = function () {
            if (_isInitialized()) {
                _swfObj.stop();
            } else {
                //TODO: implement exceptions similar to HTML5 one, and handle them correctly in the code
                new Error('Flash video is not initialized'); //TODO: should be "throw new Error(...)" but that would stop the execution
            }
        },

        _seek = function (time) {
            if(!_seeking) {
                var keyFrameTime,
                    audioOffset;
                _seekedTimeout = setTimeout(_onSeeked, 1000);
                if (_isInitialized()) {
                    
                    keyFrameTime = _getPrecedingKeyFrame(time);

                    //useles in hls because video and audio are muxed
                    audioOffset = _getSeekAudioOffset(keyFrameTime); //Needs to be keyFrameTime (actual seek time with flash) and not time
                    
                    //HACK for mediaSourceTrigger. +args?
                    //trigger flush of sourceBufferWrapper. It's a hack because shouldn't be triggered by mediaSource
                    //_mediaSource.trigger({type: 'seeking'});
                    
                    console.info("seeking");
                    self.trigger({type: 'seeking'});
                    _seeking = true;
                    
                    //Rapid fix. Check if better way
                    for (var i=0; i<_sourceBuffers.length; i++) {
                        _sourceBuffers[i].seeking(keyFrameTime, audioOffset);
                    }

                    _seekTarget = _fixedCurrentTime = keyFrameTime;

                    //The flash is flushed somewhere in this seek function
                    _swfObj.seek(keyFrameTime/*, time*/);
                } else {
                    //TODO: implement exceptions similar to HTML5 one, and handle them correctly in the code
                    new Error('Flash video is not initialized'); //TODO: should be "throw new Error(...)" but that would stop the execution
                }
            }
        },
        
        _getCurrentTimeFromFlash = function () {
            _currentTime = _swfObj.currentTime();
            return _currentTime;
        },
        
        _getCurrentTime = function () {
            var now = new Date().getTime();
            
            if (_ended) {
                return 0;
            }
            
            if (typeof _seekTarget !== "undefined") {
                return _seekTarget;
            }
                
            if (typeof _fixedCurrentTime !== "undefined") {
                return _fixedCurrentTime;
            }
            
            if (_lastCurrentTimeTimestamp && now - _lastCurrentTimeTimestamp < _REFRESH_INTERVAL) {
                return _currentTime + (now - _lastCurrentTimeTimestamp) / 1000;
            } else if (_isInitialized()) {
                _lastCurrentTimeTimestamp = now;
                return _getCurrentTimeFromFlash();
            }
            return 0;
        },
        
        _getPaused = function () {
            if (_isInitialized()) {
                return _swfObj.paused();
            } else {
                //TODO: implement exceptions similar to HTML5 one, and handle them correctly in the code
                new Error('Flash video is not initialized'); //TODO: should be "throw new Error(...)" but that would stop the execution
            }
        },
        
        _getPrecedingKeyFrame = function (time) {
            var videoTrack =  mediaController.currentTracks["video"],
                segment = mediaController.manifestManager.getPartForTime(mediaController.currentPeriod, time, videoTrack.id_aset, videoTrack.id_rep).segment;
            return segment.time;
        },
        
        _getSeekAudioOffset = function (time) {
            var audioTrack =  mediaController.currentTracks["audio"],
                segment;
            if (audioTrack) {
                segment = mediaController.manifestManager.getPartForTime(mediaController.currentPeriod, time, audioTrack.id_aset, audioTrack.id_rep);
                segment = mediaController.manifestManager.getNextSegment(segment);
                return segment.segment.time;
            }
        },
        
        _bufferEmpty = function () {
            _fixedCurrentTime = _fixedCurrentTime || _getCurrentTimeFromFlash(); // Do not erase value if already set
            _swfObj.bufferEmpty();
            _watchBuffer();
        },
        
        _bufferFull = function () {
            if (!_getPaused()) {
				_fixedCurrentTime = undefined;
			}
            _swfObj.bufferFull();
        },
        
        _watchBuffer = function () {
            var watchBufferInterval = setInterval(function(){
                var currentTime = _getCurrentTime(),
                    buffered,
                    buffersReady = _sourceBuffers.length,
                    i;
                for (i=0; i<_sourceBuffers.length; i++) {
                    buffered = _sourceBuffers[i].buffered;
                    if (buffered.length) {
                        buffersReady = buffersReady && (buffered.end(0) - currentTime > conf.BUFFER.EMERGENCY_MARGIN + 0.5);
                    } else {
                        buffersReady = false;
                    }
                }
                
                if (buffersReady) {
                    clearInterval(watchBufferInterval);
                    _bufferFull();
                }
                
            }, 100);
        },
        
        //EVENTS
        
        _onSeeked = function() {
            _seeking = false;
            _seekTarget = undefined;
            clearTimeout(_seekedTimeout);
            self.trigger({type: 'seeked'}); //trigger with value _fixedCurrentTime
            for (var i = 0; i < _sourceBuffers.length; i++) {
                        _sourceBuffers[i].seeked();
            }
        },
        
        _onLoadStart = function() {
            _ended = false;
            self.trigger({type: 'loadstart'});
        },
        
        _onPlaying = function() {
            _currentTime = _getCurrentTimeFromFlash(); //Force refresh _currentTime
            _fixedCurrentTime = undefined;
            
            _ended = false;
            self.trigger({type: 'playing'});
        },
        
        _onStopped = function() {
            var i;
            
            _ended = true;
            _currentTime = 0;
            
            self.trigger({type: 'ended'});
            
            for (i=0; i<_sourceBuffers.length; i++) {
                _sourceBuffers[i].seekTime(0); //Sets start and end to 0 in source buffer
            }
        },

        _initialize = function () {        
            _watchBuffer();
            
            window.sr_request_seek = function(time) {
                _seek(time);
            };
            
            window.sr_flash_seeked = function () {
                _onSeeked();
            };
            
            window.sr_flash_loadstart = function () {
                _onLoadStart();
            };
            
            window.sr_flash_playing = function () {
                _onPlaying();
            };
            
            window.sr_flash_stopped = function () {
                _onStopped();
            };

            window.updateend = function() {
                for (var i=0; i<_sourceBuffers.length; i++) {
                    _sourceBuffers[i].trigger({type:'updateend'});
                }
            };
        };

    this.createSrc = function (mediaSourceFlash) {
        _mediaSource = mediaSourceFlash;
        
        //Global access for debugging
        //window.SWFOBJ = _swfObj;
    };

    this.play = function () {
        _play();
    };

    this.pause = function () {
        _pause();
    };

    //TODO: What's this stop method? Doesn't exist in HT:L5 video spec, and I didn't see it implemented in flash interface
    this.stop = function () {
        _stop();
    };

    Object.defineProperty(this, "currentTime", {
        get: _getCurrentTime,
        set: function (time) { _seek(time); }
    });
    
    Object.defineProperty(this, "seeking", {
        get: function () { return _seeking; },
        set: undefined
    });
    
    Object.defineProperty(this, "paused", {
        get: _getPaused,
        set: undefined
    });
    
    //Did this weird structure because event_handlers is set in dash.js after VideoExtension is created. But we need both to send metaData to flash player (from inside this class), and to
    //call the wrapper's event_handler. Then we need to combine both steps into the video.event_handlers.onMetaData method, and do everything from inside this class in order not to impact the rest
    //of the code with the switch HTML5 / Flash
    Object.defineProperty(this, "event_handlers", {
        get: function () { return _eventHandlers; },
        set: function (eventHandlers) { _setEventHandlers(eventHandlers); }
    });

    this.addEventListener = function (type, listener) {
        _addEventListener(type, listener);
    };

    this.trigger = function (event) {
        _trigger(event);
    };


    this.registerSourceBuffer = function (sourceBuffer) {
        _sourceBuffers.push(sourceBuffer);
        //TODO: register source buffer in there for sourceBufferEvents
    };
    
    this.getSwf = function () {
        return _swfObj;
    };

    //TODO:register mediaSource and video events

    //TODO: create global methods for flash events here, and dispatch events to registered MediaSource, SourceBuffers, etc...

    _initialize();
};

module.exports = VideoExtension;
