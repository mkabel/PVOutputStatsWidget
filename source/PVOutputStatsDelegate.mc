//
// Copyright 2016-2021 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.`Application.Properties;

enum PropKeys {
    sysid = "sysid_prop",
    api = "apikey_prop"
}

//! Creates a web request on menu / select events
(:glance) class PVOutputStatsDelegate extends WatchUi.BehaviorDelegate {
    private var _sysid = $._sysid_ as Long;
    private var _apikey = $._apikey_ as String;
    private var _notify as Method(args as Dictionary or String or Null) as Void;

    //! Set up the callback to the view
    //! @param handler Callback method for when data is received
    public function initialize(handler as Method(args as Dictionary or String or Null) as Void) {
        WatchUi.BehaviorDelegate.initialize();
        ReadSettings();
        _notify = handler;
        getStatus();
    }

    private function ReadSettings() {
        var sysid = Properties.getValue($.sysid);
        if ( sysid != null ) {
            _sysid = sysid;
        }
        var apikey = Properties.getValue($.api);
        if ( apikey != null ) {
            _apikey = apikey;
        }
    }

    //! On a menu event, make a web request
    //! @return true if handled, false otherwise
    public function onMenu() as Boolean {
        return true;
    }

    //! On a select event, make a web request
    //! @return true if handled, false otherwise
    public function onSelect() as Boolean {
        getStatus();
        return true;
    }

    //! Make the web request
    private function getStatus() as Void {
        if ( !System.getDeviceSettings().phoneConnected ) {
            _notify.invoke("Connect phone");
            return;
        }

        var url = "https://pvoutput.org/service/r2/getstatus.jsp";

        var params = {           // set the parameters
            "ext" => 1
        };

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "X-Pvoutput-Apikey" => _apikey,
                "X-Pvoutput-SystemId" => _sysid.toString()
            }
        };

        Communications.makeWebRequest(
            url,
            params,
            options,
            method(:onReceiveStatus)
        );
    }

    //! Make the web request
    private function getStatistic() as Void {
        if ( !System.getDeviceSettings().phoneConnected ) {
            _notify.invoke("Connect phone");
            return;
        }

        var url = "https://pvoutput.org/service/r2/getstatistic.jsp";

        var params = {           // set the parameters
            "df" => "01062022",
            "c" => 1
        };

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "X-Pvoutput-Apikey" => _apikey,
                "X-Pvoutput-SystemId" => _sysid.toString()
            }
        };

        Communications.makeWebRequest(
            url,
            params,
            options,
            method(:onReceiveStatus)
        );
    }

    //! Receive the data from the web request
    //! @param responseCode The server response code
    //! @param data Content from a successful request
    public function onReceiveStatus(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == 200) {
            _notify.invoke(ParseString(data));

        } else {
            _notify.invoke("Failed to load\nError: " + responseCode.toString());
        }
    }

    private function ParseString(data as String) as Dictionary {
        var result = {} as Dictionary;
        var idx = 1 as Long;
        var endIndex = data.find(",") as Long;
        while (endIndex != null) {
            var value = data.substring(0, endIndex) as String;
            result.put(idx, value);
            //strip string, and find next 'token', increase idx
            data = data.substring(endIndex+1, data.length());
            endIndex = data.find(",");
            idx += 1;
        }

        return result;
    }
}