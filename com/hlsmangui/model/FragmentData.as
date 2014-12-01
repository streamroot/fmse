package com.hlsmangui.model {
	import flash.utils.ByteArray;

	/** Fragment Data **/
	public class FragmentData {
		/** Fragment byte array **/
		public var bytes:ByteArray;
		/**Start PTS of this fragment **/
		public var pts_start:Number;
		/** min/max audio/video PTS of this fragment **/
		public var pts_min_audio : Number;
        public var pts_max_audio : Number;
        public var pts_min_video : Number;
        public var pts_max_video : Number;
        /** tag related stuff */
        public var tags_pts_min_audio : Number;
        public var tags_pts_max_audio : Number;
        public var tags_pts_min_video : Number;
        public var tags_pts_max_video : Number;
        public var tags_audio_found : Boolean;
        public var tags_video_found : Boolean;
        public var tags : Vector.<FLVTag>;

        /** Fragment Metrics **/
        public function FragmentData(input:ByteArray) {
            this.pts_start = NaN;
            this.pts_start_computed = NaN;
            this.bytes = input;
        };
	}
	
}