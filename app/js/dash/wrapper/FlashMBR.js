"use strict";


var FlashMBR = function (mediaController, swfObj) {
    var self = this,
        
        _mediaController = mediaController,
        _swfObj = swfObj,
        
        _trackList = [],
        
        _addTrackList = function (trackList) {
            //TODO: get actual tracklist from map
            var trackListString = "",
                track,
                i;
            for (i=0; i<trackList.length; i++) {
                track = trackList[i];
                if (track.type === "video") {
                    if (!track.label) {
                        if (track.height) {
                            track.label = track.height + "p";
                        } else {
                            track.label = track.bandwidth / 1000 + "kbps";
                        }
                    }
                    
                    _trackList.push(track);
                    
                    if (trackListString.length !== 0) {
                        trackListString += ",";
                    }
                    if (track.selected) {
                        trackListString += "*";
                    }
                    trackListString += track.label;
                }
            }
            
            _swfObj.onTrackList(trackListString);
        },
        
        _onQualityChangeRequest = function (quality) {
            var track = _trackList[quality];
            _mediaController.manualSwitchRepresentation(track.type, track.id_aset, track.id_rep);
        },
        
        _initialize = function () {
            window.sr_request_quality_change = function(quality) {
                _onQualityChangeRequest(quality);
            };
        };
    
    this.addTrackList = function (trackList) {
        _addTrackList(trackList);
    };
        
    _initialize();
};

module.exports = FlashMBR;