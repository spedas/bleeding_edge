;       @(#)fa_fields_magdc.pro	1.3     
;+
; FUNCTION: FA_FIELDS_MAGDC, t1=t1, t2=t2, fit=fit, twd=twd, tws=tws,
;                              fit2=fit2, twd2=twd2, tws2=tws2,  
;                              iterate=iterate
;       
; PURPOSE: Gets mag data and calibrates accurately.
;
; INPUT: 
;       mag -         OPTIONAL. 'MagDC' data structure.
;
; KEYWORDS: 
;       t1 -          Optional start time.
;       t2 -          Optional end time.
;       iterate -     OPTIONAL. Will iterate fits twice.
;       talk -        OPTIONAL. Give informational message.
;       plot -        OPTIONAL. Plot results.
;
; USED IN FF_MAG_SPEED: 
;      	min_streak -  OPTIONAL. DEFAULT=40. Miniumun stretch of good data.
;
; USED IN FF_MAG_TORQUE:
;       max_sig -     OPTIONAL. Max error in fit. DFLT=10 nT
;      	max_x0 -      OPTIONAL. Maximum allowed x0. DFLT=40 nT.
;                     Used to determine where torquers are on.
;
; USED IN FF_MAG_REJECT:
;       max_err -     OPTIONAL. Maximun allowable error. DFLT = 100 nT
;       ave_per -     OPTIONAL. S/C period.              DFLT = 5.0 s
;       nper_trq -    OPTIONAL. Throw out points within nper_trq
;                     spin periods of a torque boundary. DFLT = 1.5
;       npts_speed_af OPTIONAL. Throw out npts_speed_after
;                     a speed change boundary. DFLT = 40
;       npts_speed_be OPTIONAL. Throw out npts_speed_before
;                     a speed change boundary. DFLT = 5
;       npts_per_spin-OPTIONAL. Too tricky to describe.  DFLT = 16
;       max_sig2 -    OPTIONAL. Max error in fit.        DFLT = 10 nT
;       n_sm -        OPTIONAL. N_points to smooth fits. DFLT = 21
;	
; USED IN FF_MAG_TWD:
;       max_sig3 -    OPTIONAL. Max error in tweak dynamic. DFLT = 10 nT
;       n_sm_twd -    OPTIONAL. N_points to smooth fits. DFLT = 41
;
;
; CALLING: 
;       mag=fa_fields_magdc()
;
; OUTPUT: 
;      	mag -         A pointer struc containing results.
;      	fit -         Fits of raw data.
;      	twd -         Dynamic tweak matrix.
;      	tws -         Static tweak matrix.
;      	fit2 -        Fits of raw data, 2nd iteration.
;      	twd2 -        Dynamic tweak matrix, 2nd iteration.
;      	tws2 -        Static tweak matrix, 2nd iteration.
;
; INITIAL VERSION: REE/RJS/KRB 97-10-02 - see UCLA_MAG_DESPIN, FF_XYMAGFIX
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; 
;-
function fa_fields_magdc, t1=t1, t2=t2, iterate=iterate, $ 
    fit1=fit, twd1=twd, tws1=tws, fit2=fit2, twd2=twd2, tws2=tws2, $
    plot=plot, talk=talk, $
; BELOW ARE LESS USED KEYWORDS 
    min_streak=min_streak, max_sig=max_sig, max_x0=max_x0, $
    max_err=max_err, ave_per=ave_per, nper_trq=nper_trq, $
    npts_speed_after=npts_speed_after, npts_speed_before=npts_speed_before, $
    npts_per_spin=npts_per_spin, max_sig2=max_sig2, n_sm=n_sm, $
    max_sig3=max_sig3, n_sm_twd=n_sm_twd

two_pi = 2.d*!dpi
IF keyword_set(talk) then BEGIN
    tstrt   = systime(1)
    print, ' -----'
    print, 'FA_FIELDS_MAGDC: Getting mag data from sdt...'
ENDIF

; SETUP CONSTANTS.
if not keyword_set(min_streak) then min_streak  = 40.0 ; DETERMINES BUFFERS
if not keyword_set(max_sig) then max_sig = 10.0 ; nT USED ON REDUCED SIG_TOT
if not keyword_set(max_x0)  then max_x0  = 40.0 ; nT USED TO FIND TORQUE ON
if not keyword_set(max_err) then max_err = 100.0; nT MAG_REJECT
if not keyword_set(ave_per) then ave_per = 5.d  ; s  NEED IN EARLY ORBIT
if not keyword_set(npts_per_spin) then npts_per_spin = 16; MAG_REJECT
if not keyword_set(nper_trq) then nper_trq = 1.5; MAG_REJECT
if not keyword_set(npts_speed_after) then npts_speed_after = 40l; MAG_REJECT
if not keyword_set(npts_speed_before) then npts_speed_before = 5l; MAG_REJECT
if not keyword_set(n_sm) then n_sm = 21l ; MAG_REJECT
if not keyword_set(max_sig2) then max_sig2 = 10.d ; nT USE ON (XYZ) SIG RAW 
if not keyword_set(n_sm_twd) then n_sm_twd = 41l ; DYNAMIC TWEAK
if not keyword_set(max_sig3) then max_sig3 = 10 ; DYNAMIC TWEAK
if keyword_set(plot) then plot = 1 ; Avoids plotting error.

; CHECK INPUTS.
IF not keyword_set(mag) then BEGIN
    print, 'FA_FIELDS_MAGDC: Getting mag data from sdt...'
    mag = get_fa_fields('MagDC',t1,t2,/repair)
    IF mag.valid ne 1 then BEGIN
        print, "FA_FIELDS_MAGDC: STOPPED!"
        print, "Cannot get MagDC. Check SDT setup."
        return, mag
    ENDIF 
ENDIF

IF keyword_set(talk) then BEGIN
    print, 'FA_FIELDS_MAGDC: Have MagDC data.'
    print, ' -----'
    print, 'FA_FIELDS_MAGDC: Converting data to (pointer) double precision...'
ENDIF

; MAKE DOUBLE AND FIND SUN. PERIA NEEDS TO SPEED THIS UP!
; IMPORTANT! FROM NOW ON PROGRAM IS ONLY IDL >=5 COMPATABLE!!
; MAG CONTAINS POINTERS!
ff_dat_to_ptr, mag, /double, /streak
IF keyword_set(talk) then BEGIN
    print, 'FA_FIELDS_MAGDC: Done converting.'
ENDIF

; FIT THE DATA
fit = ff_magfit(mag, talk=talk, plot=plot)

IF (fit.valid EQ 0) then BEGIN
    print, 'FA_FIELDS_MAGDC: NO VALID FITS!'
    return, mag
ENDIF
    
; ADD SPEED, TORQUER, AND SUN LOCATIONS
ff_mag_speed,  mag, fit=fit, min_streak=min_streak, $
    talk=talk, plot=plot 
ff_mag_torque, mag, fit, /add_sig, max_x0=max_x0, max_sig=max_sig, $
    talk=talk, plot=plot 
ff_mag_sun, mag, fit=fit, talk=talk, plot=plot

; CALCULATE THE STATIC TWEAK MATRIX
tws = ff_mag_twc(fit, talk=talk)

; REJECT BAD MAG POINTS
ff_mag_reject, mag, fit, max_err=max_err, ave_per=ave_per, $
    nper_trq=nper_trq, npts_speed_after=npts_speed_after, $
    npts_per_spin=npts_per_spin, n_sm=n_sm, max_sig=max_sig2, $
    npts_speed_before=npts_speed_before, talk=talk, plot=plot 

; SMOOTH THE FIT AND MAKE DYNAMIC CALIBRATION ARRAY
twd = ff_mag_twd(mag, fit, n_sm=n_sm_twd, max_sig=max_sig3, $
    talk=talk, plot=plot )
ff_mag_twkdat, mag, twd, talk=talk, plot=plot

; ALL DONE
; NOW DO AGAIN IF KEYWORD ITERATE IS SET!
IF keyword_set(iterate) then BEGIN

    IF keyword_set(talk) then BEGIN
        print, ' -----'
        print, 'FA_FIELDS_MAGDC: 1st iteration Done.
        print, 'FA_FIELDS_MAGDC: Run time =', systime(1)-tstrt, ' seconds.'
        print, ' -----'
        print, 'FA_FIELDS_MAGDC: Starting 2nd iteration ...'
    ENDIF

    ; FIT THE DATA
    fit2 = ff_magfit(mag, talk=talk, plot=plot)

    IF (fit2.valid EQ 0) then BEGIN
        print, 'FA_FIELDS_MAGDC: NO VALID FITS!'
        return, mag
    ENDIF
  
    ; ADD SPEED, TORQUER, AND SUN LOCATIONS
    ff_mag_speed,  mag, fit=fit2, min_streak=min_streak, $
        talk=talk, plot=0 
    ff_mag_torque, 0, fit2, /add_sig, max_x0=max_x0, max_sig=max_sig, $
        talk=talk, plot=0 
    ff_mag_sun, mag, fit=fit2, talk=talk, plot=plot

    ; CALCULATE THE STATIC TWEAK MATRIX
    tws2 = ff_mag_twc(fit2, talk=talk)

    ; REJECT BAD MAG POINTS
    ff_mag_reject, mag, fit2, max_err=max_err, ave_per=ave_per, $
        nper_trq=nper_trq, npts_speed_after=npts_speed_after, $
        npts_per_spin=npts_per_spin, n_sm=n_sm, max_sig=max_sig2, $
        npts_speed_before=npts_speed_before, talk=talk, plot=0 

    ; SMOOTH THE FIT AND MAKE DYNAMIC CALIBRATION ARRAY
    twd2 = ff_mag_twd(mag, fit2, n_sm=n_sm_twd, max_sig=max_sig3, $
        talk=talk, plot=plot )
    ff_mag_twkdat, mag, twd2, talk=talk, plot=plot

ENDIF

IF keyword_set(talk) then BEGIN
    print, ' -----'
    print, 'FA_FIELDS_MAGDC: Done! Run time =', systime(1)-tstrt, ' seconds.'
ENDIF

return, mag
end

