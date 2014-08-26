
package com.dash.handlers {
import com.dash.boxes.FLVTag;
import com.dash.boxes.Muxer;

import flash.utils.ByteArray;

public class AudioSegmentHandler extends MediaSegmentHandler {
    public function AudioSegmentHandler(segment:ByteArray, messages:Vector.<FLVTag>,
                                        defaultSampleDuration:uint, timescale:uint, timestamp:Number,  mixer:Muxer) {
        super(segment, messages, defaultSampleDuration, timescale, timestamp, mixer);
    }

    protected override function buildMessage(sampleDuration:uint, sampleSize:uint, sampleDependsOn:uint,
                                             sampleIsDependedOn:uint, compositionTimeOffset:Number,
                                             dataOffset:uint, ba:ByteArray):FLVTag {
        var message:FLVTag = new FLVTag();

        message.markAsAudio();

        message.timestamp = _timestamp;
        _timestamp = message.timestamp + sampleDuration * 1000 / _timescale;

		message.duration 	= sampleDuration / _timescale;// * 1000
		
        message.length = sampleSize;

        message.dataOffset = dataOffset;

        message.data = new ByteArray();
        ba.position = message.dataOffset;
        ba.readBytes(message.data, 0, sampleSize);

        return message;
    }
}
}