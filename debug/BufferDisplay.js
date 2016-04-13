const CACHE_HEIGHT = 40;
const BUFFER_HEIGHT = 25;
const TRACK_TOP_MARGIN = 3;
const BUFFERED_COLOR = "#0c1b2e";
const PENDING_COLOR = "#07659f";
const CURRENT_TIME_COLOR = "#bf0101";
const CANVAS_WIDTH = 700;
const TRACK_TYPE_WIDTH = 60;
const FONT_STYLE = "12px Arial";
const TRACK_TYPE_COLOR = "#000824";


class BufferDisplay {
    constructor(){
        this._sourceBuffers = [];
    }

    attachVideo(video) {
        this._video = video;
        this._startIfReady();
    }

    attachSourceBuffer(sourceBuffer) {
        this._sourceBuffers.push(sourceBuffer);
        this._startIfReady();
    }

    _startIfReady() {
        if (this._sourceBuffers.length && this._video && !this._started) {
            this._started = true;
            this._canvas = document.createElement('canvas');

            this._canvas.width = CANVAS_WIDTH;
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

        this._canvas.height = (CACHE_HEIGHT + TRACK_TOP_MARGIN)*this._sourceBuffers.length;

        // calculate the scale of the chart
        let min = Infinity, max = 0;
        for (let sourceBuffer of this._sourceBuffers) {
            let buffered = sourceBuffer.debugBuffered || sourceBuffer.buffered;
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
        for (let i=0, sourceBuffer; sourceBuffer = this._sourceBuffers[i]; i++) {
            let buffered = sourceBuffer.debugBuffered || sourceBuffer.buffered;
            let debug = !!sourceBuffer.debugBuffered;

            let yPosition = (CACHE_HEIGHT + TRACK_TOP_MARGIN)*i;
            let opt = {
                scale,
                height: BUFFER_HEIGHT,
                yPosition: yPosition+(CACHE_HEIGHT - BUFFER_HEIGHT),
                color: BUFFERED_COLOR,
                debug
            };
            this._drawTimeRanges(context2D, opt, buffered, currentTime);
            if (debug) {
                let captionYPosition = yPosition + (CACHE_HEIGHT * 1 / 4);
                this._writeTrackType(context2D, sourceBuffer.type, captionYPosition);
            }
        }
        let currentTimeLineOptions = {
            height:this._canvas.height,
            color: CURRENT_TIME_COLOR,
            scale
        };
        this._drawCurrentTimeLine(context2D, currentTimeLineOptions, currentTime);
    }

    //The actual canvas drawing functions
    _drawTimeRanges(context2D, options, timeRanges, currentTime){
        let {scale, height, yPosition, color, debug} = options;

        if (debug && timeRanges.length > 2) {
            throw new Error("Expected debug buffered attribute with a buffered time interval and a pending time interval. Got more than 2 time intervals");
        }

        for (let j = 0; j < timeRanges.length; j++) {

            if (debug && j===1) {
                color = PENDING_COLOR;
            }


            let start = timeRanges.start(j);
            let end = timeRanges.end(j);

            let startX = this._convertTimeToPixel(scale, start);
            let endX = this._convertTimeToPixel(scale, end);
            let length = endX - startX > 1 ? endX - startX : 1;
            context2D.fillStyle = color;
            context2D.fillRect(startX, yPosition, length, height);

            if (start <= currentTime && currentTime <= end) {
                context2D.fillStyle = "#868686";
                context2D.font = "11px Arial";
                context2D.fillText((parseInt(start, 10)).toFixed(3), startX + 2, yPosition + 10);
                context2D.fillText((parseInt(end, 10)).toFixed(3), endX - 38, yPosition + height - 2);
            }
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
        let effectiveCanvasWidth = canvasWidth - TRACK_TYPE_WIDTH;
        let divider = Math.max(max - min, 3*60); //trick so we can see the progression of the buffer during the 3 first minutes of a stream.
        return TRACK_TYPE_WIDTH + ((time - min) * effectiveCanvasWidth / divider);
    }

    _writeTrackType(context2D, trackType, yPosition){
        context2D.fillStyle = TRACK_TYPE_COLOR;
        context2D.font = FONT_STYLE;
        context2D.fillText(trackType, 0, yPosition);
    }

}

export default new BufferDisplay();
