;+
; FUNCTION: das2dlm_mj1958_to_unixtime, ...
;
; Description:
;    Converts mj1958 time to unixtime
;    mj1958 –  Days since midnight 1958-01-01, more accurately Julian day – 2436204.5
;
; INPUT:
;    time - mj1958 time 
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
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/das2dlm/das2dlm_mj1958_to_unixtime.pro $
;-

function das2dlm_mj1958_to_unixtime, time

  dt = time_double('1958-01-01')
  unixtime = time*86400. + dt
    
  return, unixtime
end