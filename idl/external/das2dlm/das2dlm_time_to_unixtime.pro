;+
; FUNCTION: das2dlm_time_to_unixtime, ...
;
; Description:
;    Converts time from das2dlm to unixtime
;
; INPUT:
;    time - vector of time data
;    units - string of das2dlm time, e.g. 'us2000'
;     
; 
; RETURN:
;   unixtime - unixtime (SPEDAS time)
;
; CREATED BY:
;    Alexander Drozdov (adrozdov@ucla.edu)
;    
; TODO:
;    us1980 – Microseconds since midnight January 1st 1980, ignoring leap seconds
;    t1970 – Seconds since midnight January 1st 1970, ignoring leap seconds. (unixtime?)
;    mjd – Days since midnight November 17, 1858.
;    tt2000 – nanoseconds since 01-Jan-2000 including leap seconds, may be transmitted as an 8-byte
;    cdfEpoch – milliseconds since 01-Jan-0000  
;
; $LastChangedBy: adrozdov $
; $Date: 2020-08-03 20:45:11 -0700 (Mon, 03 Aug 2020) $
; $Revision: 28983 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/das2dlm/das2dlm_time_to_unixtime.pro $
;-

function das2dlm_time_to_unixtime, time, units

  case strlowcase(units) of
    'us2000': time = das2dlm_us2000_to_unixtime(time) ; convert time
    't2000': time = das2dlm_t2000_to_unixtime(time) ; convert time
    'mj1958': time = das2dlm_mj1958_to_unixtime(time) ; convert time
    else: dprint, dlevel = 0, 'Unknown time units: ' + string(units)
  endcase
    
  return, time
end