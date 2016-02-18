"use strict";

var CustomTimeRange = require('../utils/CustomTimeRange');
var MediaSourceFlash = require('./MediaSourceFlash');

var VideoExtension = function(swfObj) {

    var self = this,

    _swfObj = swfObj,

    _mediaSource,
    _sourceBuffers = [],

    _eventHandlers, //Event handlers for wrappers

    _currentTime = 0,
    _fixedCurrentTime = 0, //In case of video paused or buffering
    _seekTarget, // Using another variable for seeking, because seekTarget can be set to undefined by "playing" event (TODO: triggered during seek, which is a separate issue)
    _lastCurrentTimeTimestamp,
    _REFRESH_INTERVAL = 2000, //Max interval until we look up flash to get real value of currentTime

    _listeners = [],

    _ended = false,
    //_buffering = true,
    //_paused = false,
    _seeking = false,
    _seekedTimeout,

    // atm we don't handle the case when Flash is not ready yet
    _isFlashReady = true,
    _propertyCache = {}, // the values from the setters
    _actionsCache = [], // the callbacks to execute (in order)
    _buffered = new CustomTimeRange(),

    _isInitialized = function() {
        return (typeof _swfObj !== 'undefined');
    },

    _addEventListener = function(type, listener) {
        if (!_listeners[type]) {
            _listeners[type] = [];
        }
        _listeners[type].unshift(listener);
    },

    _removeEventListener = function(type, listener) {
        //Same thing as MediaSourceFlash. Though splice should modify in place, and it should wok. But why return? Get out of the loop?
        var listeners = _listeners[type],
            i = listeners.length;
        while (i--) {
            if (listeners[i] === listener) {
                return listeners.splice(i, 1);
            }
        }
    },

    _trigger = function(event) {
        //updateend, updatestart
        var listeners = _listeners[event.type] || [],
            i = listeners.length;
        while (i--) {
            listeners[i](event);
        }
    },

    _savePropertyValueToCache = function(property, value) {
        _propertyCache[property] = value;
    },

    _setPropertiesFromCache = function() {
        Object.keys(_propertyCache).forEach(function(key) {
            key.set(_propertyCache[key]);
        });
    },

    _saveActionToCache = function(callback) {
        _actionsCache.push(callback);
    },

    _executeActionsFromCache = function() {
        for(var i = 0; i < _actionsCache.length; i++) {
            var action = _actionsCache[i];
            action();
        }
    },

    _play = function() {
        if (!_isFlashReady) {
            _saveActionToCache(_play);
            return;
        }

        if (_isInitialized()) {
            _fixedCurrentTime = undefined;
            _swfObj.play();
        } else {
            //TODO: implement exceptions similar to HTML5 one, and handle them correctly in the code
            new Error('Flash video is not initialized'); //TODO: should be "throw new Error(...)" but that would stop the execution
        }
    },

    _pause = function() {
        if (!_isFlashReady) {
            _saveActionToCache(_play);
            return;
        }

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

    _seek = function(time) {
        if (!_seeking) {
            _seekedTimeout = setTimeout(_onSeeked, 5000);
            if (_isInitialized()) {

                console.info("seeking");
                self.trigger({
                    type: 'seeking'
                });
                _seeking = true;

                //Rapid fix. Check if better way
                for (var i = 0; i < _sourceBuffers.length; i++) {
                    _sourceBuffers[i].seeking(time);
                }

                _seekTarget = _fixedCurrentTime = time;

                //The flash is flushed somewhere in this seek function
                _swfObj.seek(time);
            } else {
                //TODO: implement exceptions similar to HTML5 one, and handle them correctly in the code
                new Error('Flash video is not initialized'); //TODO: should be "throw new Error(...)" but that would stop the execution
            }
        }
    },

    _getCurrentTimeFromFlash = function() {
        _currentTime = _swfObj.currentTime();
        return _currentTime;
    },

    _getCurrentTime = function() {
        if (!_isFlashReady) {
            return undefined;
        }

        var now = new Date().getTime();

        if (_ended) {
            return _mediaSource.duration;
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

    _getPaused = function() {
        if (!_isFlashReady) {
            return undefined;
        }

        if (_isInitialized()) {
            return _swfObj.paused();
        } else {
            //TODO: implement exceptions similar to HTML5 one, and handle them correctly in the code
            new Error('Flash video is not initialized'); //TODO: should be "throw new Error(...)" but that would stop the execution
        }
    },

    _getBuffered = function() {
        return _buffered;
    },

    _getPlayed = function() {
        // TODO: return normalized TimeRange here according to MediaElement API

        return [];
    },

    //EVENTS
    _onSeeked = function() {
        _seeking = false;
        _ended = false;
        _seekTarget = undefined;
        clearTimeout(_seekedTimeout);
        self.trigger({
            type: 'seeked'
        }); //trigger with value _fixedCurrentTime
        for (var i = 0; i < _sourceBuffers.length; i++) {
            _sourceBuffers[i].seeked();
        }
    },

    _onLoadStart = function() {
        _ended = false;
        self.trigger({
            type: 'loadstart'
        });
    },

    _onPlay = function() {
        _currentTime = _getCurrentTimeFromFlash(); //Force refresh _currentTime
        _fixedCurrentTime = undefined;

        _ended = false;
        self.trigger({type: 'play'});
    },

    //TODO: seems not be used anymore see CLIEN-268
    _onPause = function() {
        _fixedCurrentTime = _fixedCurrentTime !== undefined ? _fixedCurrentTime : _getCurrentTimeFromFlash(); // Do not erase value if already set
        self.trigger({type: 'pause'});
    },

    _onPlaying = function() {
        _fixedCurrentTime = undefined;
        self.trigger({type: 'playing'});
    },

    _onWaiting = function() {
        _fixedCurrentTime = _fixedCurrentTime !== undefined ? _fixedCurrentTime : _getCurrentTimeFromFlash(); // Do not erase value if already set
    },

    _onStopped = function() {
        _ended = true;

        self.trigger({
            type: 'ended'
        });
    },

    _onCanplay = function() {
        self.trigger({
            type: 'canplay'
        });
    },

    _onDurationchange = function() {
        self.trigger({
            type: 'durationchange'
        });
    },

    _onVolumechange = function() {
        self.trigger({
            type: 'volumechange'
        });
    },

    _onFlashReady = function() {
        _setPropertiesFromCache();
        _executeActionsFromCache();
    },

    _updateTimeRange = function(startTime, endTime) {
        _buffered.add({
            start: startTime,
            end: endTime
        });
    },

    _canPlayType = function() {
        return 'probably';
    },

    _initialize = function() {

        window.sr_request_seek = function(time) {
            _seek(time);
        };

        window.sr_flash_seeked = function() {
          //Trigger event when seek is done
            _onSeeked();
        };

        window.sr_flash_loadstart = function() {
          //Trigger event when we want to start loading data (at the beginning of the video or on replay)
            _onLoadStart();
        };

        window.sr_flash_play = function() {
          //Trigger event when media is ready to play
          _onPlay();
        };

        window.sr_flash_pause = function () {
            _onPause();
        };

        window.sr_flash_canplay = function() {
            _onCanplay();
        };

        window.sr_flash_playing = function() {
          //Trigger event when the media is playing
            _onPlaying();
        };

        window.sr_flash_waiting = function() {
          //Trigger event when video has been paused but is expected to resume (ie on buffering or manual paused)
          _onWaiting();
        };

        window.sr_flash_stopped = function() {
          //Trigger event when video ends.
          _onStopped();
        };

        window.sr_flash_durationChange = function(duration) {
            _onDurationchange(duration);
        }

        window.sr_flash_appended_segment = function(startTime, endTime) {
          //Trigger event when video ends.
          _updateTimeRange(startTime, endTime);
        };

        window.sr_flash_volumeChange = function(volume) {
            _onVolumechange(volume);
        };

        var oldCreateObjectURL = window.URL.createObjectURL;
        window.URL.createObjectURL = function (mediaSource) {
            if (mediaSource.initialize) {
                _mediaSource = mediaSource;
                _mediaSource.initialize(self);
            } else {
                return oldCreateObjectURL(mediaSource);
            }
        };
    };

    Object.defineProperty(this, "currentTime", {
        get: _getCurrentTime,
        set: function(time) {
            _savePropertyValueToCache("currentTime", time);
            _seek(time);
        }
    });

    Object.defineProperty(this, "seeking", {
        get: function() {
            if (!_isFlashReady) {
                return undefined;
            }

            return _seeking;
        },
        set: undefined
    });

    Object.defineProperty(this, "paused", {
        get: _getPaused,
        set: undefined
    });

    Object.defineProperty(this, "duration", {
        get: function () {
            if (!_isFlashReady) {
                return undefined;
            }

            return _mediaSource.duration;
        },
        set: undefined
    });

    Object.defineProperty(this, "playbackRate", {
        get: function () {
            if (!_isFlashReady) {
                return undefined;
            }

            return 1; //Always return 1, as we don't support changing playback rate
        },
        set: function () {
            //The only time we'll set playback rate for now is to pause video on rebuffering (workaround in HTML5 only).
            //Added warning if we ever wanted to use it for other purposes.
            console.error("Changing playback rate is not supported for now with Streamroot Flash playback.");
        }
    });

    //Did this weird structure because event_handlers is set in mediaController.js after VideoExtension is created. But we need both to send metaData to flash player (from inside this class), and to
    //call the wrapper's event_handler. Then we need to combine both steps into the video.event_handlers.onMetaData method, and do everything from inside this class in order not to impact the rest
    //of the code with the switch HTML5 / Flash
    Object.defineProperty(this, "event_handlers", {
        get: function() {
            if (!_isFlashReady) {
                return undefined;
            }

            return _eventHandlers;
        },
        set: function(eventHandlers) {
            _savePropertyValueToCache("event_handlers", eventHandlers);
            _eventHandlers = eventHandlers;
        }
    });

    Object.defineProperty(this, "isFlash", {
        get: function() {
            if (!_isFlashReady) {
                return undefined;
            }

            return true;
        },
        set: undefined
    });

    Object.defineProperty(this, "flashDimension", {
        get: undefined,
        set: function(dimension){
            _swfObj.onMetaData(0, dimension.width, dimension.height);
        },
    });

    Object.defineProperty(this, "buffered", {
        get: _getBuffered,
        set: undefined
    });

    Object.defineProperty(this, "played", {
        get: _getPlayed,
        set: undefined
    });

    this.createSrc = function(mediaSourceFlash) {
        _mediaSource = mediaSourceFlash;
    };

    this.registerSourceBuffer = function(sourceBuffer) {
        _sourceBuffers.push(sourceBuffer);
        //TODO: register source buffer in there for sourceBufferEvents
    };

    this.getSwf = function() {
        return _swfObj;
    };

    this.play = _play;
    this.pause = _pause;
    this.addEventListener = _addEventListener;
    this.removeEventListener = _removeEventListener;
    this.trigger = _trigger;
    this.dispatchEvent = _trigger;
    this.canPlayType = _canPlayType;

    //TODO:register mediaSource and video events

    //TODO: create global methods for flash events here, and dispatch events to registered MediaSource, SourceBuffers, etc...

    _initialize();
};

module.exports = VideoExtension;
