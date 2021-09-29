;+
; PROCEDURE:
;         mms_eis_spec_combine_sc
;
; PURPOSE:
;         Combines omni-directional energy spectrogram variable from EIS on multiple MMS spacecraft
;
; KEYWORDS:
;         probes:        Probe # to calculate the spin average for
;                       if no probe is specified the default is probe '1'
;         datatype:     eis data types include ['electronenergy', 'extof', 'phxtof'].
;                       If no value is given the default is 'extof'.
;         data_rate:    instrument data rates for eis include 'brst' 'srvy'. The
;                       default is 'srvy'.
;         data_units:   desired units for data. for eis units are ['flux', 'cps', 'counts'].
;                       The default is 'flux'.
;         level:        data level ['l1a','l1b','l2pre','l2' (default)]
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variable.
;         species:      proton (default), oxygen, helium (formerly alpha) or electron
;         
; CREATED BY: I. Cohen, 2017-11-17
;
; REVISION HISTORY:
;         + 2017-12-01, I. Cohen        : added call to mms_eis_spin_avg.pro
;         + 2018-01-04, I. Cohen        : removed bad "error" message
;         + 2018-02-19, I. Cohen        : added ability to handle multiple species; fixed how missing spacecraft data is handled
;         + 2019-11-21, I. Cohen        : added ability to handle different data_units; changed new variable prefix to 'mmsx' instead of 'mms#-#'
;         + 2020-03-30, I. Cohen        : removed probes keyword, added ability to automatically define probes based on loaded EIS data
;         + 2020-06-08, I. Cohen        : fixed issue with counting MMSX data (i.e. thinking there were 5 probes)
;         + 2020-09-14, I. Cohen        : fixed issue with proton being hardcoded in eis_sc_check
;         + 2020-09-28, I. Cohen        : fixed issue with proton being hardcoded in call for spin-averaging
;         + 2020-09-29, I. Cohen        : changed "mmsx" prefix to mms#-# for consistency with other EIS procedures and 
;                                         removed call to mms_eis_spin_avg.pro, instead create spin-averaged variables directly here
;         + 2020-09-30, I. Cohen        : removed duplicate "datatype" in name of tplot spin variable (line 105)
;         + 2020-10-26, I. Cohen        : added missing "datatype" in definition of prefix for survey data                   
;         + 2020-12-11, I. Cohen        : moved eis_sc_check definition into species loop to address issue handling multiple species from single call
;         + 2021-02-09, I. Cohen        : added helium to species in header under KEYWORD section 
;         + 2021-02-15, R. Nikoukar     : accommodate data_units other than flux
;         + 2021-02-24, I. Cohen        : changed combined s/c variable names from mms#-# to mmsx
;         + 2021-03-11, I. Cohen        : updated to allow to work for electrons
;         + 2021-03-16, R. Nikoukar     : use existing individual spacecraft spin parameters to make combined spacecraft spin parameters
;         + 2021-04-08, I. Cohen        : added level keyword; updated allmms_prefix, omni_vars, & prefix definitions to handle new L2 variable names
;         + 2021-05-12, I. Cohen        : fixed eis_sc_check definition to handle any datatype
;         + 2021-07-09, I. Cohen        : fixed default level defition to 'l2'
;
;-
pro mms_eis_spec_combine_sc, species = species, data_units = data_units, datatype = datatype, data_rate = data_rate, level = level, suffix=suffix
  ;
  compile_opt idl2
  if undefined(datatype) then datatype = 'extof'
  if undefined(data_units) then data_units = 'flux'
  case data_units of
    'flux': ztitle_string = 'Intensity!C[1/cm!U-2!N-sr-s-keV]'
    'cps': ztitle_string = 'CountRate!C[counts/s]'
    'counts': ztitle_string = 'Counts!C[counts]'
  endcase
  if undefined(suffix) then suffix = ''
  if undefined(data_rate) then data_rate = 'srvy'
  if undefined(species) then species = 'proton'
  if datatype eq 'electronenergy' then species = 'electron'
  if undefined(level) then level = 'l2'
  ;
  ;
  suffix_ind = ['', '_spin']
  for sp = 0, n_elements(suffix_ind)-1 do begin         ; loop through to handle both spin-avg and "full-resolution" variables
    ;
    for ss=0,n_elements(species)-1 do begin              ; loop through species
      ;
      ;if (datatype[0] ne 'phxtof') then eis_sc_check = tnames('mms*eis*extof_'+species[ss]+'*' + data_units + '*omni' + suffix_ind[sp] ) else eis_sc_check = tnames('mms*eis*phxtof_'+species[ss]+'*' + data_units + '*omni'+ suffix_ind[sp])
      eis_sc_check = tnames('mms*eis*' + data_rate + '*' + datatype+'*' + species[ss] + '*' + data_units + '*omni'+ suffix_ind[sp])
      ;
      probes = strmid(eis_sc_check, 3, 1)
      if (n_elements(probes) gt 4) then probes = probes[0:-2]
      ; if (n_elements(probes) gt 1) then probe_string = probes[0]+'-'+probes[-1] else probe_string = probes
      probe_string = 'x'
      allmms_prefix = 'mmsx_epd_eis_'+data_rate+'_'+level+'_'+datatype+'_'
      ;
      ; DETERMINE SPACECRAFT WITH SMALLEST NUMBER OF TIME STEPS TO USE AS REFERENCE SPACECRAFT
      omni_vars = tnames('mms?_epd_eis_'+data_rate+'_'+level+'_'+datatype+'_'+species[ss]+'_'+data_units+'_omni'+ suffix_ind[sp])
      ;
      if (omni_vars[0] eq '') then begin
        print, 'No EIS '+datatype+' data loaded!'
        return
      endif
      time_size = dblarr(n_elements(probes))
      energy_size = dblarr(n_elements(probes))
      for pp=0,n_elements(probes)-1 do begin
        get_data, omni_vars[pp], data=thisprobe_pad
        time_size[pp] = n_elements(thisprobe_pad.x)
        get_data,omni_vars[pp],data=thisprobe_flux
        energy_size[pp] = n_elements(thisprobe_flux.v)
      endfor
      ref_sc_time_size = min(time_size, reftime_sc_loc)
      prefix = 'mms'+probes[reftime_sc_loc]+'_epd_eis_'+data_rate+'_'+level+'_'+datatype+'_'
      get_data, omni_vars[reftime_sc_loc], data=time_refprobe
      ref_sc_energy_size = min(energy_size, refenergy_sc_loc)
      get_data, omni_vars[refenergy_sc_loc], data=energy_refprobe
      omni_spec_data = dblarr(n_elements(time_refprobe.x),n_elements(energy_refprobe.v),n_elements(probes)) + !Values.d_NAN       ; time x energy x spacecraft
      omni_spec = dblarr(n_elements(time_refprobe.x),n_elements(energy_refprobe.v)) + !Values.d_NAN                               ; time x energy
      energy_data = dblarr(n_elements(energy_refprobe.v),n_elements(probes))
      common_energy = dblarr(n_elements(energy_refprobe.v))  
      ;
      ; Average omni flux over all spacecraft and define common energy grid
      for pp=0,n_elements(omni_vars)-1 do begin
        get_data, omni_vars[pp], data=temp_data
        energy_data[*,pp] = temp_data.v[0:n_elements(common_energy)-1]
    ;    start_time_loc = where((temp_data.x ge time_refprobe.x[0]) and (temp_data.x le time_refprobe.x[1]))
    ;    omni_spec_data[0:ref_sc_time_size-1,*,pp] = temp_data.y[start_time_loc[0]:start_time_loc[0]+ref_sc_time_size-1,*]
        omni_spec_data[0:ref_sc_time_size-1,*,pp] = temp_data.y[0:ref_sc_time_size-1,0:n_elements(common_energy)-1]
      endfor
      for ee=0,n_elements(common_energy)-1 do common_energy[ee] = average(energy_data[ee,*],/NAN)
      ;
      ; Average omni flux over all spacecraft - sum for counts
      if data_units eq 'counts' then $
      for tt=0,n_elements(time_refprobe.x)-1 do for ee=0,n_elements(energy_refprobe.v)-1 do omni_spec[tt,ee] = total(omni_spec_data[tt,ee,*],/NAN) $
      else for tt=0,n_elements(time_refprobe.x)-1 do for ee=0,n_elements(energy_refprobe.v)-1 do omni_spec[tt,ee] = average(omni_spec_data[tt,ee,*],/NAN) 
      ;
      ; store new tplot variable
      omni_spec[where(finite(omni_spec) eq 0)] = 0d
      if suffix_ind[sp] eq '' then begin 
         store_data, allmms_prefix+species[ss]+'_'+data_units+'_omni', data={x:time_refprobe.x,y:omni_spec,v:energy_refprobe.v}
         options, allmms_prefix+species[ss]+'_'+data_units+'_omni', yrange = minmax(common_energy), ystyle=1, spec = 1, no_interp=1, ysubtitle='Energy [keV]', ztitle=ztitle_string, minzlog=.001, ylog = 1
         zlim, allmms_prefix+species[ss]+'_'+data_units+'_omni', 0, 0, 1
      endif else begin
         store_data, allmms_prefix+species[ss]+'_'+data_units+'_omni' + suffix_ind[sp], data={x:time_refprobe.x,y:omni_spec,v:energy_refprobe.v}, dlimits=flux_dl
         options, allmms_prefix+species[ss]+'_'+data_units+'_omni' + suffix_ind[sp], spec=1, minzlog = .01, ystyle=1, yrange = minmax(common_energy), ylog = 1
         zlim, allmms_prefix+species[ss]+'_'+data_units+'_omni' + suffix_ind[sp], 0,0,1
     endelse    
     if data_units eq 'counts' then $
        options, allmms_prefix+species[ss]+'_'+data_units+'_omni' + suffix_ind[sp], ztitle = 'counts', ytitle = 'mms'+probe_string+  '!C'+ species[ss] + '!Comni-spin', ysubtitle = 'Energy!C[keV]'
     

    endfor ; ss
    ;
  endfor ; sp
  ;
end