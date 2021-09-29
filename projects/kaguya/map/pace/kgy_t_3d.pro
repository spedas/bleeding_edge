;+
;FUNCTION:	kgy_t_3d
;INPUT:	
;	dat:	structure,	2d data structure filled by get_eesa_surv, get_eesa_burst, etc.
;PURPOSE:
;	Returns the temperature, [Tx,Ty,Tz,Tavg], eV 
;NOTES:	
;	Function normally called by "get_3dt" or "get_2dt" to
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	Yuki Harada on 2018-05-09
;       modified from t_3d and t_3d_new
;-
function kgy_t_3d,dat2,_extra=_extra

Tavg = 0.
Tx = 0.
Ty = 0.
Tz = 0.

if dat2.valid eq 0 then begin
	dprint, 'Invalid Data'
	return, [Tx,Ty,Tz,Tavg]
endif

press = kgy_p_3d(dat2,_extra=_extra)
density = kgy_n_3d(dat2,_extra=_extra)
if density ne 0. then begin
	Tavg = (press(0)+press(1)+press(2))/(density*3.)
	Tx = press(0)/(density)
	Ty = press(1)/(density)
	Tz = press(2)/(density)
endif

return, [Tx,Ty,Tz,Tavg]

end

