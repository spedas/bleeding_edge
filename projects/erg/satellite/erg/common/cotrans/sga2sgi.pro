;+
; PRO SGA2SGI
;
; :Description:
;    To transform a time series data between the SGA and SGI coordinate systems
;
; :Params:
;   name_in: input tplot variable to be transformed 
;   name_out: Name of the tplot variable in which the transformed data is stored
;
; :Keywords:
;   SGI2SGA: Set to transform data from SGI to SGA. If not set, it transforms data from SGA to SGI. 
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
pro sga2sgi, name_in, name_out, SGI2SGA=SGI2SGA, ignore_dlimits=ignore_dlimits, noload=noload 
  
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
    sgiz_j2000=sgiz, sgax_j2000=sgax, sgaz_j2000=sgaz, $
    sgay_j2000=sgay, sgix_j2000=sgix, sgiy_j2000=sgiy, noload=noload  
  sgix = sgix.y & sgiy = sgiy.y & sgiz = sgiz.y
  sgax = sgax.y & sgay = sgay.y & sgaz = sgaz.y 
  
  ; SGA --> SGI 
  if undefined(SGI2SGA) then begin 
    dprint, 'SGA --> SGI'
    coord_out = 'sgi'
    
    ;Transform SGI-X,Y,Z axis unit vectors in J2000 to those in SGA 
    cart_trans_matrix_make, sgax, sgay, sgaz, mat_out=mat 
    tvector_rotate, mat, sgix, new=sgix_in_sga 
    tvector_rotate, mat, sgiy, new=sgiy_in_sga 
    tvector_rotate, mat, sgiz, new=sgiz_in_sga 
    
    ;Now transform the given vector in SGA to those in SGI
    cart_trans_matrix_make, sgix_in_sga, sgiy_in_sga, sgiz_in_sga, mat_out=mat 
    tvector_rotate, mat, dat, new=dat_in_sgi
    
    ;Store the converted data in a tplot variable
    dl_out = dl_in 
    cotrans_set_coord, dl_out, coord_out 
    str_element, dl_out, 'ytitle', /delete 
    lim_out = lim_in 
    str_element, lim_out, 'ytitle', /delete 
    store_data, name_out, data = { x:time, y:dat_in_sgi }, dl=dl_out, lim=lim_out
     
    return 
    
  endif else begin  ;SGI --> SGA 
    dprint, 'SGI --> SGA'
    coord_out = 'sga' 
    
    ;Transform SGA-X,Y,Z axis unit vectors in J2000 to those in SGI
    cart_trans_matrix_make, sgix, sgiy, sgiz, mat_out=mat
    tvector_rotate, mat, sgax, new=sgax_in_sgi
    tvector_rotate, mat, sgay, new=sgay_in_sgi
    tvector_rotate, mat, sgaz, new=sgaz_in_sgi

    ;Now transform the given vector in SGI to those in SGA
    cart_trans_matrix_make, sgax_in_sgi, sgay_in_sgi, sgaz_in_sgi, mat_out=mat
    tvector_rotate, mat, dat, new=dat_in_sga

    ;Store the converted data in a tplot variable 
    dl_out = dl_in 
    cotrans_set_coord, dl_out, coord_out 
    str_element, dl_out, 'ytitle', /delete 
    lim_out = lim_in 
    str_element, lim_out, 'ytitle', /delete 
    store_data, name_out, data = { x:time, y:dat_in_sga }, dl=dl_out, lim=lim_out 
    
    return
    
    
    
  endelse
  
  
end
