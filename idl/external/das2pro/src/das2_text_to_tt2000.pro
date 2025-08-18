;+
; Description: Convert a string time value to a cdf_tt2000 epoch time
;
; tt2000 is the number of nano-seconds since 2000-01-01T11:58:55.816
;
; :Params:
;    sTime: in, required
;      This is a string time value such as '2007-001T14:00'
; 
; This function works by calling das2_parsetime to parse time components
; from a variety of string formats, and then calling cdf_tt2000 to get
; the epoch.
;
; 2019-01-24 L. Granroth, original
; 2019-05-23 C. Piker,    nano second accuracy fix
;-

function das2_text_to_tt2000, sTime
	compile_opt idl2

	status = das2_parsetime (sTime, Y, M, D, nDOY, nHr, nMin, rSec)
	; if status eq 1 return, fail

	nSec   = floor(rSec)
	nMilli = floor( (rSec - nSec)*1.0D+03 )
	nMicro = floor( (rSec - nSec)*1.0D+06 - nMilli*1.0D+03 )
	nNano  = round( (rSec - nSec)*1.0D+09 - nMilli*1.0D+06 - nMicro*1.0D+03 )
        
   cdf_tt2000, nEpoch, Y, M, D, nHr, nMin, nSec, nMilli, nMicro, nNano, /COMPUTE_EPOCH
	return, nEpoch
end
