
package com.dash.boxes {

import flash.utils.ByteArray;

public class SampleDescriptionBox extends FullBox {
    private var _sampleEntries:Vector.<SampleEntry> = new Vector.<SampleEntry>();

    public function SampleDescriptionBox(offset:uint, size:uint) {
        super(offset, size);
    }

    public function get sampleEntries():Vector.<SampleEntry> {
        return _sampleEntries;
    }

    override protected function parseBox(ba:ByteArray):void {
        var sampleEntriesLength:uint = ba.readUnsignedInt();

        for (var i:uint = 0; i < sampleEntriesLength; i++) {
            var offset:uint = ba.position;
            var size:uint = ba.readUnsignedInt();
            var type:String = ba.readUTFBytes(4);

            parseSampleEntry(offset, size, type, ba);
        }
    }

    private function parseSampleEntry(offset:uint, size:uint, type:String, ba:ByteArray):void {
        var sampleEntry:SampleEntry = new SampleEntry(offset, size, type);
        sampleEntry.parse(ba);
        _sampleEntries.push(sampleEntry);
    }
}
}