/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.dash.utils {
import flash.utils.ByteArray;

public class Bytes {
    private static const NUMBER:uint = 4;

    public function Bytes() {
        throw new Error("It's a static class");
    }

    public static function readNumber(ba:ByteArray, length:uint = NUMBER):uint {
        var number:uint = 0;

        for (var i:uint = 0; i < length; i++) {
            number = number << 8;
            number += ba.readUnsignedByte();
        }

        return number;
    }

    public static function skipNumberIfNeeded(condition:Boolean, ba:ByteArray):void {
        if (condition) {
            ba.position += NUMBER;
        }
    }
}
}
