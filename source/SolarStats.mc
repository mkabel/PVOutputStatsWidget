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

import Toybox.Lang;

(:background)
class SolarStats {
    public var consumed = NaN as Float;
    public var generated = NaN as Float;
    public var generating = NaN as Long;
    public var consuming = NaN as Long;
    public var period = currentStats as Statistics;
    public var date = _na_ as String;
    public var time = _na_ as String;

    public function set( valueString as String ) {
        var result = ParseString(";", valueString);

        if ( result.size() == 7 ) {
            period     = CheckLong(result[0].toNumber());
            date       = result[1];
            time       = result[2];
            generated  = CheckFloat(result[3].toFloat());
            generating = CheckLong(result[4].toLong());
            consumed   = CheckFloat(result[5].toFloat());
            consuming  = CheckLong(result[6].toLong());
        }
    }


    public function toString() as String {
        var string = period.toString();
        string += ";" + date;
        string += ";" + time;
        string += ";" + CheckFloat(generated).toString();
        string += ";" + CheckLong(generating).toString();
        string += ";" + CheckFloat(consumed).toString();
        string += ";" + CheckLong(consuming).toString();

        return string;
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