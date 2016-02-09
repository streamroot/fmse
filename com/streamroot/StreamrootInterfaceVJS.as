package com.streamroot {

import flash.utils.ByteArray;
import com.videojs.providers.StreamrootProvider;

public class StreamrootInterfaceVJS extends StreamrootInterfaceBase{

    public function StreamrootInterfaceVJS(provider):void {
        super(provider);
    }

    override public function appendBytesAction(action:String):void {
        _provider.appendBytesAction(action);
    }

    public override function appendBytes(bytes:ByteArray):void {
        _provider.appendBuffer(bytes);
    }

    override public function onMetaData(duration:Number, width:Number=0, height:Number=0):void {
        var metaData:Object = new Object();
        metaData.duration = duration;
        if (width > 0 && height > 0) {
            metaData.width = width;
            metaData.height = height;
        }
        _provider.onMetaData(metaData);
    }

    override public function bufferEmpty():void {
        _provider.onBufferEmpty(true);
    }

    override public function bufferFull():void {
        _provider.onBuffersReady();
    }

    override public function getBufferLength():Number {
        return _provider.getBufferLength();
    }

    public override function play():void {
        _provider.resume();
    }

    public override function pause():void {
        _provider.pause();
    }

    public override function seek(time:Number):void {
        _provider.seekBySeconds(time);
    }

    //GETTERS
    public override function currentTime():Number {
        return _provider.time;
    }

    public override function paused():Boolean {
        return _provider.paused;
    }

    public function getQoSMetrics():Object {
        return _provider.getQoSMetrics();
    }
}
}
