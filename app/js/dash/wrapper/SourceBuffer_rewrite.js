"use strict";

/*

used in SourceBufferWrapper
		getBufferedTimeRanges: function(){
			return [];
		},
		createSourceBuffer: function(init){
		},
		append:function(data, segmentInterval){
		},
		remove: function(obj){
		},
		clearRemoveJobs:function(){
		},
		getPlaybackInterval:function(currentTime){
		},
		switchedTrack:function(init, startTime, endTime){
		},
		getBufferedStrict:function(){
		},
		checkSegment:function(segmentMapItem){
		},

*/


var SourceBuffer = function (mediaSource, type) {
	var sourcebufferflash = {

		audioTracks:[], 
		videoTracks:[], 

		mediasource:mediaSource,
		type:type,
		updating:false,
		listener:{},

		_buffered:function(i){
			var length = 1;
			var tr = {0:{start:0,end:0}}
			if (i<length){
				return tr[i]
			}
		},
		
		_addEventListener:function(type, listener){
			if (!this.listeners[type]){
				this.listeners[type] = [];
			}
			this.listeners[type].unshift(listener);
		},
	
		_removeEventListener:function(type, listener){
			var listeners = this.listeners[type],
				i = listeners.length;
			while (i--) {
				if (listeners[i] === listener) {
					return listeners.splice(i, 1);
				}
			}
		},
		
		_arrayBufferToBase64:function(buffer){
			var binary = '';
			var bytes = new Uint8Array( buffer );
			var len = bytes.byteLength;
			for (var i = 0; i < len; i++) {
				binary += String.fromCharCode( bytes[ i ] )
			}
			return window.btoa(binary);
		},	
		appendBuffer: function (arraybuffer_data){
			data = this._arrayBufferToBase64( arraybuffer_data );
			this.mediasource.swfobj.appendBufferPlayed(data);
			_trigger({type:'updatestart'});
			this.updating = true;
		},
		
		

	};
	return sourcebufferflash
}


module.exports = SourceBuffer;
