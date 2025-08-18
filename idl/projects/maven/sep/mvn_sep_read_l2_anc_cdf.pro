;+
;PROCEDURE: 
;	MVN_SEP_READ_L2_ANC_CDF
;PURPOSE: 
;	Routine to read CDF ancillary and ephemeris data files
;AUTHOR: 
;	Robert Lillis (rlillis@ssl.Berkeley.edu)
;CALLING SEQUENCE:
;	MVN_SEP_READ_L2_ANC_CDF, ffile
;KEYWORDS:
	


pro mvn_sep_read_l2_anc_cdf, file, tplot = tplot, sep_ancillary = sep_ancillary 

 cdfi = cdf_load_vars(file,/all,/verbose)
 vns = cdfi.vars.name
 nvars = n_elements (vns)
 
;epoch time.
 epoch = *cdfi.vars[0].dataptr
; UNIX time
 times = *cdfi.vars[3].dataptr
; SEP look directions in three coordinate systems
  look_directions_MSO =*cdfi.vars[4].dataptr
  look_directions_SSO =*cdfi.vars[5].dataptr
  look_directions_GEO =*cdfi.vars[6].dataptr
  

 nt = n_elements (times)
; here we define the tags for the ancillary/ephemeris data structure.
  SEP_ancillarya = {time: 0d, look_directions_MSO:fltarr(4, 3),look_directions_SSO:fltarr(4, 3), $
                 look_directions_GEO:fltarr (4, 3)} 
  SEP_ancillary = replicate (SEP_ancillarya, nt)
  SEP_ancillary.time = times
  SEP_ancillary.look_directions_MSO = transpose (look_directions_MSO, [1, 2, 0])
  SEP_ancillary.look_directions_SSO = transpose (look_directions_SSO, [1, 2, 0])
  SEP_ancillary.look_directions_GEO = transpose (look_directions_GEO, [1, 2, 0])
  
  dimensions = size(look_directions,/dimensions)
  
  if keyword_set (tplot) then begin
  colors_3_lines = [80, 150, 240]
  store_data, 'SEP_FOV_Front1_MSO', data = {x: times,y:reform (look_directions_MSO [*, 0,*])}
  store_data, 'SEP_FOV_Back1_MSO', data = {x: times,y:reform (look_directions_MSO [*, 1,*])}
  store_data, 'SEP_FOV_Front2_MSO', data = {x: times,y:reform (look_directions_MSO [*, 2,*])}
  store_data, 'SEP_FOV_Back2_MSO', data = {x: times,y:reform (look_directions_MSO [*, 3,*])}
 
  store_data, 'SEP_FOV_Front1_SSO', data = {x: times,y:reform (look_directions_SSO [*, 0,*])}
  store_data, 'SEP_FOV_Back1_SSO', data = {x: times,y:reform (look_directions_SSO [*, 1,*])}
  store_data, 'SEP_FOV_Front2_SSO', data = {x: times,y:reform (look_directions_SSO [*, 2,*])}
  store_data, 'SEP_FOV_Back2_SSO', data = {x: times,y:reform (look_directions_SSO [*, 3,*])}
 
  store_data, 'SEP_FOV_Front1_GEO', data = {x: times,y:reform (look_directions_GEO [*, 0,*])}
  store_data, 'SEP_FOV_Back1_GEO', data = {x: times,y:reform (look_directions_GEO [*, 1,*])}
  store_data, 'SEP_FOV_Front2_GEO', data = {x: times,y:reform (look_directions_GEO [*, 2,*])}
  store_data, 'SEP_FOV_Back2_GEO', data = {x: times,y:reform (look_directions_GEO [*, 3,*])}
  
  options,'SEP_FOV*', 'colors', colors_3_lines
 
  ylim,'SEP_FOV*', [-1.0, 1.0]
 
  options, 'SEP_FOV_*', 'labels', ['X', 'Y', 'Z']

  tplot, ['SEP_FOV*']
  endif
  
end
