SourceBufferWrapper = function (swfObj) {

	var _init 		= function(){},

	_listeners 		= {},
	_swfobj = swfObj,
	_audioTracks 	= [], 
	_videoTracks 	= [], 
	_updating 		= false, //true , false
	_buffered 		= function(i){
		var length = 1;
		tr = {0:{start:0,end:0}}
		if (i<length){
			return tr[i]
		}
	},
	
	_addEventListener 	= function(type, listener){
		if (!this.listeners[type]){
			this.listeners[type] = [];
		}
		this.listeners[type].unshift(listener);
	},
	
	_removeEventListener = function(type, listener){
		var listeners = this.listeners[type],
			i = listeners.length;
		while (i--) {
			if (listeners[i] === listener) {
				return listeners.splice(i, 1);
			}
		}
	},
	
	_trigger 			= function(event){
		//updateend, updatestart
		var listeners = this.listeners[event.type] || [],
			i = listeners.length;
		while (i--) {
			listeners[i](event);
		}
	},

	_appendBuffer     		= function (arraybuffer_data){
		data = _arrayBufferToBase64( arraybuffer_data );
		_swfobj.appendBufferPlayed(data);
		_trigger({type:'updatestart'});
		updating = true;
	},

	_arrayBufferToBase64 	= function(buffer){
		var binary = '';
		var bytes = new Uint8Array( buffer );
		var len = bytes.byteLength;
		for (var i = 0; i < len; i++) {
			binary += String.fromCharCode( bytes[ i ] )
		}
		return window.btoa(binary);
	},	

	_remove     			= = function (start,end){
		_swfobj.removeBuffer(start,end);
	};
	
	init();

	
}