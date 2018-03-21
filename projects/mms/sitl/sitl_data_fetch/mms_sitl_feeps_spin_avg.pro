;+
;Procedure:
;     mms_feeps_spin_avg
;
;Purpose:
;     spin-averages FEEPS spectra using the '_spinsectnum' 
;       variable (variable containing spin sector #s associated 
;       with each measurement)
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-03-20 07:42:32 -0700 (Tue, 20 Mar 2018) $
;$LastChangedRevision: 24906 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/sitl_data_fetch/mms_sitl_feeps_spin_avg.pro $
;-
pro mms_sitl_feeps_spin_avg, probe=probe, data_units = data_units, datatype = datatype, $
  data_rate = data_rate, level = level, suffix = suffix, tplotnames = tplotnames
  
  if undefined(probe) then probe='1' else probe = strcompress(string(probe), /rem)
  if undefined(datatype) then datatype = 'electron'
  if undefined(data_units) then data_units = 'intensity'
  if undefined(suffix) then suffix=''
  if undefined(data_rate) then data_rate = 'srvy'
  
  lower_en = datatype eq 'electron' ? 71 : 78 ; keV

  prefix = 'mms'+probe+'_epd_feeps_'

  ; get the spin sectors
  ; v5.5+ = mms1_epd_feeps_srvy_l1b_electron_spinsectnum
  get_data, prefix + data_rate + '_' + level + '_' + datatype + '_spinsectnum'+suffix, data=spin_sectors
  
  if ~is_struct(spin_sectors) then begin
      dprint, dlevel = 0, 'Error, couldn''t find the tplot variable containing the spin sectors for calculating the spin averages.'
      return
  endif

  spin_starts = where(spin_sectors.Y[0:n_elements(spin_sectors.Y)-2] ge spin_sectors.Y[1:n_elements(spin_sectors.Y)-1])+1
 
  prefix = 'mms'+probe+'_epd_feeps_'
  ;var_name = prefix+datatype+'_'+data_units+'_omni'
  var_name = strcompress('mms'+probe+'_epd_feeps_'+data_rate+'_'+level+'_'+datatype+'_'+data_units+'_omni', /rem)

  get_data, var_name+suffix, data=flux_data, dlimits=flux_dl

  if ~is_struct(flux_data) || ~is_struct(flux_dl) then begin
    dprint, dlevel = 0, 'Error, no data or metadata for the variable: ' + var_name+suffix
    return
  endif

  spin_sum_flux = dblarr(n_elements(spin_starts), n_elements(flux_data.Y[0, *]))

  current_start = spin_starts[0]
  ; loop through the spins for this telescope
  for spin_idx = 1, n_elements(spin_starts)-1 do begin
    spin_sum_flux[spin_idx-1, *] = average(flux_data.Y[current_start:spin_starts[spin_idx], *], 1, /nan)

    current_start = spin_starts[spin_idx]+1
  endfor

  store_data,var_name+'_spin'+suffix, data={x: flux_data.X[spin_starts], y: spin_sum_flux, v: flux_data.V}, dlimits=flux_dl
  options, var_name+'_spin'+suffix, spec=1

  ylim, var_name+'_spin'+suffix, lower_en, 600., 1
  zlim, var_name+'_spin'+suffix, 0, 0, 1
  
  append_array, tplotnames, var_name+'_spin'+suffix

end