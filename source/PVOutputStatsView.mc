//
// Copyright 2015-2021 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;

using Toybox.Application.Storage;

//! Shows the web request result
(:glance) class PVOutputStatsView extends WatchUi.View {
    private var _message as String = "Press menu or\nselect button";
    private var _generated as Float = NaN;
    private var _generating as Long = NaN;
    private var _consumed as Float = NaN;
    private var _power as Long = NaN;
    private var _time as String ="n/a";
    private var _error as Boolean = false;

    //! Constructor
    public function initialize() {
        WatchUi.View.initialize();
    }

    //! Load your resources here
    //! @param dc Device context
    public function onLayout(dc as Dc) as Void {
    }

    //! Restore the state of the app and prepare the view to be shown
    public function onShow() as Void {
        //_generated = Storage.getValue("generated") as Float;
        //_consumed = Storage.getValue("consumed") as Float;
        //_time = Storage.getValue("time") as String;

        if ( _generated == null ) {
            _generated = NaN;
        }
        if ( _consumed == null ) {
            _consumed = NaN;
        }
        if ( _time == null ) {
            _time = "n/a";
        }
    }

    //! Update the view
    //! @param dc Device Context
    public function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        if ( !_error ) {
            dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 - 75, Graphics.FONT_LARGE, "Today", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            if ( _generated != NaN ) {
                dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 - 30, Graphics.FONT_LARGE, _generated.format("%.1f") + " kWh", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 - 14, Graphics.FONT_SYSTEM_XTINY, "Current: " + _generating + " W", Graphics.TEXT_JUSTIFY_CENTER );
            }
            
            if ( _consumed != NaN ) {
                dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 + 10, Graphics.FONT_SYSTEM_TINY, "Consumed: " + _consumed.format("%.1f")+ " kWh", Graphics.TEXT_JUSTIFY_CENTER );
                dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 + 36, Graphics.FONT_SYSTEM_XTINY, "Current: " + _power + " W", Graphics.TEXT_JUSTIFY_CENTER );
            }
            
            dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 + 80, Graphics.FONT_SYSTEM_XTINY, "@ " + _time, Graphics.TEXT_JUSTIFY_CENTER );
        } else {
            dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_LARGE, _message, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    public function onHide() as Void {
        Storage.setValue("generated", _generated);
        Storage.setValue("consumed", _consumed);
        Storage.setValue("time", _time);
    }

    //! Show the result or status of the web request
    //! @param args Data from the web request, or error message
    public function onReceive(args as Dictionary or String or Null) as Void {
        if (args instanceof String) {
            _message = args;
            _error = true;
        } else if (args instanceof Dictionary) {
            _error      = false;
            _time       = args.get(2);
            _generated  = args.get(3).toFloat()/1000 as Float;
            _generating = args.get(4).toLong() as Long;
            _consumed   = args.get(5).toFloat()/1000 as Float;
            _power      = args.get(6).toLong() as Long;
        }
        WatchUi.requestUpdate();
    }
}
