var MediaSourceFlash = require('./lib/wrapper/MediaSourceFlash');
var VideoExtension = require('./lib/wrapper/VideoExtension');

function WrapFlashVideo(polyfillSwfUrl, videoElement, onReady, flashByDefault, autoplay){
    var isMSESupported = true;
    if(isMSESupported && !flashByDefault){
        return videoElement;
    }

    window.MediaSource = MediaSourceFlash;

    window.go = function(){
        onReady(new VideoExtension(swfObj));
    };

    window.tapEvent = function(){
        console.log(arguments);
    };
    window.tapError = function(){
        console.log(arguments);
    };

    var readyFunctionString = "window.go";
    var eventProxyFunctionString = "window.tapEvent";
    var errorEventProxyFunctionString = "window.tapError";

    var height = videoElement.height || 150;
    var width = videoElement.width || 300;

    var oldId = videoElement.id;
    var oldIdClasses = videoElement.className;

    var swfObjString = '<object id="'+oldId+'" type="application/x-shockwave-flash"'+
    ' data="'+ polyfillSwfUrl +'" width="'+ width +'" height="'+ height +'" name="'+oldId+'" class="'+oldIdClasses+'" style="display: block;">'+
    '        <param name="movie" value="'+ polyfillSwfUrl +'">'+
    '        <param name="flashvars" value="readyFunction='+readyFunctionString+
                                            '&amp;eventProxyFunction='+eventProxyFunctionString+
                                            '&amp;errorEventProxyFunction='+errorEventProxyFunctionString+
                                            '&amp;autoplay='+autoplay+
                                            '&amp;preload=undefined'+
                                            '&amp;loop=undefined'+
                                            '&amp;muted=undefined'+
                                            '&amp;src=null&amp;">'+
    '        <param name="allowScriptAccess" value="always">'+
    '        <param name="allowNetworking" value="all">'+
    '        <param name="wmode" value="opaque">'+
    '        <param name="bgcolor" value="#000000">'+
    '    </object>';

    var parentElement = videoElement.parentElement;
    parentElement.innerHTML = swfObjString;
    var swfObj = parentElement.firstChild;
}

module.exports = WrapFlashVideo;
