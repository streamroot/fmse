package com.hlsmangui {
	import flash.utils.ByteArray;

	/** Fragment model **/
	public class Fragment {
		/** Duration of fragment **/
		public var duration:Number;
		/** Start time of the segment **/
		public var start_time:Number;
		/** Sequence number of this segment **/
		public var seqnum:int;
		/** data **/
		public var data:FragmentData;

		/** Create the fragment **/
		public function Fragment(seqnum:int, input:ByteArray) {
			this.seqnum = seqnum;
			this.data = new FragmentData(input);
		}
	}
}