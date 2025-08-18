
;so we don't have one long routine of doom, all transforms should be separate helper functions
pro thm_pgs_xgse,mag_temp,pos_temp,probe,x_basis,y_basis,z_basis

  compile_opt idl2,hidden


  get_data,mag_temp,data=d

  ;xaxis of this system is X of the gse system. Z is mag field
  x_axis = transpose(rebin([1D,0D,0D],3,n_elements(d.x)))
  
  store_data,'xgse_pgs_temp',data={x:d.x,y:x_axis},dl={data_att:{coord_sys:'gse'}}
  thm_cotrans,'xgse_pgs_temp','xgse_pgs_temp',out_coord='dsl',probe=probe
    
  ;create orthonormal basis set
  tnormalize,mag_temp,out=z_basis
  tcrossp,z_basis,'xgse_pgs_temp',out=y_basis
  tnormalize,y_basis,out=y_basis
  tcrossp,y_basis,z_basis,out=x_basis
  
  ;create orthonormal basis set
  ;  z_basis = mag/norm(mag)
  ;  x_basis = crossp(z_basis,pos_basis)
  ;  x_basis = x_basis/norm(x_basis)
  ;  y_basis = crossp(z_basis,x_basis)
  
end

;so we don't have one long routine of doom, all transforms should be separate helper functions
pro thm_pgs_phigeo,mag_temp,pos_temp,probe,x_basis,y_basis,z_basis

  compile_opt idl2,hidden

  get_data,pos_temp,data=pos_data
  
  ;transformation to generate other_dim dim for phigeo from thm_fac_matrix_make
  ;All the conversions to polar and trig simplifies to this.
  ;But the reason the conversion is why this is the conversion that is done, is lost on me.
  ;The conversion swaps the x & y components of position, reflects over x=0,z=0 then projects into the xy plane
  store_data,pos_temp[0],data={x:pos_data.x,y:[[-pos_data.y[*,1]],[pos_data.y[*,0]],[replicate(0.,n_elements(pos_data.x))]]}
  
  ;transform into dsl because particles are in dsl
  thm_cotrans,pos_temp,pos_temp,out_coord='dsl',probe=probe
  
  ;create orthonormal basis set
  tnormalize,mag_temp,out=z_basis
  tcrossp,pos_temp,z_basis,out=x_basis
  tnormalize,x_basis,out=x_basis
  tcrossp,z_basis,x_basis,out=y_basis
  
  ;create orthonormal basis set
  ;  z_basis = mag/norm(mag)
  ;  x_basis = crossp(z_basis,pos_basis)
  ;  x_basis = x_basis/norm(x_basis)
  ;  y_basis = crossp(z_basis,x_basis)
  
end

;so we don't have one long routine of doom, all transforms should be separate helper functions
pro thm_pgs_mphigeo,mag_temp,pos_temp,probe,x_basis,y_basis,z_basis
  
  compile_opt idl2,hidden
  
  get_data,pos_temp,data=pos_data
  
  ;transformation to generate other_dim dim for mphigeo from thm_fac_matrix_make
  ;All the conversions to polar and trig simplifies to this.  
  ;But the reason the conversion is why this is the conversion that is done, is lost on me.
  ;The conversion swaps the x & y components of position, reflects over x=0,z=0 then projects into the xy plane 
  store_data,pos_temp[0],data={x:pos_data.x,y:[[-pos_data.y[*,1]],[pos_data.y[*,0]],[replicate(0.,n_elements(pos_data.x))]]}
  
  ;transform into dsl because particles are in dsl
  thm_cotrans,pos_temp,pos_temp,out_coord='dsl',probe=probe
  
  ;create orthonormal basis set
  tnormalize,mag_temp,out=z_basis
  tcrossp,z_basis,pos_temp,out=x_basis
  tnormalize,x_basis,out=x_basis
  tcrossp,z_basis,x_basis,out=y_basis
 
  ;create orthonormal basis set
  ;  z_basis = mag/norm(mag)
  ;  x_basis = crossp(z_basis,pos_basis)
  ;  x_basis = x_basis/norm(x_basis)
  ;  y_basis = crossp(z_basis,x_basis)

end


;+
;PROCEDURE: thm_pgs_make_fac
;PURPOSE:
;  Generate the field aligned coordinate transformation matrix
;  Specifically
;  #1 guarantee mag_data is in dsl and pos data is in  gei
;  #2 guarantee that time grid matches particle data
;
;Inputs(required):
;
;Outputs:
;
;Keywords:
;
;Notes:
;  Needs to be vectorized because thm_cotrans is waaaay too slow if fed single vectors at a time
;  If an error occurs fac_output will be undfined on return
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-02-10 19:03:17 -0800 (Wed, 10 Feb 2016) $
;$LastChangedRevision: 19949 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_products/thm_pgs_make_fac.pro $
;-
pro thm_pgs_make_fac,times,$ ;the time grid of the particle data
                  mag_tvar_in,$ ;tplot variable containing the mag data
                  pos_tvar_in,$ ;position variable containing the position data
                  probe, $ ;string designating the probe being transformed
                  fac_output=fac_output,$ ; output time series field aligned coordinate transform matrix
                  fac_type=fac_type, $ ;field aligned coordinate transform type (only mphigeo, atm)
                  display_object=display_object ;(optional) dprint display object

    compile_opt idl2, hidden

                  
  valid_types = ['mphigeo','phigeo','xgse']
                  
  if ~undefined(fac_type) && ~in_set(fac_type,valid_types) then begin
    ;ensure the user knows that the requested FAC variant is not being used 
    dprint, 'Transform: ' + fac_type + ' not yet implemented.  ' + $
            'Let us know you want it and we can add it ASAP.  ', $
            dlevel=0, display_object=display_object
    return
  endif              
  
  ;--------------------------------------------------------------------       
  ;sanitize
  ;--------------------------------------------------------------------
  
  ;Note this logic could probably be rolled into thm_pgs_clean_support in the future
  if (tnames(mag_tvar_in))[0] ne '' then begin
    mag_temp = mag_tvar_in + '_pgs_temp'
    thm_cotrans,mag_tvar_in,mag_temp,out_coord='dsl',probe=probe
    tinterpol_mxn,mag_temp,times,newname=mag_temp,/nan_extrapolate
  endif else begin
    dprint, 'Magnetic field variable not found: "' + mag_tvar_in + $
            '"; skipping field-aligned outputs', $
            dlevel=1, display_object=display_object
    return
  endelse

  if (tnames(pos_tvar_in))[0] ne '' then begin
    pos_temp = pos_tvar_in + '_pgs_temp' 
    thm_cotrans,pos_tvar_in,pos_temp,out_coord='gei',probe=probe
    tinterpol_mxn,pos_temp,times,newname=pos_temp,/nan_extrapolate
  endif else begin
    dprint, 'Position variable not found: "' + pos_tvar_in + $
            '"; skippingfield-aligned outputs', $
            dlevel=1, display_object=display_object
    return
  endelse

  
  
  if fac_type eq 'mphigeo' then begin

    ;--------------------------------------------------------------------
    ;mphigeo
    ;--------------------------------------------------------------------
    
    thm_pgs_mphigeo,mag_temp,pos_temp,probe,x_basis,y_basis,z_basis
     
  endif else if fac_type eq 'phigeo' then begin
    ;--------------------------------------------------------------------
    ;phigeo
    ;--------------------------------------------------------------------
    
    thm_pgs_phigeo,mag_temp,pos_temp,probe,x_basis,y_basis,z_basis
    

  endif else if fac_type eq 'xgse' then begin
    
    ;--------------------------------------------------------------------
    ;xgse
    ;--------------------------------------------------------------------
    
    ;position isn't necessary for this one, but uniformity of interface and requirements trumps here 
    thm_pgs_xgse,mag_temp,pos_temp,probe,x_basis,y_basis,z_basis
    
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
  
  del_data,pos_temp
  del_data,mag_temp
end