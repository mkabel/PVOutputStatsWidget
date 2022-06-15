//
// Copyright 2015-2021 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Application.Storage;

//! Shows the web request result
(:glance) class PVOutputStatsView extends WatchUi.View {
    private var _message as String = "Press menu or\nselect button";
    private var _stats = new SolarStats();
    private var _error as Boolean = false;
    private var _today as String;
    private var _month as String;
    private var _year as String;
    private var _consumed as String;
    private var _current as String;


    //! Constructor
    public function initialize() {
        WatchUi.View.initialize();
        _today    = WatchUi.loadResource($.Rez.Strings.today) as String;
        _month    = WatchUi.loadResource($.Rez.Strings.month) as String;
        _year     = WatchUi.loadResource($.Rez.Strings.year) as String;
        _consumed = WatchUi.loadResource($.Rez.Strings.consumed) as String;
        _current  = WatchUi.loadResource($.Rez.Strings.current) as String;
    }

    //! Load your resources here
    //! @param dc Device context
    public function onLayout(dc as Dc) as Void {
    }

    //! Restore the state of the app and prepare the view to be shown
    public function onShow() as Void {
        _stats.generated = Storage.getValue("generated") as Float;
        _stats.consumed  = Storage.getValue("consumed") as Float;
        _stats.time      = Storage.getValue("time") as String;
    }

    //! Update the view
    //! @param dc Device Context
    public function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        if ( !_error ) {
            CheckValues();
            dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 - 75, Graphics.FONT_LARGE, Header(_stats), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            
            if ( _stats.period.equals("day") ) {
                dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 - 30, Graphics.FONT_LARGE, (_stats.generated/1000).format("%.1f") + " kWh", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 + 10, Graphics.FONT_SYSTEM_TINY, _consumed + ": " + (_stats.consumed/1000).format("%.1f")+ " kWh", Graphics.TEXT_JUSTIFY_CENTER );
                dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 - 14, Graphics.FONT_SYSTEM_XTINY, _current + ": " + _stats.generating + " W", Graphics.TEXT_JUSTIFY_CENTER );
                dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 + 36, Graphics.FONT_SYSTEM_XTINY, _current + ": " + _stats.consuming + " W", Graphics.TEXT_JUSTIFY_CENTER );
                dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 + 80, Graphics.FONT_SYSTEM_XTINY, "@ " + _stats.time, Graphics.TEXT_JUSTIFY_CENTER );
            }
            else {
                dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 - 30, Graphics.FONT_LARGE, (_stats.generated/1000).format("%.0f") + " kWh", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_SYSTEM_TINY, _consumed + ":", Graphics.TEXT_JUSTIFY_CENTER );
                dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 + 26, Graphics.FONT_SYSTEM_TINY, (_stats.consumed/1000).format("%.0f")+ " kWh", Graphics.TEXT_JUSTIFY_CENTER );
                dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 + 80, Graphics.FONT_SYSTEM_XTINY, "@ " + _stats.date, Graphics.TEXT_JUSTIFY_CENTER );
            }
        } else {
            dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_LARGE, _message, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    private function Header( stats as SolarStats ) as String {
        var header = "n/a";
        if ( stats.period.equals("day") ) {
            header = _today;
        } else if ( stats.period.equals("month") ) {
            header = _month;
        } else if ( stats.period.equals("year") ) {
            header = _year;
        }
        return header;
    }

    private function CheckValues() {
        if ( _stats.generated == null ) {
            _stats.generated = NaN;
        }
        if ( _stats.consumed == null ) {
            _stats.consumed = NaN;
        }
        if ( _stats.generating == null ) {
            _stats.generating = NaN;
        }
        if ( _stats.consuming == null ) {
            _stats.consuming = NaN;
        }
        if ( _stats.time == null ) {
            _stats.time = "n/a";
        }
    }

    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    public function onHide() as Void {
        Storage.setValue("generated", _stats.generated);
        Storage.setValue("consumed", _stats.consumed);
        Storage.setValue("time", _stats.time);
    }

    //! Show the result or status of the web request
    //! @param args Data from the web request, or error message
    public function onReceive(result as SolarStats or Dictionary or String or Null) as Void {
        if (result instanceof String) {
            _error      = true;
            _message    = result;
        } else if (result instanceof SolarStats ) {
            _error      = false;
            _stats      = result;
        }
        WatchUi.requestUpdate();
    }
}
