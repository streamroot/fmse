"use strict";

var VideoExtension = function () {

    var self = this,
        
        //TODO: remove _currentTime property stuff
        //_currentTime = 0,

        _swfObj,

        _mediaSource,
        _sourceBuffers = [],


        _listeners = [],

        _isInitialized = function () {
            return (typeof _swfObj !== 'undefined');
        },


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
                i = listeners.length;
            while (i--) {
                listeners[i](event);
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
            if (_isInitialized()) {
                _swfObj.seek(time);
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

            window.updateend = function() {
                for (var i=0; i<_sourceBuffers.length; i++) {
                    _sourceBuffers[i].trigger({type:'updateend'});
                }
            };
        };

    this.createSrc = function (swfObj, mediaSourceFlash) {
        _swfObj = swfObj;
        _mediaSource = mediaSourceFlash;
    };

    this.getFlashVideoObject = function () {
        return self;
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
        get: function () { return _getCurrentTime(); },
        set: function (time) { _seek(time); } //TODO: pas vu de method seek dans l'interface flash
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