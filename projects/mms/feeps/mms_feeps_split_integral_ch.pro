;+
; Procedure:
;  mms_feeps_split_integral_ch
;
; Purpose:
;    this procedure splits the last integral channel from the FEEPS spectra, 
;    creating 2 new tplot variables:
;    
;       [original variable]_clean - spectra with the integral channel removed
;       [original variable]_500keV_int - the integral channel that was removed
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-09-12 11:01:04 -0700 (Tue, 12 Sep 2017) $
;$LastChangedRevision: 23954 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_feeps_split_integral_ch.pro $
;-

pro mms_feeps_split_integral_ch, types, species, probe, suffix = suffix, data_rate = data_rate, level = level, sensor_eyes = sensor_eyes
  if undefined(level) then level = 'l2'
  if undefined(species) then species = 'electron' ; default to electrons
  if undefined(probe) then probe = '1' ; default to probe 1
  if undefined(suffix) then suffix = ''
  if undefined(data_rate) then data_rate = 'srvy'
  bottom_en = species eq 'electron' ? 71 : 78
  
  top_sensors = sensor_eyes['top']
  bot_sensors = sensor_eyes['bottom']
  
  for type_idx = 0, n_elements(types)-1 do begin
   ; type = level eq 'l2' ? species+'_'+types[type_idx] : types[type_idx]
    units_type = types[type_idx]
    for sensor_idx = 0, n_elements(top_sensors)-1 do begin
      top_name = strcompress('mms'+probe+'_epd_feeps_'+data_rate+'_'+level+'_'+species+'_top_'+units_type+'_sensorid_'+string(top_sensors[sensor_idx]), /rem)

      get_data, top_name+suffix, data=top_data, dlimits=top_dl

      if ~is_struct(top_data) then begin
        dprint, dlevel = 0, 'Couldnt find the variable: ' + top_name+suffix
        continue
      endif

      top_name_out = strcompress('mms'+probe+'_epd_feeps_'+data_rate+'_'+level+'_'+species+'_top_'+units_type+'_sensorid_'+string(top_sensors[sensor_idx])+'_clean', /rem)

      store_data, top_name_out+suffix, data={x: top_data.X, y: top_data.Y[*, 0:n_elements(top_data.V)-2], v: top_data.V[0:n_elements(top_data.V)-2]}, dlimits=top_dl

      ; limit the lower energy plotted
      options, top_name_out+suffix, ystyle=1
      ylim, top_name_out+suffix, bottom_en, 510., 1
      zlim, top_name_out+suffix, 0, 0, 1
  
      ; store the integral channel
      store_data, top_name+'_500keV_int'+suffix, data={x: top_data.X, y: top_data.Y[*, n_elements(top_data.V)-1]}

      ; delete the variable that contains both the spectra and the integral channel
      ; so users don't accidently plot the wrong quantity (discussed with Drew Turner 2/4/16)
      del_data, top_name+suffix
    endfor
    for sensor_idx = 0, n_elements(bot_sensors)-1 do begin
      bottom_name = strcompress('mms'+probe+'_epd_feeps_'+data_rate+'_'+level+'_'+species+'_bottom_'+units_type+'_sensorid_'+string(bot_sensors[sensor_idx]), /rem)

      get_data, bottom_name+suffix, data=bottom_data, dlimits=bottom_dl

      if level ne 'sitl' and ~is_struct(bottom_data) then begin
        dprint, dlevel = 0, 'Couldnt find the variable: ' + bottom_name+suffix
        continue
      endif

      bottom_name_out = strcompress('mms'+probe+'_epd_feeps_'+data_rate+'_'+level+'_'+species+'_bottom_'+units_type+'_sensorid_'+string(bot_sensors[sensor_idx])+'_clean', /rem)

      if level ne 'sitl' then store_data, bottom_name_out+suffix, data={x: bottom_data.X, y: bottom_data.Y[*, 0:n_elements(bottom_data.V)-2], v: bottom_data.V[0:n_elements(bottom_data.V)-2]}, dlimits=bottom_dl

      ; limit the lower energy plotted
      if level ne 'sitl' then begin
        options, bottom_name_out+suffix, ystyle=1
        ylim, bottom_name_out+suffix, bottom_en, 510., 1
        zlim, bottom_name_out+suffix, 0, 0, 1
      endif

      ; store the integral channel
      if level ne 'sitl' then store_data, bottom_name+'_500keV_int'+suffix, data={x: bottom_data.X, y: bottom_data.Y[*, n_elements(bottom_data.V)-1]}

      ; delete the variable that contains both the spectra and the integral channel
      ; so users don't accidently plot the wrong quantity (discussed with Drew Turner 2/4/16)
      if level ne 'sitl' then del_data, bottom_name+suffix
    endfor
  endfor
end
