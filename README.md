# Flash Media Source Extensions polyfill

fMSE is a library that emulates MSE in browsers that do not support it.

It allows transparent fallback for players supporting modern video formats such as MPEG-DASH or HLS when MSE is not available.

Adobe Flash is used to do the actual playback, and communicates with a small JS polyfill that implements the MSE API.

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

For development, you most certainly want to enable debug and error logging. Build using the following options:
```
$ python buildPlayer.py --debug --log-debug --log-error
```

You can provide additional options to customize the build. Use

```
$ python buildPlayer.py -h
```

to get list of supported options. Successful build will create `fMSE.swf` in the `build` directory.

### Building Debug tool

This repo also contains a visual debug tool for video / source buffer information. To build it, just run:
```
$ grunt debug
```

This will create `debug/build/BufferDisplay.js`, which is already included in `demo/example_dash.html`

##### NOTE:

We're targeting flash versions 11.4+, so you should make sure you have playerglobal.swc v11.4 at `$FLEX_PATH/frameworks/libs/player/11.4/playerglobal.swc`

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

## Requirements & Compatibilities

This library requires Adobe Flash Player 11.4 or higher installed.
This library also needs [Service workers support](http://caniuse.com/#feat=serviceworkers), so it might not be working correctly on Safari and Edge.

fMSE has been tested with the following media libraries:
- [dash.js](https://github.com/Dash-Industry-Forum/dash.js)

Media engines to we want to provide support with:
- [shakapayer](https://github.com/google/shaka-player)
- [hls.js](https://github.com/dailymotion/hls.js)

## Known issues (PRs appreciated!)

- seek not working yet
- Muxed streams not supported
- EME is not supported (planning to provide EME support with Flash Access DRM)

For more details see our [issues tracker](https://github.com/streamroot/fmse/issues).

## Contributing

fMSE is a free and open source library. It's a work in progress and we appreciate any help you're willing to give. Don't hesitate add and comment issues on Github, or contact us directly at contact@streamroot.io.

## License

This project is licensed under [MPL 2.0](https://www.mozilla.org/en-US/MPL/2.0/)
If you need a special type of license for this project, you can contact us at contact@streamroot.io.

## Credits

The project uses [dash.as](https://github.com/castlabs/dashas) for MP4 to FLV transmuxing.
