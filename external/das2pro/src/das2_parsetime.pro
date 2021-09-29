; The MIT License
;
; Copyright 2012-2019 Larry Granroth
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
; copies of the Software, and to permit persons to whom the Software is 
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in 
; all copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.


function das2_parsetime, timestr, year, month, day, doy, hour, minute, $
  second, julian=julian, debug=debug
;+
; Given a string, parse typical delimited ASCII date/time and
; return year, month, day of month, day of year, hour, minute, second.
;
; This function loads JULDAY and CALDAT as dependencies and prints error or
; debug messages to stderr.
;
; :Params:
;   timestr: in, required, type=string
;	    Either 4-digit or 2-digit years can be parsed.  4-digit years must be in 
;      the range range 1900 through 2199, and 2-digit years are only allowed in
;      the range 1960 through 2059.
;
;   year: out, required, type=integer
;      Year like 2000
;
;	 month: out, required, type=integer
;      Month of year (1 through 12)
;
;   day: out, required, type=integer
;      Day of month (1 through 31)
;
;   doy: out, required, type=integer
;      Day of year (1 through 366)
;
;   hour: out, required, type=integer
;      Hour of day (0 through 23)
;
;   minute: out, required, type=integer
;      Minute of hour (0 through 59)
;
;   second: out, required, type=double
;      Second of minute (0.0d0 to 61.0d0)
;
; :Keywords:
;    julian: out, optional, type=double
;       Double precision fractional Julian Day
;
;    debug: in, optional, type=bool
;       Turn on certian debug output strings
;
; :Returns:
;    integer: 0 on success, 1 on failure
;
; :Examples:
;     status = das2_parsetime (timestr, year, month, day_month, day_year $
;              [, hour, minute, second] [, julian=julian] [, /debug])
;
; :History:
;	2012-10-30, L. Granroth: Rewrite using regex
;	2019-05-23, L. Granroth: Extended to handle nanoseconds
;-

compile_opt IDL2

on_error, 2

; return values

success = 0
failure = 1

; check for required arguments

if ~(n_elements(timestr) && arg_present(year) && arg_present(month) $
  && arg_present(day) && arg_present(doy)) then begin
  printf, -2, $
  'PARSETIME USAGE: status = parsetime (timestr, year, month, day_month,', $
  '  day_year [, hour, minute, second] [, julian=julian] [,/debug])'
  return, failure
endif

ipos = stregex (timestr, '^[[:space:]]*$')
if ipos eq 0 then begin
  printf, -2, 'PARSETIME ERROR: blank time string'
  return, failure
endif

sdate = strlowcase(timestr) ; don't accidentally mess with the input
stime = sdate

; date related regex

yyyy='(19|20|21)[0-9][0-9]'
mm='(0?[1-9]|1[0-2])'
dd='(0?[1-9]|[12][0-9]|3[01])'
mon='(jan(uary)?|feb(ruary)?|mar(ch)?|apr(il)?|may|june?|july?|'+$
     'aug(ust)?|sep(t(ember)?)?|oct(ober)?|nov(ember)?|dec(ember)?)'
ddd='([0-2][0-9][0-9]|3[0-5][0-9]|36[0-6])'
yy='[0-9][0-9]'

; ordinals, date delimiter, begin and end of date string

ord='(st|nd|rd|th)?'
d='([[:blank:],./_-][[:blank:]]*)'
a='^[[:blank:],./_-]*'
z='([t[:blank:],./_-][[:space:]]*|$)'

; encode these general patterns for date:

pattern_date = [        $
  ['yyyy','mm','dd'],   $
  ['yyyy','ddd',''],    $
  ['yyyy','month','dd'],$
  ['month','dd','yyyy'],$
  ['dd','month','yyyy'],$
  ['mm','dd','yyyy'],   $
  ['ddd','yyyy',''],    $
  ['yyyy','',''],       $
  ['yyddd','',''],      $
  ['mm','dd','yy']]

regex_date = [          $
  a+yyyy+d+mm+d+dd+z,   $
  a+yyyy+d+ddd+z,       $
  a+yyyy+d+'?'+mon+d+'?'+dd+ord+z, $
  a+mon+d+'?'+dd+ord+d+yyyy+z, $
  a+dd+ord+d+'?'+mon+d+'?'+yyyy+z, $
  a+mm+d+dd+d+yyyy+z,   $
  a+ddd+d+yyyy+z,       $
  a+yyyy+z,             $
  a+yy+ddd+z,           $
  a+mm+d+dd+d+yy+z ]

; time related regex

hrmn='(0[0-9]|1[0-9]|2[0-3])[0-5][0-9]'
hr='(0?[0-9]|1[0-9]|2[0-3])'
mn='[0-5][0-9]'
ss='([0-5][0-9]|6[01])'
sss='\.[0-9]{1,9}'

; time delimiter, begin and end of time string

t='[[:blank:],.:_-][[:blank:]]*'      ; time component delimiters
a='^([t[:blank:],./_-][[:blank:]]*)?' ; beginning of time string
z='[z _,;.[:space:]]*$'               ; end of time string

; encode these general patterns for time:

pattern_time = [         $
  ['hhmm','','',''],     $
  ['hh','mm','ss','sss'],$
  ['hh','mm','ss',''],   $
  ['hh','mm','',''],     $
  ['hh','','','']]

regex_time = [           $
  a+hrmn+z,              $
  a+hr+t+mn+t+ss+sss+z,  $
  a+hr+t+mn+t+ss+z,      $
  a+hr+t+mn+z,           $
  a+hr+z ]

; okay, now see if we can find the patterns

want_date = 1
want_time = 1
allow_hhmm = 1

year = -1
month = -1
day = -1
doy = -1

n = n_elements(regex_date) - 1

if keyword_set(debug) then printf, -2, 'PARSETIME DEBUG: input string "'+sdate+'"'

; extract any date patterns

for i = 0, n do begin

  ipos = stregex (sdate, regex_date[i], length=length)

  if ipos ge 0 then begin ; found a match
    sdate = strmid (sdate, ipos, length)
    if keyword_set(debug) then printf, -2, 'PARSETIME DEBUG: date string "'+sdate+'"'
    lentime = strlen (stime) - ipos - length
    stime = strmid (stime, ipos+length, lentime)
    for j = 0, 2 do begin ; process up to 3 date components
      if pattern_date[j,i] eq '' then break
      ip = stregex (sdate, '([0-9]+|'+mon+')', length=len)
      if ip lt 0 then begin
        printf, -2, 'PARSETIME ERROR: input string "', timestr, $
          '" date string "', sdate, '"'
        return, failure
      endif
      s = strmid(sdate,ip,len)
      if keyword_set(debug) then printf, -2, 'PARSETIME DEBUG: date component "', s, $
        '" as ', pattern_date[j,i]
      if pattern_date[j,i] eq 'yyddd' then $
        reads, s, year, doy, format='(i2,i3)' $
      else if pattern_date[j,i] eq 'yyyy' then $
        reads, s, year, format='(i4)' $
      else if pattern_date[j,i] eq 'mm' then $
        reads, s, month, format='(i2)' $
      else if pattern_date[j,i] eq 'ddd' then $
        reads, s, doy, format='(i3)' $
      else if pattern_date[j,i] eq 'dd' then $
        reads, s, day, format='(i2)' $
      else if pattern_date[j,i] eq 'yy' then $
        reads, s, year, format='(i2)' $
      else if pattern_date[j,i] eq 'month' then begin
        s = strmid(s,0,3)
        s = strlowcase(s)
        if s eq 'jan' then month = 1 else $
        if s eq 'feb' then month = 2 else $
        if s eq 'mar' then month = 3 else $
        if s eq 'apr' then month = 4 else $
        if s eq 'may' then month = 5 else $
        if s eq 'jun' then month = 6 else $
        if s eq 'jul' then month = 7 else $
        if s eq 'aug' then month = 8 else $
        if s eq 'sep' then month = 9 else $
        if s eq 'oct' then month = 10 else $
        if s eq 'nov' then month = 11 else $
        if s eq 'dec' then month = 12 else $
        message, 'PARSETIME FATAL ERROR: month: '+s
      endif else begin
        printf, -2, 'PARSETIME ERROR: input string "', timestr, $
          '" date component "', s, '"'
        return, failure
      endelse
      ip = ip + len
      length = length-ip
      sdate = strmid (sdate, ip, length)
    endfor ; each of up to 3 date components
    want_date = 0
    break
  endif
    
endfor

if year lt 0 then begin ; default to current date
  julian = systime(/julian)
  caldat, julian, month, day, year
  want_date = 0
  allow_hhmm = 0
endif

if year lt 1900 then begin ; adjust two-digit year
  if year lt 60 then year = year + 2000 else year = year + 1900
endif

julian0 = julday(1,1,year,0,0,0.0) ; julian date at beginning of year

if (month lt 0) and (doy gt 0) then begin ; day of year to month and day
  julian = julian0 + doy - 1
  caldat, julian, month, day, year
  want_date = 0
endif

if doy lt 0 then begin ; derive day of year
  julian = julday(month, day, year, 0, 0, 0.0)
  doy = fix (julian - julian0 + 1.5)
endif

if (month lt 0) or (day lt 0) then begin
  printf, -2, 'PARSETIME ERROR: time string "', timestr, '"'
  return, failure
endif

; read and check optional day of year in parenthises

ipos = stregex (stime, d+'*\('+ddd+'\)'+d+'*', length=length)
if ipos ge 0 then begin ; found day of year in parens
  ip = stregex (stime, ddd, length=len)
  if ip lt 0 then begin
    printf, -2, 'PARSETIME ERROR: input string "', timestr, $
      '" day of year "', stime, '"'
    return, failure
  endif
  s = strmid (stime, ip, len)
  stime = strmid (stime, ipos+length, strlen(stime)-length)
  reads, s, thisdoy, format='(i3)'
  if doy ne thisdoy then begin
    printf, -2, 'PARSETIME ERROR: input string "', timestr, $
      '" conflicting day of year "', s, '"'
    return, failure
  endif
  if keyword_set(debug) then printf, -2, 'PARSETIME DEBUG: day of year "', s, '"'
endif

; if caller doesn't want time of day then return

if ~(arg_present(hour) && arg_present(minute) && arg_present(second)) then begin
  if arg_present(julian) && ~n_elements(julian) then $
    julian = julday (month, day, year, 0, 0, 0.0)
  return, success
endif

; now get the time of day (default to 00:00:00)

hour = 0
minute = 0
isecond = 0
dsecond = 0.0d0
want_time = 0

if keyword_set(debug) then printf, -2, 'PARSETIME DEBUG: input time string "', stime, '"'

; extract any time patterns

if strlen(stime) gt 0 then begin

  want_time = 1
  n = n_elements(regex_time) - 1

  for i = 0, n do begin

    ipos = stregex (stime, regex_time[i], length=length)

    if ipos ge 0 then begin ; found a match
      stime = strmid (stime, ipos, length)
      if keyword_set(debug) then printf, -2, 'PARSETIME DEBUG: time string "', stime, '"'
      for j = 0, 3 do begin ; process up to 4 time components
        if pattern_time[j,i] eq '' then break
        ip = stregex (stime, '[0-9]+', length=len)
        if ip lt 0 then begin
          printf, -2, 'PARSETIME ERROR: input string "', timestr, $
            '" time string "', stime, '"'
          return, failure
        endif
        s = strmid(stime,ip,len)
        if keyword_set(debug) then printf, -2, 'PARSETIME DEBUG: time component "', $
          s, '" as ', pattern_time[j,i]
        if (pattern_time[j,i] eq 'hhmm') and allow_hhmm then $
          reads, s, hour, minute, format='(2i2)' $
        else if pattern_time[j,i] eq 'hh' then $
          reads, s, hour, format='(i2)' $
        else if pattern_time[j,i] eq 'mm' then $
          reads, s, minute, format='(i2)' $
        else if pattern_time[j,i] eq 'ss' then $
          reads, s, isecond, format='(i2)' $
        else if pattern_time[j,i] eq 'sss' then $
          reads, '0.'+s, dsecond, format='(d11)' $
        else message, 'PARSETIME FATAL ERROR: time component: '+s
        ip = ip + len
        length = length-ip
        stime = strmid (stime, ip, length)
      endfor
      want_time = 0
      break
    endif

  endfor

endif ; nonzero time string

if keyword_set(debug) then printf, -2, 'PARSETIME DEBUG: remnants "', stime, '"'

if want_date or want_time then begin
  printf, -2, 'PARSETIME ERROR: input string "', timestr, '"'
  return, failure
endif

second = dsecond + double(isecond)

if arg_present(julian) then $
  julian = julday (month, day, year, hour, minute, second)

return, success
end
