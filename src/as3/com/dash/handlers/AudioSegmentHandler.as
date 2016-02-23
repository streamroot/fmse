/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

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

        message.duration     = sampleDuration * 1000 * 1000 / _timescale; //sampleDuration / _timescale;// * 1000

        message.length = sampleSize;

        message.dataOffset = dataOffset;

        message.data = new ByteArray();
        ba.position = message.dataOffset;
        ba.readBytes(message.data, 0, sampleSize);

        return message;
    }
}
}