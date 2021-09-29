;+
; PROCEDURE:
;         mms_eis_pad_combine_sc
;
; PURPOSE: Generate composite pitch angle distributions from the EIS sensors across the MMS spacecraft
;       
; CAVEAT: This procedure does not work across HV turnoffs during periods of time when the EIS instruments
;         had varying HV turnoff locations/times (prior to Phase 2b)
;
; KEYWORDS:
;         probes:               value for MMS SC #
;         trange:               time range of interest
;         species:              proton (default), helium (formerly alpha), oxygen, electron
;         level:                data level ['l1a','l1b','l2pre','l2' (default)] 
;         data_rate:            instrument data rates ['brst', 'srvy' (default), 'fast', 'slow']
;         energy:               energy range to include in the calculation
;         datatype:             extof (default), phxtof, electronenergy
;         suffix:               suffix used when loading the data
;         combine_proton_data:  set equal to 1 to combine extof and phxtof proton data
;
; CREATED BY: I. Cohen, 2017-08-14
;
; REVISION HISTORY:
;       + 2017-11-14, I. Cohen    : removed num_smooth keyword and calls to spd_smooth_time
;       + 2017-11-15, I. Cohen    : removed n_pad_spec and num_smooth keywords; added energy, data_units, datatype, and species keywords to mirror call to mms_eis_pad.pro
;       + 2017-11-17, I. Cohen    : removed combination of phxtof and extof data to rely on use of mms_eis_pad.pro and mms_eis_pad_combine_proton_pad.pro;
;                                   replaced species keyword definition with species and removed species
;       + 2018-01-04, I. Cohen    : fixed if statement for species case of 'proton'
;       + 2018-02-05, I. Cohen    : added suffix keyword
;       + 2018-02-19, I. Cohen    : added ability to handle multiple species 
;       + 2018-03-20, I. Cohen    : added combine_proton_data keyword
;       + 2018-06-14, I. Cohen    : changed so that if 'combine_proton_data' is set, then only 'combined' data is handled
;       + 2019-11-21, I. Cohen    : changed new variable prefix to 'mmsx' instead of 'mms#-#'
;       + 2020-06-16, I. Cohen    : removed probes keyword, added ability to automatically define probes based on loaded EIS data like mms_eis_spec_combine_sc.pro;
;                                   change format of energy ranges in thissc_pad_vars definition
;       + 2020-10-26, I. Cohen    : added/edited lines from mms_eis_spec_combine_sc.pro to create spin-averaged variables
;       + 2020-11-02, R. Nikoukar : changed 'mmsx' to 'mms#-#' for consistency with mms_eis_spec_combine_sc.pro; corrected time indexing for spin-averaged variables
;       + 2020-12-14, I. Cohen    : changed "not KEYWORD_SET" to "undefined" in initialization of some keywords; 
;                                   added "datarate_str" to handle issue with probes definition if both burst and survey data are loaded
;       + 2021-01-06, I. Cohen    : added wildcard into string in definition of eis_sc_check for phxtof data
;       + 2021-02-09, I. Cohen    : added helium to species in header under KEYWORD section and added default datatype if species=helium
;       + 2021-04-08, I. Cohen    : updated allmms_prefix definition to handle new L2 variable names
;       + 2021-06-16, I. Cohen    : fixed error in definition of allmms_pad_vars and thissc_pad_vars 
;       + 2021-06-17, I. Cohen    : fixed error in definition of prefix
;       + 2021-07-09, I. Cohen    : fupdated definition of prefix to handle 'combined' datatype
;
;-
pro mms_eis_pad_combine_sc, trange = trange, species = species, level = level, data_rate = data_rate, $
                energy = energy, data_units = data_units, datatype = datatype, suffix = suffix, combine_proton_data = combine_proton_data
  ;
  compile_opt idl2
  if undefined(data_rate) then data_rate = 'srvy' else data_rate = strlowcase(data_rate)
  if (data_rate eq 'brst') then  datarate_str = 'brst_' else datarate_str = ''
  if undefined(scopes) then scopes = ['0','1','2','3','4','5']
  if undefined(level) then level = 'l2'
  if undefined(energy) then energy = [55,800]
  if undefined(data_units) then data_units = 'flux'
  if undefined(species) then species = 'proton'
  if undefined(suffix) then suffix = ''
  if undefined(combine_proton_data) then combine_proton_data = 0
  if undefined(datatype) then begin
    case species of
      'proton':   if (energy[0] gt 50) and (energy[1] gt 50) then datatype = 'extof' $
                  else if (energy[0] lt 50) and (energy[1] lt 50) then datatype = 'phxtof' $
                  else begin
                    if (combine_proton_data eq 1) then datatype = 'combined' else datatype = ['phxtof','extof']
                  endelse
      'alpha':    datatype = 'extof'
      'helium':   datatype = 'extof'
      'oxygen':   datatype = 'extof'
      'electron': datatype = 'electronenergy'
    endcase
  endif

  eis_sc_check = tnames('mms*eis*'+datatype[0]+'*'+species+'*flux*omni')
  probes = strmid(eis_sc_check, 3, 1)
  if (n_elements(probes) gt 4) then probes = probes[0:-2]
  ;
  ; Combine flux from all MMS spacecraft into omni-directional array
  allmms_prefix = 'mmsx_epd_eis_'+data_rate+'_'+level+'_'
  ;
  for dd=0,n_elements(datatype)-1 do begin
    ;
    ; Determine spacecraft with smallest number of time steps to use as reference spacecraft
    allmms_pad_vars = tnames('mms*_epd_eis_'+data_rate+'_'+level+'_'+datatype[dd]+'_'+species+'*pads')
    if (n_elements(allmms_pad_vars) ne n_elements(probes)) then begin
      print, 'EIS data from one or more EIS instruments is missing'
      probes = probes[where(probes eq strmid(allmms_pad_vars,3,1))]
    endif
    time_size = dblarr(n_elements(probes))
    for pp=0,n_elements(probes)-1 do begin
      get_data, allmms_pad_vars[pp], data=thisprobe_pad
      time_size[pp] = n_elements(thisprobe_pad.x)
    endfor
    ref_sc_time_size = min(time_size, ref_sc_loc)
    ;
    ; Define common energy grid across EIS instruments
    get_data, allmms_pad_vars[ref_sc_loc], data=temp_refprobe
    n_energy_chans = dblarr(n_elements(probes))
    for pp=0,n_elements(probes)-1 do begin
      get_data, allmms_pad_vars[pp], data=thisprobe_pad
      n_energy_chans[pp] = n_elements(thisprobe_pad.v2) 
    endfor
    size_energy = min(n_energy_chans,loc_ref_energy)
    energy_data = dblarr(size_energy,n_elements(probes))
    common_energy = dblarr(size_energy)
    for pp=0,n_elements(probes)-1 do begin
      get_data, allmms_pad_vars[pp], data=thisprobe_pad
      energy_data[*,pp] = thisprobe_pad.v2[0:size_energy-1]
    endfor
    for ee=0,n_elements(common_energy)-1 do common_energy[ee] = average(energy_data[ee,*],/NAN)
    ;
    ; create PA labels
    n_pabins = n_elements(temp_refprobe.v1)
    size_pabin = 180d / n_pabins
    pa_label = 180d*indgen(n_pabins)/n_pabins+size_pabin/2.
    ;
    allmms_pad_thisenergy = dblarr(n_elements(temp_refprobe.x),n_elements(temp_refprobe.v1),n_elements(common_energy),n_elements(probes))                       ; time x bins x energy x spacecraft
    allmms_pad_energy_avg = dblarr(n_elements(temp_refprobe.x),n_elements(temp_refprobe.v1),n_elements(common_energy))                                          ; time x bins x energy
    allmms_pad_avg = dblarr(n_elements(temp_refprobe.x),n_elements(temp_refprobe.v1))                                                                           ; time x bins
    ;
    for pp=0,n_elements(probes)-1 do begin                                                                                                                      ; loop through telescopes
      thissc_pad_vars = tnames(['mms'+probes[pp]+'_epd_eis_'+data_rate+'_'+level+'_'+datatype[dd]+'_*keV_'+species+'_'+data_units+'_omni'+suffix+'_pad'])
      ;
      for ee=0,n_elements(common_energy)-1 do begin
         get_data,thissc_pad_vars[ee],data=temp_data_pad
  ;       start_time_loc = where((temp_data_pad.x ge temp_refprobe.x[0]) and (temp_data_pad.x le temp_refprobe.x[1]))
         allmms_pad_thisenergy[*,*,ee,pp] = temp_data_pad.y[0:n_elements(temp_refprobe.x)-1,*]
      endfor    
    endfor
    ;
    ; SET UP FOR SPIN-AVERAGING
    ;
    IF (datatype[dd] EQ 'combined') THEN prefix = 'mms'+probes[ref_sc_loc]+'_epd_eis_'+data_rate+'_'+level+'_extof_' ELSE prefix = 'mms'+probes[ref_sc_loc]+'_epd_eis_'+data_rate+'_'+level+'_'+datatype[dd]+'_'
    get_data, prefix + 'spin' + suffix, data=spin_nums
    if ~is_struct(spin_nums) then begin
      print, 'ERROR: COULD NOT FIND EIS SPIN VARIABLE -- NOW ENDING PROCEDURE'
      return ; gracefully handle the case of no spin # variable found
    endif
    ;
    ; find where the spins start
    spin_starts = uniq(spin_nums.Y)
    sp = '_spin'
    ;
    ; LOOP THROUGH INDIVIDUAL ENERGY CHANNELS
    for ee=0,n_elements(common_energy)-1 do begin
      ;
      for tt=0,n_elements(temp_refprobe.x)-1 do for bb=0,n_elements(temp_refprobe.v1)-1 do allmms_pad_energy_avg[tt,bb,ee] = average(allmms_pad_thisenergy[tt,bb,ee,*],/NAN)
      ;
  ;    allmms_pad_energy_avg[where(allmms_pad_energy_avg eq 0)] = !Values.d_NAN
      store_data, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[ee])),2)+'keV_'+species+'_'+data_units+'_omni'+suffix+'_pad', data={x:temp_refprobe.x,y:reform(allmms_pad_energy_avg[*,*,ee]),v:pa_label}
      options, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[ee])),2)+'keV_'+species+'_'+data_units+'_omni'+suffix+'_pad', yrange = [0,180], ystyle=1, spec = 1, no_interp=1, $
        ysubtitle='PA [Deg]',ztitle='Intensity!C[1/cm!U-2!N-sr-s-keV]',minzlog=.001
      if data_units eq 'flux' then zlim, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[ee])),2)+'keV_'+species+'_'+data_units+'_omni'+suffix+'_pad', 5e2, 1e4, 1
      tdegap, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[ee])),2)+'keV_'+species+'_'+data_units+'_omni'+suffix+'_pad', /overwrite
      ;
      ; spin-average
      spin_avg_pad_energy = dblarr(n_elements(spin_starts), n_elements(temp_refprobe.v1))
      current_start = 0
      ; loop through the spins for this telescope
      for spin_idx = 0,n_elements(spin_starts)-1 do begin
        ; loop over bins
        for bb=0,n_elements(temp_refprobe.v1)-1 do spin_avg_pad_energy[spin_idx, bb] = average(allmms_pad_energy_avg[current_start:spin_starts[spin_idx], bb, ee], 1, /NAN)
        current_start = spin_starts[spin_idx]+1
      endfor
      ;
      store_data, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[ee])),2)+'keV_'+species+'_'+data_units+'_omni'+suffix+'_pad'+sp, data={x:temp_refprobe.x[spin_starts],y:spin_avg_pad_energy,v:pa_label}
      options, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[ee])),2)+'keV_'+species+'_'+data_units+'_omni'+suffix+'_pad'+sp, yrange = [0,180], ystyle=1, spec = 1, no_interp=1, $
        ysubtitle='PA [Deg]',ztitle='Intensity!C[1/cm!U-2!N-sr-s-keV]',minzlog=.001
      if data_units eq 'flux' then zlim, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[ee])),2)+'keV_'+species+'_'+data_units+'_omni'+suffix+'_pad'+sp, 5e2, 1e4, 1
      tdegap, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[ee])),2)+'keV_'+species+'_'+data_units+'_omni'+suffix+'_pad'+sp, /overwrite
    endfor
    ;
    store_data,allmms_prefix+datatype[dd]+'_'+species+'_'+data_units+'_omni'+suffix+'_pads',data={x:temp_refprobe.x,y:allmms_pad_energy_avg,v1:pa_label,v2:common_energy}
    tdegap,allmms_prefix+datatype[dd]+'_'+species+'_'+data_units+'_omni'+suffix+'_pads',/overwrite
    ;
  ;  allmms_pad_energy_avg[where(allmms_pad_energy_avg eq 0)] = !Values.d_NAN
    for tt=0,n_elements(temp_refprobe.x)-1 do for bb=0,n_elements(temp_refprobe.v1)-1 do allmms_pad_avg[tt,bb] = average(allmms_pad_energy_avg[tt,bb,*],/NAN)
    store_data, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[0])),2)+'-'+strtrim(string(fix(common_energy[-1])),2)+'keV_'+species+'_'+data_units+'_omni'+suffix+'_pad', data={x:temp_refprobe.x,y:allmms_pad_avg,v:pa_label}
    options, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[0])),2)+'-'+strtrim(string(fix(common_energy[-1])),2)+'keV_'+species+'_'+data_units+'_omni'+suffix+'_pad', yrange = [0,180], ystyle=1, spec = 1, no_interp=1, $
      ysubtitle='PA [Deg]',ztitle='Intensity!C[1/cm!U-2!N-sr-s-keV]',minzlog=.001, /extend_y_edges
    if data_units eq 'flux' then zlim, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[0])),2)+'-'+strtrim(string(fix(common_energy[-1])),2)+'keV_'+species+'_'+data_units+'_omni'+suffix+'_pad', 5e2, 1e4, 1
    tdegap, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[0])),2)+'-'+strtrim(string(fix(common_energy[-1])),2)+'keV_'+species+'_'+data_units+'_omni'+suffix+'_pad', /overwrite
    ;
    spd_smooth_time, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[0])),2)+'-'+strtrim(string(fix(common_energy[-1])),2)+'keV_'+species+'_'+data_units+'_omni'+suffix+'_pad', $
      newname=allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[0])),2)+'-'+strtrim(string(fix(common_energy[-1])),2)+'keV_'+species+'_'+data_units+'_omni'+suffix+'_pad_smth', 20, /nan
    ;
    spin_avg_pad = dblarr(n_elements(spin_starts), n_elements(allmms_pad_avg[0, *]))
    ;
    current_start = 0
    ; loop through the spins for this telescope
    for spin_idx = 0, n_elements(spin_starts)-1 do begin
      ; loop over energies
      spin_avg_pad[spin_idx, *] = average(allmms_pad_avg[current_start:spin_starts[spin_idx], *], 1, /NAN)
      current_start = spin_starts[spin_idx]+1
    endfor
    ;
    store_data, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[0])),2)+'-'+strtrim(string(fix(common_energy[-1])),2)+'keV_'+species+'_'+data_units+'_omni'+suffix+'_pad'+sp, data={x:temp_refprobe.x,y:spin_avg_pad,v:pa_label}
    options, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[0])),2)+'-'+strtrim(string(fix(common_energy[-1])),2)+'keV_'+species+'_'+data_units+'_omni'+suffix+'_pad'+sp, yrange = [0,180], ystyle=1, spec = 1, no_interp=1, $
      ysubtitle='PA [Deg]',ztitle='Intensity!C[1/cm!U-2!N-sr-s-keV]',minzlog=.001, /extend_y_edges
    if data_units eq 'flux' then zlim, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[0])),2)+'-'+strtrim(string(fix(common_energy[-1])),2)+'keV_'+species+'_'+data_units+'_omni'+suffix+'_pad'+sp, 5e2, 1e4, 1
    tdegap, allmms_prefix+datatype[dd]+'_'+strtrim(string(fix(common_energy[0])),2)+'-'+strtrim(string(fix(common_energy[-1])),2)+'keV_'+species+'_'+data_units+'_omni'+suffix+'_pad'+sp, /overwrite
    ;
  endfor
  ;
end