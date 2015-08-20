package com.hls.model {
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;

	/** Fragment model **/
	public class Fragment {
		/** Duration of fragment **/
		public var duration:Number;
		/** Start time of the segment **/
		public var start_time:Number;
		/** data **/
		public var data:FragmentData;

		/** Create the fragment **/
		public function Fragment(input:IDataInput) {
			this.data = new FragmentData(input);
		}
	}
}