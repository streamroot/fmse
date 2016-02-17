

package com.dash.boxes {

import flash.utils.ByteArray;

public class TrackBox extends Box {
    private var _tkhd:TrackHeaderBox;
    private var _mdia:MediaBox;

    public function TrackBox(offset:uint, size:uint) {
        super(offset, size);
    }

    public function get tkhd():TrackHeaderBox {
        return _tkhd;
    }

    public function get mdia():MediaBox {
        return _mdia;
    }

    override protected function parseChildBox(type:String, offset:uint, size:uint, ba:ByteArray):Boolean {
        if (type == "tkhd") {
            parseTrackHeaderBox(offset, size, ba);
            return true;
        }

        if (type == "mdia") {
            parseMediaBox(offset, size, ba);
            return true;
        }

        return false;
    }

    private function parseTrackHeaderBox(offset:uint, size:uint, ba:ByteArray):void {
        _tkhd = new TrackHeaderBox(offset, size);
        _tkhd.parse(ba);
    }

    private function parseMediaBox(offset:uint, size:uint, ba:ByteArray):void {
        _mdia = new MediaBox(offset, size);
        _mdia.parse(ba);
    }
}
}