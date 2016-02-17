// Apr 1st 2015
// Was removed by Kevin Oury, see commit 9be8c00a8c20e5889b367fec09448f086d69115f
// Restore by Stanislas Fechner for performance issue

/**
 * B64Encoding is done in a seperate worker to avoid performance issue when the
 * user switch tab or use fullscreen
 * In these use case, the browser consider the tab is not the active one, and all
 * timeout in the main thread are set to minimum 1 second
 * Since we need the timeout in the function _arrayBufferToBase64 (for performance issue)
 * we do it in a different worker, in which timeout will not be affected
 */

function B64Worker(){

    var _arrayBufferToBase64 = function(bytes, index) {
        var len = bytes.byteLength,
            b64Data = "";
        for (var i = 0; i < len; i++) {
            b64Data += String.fromCharCode(bytes[i]);
        }
        b64Data = btoa(b64Data);
        self.postMessage({
            b64data: b64Data,
            jobIndex: index
        });
    };

    self.onmessage = function(e) {
        _arrayBufferToBase64(new Uint8Array(e.data.data), e.data.jobIndex);
    };


    //Not in use atm,
    //Method tick can be used trigger event 'timeUpdate' in flash.
    //We'll be able to use this event as a workaroud for the setTimeout / setInterval throttling when the tab is inactive / video in fullscreen

    var tick = function() {
      self.postMessage({
        tick: true
      });
    };

    //setInterval(tick, 125);
}

module.exports = B64Worker;
