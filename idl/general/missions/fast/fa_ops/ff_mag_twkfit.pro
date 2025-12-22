;+
; FUNCTION: FF_MAG_TWKFIT, fit, twc 
;       
; PURPOSE: Routine calculates a constant tweak matrix for the orbit.
;          NOT FOR GENERAL USE!
;
; INPUT: 
;      	fit -	      REQUIRED. Fits from ff_magfit.
;      	twc -	      REQUIRED. Static tweak matrix.
;
;
; KEYWORDS: 
;
; CALLING: 
;       fit = ff_mag_twkfit(fit,twc)
;
; OUTPUT: fit.
;
; INITIAL VERSION: REE/RJS/KRB 97-10-20 - see ff_magdc
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; 
;-
;       @(#)ff_mag_twkfit.pro	1.1     

function ff_mag_twkfit, in_fit, twc

fit = in_fit

; CHECK VALIDITY
if (fit.valid NE 1) then return, fit
if data_type(twc) NE 8 then return, fit

; FIX BASES
fit.x0 = fit.x0 - twc.x0 + twc.xz * fit.z0
fit.y0 = fit.y0 - twc.y0 + twc.yz * fit.z0

; ROTATE Y
fit.yc = fit.yc + twc.yx * fit.xc
fit.ys = fit.ys + twc.yx * fit.xs

; NORMALIZE X and Y
fit.xc = fit.xc * twc.xx
fit.xs = fit.xs * twc.xx
fit.yc = fit.yc * twc.yy
fit.ys = fit.ys * twc.yy

; FIX Z
fit.zc = fit.zc + twc.zx * fit.xc
fit.zs = fit.zs + twc.zy * fit.ys

; ALL DONE!

return, fit

END
