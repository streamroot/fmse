var MediaSourceFlash = require('./lib/MediaSourceFlash');
var VideoExtension = require('./lib/VideoExtension');

function init(polyfillSwfUrl, videoElement, onReady, flashByDefault){
    var isMSESupported = !!window.MediaSource;
    if(isMSESupported && !flashByDefault){
        return onReady(videoElement);
    }

    window.MediaSource = MediaSourceFlash;

    window.fMSE.onFlashReady = function(){
        onReady(new VideoExtension(swfObj));
    };

    var readyFunctionString = "window.fMSE.onFlashReady";

    var height = videoElement.height || 150;
    var width = videoElement.width || 300;

    var oldId = videoElement.id;
    var oldIdClasses = videoElement.className;

    var swfObjString = '<object id="'+oldId+'" type="application/x-shockwave-flash"'+
    ' data="'+ polyfillSwfUrl +'" width="'+ width +'" height="'+ height +'" name="'+oldId+'" class="'+oldIdClasses+'" style="display: block;">'+
    '        <param name="movie" value="'+ polyfillSwfUrl +'">'+
    '        <param name="flashvars" value="readyFunction='+readyFunctionString+'">'+
    '        <param name="allowScriptAccess" value="always">'+
    '        <param name="allowNetworking" value="all">'+
    '        <param name="wmode" value="opaque">'+
    '        <param name="bgcolor" value="#000000">'+
    '    </object>';

    var parentElement = videoElement.parentElement;
    parentElement.innerHTML = swfObjString;
    var swfObj = parentElement.firstChild;
}

module.exports = init;
