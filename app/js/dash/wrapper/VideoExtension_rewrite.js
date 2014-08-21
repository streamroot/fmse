 "use strict";

var VideoExtension = function (mediaSource,sourceBuffer) {
	var videoextensionflash = {
		mediasource:mediaSource,
		sourcebuffer:sourceBuffer,
		currenttime:0,
	};
	mediaSource.videoextension 	= videoextensionflash;
	
	window.mse_callback 		= mediaSource;
	window.srcbuffer_callback 	= sourceBuffer;
	window.videoext_callback 	= mediaSource.videoextension;
	
	window.cjs_callback_as_event = function(){
		directory = {
			'mediasource':window.mse_callback,
			'sourcebuffer':window.srcbuffer_callback,
			'videoextension':window.videoext_callback,
		}
		event_name = arguments[0];
		event_target = directory[arguments[1]];
		if(event_name=="updatebuffered"){
			event_target.trigger({type:event_name,endtime:arguments[2]})
		}else{
			event_target.trigger({type:event_name})
		}
	}
	window.update_currenttime = function(){
		time = int(arguments[0]);
		window.mse_callback.videoextension.currenttime = time;
	}
	
	return videoextensionflash;
}

module.exports = VideoExtension;
