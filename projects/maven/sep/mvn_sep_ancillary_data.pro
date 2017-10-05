; This file will eventually calculate all of the necessary ancillary data that does not go into the SEP level II CDF files

function mvn_sep_ancillary_data, trange = trange, delta_t = delta_t ,load_kernels=load_kernels,maven_kernels = maven_kernels

  if not keyword_set (delta_t) then delta_t = 32
   
  tr = timerange(trange)
  total_time = tr[1] - tr[0]
  ntimes =ceil(total_time/delta_t)
  times = tr[0] + delta_t*dindgen(ntimes)
  et = time_ephemeris(times)

;here we define the tags for the ancillary/ephemeris data structure.  This should have exactly the same
; format as the same structure in mvn_sep_read_l2_anc_cdf
  SEP_ancillarya = {time_UNIX: 0d, time_ephemeris:0d,look_directions_MSO:fltarr(4, 3),look_directions_SSO:fltarr(4, 3), $
                 look_directions_GEO:fltarr (4, 3)} 
                 
  SEP_ancillary = replicate (SEP_ancillarya,ntimes)
  if keyword_set(load_kernels) then maven_kernels = mvn_spice_kernels(trange = tr,/load,/valid) 
  
  tmp_MSO = mvn_sep_look_directions(utc = times, coordinate_frame = 'MAVEN_MSO')
  tmp_SSO = mvn_sep_look_directions(utc = times, coordinate_frame = 'MAVEN_SSO')
  tmp_GEO = mvn_sep_look_directions(utc = times, coordinate_frame = 'IAU_MARS')
  
   
  SEP_ancillary.look_directions_MSO = tmp_MSO.SEP_look_directions
  SEP_ancillary.look_directions_SSO = tmp_SSO.SEP_look_directions
  SEP_ancillary.look_directions_GEO = tmp_GEO.SEP_look_directions
  SEP_ancillary.time_UNIX =  times    
  SEP_ancillary.time_ephemeris = et
  
  return, SEP_ancillary
end
  
        
                 