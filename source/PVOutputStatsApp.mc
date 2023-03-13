//
// Copyright 2022-2023 by garmin@ibuyonline.nl
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

import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Background;

//! This app retrieves Solar Panel (PV) statistics from the httpts://PVOutput.org website
(:background)
class PVOutputStatsApp extends Application.AppBase {
    public var status = null as SolarStats;
    private var _gv = null as PVOutputStatsGlanceView;

    //! Constructor
    public function initialize() {
        AppBase.initialize();

        status = new SolarStats();

        if(Background.getTemporalEventRegisteredTime() == null) {
            Background.registerForTemporalEvent(new Time.Duration(15 * 60));
        }
    }

    //! Handle app startup
    //! @param state Startup arguments
    public function onStart(state as Dictionary?) as Void {
        var stored = Storage.getValue("status");
        if ( stored != null ) {
            status.set(stored);
        }
    }

    //! Handle app shutdown
    //! @param state Shutdown arguments
    public function onStop(state as Dictionary?) as Void {
        Storage.setValue("status", status.toString());
    }

    //! Return the initial view for the app
    //! @return Array Pair [View, Delegate]
    public function getInitialView() as Array<Views or InputDelegates>? {
        var view = new $.PVOutputStatsView();
        var delegate = new $.PVOutputStatsDelegate(view.method(:onReceive));
        return [view, delegate] as Array<Views or InputDelegates>;
    }

    public function getServiceDelegate() as Lang.Array<System.ServiceDelegate> {
        return [ new BackgroundTimerServiceDelegate() ];
    }    

    (:glance)
    public function getGlanceView() as Array<GlanceView>? {
        _gv = new $.PVOutputStatsGlanceView();
        return [_gv] as Array<GlanceView>;
    }

    public function onBackgroundData(data as Application.PersistableType) as Void {
        status.set(data);
        // if ( _gv != null ) {
        //     _gv.refresh();
        // }
    }
}