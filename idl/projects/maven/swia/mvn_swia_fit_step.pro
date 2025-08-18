;+
;PROCEDURE: 
;	MVN_SWIA_FIT_STEP
;PURPOSE: 
;	Routine to fit discontinuity, in order to find attenuator and mode switches
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_FIT_STEP, Series, Ratio, Ind
;INPUTS:
;	Series: A series of 17 values
;	Ratio: The expected ratio before/after discontinuity
;OUTPUTS
;	Ind: Index where the change occurred
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2015-05-11 11:11:08 -0700 (Mon, 11 May 2015) $
; $LastChangedRevision: 17549 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_fit_step.pro $
;
;-

pro mvn_swia_fit_step, series, ratio, ind

; take one from packet after to pad w/ known value
; result is index where first post-change value should be located

mult = fltarr(18)
cc = fltarr(18)

for i = 1,17 do begin
	mult(0:i-1) = 1.0
	mult(i:17) = ratio

	cc(i) = correlate(mult,series)

endfor

mincc = max(cc,mini)

ind = mini

end