package com.streamroot {

import flash.display.Sprite;
import flash.events.Event;
import flash.external.ExternalInterface;
import flash.system.Security;
import flash.ui.ContextMenu;

[SWF(backgroundColor="#000000", frameRate="60", width="480", height="270")]
public class Main extends Sprite {

    private var _model:NetStreamWrapper;
    private var _view:Skin;

    public function Main() {
        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
    }

    private function onAddedToStage(e:Event):void {
        init();
    }

    private function init():void {
        Security.allowDomain("*");
        Security.allowInsecureDomain("*");

        _model = new NetStreamWrapper();

        _view = new Skin(_model);
        addChild(_view);

        var _ctxMenu:ContextMenu = new ContextMenu();
        _ctxMenu.hideBuiltInItems();
        this.contextMenu = _ctxMenu;

        if (loaderInfo.parameters.readyFunction != undefined) {
            ExternalInterface.call(loaderInfo.parameters.readyFunction, ExternalInterface.objectID);
        }
    }

}
}
