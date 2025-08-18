;+
;FUNCTION:   mvn_swe_crosscal
;PURPOSE:
;  Calculates SWEA-SWIA cross calibration factor as a function of time.
;  Based on polynomial fits to numerous cross calibrations between SWEA
;  and SWIA in the upstream solar wind, when both instruments were 
;  measuring the complete electron and ion distributions, respectively.
;  Only periods of steady solar wind, when the spacecraft potential can
;  be reliably estimated from SWEA data are used.
;
;  The variation of the cross calibration factor with time after each 
;  MCPHV bump is well fit with a quadratic, so I'll allow extrapolation
;  into periods with no solar wind coverage.
;
;  Assumptions:
;
;    (1) Charge neutrality.
;
;    (2) SWIA is measuring the entire ion distribution.  This is safe 
;        in the upstream solar wind, as long as the spacecraft is Sun
;        pointed, which is most of the time.  Watch out for times of
;        Earth point.
;
;    (3) The energy flux in SWEA's blind spots is the same as the 
;        average energy flux over the rest of the field of view.  This
;        can be very much in error for the solar wind halo distribution;
;        however, most of the density is in the core distribution, which
;        is not strongly directional.
;
;USAGE:
;  factor = mvn_swe_crosscal(time)
;
;INPUTS:
;       time:         A single time or an array of times in any format 
;                     accepted by time_double().
;
;KEYWORDS:
;       ON:           Turn cross calibation switch on.
;
;       OFF:          Turn cross calibration switch off.
;
;       REFRESH:      Refresh the polynomial coefficients.
;
;       EXTRAP:       Extrapolate past the last measured cross calibration
;                     factor using a polynomial fit to measurements since the 
;                     last MCPHV bump.  The default is to use the last 
;                     known value.
;
;       SILENT:       Don't print any warnings or messages.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-01-22 14:39:31 -0800 (Wed, 22 Jan 2025) $
; $LastChangedRevision: 33078 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_crosscal.pro $
;
;CREATED BY:    David L. Mitchell  05-04-16
;FILE: mvn_swe_crosscal.pro
;-
function mvn_swe_crosscal, time, on=on, off=off, refresh=refresh, extrap=extrap, silent=silent

  @mvn_swe_com
  common swe_cc_com, tc, ac, eflg

  if ((size(tc,/type) eq 0) or keyword_set(refresh)) then begin
    tc = time_double(['2014-03-22','2014-11-12','2015-12-20','2016-10-25','2017-08-12','2018-11-13','2023-09-21'])
    ac = dblarr(4, n_elements(tc))
    ac[*,0] = [2.6D   ,  0.0D     ,  0.0D     ,  0.0D      ]  ; MCPHV = 2500 V
    ac[*,1] = [2.3368D, -9.9426d-4,  2.6014d-5,  0.0D      ]  ; MCPHV = 2600 V
    ac[*,2] = [2.2143D,  7.9280d-4,  1.4300d-5,  0.0D      ]  ; MCPHV = 2700 V
    ac[*,3] = [2.0027D,  7.2892d-3, -1.1918d-5,  0.0D      ]  ; MCPHV = 2750 V
    ac[*,4] = [2.2929D,  6.0841d-3, -2.0345d-5,  3.0202d-8 ]  ; MCPHV = 2800 V
    ac[*,5] = [2.0304D,  1.7992d-3, -1.2476d-6,  3.0578d-10]  ; MCPHV = 2875 V
    ac[*,6] = [2.0200D,  0.0D     ,  0.0D     ,  0.0D      ]  ; MCPHV = 2925 V
    eflg = 0                                                  ; 0 -> extrapolate using last known value
                                                              ; 1 -> extrapolate using last polynomial
  endif

  domsg = ~keyword_set(silent)

  if (size(extrap,/type) gt 0) then begin
    eflg = keyword_set(extrap)
    if (domsg) then if (eflg) then print,"SWE-SWI polynomial extrapolation ON." $
                              else print,"SWE-SWI polynomial extrapolation OFF."
    return, 0.
  endif
  
  if keyword_set(on) then begin
    swe_cc_switch = 1
    if (domsg) then print,"SWE-SWI crosscal enabled."
    return, 0.
  endif

  if keyword_set(off) then begin
    swe_cc_switch = 0
    if (domsg) then print,"SWE-SWI crosscal disabled."
    return, 0.
  endif

  cc = replicate(1., n_elements(time))
  if (~swe_cc_switch) then return, cc

  t = time_double(time)

  indx = where(t lt t_mcp[1], count)                        ; MCPHV = 2500 V
  if (count gt 0L) then cc[indx] = ac[0,0]

  indx = where((t ge t_mcp[1]) and (t lt t_mcp[2]), count)  ; MCPHV = 2600 V
  if (count gt 0L) then cc[indx] = ac[0,1]

; Polynomial fits to SWE-SWI cross calibration data
  
  indx = where((t ge t_mcp[2]) and (t lt t_mcp[3]), count)  ; MCPHV = 2600 V
  if (count gt 0L) then begin
    i = 1
    day = (t[indx] - tc[i])/86400D
    cc[indx] = ac[0,i] + day*(ac[1,i] + day*(ac[2,i] + day*ac[3,i]))
  endif
  
  indx = where((t ge t_mcp[3]) and (t lt t_mcp[4]), count)  ; MCPHV = 2700 V
  if (count gt 0L) then begin
    i = 2
    day = (t[indx] - tc[i])/86400D
    cc[indx] = ac[0,i] + day*(ac[1,i] + day*(ac[2,i] + day*ac[3,i]))
  endif
  
  indx = where((t ge t_mcp[4]) and (t lt t_mcp[5]), count)  ; MCPHV = 2600 V
  if (count gt 0L) then begin
    i = 1
    day = (t[indx] - tc[i])/86400D
    cc[indx] = ac[0,i] + day*(ac[1,i] + day*(ac[2,i] + day*ac[3,i]))
  endif
  
  indx = where((t ge t_mcp[5]) and (t lt t_mcp[6]), count)  ; MCPHV = 2700 V
  if (count gt 0L) then begin
    i = 2
    day = (t[indx] - tc[i])/86400D
    cc[indx] = ac[0,i] + day*(ac[1,i] + day*(ac[2,i] + day*ac[3,i]))
  endif

  indx = where((t ge t_mcp[6]) and (t lt t_mcp[7]), count)  ; MCPHV = 2750 V
  if (count gt 0L) then begin
    i = 3
    day = (t[indx] - tc[i])/86400D
    cc[indx] = (ac[0,i] + day*(ac[1,i] + day*(ac[2,i] + day*ac[3,i]))) > 2.25D
  endif

  indx = where((t ge t_mcp[7]) and (t lt t_mcp[8]), count)  ; MCPHV = 2800 V
  if (count gt 0L) then begin
    i = 4
    day = (t[indx] - tc[i])/86400D
    cc[indx] = ac[0,i] + day*(ac[1,i] + day*(ac[2,i] + day*ac[3,i]))
  endif

  indx = where((t ge t_mcp[8]) and (t lt t_mcp[9]), count)  ; MCPHV = 2875 V
  if (count gt 0L) then begin
    i = 5
    day = (t[indx] - tc[i])/86400D
    cc[indx] = ac[0,i] + day*(ac[1,i] + day*(ac[2,i] + day*ac[3,i]))
  endif

  indx = where((t ge t_mcp[9]) and (t lt t_mcp[10]), count) ; MCPHV = 2925 V
  if (count gt 0L) then begin
    i = 6
    day = (t[indx] - tc[i])/86400D
    cc[indx] = ac[0,i] + day*(ac[1,i] + day*(ac[2,i] + day*ac[3,i]))
  endif

; Extrapolate past last measured SWE-SWI cross calibration

  indx = where(t ge t_mcp[10], count)
  if (count gt 0L) then begin
    i = 6
    if (eflg) then tt = t[indx] else tt = t_mcp[10]
    day = (tt - tc[i])/86400D
    cc[indx] = ac[0,i] + day*(ac[1,i] + day*(ac[2,i] + day*ac[3,i]))

    if (domsg) then begin
      msg = "Warning: SWE-SWI cross calibration factor "
      if (eflg) then print,msg,"extrapolated after ",time_string(t_mcp[10],prec=-3) $
                else print,msg,"fixed after ",time_string(t_mcp[10],prec=-3)
    endif
  endif

  return, cc

end
