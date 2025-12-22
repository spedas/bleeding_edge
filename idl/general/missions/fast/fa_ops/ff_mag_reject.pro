;+
; PROCEEDURE: FF_MAG_REJECT, mag, fit
;       
; PURPOSE: REJECTS BAD MAG DATA. 
;          IDL 5 OR HIGHER - USES POINTERS! 
;
; INPUT: 
;       mag -         REQUIRED. 'MagDC' data structure. MAY HAVE POINTERS!
;       fit -         REQUIRED. Fit to mag data. See ff_magfit.
;
;
; KEYWORDS: 
;       max_err -     OPTIONAL. Maximun allowable error. DFLT = 100 nT
;       ave_per -     OPTIONAL. S/C period.              DFLT = 5.0 s
;       nper_trq -    OPTIONAL. Throw out points within nper_trq
;                     spin periods of a torque boundary. DFLT = 1.5
;       npts_speed_af OPTIONAL. Throw out npts_speed_after
;                     a speed change boundary. DFLT = 40
;       npts_speed_be OPTIONAL. Throw out npts_speed_before
;                     a speed change boundary. DFLT = 5
;       npts_per_spin-OPTIONAL. Too tricky to describe.  DFLT = 16
;       n_sm -        OPTIONAL. N_points to smooth fits. DFLT = 21
;       max_sig -     OPTIONAL. Max error in fit.        DFLT = 10 nT
;       talk -        OPTIONAL. Give informational message.
;       plot -        OPTIONAL. Plot results.
;
; CALLING: 
;       ff_mag_reject, mag, fit
;
; OUTPUT: Adds notch, notch3, and bphase to mag.
;
; INITIAL VERSION: REE/RJS/KRB 97-10-20 - see UCLA_MAG_DESPIN, FF_XYMAGFIX
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; 
;-
;       @(#)ff_mag_reject.pro	1.2     

pro ff_mag_reject, mag, fit, max_err=max_err, ave_per=ave_per, $
    talk=talk, nper_trq=nper_trq, npts_speed_after=npts_speed_after, $
    npts_per_spin=npts_per_spin, n_sm=n_sm, max_sig=max_sig, $
    npts_speed_before=npts_speed_before, plot=plot

IF keyword_set(talk) then BEGIN
    tstrt   = systime(1)
    print, '-----'
    print, 'FF_MAG_REJECT: Starting ..."
ENDIF

; CHECK KEYWORDS
two_pi = 2.d * !dpi
if not keyword_set(max_err) then max_err = 100.0; nT
if not keyword_set(ave_per) then ave_per = 5.d
if not keyword_set(npts_per_spin) then npts_per_spin = 16
if not keyword_set(nper_trq) then nper_trq = 1.5
if not keyword_set(npts_speed_after) then npts_speed_after = 40l
if not keyword_set(npts_speed_before) then npts_speed_before = 5l
if not keyword_set(n_sm) then n_sm = 21l
if not keyword_set(max_sig) then max_sig = 10.d
if ptr_valid(mag.time(0)) then is_ptr=1 else is_ptr=0

; SMOOTH THEN FITS
fit_sm = ff_magfit_sm(mag, fit, n_sm=n_sm, max_sig=max_sig)

; MAKE PHASE ARRAY
phs = fit_sm.phs
FOR i = 1l, (fit_sm.npts-1) DO BEGIN
    dt = fit_sm.time(i) - fit_sm.time(i-1)
    dp = phs(i) - phs(i-1) - dt*two_pi/ave_per + !dpi
    if (dp) LT 0.d    then phs(i) = phs(i) + fix(-dp/two_pi) * two_pi + two_pi
    if (dp) GE two_pi then phs(i) = phs(i) - fix(dp/two_pi)  * two_pi
ENDFOR

; MAKE MAG PHASE ARRAY
if is_ptr then phase = ff_interp(*mag.time, fit_sm.time, phs) $
   else phase = ff_interp(mag.time, fit_sm.time, phs)

; CREATE A PHASE ARRAY WITH npts_per_spin points per spin.
phs_strt  = phase(0) - (phase(0) mod two_pi) - 2.d*two_pi
phs_stop  = phase(mag.npts-1) - (phase(mag.npts-1) mod two_pi) + 3.d*two_pi
n_spins   = long( (phs_stop - phs_strt) / two_pi )
n_fix_phs = n_spins*npts_per_spin + 1l
fix_phase = dindgen(n_fix_phs) * two_pi / double(npts_per_spin) + $
            phs_strt + !dpi / double(npts_per_spin)

; CALCULATE EXPECTED MAG AT FIX_PHASE
cos_fix = cos(fix_phase)
sin_fix = sin(fix_phase)

xs      = ff_interp(fix_phase, phs, fit_sm.xs)
xc      = ff_interp(fix_phase, phs, fit_sm.xc)
x0      = ff_interp(fix_phase, phs, fit_sm.x0)
ys      = ff_interp(fix_phase, phs, fit_sm.ys)
yc      = ff_interp(fix_phase, phs, fit_sm.yc)
y0      = ff_interp(fix_phase, phs, fit_sm.y0)
;zs      = ff_interp(fix_phase, phs, fit_sm.zs)
;zc      = ff_interp(fix_phase, phs, fit_sm.zc)
;z0      = ff_interp(fix_phase, phs, fit_sm.z0)

x       = x0 + xs*sin_fix + xc*cos_fix
y       = y0 + ys*sin_fix + yc*cos_fix
;z       = z0 + zs*sin_fix + zc*cos_fix

; INTERPRET EXPECTED MAG INTO MAG PHASE
x       = ff_interp(phase, fix_phase, x, /spline, delt=1000.)
y       = ff_interp(phase, fix_phase, y, /spline, delt=1000.)
;z       = ff_interp(phase, fix_phase, z)

IF is_ptr then BEGIN
    x_err   = *mag.comp1 - x
    y_err   = *mag.comp2 - y
;    z_err   = *mag.comp3 - z
ENDIF ELSE BEGIN
    x_err   = mag.comp1 - x
    y_err   = mag.comp2 - y
;    z_err   = mag.comp3 - z
ENDELSE

; The following code is entirely ad hoc. The error in typically has 
; peak-to-peak values between 5 nT and 50 nT. During periods of strong
; currents, one sees error (between measurement and reconstructed fit)
; up to 100 nT. We do not want to throw those fits away. I will use the 
; following algorithm:
; (1) Calculate smoothed median abs(x_err) and abs(y_err).
; (2) Throw away points whose spin_plane_err > 3 times median.
; (3) Throw away any points within 1.5 spins of torquer boundary,
;     depending on z_err!
; (4) Throw away the 40 points after a speed change boundary in x and y.
; (5) Z_err will not be used except at torquer boundaries. 

; FIRST, CALCULATE MEDIAN X and Y ERROR
err = sqrt (x_err*x_err + y_err*y_err)

ind      = lindgen(mag.npts)
fix_phs1 = dindgen(n_spins+1) * two_pi  + phs_strt
ind      = ff_interp(fix_phs1, phase, ind)
ave_err = dblarr(n_spins+1)
FOR i = 0, n_spins DO BEGIN
    strt = (ind( (i-3) > 0 )         > 0) < (mag.npts - 1)
    stop = (ind( (i+3) < (n_spins) ) > 0) < (mag.npts - 1)
    iuse = where(err(strt:stop) LT  max_err, n_use)
    if n_use GT 0 then ave_err(i)=total(err(iuse+strt))/n_use
ENDFOR

spin_err = ff_interp(phase, fix_phs1, ave_err)
notch    = (err LT max_err) AND (err LT (spin_err*2.0+max_err/2.0) )

; NOW FIND TORQUE BOUNDARIES
if is_ptr then torq = (*mag.torque)(1:*) - (*mag.torque)(0:*) $
    else torq = mag.torque(1:*) - mag.torque(0:*)
i_torq   = where(torq NE 0, n_torq) 

FOR i=0, n_torq-1 do BEGIN
    ind = where( abs(phase - phase(i_torq(i)) ) LT nper_trq*two_pi, n_ind)
    if n_ind GT 0 then notch(ind) = 0
ENDFOR

; DONE WITH Z-NOTCH
if is_ptr then notch3   = ptr_new(notch) else notch3 = notch

; NOW THROW OUT SPEED BOUNADRIES
if is_ptr then speed = (*mag.speed)(1:*) - (*mag.speed)(0:*) $
    else speed = mag.speed(1:*) - mag.speed(0:*)
i_speed  = where(speed NE 0, n_speed) 

FOR i=0, n_speed-1 do BEGIN
    strt = (i_speed(i) - npts_speed_before ) > 0
    stop = (i_speed(i) + npts_speed_after ) < (mag.npts-1)
    notch(strt:stop) = 0
ENDFOR

if is_ptr then notch   = ptr_new(notch)
if is_ptr then phase   = ptr_new(phase)
if is_ptr then ptr_free,mag.notch

add_str_element, mag, 'notch', notch
add_str_element, mag, 'notch3', notch3
add_str_element, mag, 'bphase', phase

if is_ptr then dummy = where(*notch, npts) else dummy = where(notch,npts)

IF keyword_set(talk) then BEGIN
    print, 'FF_MAG_REJECT: Rejected: ', mag.npts-npts, $
           ' points out of', mag.npts, ' points.'
    print, 'FF_MAG_REJECT: Run time =', systime(1)-tstrt, ' seconds.'
ENDIF

IF keyword_set(plot) AND is_ptr then BEGIN
    wi, plot-1
    !p.multi=0
    !p.psym = 3
    ind1 = where(*notch)
    ind0 = where(*notch EQ 0)
    x=[-0.4,0.4,0.4,-0.4]
    y=[0.4, 0.4, -0.4, -0.4]
    usersym, x, y, /fill
    plot, *mag.time-(*mag.time)(0), *mag.comp3, yran=[-8000,8000], $
          charsize=2.0, xtitle='TIME', ytitle = 'nT', $
          title='FF_MAG_REJECT RESULTS'
    oplot, (*mag.time)(ind1)-(*mag.time)(0), (*mag.comp3)(ind1), col=1
    oplot, (*mag.time)(ind0)-(*mag.time)(0), (*mag.comp3)(ind0), col=5, psym=8
    oplot, (*mag.time)-(*mag.time)(0), (*mag.speed)*1000, col=3, psym=0
    oplot, (*mag.time)-(*mag.time)(0), (*mag.torque)*4000-2000, col=4, psym=0
    xyouts, 4000, -6000,'MAGENTA - MAG.COMP3 (Z)', charsize=1.5
    xyouts, 4000, -7000,'YELLOW  - REJECTED POINTS', charsize=1.5
    xyouts, 4000, -8000,'LT BLUE - LOG2(SAMPLE RATE)', charsize=1.5
    xyouts, 4000, -9000,'GREEN    - TORQUE', charsize=1.5
    !p.psym = 0
    wshow, /icon
    wset,0
    plot=plot+1
ENDIF

return
END
