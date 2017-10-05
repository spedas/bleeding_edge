;+
; PROCEDURE:
;         mms_feeps_sector_spec
;
; PURPOSE:
;       Creates sector-spectrograms with FEEPS data (particle data organized by time and sector number)
;
; NOTES:
;
; 
; $LastChangedBy: rickwilder $
; $LastChangedDate: 2017-08-09 13:51:06 -0700 (Wed, 09 Aug 2017) $
; $LastChangedRevision: 23769 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/sitl_data_fetch/mms_sitl_feeps_sector_spec.pro $
;-

pro mms_sitl_feeps_sector_spec, probe = probe, data_units = data_units, data_rate = data_rate, $
  datatype = datatype, suffix = suffix, remove_sun = remove_sun, level = level
    if undefined(suffix) then suffix = ''
    if undefined(level) then level = 'l2'
    if undefined(probe) then probe = '1' else probe = strcompress(string(probe), /rem)
    if undefined(data_units) then data_units = 'count_rate'
    if undefined(data_rate) then data_rate = 'brst'
    if undefined(datatype) then datatype = 'electron'
    if undefined(remove_sun) then remove_sun = 0 ; 1=true/0=false

    suffix_in = remove_sun eq 1 ? suffix+'_sun_removed' : suffix

    if undefined(probe) then probe = '1'
    if undefined(data_units) then data_units = 'count_rate'
    
    ; the following works for srvy mode, but doesn't get all of the sensors for burst mode
    if datatype eq 'electron' then sensors = ['3', '4', '5', '11', '12'] else sensors = ['6', '7', '8']
  
    ; special case for burst mode data
    if data_rate eq 'brst' && datatype eq 'electron' then sensors = ['1','2','3','4','5','9','10','11','12']
    if data_rate eq 'brst' && datatype eq 'ion' then sensors = ['6','7','8']
    
    sensor_types = ['top', 'bottom']
    for sensor_type_idx = 0, n_elements(sensor_types)-1 do begin
        for sensor_idx = 0, n_elements(sensors)-1 do begin
          ; the following are valid names for v5.4 and below of the FEEPS CDFs
         ; get_data, 'mms'+probe+'_epd_feeps_'+sensor_types[sensor_type_idx]+'_'+datatype+'_'+data_units+'_sensorid_'+sensors[sensor_idx]+'_clean'+suffix_in, data=sensor_data
         ; get_data, 'mms'+probe+'_epd_feeps_'+datatype+'_spinsectnum'+suffix, data=sector_data
          
         ; the following are valid names for v5.5 and above of the FEEPS CDFs
          get_data, 'mms'+probe+'_epd_feeps_'+data_rate+'_'+level+'_'+datatype+'_'+sensor_types[sensor_type_idx]+'_'+data_units+'_sensorid_'+string(sensors[sensor_idx])+'_clean'+suffix_in, data=sensor_data
          get_data, 'mms'+probe+'_epd_feeps_' + data_rate + '_' + level + '_' + datatype + '_spinsectnum'+suffix, data=sector_data


          if ~is_struct(sensor_data) then begin
              dprint, dlevel = 0, 'Error, couldn''t find the sensor data for sensor ID: ' + sensors[sensor_idx] 
              continue
          endif
          spin_starts = where(sector_data.Y[0:n_elements(sector_data.Y)-2] ge sector_data.Y[1:n_elements(sector_data.Y)-1])+1
      
          sector_spec = dblarr(n_elements(spin_starts), 64)
          
          current_start = spin_starts[0]
          for spin_idx = 1, n_elements(spin_starts)-1 do begin
              ; find the sectors for this spin
              sectors = sector_data.Y[current_start:spin_starts[spin_idx]]
      
              average_over_en = average(sensor_data.Y[current_start:spin_starts[spin_idx], *], 2, /nan)
              sector_spec[spin_idx, sectors] = average_over_en
      
              current_start = spin_starts[spin_idx]
          endfor
          
          new_name = 'mms'+probe+'_epd_feeps_'+data_rate+'_'+level+'_'+datatype+'_'+sensor_types[sensor_type_idx]+'_'+data_units+'_sensorid_'+string(sensors[sensor_idx])+'_sectspec'+suffix_in
          store_data, new_name, data={x: sector_data.X[spin_starts], y: sector_spec, v: indgen(64)}
          options, new_name, spec=1
          ylim, new_name, 0, 64, 0
        endfor
    endfor
    
end