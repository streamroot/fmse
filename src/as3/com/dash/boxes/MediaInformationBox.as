
package com.dash.boxes {
import flash.utils.ByteArray;

public class MediaInformationBox extends Box {
    private var _stbl:SampleTableBox;

    public function MediaInformationBox(offset:uint, size:uint) {
        super(offset, size);
    }

    public function get stbl():SampleTableBox {
        return _stbl;
    }

    override protected function parseChildBox(type:String, offset:uint, size:uint, ba:ByteArray):Boolean {
        if (type == "stbl") {
            parseSampleTableBox(offset, size, ba);
            return true;
        }

        return false;
    }

    private function parseSampleTableBox(offset:uint, size:uint, ba:ByteArray):void {
        _stbl = new SampleTableBox(offset, size);
        _stbl.parse(ba);
    }
}
}