
package com.dash.events {

import flash.events.Event;

public class MessageEvent extends Event {
    public static const ADDED:String = "messageAdded";

    private var _message:String;

    public function MessageEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false,
                                  message:String='') {
        super(type, bubbles, cancelable);

        _message = message;
    }

    public function get message():String {
        return _message;
    }

}
}