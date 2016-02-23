var CustomTimeRange = require('../lib/utils/CustomTimeRange');
require('should');

describe('CustomTimeRange module', function(){
    var GOODTIMERANGEARRAY = [{start: 0, end: 10}, {start: 21, end: 22}],
        customTimeRange;
    describe('Test CustomTimeRange.start good result handling', function(){
        it('should return the correct start value', function(){
            customTimeRange = new CustomTimeRange();
            customTimeRange.add(GOODTIMERANGEARRAY[0]);
            customTimeRange.add(GOODTIMERANGEARRAY[1]);
            customTimeRange.start(0).should.equal(0);
            customTimeRange.start(1).should.equal(21);
        });
    });
    describe('Test CustomTimeRange.start error handling', function(){
        it('should throw IndexOutOfRange error', function(){
            customTimeRange = new CustomTimeRange();
            customTimeRange.add(GOODTIMERANGEARRAY[0]);
            customTimeRange.start.bind(null, -1).should.throw("CustomTimeRange index out of range");
            customTimeRange.start.bind(null, 3).should.throw("CustomTimeRange index out of range");
        });
        it('should throw incorrect type error', function(){
            customTimeRange = new CustomTimeRange(GOODTIMERANGEARRAY);
            customTimeRange.add(GOODTIMERANGEARRAY[0]);
            customTimeRange.start.bind(null, null).should.throw("Incorrect index type");
            customTimeRange.start.bind(null, 4.5).should.throw("Incorrect index type");
            customTimeRange.start.bind(null, true).should.throw("Incorrect index type");
            customTimeRange.start.bind(null, false).should.throw("Incorrect index type");
            customTimeRange.start.bind(null, undefined).should.throw("Incorrect index type");
            customTimeRange.start.bind(null, "string").should.throw("Incorrect index type");
            customTimeRange.start.bind(null, NaN).should.throw("Incorrect index type");
        });
    });

    describe('Test CustomTimeRange.end good result handling', function(){
        it('should return the correct end value', function(){
            customTimeRange = new CustomTimeRange(GOODTIMERANGEARRAY);
            customTimeRange.add(GOODTIMERANGEARRAY[0]);
            customTimeRange.add(GOODTIMERANGEARRAY[1]);
            customTimeRange.end(0).should.equal(10);
            customTimeRange.end(1).should.equal(22);
        });
    });
    describe('Test CustomTimeRange.end error handling', function(){
        it('should throw IndexOutOfRange error', function(){
            customTimeRange = new CustomTimeRange(GOODTIMERANGEARRAY);
            customTimeRange.add(GOODTIMERANGEARRAY[0]);
            customTimeRange.end.bind(null, -1).should.throw("CustomTimeRange index out of range");
            customTimeRange.end.bind(null, 3).should.throw("CustomTimeRange index out of range");
        });
        it('should throw incorrect type error', function(){
            customTimeRange = new CustomTimeRange(GOODTIMERANGEARRAY);
            customTimeRange.add(GOODTIMERANGEARRAY[0]);
            customTimeRange.end.bind(null, null).should.throw("Incorrect index type");
            customTimeRange.end.bind(null, 4.5).should.throw("Incorrect index type");
            customTimeRange.end.bind(null, true).should.throw("Incorrect index type");
            customTimeRange.end.bind(null, false).should.throw("Incorrect index type");
            customTimeRange.end.bind(null, undefined).should.throw("Incorrect index type");
            customTimeRange.end.bind(null, "string").should.throw("Incorrect index type");
            customTimeRange.end.bind(null, NaN).should.throw("Incorrect index type");
        });
    });
});

