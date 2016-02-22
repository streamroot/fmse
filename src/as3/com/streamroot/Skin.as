package com.streamroot {

import com.streamroot.events.PlaybackEvent;

import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.media.Video;

public class Skin extends Sprite {

    private var video:Video;
    private var bg:Sprite;

    private var _model:NetStreamWrapper;

    public function Skin(model:NetStreamWrapper) {
        _model = model;
        _model.addEventListener(PlaybackEvent.ON_META_DATA, onMetaData);
        _model.addEventListener(PlaybackEvent.ON_VIDEO_DIMENSION_UPDATE, onDimensionUpdate);

        bg = new Sprite();
        addChild(bg);

        video = new Video();
        video.smoothing = true;
        addChild(video);

        _model.attachVideo(video);

        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
    }

    private function onAddedToStage(event:Event):void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;
        stage.addEventListener(Event.RESIZE, onStageResize);

        onStageResize(null);
    }

    private function onStageResize(event:Event):void {
        drawBackground();
        sizeVideoObject();
    }

    private function onMetaData(e:PlaybackEvent):void {
        sizeVideoObject();
    }

    private function onDimensionUpdate(e:PlaybackEvent):void {
        sizeVideoObject();
    }

    private function drawBackground():void {
        bg.graphics.clear();
        bg.graphics.beginFill(0, 1);
        bg.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
        bg.graphics.endFill();
    }

    private function sizeVideoObject():void {
        var videoWidth:int = video.videoWidth || Number(_model.metadata.width);
        var videoHeight:int = video.videoHeight || Number(_model.metadata.height);
        var givenWidth:Number = stage.stageWidth;
        var givenHeight:Number = stage.stageHeight;

        if (isNaN(videoWidth) || isNaN(videoHeight) || isNaN(givenWidth) || isNaN(givenHeight))
        {
            return;
        }

        var kw:Number = videoWidth / givenWidth;
        var kh:Number = videoHeight / givenHeight;
        if (kw > kh)
        {
            doResize(givenWidth, Math.round(videoHeight / kw));
        }
        else
        {
            doResize(Math.round(videoWidth / kh), givenHeight);
        }
    }

    private function doResize(width:Number, height:Number):void
    {
        video.width = width;
        video.height = height;

        video.x = Math.round(0.5 * (stage.stageWidth - video.width));
        video.y = Math.round(0.5 * (stage.stageHeight - video.height));
    }

}
}
