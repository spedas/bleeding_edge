;+
; PRO SGI2DSI
;
; :Description:
;    To transform a time series data between the SGI and DSI coordinate systems. 
;    This routine despins (by default) or spins (with DSI2SGI keyword) data regarding the satellite spin. 
;
; :Params:
;   name_in: input tplot variable to be transformed 
;   name_out: Name of the tplot variable in which the transformed data is stored
;
; :Keywords:
;   DSI2SGI: Set to transform data from DSI to SGI (despun coord --> spinning coord). 
;                       If not set, it transforms data from SGI to DSI (spinning coord --> despun coord). 
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
pro sgi2dsi, name_in, name_out, DSI2SGI=DSI2SGI, ignore_dlimits=ignore_dlimits, noload=noload 
  
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

  ;Get the SGA and SGI axes by interpolating the attitude data
  erg_interpolate_att, name_in, $ 
    spinperiod=spinperiod, spinphase=spinphase, $
    sgiz_j2000=sgiz, sgix_j2000=sgix, sgiy_j2000=sgiy, $
    sgaz_j2000=sgaz, sgax_j2000=sgax, sgay_j2000=sgay, noload=noload 
  
  ;Get the angle from SGI-X to SSI-X
  ;sgix2ssix_angle = erg_get_sgi2ssi_angle( $
  ;  sgax, sgay, sgaz, sgix, sgiy, sgiz )
  sgix2ssix_angle = sgiz.y[*,0] 
  sgix2ssix_angle[*] = 90.D + 21.6D ;[deg] Now the constant angle is used, which is not correct, though 
  
  spperiod = spinperiod.y & spphase = spinphase.y 
  
  ;Provide the SGI/DSI-Z axis vector array as the rotation axis 
  rot_axis = transpose( [ 0.D, 0.D, 1.D ] ) ## replicate( 1.D, n_elements(time) ) 
  
  ; SGI --> DSI (despin) 
  if undefined(DSI2SGI) then begin
    dprint, 'SGI --> DSI'
    coord_out = 'dsi'
    
    vector_rotate, $
      dat[*,0], dat[*,1], dat[*,2], $
      rot_axis[*,0], rot_axis[*,1], rot_axis[*,2], $
      -sgix2ssix_angle + spphase, $
      x1, y1, z1 
    endif else begin  ; DSI --> SGI (spin) 
      dprint, 'DSI --> SGI'
      coord_out = 'sgi' 
      
      vector_rotate, $
        dat[*,0], dat[*,1], dat[*,2], $
        rot_axis[*,0], rot_axis[*,1], rot_axis[*,2], $
        -1 * ( -sgix2ssix_angle + spphase), $
        x1, y1, z1
       
    endelse
    
    ;Store the converted data in a tplot variable
    dl_out = dl_in
    cotrans_set_coord, dl_out, coord_out
    str_element, dl_out, 'ytitle', /delete
    lim_out = lim_in
    str_element, lim_out, 'ytitle', /delete
    store_data, name_out, data = { x:time, y:[ [x1], [y1], [z1] ] }, dl=dl_out, lim=lim_out
  
  
  return
end

  
