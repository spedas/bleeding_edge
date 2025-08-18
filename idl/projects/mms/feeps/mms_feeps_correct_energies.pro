;+
; PROCEDURE:
;       mms_feeps_correct_energies
;
; PURPOSE:
;       This function modifies the energy table in FEEPS spectra (intensity, count_rate, counts) variables
;       using the function: mms_feeps_energy_table (which is s/c, sensor head and sensor ID dependent)
;
; NOTES:
;     BAD EYES are replaced by NaNs
;
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2024-03-27 16:34:54 -0700 (Wed, 27 Mar 2024) $
; $LastChangedRevision: 32511 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_feeps_correct_energies.pro $
;-

pro mms_feeps_correct_energies, probes = probes, data_rate = data_rate, level = level, suffix = suffix, keep_bad_eyes = keep_bad_eyes
    if undefined(suffix) then suffix = ''
    if undefined(level) then level = 'l2'
    if undefined(probes) then probes =  ['1', '2', '3', '4'] else probes = strcompress(string(probes), /rem)
    
    types = ['top', 'bottom']
    sensors = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12']
    units_types = ['intensity', 'count_rate', 'counts']
    
    for probe_idx = 0, n_elements(probes)-1 do begin
      for type_idx = 0, n_elements(types)-1 do begin
        for sensor_idx = 0, n_elements(sensors)-1 do begin
          if long(sensors[sensor_idx]) ge 6 and long(sensors[sensor_idx]) le 8 then species = 'ion' else species = 'electron'
          
          for units_idx = 0, n_elements(units_types)-1 do begin
              var_name = strcompress('mms'+probes[probe_idx]+'_epd_feeps_'+data_rate+'_'+level+'_'+species+'_'+types[type_idx]+'_'+units_types[units_idx]+'_sensorid_'+string(sensors[sensor_idx]), /rem)
    
              get_data, var_name+suffix, data=d, dlimits=dl
              if is_struct(d) then begin
                energy_map = mms_feeps_energy_table(probes[probe_idx], strmid(types[type_idx], 0, 3), long(sensors[sensor_idx]), keep_bad_eyes=keep_bad_eyes)
                store_data, var_name+suffix, data={x: d.X, y: d.Y, v: energy_map}, dlimits=dl
              endif
              
          endfor ; units
        endfor ; sensors
      endfor ; types
    endfor ; probes
end