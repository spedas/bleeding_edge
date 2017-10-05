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
;$LastChangedDate: 2017-02-22 07:52:31 -0800 (Wed, 22 Feb 2017) $
;$LastChangedRevision: 22844 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_feeps_split_integral_ch.pro $
;-

pro mms_feeps_split_integral_ch_old, types, species, probe, suffix = suffix, data_rate = data_rate, level = level
  if undefined(level) then level = 'l2'
  if undefined(species) then species = 'electron' ; default to electrons
  if undefined(probe) then probe = '1' ; default to probe 1
  if undefined(suffix) then suffix = ''
  if undefined(data_rate) then data_rate = 'srvy'
  bottom_en = species eq 'electron' ? 71 : 78
  
  ; the following works for srvy mode, but doesn't get all of the sensors for burst mode
  if species eq 'electron' then sensors = [3, 4, 5, 11, 12] else sensors = [6, 7, 8]
  if level eq 'sitl' && species eq 'electron' then sensors = [5, 11, 12]
  
  ; special case for burst mode data
  if data_rate eq 'brst' && species eq 'electron' then sensors = ['1','2','3','4','5','9','10','11','12']
  if data_rate eq 'brst' && species eq 'ion' then sensors = ['6','7','8']

  for type_idx = 0, n_elements(types)-1 do begin
   ; type = level eq 'l2' ? species+'_'+types[type_idx] : types[type_idx]
    units_type = types[type_idx]
    for sensor_idx = 0, n_elements(sensors)-1 do begin
      ; the following 4 lines work for v5.4.x
      ;top_name = strcompress('mms'+probe+'_epd_feeps_top_'+type+'_sensorID_'+string(sensors[sensor_idx]), /rem)
      ;bottom_name = strcompress('mms'+probe+'_epd_feeps_bottom_'+type+'_sensorID_'+string(sensors[sensor_idx]), /rem)
      ;top_name = strlowcase(top_name)
      ;bottom_name = strlowcase(bottom_name)
      top_name = strcompress('mms'+probe+'_epd_feeps_'+data_rate+'_'+level+'_'+species+'_top_'+units_type+'_sensorid_'+string(sensors[sensor_idx]), /rem)
      bottom_name = strcompress('mms'+probe+'_epd_feeps_'+data_rate+'_'+level+'_'+species+'_bottom_'+units_type+'_sensorid_'+string(sensors[sensor_idx]), /rem)

      get_data, top_name+suffix, data=top_data, dlimits=top_dl
      get_data, bottom_name+suffix, data=bottom_data, dlimits=bottom_dl
      
      if ~is_struct(top_data) then begin
        dprint, dlevel = 0, 'Couldnt find the variable: ' + top_name+suffix
        continue
      endif
      if level ne 'sitl' and ~is_struct(bottom_data) then begin
        dprint, dlevel = 0, 'Couldnt find the variable: ' + bottom_name+suffix
        continue
      endif

;      top_name_out = strcompress('mms'+probe+'_epd_feeps_top_'+type+'_sensorID_'+string(sensors[sensor_idx])+'_clean', /rem)
;      bottom_name_out = strcompress('mms'+probe+'_epd_feeps_bottom_'+type+'_sensorID_'+string(sensors[sensor_idx])+'_clean', /rem)
;      top_name_out = strlowcase(top_name_out)
;      bottom_name_out = strlowcase(bottom_name_out)
      top_name_out = strcompress('mms'+probe+'_epd_feeps_'+data_rate+'_'+level+'_'+species+'_top_'+units_type+'_sensorid_'+string(sensors[sensor_idx])+'_clean', /rem)
      bottom_name_out = strcompress('mms'+probe+'_epd_feeps_'+data_rate+'_'+level+'_'+species+'_bottom_'+units_type+'_sensorid_'+string(sensors[sensor_idx])+'_clean', /rem)

      store_data, top_name_out+suffix, data={x: top_data.X, y: top_data.Y[*, 0:n_elements(top_data.V)-2], v: top_data.V[0:n_elements(top_data.V)-2]}, dlimits=top_dl
      if level ne 'sitl' then store_data, bottom_name_out+suffix, data={x: bottom_data.X, y: bottom_data.Y[*, 0:n_elements(bottom_data.V)-2], v: bottom_data.V[0:n_elements(bottom_data.V)-2]}, dlimits=bottom_dl
     
      ; limit the lower energy plotted
      options, top_name_out+suffix, ystyle=1
      ylim, top_name_out+suffix, bottom_en, 510., 1
      zlim, top_name_out+suffix, 0, 0, 1
      if level ne 'sitl' then begin
        options, bottom_name_out+suffix, ystyle=1
        ylim, bottom_name_out+suffix, bottom_en, 510., 1
        zlim, bottom_name_out+suffix, 0, 0, 1
      endif
  
      ; store the integral channel
      store_data, top_name+'_500keV_int'+suffix, data={x: top_data.X, y: top_data.Y[*, n_elements(top_data.V)-1]}
      if level ne 'sitl' then store_data, bottom_name+'_500keV_int'+suffix, data={x: bottom_data.X, y: bottom_data.Y[*, n_elements(bottom_data.V)-1]}
  
      ; delete the variable that contains both the spectra and the integral channel
      ; so users don't accidently plot the wrong quantity (discussed with Drew Turner 2/4/16)
      del_data, top_name+suffix
      if level ne 'sitl' then del_data, bottom_name+suffix
    endfor
  endfor
end
