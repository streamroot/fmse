const CACHE_HEIGHT = 30;
const BUFFER_HEIGHT = 10;
const TRACK_TOP_MARGIN = 3;
const BUFFERED_COLOR = "#202429";
const CURRENT_TIME_COLOR = "#bf0101";
const CANVAS_WIDTH = 460;
const TRACK_NAME_WIDTH = 60;
const FONT_STYLE = "12px Arial";


function init(video){
    let canvas = document.createElement('canvas');
    canvas.width = /*video.clientWidth ||*/ CANVAS_WIDTH;
    let div = document.getElementById("bufferDisplay");
    if(!div){
        div = document.createElement('div');
        document.getElementsByTagName('body')[0].appendChild(div);
    }
    div.appendChild(canvas);
    let refresh = render.bind(null, canvas, video);
    setInterval(refresh, 30);
}

function render(canvas, video){
    let {buffered, currentTime} = video;
    let context2D = canvas.getContext('2d');

    var SOURCE_BUFFER_LENGTH = 1; // TODO: remove this as soon as we use a list of sourceBuffers instead of the video tag

    canvas.height = (CACHE_HEIGHT + TRACK_TOP_MARGIN)*SOURCE_BUFFER_LENGTH;

    // calculate the scale of the chart
    let min = Infinity, max = 0;
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

    let scale = {min, max, canvasWidth: canvas.width};

    //for each SourceBuffer, draw TimeRanges.
    for(let i=0; i < SOURCE_BUFFER_LENGTH;i++){
        let yPosition = (CACHE_HEIGHT + TRACK_TOP_MARGIN)*i;
        let opt = {
            scale,
            height: BUFFER_HEIGHT,
            yPosition: yPosition+(CACHE_HEIGHT - BUFFER_HEIGHT),
            color: BUFFERED_COLOR,
        };
        drawTimeRanges(context2D, opt, buffered);
    }
    let currentTimeLineOptions = {
        height:canvas.height,
        color: CURRENT_TIME_COLOR,
        scale
    };
    drawCurrentTimeLine(context2D, currentTimeLineOptions, currentTime);
}

//The actual canvas drawing functions
function drawTimeRanges(context2D, options, vbm){
    let {scale, height, yPosition, color} = options;
    for (let j = 0; j < vbm.length; j++) {
        let start = convertTimeToPixel(scale, vbm.start(j));
        let end = convertTimeToPixel(scale, vbm.end(j));
        let length = end - start > 1 ? end - start : 1;
        context2D.fillStyle = color;
        context2D.fillRect(start, yPosition, length, height);
    }
}


function drawCurrentTimeLine(context2D, options, time){
    let {color, scale, height} = options;
    let position = convertTimeToPixel(scale,time);
    context2D.fillStyle = color;
    context2D.fillRect(position, 0, 1, height);
    context2D.fillStyle = color;
    context2D.font = FONT_STYLE;
    context2D.fillText(time.toFixed(3), 0, height);
}


var convertTimeToPixel = function(scale, time) {
    let {min, max, canvasWidth} = scale;
    let effectiveCanvasWidth = canvasWidth - TRACK_NAME_WIDTH;
    let divider = Math.max(max - min, 3*60); //trick so we can see the progression of the buffer during the 3 first minutes of a stream.
    return TRACK_NAME_WIDTH + ((time - min) * effectiveCanvasWidth / divider);
};

export default init;
