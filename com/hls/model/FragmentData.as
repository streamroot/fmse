package com.hls.model {
    import flash.utils.ByteArray;
    import com.hls.FLVTag;
    import flash.utils.IDataInput;

    /** Fragment Data **/
    public class FragmentData {
        /** Fragment byte array **/
        public var bytes:ByteArray;
        /**Start PTS of this fragment **/
        public var pts_start:Number;
        /** computed Start PTS of this chunk. **/
        public var pts_start_computed : Number;
        /** min/max audio/video PTS of this fragment **/
        public var pts_min_audio : Number;
        public var pts_max_audio : Number;
        public var pts_min_video : Number;
        public var pts_max_video : Number;
        /** audio/video found ? */
        public var audio_found : Boolean;
        public var video_found : Boolean;
        /** tag related stuff */
        public var tags_pts_min_audio : Number;
        public var tags_pts_max_audio : Number;
        public var tags_pts_min_video : Number;
        public var tags_pts_max_video : Number;
        public var tags_audio_found : Boolean;
        public var tags_video_found : Boolean;
        public var tags : Vector.<FLVTag>;

        public var video_width : Number = 0;
        public var video_height : Number = 0;

        /** Fragment Metrics **/
        public function FragmentData(input:IDataInput) {
            this.pts_start = NaN;
            this.pts_start_computed = NaN;
            this.bytes = ByteArray(input);
        };

        public function get pts_min() : Number {
            if (audio_found) {
                return pts_min_audio;
            } else {
                return pts_min_video;
            }
        }

        public function get pts_max() : Number {
            if (audio_found) {
                return pts_max_audio;
            } else {
                return pts_max_video;
            }
        }

        public function get tag_pts_min() : Number {
            if (audio_found) {
                return tags_pts_min_audio;
            } else {
                return tags_pts_min_video;
            }
        }

        public function get tag_pts_max() : Number {
            if (audio_found) {
                return tags_pts_max_audio;
            } else {
                return tags_pts_max_video;
            }
        }

        public function get tag_pts_start_offset() : Number {
            if (tags_audio_found) {
                return tags_pts_min_audio - pts_min_audio;
            } else {
                return tags_pts_min_video - pts_min_video;
            }
        }

        public function get tag_pts_end_offset() : Number {
            if (tags_audio_found) {
                return tags_pts_max_audio - pts_min_audio;
            } else {
                return tags_pts_max_video - pts_min_video;
            }
        }
    }

}