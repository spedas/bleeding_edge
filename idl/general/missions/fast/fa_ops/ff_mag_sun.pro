;+
; PROCEEDURE: FF_MAG_SUN, mag, fit=fit, talk=talk, plot=plot 
;       
; PURPOSE: Routine determines where torque on/off is.
;          NOT FOR GENERAL USE! ACCEPTS PTR STRUCTURE.
;
; INPUT: 
;      	mag -	      REQUIRED. DC mag data.
;
;
; KEYWORDS: 
;      	fit -	      OPTIONAL. Fits from ff_magfit.
;       talk -        OPTIONAL. Give informational message.
;
; CALLING: 
;      ff_mag_sun, mag, fit=fit.
;
; OUTPUT: Adds structure elememt 'sun' to mag and fit.
;
; INITIAL VERSION: REE 97-10-20 - see ff_magdc
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; 
;-
;       @(#)ff_mag_sun.pro	1.1     

pro ff_mag_sun, mag, fit=fit, talk=talk, plot=plot

IF keyword_set(talk) then BEGIN
    tstrt   = systime(1)
    print, ' ----'
    print, 'FF_MAG_SUN: Finding sun/shadow times (why so slow?) ..."
ENDIF

if ptr_valid(mag.time(0)) then is_ptr=1 else is_ptr=0

; CHECK TO SEE IF 'SUN' IS ALREADY ADDED TO MAG
tags  = strlowcase(tag_names(mag))
isun  = where(tags eq 'sun', nsun)

IF nsun NE 1 THEN BEGIN
    ; GET SUN
    fa_shadow, mag.start_time, mag.end_time
    get_data,'sunlit?', data=data
    sun = ff_interp(mag.time,data.x,byte(data.y), /nearest)
    add_str_element, mag, 'sun', sun
ENDIF

IF keyword_set(fit) THEN BEGIN
    IF (fit.valid) THEN BEGIN
        sun = ff_interp(fit.time,mag.time,mag.sun, /nearest)
        add_str_element, fit, 'sun', sun
    ENDIF
ENDIF
       
if keyword_set(talk) then $
    print, 'FF_MAG_SUN: Sun is done! Run time =', systime(1)-tstrt, ' seconds.'

IF keyword_set(plot) AND keyword_set(fit) then BEGIN
    wi, plot-1
    !p.psym = 3
    plot, fit.time-fit.time(0), fit.x0, yran=[-200,200], $
           xtitle='TIME', ytitle = 'FITS', title='FF_MAG_SUN RESULTS'
    oplot, fit.time-fit.time(0), fit.y0, col=5
    oplot, fit.time-fit.time(0), fit.z0/50, col=2
    oplot, fit.time-fit.time(0), fit.sun*50+100, col=4
    oplot, fit.time-fit.time(0), fit.speed*10-200, col=3
    oplot, fit.time-fit.time(0), fit.torque*50, col=1
    !p.psym = 0
    xyouts, 4000, -110,'WHITE    - FIT.X0', charsize=1.5     
    xyouts, 4000, -125,'YELLOW  - FIT.Y0', charsize=1.5     
    xyouts, 4000, -140,'DK BLUE - FIT.Z0/50', charsize=1.5     
    xyouts, 4000, -155,'GREEN   - FIT.SUN*50+100', charsize=1.5     
    xyouts, 4000, -170,'LT BLUE  - FIT.SPEED*10-200', charsize=1.5     
    xyouts, 4000, -185,'MAGENTA - FIT.TORQUE*500', charsize=1.5     
    wshow, /icon
    wset,0
    plot=plot+1
ENDIF

return
END
