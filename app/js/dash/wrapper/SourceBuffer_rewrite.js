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
		type:type,
		mediasource:mediaSource,
		
		
		_buffered:{
			length:1,
			0:{start:0,end:0},
		},
		
		listener:{},
		audioTracks:[], 
		videoTracks:[], 
		addEventListener:function(type, listener){
			if (!this.listeners[type]){
				this.listeners[type] = [];
			}
			this.listeners[type].unshift(listener);
		},
	
		removeEventListener:function(type, listener){
			var listeners = this.listeners[type],
				i = listeners.length;
			while (i--) {
				if (listeners[i] === listener) {
					return listeners.splice(i, 1);
				}
			}
		},
		trigger:function(event){
			//updateend, updatestart
			var listeners = this.listeners[event.type] || [],
				i = listeners.length;
			while (i--) {
				listeners[i](event);
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
			var data = this._arrayBufferToBase64( arraybuffer_data );
			this.mediasource.swfobj.appendBufferPlayed(data);
			_trigger({type:'updatestart'});
			this.updating = true;
		},
		_remove:function (start,end){
			this.mediasource.swfobj.removeBuffer(start,end);
		},
		init:function(){
			this.addEventListener('updateend',function(){this.updating=false});
			this.addEventListener('updatebuffered',
				function(event){
					this.buffered = {
						length:1,
						0:{start:0,end:int(event.endtime)},
					}
				});
		}

	};
	return sourcebufferflash
}

module.exports = SourceBuffer;
