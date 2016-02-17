
package com.dash.boxes {
import flash.utils.ByteArray;

public class HandlerReferenceBox extends FullBox {

    // 'vide', 'soun' or other values
    private var _type:String;

    public function HandlerReferenceBox(offset:uint, size:uint) {
        super(offset, size);
    }

    public function get type():String {
        return _type;
    }

    override protected function parseBox(ba:ByteArray):void {

        // skip QUICKTIME type
        ba.position += 4;

        _type = ba.readUTFBytes(4);
    }
}
}
