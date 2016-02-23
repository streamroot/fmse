/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

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