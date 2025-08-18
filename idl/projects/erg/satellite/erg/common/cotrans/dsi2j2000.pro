;+
; PRO DSI2J2000
;
; :Description:
;    To transform a time series data between the DSI and J2000 coordinate systems
;
; :Params:
;   name_in: input tplot variable to be transformed 
;   name_out: Name of the tplot variable in which the transformed data is stored
;
; :Keywords:
;   J20002DSI: Set to transform data from J2000 to DSI. If not set, it transforms data from DSI to J2000. 
;   ignore_dlimits: (not yet implemented) 
; :Examples:
;
; :History:
; 2016/10/03: drafted
;
; :Author: Tomo Hori, ISEE (tomo.hori at nagoya-u.jp)
;
;   $LastChangedDate: 2019-10-23 14:19:14 -0700 (Wed, 23 Oct 2019) $
;   $LastChangedRevision: 27922 $
;
;-
pro dsi2j2000, name_in, name_out, J20002DSI=J20002DSI, $
  no_orb=no_orb, ignore_dlimits=ignore_dlimits, noload=noload

  ;Check the arguments and keywords
  if n_elements(name_in) eq 0 then begin
    message, 'Missing required argument name_in'
  endif
  if strlen( tnames(name_in) ) eq 0 then begin
    message, 'the input tplot variable is missing'
  endif
  if n_elements(name_out) eq 0 then begin
    message, 'Missing required argument name_out'
  endif
  
  reload = undefined( noload ) 


  get_data, name_in, data=d, dl=dl_in, lim=lim_in
  time = d.x
  dat = d.y

  ;Get the SGI axis by interpolating the attitude data
  erg_interpolate_att, name_in, $
    sgiz_j2000=dsiz_j2000, noload=noload  ;DSI-Z axis is identical to SGI-Z axis by definition

  ; Sun direction in J2000
  sundir = dblarr( n_elements(time), 3 )
  if keyword_set( no_orb ) then begin
    sundir[ *, 0 ] = 1.D & sundir[ *, 1 ] = 0.D & sundir[ *, 2 ] = 0.D  ; (1, 0, 0) in GSE
    store_data, 'sundir_gse', data={ x:time, y:sundir } 
  endif else begin ;Calculate the sun directions from the instantaneous satellite locations 
    if reload then begin
      get_timespan, tr_org 
      timespan, tr_org + [ -60., 60 ] 
      erg_load_orb 
      tinterpol, 'erg_orb_l2_pos_gse', time 
      get_data, 'erg_orb_l2_pos_gse_interp', t, scpos  
      sunpos = transpose( [ 1.496D+8, 0.D, 0.D ] ) ## replicate( 1.D, n_elements(scpos[*,0]) ) 
      sundir = sunpos - scpos 
      store_data, 'sundir_gse', data={ x:time, y:sundir } 
      tnormalize, 'sundir_gse', newname='sundir_gse' 
      timespan, tr_org 
    endif
  endelse
  
  if reload then cotrans, 'sundir_gse', 'sundir_gei', /gse2gei
  if reload then cotrans, 'sundir_gei', 'sundir_j2000', /gei2j2000
  ;store_data, delete='sundir_'+['gse','gei']
  
  ; Derive DSI-X and DSI-Y axis vectors in J2000. 
  ; The elementary vectors below are the definition of DSI. The detailed relationship 
  ; between the spin phase, sun pulse timing, sun direction, and the actual subsolar point 
  ; on the spining s/c body should be incorporated into the calculation below. 
  get_data, 'sundir_j2000', data=sun_j2000
  tcrossp, dsiz_j2000.y, sun_j2000.y, out=dsiy
  tcrossp, dsiy, dsiz_j2000.y, out=dsix
  dsix_j2000 = { x:time, y:dsix }
  dsiy_j2000 = { x:time, y:dsiy }


  ; DSI --> J2000
  if undefined(J20002DSI) then begin
    dprint, 'DSI --> J2000'
    coord_out = 'j2000'

    ; J2000-X,Y,Z axis vectors in DSI are derived
    cart_trans_matrix_make, dsix_j2000.y, dsiy_j2000.y, dsiz_j2000.y, mat_out=mat
    tvector_rotate, mat, transpose( [1.D, 0.D, 0.D] ) ## replicate( 1.D, n_elements(time) ), $
      new=j2000x_in_dsi
    tvector_rotate, mat, transpose( [0.D, 1.D, 0.D] ) ## replicate( 1.D, n_elements(time) ), $
      new=j2000y_in_dsi
    tvector_rotate, mat, transpose( [0.D, 0.D, 1.D] ) ## replicate( 1.D, n_elements(time) ), $
      new=j2000z_in_dsi

    ; Now transform the given vectors in DSI to those in J2000
    cart_trans_matrix_make, j2000x_in_dsi, j2000y_in_dsi, j2000z_in_dsi, $
      mat_out=mat
    tvector_rotate, mat, dat, new=dat_new

  endif else begin ; J2000 --> DSI
    dprint, 'J2000 --> DSI'
    coord_out = 'dsi'

    ;Transform the given vectors in J2000 to those in DSI
    cart_trans_matrix_make, dsix_j2000.y, dsiy_j2000.y, dsiz_j2000.y, mat_out=mat
    tvector_rotate, mat, dat, new=dat_new

  endelse

  ;Store the converted data in a tplot variable
  dl_out = dl_in
  cotrans_set_coord, dl_out, coord_out
  str_element, dl_out, 'ytitle', /delete
  lim_out = lim_in
  str_element, lim_out, 'ytitle', /delete
  store_data, name_out, data = { x:time, y:dat_new }, dl=dl_out, lim=lim_out


  return
end
