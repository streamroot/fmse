// on supprime l'élement vidéo
//
//
// utiliser la EventProxyfunction pour passer les messages du flash vers le js, avec un id unique dans le nom de cette proxy function. Comme ça on pourra instancier plusieurs player vidéo sur la même page.
// on crée l'object swf, qu'on append juste à la place de l'élément video
// on surcharge le swf avec videoExtension (videoExtension.call(swfObj))
//
// on retourne l'élement swf à la place de la vidéo

var MediaSourceFlash = require('./lib/wrapper/MediaSourceFlash');
var VideoExtension = require('./lib/wrapper/VideoExtension');

function WrapFlashVideo(polyfillSwfUrl, videoElement, onReady, flashByDefault, autoplay){
    // on vérifie si MSE est supporté, si non alors notre truc prend sa place
    var isMSESupported = true;
    if(isMSESupported && !flashByDefault){
        return videoElement;
    }

    // on surcharge MediaSource (pas la peine avec notre player)
    window.MediaSource = MediaSourceFlash;

    window._DEBUG_ = true;
    window._TEST_ = false;

    window.go = function(){
        onReady(new VideoExtension(swfObj));
    }

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
    '        <param name="flashvars" value="readyFunction='+readyFunctionString+'&amp;eventProxyFunction='+eventProxyFunctionString+'&amp;errorEventProxyFunction='+errorEventProxyFunctionString+'&amp;autoplay='+autoplay+'&amp;preload=undefined&amp;loop=undefined&amp;muted=undefined&amp;src=null&amp;">'+
    '        <param name="allowScriptAccess" value="always">'+
    '        <param name="allowNetworking" value="all">'+
    '        <param name="wmode" value="opaque">'+
    '        <param name="bgcolor" value="#000000">'+
    '    </object>';

    var parentElement = videoElement.parentElement;
    parentElement.innerHTML = swfObjString;
    var swfObj = parentElement.firstChild;
    // VideoExtension.call(swfObj,swfObj);
    // return swfObj;
}

module.exports = WrapFlashVideo;
