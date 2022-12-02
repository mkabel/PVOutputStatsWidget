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

using Toybox.Application as App;
using Toybox.Communications as Comm;
using Toybox.System;

class EstimateTransaction extends Transaction
{
    private var _notify = null;

    function initialize( handler as Method(data as Lang.Array), apikey as Lang.String, sysid as Lang.Number )
    {
        Transaction.initialize(apikey, sysid);

        _notify   = handler;
        
        _endpoint = "getsystem.jsp";
        _params   = {           // set the parameters
            "est" => 1
        };
    }

    // Function to put response handling
    function handleResponse(data)
    {
        var estimates = [] as Lang.Array;
        var records = ParseString(";", data.toString());
        if ( records.size() > 3 ) {
            var estStrings = ParseString(",", records[3]);
            if ( estStrings.size() == 24 ) {
                for ( var i=0; i<12; i++ ) {
                    var month = new Month();
                    month.monthid = i+1;
                    month.generation = estStrings[i];
                    month.consumption = estStrings[i+12];
                    estimates.add(month);
                }
            }
        }

        _notify.invoke(estimates);
    }
}