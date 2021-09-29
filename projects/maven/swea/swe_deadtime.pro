;+
;FUNCTION:   swe_deadtime
;PURPOSE:
;  Calculates the deadtime correction given the measured count rate and the
;  deadtime.  The correction is the ratio of the measured count rate to the 
;  true count rate.  Works for both non-paralyzing and paralyzing
;  behavior.
;
;  For non-paralyzing deadtime: R' = R / (1 + R*tau), where R' is the
;  measured count rate, R is the true count rate, and tau is the deadtime.
;  The measured count rate asympotically approaches 1/tau.  This is the
;  default.
;
;  For paralyzing deadtime: R' = R * exp(-R*tau).  The measured count rate
;  peaks at 1/tau and drops rapidly at higher true count rates.  It is two
;  valued, so one must assume which side of the peak when estimating the 
;  true count rate from the measured count rate.  This routine assumes that
;  R' <= 1/tau.  For a given deadtime, a paralyzing system is more aggressive
;  because more events are missed.
;
;USAGE:
;  dtc = swe_deadtime(rate)
;
;INPUT:
;       rate:         An array of measured raw count rates.
;
;OUTPUT:
;       dtc:          Deadtime correction factor, or the ratio of the 
;                     measured count rate to the true count rate.
;
;KEYWORDS:
;       DEADTIME:     Deadtime.  Default is obtained from mvn_swe_calib.
;                     Once set, this value is persistent.
;
;       PARALYZE:     If set, use paralyzing deadtime.  Once set, this
;                     value is persistent.
;
;       INIT:         If set, initialize the paralyzable deadtime function.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2020-12-15 13:01:44 -0800 (Tue, 15 Dec 2020) $
; $LastChangedRevision: 29491 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_deadtime.pro $
;
;CREATED BY:    David L. Mitchell
;FILE: swe_deadtime.pro
;-
function swe_deadtime, rate, deadtime=deadtime, paralyze=paralyze, init=init

  @mvn_swe_com
  common deadcom, Rtrue, Rmeas, d2r, tau, Rmin, Rpeak

  if (size(swe_dead,/type) eq 0) then begin
    mvn_swe_calib, tab=5, /default  ; initialize common block
    Rtrue = 0                       ; new deadtime, so force a recalculation
  endif

  if (size(deadtime,/type) gt 0) then begin
    swe_dead = deadtime  ; update common block
    Rtrue = 0            ; new deadtime, so force a recalculation
  endif

  if keyword_set(init) then Rtrue = 0  ; force a recalculation

  tau = swe_dead

  if (size(paralyze,/type) gt 0) then swe_paralyze = keyword_set(paralyze)

; Initialize common block

  if (size(Rtrue,/type) lt 5) then begin
    lRmin = -1D
    lRmax = alog10(1D/double(tau))
    Npts = 500
    dlR = (lRmax - lRmin)/double(Npts)
    Rtrue = 10D^(dlR*dindgen(Npts + 1) + lRmin)

    Rmeas = Rtrue * exp(-Rtrue * double(tau))
    d2r = spl_init(Rmeas, Rtrue, /double)
    Rmin = 10D^lRmin
    Rpeak = (1D/tau) * exp(-1D)  ; maximum raw count rate at Rtrue = 1/tau
  endif

; Calculate deadtime correction

  if keyword_set(swe_paralyze) then begin
    trate = rate
    n = where((rate ge Rmin) and (rate le Rpeak), count)
    if (count gt 0L) then trate[n] = float(spl_interp(Rmeas, Rtrue, d2r, rate[n], /double))
    dtc = rate/trate
    n = where(rate gt Rpeak, count)
    if (count gt 0L) then dtc[n] = !values.f_nan
  endif else begin
    dtc = 1. - rate*tau
    n = where(dtc lt swe_min_dtc, count)
    if (count gt 0L) then dtc[n] = !values.f_nan
  endelse

  return, dtc

end
