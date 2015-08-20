/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
 package com.hls.utils {
    public class PTS {
        /* find PTS value nearest a given reference PTS value 
         * 
         * PTS retrieved from demux are within a range of
         * (+/-) 2^32/90 - 1 = (+/-) 47721858
         * when reaching upper limit, PTS will loop to lower limit
         * this cause some issues with fragment duration calculation
         * this method will normalize a given PTS value and output a result 
         * that is closest to provided PTS reference value.
         * i.e it could output values bigger than the (+/-) 2^32/90.
         * this will avoid PTS looping issues.  
         */

        // Tweaked original function just to make sure pts never turns < 0.
        /*public static function normalize(reference : Number, value : Number) : Number {
            var offset : Number;
            // This case cannot happen, value is < (2^32)/90 and reference = (2^32)/90
            if (reference < value) {
                // - 2^32/90
                offset = -47721859;
            } else {
                // + 2^32/90
                offset = 47721859;
            }
            // 2^32 / 90
            while (!isNaN(reference) && (Math.abs(value - reference) > 47721859)) {
                value += offset;
            }
            return value;
        }*/

        public static function normalize(value : Number) : Number {
            if(value < 0) {
                // 2^32/90
                value += 47721859;
            }
            return value;
        }
    }
}
