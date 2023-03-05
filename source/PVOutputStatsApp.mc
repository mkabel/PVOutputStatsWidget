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

import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Background;

//! This app retrieves Solar Panel (PV) statistics from the httpts://PVOutput.org website
(:background)
class PVOutputStatsApp extends Application.AppBase {

    //! Constructor
    public function initialize() {
        AppBase.initialize();
        
    }

    //! Handle app startup
    //! @param state Startup arguments
    public function onStart(state as Dictionary?) as Void {
    }

    //! Handle app shutdown
    //! @param state Shutdown arguments
    public function onStop(state as Dictionary?) as Void {
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
        var view = new $.MyGlanceView();
        return [view] as Array<GlanceView>;
    }
}

// Your service delegate has to be marked as background
// so it can handle your service callbacks
(:background)
class BackgroundTimerServiceDelegate extends System.ServiceDelegate {

    //! Constructor
    public function initialize() {
        ServiceDelegate.initialize();
    }

    private function WebRequestOptions() as Dictionary {
        return {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "X-Pvoutput-Apikey" => "72865",
                "X-Pvoutput-SystemId" => "64b1ee240c7f3428f005a7417a85b584fac68816"
            }
        };  
    }

    function onTemporalEvent() {

        // Communications.makeWebRequest(
        //     "https://pvoutput.org/service/r2/getStatus.jsp",
        //     {},
        //     WebRequestOptions(),
        //     method(:responseCallback)
        // );
    }    

    //! If our timer expires, it means the application timer ran out,
    //! and the main application is not open. Prompt the user to let them
    //! know the timer expired.
    public function responseCallback() as Void {
        System.println(Time.now());
    }
}
