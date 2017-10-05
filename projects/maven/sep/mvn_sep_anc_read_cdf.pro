;+
;PROCEDURE: 
;	MVN_SEP_ANC_READ_CDF
;PURPOSE: 
;	Routine to read CDF ancillary and ephemeris data files
;AUTHOR: 
;	Robert Lillis (rlillis@ssl.Berkeley.edu)
;CALLING SEQUENCE:
;	MVN_SEP_READ_L2_ANC_CDF, ffile
;KEYWORDS:
	

                 

pro mvn_sep_anc_read_cdf, files, tplot = tplot, sep_ancillary = sep_ancillary 

 n_files =n_elements (files)
 ntheta = 10
 nphi = 14
 ; here we define the tags for the ancillary/ephemeris data structure.
 SEP_ancillarya = {time: 0d, look_directions_MSO:fltarr(4, 3),look_directions_SSO:fltarr(4, 3), $
                   look_directions_GEO:fltarr (4, 3), $
                   fov_theta_centers:fltarr(4,ntheta), $
                   fov_phi_centers:fltarr(4,nphi), $
                   fov_full_MSO:fltarr(4,nphi, ntheta, 3), $
                   FOV_sun_angle:fltarr(4), FOV_ram_angle: fltarr(4), $
                   FOV_nadir_angle: fltarr(4),FOV_pitch_angle: fltarr(4),$
                   fraction_FOV_Mars:fltarr(4), fraction_FOV_illuminated:fltarr(4), $
                   Mars_fraction_sky:sqrt(-6.6), $
                   qrot_SEP1_to_MSO: fltarr(4), qrot_SEP2_to_MSO: fltarr(4), $
                   qrot_SEP1_to_SSO: fltarr(4), qrot_SEP2_to_SSO: fltarr(4), $
                   qrot_SEP1_to_GEO: fltarr(4), qrot_SEP2_to_GEO: fltarr(4), $
                   mvn_pos_MSO:fltarr(3),mvn_pos_GEO:fltarr(3),mvn_pos_ECLIPJ2000:fltarr(3), $
                   Earth_pos_ECLIPJ2000:fltarr(3),Mars_pos_ECLIPJ2000:fltarr(3),$
                   mvn_lat_GEO:sqrt(-6.6), mvn_elon_GEO:sqrt(-6.6), mvn_alt_areoid:sqrt(-6.6), mvn_sza:sqrt(-7.7), $
                   mvn_slt:sqrt(-7.7)}
   inf = sqrt(-7.7)
; initialize  'final' array of structures
  SEP_ancillary = SEP_ancillarya
  for J = 0, n_files-1 do begin
    cdfi = cdf_load_vars(files[J],/all,/verbose)
 ;vns = cdfi.vars.name
 ;nvars = n_elements (vns)
 
 
;epoch time.
    epoch = *cdfi.vars[1].dataptr
; UNIX time
    times = *cdfi.vars[0].dataptr
 
    nt = n_elements (times)

                    
  tmp = replicate (SEP_ancillarya, nt)
  tmp.time = times
 
 
; SEP look directions in three coordinate systems
  look_directions_MSO =[[[*cdfi.vars[5].dataptr]], [[*cdfi.vars[6].dataptr]],$
    [[*cdfi.vars[7].dataptr]],[[*cdfi.vars[8].dataptr]]]
; note that SSO coordinates are only useful or relevant for cruise phase data (2013-11-18 to 2014-09-21)
  look_directions_SSO =[[[*cdfi.vars[9].dataptr]], [[*cdfi.vars[10].dataptr]],$
    [[*cdfi.vars[11].dataptr]],[[*cdfi.vars[12].dataptr]]]
  look_directions_GEO =[[[*cdfi.vars[13].dataptr]], [[*cdfi.vars[14].dataptr]],$
    [[*cdfi.vars[15].dataptr]],[[*cdfi.vars[16].dataptr]]]
  
  tmp.look_directions_MSO = transpose (look_directions_MSO, [2, 1, 0])
  tmp.look_directions_SSO = transpose (look_directions_SSO, [2, 1, 0])
  tmp.look_directions_GEO = transpose (look_directions_GEO, [2, 1, 0])
  
  dimensions = size(look_directions,/dimensions)
  
  tmp.fov_phi_centers = transpose ([[*cdfi.vars[20].dataptr], [*cdfi.vars[21].dataptr],$
                                    [*cdfi.vars[22].dataptr],[*cdfi.vars[23].dataptr]])

  tmp.fov_theta_centers = transpose ([[*cdfi.vars[24].dataptr], [*cdfi.vars[25].dataptr],$
                                      [*cdfi.vars[26].dataptr],[*cdfi.vars[27].dataptr]])
  tmp.fov_full_MSO = transpose ([[*cdfi.vars[28].dataptr], [*cdfi.vars[29].dataptr],$
                                 [*cdfi.vars[30].dataptr],[*cdfi.vars[31].dataptr]])

  tmp.FOV_sun_angle = transpose ([[*cdfi.vars[32].dataptr], [*cdfi.vars[33].dataptr],$
                                  [*cdfi.vars[34].dataptr],[*cdfi.vars[35].dataptr]])
  tmp.FOV_ram_angle = transpose ([[*cdfi.vars[36].dataptr], [*cdfi.vars[37].dataptr],$
                                  [*cdfi.vars[38].dataptr],[*cdfi.vars[39].dataptr]])
  tmp.FOV_nadir_angle = transpose ([[*cdfi.vars[40].dataptr], [*cdfi.vars[41].dataptr],$
                                    [*cdfi.vars[42].dataptr],[*cdfi.vars[43].dataptr]])
  tmp.FOV_pitch_angle = transpose ([[*cdfi.vars[44].dataptr], [*cdfi.vars[45].dataptr],$
                                    [*cdfi.vars[46].dataptr],[*cdfi.vars[47].dataptr]])
  tmp.fraction_FOV_Mars = transpose ([[*cdfi.vars[48].dataptr], [*cdfi.vars[49].dataptr],$
                                      [*cdfi.vars[50].dataptr],[*cdfi.vars[51].dataptr]])
  tmp.fraction_FOV_illuminated = transpose ([[*cdfi.vars[52].dataptr], [*cdfi.vars[53].dataptr],$
                                             [*cdfi.vars[54].dataptr],[*cdfi.vars[55].dataptr]])

  tmp.Mars_fraction_sky = *cdfi.vars[56].dataptr
  tmp.qrot_SEP1_to_MSO = transpose (*cdfi.vars[57].dataptr)
  tmp.qrot_SEP2_to_MSO = transpose (*cdfi.vars[58].dataptr)
  tmp.qrot_SEP1_to_SSO = transpose (*cdfi.vars[59].dataptr)
  tmp.qrot_SEP2_to_SSO = transpose (*cdfi.vars[60].dataptr)
  tmp.qrot_SEP1_to_GEO = transpose (*cdfi.vars[61].dataptr)
  tmp.qrot_SEP2_to_GEO = transpose (*cdfi.vars[62].dataptr)
  tmp.mvn_pos_MSO = transpose (*cdfi.vars[63].dataptr)
  tmp.mvn_pos_GEO = transpose (*cdfi.vars[64].dataptr)
  tmp.mvn_pos_ECLIPJ2000 = transpose (*cdfi.vars[65].dataptr)
  tmp.Earth_pos_ECLIPJ2000 = transpose (*cdfi.vars[66].dataptr)
  tmp.Mars_pos_ECLIPJ2000 = transpose (*cdfi.vars[67].dataptr)
  tmp.mvn_lat_GEO=*cdfi.vars[68].dataptr
  tmp.mvn_elon_GEO=*cdfi.vars[69].dataptr
  tmp.mvn_alt_areoid = mvn_get_altitude(reform (tmp.mvn_pos_GEO[0,*]),$
                                                  reform (tmp.mvn_pos_GEO[1,*]),$
    reform (tmp.mvn_pos_GEO[2,*]))
  tmp.mvn_sza=*cdfi.vars[70].dataptr
  tmp.mvn_slt=*cdfi.vars[71].dataptr
  ; now increment the 'full' ancillary array
  SEP_ancillary = [SEP_ancillary, tmp]
  endfor
  
;  get rid of the first Nan element
  SEP_ancillary = SEP_ancillary [1:*]
  

  if keyword_set (tplot) then begin
  colors_3_lines = [80, 150, 240]
  store_data, 'SEP_FOV_Front1_MSO', data = {x: times,y:reform (full_SEP_ancillary.look_directions_MSO [0,*])}
  store_data, 'SEP_FOV_Back1_MSO', data = {x: times,y:reform (full_SEP_ancillary.look_directions_MSO [1,*])}
  store_data, 'SEP_FOV_Front2_MSO', data = {x: times,y:reform (full_SEP_ancillary.look_directions_MSO [2,*])}
  store_data, 'SEP_FOV_Back2_MSO', data = {x: times,y:reform (full_SEP_ancillary.look_directions_MSO [3,*])}
 
  store_data, 'SEP_FOV_Front1_SSO', data = {x: times,y:reform (full_SEP_ancillary.look_directions_SSO [0,*])}
  store_data, 'SEP_FOV_Back1_SSO', data = {x: times,y:reform (full_SEP_ancillary.look_directions_SSO [1,*])} 
  store_data, 'SEP_FOV_Front2_SSO', data = {x: times,y:reform (full_SEP_ancillary.look_directions_SSO [2,*])}
  store_data, 'SEP_FOV_Back2_SSO', data = {x: times,y:reform (full_SEP_ancillary.look_directions_SSO [3,*])}
 
  store_data, 'SEP_FOV_Front1_GEO', data = {x: times,y:reform (full_SEP_ancillary.look_directions_GEO [0,*])}
  store_data, 'SEP_FOV_Back1_GEO', data = {x: times,y:reform (full_SEP_ancillary.look_directions_GEO [1,*])}
  store_data, 'SEP_FOV_Front2_GEO', data = {x: times,y:reform (full_SEP_ancillary.look_directions_GEO [2,*])}
  store_data, 'SEP_FOV_Back2_GEO', data = {x: times,y:reform (full_SEP_ancillary.look_directions_GEO [3,*])}
  
; this tplot section not finished.  
  
  store_data, 'SEP_sun_angle', data ={x: times,y:transpose (full_SEP_ancillary.FOV_sun_angle)}
  store_data, 'SEP_ram_angle', data ={x: times,y:transpose (full_SEP_ancillary.FOV_ram_angle)}
  store_data, 'SEP_nadir_angle', data ={x: times,y:transpose (full_SEP_ancillary.FOV_nadir_angle)}
  store_data, 'SEP_pitch_angle', data ={x: times,y:transpose (full_SEP_ancillary.FOV_pitch_angle)}
  options,'SEP_FOV*', 'colors', colors_3_lines
 
  ylim,'SEP_FOV*', [-1.0, 1.0]
 
  options, 'SEP_FOV_*', 'labels', ['X', 'Y', 'Z']

  tplot, ['SEP_FOV*']
  endif
  
  
  
  
  
end
