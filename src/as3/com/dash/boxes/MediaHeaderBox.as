
package com.dash.boxes {
import flash.utils.ByteArray;

public class MediaHeaderBox extends FullBox {
    private var _timescale:uint;

    public function MediaHeaderBox(offset:uint, size:uint) {
        super(offset, size);
    }

    public function get timescale():uint {
        return _timescale;
    }

    override protected function parseBox(ba:ByteArray):void {
        if (version == 1) {
            parseVersion1(ba);
        }

        if (version == 0) {
            parseVersion2(ba);
        }
    }

    private function parseVersion1(ba:ByteArray):void {

//        // creation time MSB
//        ba.readUnsignedInt();  // 4 bytes
//        // creation time LSB
//        ba.readUnsignedInt();  // 4 bytes
//        // modification time MSB
//        ba.readUnsignedInt();  // 4 bytes
//        // modification time LSB
//        ba.readUnsignedInt();  // 4 bytes

        // skip
        ba.position += 16;

        // timescale
        _timescale = ba.readUnsignedInt(); // 4 bytes
    }

    private function parseVersion2(ba:ByteArray):void {

//        // creation time LSB
//        ba.readUnsignedInt(); // 4 bytes
//        // modification time LSB
//        ba.readUnsignedInt(); // 4 bytes

        // skip
        ba.position += 8;

        // timescale
        _timescale = ba.readUnsignedInt();
    }
}
}