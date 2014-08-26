
package com.dash.handlers {
import com.dash.boxes.FLVTag;
import com.dash.boxes.SampleEntry;

import flash.utils.ByteArray;

public class InitializationVideoSegmentHandler extends InitializationSegmentHandler {
    public function InitializationVideoSegmentHandler(ba:ByteArray) {
        super(ba);
    }

    override protected function get expectedTrackType():String {
        return 'vide';
    }

    protected override function buildMessage(sampleEntry:SampleEntry):FLVTag {
        var message:FLVTag = new FLVTag();

        message.markAsVideo();

        message.timestamp = 0;

        message.length = sampleEntry.data.length;

        message.data = new ByteArray();
        sampleEntry.data.readBytes(message.data, 0, sampleEntry.data.length);

        message.frameType = FLVTag.UNKNOWN;

        message.compositionTimestamp = 0;

        message.setup = true;

        return message;
    }
}
}
