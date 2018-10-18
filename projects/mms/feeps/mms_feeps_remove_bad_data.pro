;+
; PROCEDURE:
;       mms_feeps_remove_bad_data
;
; PURPOSE:
;       Removes bad eyes, bad lowest energy channels 
;       based on data from Drew Turner, 1/26/2017
;
; NOTES:
; 
;     Updated to use time varying bad eye tables and changed bottom channels that we NaN out from Drew Turner, egrimes, 8Oct2018
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-10-08 17:44:24 -0700 (Mon, 08 Oct 2018) $
; $LastChangedRevision: 25934 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_feeps_remove_bad_data.pro $
;-

pro mms_feeps_remove_bad_data, probe=probe, data_rate=data_rate, datatype=datatype, level=level, suffix = suffix, trange=trange
  if undefined(suffix) then suffix = ''
  if undefined(level) then level = 'l2'
  if undefined(probe) then probe = '1'
  if undefined(data_rate) then data_rate = 'srvy'
  if undefined(datatype) then datatype = 'electron'
  
  data_rate_level = data_rate + '_' + level
    
  ; electrons first, remove bad eyes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 1. BAD EYES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  First, here is a list of the EYES that are bad, we need to make sure these 
;  data are not usable (i.e., make all of the counts/rate/flux data from these eyes NAN). 
;  These are for all modes, burst and survey:

  bad_data_table = hash()
  
  ; Oct 2017
  bad_data_table['2017-10-01'] = hash()
  (bad_data_table['2017-10-01'])['mms1'] = hash('top', [1], 'bottom', [1, 11])
  (bad_data_table['2017-10-01'])['mms2'] = hash('top', [5, 7, 12], 'bottom', [7])
  (bad_data_table['2017-10-01'])['mms3'] = hash('top', [2, 12], 'bottom', [2, 5, 11])
  (bad_data_table['2017-10-01'])['mms4'] = hash('top', [1, 2, 7], 'bottom', [2, 4, 5, 10, 11])
  
  ; Oct 2018
  bad_data_table['2018-10-01'] = hash()
  (bad_data_table['2018-10-01'])['mms1'] = hash('top', [1], 'bottom', [1, 11])
  (bad_data_table['2018-10-01'])['mms2'] = hash('top', [7, 12], 'bottom', [2, 12])
  (bad_data_table['2018-10-01'])['mms3'] = hash('top', [1, 2], 'bottom', [5, 11])
  (bad_data_table['2018-10-01'])['mms4'] = hash('top', [1, 7], 'bottom', [4, 11])
  
  ; note: add more dates here
  
  closest_table_tm = find_nearest_neighbor(time_double((bad_data_table.Keys()).toArray()), time_double(trange[0]), /allow_outside)
  closest_table = time_string(closest_table_tm, tformat='YYYY-MM-DD')
  bad_data = (bad_data_table[closest_table])['mms'+strcompress(string(probe), /rem)]
  
  dprint, dlevel=2, 'Removing bad eyes using table from ' + closest_table
  
  ; top electrons
  for bad_idx=0, n_elements(bad_data['top'])-1 do begin
    if array_contains([6, 7, 8], (bad_data['top'])[bad_idx]) then continue ; ion eyes
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_electron_top_count_rate_sensorid_'+strcompress(string((bad_data['top'])[bad_idx]), /rem)+suffix)
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_electron_top_intensity_sensorid_'+strcompress(string((bad_data['top'])[bad_idx]), /rem)+suffix)
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_electron_top_counts_sensorid_'+strcompress(string((bad_data['top'])[bad_idx]), /rem)+suffix)
  endfor
  
  ; bottom electrons
  for bad_idx=0, n_elements(bad_data['bottom'])-1 do begin
    if array_contains([6, 7, 8], (bad_data['bottom'])[bad_idx]) then continue ; ion eyes
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_electron_bottom_count_rate_sensorid_'+strcompress(string((bad_data['bottom'])[bad_idx]), /rem)+suffix)
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_electron_bottom_intensity_sensorid_'+strcompress(string((bad_data['bottom'])[bad_idx]), /rem)+suffix)
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_electron_bottom_counts_sensorid_'+strcompress(string((bad_data['bottom'])[bad_idx]), /rem)+suffix)
  endfor
  
  ; top ions
  for bad_idx=0, n_elements(bad_data['top'])-1 do begin
    if ~array_contains([6, 7, 8], (bad_data['top'])[bad_idx]) then continue ; ion eyes
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_ion_top_count_rate_sensorid_'+strcompress(string((bad_data['top'])[bad_idx]), /rem)+suffix)
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_ion_top_intensity_sensorid_'+strcompress(string((bad_data['top'])[bad_idx]), /rem)+suffix)
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_ion_top_counts_sensorid_'+strcompress(string((bad_data['top'])[bad_idx]), /rem)+suffix)
  endfor
  
  ; bottom ions
  for bad_idx=0, n_elements(bad_data['bottom'])-1 do begin
    if ~array_contains([6, 7, 8], (bad_data['bottom'])[bad_idx]) then continue ; ion eyes
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_ion_bottom_count_rate_sensorid_'+strcompress(string((bad_data['bottom'])[bad_idx]), /rem)+suffix)
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_ion_bottom_intensity_sensorid_'+strcompress(string((bad_data['bottom'])[bad_idx]), /rem)+suffix)
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_ion_bottom_counts_sensorid_'+strcompress(string((bad_data['bottom'])[bad_idx]), /rem)+suffix)
  endfor

  for var_idx=0, n_elements(vars)-1 do begin
    get_data, vars[var_idx], data=bad, dlimits=dl, limits=l
    if is_struct(bad) then begin
      bad.Y[*] = !values.d_nan
      store_data, vars[var_idx], data=bad, dlimits=dl, limits=l
    endif
  endfor
  
  undefine, vars
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 2. BAD LOWEST E-CHANNELS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Next, these eyes have bad first channels (i.e., lowest energy channel, E-channel 0 in IDL indexing).  
; Again, these data (just the counts/rate/flux from the lowest energy channel ONLY!!!) 
; should be hardwired to be NAN for all modes (burst and both types of survey).  
; The eyes not listed here or above are ok though... so once we do this, we can actually start 
; showing the data down to the lowest levels (~33 keV), meaning we'll have to adjust the hard-coded 
; ylim settings in SPEDAS and the SITL software:

; from Drew Turner, 5Oct18:
;Bad Channels (0 and 1):
;Update: All channels 0 (Ch0) on MMS-2, -3, and -4 electron eyes (1, 2, 3, 4, 5, 9, 10, 11, 12) should be NaN
;Additionally, the second channels (Ch1) on the following should also be made NaN:
;MMS-1: Top: Ch0 on Eyes 6, 7
;Bot: Ch0 on Eyes 6, 7, 8
;MMS-2: Top:
;Bot: Ch0 on Eyes 6, 8
;MMS-3: Top: Ch0 on Eye 8
;Bot: Ch0 on Eyes 6, 7
;MMS-4: Top: Ch1 on Eye 1; Ch0 on Eye 8
;Bot: Ch0 on Eyes 6, 7, 8; Ch1 on Eye 9

  bad_ch0 = hash()
  bad_ch0['mms1'] = hash('top', [2, 5, 6, 7], 'bottom', [2, 3, 4, 5, 6, 7, 8, 9, 11, 12])
  bad_ch0['mms2'] = hash('top', [1, 2, 3, 4, 5, 9, 10, 11, 12], 'bottom', [1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12])
  bad_ch0['mms3'] = hash('top', [1, 2, 3, 4, 5, 8, 9, 10, 11, 12], 'bottom', [1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12])
  bad_ch0['mms4'] = hash('top', [1, 2, 3, 4, 5, 8, 9, 10, 11, 12], 'bottom', [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
  
  bad_ch1 = hash()
  bad_ch1['mms1'] = hash('top', [], 'bottom', [11])
  bad_ch1['mms2'] = hash('top', [8], 'bottom', [12])
  bad_ch1['mms3'] = hash('top', [1], 'bottom', [])
  bad_ch1['mms4'] = hash('top', [1], 'bottom', [6, 9])
  
  bad_ch0 = bad_ch0['mms'+strcompress(string(probe), /rem)]
  bad_ch1 = bad_ch1['mms'+strcompress(string(probe), /rem)]

  ;;;;;;;;;;;;;;;; bottom channel
  ; top electrons
  for bad_idx=0, n_elements(bad_ch0['top'])-1 do begin
    if array_contains([6, 7, 8], (bad_ch0['top'])[bad_idx]) then continue ; ion eyes
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_electron_top_count_rate_sensorid_'+strcompress(string((bad_ch0['top'])[bad_idx]), /rem)+suffix)
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_electron_top_intensity_sensorid_'+strcompress(string((bad_ch0['top'])[bad_idx]), /rem)+suffix)
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_electron_top_counts_sensorid_'+strcompress(string((bad_ch0['top'])[bad_idx]), /rem)+suffix)
  endfor

  ; bottom electrons
  for bad_idx=0, n_elements(bad_ch0['bottom'])-1 do begin
    if array_contains([6, 7, 8], (bad_ch0['bottom'])[bad_idx]) then continue ; ion eyes
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_electron_bottom_count_rate_sensorid_'+strcompress(string((bad_ch0['bottom'])[bad_idx]), /rem)+suffix)
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_electron_bottom_intensity_sensorid_'+strcompress(string((bad_ch0['bottom'])[bad_idx]), /rem)+suffix)
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_electron_bottom_counts_sensorid_'+strcompress(string((bad_ch0['bottom'])[bad_idx]), /rem)+suffix)
  endfor

  ; top ions
  for bad_idx=0, n_elements(bad_ch0['top'])-1 do begin
    if ~array_contains([6, 7, 8], (bad_ch0['top'])[bad_idx]) then continue ; ion eyes
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_ion_top_count_rate_sensorid_'+strcompress(string((bad_ch0['top'])[bad_idx]), /rem)+suffix)
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_ion_top_intensity_sensorid_'+strcompress(string((bad_ch0['top'])[bad_idx]), /rem)+suffix)
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_ion_top_counts_sensorid_'+strcompress(string((bad_ch0['top'])[bad_idx]), /rem)+suffix)
  endfor

  ; bottom ions
  for bad_idx=0, n_elements(bad_ch0['bottom'])-1 do begin
    if ~array_contains([6, 7, 8], (bad_ch0['bottom'])[bad_idx]) then continue ; ion eyes
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_ion_bottom_count_rate_sensorid_'+strcompress(string((bad_ch0['bottom'])[bad_idx]), /rem)+suffix)
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_ion_bottom_intensity_sensorid_'+strcompress(string((bad_ch0['bottom'])[bad_idx]), /rem)+suffix)
    append_array, vars, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_ion_bottom_counts_sensorid_'+strcompress(string((bad_ch0['bottom'])[bad_idx]), /rem)+suffix)
  endfor

 ;;;;;;;;;;;;;;;; bottom 2 channels
  ; top electrons
  for bad_idx=0, n_elements(bad_ch1['top'])-1 do begin
    if array_contains([6, 7, 8], (bad_ch1['top'])[bad_idx]) then continue ; ion eyes
    append_array, vars_bothchans, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_electron_top_count_rate_sensorid_'+strcompress(string((bad_ch1['top'])[bad_idx]), /rem)+suffix)
    append_array, vars_bothchans, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_electron_top_intensity_sensorid_'+strcompress(string((bad_ch1['top'])[bad_idx]), /rem)+suffix)
    append_array, vars_bothchans, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_electron_top_counts_sensorid_'+strcompress(string((bad_ch1['top'])[bad_idx]), /rem)+suffix)
  endfor

  ; bottom electrons
  for bad_idx=0, n_elements(bad_ch1['bottom'])-1 do begin
    if array_contains([6, 7, 8], (bad_ch1['bottom'])[bad_idx]) then continue ; ion eyes
    append_array, vars_bothchans, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_electron_bottom_count_rate_sensorid_'+strcompress(string((bad_ch1['bottom'])[bad_idx]), /rem)+suffix)
    append_array, vars_bothchans, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_electron_bottom_intensity_sensorid_'+strcompress(string((bad_ch1['bottom'])[bad_idx]), /rem)+suffix)
    append_array, vars_bothchans, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_electron_bottom_counts_sensorid_'+strcompress(string((bad_ch1['bottom'])[bad_idx]), /rem)+suffix)
  endfor

  ; top ions
  for bad_idx=0, n_elements(bad_ch1['top'])-1 do begin
    if ~array_contains([6, 7, 8], (bad_ch1['top'])[bad_idx]) then continue ; ion eyes
    append_array, vars_bothchans, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_ion_top_count_rate_sensorid_'+strcompress(string((bad_ch1['top'])[bad_idx]), /rem)+suffix)
    append_array, vars_bothchans, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_ion_top_intensity_sensorid_'+strcompress(string((bad_ch1['top'])[bad_idx]), /rem)+suffix)
    append_array, vars_bothchans, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_ion_top_counts_sensorid_'+strcompress(string((bad_ch1['top'])[bad_idx]), /rem)+suffix)
  endfor

  ; bottom ions
  for bad_idx=0, n_elements(bad_ch1['bottom'])-1 do begin
    if ~array_contains([6, 7, 8], (bad_ch1['bottom'])[bad_idx]) then continue ; ion eyes
    append_array, vars_bothchans, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_ion_bottom_count_rate_sensorid_'+strcompress(string((bad_ch1['bottom'])[bad_idx]), /rem)+suffix)
    append_array, vars_bothchans, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_ion_bottom_intensity_sensorid_'+strcompress(string((bad_ch1['bottom'])[bad_idx]), /rem)+suffix)
    append_array, vars_bothchans, tnames('mms'+strcompress(string(probe), /rem)+'_epd_feeps_'+data_rate_level+'_ion_bottom_counts_sensorid_'+strcompress(string((bad_ch1['bottom'])[bad_idx]), /rem)+suffix)
  endfor

  ; the following sets the first energy channel to NaN
  for var_idx=0, n_elements(vars)-1 do begin
    get_data, vars[var_idx], data=bad, dlimits=dl, limits=l
    if is_struct(bad) then begin
      bad.Y[*, 0] = !values.d_nan ; remove the first energy channel
      store_data, vars[var_idx], data=bad, dlimits=dl, limits=l
    endif
  endfor
  
  ; the following sets the first and second energy channels to NaNs
  for var_idx=0, n_elements(vars_bothchans)-1 do begin
    get_data, vars_bothchans[var_idx], data=bad, dlimits=dl, limits=l
    if is_struct(bad) then begin
      bad.Y[*, 0] = !values.d_nan ; remove the first energy channel
      bad.Y[*, 1] = !values.d_nan ; remove the second energy channel
      store_data, vars_bothchans[var_idx], data=bad, dlimits=dl, limits=l
    endif
  endfor
  

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 3. CORRECTED E-CHANNEL EQUIVALENT ENERGIES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Last, here are the energy shifts that we need to apply to the current ELECTRON 
  ; energies listed in the CDF files.  These shifts should be applied to the energy 
  ; bin centers for ALL ELECTRON EYES on each spacecraft.  
  ; These are positive shifts (i.e., Enew = Eold + Ecorr) if Ecorr listed is positive; 
  ; they are negative shifts (i.e., Enew = Eold - Ecorr) if Ecorr listed is negative.  
  ; For those equations, Eold is the original energy array (E0, E1, E2...E14) in units of
  ; keV and Enew is the corrected version of the arrays in keV using the factors listed below.

  ; the above, (3), is now handled by mms_feeps_correct_energies, called directly from mms_load_feeps

end