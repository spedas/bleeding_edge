;+
; FUNCTION:
;         tt2000_2_unix
;
; PURPOSE:
;         Converts TT2000 times to unix times. This function converts the input time
;           to a 64-bit integer prior to calling time_double (the input is required to 
;           be a 64-bit integer if the /tt2000 keyword is specified)
;
; INPUT:
;         time: time values in TT2000
;         
; EXAMPLE:
;         IDL> unix_time = tt2000_2_unix(4.98e17)
;         IDL> unix_time
;               1444727946.6781905
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-01-03 08:27:35 -0800 (Tue, 03 Jan 2017) $
;$LastChangedRevision: 22472 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/time/TT2000/tt2000_2_unix.pro $
;-

function tt2000_2_unix, time

  defsysv,'!CDF_LEAP_SECONDS',exists=exists

  if ~keyword_set(exists) then begin
    cdf_leap_second_init
  endif
  
  return, time_double(long64(time), /tt2000)
end