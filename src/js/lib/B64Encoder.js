'use strict';

var B64Worker = require("./B64Worker.js");

/**
 * This object manage the B64Worker, which encode data in B64
 * Indeed, since data may come from different track (ie audio/video),
 * we need this object, that will keep in memory a callback for each data it received
 * When the data has been encoded, the corresponding callback is called
 */
var B64Encoder = function() {

    var self = this,
        _b64w,
        _jobQueue = [],

        _createWorker = function() {
            //Build an inline worker that can be used with browserify
            var blobURL = URL.createObjectURL(new Blob(
                [ '(' + B64Worker.toString() + ')()' ],
                {type: 'application/javascript'}
            ));
            var worker = new Worker(blobURL);
            URL.revokeObjectURL(blobURL);
            return worker;
        },

        _encodeData = function (data, cb) {
            var jobIndex = _jobQueue.push({
                cb: cb
            }) -1;
            _b64w.postMessage({
                data: data,
                jobIndex: jobIndex
            });
        },

        _onWorkerMessage = function(e) {
            var jobIndex = e.data.jobIndex,
                job = _jobQueue[jobIndex];
            delete(_jobQueue[jobIndex]); //delete and not splice to avoid offsetting index
            job.cb(e.data.b64data);
        },

        _initialize = function(){
            _b64w = _createWorker();
            _b64w.onmessage = _onWorkerMessage;
        };

    _initialize();

    self.encodeData = _encodeData;
};

module.exports = B64Encoder;
