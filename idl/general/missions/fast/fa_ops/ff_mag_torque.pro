;+
; PROCEEDURE: FF_MAG_TORQUE, mag, fit, max_sig=max_sig, max_x0=max_x0, 
;                            add_sig=add_sig, talk=talk, plot=plot
;       
; PURPOSE: Routine determines where torque on/off is.
;          NOT FOR GENERAL USE!
;          IDL 5 OR HIGHER - USES POINTERS! 
;
; INPUT: 
;      	fit -	      REQUIRED. Fits from ff_magfit.
;      	mag -	      OPTIONAL. ENTER 0 IF YOU NOT WANT MAG ALTERED!
;
;
; KEYWORDS: 
;      	max_sig -     OPTIONAL. Maximum allowed sigma in fit. DFLT=10 nT.
;      	max_x0 -      OPTIONAL. Maximum allowed x0. DFLT=40 nT.
;                     Used to determine where torquers are on.
;      	add_sig -     OPTIONAL. Add where 'good' to fit.
;       talk -        OPTIONAL. Give informational message.
;       plot -        OPTIONAL. Plot the torquer results.
;
; CALLING: 
;      ff_mag_torque, 0, fit, /add_sig - Adds torque and sigma to fit.
;
; OUTPUT: Adds structure elememt 'torque' and 'good'.
;
; INITIAL VERSION: REE/RJS/KRB 97-10-20 - see ff_magdc
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; 
;-
;       @(#)ff_mag_torque.pro	1.1     

pro ff_mag_torque, mag, fit, max_sig=max_sig, max_x0=max_x0, $
    add_sig=add_sig, talk=talk, plot=plot

IF keyword_set(talk) then BEGIN
    tstrt   = systime(1)
    print, ' -----'
    print, 'FF_MAG_TORQUE: Finding torque locations. Computing sigma_total ...'
ENDIF

; START BY CHECKING INPUTS.
if not keyword_set(max_sig) then max_sig = 10.0 ; nT
if not keyword_set(max_x0)  then max_x0  = 40.0 ; nT

; CHECK INPUTS
if (not keyword_set(fit) ) OR (fit.valid NE 1) then return 

; FIRST SET UP A CRUDE INDEX
index = where( fit.xsig LT 5.0*max_sig AND fit.ysig LT 5.0*max_sig, npts)
IF npts LT 1 THEN BEGIN
    print, "FF_MAG_TORQUE: STOPPED! No usable fits."
    fit.valid = 0
    return
ENDIF

; FIND ACCEPTABLE SIGMAS - FIRST REMOVE SIGMA DUE TO SLOPE OR CUBIC TERM
dxc = [abs(fit.xc(1:*) - fit.xc(0:*)),0] 
lfit = ladfit(dxc(index), fit.xsig(index))
xsig = fit.xsig - lfit(1)*dxc*0.75
xc3 = fit.xc*fit.xc*fit.xc
lfit3 = ladfit(xc3(index), xsig(index))
xsig = xsig - lfit3(1)*xc3

dys = [abs(fit.ys(1:*) - fit.ys(0:*)),0] 
lfit = ladfit(dys(index), fit.ysig(index))
ysig = fit.ysig - lfit(1)*dys*0.50
ys3 = fit.ys*fit.ys*fit.ys
lfit3 = ladfit(ys3(index), ysig(index))
ysig = abs(ysig - lfit3(1)*ys3)

sig_tot = sqrt(xsig*xsig+ysig*ysig+fit.zsig*fit.zsig)

index = where(sig_tot LT max_sig, npts)
print, 'FF_MAG_TORQUE: Rejected', fit.npts-npts, ' fits out of:', fit.npts, '.'

IF npts LT 1 THEN BEGIN
    print, "FF_MAG_TORQUE: STOPPED! No usable fits."
    fit.valid = 0
    return
ENDIF

; LOCATE OF GOOD SIGMA FITS
good        = bytarr(fit.npts)
good(index) = 1

; ADD GOOD IF REQUIRED
if keyword_set(add_sig) then add_str_element, fit, 'good', good
if keyword_set(add_sig) then add_str_element, fit, 'sig', sig_tot

; LOCATE TORQUER OFF TIMES - ITERATE TWICE
;lfit       = ladfit( fit.z0(index), fit.x0(index) )
;temp       = fit.x0 - lfit(1)*fit.z0 - lfit(0) 
x_med       = median(fit.x0(index))
temp        = fit.x0 - x_med ; Test
itrq_off   = where(temp LE max_x0 AND temp GE -max_x0 AND good, n_trq_off)

IF n_trq_off lt 1 THEN BEGIN
    print, "FF_MAG_TORQUE: STOPPED! Can't figure out torquer!."
    return
ENDIF

lfit       = ladfit( fit.z0(itrq_off), fit.x0(itrq_off) )
temp       = fit.x0 - lfit(1)*fit.z0 - lfit(0) 
itrq_off    = where(temp LE max_x0 AND temp GE -max_x0 AND good, n_trq_off)

IF n_trq_off lt 1 THEN BEGIN
    print, "FF_MAG_TORQUE: STOPPED! Can't figure out torquer!."
    return
ENDIF

; CREATE A TORQUE ARRAY FOR GOOD POINTS ONLY
gtorque   = intarr(n_elements(index)) + 1
x0        = temp(index)
gtime     = fit.time(index)
itrq_pos  = where( x0 GT max_x0, n_pos_trq)
itrq_neg  = where( x0 LT -max_x0, n_neq_trq)
if (n_pos_trq GT 0) then gtorque(itrq_pos) = 2
if (n_neq_trq GT 0) then gtorque(itrq_neg) = 0

; INTERPOLATE TORQUE TO ALL POINTS IN FIT
torque    = ff_interp(fit.time, gtime, gtorque, /nearest) - 1

; ADD 'TORQUE' TO FIT
add_str_element, fit, 'torque', torque

; ADD TORQUE TO THE MAG ARRAY
IF keyword_set(mag) then BEGIN
    torque = ff_interp(mag.time, fit.time, fit.torque, /nearest)
    add_str_element, mag, 'torque', torque
ENDIF

IF (n_pos_trq GT 0) or (n_neq_trq GT 0) THEN BEGIN
    print, 'FF_MAG_TORQUE: Torquer on during part of this orbit.'
ENDIF ELSE print, 'FF_MAG_TORQUE: Torquer off this orbit.'

if keyword_set(talk) then $
    print, 'FF_MAG_TORQUE: Done. Run time =', systime(1)-TSTRT, ' seconds.'

IF keyword_set(plot) then BEGIN
    wi, plot-1
    !p.psym = 3
    plot, fit.time-fit.time(0), fit.x0, yran=[-200,200], $
           xtitle='TIME', ytitle = 'FITS', title='FF_MAG_TORQUE RESULTS'
    oplot, fit.time-fit.time(0), fit.x0, col=5
    oplot, fit.time(index)-fit.time(0), fit.x0(index)
    oplot, fit.time-fit.time(0), fit.z0/50, col=4
    oplot, fit.time-fit.time(0), fit.x0*0.0 + x_med, col=2
    oplot, fit.time-fit.time(0), temp, col=3
    oplot, fit.time-fit.time(0), fit.torque*100, col=1
    !p.psym = 0
    xyouts, 4000, -110,'WHITE    - FIT.X0', charsize=1.5     
    xyouts, 4000, -125,'YELLOW  - BAD FITS', charsize=1.5     
    xyouts, 4000, -140,'DK BLUE - MEDIAN(FIT.X0)', charsize=1.5     
    xyouts, 4000, -155,'GREEN   - FIT.Z0/50', charsize=1.5     
    xyouts, 4000, -170,'LT BLUE  - FIT.X0-LADFIT', charsize=1.5     
    xyouts, 4000, -185,'MAGENTA - FIT.TORQUE*100', charsize=1.5     
    wshow, /icon
    wset,0
    plot=plot+1
ENDIF

return
end

