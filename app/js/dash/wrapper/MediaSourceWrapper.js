MediaSourceWrapper = function () {

	_init 		= function(){
		this.readyState = 'open'
		this.trigger({{type:'sourceopen'}})
	}
	
	_listeners 	= {};

	_duration 	= NaN; //
	_readyState = 'close'; //close, open, ended
	_sourceBuffers = [];

	_addEventListener 	= function(type, listener){
		if (!this._listeners[type]){
			this._listeners[type] = [];
		}
		this._listeners[type].unshift(listener);
	},
	
	_removeEventListener = function(type, listener){
		var listeners = this._listeners[type],
			i = listeners.length;
		while (i--) {
			if (listeners[i] === listener) {
				return listeners.splice(i, 1);
			}
		}
	},
	
	_trigger 			= function(event){
		//updateend, updatestart
		var listeners = this._listeners[event.type] || [],
			i = listeners.length;
		while (i--) {
			listeners[i](event);
		}
	},

	_addSourceBuffer 		= function(type){
		var sourceBuffer;
		sourceBuffer = new SourceBuffer(this);
		_sourceBuffers.push(sourceBuffer);
		return sourceBuffer;
	};
	_removeSourceBuffer 	= function(){}
	_endOfStream 			= function(){}
	
	init();

}