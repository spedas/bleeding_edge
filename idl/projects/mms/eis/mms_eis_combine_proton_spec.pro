;+
; mms_eis_combine_proton_spec.pro
;
; PURPOSE:
;   Combine ExTOF and PHxTOF proton energy spectra into a single combined tplot variable
;
; KEYWORDS:
;         probes:             string indicating value for MMS SC #
;         data_rate:          data rate ['srvy' (default), 'brst']
;         data_units:         data units ['flux' (default), 'cps', 'counts']
;         level:              data level ['l1a','l1b','l2pre','l2' (default)]
;
; CREATED BY: I. Cohen, 2017-05-24
;
; REVISION HISTORY:
;       + 2017-06-05, I. Cohen          : added capability to handle burst data
;       + 2017-06-07, I. Cohen          : added capability to handle different data_units
;       + 2017-08-10, I. Cohen          : added warning that combination should only be done for flux data
;       + 2017-08-15, I. Cohen          : adjusted handling of overlapping energy range in combined spectrum
;       + 2017-10-30, I. Cohen          : removed "_omni" suffix
;       + 2017-11-17, I. Cohen          : altered how energy array is constructed; allowed for differences
;                                         in number of time steps between phxtof and extof data; changed probe
;                                         keyword to probes
;       + 2017-12-04, I. Cohen          : added creation of spin-averaged variable; changed to calculate combined
;                                         variables for each individual telescope, instead of just the omni variable;
;                                         added calls to mms_eis_spin_avg.pro and mms_eis_omni.pro
;       + 2018-01-19, I. Cohen          : added capability to handle multiple s/c at once and combine at the end
;       + 2018-02-19, I. Cohen          : added "total" to NAN creation on lines 77-78 to fix syntax
;       + 2018-06-11, I. Cohen          : added creation of new combined energy limits tplot variable
;       + 2018-06-12, I. Cohen          : removed 12 keV energy channel from combined proton spectrum
;       + 2018-08-02, I. Cohen          : fixed issue energy limits in crossover energy range
;       + 2018-08-03, I. Cohen          : removed "fix" from 2018-08-02; changed energy ranges to correctly
;                                         handle burst data
;       + 2018-10-19, I. Cohen          : fixed issue in matching phxtof/extof timing when there are more extof events
;       + 2020-04-07, S. Bingham        : fixed issue in mismatching phxtof/extof timing & E channel stitching
;       + 2020-06-23, E. Grimes         : updated call to mms_eis_omni to use the /spin keyword when calculating the spin-averages
;       + 2020-11-19, I. Cohen          : fixed issue with overlap energies - average between all shared energies
;       + 2020-12-11, I. Cohen          : changed "not KEYWORD_SET" to "undefined" in initialization of some keywords
;       + 2021-01-21, I. Cohen          : removed lowest ExTOF energy channel because of noise near detector threshold
;       + 2021-01-27, I. Cohen          ; fixed error from previous change that duplicated uppermost energy channel
;       + 2021-06-17, I. Cohen          : added level keyword; updated eis_prefix definition to handle new L2 variable names;
;                                         added level to mms_eis_spin_avg and mms_eis_omni calls
;                       
;-
pro mms_eis_combine_proton_spec, probes=probes, data_rate = data_rate, data_units = data_units, level = level, suffix = suffix
  ;
  compile_opt idl2
  if undefined(probes) then probes = '1'
  if undefined(data_rate) then data_rate = 'srvy'
  if undefined(data_units) then data_units = 'flux'
  if undefined(level) then level = 'flux'
  if undefined(suffix) then suffix = ''
  if (data_units ne 'flux') then begin
    print,'Combination of PHxTOF and ExTOF data products is only recommended for flux data!'
    return
  endif
  ;
  for pp=0,n_elements(probes)-1 do begin
    ;
    eis_prefix = 'mms'+probes[pp]+'_epd_eis_'+data_rate+'_'+level+'_'
    ;
    extof_vars = tnames(eis_prefix+'extof_proton_P?_'+data_units+'_t?'+suffix)
    if (extof_vars[0] eq '') then begin
      print,'Must load ExTOF data to combine proton spectra'
      return
    endif
    phxtof_vars = tnames(eis_prefix+'phxtof_proton_P?_'+data_units+'_t?'+suffix)
    if (phxtof_vars[0] eq '') then begin
      print,'Must load PHxTOF data to combine proton spectra'
      return
    endif
    str = string(strsplit(extof_vars[0], '_', /extract))
    if (data_rate eq 'brst') then p_num = strmid(str[6],1,1) else p_num = strmid(str[5],1,1)
    ;
    get_data,eis_prefix+'extof_proton_t0_energy_dminus'+suffix,data=extof_energy_minus
    get_data,eis_prefix+'extof_proton_t0_energy_dplus'+suffix,data=extof_energy_plus
    get_data,eis_prefix+'phxtof_proton_t0_energy_dminus'+suffix,data=phxtof_energy_minus
    get_data,eis_prefix+'phxtof_proton_t0_energy_dplus'+suffix,data=phxtof_energy_plus
    for aa=0,n_elements(extof_vars)-1 do begin
      ;
      ; Make sure ExTOF and PHxTOF data have the same time dimension
      get_data,extof_vars[aa],data=proton_extof
      ; remove lowest ExTOF energy channel because of noise near detector threshold
      proton_extof_energy = proton_extof.v[1:-1]
      proton_extof_flux = proton_extof.y[*, 1:-1]
      get_data,phxtof_vars[aa],data=proton_phxtof
      data_size = [n_elements(proton_phxtof.x),n_elements(proton_extof.x)]
      
      if (data_size[0] eq data_size[1]) then begin
        
        bad_inds = WHERE(proton_phxtof.x - proton_extof.x NE 0, bad_count) ; identify mismatching timesteps
        IF bad_count GT 0 THEN BEGIN ; If mismatching timesteps, find like timesteps
          flag = 0
          FOR tt = 0, N_ELEMENTS(proton_extof.x)-1 DO BEGIN
            dt_dummy = MIN(ABS(proton_extof.x[tt]-proton_phxtof.x),t_ind)
            IF dt_dummy EQ 0 then begin
              IF flag EQ 0 THEN e_inds = tt ELSE e_inds = [e_inds,tt]
              IF flag EQ 0 THEN ph_inds = tt ELSE ph_inds = [ph_inds,t_ind]
              flag = 1
            ENDIF
          ENDFOR
          time_data = proton_extof.x[e_inds]
          phxtof_spec_data = proton_phxtof.y[ph_inds,*]
          extof_spec_data = proton_extof_flux[e_inds,*]
        ENDIF ELSE BEGIN
          time_data = proton_phxtof.x
          phxtof_spec_data = proton_phxtof.y
          extof_spec_data = proton_extof_flux
        ENDELSE 
      endif else if (data_size[0] gt data_size[1]) then begin
      bad_inds = WHERE(proton_phxtof.x[0:n_elements(proton_extof.x)-1] - proton_extof.x NE 0, bad_count) ; identify mismatching timesteps
        IF bad_count GT 0 THEN BEGIN ; If mismatching timesteps, find like timesteps
          flag = 0
          FOR tt = 0, N_ELEMENTS(proton_extof.x)-1 DO BEGIN
            dt_dummy = MIN(ABS(proton_extof.x[tt]-proton_phxtof.x),t_ind)
            IF dt_dummy EQ 0 then begin
              IF flag EQ 0 THEN e_inds = tt ELSE e_inds = [e_inds,tt]
              IF flag EQ 0 THEN ph_inds = tt ELSE ph_inds = [ph_inds,t_ind]
              flag = 1
            ENDIF
          ENDFOR
          time_data = proton_extof.x[e_inds]
          phxtof_spec_data = proton_phxtof.y[ph_inds,*]
          extof_spec_data = proton_extof_flux[e_inds,*]
        ENDIF ELSE BEGIN
          time_data = proton_extof.x
          phxtof_spec_data = proton_phxtof.y[0:n_elements(proton_extof.x)-1,*]
          extof_spec_data = proton_extof_flux
        ENDELSE
      endif else if (data_size[0] lt data_size[1]) then begin
        bad_inds = WHERE(proton_phxtof.x - proton_extof.x[0:n_elements(proton_phxtof.x)-1] NE 0, bad_count) ; identify mismatching timesteps
        IF bad_count GT 0 THEN BEGIN ; If mismatching timesteps, find like timesteps
          flag = 0
          FOR tt = 0, N_ELEMENTS(proton_phxtof.x)-1 DO BEGIN
            dt_dummy = MIN(ABS(proton_phxtof.x[tt]-proton_extof.x),t_ind)
            IF dt_dummy EQ 0 then begin
              IF flag EQ 0 THEN ph_inds = tt ELSE ph_inds = [ph_inds,tt]
              IF flag EQ 0 THEN e_inds = tt ELSE e_inds = [e_inds,t_ind]
              flag = 1
            ENDIF
          ENDFOR
          time_data = proton_phxtof.x[ph_inds]
          phxtof_spec_data = proton_phxtof.y[ph_inds,*]
          extof_spec_data = proton_extof_flux[e_inds,*]
        ENDIF ELSE BEGIN
          time_data = proton_phxtof.x
          phxtof_spec_data = proton_phxtof.y
          extof_spec_data = proton_extof_flux[0:n_elements(proton_phxtof.x)-1,*]
        ENDELSE
      endif
;      if (total(where(phxtof_spec_data eq 0)) ge 0) then phxtof_spec_data[where(phxtof_spec_data eq 0)] = !Values.d_NAN
;      if (total(where(extof_spec_data eq 0) ge 0)) then extof_spec_data[where(extof_spec_data eq 0)] = !Values.d_NAN
      ; Find xPH E below xE E, cross-over E below highest xPH E, and xE E above second highest xPH E
      target_phxtof_energies = where((proton_phxtof.v lt proton_extof_energy[0]), n_target_phxtof_energies)
      target_phxtof_crossover_energies = where(proton_phxtof.v gt proton_extof_energy[0], n_target_phxtof_crossover_energies)
      target_extof_crossover_energies = where(proton_extof_energy lt proton_phxtof.v[-1], n_target_extof_crossover_energies)
      target_extof_energies = where(proton_extof_energy gt proton_phxtof.v[-1], n_target_extof_energies)
      n_energies = n_target_phxtof_energies +  n_target_phxtof_crossover_energies + n_target_extof_energies
      combined_energy_low = dblarr(n_energies)
      combined_energy_hi = dblarr(n_energies)
      ;
      combined_array = dblarr(n_elements(time_data), n_energies)                                          ; time x energy
      combined_energy = dblarr(n_energies)                                                               ; energy
      ;
      ; Combine spectra and store new tplot variable
      combined_array[*,0:n_target_phxtof_energies-1] = phxtof_spec_data[*,target_phxtof_energies]
      combined_energy[0:n_target_phxtof_energies-1] = proton_phxtof.v[target_phxtof_energies]
      combined_energy_low[0:n_target_phxtof_energies-1] = combined_energy[0:n_target_phxtof_energies-1] - phxtof_energy_minus.y[target_phxtof_energies]
      combined_energy_hi[0:n_target_phxtof_energies-1] = combined_energy[0:n_target_phxtof_energies-1] + phxtof_energy_plus.y[target_phxtof_energies]
      for ii=0,n_target_phxtof_crossover_energies-1 do begin
        for tt=0,n_elements(time_data)-1 do combined_array[tt,n_target_phxtof_energies+ii] = average([phxtof_spec_data[tt,target_phxtof_crossover_energies[ii]], extof_spec_data[tt,target_extof_crossover_energies[ii]]],/NAN)
        combined_energy_low[n_target_phxtof_energies+ii] = min([[proton_phxtof.v[n_target_phxtof_energies+ii] - phxtof_energy_minus.y[n_target_phxtof_energies+ii]],[proton_extof_energy[ii] - extof_energy_minus.y[ii]]],/NAN)
        combined_energy_hi[n_target_phxtof_energies+ii] = max([[proton_phxtof.v[n_target_phxtof_energies+ii] + phxtof_energy_plus.y[n_target_phxtof_energies+ii]],[proton_extof_energy[ii] + extof_energy_plus.y[ii]]],/NAN)
        combined_energy[n_target_phxtof_energies+ii] = sqrt(combined_energy_low[n_target_phxtof_energies+ii]*combined_energy_hi[n_target_phxtof_energies+ii])
      endfor
    ;  stop
      combined_array[*,n_elements(proton_phxtof.v):-1] = extof_spec_data[*,target_extof_energies]
      combined_energy[n_elements(proton_phxtof.v):-1] = proton_extof_energy[target_extof_energies]
      combined_energy_low[n_elements(proton_phxtof.v):-1] = proton_extof_energy[target_extof_energies] - extof_energy_minus.y[target_extof_energies]
      combined_energy_hi[n_elements(proton_phxtof.v):-1] = proton_extof_energy[target_extof_energies] + extof_energy_plus.y[target_extof_energies]
      ;
      combined_array[where(finite(combined_array) eq 0)] = 0d
      store_data,eis_prefix+'combined_proton_P'+p_num[0]+'_'+data_units+'_t'+strtrim(string(aa),2)+suffix,data={x:time_data,y:combined_array,v:combined_energy}
      tdegap,eis_prefix+'combined_proton_P'+p_num[0]+'_'+data_units+'_t'+strtrim(string(aa),2)+suffix, /overwrite
      options,eis_prefix+'combined_proton_P'+p_num[0]+'_'+data_units+'_t'+strtrim(string(aa),2)+suffix,spec=1,zrange=[5e0,5e4],zticks=0,zlog=1,minzlog=0.01,yrange=[14,650],yticks=2,ystyle=1,ylog=0,no_interp=1, $
        ysubtitle='Energy!C[keV]',ztitle='1/(cm!E2!N-sr-s-keV)'
      ;
    endfor
    store_data,eis_prefix+'combined_proton_energy_limits',data={x:time_data,y:[[combined_energy_low],[combined_energy_hi]],v:combined_energy}
    ;
    mms_eis_spin_avg, probe=probes[pp], datatype='combined', species='proton', data_units = data_units, data_rate = data_rate, suffix = suffix, level = level
    ;
    mms_eis_omni, probes[pp], species='proton', datatype='combined', tplotnames = tplotnames, suffix = suffix, data_units = data_units, data_rate = data_rate, level = level
    mms_eis_omni, /spin, probes[pp], species='proton', datatype='combined', tplotnames = tplotnames, suffix = suffix, data_units = data_units, data_rate = data_rate, level = level
    ;
  endfor
  ;
  if (n_elements(probes) gt 1) then mms_eis_spec_combine_sc, probes=probes, species = 'proton', data_units = data_units, datatype = 'combined', data_rate = data_rate, suffix = suffix
end