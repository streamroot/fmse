var _bytes,
    _b64Data,
    _offset,
    PIECE_SIZE = 65536;

var _arrayBufferToBase64 = function(){
    var i,
        len = _bytes.byteLength,
        end = Math.min(_offset + PIECE_SIZE, len);
    for (i = _offset; i < end; i++) {
        _b64Data += String.fromCharCode( _bytes[i] );
    }
    if (end === len) {
        _b64Data = btoa(_b64Data);
        self.postMessage({b64Data: _b64Data});
    } else {
        _offset = end;
        setTimeout(_arrayBufferToBase64, 5);
    }
};

self.onmessage = function (e) {
    _bytes = new Uint8Array(e.data.data);
    _b64Data = '';
    _offset = 0;
    
    _arrayBufferToBase64();
};