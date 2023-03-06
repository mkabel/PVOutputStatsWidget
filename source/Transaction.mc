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

import Toybox.Communications;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Lang;

class Transaction
{
    private   var _baseUrl  = "https://pvoutput.org/service/r2/";
    protected var _endpoint = "getstatus.jsp";
    protected var _params   = null;
    private   var _apikey   = "n/a";
    private   var _sysid    = "99999";

    // Constructor
    hidden function initialize( apikey as String, sysid as Number ) {
        _apikey = apikey;
        _sysid  = sysid;
    }

    function go()
    {
        System.println("Transaction::go() => " + _baseUrl + _endpoint);

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "X-Pvoutput-Apikey"   => _apikey,
                "X-Pvoutput-SystemId" => _sysid.toString()
            }
        };

        Communications.makeWebRequest(
            _baseUrl + _endpoint,
            _params,
            options,
            method(:onReceive)
        );
    }

   // set up the response callback function
   function onReceive( responseCode as Number, data as Dictionary or String or Null ) as Void {
     if (responseCode == 200) {
            handleResponse(data);
        }
        else if (responseCode == 401) {
            handleAuthError(data);
        }
        else {
            System.println("Request failed: " + responseCode);

            var message = "";
            if (data instanceof Dictionary && data["message"] != null) {
                System.println("has message");
                message = data["message"];
            }
            handleError(responseCode, message);
        }
    }

    // Function to put response handling
    function handleResponse(data)
    {
        System.println("Transaction::handleResponse");
    }

    // Function to put error handling
    function handleAuthError(error)
    {
        System.println("Transaction::handleAuthError");
        System.println("error = " + error);
    }

    // Handle an error from the server
    function handleError(code, message)
    {
        System.println("Transaction::handleError");
        System.println("code = " + code);
        System.println("message = " + message);
    }

    //! convert string into a substring dictionary
    protected function ParseString(delimiter as String, data as String) as Array {
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