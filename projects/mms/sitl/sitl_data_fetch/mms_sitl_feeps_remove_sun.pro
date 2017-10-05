;+
; PROCEDURE:
;       mms_feeps_remove_sun
;
; PURPOSE:
;       Removes the sunlight contamination from FEEPS data
;
; NOTES:
;       Will only work in IDL 8.0+, due to the hash table data structure
;     
;       Originally based on code from Drew Turner, 2/1/2016
;
; $LastChangedBy: rickwilder $
; $LastChangedDate: 2017-08-09 13:51:06 -0700 (Wed, 09 Aug 2017) $
; $LastChangedRevision: 23769 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/sitl_data_fetch/mms_sitl_feeps_remove_sun.pro $
;-

pro mms_sitl_feeps_remove_sun, probe = probe, datatype = datatype, data_units = data_units, $
    data_rate = data_rate, level = level, suffix = suffix, tplotnames = tplotnames
    
    if undefined(data_units) then data_units = 'flux'
    if undefined(suffix) then suffix = ''
    if undefined(data_rate) then data_rate = 'srvy'
    if undefined(datatype) then datatype = 'electron'
    if undefined(probe) then probe = '1'
    
    
    ; the following works for srvy mode, but doesn't get all of the sensors for burst mode
    if datatype eq 'electron' then sensors = ['3', '4', '5', '11', '12'] else sensors = ['6', '7', '8']
    if level eq 'sitl' && datatype eq 'electron' then sensors = ['5', '11', '12']
    
    ; special case for burst mode data
    if data_rate eq 'brst' && datatype eq 'electron' then sensors = ['1','2','3','4','5','9','10','11','12']
    if data_rate eq 'brst' && datatype eq 'ion' then sensors = ['6','7','8']

    ; get the sector data
    get_data,  'mms'+probe+'_epd_feeps_' + data_rate + '_' + level + '_' + datatype + '_spinsectnum'+suffix, data=spin_sector
 ;   get_data, 'mms'+probe+'_epd_feeps_'+datatype+'_spinsectnum'+suffix, data=spin_sector ; v5.4.x
    
    if ~is_struct(spin_sector) then begin
        dprint, dlevel = 0, 'Error - couldn''t find the spin sector variable!!!! Cannot remove sun contamination!'
        return
    endif
    ; get the sector masks
    ;mask_sectors = mms_feeps_sector_masks()
    ; egrimes updated to use the CSV files on 8/2/2016
    mask_sectors = mms_sitl_read_feeps_sector_masks_csv()
    
    for data_units_idx = 0, n_elements(data_units)-1 do begin
        these_units = data_units[data_units_idx]
        
        if these_units eq 'cps' then these_units = 'count_rate'
        if these_units eq 'flux' then these_units = 'intensity'
        units_label = these_units eq 'intensity' ? '1/(cm!U2!N-sr-s-keV)' : 'Counts/s'
        
        ; added datatype to the name for L2 data
        ;these_units = datatype + '_' + these_units
        
        ; top sensors
        for sensor_idx = 0, n_elements(sensors)-1 do begin
          ;var_name = 'mms'+probe+'_epd_feeps_top_'+these_units+'_sensorID_'+sensors[sensor_idx]+'_clean'
          ;var_name = strlowcase(var_name)
          var_name = strcompress('mms'+probe+'_epd_feeps_'+data_rate+'_'+level+'_'+datatype+'_top_'+these_units+'_sensorid_'+string(sensors[sensor_idx])+'_clean', /rem)

          
          get_data, var_name+suffix, data = top_data, dlimits=top_dlimits
          
          ; don't crash if the data couldn't be found
          if ~is_struct(top_data) then continue
          
          if mask_sectors.haskey('mms'+probe+'imaskt'+sensors[sensor_idx]) && mask_sectors['mms'+probe+'imaskt'+sensors[sensor_idx]] ne !NULL then begin
            bad_sectors = mask_sectors['mms'+probe+'imaskt'+sensors[sensor_idx]]
    
            for bad_sector_idx = 0, n_elements(bad_sectors)-1 do begin
              this_bad_sector = where(spin_sector.Y eq bad_sectors[bad_sector_idx], bad_sect_count)
              if bad_sect_count ne 0 then top_data.Y[this_bad_sector, *] = !values.d_nan
            endfor
          endif
    
          ; resave the data, with the sunlight contamination removed
          store_data, var_name+'_sun_removed'+suffix, data=top_data, dlimits=top_dlimits
          zlim, var_name+'_sun_removed'+suffix, 0, 0, 1
          ylim, var_name+'_sun_removed'+suffix, 0, 0, 1
          options, var_name+'_sun_removed'+suffix, ztitle=units_label, ysubtitle='[keV]', ytitle='mms'+probe+'!CFEEPS!CTop!CSensor '+sensors[sensor_idx]
          append_array, tplotnames, var_name+'_sun_removed'+suffix
        endfor
    
        ; bottom sensors
        ; note: no bottom data in SITL files
        if level ne 'sitl' then begin
          for sensor_idx = 0, n_elements(sensors)-1 do begin
            ;var_name = 'mms'+probe+'_epd_feeps_bottom_'+these_units+'_sensorID_'+sensors[sensor_idx]+'_clean'
            ;var_name = strlowcase(var_name)
            var_name = strcompress('mms'+probe+'_epd_feeps_'+data_rate+'_'+level+'_'+datatype+'_bottom_'+these_units+'_sensorid_'+string(sensors[sensor_idx])+'_clean', /rem)

            get_data, var_name+suffix, data = bottom_data, dlimits=bottom_dlimits
            
            ; don't crash if the data couldn't be found
            if ~is_struct(bottom_data) then continue

            if mask_sectors.haskey('mms'+probe+'imaskb'+sensors[sensor_idx]) && mask_sectors['mms'+probe+'imaskb'+sensors[sensor_idx]] ne !NULL then begin
              bad_sectors = mask_sectors['mms'+probe+'imaskb'+sensors[sensor_idx]]
      
              for bad_sector_idx = 0, n_elements(bad_sectors)-1 do begin
                this_bad_sector = where(spin_sector.Y eq bad_sectors[bad_sector_idx], bad_sect_count)
                if bad_sect_count ne 0 then bottom_data.Y[this_bad_sector, *] = !values.d_nan
              endfor
            endif
      
            ; resave the data, with the sunlight contamination removed
            store_data, var_name+'_sun_removed'+suffix, data=bottom_data, dlimits=bottom_dlimits
            zlim, var_name+'_sun_removed'+suffix, 0, 0, 1
            ylim, var_name+'_sun_removed'+suffix, 0, 0, 1
            options, var_name+'_sun_removed'+suffix, ztitle=units_label, ysubtitle='[keV]', ytitle='mms'+probe+'!CFEEPS!CBottom!CSensor '+sensors[sensor_idx]
            append_array, tplotnames, var_name+'_sun_removed'+suffix
          endfor
        endif
    endfor
  
end