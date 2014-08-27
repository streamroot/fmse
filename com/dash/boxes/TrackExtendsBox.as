

package com.dash.boxes {
import flash.utils.ByteArray;

public class TrackExtendsBox extends FullBox {
    private var _trackId:uint;
    private var _defaultSampleDuration:uint;

    public function TrackExtendsBox(offset:uint, size:uint) {
        super(offset, size);
    }

    public function get trackId():uint {
        return _trackId;
    }

    public function get defaultSampleDuration():uint {
        return _defaultSampleDuration;
    }

    override protected function parseBox(ba:ByteArray):void {

        // track ID
        _trackId = ba.readUnsignedInt();

//        // default sample description index
//        ba.readUnsignedInt(); // 4 bytes

        // skip
        ba.position += 4;

        _defaultSampleDuration = ba.readUnsignedInt();
    }
}
}