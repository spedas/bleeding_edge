

;coeff = [0.00E+00,  0.00E+00,  -5.76E-20, 5.01E-15,  -1.68E-10,
;         2.69E-06,  -2.33E-02, 9.33E+01]


function spp_spc_met_to_unixtime_old,met,reverse=reverse

 ; dprint,'hello'
  ;; long(time_double('2000-1-1/12:00'))  ;Early SWEM definition
  epoch =  946771200d - 12L*3600
  ;; long(time_double('2010-1-1/0:00')) ; Correct SWEM use
  epoch =  1262304000d
  if keyword_set(reverse) then begin
    return,met -epoch
  endif
  if met lt 1e6 then begin
    dprint,dlevel=4,'Bad MET ',time_string(met+epoch) ,dwait=5.
  ;  help,/trace
    return, !values.d_nan
  endif
  if met gt 'FFFFFFFE'x then begin
    dprint,dlevel=4,'Bad MET: 0xFFFF  - Restarting Op???'
    return, !values.d_nan
  endif
  unixtime =  met +  epoch

  return,unixtime

end



;
;+
;Function:  spp_spc_met_to_unixtime
;Purpose:  Convert MET (mission Elapsed Time) to Unix Time  (which is almost equivalent to UTC)
;see also:  "spp_spc_unixtime_to_met" for the reverse conversion
; This routine is in the process of being modified to use SPICE Kernels to correct for clock drift as needed.
; Author: Davin Larson
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-09-08 13:30:40 -0700 (Sat, 08 Sep 2018) $
; $LastChangedRevision: 25751 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spp_spc_met_to_unixtime.pro $
;-
function spp_spc_met_to_unixtime,input,reverse=reverse,correct_clockdrift=correct_clockdrift   ,reset=reset   ;,prelaunch = prelaunch

  common spp_spc_met_to_unixtime_com, cor_clkdrift, icy_installed, kernel_verified, time_verified, sclk, tls

  ;Set clockdrift by default
  if n_elements(correct_clockdrift) eq 1 then begin
    cor_clkdrift = correct_clockdrift
  endif

  if n_elements(cor_clkdrift) eq 0 then cor_clkdrift = 0b

  if keyword_set(cor_clkdrift) then begin
    if  n_elements(kernel_verified) eq 0 || keyword_set(reset) then begin ; check for cspice first
      if spice_test() then begin
        ;       tls = spice_standard_kernels(/load) ;jmm, 22-sep-2014;  DEL, tls  included in call on next line
        tls  = spp_spice_kernels('LSK',/load)  ; getting only the LSK file
        sclk = spp_spice_kernels('SCK',/load)
        if keyword_set(sclk)  then begin
          kernel_verified = 1
        endif else begin
          kernel_verified = 0
          dprint,dlevel=2,'ICY is not installed.'
          dprint,dlevel=2,'Times are subject to spacecraft clock drift.'
          prelaunch = 1
        endelse
      endif else begin
        kernel_verified = 0
        prelaunch = 1
      endelse
      reset=0
      time_verified = systime(1)
    endif
  endif else cor_clkdrift = 0b ;need to set this to avoid crash at line 66, jmm, 22-sep-2014


  if n_elements(input) eq 0 then message,'Must provide input'

  if keyword_set(reverse) then begin
    if n_params() ge 1 then unixtime = input
    if ~keyword_set(cor_clkdrift)  then begin
     ;  maven: epoch =  946771200d - 12L*3600   ; long(time_double('2000-1-1/12:00'))  ; Normal use
      epoch =  1262304000d
      ut = time_double(unixtime)
      ;    if unixtime[0] le 1354320000  then unixtime = met + epoch + 3600L*12   ; correction prior to '2012-12-1'
      delta = (ut le 1354320000) * 3600L*12
      met = ut - epoch + delta
      return,met
    endif else begin
      ;   dprint,'Using cspice',dlevel=3
      et = time_ephemeris(unixtime)
      met = double(et)
      for i = 0,n_elements(met)-1 do begin
        cspice_sce2s, -202, et[i], sclk_out
        seconds = double(strmid(sclk_out,2,10))
        subticks = double(strmid(sclk_out,13,5))
        met[i] = seconds+subticks/(2.0^16)
      endfor
      return,met
    endelse
    return,met
  endif

  met = input
  if ~cor_clkdrift then begin
    ;    epoch =  978307200d    ; long(time_double('2001-1-1'))  ; valid for files prior to about June, 2012
   ;maven: epoch =  946771200d - 12L*3600   ; long(time_double('2000-1-1/12:00'))  ; Normal use
    epoch =  1262304000d
    unixtime =  met +  epoch
    ;    if unixtime[0] le 1356998400  then unixtime = met + epoch + 3600L*12   ; correction prior to '2013-1-1'
    ;    if unixtime[0] le 1354320000  then unixtime = met + epoch + 3600L*12   ; correction prior to '2012-12-1'
    delta = (unixtime le 1354320000) * 3600L*12
    unixtime += delta
    ;    if unixtime[0] le 1351728000  then unixtime = met + epoch + 3600L*12   ; correction prior to '2012-11-1'
  endif else begin
    seconds = floor(met,/l64)
    subseconds = met mod 1
    subticks = round(subseconds*65536)
    sclk_in = string(seconds)+':'+string(subticks)
    n = n_elements(met)
    cspice_scs2e, -96, sclk_in, ET
    unixtime = time_ephemeris(ET,/et2ut)
  endelse

  return,unixtime
end


