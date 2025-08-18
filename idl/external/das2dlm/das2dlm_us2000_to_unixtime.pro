;+
; FUNCTION: das2dlm_us2000_to_unixtime, ...
;
; Description:
;    Converts us2000 time to unixtime
;    us2000 – Microseconds since midnight January 1st 2000, ignoring leap seconds
;
; INPUT:
;    time - us2000 time 
; 
; RETURN:
;   unixtime - unixtime (SPEDAS time)
;
; CREATED BY:
;    Alexander Drozdov (adrozdov@ucla.edu)
;
; $LastChangedBy: adrozdov $
; $Date: 2020-08-03 20:45:11 -0700 (Mon, 03 Aug 2020) $
; $Revision: 28983 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/das2dlm/das2dlm_us2000_to_unixtime.pro $
;-

function das2dlm_us2000_to_unixtime, time

  dt = time_double('2000-01-01')-time_double('1970-01-01')
  unixtime = time/1d6 + dt
    
  return, unixtime
end