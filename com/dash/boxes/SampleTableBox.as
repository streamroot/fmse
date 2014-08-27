

package com.dash.boxes {
import flash.utils.ByteArray;

public class SampleTableBox extends Box {
    private var _stsd:SampleDescriptionBox;

    public function SampleTableBox(offset:uint, size:uint) {
        super(offset, size);
    }

    public function get stsd():SampleDescriptionBox {
        return _stsd;
    }

    override protected function parseChildBox(type:String, offset:uint, size:uint, ba:ByteArray):Boolean {
        if (type == "stsd") {
            parseSampleDescriptionBox(offset, size, ba);
            return true;
        }

        return false;
    }

    private function parseSampleDescriptionBox(offset:uint, size:uint, ba:ByteArray):void {
        _stsd = new SampleDescriptionBox(offset, size);
        _stsd.parse(ba);
    }
}
}