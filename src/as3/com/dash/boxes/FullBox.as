
package com.dash.boxes {
import flash.errors.IllegalOperationError;
import flash.utils.ByteArray;

public class FullBox extends Box {
    private var _version:uint;
    private var _flags:uint;

    public function FullBox(offset:uint, size:uint) {
        super(offset, size);
    }

    public function get version():uint {
        return _version;
    }

    public function get flags():uint {
        return _flags;
    }

    public override function parse(ba:ByteArray):void {
        parseVersion(ba);
        parseFlags(ba);

        parseBox(ba);

        ba.position = end;
    }

    protected function parseBox(ba:ByteArray):void {
        throw new IllegalOperationError("Method not implemented");
    }

    private function parseVersion(ba:ByteArray):void {
        _version = ba.readUnsignedByte();
    }

    private function parseFlags(ba:ByteArray):void {
        _flags = 0;

        for (var i:uint = 0; i < 3; i++) {
            _flags = _flags << 8;
            _flags += ba.readUnsignedByte();
        }
    }
}
}