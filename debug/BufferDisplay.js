const CACHE_HEIGHT = 30;
const BUFFER_HEIGHT = 10;
const TRACK_TOP_MARGIN = 3;
const BUFFERED_COLOR = "#202429";
const CURRENT_TIME_COLOR = "#bf0101";
const CANVAS_WIDTH = 460;
const TRACK_NAME_WIDTH = 60;
const FONT_STYLE = "12px Arial";

class BufferDisplay {
    constructor(){

    }

    attachVideo(video) {
        this._video = video;
        this._startIfReady();
    }

    attachMSE(mse) {
        this._mse = mse;
        this._startIfReady();
    }

    _startIfReady() {
        if (this._mse && this._video) {
            this._canvas = document.createElement('canvas');

            this._canvas.width = /*video.clientWidth ||*/ CANVAS_WIDTH;
            let div = document.getElementById("bufferDisplay");
            if(!div){
                div = document.createElement('div');
                document.body.appendChild(div);
            }
            div.appendChild(this._canvas);

            let render = this._render.bind(this);
            setInterval(render, 30);
        }
    }

    _render(){
        let { currentTime } = this._video;
        let context2D = this._canvas.getContext('2d');

        var SOURCE_BUFFER_LENGTH = 1; // TODO: remove this as soon as we use a list of sourceBuffers instead of the video tag

        this._canvas.height = (CACHE_HEIGHT + TRACK_TOP_MARGIN)*this._mse.sourceBuffers.length;

        // calculate the scale of the chart
        let min = Infinity, max = 0;
        for (let { buffered } of this._mse.sourceBuffers) {
            if(buffered.length){
                let bufferedMin = buffered.start(0);
                let bufferedMax = buffered.end(buffered.length-1);

                if( bufferedMin < min ){
                    min = bufferedMin;
                }
                if(bufferedMax > max){
                    max = bufferedMax;
                }
            }
        }

        let scale = {min, max, canvasWidth: this._canvas.width};

        //for each SourceBuffer, draw TimeRanges.
        for (let i=0; i < this._mse.sourceBuffers.length; i++) {
            let buffered = this._mse.sourceBuffers[i].buffered;
            let yPosition = (CACHE_HEIGHT + TRACK_TOP_MARGIN)*i;
            let opt = {
                scale,
                height: BUFFER_HEIGHT,
                yPosition: yPosition+(CACHE_HEIGHT - BUFFER_HEIGHT),
                color: BUFFERED_COLOR,
            };
            this._drawTimeRanges(context2D, opt, buffered);
        }
        let currentTimeLineOptions = {
            height:this._canvas.height,
            color: CURRENT_TIME_COLOR,
            scale
        };
        this._drawCurrentTimeLine(context2D, currentTimeLineOptions, currentTime);
    }

    //The actual canvas drawing functions
    _drawTimeRanges(context2D, options, vbm){
        let {scale, height, yPosition, color} = options;
        for (let j = 0; j < vbm.length; j++) {
            let start = this._convertTimeToPixel(scale, vbm.start(j));
            let end = this._convertTimeToPixel(scale, vbm.end(j));
            let length = end - start > 1 ? end - start : 1;
            context2D.fillStyle = color;
            context2D.fillRect(start, yPosition, length, height);
        }
    }


    _drawCurrentTimeLine(context2D, options, time){
        let {color, scale, height} = options;
        let position = this._convertTimeToPixel(scale,time);
        context2D.fillStyle = color;
        context2D.fillRect(position, 0, 1, height);
        context2D.fillStyle = color;
        context2D.font = FONT_STYLE;
        context2D.fillText(time.toFixed(3), 0, height);
    }


    _convertTimeToPixel(scale, time) {
        let {min, max, canvasWidth} = scale;
        let effectiveCanvasWidth = canvasWidth - TRACK_NAME_WIDTH;
        let divider = Math.max(max - min, 3*60); //trick so we can see the progression of the buffer during the 3 first minutes of a stream.
        return TRACK_NAME_WIDTH + ((time - min) * effectiveCanvasWidth / divider);
    };

}

export default new BufferDisplay();
