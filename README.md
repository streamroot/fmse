# Flash Media Source Extensions polyfill

fMSE is a library that emulates MSE in browsers that do not support them.
It allows the playback of modern video formats such as MPEG-DASH or HLS in web browsers that are not able to do it otherwise.
Adobe Flash is used to emulate MSE API and JavaScript as a bridge between browser and Flash.

## Building

This is a two steps process:

### Building JavaScript

Quite simple:
```
$ npm install
$ grunt
```

This will create `fMSE.js` in the `build` directory.

### Building ActionScript files

If you don't have Flex SDK:

1. Download [Apache Flex SDK Installer](http://flex.apache.org/installer.html)
1. Install the latest Flex SDK.

Edit `buildPlayer.py` and specify path to your Flex SDK directory and run the script:

```
$ python buildPlayer.py
```

You can provide additional options to customize the build. Use

```
$ python buildPlayer.py -h
```

to get list of supported options. Successful build will create `fMSE.swf` in the `build` directory.

## Example

Here is an example of MPEG-DASH playback using [dash.js v2.0](https://github.com/Dash-Industry-Forum/dash.js) and fMSE

```html
<!DOCTYPE html>
<html>
<head>
    <title>fMSE Polyfill - dash.js test page</title>
    <meta charset="UTF-8">
    <script src="../build/fMSE.js"></script>
    <script src="dash.all.debug.js"></script>
</head>
<body>
    <div>
        <video id="videoPlayer" width="480" height="360"></video>
    </div>

    <div>
        <button onclick="v_play()">Play/Resume</button>
        <button onclick="v_pause()">Pause</button>
    </div>

    <script>
        var polyfillSwfUrl = "../build/fMSE.swf";
        var videoElementId = "videoPlayer";
        var videoElement = document.getElementById(videoElementId);
        var forceFlashUsage = true;
        window.fMSE.init(polyfillSwfUrl, videoElement, initDashJS, forceFlashUsage);

        function initDashJS(video) {
            videoElement = video;
            console.log("initDashJS()", video);

            var url = "http://dash.edgesuite.net/envivio/Envivio-dash2/manifest.mpd";
            var player = dashjs.MediaPlayer().create();
            var autoStart = true;
            player.initialize(video, url, autoStart);
        }

        function v_play() {
            videoElement.play();
        }

        function v_pause() {
            videoElement.pause();
        }
    </script>
</body>
</html>
```

This demo page is here `demo/example_dash.html`. You can go to `demo` directory and run simple HTTP server (like Python's) to test it in a browser.

## Integration

1. Include fSME.js in your page

    ```html
    <head>
        <script src="../build/fMSE.js"></script>

        ...
    </head>
    ```

1. Initialize fMSE

    ```html
    <body>
        ...
        <script>
            //path to fMSE.swf
            var polyfillSwfUrl = "../build/fMSE.swf";

            // video tag that will be wrapped by fMSE
            var videoElement = document.getElementById(video_tag_id_here);

            // force fMSE usage or use native MSE if they are supported
            var forceFlash = true;
            window.fMSE.init(polyfillSwfUrl, videoElement, callback, forceFlash);

            // @video - video tag wrapper instance or original video tag
            function callback(video) {
                // fMSE initialization complete
                // you can initialize media engine here (dash.js, hls.js, etc)
            }
        </script>
    </body>
    ```

## Issues

## Contributing

fMSE is a free and open source library. It's a work in progress and we appreciate any help you're willing to give.

## Credits

The project uses [dash.as](https://github.com/castlabs/dashas) for MP4 to FLV transmuxing.

## License

[dash.as](https://github.com/castlabs/dashas) is licensed under [MPL 2.0](https://www.mozilla.org/en-US/MPL/2.0/)

