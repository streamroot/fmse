
package com.dash.handlers {
import com.dash.boxes.FLVTag;
import com.dash.boxes.SampleEntry;

import flash.utils.ByteArray;

public class InitializationAudioSegmentHandler extends InitializationSegmentHandler {
    public function InitializationAudioSegmentHandler(ba:ByteArray) {
        super(ba);
    }

    override protected function get expectedTrackType():String {
        return 'soun';
    }

    protected override function buildMessage(sampleEntry:SampleEntry):FLVTag {
        var message:FLVTag = new FLVTag();

        message.markAsAudio();

        message.timestamp = 0;

        message.length = sampleEntry.data.length;

        message.data = new ByteArray();
        sampleEntry.data.readBytes(message.data, 0, sampleEntry.data.length);

        message.setup = true;

        return message;
    }
}
}
