;+
; PROCEDURE:
;         mms_feeps_pad
;
; PURPOSE:
;         Calculate pitch angle distributions using data from the
;           MMS Fly's Eye Energetic Particle Sensor (FEEPS)
;
; KEYWORDS:
;         trange: time range of interest
;         probe: value for MMS SC #
;         datatype: 'electron' or 'ion'
;         energy: energy range to include in the calculation
;         bin_size: size of the pitch angle bins
;         num_smooth: should contain number of seconds to use when smoothing
;             only creates a smoothed product (_pad_smth) if this keyword is specified
;         angles_from_bfield: calculate the pitch angles from the B-field data instead of
;             reading from the CDFs
;
;
; EXAMPLES:
;         MMS> mms_load_feeps
;         MMS> mms_feeps_pad, energy=[70, 600]
;         MMS> tplot, '*70-600keV_pad'
;
;
; NOTES:
;     **** this routine requires IDL 8.0+ ****
;
; HISTORY:
;
;     Revision of mms_feeps_pad by Drew Turner
;
;     dturner, 26 Jan 2017, Modified mms_feeps_pad to produce results consistent with Drew's own PAD codes for FEEPS
;     egrimes, 27 Sep 2018, modified to use pitch angles from CDF files for burst mode data; added angles_from_bfield keyword for calculating PAs from the Bfield data
;                       
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-09-27 10:13:28 -0700 (Thu, 27 Sep 2018) $
;$LastChangedRevision: 25866 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_feeps_pad.pro $
;-

pro mms_feeps_pad, bin_size = bin_size, probe = probe, energy = energy, level = level, $
  suffix = suffix_in, datatype = datatype, data_units = data_units, data_rate = data_rate, $
  num_smooth = num_smooth, angles_from_bfield=angles_from_bfield
  
  if undefined(datatype) then datatype='electron' else datatype=strlowcase(datatype)
  if undefined(data_rate) then data_rate = 'srvy' else data_rate=strlowcase(data_rate)
  if undefined(probe) then probe = '1' else probe = strcompress(string(probe), /rem)
  if undefined(suffix_in) then suffix_in = ''
  prefix = 'mms'+strcompress(string(probe), /rem)
  if undefined(bin_size) then bin_size = 16.3636 ;deg
  if undefined(energy) then energy = [70,600]
  if undefined(data_units) then data_units = 'intensity'
  if undefined(level) then level = 'l2' else level = strlowcase(level)
  if undefined(num_smooth) then num_smooth = 1
  if data_units eq 'intensity' then out_units = '[#/cm!E2!N-s-sr-keV]'
  if data_units eq 'cps' || data_units eq 'count_rate' then out_units = '[counts/s]'
  if data_units eq 'counts' then out_units = '[counts]'
  
  ; Added by DLT on 26 Jun 2017:
  ; Account for angular response (finite field of view) of instruments
  ; elec can use +/-21.4 deg on each pitch angle as average response angle; ions can start with +/-10 deg, but both need to be further refined
  if datatype eq 'electron' then dAngResp = 21.4 ; [deg] 
  if datatype eq 'ion' then dAngResp = 10.0 ; [deg]


  if energy[0] lt 32.0 then begin
    dprint, dlevel = 0, 'Please select a starting energy of 32 keV or above'
    return
  endif

  ; set up the number of pa bins to create
  bin_size = float(bin_size)
  n_pabins = 180./bin_size
  pa_bins = 180.*indgen(n_pabins+1)/n_pabins
  pa_label = 180.*indgen(n_pabins)/n_pabins+bin_size/2.

  
  ; get the pitch angles
  if data_rate eq 'brst' && undefined(angles_from_bfield) then begin
    ; tdeflag, prefix+'_epd_feeps_pitch_angle'+suffix_in, 'linear', /overwrite
    ; v5.5+ = mms1_epd_feeps_srvy_l2_electron_pitch_angle
    get_data, prefix+'_epd_feeps_'+data_rate+'_'+level+'_'+datatype+'_pitch_angle'+suffix_in, data=pa_data, dlimits=pa_dlimits
  endif else begin
  ; temporary solution to issue with NaNs in the _pitch_angle variable
  ; calculate the pitch angles from the magnetic field data
    mms_feeps_pitch_angles, trange=trange, probe=probe, level=level, data_rate=data_rate, datatype=datatype, suffix=suffix_in, idx_maps=idx_maps
    get_data, prefix+'_epd_feeps_'+data_rate+'_'+level+'_'+datatype+'_pa'+suffix_in, data=pa_data, dlimits=pa_dlimits
  endelse

  if ~is_struct(pa_data) then begin
    dprint, dlevel = 0, 'Error, couldn''t find the PA variable: ' + prefix+'_epd_feeps_'+data_rate+'_'+level+'_'+datatype+'_pitch_angle'+suffix_in
    return
  endif

  eyes = mms_feeps_active_eyes(trange, probe, data_rate, datatype, level)
  
  pa_data_map = hash()
  if data_rate eq 'srvy' then begin
    ; From Allison Jaynes @ LASP: The 6,7,8 sensors (out of 12) are ions,
    ; so in the pitch angle array, the 5,6,7 columns (counting from zero) will be the ion pitch angles.
    ; for electrons:
    if datatype eq 'electron' then pa_data_map['top-electron'] = (idx_maps[0])['electron-top']
    if datatype eq 'electron' then pa_data_map['bottom-electron'] = (idx_maps[1])['electron-bottom']
    ; and ions:
    if datatype eq 'ion' then pa_data_map['top-ion'] = (idx_maps[0])['ion-top']
    if datatype eq 'ion' then pa_data_map['bottom-ion'] = (idx_maps[1])['ion-bottom']

    ; these should match n-1, where n is the telescope # in the variable names
   ; particle_idxs = datatype eq 'electron' ? [2, 3, 4, 10, 11] : [5, 6, 7]
  endif else if data_rate eq 'brst' then begin
    ; note: the following are indices of the top/bottom sensors in pa_data
    ; they should be consistent with pa_dlimits.labels
    pa_data_map['top-electron'] = [0, 1, 2, 3, 4, 5, 6, 7, 8]
    pa_data_map['bottom-electron'] = [9, 10, 11, 12, 13, 14, 15, 16, 17]
    ; and ions:
    pa_data_map['top-ion'] = [0, 1, 2]
    pa_data_map['bottom-ion'] = [3, 4, 5]

    ; these should match n-1, where n is the telescope # in the variable names
  ;  particle_idxs = datatype eq 'electron' ? [0, 1, 2, 3, 4, 8, 9, 10, 11] : [5, 6, 7]
  endif

  sensor_types = ['top', 'bottom']
  
  ; Load data in appropriate format:
  ; First, initialize arrays for flux (dflux) and pitch angles (dpa) compiled from all sensors:
  if datatype eq 'electron' then dflux = fltarr(n_elements(pa_data.x), (n_elements(pa_data_map['top-electron'])+n_elements(pa_data_map['bottom-electron'])))
  if datatype eq 'ion' then dflux = fltarr(n_elements(pa_data.x), (n_elements(pa_data_map['top-ion'])+n_elements(pa_data_map['bottom-ion'])))
  dpa = dflux
  for s_type_idx = 0, n_elements(sensor_types)-1 do begin ; loop through top and bottom
    s_type = sensor_types[s_type_idx]
    pa_map = pa_data_map[s_type+'-'+datatype]
    particle_idxs = eyes[s_type]-1

    for isen=0, n_elements(particle_idxs)-1 do begin ; loop through sensors
      ; get data
      var_name = strcompress('mms'+probe+'_epd_feeps_'+data_rate+'_'+level+'_'+datatype+'_'+s_type+'_'+data_units+'_sensorid_'+strcompress(string(particle_idxs[isen]+1), /rem)+'_clean_sun_removed'+suffix_in, /rem)
      get_data, var_name, data = d
      d.y[where(d.y eq 0.0)] = !values.d_nan ; remove any 0s before averaging
      ; store data in dflux and dpa
      ; Energy indices to use:
      indx = where((d.v le energy[1]) and (d.v ge energy[0]), energy_count)
      if energy_count eq 0 then begin
        dprint, dlevel = 0, 'Energy range selected is not covered by the detector for FEEPS ' + datatype + ' data'
        continue
      endif
      dflux[*, pa_map[isen]] = reform(average(d.y[*,indx],2,/NAN)) 
      dpa[*, pa_map[isen]] = reform(pa_data.y[*, pa_map[isen]])   
    endfor
  endfor
  
  ; we need to replace the 0.0s left in after populating dpa with NaNs; these 
  ; 0.0s are left in there because these points aren't covered by sensors loaded
  ; for this datatype/data_rate
  dpa[where(dpa eq 0.0)] = !values.d_nan ; fill any missed bins with NAN

  pa_flux = fltarr(n_elements(pa_data.x), n_pabins)
  delta_pa = (pa_bins[1]-pa_bins[0])/2.0
  
  ; Now loop through PA bins and time, find the telescopes where there is data in those bins and average it up!
  for it = 0l, n_elements(dpa[*,0])-1 do begin
    for ipa = 0, n_pabins-1 do begin
      ind = where((dpa[it,*] + dAngResp ge pa_label[ipa]-delta_pa) and (dpa[it,*] - dAngResp lt pa_label[ipa]+delta_pa))  ; edited by DLT on 26 Jun 2017
      if ind[0] ne -1 then pa_flux[it, ipa] = reform(average(dflux[it, ind], 2, /NAN))
    endfor
  endfor
  pa_flux[where(pa_flux eq 0.0)] = !values.d_nan ; fill any missed bins with NAN
  
  ; feeps_bin_info, pa_bins, new_pa_flux, pa_num_in_bin, particle_pa, flux_file, 0

  en_range_string = strcompress(string(fix(energy[0])), /rem) + '-' + strcompress(string(fix(energy[1])), /rem) + 'keV'
  ;new_name = 'mms'+probe+'_epd_feeps_' + datatype + '_' + en_range_string + '_pad'+suffix_in
  new_name = strcompress('mms'+probe+'_epd_feeps_'+data_rate+'_'+level+'_'+datatype+'_'+data_units+'_'+ en_range_string +'_pad'+suffix_in, /rem)

  store_data, new_name, data={x:pa_data.x, y:pa_flux, v:pa_label}

  options, new_name, yrange = [0,180], ystyle=1, spec = 1, no_interp=1, minzlog = 0.01, $
    zlog = 1, ytitle = 'MMS'+probe+'!CFEEPS ' + datatype, ysubtitle=en_range_string+'!CPA [Deg]', ztitle=out_units
  options, new_name, 'extend_y_edges', 1
  
  ; calculate the smoothed pad
  if ~undefined(num_smooth) then spd_smooth_time, new_name, newname=new_name+'_smth', num_smooth, /nan
    
  ; calculate the spin averages
  mms_feeps_pad_spinavg, probe=probe, datatype=datatype, energy=energy, bin_size=bin_size, data_units=data_units, $
    suffix = suffix_in, data_rate = data_rate, level = level


end ; pro