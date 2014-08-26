
package com.dash.boxes {
import com.dash.utils.Console;

import flash.utils.ByteArray;

public class TrackHeaderBox extends FullBox {
    private var _id:uint;

    public function TrackHeaderBox(offset:uint, size:uint) {
        super(offset, size);
    }

    public function get id():uint {
        return _id;
    }

    override protected function parseBox(ba:ByteArray):void {
        if (version == 0) {

//            // created mac UTC date
//            ba.position += 4;
//            // modified mac UTC date
//            ba.position += 4;

            ba.position += 8;
        } else if (version == 1) {

//            // created mac UTC date
//            ba.position += 8;
//            // modified mac UTC date
//            ba.position += 8;

            ba.position += 16;
        } else {
            throw Console.getInstance().logError(new Error("Unknown TrackHeaderBox version"));
        }

        _id = ba.readUnsignedInt();
    }
}
}
