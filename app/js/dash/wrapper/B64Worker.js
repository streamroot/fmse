var _arrayBufferToBase64 = function(buffer){
    var binary = '';
    var bytes = new Uint8Array( buffer );
    var len = bytes.byteLength;
    for (var i = 0; i < len; i++) {
        binary += String.fromCharCode( bytes[ i ] );
    }
    return self.btoa(binary);
};	

self.onmessage = function (e) {
    var b64Data = _arrayBufferToBase64(e.data.data);
    self.postMessage({b64Data: b64Data});
};