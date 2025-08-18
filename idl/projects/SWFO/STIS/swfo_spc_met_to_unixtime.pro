

;
;+
;Function:  spp_spc_met_to_unixtime
;Purpose:  Convert MET (mission Elapsed Time) to Unix Time  (which is almost equivalent to UTC)
;see also:  "spp_spc_unixtime_to_met" for the reverse conversion
; This routine is in the process of being modified to use SPICE Kernels to correct for clock drift as needed.
; Author: Davin Larson
; $LastChangedBy: rjolitz $
; $LastChangedDate: 2025-03-04 10:57:07 -0800 (Tue, 04 Mar 2025) $
; $LastChangedRevision: 33161 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_spc_met_to_unixtime.pro $
;-
function swfo_spc_met_to_unixtime,input,reverse=reverse,correct_clockdrift=correct_clockdrift,reset=reset,ephemeris_time=et,kernels=kernels  ;,prelaunch = prelaunch

  common swfo_spc_met_to_unixtime_com2, cor_clkdrift, icy_installed, kernel_verified, time_verified, sclk, tls,epoch,last_met

  ;Do not Set clockdrift by default
  if n_elements(correct_clockdrift) eq 1 then begin
    cor_clkdrift = correct_clockdrift
  endif

  if n_elements(cor_clkdrift) eq 0 then cor_clkdrift = 0b

  if keyword_set(cor_clkdrift) then begin
    message,'Not implemented yet'
    if  n_elements(kernel_verified) eq 0 || keyword_set(reset) then begin ; check for cspice first
      if spice_test() then begin
        ;       tls = spice_standard_kernels(/load) ;jmm, 22-sep-2014;  DEL, tls  included in call on next line
 ;       tls  = swfo_spice_kernels('LSK',/load,trange=[0,1])  ; getting only the LSK file
 ;       sclk = swfo_spice_kernels('SCK',/load,trange=[0,1]) ;dummy trange is set to prevent time prompt if timespan not set
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
  endif    ;else cor_clkdrift = 0b ;need to set this to avoid crash at line 66, jmm, 22-sep-2014


  if n_elements(epoch) eq 0 then begin
    epoch =  1262304000d
    epoch =  time_double('2010-1-1') -3  ;  '2010-1-1'  add 3 leap seconds
    epoch =  time_double('1958-1-1')
    ;epoch = 0
  endif
  
  if n_elements(input) eq 0 then begin
    dprint,'Must provide input';   ;reseting the epoch
    epoch = systime(1) - last_met
    dprint,'Epoch set to: '+time_string(epoch)
    return,epoch
  endif 

  if keyword_set(reverse) then begin
    if n_params() ge 1 then unixtime = input
    if ~keyword_set(cor_clkdrift)  then begin
      ut = time_double(unixtime)
      met = ut - epoch 
;      printdat,time_string(met)
      return,met
    endif else begin
      dprint,'Using cspice',dlevel=3
      et = time_ephemeris(unixtime)
      met = double(et)
      for i = 0,n_elements(met)-1 do begin
        cspice_sce2s, -96, et[i], sclk_out
        seconds = double(strmid(sclk_out,2,10))
        subticks = double(strmid(sclk_out,13,5))
        met[i] = seconds+subticks/(2.0^16)
      endfor
      return,met
    endelse
    message   ; this should never occur
    return,met
  endif
  
  ;dprint,'hello

  met = input
  last_met = met
  if epoch eq 0 then begin
    epoch = systime(1) - met
  endif
  if ~cor_clkdrift then begin
    unixtime =  met +  epoch
  endif else begin
    message,'Not implemented!'
    seconds = floor(met,/l64)
    subseconds = met mod 1
    subticks = round(subseconds*50000)
    sclk_in = string(seconds)+':'+string(subticks)
    n = n_elements(met)
    cspice_scs2e, -96, sclk_in, ET
    unixtime = time_ephemeris(ET,/et2ut)
  endelse

;  kernels=[tls,sclk]
;dprint,time_string(unixtime)
  return,unixtime
end


