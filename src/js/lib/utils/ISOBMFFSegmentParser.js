"use strict";

var ISOBMFFSegmentParser = function(segmentData) {
    var self = this,

        _segmentData = segmentData,
        _isInitSegment = false,
        _initSegmentType = "InitializationSegment",
        _mediaSegmentType = "MediaSegment",
        _segmentTimeScale = NaN,
        _segmentStartTime = NaN,
        _segmentEndTime = NaN,
        _segmentDuration = NaN,
        _majorBrand,
        _compatBrands,
        _majorBrandLen = 8,
        _compatBrandsLen = 8,
        _typeBoxOffset = 4,
        _int32Size = 4,
        _int64Size = 8,
        _ftyp = "ftyp",
        _styp = "styp",
        _sidx = "sidx",
        _moov = "moov",
        _moof = "moof",
        _mdat = "mdat",
        _mvhd = "mvhd",
        _mvex = "mvex",
        _trak = "trak",
        _tkhd = "tkhd",
        _tfhd = "tfhd",
        _tfdt = "tfdt",
        _trun = "trun",
        _mdia = "mdia",
        _mdhd = "mdhd",
        _ftypRegex = /ftyp..../,
        _stypRegex = /styp..../,
        // Matches either the moov or the moof atoms.
        _moovRegex = /moo[vf]/,
        _mdatRegex = /mdat.*/,
        _sidxRegex = /sidx.*/,
        _tfhdRegex = /tfhd.*/,
        _tfdtRegex = /tfdt.*/,
        _trunRegex = /trun.*/,
        _mvhdRegex = /mvhd.*/,
        _mdhdRegex = /mdhd.*/,
        _sidxVersionLength = 1,
        _sidxFlagsLength = 3,
        _sidxSkipReservedBytes = 2,
        _sidxNumSubSegmentsBytes = 2,
        _sidxSubSegmentRefBytes = 4,
        _sidxSubSegmentDurationBytes = 4,
        _sidxPresTimeAndOffsetBytes,
        _sidxEarliestPresTime,
        _sidxStartOffset,
        _sidxNumSubSegments,
        _sidxTotalSubSegmentDuration,

        _tfhdVersionLength = 1,
        _tfhdFlagsLength = 3,
        _tfhdTrackIDLength = 4,
        _tfhdBaseDataOffsetBytes = _int64Size,
        _tfhdBaseDataOffsetFlagValue = 0x000001,
        _tfhdDurationEmptyFlagValue = 0x010000,
        _tfhdBaseDataOffset,
        _tfhdBaseDataOffsetPresent = false,
        _tfhdDurationEmpty = false,

        _tfdtVersionLength = 1,
        _tfdtFlagsLength = 3,
        _tdftBaseMediaDecodeTime,

        _trunVersionLength = 1,
        _trunFlagsLength = 3,
        _trunSampleCountBytes = _int32Size,
        _trunSampleCount,
        _trunDataOffsetBytes = _int32Size,
        _trunDataOffsetPresent = false,
        _trunDataOffset,
        _trunFirstSampleFlagsPresent = false,
        _trunFirstSampleFlagsBytes = _int32Size,
        _trunSampleDurationPresent = false,
        _trunSampleDurationBytes = _int32Size,
        _trunSampleSizePresent = false,
        _trunSampleSizeBytes = _int32Size,
        _trunSampleFlagsPresent = false,
        _trunSampleFlagsBytes = _int32Size,
        _trunSampleCompositionOffsetPresent = false,
        _trunSampleCompositionOffsetBytes = _int32Size,
        _trunSampleCompositionOffsetIsSignedInt = false,
        _trunDataOffsetFlagValue = 0x000001,
        _trunFirstSampleFlagsPresentFlagValue = 0x000004,
        _trunSampleDurationPresentFlagValue = 0x000100,
        _trunSampleSizePresentFlagValue = 0x000200,
        _trunSampleFlagsPresentFlagValue = 0x000400,
        _trunSampleCompositionTimeOffsetPresentFlagValue = 0x000800,
        _trunSampleCompositionOffset,

        _mvhdVersionLength = 1,
        _mvhdValuesBytes,

        _moovFound = false,
        _mdatFound = false,
        _sidxFound = false,
        _tfhdFound = false,
        _tfdtFound = false,
        _trunFound = false,
        _mvhdFound = false,
        _mdhdFound = false,

        /**
         * Converts an array buffer that constitutes segment data to string type.
         * Needed for any regex matches in headers.
         */
    _arrayBufferToString = function(buffer) {
        return String.fromCharCode.apply(null, new Uint8Array(buffer));
    },

    /**
     * Converts a string buffer back to an array buffer.
     */
    _stringToArrayBuffer = function(str) {
        var buf = new ArrayBuffer(str.length);
        var bufView = new Uint8Array(buf);

        for (var i=0, strLen=str.length; i < strLen; i++) {
            bufView[i] = str.charCodeAt(i);
        }

        return buf;
    },

    /**
     * Takes in an array of unsigned integers in hex byte format.
     * Concatenates into a hex string. Finally converts the hex value
     * in the string to decimal value. Useful to parse out values of
     * fixed sizes from mp4 boxes.
     */
    _intValueFromHexByteArray = function(arr) {
        var len = arr.length;
        var valueInHex = "";

        for (var idx = 0; idx < len; idx++) {
            valueInHex += arr[idx].toString(16);
        }

        return parseInt(valueInHex, 16);
    },

    /**
     * Parses the needed mp4 boxes to retrieve the timescale, the starting timestamp
     */
    _parseBoxes = function () {

        if (_segmentData.byteLength <= 0) {
            console.info("Segment length = " + _segmentData.byteLength + ". Unable to parse the segment for boxes. Segment with invalid length received.");
            return [this.segmentType, _segmentStartTime, _segmentEndTime];
        }

        var bufferStr = _arrayBufferToString(_segmentData);

        // Segment data is an ArrayBuffer. Slice and dice as needed to get the required parameters.
        try {

            var typeBuffer = _arrayBufferToString(_segmentData.slice(_typeBoxOffset, _typeBoxOffset + _majorBrandLen));
            var type = typeBuffer.match(_ftypRegex) !== null ? _ftyp : typeBuffer.match(_stypRegex) !== null ? _styp : null;

            // Look for the segment index box in the segment.
            var sidxRegexRes = _sidxRegex.exec(bufferStr);
            var tfhdRegexRes = null;
            var tfdtRegexRes = null;
            var trunRegexRes = null;
            var mvhdRegexRes = null;
            var mdhdRegexRes = null;

            _sidxFound = sidxRegexRes !== null ? sidxRegexRes[0].length > 0 : false;

            if (!_sidxFound) {
                tfhdRegexRes = _tfhdRegex.exec(bufferStr);
                _tfhdFound = tfhdRegexRes !== null ? tfhdRegexRes[0].length > 0 : false;

                tfdtRegexRes = _tfdtRegex.exec(bufferStr);
                _tfdtFound = tfdtRegexRes !== null ? tfdtRegexRes[0].length > 0 : false;

                trunRegexRes = _trunRegex.exec(bufferStr);
                _trunFound = trunRegexRes !== null ? trunRegexRes[0].length > 0 : false;

                mvhdRegexRes = _mvhdRegex.exec(bufferStr);
                _mvhdFound = mvhdRegexRes !== null ? mvhdRegexRes[0].length > 0 : false;

                mdhdRegexRes = _mdhdRegex.exec(bufferStr);
                _mdhdFound = mdhdRegexRes !== null ? mdhdRegexRes[0].length > 0 : false;
            }


            switch(type) {
            case _styp:
                // An styp box was downloaded.
                _isInitSegment = false;

                break;

            case _ftyp:
                // having an ftyp box could mean it is an init segment or a media segment.
                // Check for the presence of the moov and mdat boxes.
                var mdatRegexRes = _mdatRegex.exec(bufferStr);
                var moovRegexRes = _moovRegex.exec(bufferStr);

                _moovFound = moovRegexRes !== null ? moovRegexRes[0].length == _moov.length : false;

                _mdatFound = mdatRegexRes !== null ? mdatRegexRes[0].length > 0 : false;

                // Init segment is detected by the presence of a moov box but no mdat box.
                _isInitSegment = (_moovFound && !_mdatFound) ? true : false;

                break;

            default:
                console.info ("Unrecognized segment type.");
                return [this.segmentType, _segmentStartTime, _segmentEndTime];
            }


            // If the segment index box exists, parse timestamps from it.
            if (_sidxFound) {
                _parseSidxBoxForTimestamps(sidxRegexRes.index);
            }
            else {
                [_segmentTimeScale, _segmentDuration] = (_mvhdFound) ? _parseTimeScaleFromHeaders(_mvhd, mvhdRegexRes[0].index) : (_mdhdFound) ? _parseTimeScaleFromHeaders(_mdhd, mdhdRegexRes[0].index) : NaN;

                if (_tfhdFound && _tfdtFound && _trunFound) {
                    _parseTrackBoxesForTimestamps(tfhdRegexRes[0].index, tfdtRegexRes[0].index, trunRegexRes[0].index);
                }
            }

            return [this.segmentType, _segmentStartTime, _segmentEndTime];

        }
        catch (e) {
            console.error (e.name, e.message);
            console.info ("Error parsing the segment boxes.");
            return [this.segmentType, _segmentStartTime, _segmentEndTime];
        }
    },

    _parseTimeScaleFromHeaders = function(boxType, index) {
        try {
            // mvhd and mdhd both have the same structure nearly for parsing out the timescale.
            var runningIndex = 0;
            var segmentTimeScale = NaN;
            var segmentDuration = NaN;

            var header = _segmentData.slice(index);

            var hdData = header.slice(_mvhd.length);

            var version  = hdData.slice(runningIndex, _mvhdVersionLength);
            var _mvhdValuesBytes = (version === "1") ? _int64Size : _int32Size;

            // Skip the creation and modification times.
            runningIndex += _mvhdVersionLength + 2*_mvhdValuesBytes;

            var _segmentTimeScaleArray = new Uint8Array(hdData.slice(runningIndex, runningIndex + _int32Size));
            segmentTimeScale = _intValueFromHexByteArray(_segmentTimeScaleArray);
            runningIndex += _int32Size;

            var _segmentDurationArray = new Uint8Array(hdData.slice(runningIndex, runningIndex + _mvhdValuesBytes));
            segmentDuration = (_intValueFromHexByteArray(_segmentDurationArray) / segmentTimeScale).toFixed(2);;
            runningIndex += _mvhdValuesBytes;

            return [segmentTimeScale, segmentDuration];
        }
        catch (e) {
            console.info("Error getting timescale value from the headers.");
            return [NaN, NaN];
        }
    },

    /**
     * The segment index box contains information like the timescale, the starting timestamp and duration
     * for each sub-segment that constitutes the current segment.
     */
    _parseSidxBoxForTimestamps = function(idx) {
        try {
            var buffer = _segmentData.slice(idx);
            var runningIndex = 0;

            // Remove the sidx header from the buffer.
            var sidxData = buffer.slice(_sidx.length);

            var version = sidxData.slice(0, _sidxVersionLength);

            runningIndex += _sidxVersionLength;
            var flags = sidxData.slice(runningIndex, runningIndex + _sidxFlagsLength);

            runningIndex += _sidxFlagsLength;
            var referenceID = sidxData.slice(runningIndex, runningIndex + _int32Size);

            // Segment timescale needed to get the start and end timestamps.
            runningIndex += _int32Size;
            var _segmentTimeScaleArray = new Uint8Array(sidxData.slice(runningIndex, runningIndex + _int32Size));
            _segmentTimeScale = _intValueFromHexByteArray(_segmentTimeScaleArray);

            runningIndex += _int32Size;
            _sidxPresTimeAndOffsetBytes = version === "0" ? _int32Size : _int64Size;

            var presTimeArray = new Uint8Array(sidxData.slice(runningIndex, runningIndex + _sidxPresTimeAndOffsetBytes));
            _sidxEarliestPresTime = _intValueFromHexByteArray(presTimeArray);

            // Get the segment start time.
            _segmentStartTime = (_sidxEarliestPresTime / _segmentTimeScale).toFixed(2);
            console.log("Segment Presentation Start Time: ", _segmentStartTime);

            runningIndex += _sidxPresTimeAndOffsetBytes;
            var startOffsetArray = new Uint8Array(sidxData.slice(runningIndex, runningIndex + _sidxPresTimeAndOffsetBytes));
            _sidxStartOffset = _intValueFromHexByteArray(startOffsetArray);

            runningIndex += _sidxPresTimeAndOffsetBytes + _sidxSkipReservedBytes;
            var subSegmentsArray = new Uint8Array(sidxData.slice(runningIndex, runningIndex + _sidxNumSubSegmentsBytes));
            _sidxNumSubSegments = _intValueFromHexByteArray(subSegmentsArray);

            runningIndex += _sidxNumSubSegmentsBytes;
            var subSegmentDur = 0;

            // Run through each sub segment in the box and add up the durations.
            for (var eachSeg:int = 0; eachSeg < _sidxNumSubSegments; eachSeg++) {
                // Skip the reference type and size.
                runningIndex += _sidxSubSegmentRefBytes;

                // Now get the sub segment durations.
                var subSegmentDurationArray = new Uint8Array(sidxData.slice(runningIndex, runningIndex + _sidxSubSegmentDurationBytes));
                subSegmentDur += _intValueFromHexByteArray(subSegmentDurationArray);
            }

            // Get the segment end time.
            _sidxTotalSubSegmentDuration = subSegmentDur;
            _segmentEndTime = ((_sidxEarliestPresTime + _sidxTotalSubSegmentDuration) / _segmentTimeScale).toFixed(2);
            console.log("Segment Presentation End Time: ", _segmentEndTime);

        }
        catch (e) {
            console.info ("Error parsing segment index box data. Unable to retrieve timestamps from the segment data.")
        }

    },

    _parseTrackBoxesForTimestamps = function(tfhdIndex, tfdtIndex, trunIndex) {
        try {
            var tfhdBuffer = _segmentData.slice(tfhdIndex);
            var tfhdData = tfhdBuffer.slice(_tfhd.length);
            var runningIndex = 0;

            var version = tfhdData.slice(0, _tfhdVersionLength);

            runningIndex += _tfhdVersionLength;
            var tf_flags = tfhdData.slice(runningIndex, runningIndex + _tfhdFlagsLength);

            _tfhdBaseDataOffsetPresent = tf_flags & _tfhdBaseDataOffsetFlagValue;
            _tfhdDurationEmpty = tf_flags & _tfhdDurationEmptyFlagValue;

            if (_tfhdDurationEmpty)
            {
                console.info ("Duration is empty set to true in the tfhd box. There are no track runs. Relying on the track fragment data box.");
                return;
            }

            if (_tfhdBaseDataOffsetPresent)
            {
                runningIndex += _tfhdFlagsLength + _tfhdTrackIDLength;
                _tfhdBaseDataOffset = tfhdData.slice(runningIndex, runningIndex + _tfhdBaseDataOffsetBytes);
            }

            var tfdtBuffer = _segmentData.slice(tfdtIndex);
            var tfdtData = tfdtBuffer.slice(_tfdt.length);
            runningIndex = 0;

            var version = tfdtData.slice(0, _tfdtVersionLength);

            runningIndex += _tfdtVersionLength;
            var flags = sidxData.slice(runningIndex, runningIndex + _tfdtFlagsLength);

            runningIndex += _tfdtFlagsLength;

            var _baseMediaDecodeTimeBytes  = (version == "1") ? _int64Size : _int32Size;
            var baseMediaDecodeTimeArray = new Uint8Array(tfdtData.slice(runningIndex, runningIndex + _baseMediaDecodeTimeBytes));
            _tfdtBaseMediaDecodeTime = _intValueFromHexByteArray(baseMediaDecodeTimeArray);


            var trunBuffer = _segmentData.slice(trunIndex);
            var trunData = trunBuffer.slice(_trun.length);
            runningIndex = 0;

            var version = trunBuffer.slice(0, _trunVersionLength);
            runningIndex += _trunVersionLength;

            var trunFlags = trunBuffer.slice(runningIndex, runningIndex + _trunFlagsLength);
            runningIndex += _trunFlagsLength;

            var trunSampleCountArray = new Uint8Array(trunData.slice(runningIndex, runningIndex + _trunSampleCountBytes));
            _trunSampleCount = _intValueFromHexByteArray(trunSampleCountArray);
            runningIndex += _trunSampleCountBytes;

            _trunDataOffsetPresent = trunFlags & _trunDataOffsetFlagValue;
            _trunFirstSampleFlagsPresent = trunFlags & _trunFirstSampleFlagsPresentFlagValue;
            _trunSampleDurationPresent = trunFlags & _trunSampleDurationPresentFlagValue;
            _trunSampleSizePresent = trunFlags & _trunSampleSizePresentFlagValue;
            _trunSampleFlagsPresent = trunFlags & _trunSampleFlagsPresentFlagValue;
            _trunSampleCompositionOffsetPresent = trunFlags & _trunSampleCompositionTimeOffsetPresentFlagValue;
            _trunSampleCompositionOffsetIsSignedInt = version !== "0";

            if (_trunDataOffsetPresent)
            {
                var trunDataOffsetArray = new Uint8Array(trunBuffer.slice(runningIndex, runningIndex + _trunDataOffsetBytes));
                _trunDataOffset = _intValueFromHexByteArray(trunDataOffsetArray);
                runningIndex += _trunDataOffsetBytes;
            }

            runningIndex = (_trunFirstSampleFlagsPresent) ? runningIndex + _trunFirstSampleFlagsBytes : runningIndex;
            var totalSampleDur = 0;

            for (var eachSample:int = 0; eachSample < _trunSampleCount; eachSample++) {

                if (_trunSampleDurationPresent)
                {
                    var trunSampleDurationArray = new Uint8Array(trunBuffer.slice(runningIndex, runningIndex + _trunSampleDurationBytes));
                    totalSampleDur += _intValueFromHexByteArray(trunSampleDurationArray);
                    runningIndex += _trunSampleDurationBytes;
                }

                // Skip over sample size and sample flags fields.
                runningIndex = (_trunSampleSizePresent) ? runningIndex + _trunSampleSizeBytes : runningIndex;
                runningIndex = (_trunSampleFlagsPresent) ? runningIndex + _trunSampleFlagsBytes : runningIndex;

                // If no CTS offset is present, treat the decode time in the tfdt box as the presentation time.
                if (!_trunSampleCompositionOffsetPresent)
                {
                    _trunSampleCompositionOffset = _tfdtBaseMediaDecodeTime;
                    _segmentStartTime = (_trunSampleCompositionOffset / _segmentTimeScale).toFixed(2);
                    _segmentEndTime = (!isNaN(_segmentDuration)) ? _segmentStartTime + _segmentDuration : NaN;
                }
                // Get the composition offset only for the first frame.
                else
                {
                    if (eachSample == 0) {
                        // Still need to make the signed vs. unsigned differentiation.
                        var trunSampleCompositionOffsetArray = new Uint8Array(trunBuffer.slice(runningIndex, runningIndex + _trunSampleCompositionOffsetBytes));
                        _trunSampleCompositionOffset = _intValueFromHexByteArray(trunSampleCompositionOffsetArray);
                        console.log("CTS OFFSET IN FIRST SAMPLE FRAME: ", _trunSampleCompositionOffset);
                        _segmentStartTime = ((_tfdtBaseMediaDecodeTime + _trunSampleCompositionOffset) / _segmentTimeScale).toFixed(2);
                        console.log("START TIME BASED ON THE FIRST SAMPLE FRAME: ", _segmentStartTime);
                    }

                    runningIndex += _trunSampleCompositionOffsetBytes;
                }
            }

            _segmentDuration = (totalSampleDur / _segmentTimeScale).toFixed(2);
            _segmentEndTime  = _segmentStartTime + _segmentDuration;

        }
        catch (e) {
            console.info ("Error parsing track fragment box data. Unable to retrieve timestamps from the track data either.")
        }
    }

    // Define a getter and setter for initSegParsed.
    Object.defineProperty(this, 'segmentType', {
get: function() {
            return _isInitSegment == false ? _mediaSegmentType : _initSegmentType;
        }
    });

    this.parseBoxes = _parseBoxes;

};

module.exports = ISOBMFFSegmentParser;
