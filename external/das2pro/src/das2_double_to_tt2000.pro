; Get rid of some IDL historical oddities
;COMPILE_OPT DEFINT32, STRICTARR

;+
; Description: Convert a double represeting a binary das2 time value to tt2000
;
; tt2000 is the number of nano-seconds since 2000-01-01T11:58:55.816
;
; :Params:
;    timeunits: in, required
;      This is one of the strings 'us2000', 'mj1958', 't2000' or 't1970'
;    value: a DOUBLE value
;
; To read UTC time strings in a variety of formats use das2_text_to_tt2000
; instead of this function.
;
; To avoid leap seconds, epoch time is first converted to a calendar
; representation and the broken down calendar time is converted to TT2000
; using the built-in CDF_TT2000 proceedure
;-

function das2_double_to_tt2000, timeunits, value
	; convert to julian day then use the efficient gnu algorithim to get
	; calendar time, then finally use IDL built in to get TT2000 thus avoiding
	; the need for a leap second table

	compile_opt IDL2

	if CDF_EXISTS() eq 0 then message, 'CDF library not supported for your IDL installation'

	; Get the julian day and seconds since midnight without leap seconds.
	; All the standard das2 time formats ignore leap seconds
	rDays = 0.0D
	nDays = 0
	case timeunits of
		'us2000': begin
			rDays = value / 8.64D+10
			nDays = floor(rDays)
			julian = nDays + 15340 + 2436205LL
		end
		'mj1958': begin
			rDays = value
			nDays = floor(rDays)
			julian = nDays + 2436205LL
		end
		't2000': begin
			rDays = value / 8.64D+04
			nDays = floor(rDays)
			julian = nDays + 15340 + 2436205LL
		end
		't1970': begin
			rDays = value/8.64D+04
			nDays = floor(rDays)
			julian = nDays + 4383 +  2436205LL
		end
		; error code here
		else: MESSAGE, 'Unknown time units '+timeunits
	endcase
	rSec = (rDays - nDays) * 8.64D+04 ; Seconds since midnight

	; from http://en.wikipedia.org/wiki/Julian_day (GNU Public License)
	j = julian + 32044
	g = j / 146097
	dg = j MOD 146097
	c = (dg / 36524 + 1) * 3 / 4;
	dc = dg - c * 36524
	b = dc / 1461
	db = dc MOD 1461
	a = (db / 365 + 1) * 3 / 4
	da = db - a * 365
	y = g * 400 + c * 100 + b * 4 + a
	m = (da * 5 + 308) / 153 - 2
	d = da - (m + 4) * 153 / 5 + 122
	Y = y - 4800 + (m + 2) / 12
	M = (m + 2) MOD 12 + 1
	D = d + 1
	; thanks GNU!

	nHr    = floor( rSec/3600.0 )
	nMin   = floor( (rSec - nHr*3600.0)/60.0 )
	rSec   = rSec - nHr*3600.0 - nMin*60.0  ; redefine rSec to seconds of minute
	nSec   = floor(rSec)
	nMilli = floor( (rSec - nSec)*1.0D+03 )
	nMicro = floor( (rSec - nSec)*1.0D+06 - nMilli*1.0D+03 )
	nNano  = floor( (rSec - nSec)*1.0D+09 - nMilli*1.0D+06 - nMicro*1.0D+03 )

	; good ole debug print, remove when code works
	;print, Y, M, D, nHr, nMin, nSec, nMilli, nMicro, nNano

	cdf_tt2000, nEpoch, fix(Y), fix(M), fix(D), $
	            fix(nHr), fix(nMin), fix(nSec), $
	            fix(nMilli), fix(nMicro), fix(nNano), /COMPUTE_EPOCH

	return, nEpoch
end
