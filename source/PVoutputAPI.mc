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

import Toybox.System;
import Toybox.Lang;
import Toybox.Communications;
import Toybox.Application.Properties;
import Toybox.Time.Gregorian;

//! Creates a web request on select events, and browse through day, month and year statistics
(:background)
class PVOutputAPI extends SolarAPI {
    private var _baseUrl = "https://pvoutput.org/service/r2/";
    private var _sysid = $._sysid_ as Long;
    private var _apikey = $._apikey_ as String;
    private var _errormessage = "ERROR" as String;
    private var _unauthorized = "UNAUTHORIZED" as String;
   
    //! Set up the callback to the view
    //! @param handler Callback method for when data is received
    public function initialize(handler as Method(args as SolarStats or Array or String or Null) as Void) {
        SolarAPI.initialize(handler);

        _errormessage = Application.loadResource($.Rez.Strings.error) as String;
        _unauthorized = Application.loadResource($.Rez.Strings.unauthorized) as String;

        ReadSettings();
    }

    private function ReadSettings() {
        _sysid  = Properties.getValue($.sysid);
        _apikey = Properties.getValue($.api);
    }

    //! Query the current status of the PV System
    public function getStatus() as Void {
        var url = _baseUrl + "getstatus.jsp";

        var params = {           // set the parameters
            //"ext" => 1
        };

        Communications.makeWebRequest( url, params, WebRequestOptions(), method(:onReceiveResponse) );
    }

    //! Query the current status of the PV System
    public function getHistory() as Void {
        var url = _baseUrl + "getstatus.jsp";

        var params = {          // set the parameters
            "h" => 1,
            "limit" => 72       // last 6 hours
        };

        Communications.makeWebRequest( url, params, WebRequestOptions(), method(:onReceiveArrayResponse) );
    }

    //! Query the statistics of the PV System for the specified periods
    public function getDayGraph( df as Gregorian.Info, dt as Gregorian.Info ) as Void {
        var url = _baseUrl + "getoutput.jsp";

        var params = {           // set the parameters
            "df" => DateString(df),
            "dt" => DateString(dt),
        };

        Communications.makeWebRequest( url, params, WebRequestOptions(), method(:onReceiveArrayResponse) );
    }

    //! Query the statistics of the PV System for the specified periods
    public function getMonthGraph( df as Gregorian.Info, dt as Gregorian.Info ) as Void {
        var url = _baseUrl + "getoutput.jsp";

        var params = {           // set the parameters
            "df" => DateString(df),
            "dt" => DateString(dt),
            "a" => "m"
        };

        Communications.makeWebRequest( url, params, WebRequestOptions(), method(:onReceiveArrayResponse) );
    }

    //! Query the statistics of the PV System for the specified periods
    public function getYearGraph() as Void {
        var url = _baseUrl + "getoutput.jsp";

        var params = {           // set the parameters
            "a" => "y"
        };

        Communications.makeWebRequest( url, params, WebRequestOptions(), method(:onReceiveArrayResponse) );
    }

    private function WebRequestOptions() as Dictionary {
        return {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "X-Pvoutput-Apikey" => _apikey,
                "X-Pvoutput-SystemId" => _sysid.toString()
            }
        };  
    }

    //! Receive the data from the web request
    //! @param responseCode The server response code
    //! @param data Content from a successful request
    public function onReceiveResponse(responseCode as Number, data as Dictionary<String, Object?> or String or Null) as Void {
        if (responseCode == 200) {
            var record = ParseString(",", data.toString());
            var stats = ProcessResult(ResponseType(record), record);
            _notify.invoke(stats);
        } else {
            ProcessError(responseCode, data);
        }
    }

    //! Receive the data from the web request
    //! @param responseCode The server response code
    //! @param data Content from a successful request
    public function onReceiveArrayResponse(responseCode as Number, data as Dictionary<String, Object?> or String or Null) as Void {
        if (responseCode == 200 ) {
            var records = ParseString(";", data.toString());
            var stats = [] as Array<SolarStats>;
            for ( var i = 0; i < records.size(); i++ ) {
                var record = ParseString(",", records[i]);
                if ( System.getSystemStats().freeMemory < 3500 ) {
                    break;
                }
                stats.add(ProcessResult(ResponseType(record), record));
            }
            _notify.invoke(stats);
        } else {
            ProcessError(responseCode, data);
        }
    }

    public function ProcessError( responseCode as Number, data as String ) {
        if ( IsPvOutputError(responseCode) ) {
            switch (responseCode) {
            case 401:
                _notify.invoke(_unauthorized);
                break;
            default:
                _notify.invoke("PVOutput - " + data);
            }
        } else {
            var message = CommunicationsError.Message(responseCode);
            if ( message != null ) {
                _notify.invoke(message);
            } else {
                _notify.invoke(_errormessage + responseCode.toString());
            }
        }
    }

    private function IsPvOutputError(errorCode as Number ) as Boolean {
        var isError = false;
        if ( errorCode >= 400 and errorCode < 500 ) {
            isError = true;
        }
        return isError;
    }

    private function ResponseType( record as Array<String> ) as Statistics {
        var type = unknown;
        switch ( record.size() ) {
        case 9:
            type = currentStats;
            break;
        case 11:
            type = dayStats;
            break;
        case 14:
            type = weekStats;
            break;
        case 10:
            switch ( record[0].length() ) {
            case 6:
                type = monthStats;
                break;
            case 4:
                type = yearStats;
                break;
            default:
                break;
            }
            break;
        default:
            break;
        }
        return type;
    }

    private function ProcessResult( period as Statistics, values as Array ) as SolarStats {
        var _stats = new SolarStats();

        _stats.period       = period;
        _stats.date         = ParseDate(values[0]);

        switch ( period ) {
            case currentStats:
                _stats.time         = values[1];
                _stats.generated    = values[2].toFloat();
                _stats.generating   = values[3].toLong();
                _stats.consumed     = values[4].toFloat();
                _stats.consuming    = values[5].toLong();
                break;
            case dayStats:
                _stats.time         = values[1];
                _stats.generated    = values[2].toFloat();
                _stats.generating   = values[4].toLong();
                _stats.consumed     = values[7].toFloat();
                _stats.consuming    = values[8].toLong();
                break;
            case weekStats:
                _stats.time         = values[6];
                _stats.generated    = values[1].toFloat();
                _stats.generating   = NaN;
                _stats.consumed     = values[4].toFloat();
                _stats.consuming    = NaN;
                break;
            case monthStats:
            case yearStats:
                _stats.time         = values[1];
                _stats.generated    = values[2].toFloat();
                _stats.generating   = NaN;
                _stats.consumed     = values[5].toFloat();
                _stats.consuming    = NaN;
                break;
            default:
                break;
        }

        return _stats;
    }

    private function ParseDate( input as String ) as String {
        var dateString = input;
        if ( input.length() == 6 ) {
            // convert yyyymm to (abbreviated) month string
            dateString = DateInfo(input.substring(0,4), input.substring(4,6), "1").month;
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

    protected function DateString( date as Gregorian.Info ) as String {
        return Lang.format(
            "$1$$2$$3$",
            [
                date.year,
                date.month.format("%02d"),
                date.day.format("%02d")
            ]
        );
    }

    //! convert string into a substring array
    private function ParseString(delimiter as String, data as String) as Array {
        var result = [] as Array<String>;
        var endIndex = 0;
        var subString;
        
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