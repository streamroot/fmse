package com.videojs{

    import com.videojs.events.VideoJSEvent;
    import com.videojs.structs.ExternalEventName;

    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.external.ExternalInterface;
    import flash.geom.Rectangle;
    import flash.system.Security;
    import flash.ui.ContextMenu;
    import flash.utils.Timer;

    [SWF(backgroundColor="#000000", frameRate="60", width="480", height="270")]
    public class VideoJS extends Sprite{

        private var _app:VideoJSApp;
        private var _stageSizeTimer:Timer;

        public function VideoJS(){
            _stageSizeTimer = new Timer(250);
            _stageSizeTimer.addEventListener(TimerEvent.TIMER, onStageSizeTimerTick);
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }

        private function init():void{
            // Allow JS calls from other domains
            Security.allowDomain("*");
            Security.allowInsecureDomain("*");

            if(loaderInfo.hasOwnProperty("uncaughtErrorEvents")){
                // we'll want to suppress ANY uncaught debug errors in production (for the sake of ux)
                // IEventDispatcher(loaderInfo["uncaughtErrorEvents"]).addEventListener("uncaughtError", onUncaughtError);
            }

            _app = new VideoJSApp();
            addChild(_app);

            _app.model.stageRect = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);

            var _ctxMenu:ContextMenu = new ContextMenu();
            _ctxMenu.hideBuiltInItems();
            this.contextMenu = _ctxMenu;

            finish();
        }

        private function finish():void{

            if(loaderInfo.parameters.mode != undefined){
                _app.model.mode = loaderInfo.parameters.mode;
            }

            if(loaderInfo.parameters.eventProxyFunction != undefined){
                _app.model.jsEventProxyName = loaderInfo.parameters.eventProxyFunction;
            }

            if(loaderInfo.parameters.errorEventProxyFunction != undefined){
                _app.model.jsErrorEventProxyName = loaderInfo.parameters.errorEventProxyFunction;
            }

            if(loaderInfo.parameters.autoplay != undefined && loaderInfo.parameters.autoplay == "true"){
                _app.model.autoplay = true;
            }

            if(loaderInfo.parameters.preload != undefined && loaderInfo.parameters.preload == "true"){
                _app.model.preload = true;
            }

            if(loaderInfo.parameters.poster != undefined && loaderInfo.parameters.poster != ""){
                _app.model.poster = String(loaderInfo.parameters.poster);
            }

            if(loaderInfo.parameters.src != undefined && loaderInfo.parameters.src != ""){
              if (isExternalMSObjectURL(loaderInfo.parameters.src)) {
                _app.model.srcFromFlashvars = null;
                openExternalMSObject(loaderInfo.parameters.src);
              } else {
                _app.model.srcFromFlashvars = String(loaderInfo.parameters.src);
              }
            }

            if(loaderInfo.parameters.readyFunction != undefined){
                try{
                    ExternalInterface.call(_app.model.cleanEIString(loaderInfo.parameters.readyFunction), ExternalInterface.objectID);
                }
                catch(e:Error){
                    if (loaderInfo.parameters.debug != undefined && loaderInfo.parameters.debug == "true") {
                        throw new Error(e.message);
                    }
                }
            }
        }

        private function onAddedToStage(e:Event):void{
            stage.addEventListener(MouseEvent.CLICK, onStageClick);
            stage.addEventListener(Event.RESIZE, onStageResize);
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            _stageSizeTimer.start();
        }

        private function onStageSizeTimerTick(e:TimerEvent):void{
            if(stage.stageWidth > 0 && stage.stageHeight > 0){
                _stageSizeTimer.stop();
                _stageSizeTimer.removeEventListener(TimerEvent.TIMER, onStageSizeTimerTick);
                init();
            }
        }

        private function onStageResize(e:Event):void{
            if(_app != null){
                _app.model.stageRect = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
                _app.model.broadcastEvent(new VideoJSEvent(VideoJSEvent.STAGE_RESIZE, {}));
            }
        }

        private function isExternalMSObjectURL(pSrc:*):Boolean{
          return pSrc.indexOf('blob:vjs-media-source/') === 0;
        }

        private function openExternalMSObject(pSrc:*):void{
          ExternalInterface.call('videojs.MediaSource.open', pSrc, ExternalInterface.objectID);
        }

        private function onStageClick(e:MouseEvent):void{
            _app.model.broadcastEventExternally(ExternalEventName.ON_STAGE_CLICK);
        }

    }
}
