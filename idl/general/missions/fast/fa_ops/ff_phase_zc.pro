;+
; FUNCTION: FF_PHASE_ZC, time_, data_, smooth=smooth, period=period, 
;                        tzero=tzero
;       
; PURPOSE: Calculates the phase from zero crossings. IMPUT ARRAY MUST HAVE
;          CONSTANT DT! SEE FA_FIELDS_BUFS.
;
; INPUT: 
;       time_ -       REQIRED. Double array. NOTE: subtract time(0)
;                     to avoid large errors!
;       data_ -       REQIRED. Must be nearly sinusoidal at spin_per.
;
;
; KEYWORDS: 
;       freq -        Smoothing frequency in Hertz. DEFAULT = 0.8 Slow Survey
;                     and 10.0 in Fast Survey. Optimized by REE.
;       period -      Seed value. Precise value output. Default = 5.0 seconds.
;
; CALLING: 
;       phase = ff_phase_zc(time,data)
;
; OUTPUT: Array of times. Period will be updated.
;       tzero -       Array of times.
;
; INITIAL VERSION: REE/RJS 97-10-02 - see FF_MAGDC.PRO
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; 
;-
;       @(#)ff_phase_zc.pro	1.1     

function ff_phase_zc, time_, data_, freq=freq, period=period, tzero=tzero

two_pi = 2.d*!dpi

; SETUP KEYWORDS.
time0 = time_(0)
time  = time_-time0
if not keyword_set(period) then spin_per = 5.0 else spin_per=period
IF n_elements(freq) eq 0 then BEGIN ; 
    freq = [0.d,10.d]
    if time(1) gt 0.0078 then freq = [0.d,3.2d]
    if time(1) gt 0.031 then freq = [0.d,1.6d]
    if time(1) gt 0.12 then freq = [0.d,0.8d]
ENDIF

; SMOOTH DATA - COPY SO ORIGONAL IS NOT ALTERED
IF keyword_set(freq) THEN BEGIN
    dat = {time:time, comp1:double(data_) }
    fa_fields_filter, dat,freq, /nan
    data = dat.comp1
ENDIF ELSE data = double(data_)

; GET RID OF NANS
index = where(finite(data),n_finite)
IF n_finite gt 0 THEN BEGIN
    time = time(index)
    data = data(index)
ENDIF ELSE return,0

; MAKE A PHASE ARRAY BY LOCATING ZERO CROSSINGS.
; RIPPED OFF FROM RJS
zero_cross = where(data(1:*) le 0.d and data(0:*) gt 0.d, n_zc)
if (n_zc eq 0) then return,0.d

tzero      = ( time(zero_cross+1)*data(zero_cross) - $
               time(zero_cross)*data(zero_cross+1) ) / $
             ( data(zero_cross) - data(zero_cross+1) )

if n_elements(tzero) lt 2 then return, 0

; CALCULATE PERIODS - THROW OUT BAD PERIODS. WE ITERATE TWICE.
period = tzero(1:n_elements(tzero)-1) - tzero(0:n_elements(tzero)-2)
index  = where( period lt spin_per+0.25 AND period gt spin_per-0.25,n_periods)
if (n_periods LT 1) then return,0
ave_period = total(period(index)) / n_periods
index  = where( (period lt ave_period + 0.05) AND $
                (period gt ave_period - 0.05) ,n_periods)
if (n_periods LT 1) then return,0
ave_period = total(period(index)) / n_periods

; KEEP ONLY THE TZEROS ASSOCIATED WITH GOOD PERIODS
tzero_good = dblarr(n_elements(tzero))*!values.d_nan
tzero_good(index)=tzero(index)
tzero_good(index+1)=tzero(index+1)
good_points = where(finite(tzero_good),n_good)
IF n_good gt 0 then tzero=tzero_good(good_points) + time0 ELSE BEGIN
    print, "FF_PHASE_ZC: STOPPED! No good zero crossings."
    return,0
ENDELSE

; CONSTRUCT PHASE
n_pts = n_elements(tzero)
phase = dblarr(n_pts)
phase(0) = 0.d
FOR i=1l, n_pts-1 DO BEGIN
    dt   = tzero(i) - tzero(i-1) + ave_period/2.d
    phase(i) = phase(i-1) + long(dt/ave_period) * two_pi
ENDFOR

; RECONSTRUCT PHASE
phase = ff_interp(time_, tzero, phase, delt=100.) ; /spline)


; SET SPIN_PER AND RETURN tzero_good
period=ave_period
return,phase + !dpi/2.d   ;  ZERO CROSSINGS 180 degrees out of phase.

END
