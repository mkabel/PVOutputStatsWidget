//
// Copyright 2022 by garmin@ibuyonline.nl
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and 
// associated documentation files (the "Software"), to deal in the Software without restriction, 
// including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
// and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or 
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING 
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Math;

//! Shows the PVOutput Solar panel results
(:glance) class PVOutputStatsView extends WatchUi.View {
    private var _message as String;
    private var _stats = new SolarStats();
    private var _graph = [] as Array;
    private var _error as Boolean = false;
    private var _today as String;
    private var _month as String;
    private var _year as String;
    private var _consumed as String;
    private var _current as String;

    //! Constructor
    public function initialize() {
        WatchUi.View.initialize();
    }

    //! Load your resources here
    //! @param dc Device context
    public function onLayout(dc as Dc) as Void {
        _today    = WatchUi.loadResource($.Rez.Strings.today) as String;
        _month    = WatchUi.loadResource($.Rez.Strings.month) as String;
        _year     = WatchUi.loadResource($.Rez.Strings.year) as String;
        _consumed = WatchUi.loadResource($.Rez.Strings.consumed) as String;
        _current  = WatchUi.loadResource($.Rez.Strings.current) as String;
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
            if ( _graph.size() == 0 ) {
                ShowValues(dc);
            } 
            else {
                ShowGraph(dc);
            }
        } else {
            ShowError(dc);
        }
    }

    private function ShowValues(dc as Dc) {
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
    }

    private function ShowGraph(dc as Dc) {
        // Find the max power/index in the array
        var maxPower = 0;
        var maxIndex  = 0;
        for ( var i = 0; i < _graph.size(); i++ ) {
            if ( CheckValue(_graph[i].generating ) > maxPower ) {
                maxPower = _graph[i].generating;
                maxIndex = i;
            }
        }

        // decide on type of graph - wide or high 
        var width = dc.getWidth() as Long;
        var wideX = 0.86*width as Float;
        var wideY = 0.5*width as Float;
        var stepWide = (Math.round(wideX/_graph.size())).toLong();
        var dWide = (wideX/_graph.size() - stepWide).abs();

        var highX = 0.69*width as Float;
        var highY = 0.69*width as Float;
        var stepHigh = (Math.round(highX/_graph.size())).toLong();
        var dHigh = (highX/_graph.size() - stepHigh).abs();
        
        var offsetX = 0;
        var offsetY = 0;
        var height = 0;
        var stepSize = 2;

        if ( dWide < dHigh ) {
            offsetX = ((width / 2) + (stepWide*_graph.size()/2)).toLong();
            offsetY = ((width / 2) + (wideY/2)).toLong();
            height = wideY;
            stepSize = stepWide;
        }
        else {
            offsetX = ((width / 2) + (stepHigh*_graph.size()/2)).toLong();
            offsetY = ((width / 2) + (highY/2)).toLong();
            height = highY;
            stepSize = stepHigh;
        }

        // normalize power on y-axis
        var norm = maxPower / height;

        dc.setAntiAlias(true);
        dc.setPenWidth(2);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.drawLine (0, offsetY, width, offsetY);                       // x-axis
        dc.drawLine (offsetX, offsetY + 5, offsetX, offsetY - height);  // y-axis

        // draw 500W lines
        var yIdx = maxPower / 500;
        for ( var i = 1; i <= yIdx; i ++ ) {
            dc.drawLine( offsetX - 3, (offsetY - i*500/norm).toLong(), offsetX + 3, (offsetY - i*500/norm).toLong());
        }

        var fX = offsetX;
        var fY = offsetY - (CheckValue(_graph[0].generating) / norm).toLong();
        for ( var i = 1; i < _graph.size(); i++ ) {
            var tX = offsetX - stepSize*i;
            var tY = offsetY - (CheckValue(_graph[i].generating) / norm).toLong();
            
            dc.setPenWidth(2);
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_BLACK);
            dc.drawLine(fX, fY, tX, tY);

            if ( i == maxIndex ) {
                dc.setPenWidth(1);
                dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_BLACK);
                dc.drawLine(offsetX - stepSize*i, offsetY, offsetX - stepSize*i, offsetY - height);
            }

            if ( _graph[i].time.find(":00") != null ) {
                dc.setPenWidth(1);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                dc.drawLine(offsetX - stepSize*i, offsetY + 5, offsetX - stepSize*i, offsetY - 5);
            }

            fX = tX;
            fY = tY;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 + 90, Graphics.FONT_SYSTEM_XTINY, "@ " + _graph[maxIndex].time, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER );
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 - 90, Graphics.FONT_SYSTEM_XTINY, "max: " + maxPower + " kWh", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER );
    }

    private function ShowError(dc as Dc) {
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_LARGE, _message, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function CheckValue( value as Long ) as Long {
        if ( value == null ) {
            value = NaN;
        }
        return value;
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
        _stats.generated    = CheckValue(_stats.generated);
        _stats.consumed     = CheckValue(_stats.consumed);
        _stats.generating   = CheckValue(_stats.generating);
        _stats.consuming    = CheckValue(_stats.consuming);

        if ( _stats.time == null ) {
            _stats.time = "n/a";
        }
        if ( _stats.period == null ) {
            _stats.period = "n/a";
        }
    }

    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    public function onHide() as Void {
        Storage.setValue("generated", _stats.generated);
        Storage.setValue("consumed",  _stats.consumed);
        Storage.setValue("time",      _stats.time);
    }

    //! Show the result or status of the web request
    //! @param args Data from the web request, or error message
    public function onReceive(result as SolarStats or Array or String or Null) as Void {
        if (result instanceof String) {
            _error      = true;
            _message    = result;
            _graph      = [];
        } else if (result instanceof SolarStats ) {
            _error      = false;
            _stats      = result;
            _graph      = [];
        } else if (result instanceof Array ) {
            _error      = false;
            _graph      = result;
        }
        WatchUi.requestUpdate();
    }
}
