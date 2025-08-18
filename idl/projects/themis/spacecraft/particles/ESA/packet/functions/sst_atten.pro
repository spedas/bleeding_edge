;+
;FUNCTION:	sst_atten(dat)
;INPUT:	
;	dat:	structure,	data structure filled by thm_sst_ps**
;KEYWORDS
;					0,1=exclude,include
;PURPOSE:
;	Returns the attenuator value of the structure
;NOTES:	
;	
;
;CREATED BY:
;	J.McFadden	09-01-06
;LAST MODIFICATION:
;-
function sst_atten,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins

; keywords included to make compatible with get_2dt.pro

return, dat2.atten

end

