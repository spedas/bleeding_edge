;+
; PROCEDURE:
;       mms_feeps_flat_field_corrections
;
; PURPOSE:
;       Apply flat field correction factors to FEEPS ion/electron data;
;       correct factors are from the gain factor found in:
;       
;           FlatFieldResults_V3.xlsx
;           
;       from Drew Turner, 1/19/2017
;
; NOTES:
; 
;   From Drew Turner, 1/18/17:
;       Here are the correction factors that we need to apply to the current 
;       ION counts/rates/fluxes in the CDF files.  
;       NOTE, THIS IS A DIFFERENT TYPE OF CORRECTION THAN THAT FOR THE ELECTRONS!  
;       These shifts should be applied to the counts/rates/fluxes data EYE-BY-EYE on each spacecraft.  
;       These are multiplication factors (i.e., Jnew = Jold * Gcorr). 
;       For those equations, Jold is the original count/rate/flux array and
;       Jnew is the corrected version of the arrays using the factors listed below.
;       
;MMS1:
;Top6: Gcorr = 0.7
;Top7: Gcorr = 2.5
;Top8: Gcorr = 1.5
;Bot6: Gcorr = 0.9
;Bot7: Gcorr = 1.2
;Bot8: Gcorr = 1.0
;
;MMS2:
;Top6: Gcorr = 1.3
;Top7: BAD EYE
;Top8: Gcorr = 0.8
;Bot6: Gcorr = 1.4
;Bot7: BAD EYE
;Bot8: Gcorr = 1.5
;
;MMS3:
;Top6: Gcorr = 0.7
;Top7: Gcorr = 0.8
;Top8: Gcorr = 1.0
;Bot6: Gcorr = 0.9
;Bot7: Gcorr = 0.9
;Bot8: Gcorr = 1.3
;
;MMS4:
;Top6: Gcorr = 0.8
;Top7: BAD EYE
;Top8: Gcorr = 1.0
;Bot6: Gcorr = 0.8
;Bot7: Gcorr = 0.6
;Bot8: Gcorr = 0.9
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2024-03-27 16:34:54 -0700 (Wed, 27 Mar 2024) $
; $LastChangedRevision: 32511 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_feeps_flat_field_corrections.pro $
;-


pro mms_feeps_flat_field_corrections, probes = probes, data_rate = data_rate, suffix = suffix, keep_bad_eyes=keep_bad_eyes
  if undefined(probes) then probes = ['1', '2', '3', '4'] else probes = strcompress(string(probes), /rem)
  if undefined(data_rate) then data_rate = 'brst'
  if undefined(suffix) then suffix = ''
  if undefined(keep_bad_eyes) then keep_bad_eyes=0
  
  if keep_bad_eyes then begin
    bad_eye_value = 1.0
  endif else begin
    ; Default case, zero out bad eyes
    bad_eye_value = 0.0
  endelse
  G_corr = hash()
  G_corr['mms1-top6'] = 0.7
  G_corr['mms1-top7'] = 2.5
  G_corr['mms1-top8'] = 1.5
  G_corr['mms1-bot5'] = 1.2 ; updated 1/24
  G_corr['mms1-bot6'] = 0.9
  G_corr['mms1-bot7'] = 2.2 ; updated 1/24
  G_corr['mms1-bot8'] = 1.0

  G_corr['mms2-top4'] = 1.2 ; added 1/24
  G_corr['mms2-top6'] = 1.3
  G_corr['mms2-top7'] = bad_eye_value ; bad eye
  G_corr['mms2-top8'] = 0.8
  G_corr['mms2-bot6'] = 1.4
  G_corr['mms2-bot7'] = bad_eye_value ; bad eye
  G_corr['mms2-bot8'] = 1.5
  
  G_corr['mms3-top6'] = 0.7
  G_corr['mms3-top7'] = 0.8
  G_corr['mms3-top8'] = 1.0
  G_corr['mms3-bot6'] = 0.9
  G_corr['mms3-bot7'] = 0.9
  G_corr['mms3-bot8'] = 1.3

  G_corr['mms4-top6'] = 0.8
  G_corr['mms4-top7'] = bad_eye_value ; bad eye
  G_corr['mms4-top8'] = 1.0
  G_corr['mms4-bot6'] = 0.8
  G_corr['mms4-bot7'] = 0.6
  G_corr['mms4-bot8'] = 0.9
  G_corr['mms4-bot9'] = 1.5 ; added 1/24
  
  ;sensor_ids = ['6', '7', '8']
  sensor_ids = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12']
  sensor_types = ['top', 'bottom']
  levels = ['l2', 'l1b', 'sitl']
  species = ['ion', 'electron']
  
  for probe_idx = 0, n_elements(probes)-1 do begin
    for sensor_type = 0, n_elements(sensor_types)-1 do begin
      for sensor_id = 0, n_elements(sensor_ids)-1 do begin
        
        if G_corr.hasKey('mms'+probes[probe_idx]+'-'+strmid(sensor_types[sensor_type], 0, 3)+sensor_ids[sensor_id]) eq 1 then begin
          correction = G_corr['mms'+probes[probe_idx]+'-'+strmid(sensor_types[sensor_type], 0, 3)+sensor_ids[sensor_id]]
        endif else correction = 1.0
        
        for level = 0, n_elements(levels)-1 do begin
          for spec_idx = 0, n_elements(species)-1 do begin
            if correction ne 1.0 then begin
              cr_var = 'mms'+probes[probe_idx]+'_epd_feeps_'+data_rate+'_'+levels[level]+'_'+species[spec_idx]+'_'+sensor_types[sensor_type]+'_count_rate_sensorid_'+sensor_ids[sensor_id]+suffix
              i_var = 'mms'+probes[probe_idx]+'_epd_feeps_'+data_rate+'_'+levels[level]+'_'+species[spec_idx]+'_'+sensor_types[sensor_type]+'_intensity_sensorid_'+sensor_ids[sensor_id]+suffix
              c_var = 'mms'+probes[probe_idx]+'_epd_feeps_'+data_rate+'_'+levels[level]+'_'+species[spec_idx]+'_'+sensor_types[sensor_type]+'_counts_sensorid_'+sensor_ids[sensor_id]+suffix
              
              get_data, cr_var, data=count_rate, dlimits=cr_dl, limits=cr_l
              get_data, i_var, data=intensity, dlimits=i_dl, limits=i_l
              get_data, c_var, data=counts, dlimits=c_dl, limits=c_l
      
              if is_struct(count_rate) then store_data, cr_var, data={x: count_rate.X, y: count_rate.Y*correction, v: count_rate.V}, dlimits=cr_dl, limits=cr_l
              if is_struct(intensity) then store_data, i_var, data={x: intensity.X, y: intensity.Y*correction, v: intensity.V}, dlimits=i_dl, limits=i_l
              if is_struct(counts) then store_data, c_var, data={x: counts.X, y: counts.Y*correction, v: counts.V}, dlimits=c_dl, limits=c_l
            endif
          endfor
        endfor
      endfor
    endfor
  endfor

end
