"use strict";

/*

used in SourceBufferWrapper
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
		getBufferedTimeRanges: function(){
		listener:{},
		audioTracks:[], 
		videoTracks:[], 
		mediasource:mediaSource,
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
