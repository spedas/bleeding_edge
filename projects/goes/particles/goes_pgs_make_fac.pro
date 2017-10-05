
;+
; Get basis aligned with projection of rgeo (x)
;-
pro goes_pgs_rgeo,mag_temp,x_basis,y_basis,z_basis

  compile_opt idl2,hidden


  get_data, mag_temp, times

  ;rgeo is in direction of spacecraft x
  x_axis = transpose(rebin([1D,0D,0D],3,n_elements(times)))
  
  store_data,'rgeo_pgs_temp',data={x:times,y:x_axis}
    
  ;create orthonormal basis set
  tnormalize,mag_temp,out=z_basis
  tcrossp,z_basis,'rgeo_pgs_temp',out=y_basis
  tnormalize,y_basis,out=y_basis
  tcrossp,y_basis,z_basis,out=x_basis
  
end

;+
; Get basis aligned with projection of phigeo (y)
;-
pro goes_pgs_phigeo,mag_temp,x_basis,y_basis,z_basis

  compile_opt idl2,hidden

  get_data, mag_temp, times
  
  ;phigeo is in direction of spacecraft y (east)
  y_axis = transpose(rebin([0D,1D,0D],3,n_elements(times)))

  store_data, 'phigeo_pgs_temp',data={x:times,y:y_axis}
  

  ;create orthonormal basis set
  tnormalize,mag_temp,out=z_basis
  tcrossp,'phigeo_pgs_temp',z_basis,out=x_basis
  tnormalize,x_basis,out=x_basis
  tcrossp,z_basis,x_basis,out=y_basis
  
end

;+
; Get basis aligned with projection of mphigeo (y)
;-
pro goes_pgs_mphigeo,mag_temp,x_basis,y_basis,z_basis
  
  compile_opt idl2,hidden
  
  get_data, mag_temp, times
  
  ;phigeo is in direction of spacecraft y (east), use cross product to get mphigeo
  y_axis = transpose(rebin([0D,1D,0D],3,n_elements(times)))

  store_data, 'phigeo_pgs_temp',data={x:times,y:y_axis}
  
  ;create orthonormal basis set
  tnormalize,mag_temp,out=z_basis
  tcrossp,z_basis,'phigeo_pgs_temp',out=x_basis
  tnormalize,x_basis,out=x_basis
  tcrossp,z_basis,x_basis,out=y_basis
 
end


;+
;PROCEDURE:
;  goes_pgs_make_fac
;
;PURPOSE:
;  Generate the field aligned coordinate transformation matrix
;
;Inputs:
;  times:  the time grid of the particle data
;  mag_tvar_in:  tplot variable containing the mag data
;  fac_type:  field aligned coordinate transform type (only mphigeo, atm)
;  display_object:  (optional) dprint display object
;
;Outputs:
;  fac_output:  time series of field aligned coordinate transform matrices
;               undefined in case of error
;
;Notes:
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-04-11 09:42:10 -0700 (Tue, 11 Apr 2017) $
;$LastChangedRevision: 23134 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/goes/particles/goes_pgs_make_fac.pro $
;-
pro goes_pgs_make_fac,times,$ ;the time grid of the particle data
                  mag_tvar_in,$ ;tplot variable containing the mag data
                  fac_output=fac_output,$ ; output time series field aligned coordinate transform matrix
                  fac_type=fac_type, $ ;field aligned coordinate transform type (only mphigeo, atm)
                  display_object=display_object ;(optional) dprint display object

    compile_opt idl2, hidden

                  
  valid_types = ['mphigeo','phigeo','rgeo']
                  
  if ~undefined(fac_type) && ~in_set(fac_type,valid_types) then begin
    ;ensure the user knows that the requested FAC variant is not being used 
    dprint, 'Transform: ' + fac_type + ' not yet implemented.  ' + $
            'Let us know you want it and we can add it ASAP.  ', $
            dlevel=0, display_object=display_object
    return
  endif              
  
  if undefined(mag_tvar_in) then begin
    dprint, 'Magnetic field and/or spacecraft position data not specified.  '+ $
            'Please use MAG_NAME keyword.', $
            dlevel=0, display_object=display_object
    return
  endif

  ;--------------------------------------------------------------------       
  ;sanitize
  ;--------------------------------------------------------------------
  
  ;Note this logic could probably be rolled into thm_pgs_clean_support in the future
  if (tnames(mag_tvar_in))[0] ne '' then begin
    mag_temp = mag_tvar_in + '_pgs_temp'
    tinterpol_mxn,mag_tvar_in,times,newname=mag_temp,/nan_extrapolate
  endif else begin
    dprint, 'Magnetic field variable not found: "' + mag_tvar_in + $
            '"; skipping field-aligned outputs', $
            dlevel=1, display_object=display_object
    return
  endelse

  if fac_type eq 'mphigeo' then begin

    ;--------------------------------------------------------------------
    ;mphigeo
    ;--------------------------------------------------------------------
    
    goes_pgs_mphigeo,mag_temp,x_basis,y_basis,z_basis
     
  endif else if fac_type eq 'phigeo' then begin

    ;--------------------------------------------------------------------
    ;phigeo
    ;--------------------------------------------------------------------
    
    goes_pgs_phigeo,mag_temp,x_basis,y_basis,z_basis
    

  endif else if fac_type eq 'rgeo' then begin
    
    ;--------------------------------------------------------------------
    ;rgeo
    ;--------------------------------------------------------------------
    
    goes_pgs_rgeo,mag_temp,x_basis,y_basis,z_basis
    
  endif 
  
  ;--------------------------------------------------------------------
  ;create rotation matrix
  ;--------------------------------------------------------------------
  
  fac_output = dindgen(n_elements(times),3,3)
  fac_output[*,0,*] = x_basis
  fac_output[*,1,*] = y_basis
  fac_output[*,2,*] = z_basis
  
  ;--------------------------------------------------------------------
  ;cleanup
  ;--------------------------------------------------------------------
  
  del_data, '*_pgs_temp'

end