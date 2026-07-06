;+
; FUNCTION:
;         spd_unix2tai
;
; PURPOSE:
;         Converts Unix times (epoch 1970, no leap seconds) to TAI times (epoch 1958, leap seconds included)
; INPUT:
;         tinput: Unix time values 
;
; EXAMPLE:
;         IDL> tai_time = spd_unix2tai(0.0d)
;         IDL> tai_time
;                378691208.00137800
;
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2026-07-02 19:09:32 -0700 (Thu, 02 Jul 2026) $
;$LastChangedRevision: 34617 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/time/TT2000/spd_unix2tai.pro $
;-
function spd_unix2tai, tinput

  ; need to check that the input times are doubles (floats might lead to unexpected precision problems)
  inp_type = size(/type, tinput[0])
  if (inp_type ne 5) and (inp_type ne 13) and (inp_type ne 14) then begin
    dprint, dlevel=1, 'Warning: the input values to spd_unix2tai should be double-precision, long64, or ulong'
    tinput=double(tinput)
  endif

  ; TAI epoch 1958-01-01 relative to TT2000 epoch,in nanoseconds
  tai_epoch_const_ns =   -1325419167816000000LL ; cdf_parse_tt2000('1958-01-01T00:00:00')

  scalar_input = n_elements(tinput) eq 1
  toutput = dblarr(n_elements(tinput))

  for i=0,n_elements(tinput)-1 do begin 
    ; convert unix time to equivalent UTC string in ISO 8601 format
    utc_string = time_string(tinput[i], tformat='YYYY-MM-DDThh:mm:ss.fffffffff')
    ; Convert UTC string to offset in nanoseconds, including leap seconds, relative to TT2000 epoch
    tt2000_ns = cdf_parse_tt2000(utc_string)
    ; Apply offset from TT2000 to TAI epoch
    toutput_ns = tt2000_ns - tai_epoch_const_ns
    ; Convert from nanoseconds to seconds
    toutput[i] = toutput_ns/1d9
  endfor
  
  if scalar_input then begin
    return, toutput[0]
  endif else begin
    return, toutput
  endelse
end
