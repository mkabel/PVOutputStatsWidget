//
// Copyright 2016-2021 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Application.Properties;
import Toybox.Time.Gregorian;

enum PropKeys {
    sysid = "sysid_prop",
    api = "apikey_prop"
}

//! Creates a web request on menu / select events
(:glance) class PVOutputStatsDelegate extends WatchUi.BehaviorDelegate {
    private var _sysid = $._sysid_ as Long;
    private var _apikey = $._apikey_ as String;
    private var _notify as Method(args as Dictionary or String or Null) as Void;
    private var _idx = 0 as Long;

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
        _idx++;
        if ( _idx > 2 ) {
            _idx = 0;
        }
        
        var today = DaysAgo(0);
        switch ( _idx ) {
        case 0:
            getStatus();
            break;
        case 1:
            var bom = BeginOfMonth(today);
            getStatistic(DateString(bom), DateString(today));
            break;
        case 2:
            var boy = BeginOfYear(today);
            getStatistic(DateString(boy), DateString(today));
            break;
        default:
            break;
        }

        return true;
    }

    //! Query the current status of the PV System
    private function getStatus() as Void {
        var url = "https://pvoutput.org/service/r2/getstatus.jsp";

        var params = {           // set the parameters
            "ext" => 1
        };

        webRequest(url, params, method(:onReceiveStatus));
    }

    //! Receive the data from the web request
    //! @param responseCode The server response code
    //! @param data Content from a successful request
    public function onReceiveStatus(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == 200) {
            var stats = ProcessResult("day", ParseString(data));
            _notify.invoke(stats);

        } else {
            _notify.invoke("Failed to load\nError: " + responseCode.toString());
        }
    }

    //! Query the statistics of the PV System for the specified periods
    private function getStatistic( df as String, dt as String ) as Void {
        var url = "https://pvoutput.org/service/r2/getstatistic.jsp";

        var params = {           // set the parameters
            "df" => df,
            "dt" => dt,
            "c" => 1
        };

        webRequest(url, params, method(:onReceiveStatistic));
    }

    public function onReceiveStatistic(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == 200) {
            var result = ParseString(data);
            var stats = new SolarStats();
            if ( _idx == 1 ) {
                stats = ProcessResult("month", result);
            } else if ( _idx == 2 ) {
                stats = ProcessResult("year", result);
            }
            _notify.invoke(stats);


        } else {
            _notify.invoke("Failed to load\nError: " + responseCode.toString());
        }
    }

    //! Make the web request
    private function webRequest(url as String, params as Dictionary, responseCall as Lang.method) as Void {
        if ( !System.getDeviceSettings().phoneConnected ) {
            _notify.invoke("Connect phone");
            return;
        }

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
            responseCall
        );
    }

    //! convert string into a substring dictionary
    private function ParseString(data as String) as Dictionary {
        var result = {} as Dictionary;
        var idx = 1 as Long;
        var endIndex = data.length() - 1;
        var subString as String;
        
        while (endIndex != null) {
            endIndex = data.find(",");
            if ( endIndex != null ) {
                subString = data.substring(0, endIndex) as String;
                data = data.substring(endIndex+1, data.length());
            } else {
                subString = data;
            }
            result.put(idx, subString);
            idx += 1;
        }

        return result;
    }

    private function ProcessResult( period as String, values as Dictionary ) as SolarStats {
        var _stats = new SolarStats();

        if ( period.equals("day") ) {
            _stats.period       = period;
            _stats.date         = values.get(1);
            _stats.time         = values.get(2);
            _stats.generated    = values.get(3).toFloat();
            _stats.generating   = values.get(4).toLong();
            _stats.consumed     = values.get(5).toFloat();
            _stats.consuming    = values.get(6).toLong();
        } else {
            _stats.period       = period;
            _stats.date         = "n/a";
            _stats.time         = "n/a";
            _stats.generated    = values.get(1).toFloat();
            _stats.generating   = NaN;
            _stats.consumed     = values.get(12).toFloat();
            _stats.consuming    = NaN;
        }

        return _stats;
    }

    private function DaysAgo( days_ago as Long ) as Gregorian.Info {
        var today = new Time.Moment(Time.today().value());
        return Gregorian.info(today.subtract(new Time.Duration(days_ago*60*60*24)), Time.FORMAT_SHORT);
    }

    private function BeginOfMonth( date as Gregorian.Info ) as Gregorian.Info {
        var options = {
            :year => date.year,
            :month => date.month,
            :day => 1
        };
        return Gregorian.info(Gregorian.moment(options), Time.FORMAT_SHORT);
    }

    private function BeginOfYear( date as Gregorian.Info ) as Gregorian.Info {
        var options = {
            :year => date.year,
            :month => 1,
            :day => 1
        };
        return Gregorian.info(Gregorian.moment(options), Time.FORMAT_SHORT);
    }

    private function DateString( date as Gregorian.Info ) as String {
        return Lang.format(
            "$1$$2$$3$",
            [
                date.year,
                date.month.format("%02d"),
                date.day.format("%02d")
            ]
        );
    }
}