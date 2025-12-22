;+
; FUNCTION: FF_MAG_TWC, fit, talk=talk 
;       
; PURPOSE: Routine calculates a static tweak matrix.
;          IDL VER 5 AND GREATER!
;          NOT FOR GENERAL USE!
;
; INPUT: 
;      	fit -	      REQUIRED. Fits from ff_magfit.
;
;
; KEYWORDS: 
;       talk -        OPTIONAL. Give informational message.
;
; CALLING: 
;       twc = ff_mag_twc(fit)
;
; OUTPUT: twc.
;
; INITIAL VERSION: REE/RJS/KRB 97-10-20 - see ff_magdc
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; 
;-
;       @(#)ff_mag_twc.pro	1.1     

function ff_mag_twc, fit, talk=talk

IF keyword_set(talk) then BEGIN
    tstrt   = systime(1)
    print, ' -----'
    print, 'FF_MAG_TWC: Calculating static calibration matrix ...'
ENDIF

; START BY CHECKING INPUTS.
if fit.valid NE 1 then return,0

; STEP 1: LOCATE VALID FITS
good  = fit.good
index = where(good, npts)
if npts LT 1 then retrun, 0

; STEP 2: LOCATE TORQUER OFF TIMES - ITERATE TWICE
trq_off = where( (fit.torque EQ 0) AND good, npts)
if npts LT 1 then retrun, 0

; STEP 3, CALCULATE X0, Y0, XZ, and YZ
lfit       = ladfit( fit.z0(trq_off), fit.x0(trq_off) )
tw_xz      = -lfit(1)
tw_x0      = lfit(0)

lfit       = ladfit( fit.z0(trq_off), fit.y0(trq_off) )
tw_yz      = -lfit(1)
tw_y0      = lfit(0)

; STEP 4, XX, YY, and XY
x_dot_y    = fit.xc(index)*fit.yc(index) + fit.xs(index)*fit.ys(index)
x_mag      = sqrt( fit.xc(index)*fit.xc(index) + fit.xs(index)*fit.xs(index) )
y_mag      = sqrt( fit.yc(index)*fit.yc(index) + fit.ys(index)*fit.ys(index) )
tw_yx      = -double( median( x_dot_y / (x_mag * x_mag) ) )
lfit       = ladfit( sqrt(x_mag*y_mag) , (x_mag-y_mag) )
tw_xx      = 1.d - lfit(1)/2.d
tw_yy      = 1.d + lfit(1)/2.d

; STEP 5, CALCULATE ZX and ZY
lfit       = ladfit( fit.xc(index) , fit.zc(index))
tw_zx      = -lfit(1)
lfit       = ladfit( fit.ys(index) , fit.zs(index))
tw_zy      = -lfit(1)

; ALL DONE! CONSTRUCT STRUCTURE AND RETURN

twc        = {x0: tw_x0, xx: tw_xx, xy :   0.d, xz: tw_xz, $
              y0: tw_y0, yx: tw_yx, yy : tw_yy, yz: tw_yz, $
              z0:   0.d, zx: tw_zx, zy : tw_zy, zz:   1.d }

if keyword_set(talk) then $
    print, 'FF_MAG_TWC: Done. Run time =', systime(1)-TSTRT, ' seconds.'

return, twc

END
