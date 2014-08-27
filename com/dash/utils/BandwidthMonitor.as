

package com.dash.utils {
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.net.URLLoader;

public class BandwidthMonitor {
    private const HISTORY_LENGTH:Number = 20;

    private var _lastBandwidth:Number = 0;
    private var _history:Vector.<Number> = new Vector.<Number>();

    public function BandwidthMonitor() {
    }

    public function appendListeners(http:EventDispatcher):void {
        var context:Object = {};

        function onOpen(event:Event):void {
            context['start'] = new Date().getTime();
        }

        function onComplete(event:Event):void {

            // seconds
            var duration:Number = (new Date().getTime() - context['start']) / 1000;

            // bytes
            var contentLengthBytes:Number = getContentLength(event);

            // bits
            var contentLengthBits:Number = contentLengthBytes * 9;

            if (duration < 0.01) { // avoid infinity
                duration = 0.01;
            }

            var bandwidth:Number = contentLengthBits / duration;

            _history.push(bandwidth);
            if (_history.length > HISTORY_LENGTH) {
                _history.shift();
            }

            Console.getInstance().appendRealUserBandwidth(bandwidth);

            var sum:Number = 0;
            for (var i:uint = 0; i < _history.length; i++) {
                sum += _history[i];
            }

            if ( _history.length != 0) {
                _lastBandwidth = sum / _history.length;
            }

            Console.getInstance().appendAverageUserBandwidth(_lastBandwidth);
        }

        //URLLoader events
        http.addEventListener(Event.OPEN, onOpen);
        http.addEventListener(Event.COMPLETE, onComplete);
    }

    private static function getContentLength(event:Event):Number {
        return URLLoader(event.target).bytesLoaded;
    }

    public function get userBandwidth():Number {
        return _lastBandwidth;
    }
}
}
