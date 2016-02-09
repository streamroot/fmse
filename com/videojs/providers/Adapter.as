package com.videojs.providers{

    import com.dash.loaders.FragmentLoader;
    import com.dash.events.MessageEvent;

    //import com.dash.handlers.InitializationAudioSegmentHandler;
    import com.dash.handlers.InitializationSegmentHandler;
    import com.dash.handlers.InitializationVideoSegmentHandler;
    import com.dash.handlers.VideoSegmentHandler;

    import com.dash.boxes.Muxer;
    //import com.dash.utils.Base64;

    import flash.utils.ByteArray;
    import flash.external.ExternalInterface;

    public class Adapter {
        public var data_parsed:ByteArray;
        public var data_parsed_init:ByteArray;
        public var handler:InitializationSegmentHandler;
        private var _videoSegmentHandler:VideoSegmentHandler;
        private var _mixer:Muxer;


        public function Adapter(){
            _mixer  = new Muxer();
        }

        public function parseData(bytes:ByteArray):void{
            data_parsed = bytes;
            var bytes_append:ByteArray = new ByteArray();
            _videoSegmentHandler = new VideoSegmentHandler(bytes, handler.messages, handler.defaultSampleDuration, handler.timescale, 0, _mixer);
        }

        public function parseDataInit(bytes:ByteArray):void{
            ExternalInterface.call("console.log", "InitializationVideoSegmentHandler");
            handler 	= new InitializationVideoSegmentHandler(bytes);
        }

        public function appendFileHeader():ByteArray {
        var output:ByteArray = new ByteArray();
        output.writeByte(0x46);	// 'F'
        output.writeByte(0x4c); // 'L'
        output.writeByte(0x56); // 'V'
        output.writeByte(0x01); // version 0x01

        var flags:uint = 0;

        flags |= 0x01;

        output.writeByte(flags);

        var offsetToWrite:uint = 9; // minimum file header byte count

        output.writeUnsignedInt(offsetToWrite);

        var previousTagSize0:uint = 0;

        output.writeUnsignedInt(previousTagSize0);

        return output;
        }

    }
}
