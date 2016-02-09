package com.dash.loaders {

import com.dash.events.MessageEvent;
import flash.events.EventDispatcher;

public class FragmentLoader extends EventDispatcher {

    public function FragmentLoader() {
    }

    public function sendMessage(message:String):void{
        dispatchEvent(new MessageEvent(MessageEvent.ADDED,false,false,message));
    }

    public function testMessage():void{
        sendMessage('in FragmentLoader')
    }

}

}