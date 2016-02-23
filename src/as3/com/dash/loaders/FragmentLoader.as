/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

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