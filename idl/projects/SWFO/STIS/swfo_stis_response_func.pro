; $LastChangedBy: davin-mac $
; $LastChangedDate: 2024-04-04 08:02:24 -0700 (Thu, 04 Apr 2024) $
; $LastChangedRevision: 32519 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_response_func.pro $
; $Id: swfo_stis_response_func.pro 32519 2024-04-04 15:02:24Z davin-mac $


function swfo_stis_response_func,energy_steps, parameters=flux_func,eflux_func=eflux_func,pflux_func=pflux_func,choice=choice

  ;  common swfo_stis_response_func_com,
  calval=swfo_stis_inst_response_calval()

  if ~keyword_set(flux_func) then begin
    nrgs = [30.,100.,300.,1000.,3000.,1e4,3e4,1e5]
    nrgs = 10. * 10^findgen(4)
    flux = 1e6 * nrgs ^(-1.6)
    if ~isa(pflux_func) then begin
      pflux_func = spline_fit3( !null, nrgs,flux,/xlog,/ylog )
    endif
    if ~isa(eflux_func) then begin
      eflux_func = spline_fit3( !null ,nrgs,flux/3,/xlog,/ylog)
    endif
    flux_func = {func:'swfo_stis_response_func', $
      pflux: pflux_func,  $
      eflux: eflux_func,  $
      choice: 3   $
    }
  endif

  if ~isa(energy_steps) then begin    ; pass in a !null to get the raw
    return,flux_func
  endif

  if ~keyword_set(choice) then choice = flux_func.choice

  if isa(energy_steps,/float) then begin
    ;dprint,'choice= ',choice
    flux = 0.
    if (choice and 1) ne 0 then flux += func(energy_steps,param=flux_func.pflux)
    if (choice and 2) ne 0 then flux += func(energy_steps,param=flux_func.eflux)
    return,flux
  endif 
  
  
  
  if isa(energy_steps,/int) then begin
    responses = struct_value(calval,'responses')
    if ~isa(responses,'hash') then message,'Need to save responses'
    total_rate = 0.
    if (choice and 1) ne 0 then begin
      resp = struct_value(responses,'Proton')
      if isa(resp) then begin
        resp_nrg = resp.e_inc
        p_flux = func(resp_nrg,param = flux_func.pflux)    ; interpolate the flux to the reponse matrix sampling
        p_rate =  (transpose(resp.Mde) # p_flux )       ; determine instrument rate
        total_rate += p_rate
      endif else begin
        p_rate = 0.
        dprint,'No response function found for: ','Proton'
      endelse
    endif
    if (choice and 2) ne 0 then begin
      resp = struct_value(responses,'Electron')
      if isa(resp) then begin
        resp_nrg = resp.e_inc
        e_flux = func(resp_nrg,param = flux_func.eflux)    ; interpolate the flux to the reponse matrix sampling
        e_rate =  (transpose(resp.Mde) # e_flux )       ; determine instrument rate
        total_rate += e_rate
      endif else begin
        e_rate = 0.
        dprint,'No response function found for: ','Electron'
      endelse
    endif
    if isa(energy_steps,/array) then return, total_rate[ energy_steps ]
    return, total_rate[0:48*14-1] > 2e-5
  endif

end

