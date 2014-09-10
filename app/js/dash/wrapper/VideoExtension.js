"use strict";

var VideoExtension = function (mediaController, swfObj) {

    var self = this,
        
        //TODO: remove _currentTime property stuff
        //_currentTime = 0,

        _swfObj = swfObj,

        _mediaSource,
        _sourceBuffers = [],


        _listeners = [],

        _isInitialized = function () {
            return (typeof _swfObj !== 'undefined');
        },

        _seeking = false,


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

        _play = function () {
            if (_isInitialized()) {
                _swfObj.play();
            } else {
                //TODO: implement exceptions similar to HTML5 one, and handle them correctly in the code
                new Error('Flash video is not initialized'); //TODO: should be "throw new Error(...)" but that would stop the execution
            }
        },

        _pause= function () {
            if (_isInitialized()) {
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
            var keyFrameTime,
                audioOffset;
            if (_isInitialized()) {
                
                keyFrameTime = _getPrecedingKeyFrame(time);
                audioOffset = _getSeekAudioOffset(keyFrameTime); //Needs to be keyFrameTime (actual seek time with flash) and not time
                 //HACK for mediaSourceTrigger. +args?
                _mediaSource.trigger({type: 'seeking'});
                console.info("seeking");
                console.trace();
                self.trigger({type: 'seeking'});
                _seeking = true;
                
                _swfObj.seek(keyFrameTime, time);
                //TODO: replace that (configure inBufferSeek of netStream?)
                for (var i=0; i<_sourceBuffers.length; i++) {
                    _sourceBuffers[i].seeked(keyFrameTime);
                }
            } else {
                //TODO: implement exceptions similar to HTML5 one, and handle them correctly in the code
                new Error('Flash video is not initialized'); //TODO: should be "throw new Error(...)" but that would stop the execution
            }
        },
        
        _getCurrentTime = function () {
            var currentTime = 0,
                timeString;
            if (_isInitialized()) {
                timeString = _swfObj.currentTime();
                currentTime = parseFloat(timeString);
            }
            return currentTime;
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
                segment = mediaController.manifestManager.getPartForTime(mediaController.currentPeriod, time, audioTrack.id_aset, audioTrack.id_rep).segment;
            return segment.time;
        },

        _initialize = function () {
            //TODO: remove _currentTime property stuff
            /*
            window.update_currenttime = function(){
                var time = parseInt(arguments[0]);
                _currentTime = time;
            };
            */

            window.cjs_callback_as_event = function(){
                var directory = {
                    'mediasource':window.mse_callback,
                    'sourcebuffer':window.srcbuffer_callback,
                    'videoextension':window.videoext_callback,
                },

                    event_name = arguments[1],
                    event_target = directory[arguments[0]];

                switch (arguments[0]) {
                    case 'mediasource':
                        if(event_name=="updatebuffered"){
                            _mediaSource.trigger({type:event_name,endtime:arguments[2]});
                        } else {
                            _mediaSource.trigger({type:event_name});
                        }
                        break;

                        //TODO: for now we trigger sourceBuffer events on every sourceBuffer. Find way to execute on right one ( sourceBufferID)
                    case 'sourcebuffer':
                        for (var i=0; i<_sourceBuffers.length; i++) {
                            if(event_name=="updatebuffered"){
                                _sourceBuffers[i].trigger({type:event_name,endTime:parseInt(arguments[2])/10000000});
                            }else if(event_name=="updateend"){
								console.log('\n\n\n#######\nall sourcebuffer updateend')
                                _sourceBuffers[i].trigger({type:event_name});
                            } else {
                                _sourceBuffers[i].trigger({type:event_name});
                            }
                        }
                        break;

                    case 'videoextension':
                        if(event_name=="updatebuffered"){
                            this.trigger({type:event_name,endtime:arguments[2]});
                        }else if(event_name=="updatetime"){
                            //TODO: remove _currentTime property stuff
								//console.log('#######\ncurrenttime updated')
                                //_currentTime = parseInt(arguments[2])/1000;
                        } else {
                            this.trigger({type:event_name});
                        }
                        break;
                }
            };
            
            window.sr_flash_seeked = function () {
                _seeking = false;
                self.trigger({type: 'seeked'});
            };

            window.updateend = function() {
                for (var i=0; i<_sourceBuffers.length; i++) {
                    _sourceBuffers[i].trigger({type:'updateend'});
                }
            };
        };

    this.createSrc = function (mediaSourceFlash) {
        /*
		if (!vjs_bool){
			_swfObj = swfObj;
        }
        */
        _mediaSource = mediaSourceFlash;
        
        //TODO: remove global access when debugging is done
        window.SWFOBJ = _swfObj;
    };
    
    /*
    this.getFlashVideoObject = function (vjs_swfobj) {
		if(vjs_swfobj){
			_swfObj = vjs_swfObj;
			vjs_bool = true;
		}
        return self;
    };
    */

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
        return _swfObj
    };

    //TODO:register mediaSource and video events

    //TODO: create global methods for flash events here, and dispatch events to registered MediaSource, SourceBuffers, etc...

    _initialize();

    /*
	var _createSrc = function(mediaSource){
		if (window.URL !== null) {
			this.src = window.URL.createObjectURL(_mediaSource);
		} else if (window.webkitURL = window.webkitURL || window.WebKitURL) {
			this.src = window.webkitURL.createObjectURL(_mediaSource);
		}else{
			this.src = '';
			this._swfobject 	= mediaSource.swfobject;
		}
		return;
	};

	if (window.MediaSource !== null) {
		video.createSrc = _createSrc
		return video
	} else if(window.webkitMediaSource = window.WebKitMediaSource || window.webkitMediaSource || window.MozMediaSource) {
		video.createSrc = _createSrc
		return video
	} else {

	}	

	var self=this,
	_init = function(){
		self.createSrc 	= createSrc;
	},

	_currentTime = 0.0,
	_swfobject,
	_play = function(){
		_swfobject.play();
	},
	_pause= function(){
		_swfobject.pause()
	},
	_stop = function(){
		_swfobject.stop()
	},
	_seek = function(){
		_swfobject.seek()
	},

	_canPlayType	= function(){},
	_currentTime 	= function(time){
		_currentTime = time
	};

    Object.defineProperty(this, "currentTime", {
        get: function () { return _currentTime; },
        set: function (time) { _currentTime = time; }
    });

	this.createSrc = _createSrc;
    */
};

module.exports = VideoExtension;