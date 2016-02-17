"use strict";

var CustomTimeRange = function(timeRangeArray = []) {
    var _timeRangeArray = timeRangeArray;

    this.length = _timeRangeArray.length;

    this.add = function(segment) {
        _timeRangeArray.push(segment);
        this.length = _timeRangeArray.length;
    };

    this.start = function(i) {
        if (isInteger(i) && i >= 0 && i < _timeRangeArray.length) {
            return _timeRangeArray[i].start;
        } else {
            // console.error('Index out of range');
            // if(Number.isInteger(i)){ // Comes with ECMAScript 6. Only works in Chrome and Firefox. "Enable Experimental Javascript" flag in Chrome
            if (isInteger(i)) {
                throw new Error("CustomTimeRange index out of range");
            } else {
                throw new Error("Incorrect index type");
            }
        }
    };

    this.end = function(i) {
        if (isInteger(i) && i >= 0 && i < _timeRangeArray.length) {
            return _timeRangeArray[i].end;
        } else {
            // console.error('Index out of range');
            // if(Number.isInteger(i)){ // Comes with ECMAScript 6. Only works in Chrome and Firefox. "Enable Experimental Javascript" flag in Chrome
            if (isInteger(i)) {
                throw new Error("CustomTimeRange index out of range");
            } else {
                throw new Error("Incorrect index type");
            }
        }
    };
};

function isInteger(n) {
    return (typeof n === "number" && n % 1 === 0);
}

module.exports = CustomTimeRange;
