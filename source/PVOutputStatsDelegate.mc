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

//! Creates a web request on select events, and browse through day, month and year statistics
(:glance) class PVOutputStatsDelegate extends WatchUi.BehaviorDelegate {
    private var _sysid = $._sysid_ as Long;
    private var _apikey = $._apikey_ as String;
    private var _notify as Method(args as Dictionary or String or Null) as Void;
    private var _idx = 0 as Long;
    private var _baseUrl = "https://pvoutput.org/service/r2/";
    private var _connectphone as String;
    private var _errormessage as String;

    //! Set up the callback to the view
    //! @param handler Callback method for when data is received
    public function initialize(handler as Method(args as Dictionary or String or Null) as Void) {
        WatchUi.BehaviorDelegate.initialize();
        _notify = handler;
        _connectphone = WatchUi.loadResource($.Rez.Strings.connect) as String;
        _errormessage = WatchUi.loadResource($.Rez.Strings.error) as String;

        ReadSettings();
        getStatus();
    }

    private function ReadSettings() {
        _sysid  = Properties.getValue($.sysid);
        _apikey = Properties.getValue($.api);
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
        if ( _idx > 3 ) {
            _idx = 0;
        }
        
        var today = DaysAgo(0);
        switch ( _idx ) {
        case 0:
            getStatus();
            break;
        case 1:
            getHistory();
            break;
        case 2:
            getOutput(DateString(BeginOfMonth(today)), DateString(today), "m");
            break;
        case 3:
            getOutput(DateString(BeginOfYear(today)), DateString(today), "y");
            break;
        default:
            break;
        }

        return true;
    }

    //! Query the current status of the PV System
    private function getStatus() as Void {
        var url = _baseUrl + "getstatus.jsp";

        var params = {           // set the parameters
            "ext" => 1
        };

        webRequest(url, params, method(:onReceiveResponse));
    }

    //! Query the current status of the PV System
    private function getHistory() as Void {
        var url = _baseUrl + "getstatus.jsp";

        var params = {          // set the parameters
            "h" => 1,
            "limit" => 96       // last 8 hours
        };

        webRequest(url, params, method(:onReceiveArrayResponse));
    }

    //! Query the statistics of the PV System for the specified periods
    private function getStatistic( df as String, dt as String ) as Void {
        var url = _baseUrl + "getstatistic.jsp";

        var params = {           // set the parameters
            "df" => df,
            "dt" => dt,
            "c" => 1
        };

        webRequest(url, params, method(:onReceiveResponse));
    }

    //! Query the statistics of the PV System for the specified periods
    private function getOutput( df as String, dt as String, period as String ) as Void {
        var url = _baseUrl + "getoutput.jsp";

        var params = {           // set the parameters
            "df" => df,
            "dt" => dt,
            "a" => period
        };

        webRequest(url, params, method(:onReceiveResponse));
    }

    //! Make the web request
    private function webRequest(url as String, params as Dictionary, responseCall as Lang.method) as Void {
        if ( !System.getDeviceSettings().phoneConnected ) {
            _notify.invoke(_connectphone);
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

    //! Receive the data from the web request
    //! @param responseCode The server response code
    //! @param data Content from a successful request
    public function onReceiveResponse(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == 200) {
            var stats = ProcessResult(Period(), ParseString(",", data));
            _notify.invoke(stats);

        } else {
            _notify.invoke(_errormessage + responseCode.toString());
        }
    }

    //! Receive the data from the web request
    //! @param responseCode The server response code
    //! @param data Content from a successful request
    public function onReceiveArrayResponse(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == 200) {
            var records = ParseString(";", data);
            var stats = [] as Array;
            for ( var i = 0; i < records.size(); i++ ) {
                stats.add(ProcessResult(Period(), ParseString(",", records[i])));
            }
            _notify.invoke(stats);
        } else {
            _notify.invoke(_errormessage + responseCode.toString());
        }
    }

    private function ProcessResult( period as String, values as Array ) as SolarStats {
        var _stats = new SolarStats();

        _stats.period       = period;
        _stats.date         = ParseDate(values[0]);

        if ( period.equals("day") ) {
            _stats.time         = values[1];
            _stats.generated    = values[2].toFloat();
            _stats.generating   = values[3].toLong();
            _stats.consumed     = values[4].toFloat();
            _stats.consuming    = values[5].toLong();
        } else if (period.equals("history") ) {
            _stats.time         = values[1];
            _stats.generated    = values[2].toFloat();
            _stats.generating   = values[4].toLong();
            _stats.consumed     = values[7].toFloat();
            _stats.consuming    = values[8].toLong();
        }
        else {
            _stats.time         = "n/a";
            _stats.generated    = values[2].toFloat();
            _stats.generating   = NaN;
            _stats.consumed     = values[5].toFloat();
            _stats.consuming    = NaN;
        }

        return _stats;
    }

    private function Period() as String {
        var period as String = "unknown";
        if ( _idx == 0 ) {
            period = "day";
        } else if ( _idx == 1 ) {
            period = "history";
        } else if ( _idx == 2 ) {
            period = "month";
        } else if ( _idx == 3 ) {
            period = "year";
        }

        return period;
    }

    private function ParseDate( input as String ) as String {
        var dateString = input;
        if ( input.length() == 6 ) {
            // convert yyyymm to (abbreviated) month string
            dateString = DateInfo(input.substring(0,4), input.substring(4,6), 1).month;
        }
        return dateString;
    }

    private function DateInfo( year as String, month as String, day as String ) as Gregorian.Info {
        var options = {
            :year => year.toNumber(),
            :month => month.toNumber(),
            :day => day.toNumber(),
            :hour => 0,
            :minute => 0
        };
        return Gregorian.info(Gregorian.moment(options), Time.FORMAT_LONG);
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

    //! convert string into a substring dictionary
    private function ParseString(delimiter as String, data as String) as Dictionary {
        var result = [] as Array;
        var endIndex = 0;
        var subString as String;
        
        while (endIndex != null) {
            endIndex = data.find(delimiter);
            if ( endIndex != null ) {
                subString = data.substring(0, endIndex) as String;
                data = data.substring(endIndex+1, data.length());
            } else {
                subString = data;
            }
            result.add(subString);
        }

        return result;
    }
}