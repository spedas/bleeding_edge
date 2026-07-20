;+
; FUNCTION:
;         spd_tai2unix
;
; PURPOSE:
;         Converts TAI times (epoch 1958, leap seconds included) to unix times. 
;
; INPUT:
;         time: time values in TT2000
;
; EXAMPLE:
;         IDL> unix_time = spd_tai2unix(0.0d)
;         IDL> unix_time
;               -378691200.00000000
;         IDL> time_string(unix_time)
;         1958-01-01/00:00:00
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2026-07-17 17:06:10 -0700 (Fri, 17 Jul 2026) $
;$LastChangedRevision: 34650 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/time/TT2000/spd_tai2unix.pro $
;-
function spd_tai2unix, tinput


  ; need to check that the input times are doubles (floats might lead to unexpected precision problems)
  inp_type = size(/type, tinput[0])
  if (inp_type ne 5) and (inp_type ne 3) and (inp_type ne 13) and (inp_type ne 14) then begin
    dprint, dlevel=1, 'Warning: the input values to spd_tai2unix should be double-precision, long, long64, or ulong'
    tinput=double(tinput)
  endif

  ; TAI epoch 1958-01-01 relative to TT2000 epoch,in nanoseconds
  tai_epoch_const_ns =   -1325419167816000000LL ; cdf_parse_tt2000('1958-01-01T00:00:00')

  scalar_input = n_elements(tinput) eq 1
  toutput = dblarr(n_elements(tinput))

  for i=0,n_elements(tinput)-1 do begin 
    ; convert sec to ns
    tai_ns = long64(tinput[i]*1000000000ll)
    ; change epoch from TAI to TT2000
    tt2000_ns = tai_ns + tai_epoch_const_ns
    ; convert tt2000 value to broken out time
    cdf_tt2000,tt2000_ns,year,month,day, hour, mm, ss, milli, micro, nano, /BREAKDOWN
    fracnano=long64(nano)+1000*micro+1000000*milli
    ; convert broken down time to an RFC1819 string
    utc_str =  string(year,month,day,hour,mm,ss,fracnano,format='%4d-%02d-%02dT%02d:%02d:%02d.%09d')
    ; convert string to Unix time
    toutput[i] = time_double(utc_str)
  endfor
  
  if scalar_input then begin
    return, toutput[0]
  endif else begin
    return, toutput
  endelse
end
