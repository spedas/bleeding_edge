;+
;PROCEDURE: erg_pgs_make_fac
;PURPOSE:
;  Generate the field aligned coordinate transformation matrix
;  Specifically
;  #1 guarantee mag_data is in DSI and pos data is in GSE
;  #2 guarantee that time grid matches particle data
;
;Inputs(required):
;
;Outputs:
;
;Keywords:
;
;Notes:
;  Needs to be vectorized because erg_cotrans is waaaay too slow if fed single vectors at a time
;  If an error occurs fac_output will be undefined on return
;
;Author:
;  Tomo Hori, ERG Science Center, Nagoya Univ.
;  (E-mail tomo.hori _at_ nagoya-u.jp)
;
;History:
;  ver.0.0: The 1st experimental release 
;  
;$LastChangedDate: 2020-04-23 14:59:10 -0700 (Thu, 23 Apr 2020) $
;$LastChangedRevision: 28604 $
;-

;so we don't have one long routine of doom, all transforms should be separate helper functions
pro erg_pgs_xgse,mag_temp,pos_temp,x_basis,y_basis,z_basis

  compile_opt idl2,hidden


  get_data,mag_temp,data=d

  ;xaxis of this system is X of the gse system. Z is mag field
  x_axis = transpose(rebin([1D,0D,0D],3,n_elements(d.x)))
  
  store_data, 'xgse_pgs_temp', data={x:d.x, y:x_axis}, dl={data_att:{coord_sys:'gse'}}
  spd_cotrans, 'xgse_pgs_temp', 'xgse_pgs_temp', in_coord='gse', out_coord='j2000'
  erg_cotrans,'xgse_pgs_temp','xgse_pgs_temp',in_coord='j2000', out_coord='dsi'
    
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
pro erg_pgs_phigeo,mag_temp,pos_temp,x_basis,y_basis,z_basis

  compile_opt idl2,hidden

  postmp = 'pos_pgs_temp'
  copy_data, pos_temp, postmp
  spd_cotrans, postmp, postmp, in_coord='gse', out_coord='geo'
  get_data,postmp,data=pos_data
  
  ;transformation to generate other_dim dim for phigeo from thm_fac_matrix_make
  ;All the conversions to polar and trig simplifies to this.
  ;But the reason the conversion is why this is the conversion that is done, is lost on me.
  ;The conversion swaps the x & y components of position, reflects over x=0,z=0 then projects into the xy plane
  store_data,postmp[0],data={x:pos_data.x,y:[[-pos_data.y[*,1]],[pos_data.y[*,0]],[replicate(0.,n_elements(pos_data.x))]]}
  
  ;transform into dsl because particles are in dmpa
  spd_cotrans,postmp,postmp,in_coord='geo', out_coord='j2000'
  erg_cotrans,postmp,postmp,in_coord='j2000', out_coord='dsi'
  
  ;create orthonormal basis set
  tnormalize,mag_temp,out=z_basis
  tcrossp,postmp,z_basis,out=x_basis
  tnormalize,x_basis,out=x_basis
  tcrossp,z_basis,x_basis,out=y_basis
  
  ;create orthonormal basis set
  ;  z_basis = mag/norm(mag)
  ;  x_basis = crossp(z_basis,pos_basis)
  ;  x_basis = x_basis/norm(x_basis)
  ;  y_basis = crossp(z_basis,x_basis)
  
end

;so we don't have one long routine of doom, all transforms should be separate helper functions
pro erg_pgs_mphigeo,mag_temp,pos_temp,x_basis,y_basis,z_basis
  
  compile_opt idl2,hidden
  
  postmp = 'pos_pgs_temp'
  copy_data, pos_temp, postmp
  spd_cotrans, postmp, postmp, in_coord='gse', out_coord='geo'
  get_data,postmp,data=pos_data
  
  ;transformation to generate other_dim dim for mphigeo from thm_fac_matrix_make
  ;All the conversions to polar and trig simplifies to this.  
  ;But the reason the conversion is why this is the conversion that is done, is lost on me.
  ;The conversion swaps the x & y components of position, reflects over x=0,z=0 then projects into the xy plane 
  store_data,postmp[0],data={x:pos_data.x,y:[[pos_data.y[*,1]],[-pos_data.y[*,0]],[replicate(0.,n_elements(pos_data.x))]]}
  
  ;transform into dsl because particles are in dmpa
  spd_cotrans,postmp,postmp,in_coord='geo', out_coord='j2000'
  erg_cotrans,postmp,postmp,in_coord='j2000', out_coord='dsi'
  
  ;create orthonormal basis set
  tnormalize,mag_temp,out=z_basis
  tcrossp,z_basis,postmp,out=x_basis
  tnormalize,x_basis,out=x_basis
  tcrossp,z_basis,x_basis,out=y_basis
 
  ;create orthonormal basis set
  ;  z_basis = mag/norm(mag)
  ;  x_basis = crossp(z_basis,pos_basis)
  ;  x_basis = x_basis/norm(x_basis)
  ;  y_basis = crossp(z_basis,x_basis)

end

;; ERG_PGS_PHISM
;; To get unit vectors for FAC-phi_sm coordinate system
;; Z axis: local B-vector dir, usually taken from spin-averaged MGF data
;; X axis: phi_sm vector x Z, where the phi_sm lies in the azimuthally
;;         eastward direction at a spacecraft position in the SM coordinate
;;         system. In a dipole B-field geometry, X axis roughly points
;;         radially outward. 
;; Y axis: Z axis x X axis, roughly pointing azimuthally eastward
;;
;; Common to the other procedures here, pos_temp is the name of a
;; tplot variable containing spacecraft's position coordinates
;; in GSE. "mag_temp" is for the local magnetic field vectors in DSI. 
pro erg_pgs_phism,mag_temp,pos_temp,x_basis,y_basis,z_basis

  compile_opt idl2,hidden

  postmp = 'pos_pgs_temp'
  copy_data, pos_temp, postmp
  spd_cotrans, postmp, postmp, in_coord='gse', out_coord='sm'
  get_data, postmp, data=pos_data

  ;; The conversion swaps the x & y components of position, reflects
  ;; over x=0,z=0 then projects into the xy plane. In other words, the
  ;; position vectors projected on the SM-X-Y plane are rotated by +90
  ;; degrees around the SM-Z axis to get the phi_sm vectors.
  phitmp = 'phism_tmp'
  store_data, phitmp, data={x:pos_data.x, y:[[-pos_data.y[*, 1]], [pos_data.y[*, 0]], [replicate(0., n_elements(pos_data.x))]]}
  ;; SM to DSI 
  spd_cotrans, phitmp, phitmp, in_coord='sm', out_coord='j2000'
  erg_cotrans, phitmp, phitmp, in_coord='j2000', out_coord='dsi'
  
  ;; create orthonormal basis set
  tnormalize,mag_temp,out=z_basis
  tcrossp,phitmp, z_basis, out=x_basis
  tnormalize,x_basis,out=x_basis
  tcrossp, z_basis, x_basis, out=y_basis

  ;; clean up the temporary variables
  store_data, delete=[ postmp, phitmp ]
  
  ;create orthonormal basis set
  ;  z_basis = mag/norm(mag)
  ;  x_basis = crossp(phism, z_basis)
  ;  x_basis = x_basis/norm(x_basis)
  ;  y_basis = crossp(z_basis,x_basis)
  
end

;; ERG_PGS_MPHISM
;; To get unit vectors for FAC-(minus phi_sm) coordinate system
;; Z axis: local B-vector dir, usually taken from spin-averaged MGF data
;; X axis: minus phi_sm vector x Z, where the minus phi_sm lies in the azimuthally
;;         westward direction at a spacecraft position in the SM coordinate
;;         system. In a dipole B-field geometry, X axis roughly points
;;         radially inward. 
;; Y axis: Z axis x X axis, roughly pointing azimuthally westward
;;
;; Common to the other procedures here, pos_temp is the name of a
;; tplot variable containing spacecraft's position coordinates
;; in GSE. "mag_temp" is for the local magnetic field vectors in DSI. 
pro erg_pgs_mphism,mag_temp,pos_temp,x_basis,y_basis,z_basis

  compile_opt idl2,hidden

  postmp = 'pos_pgs_temp'
  copy_data, pos_temp, postmp
  spd_cotrans, postmp, postmp, in_coord='gse', out_coord='sm'
  get_data, postmp, data=pos_data

  ;; The conversion swaps the x & y components of position, reflects
  ;; over x=0,z=0 then projects into the xy plane. In other words, the
  ;; position vectors projected on the SM-X-Y plane are rotated by +90
  ;; degrees around the SM-Z axis to get the phi_sm vectors.
  phitmp = 'phism_tmp' ;; Note that the same name is used as in erg_pgs_phism, but it has opposite vectors 
  store_data, phitmp, data={x:pos_data.x, y:[[+pos_data.y[*, 1]], [-pos_data.y[*, 0]], [replicate(0., n_elements(pos_data.x))]]}
  ;; SM to DSI 
  spd_cotrans, phitmp, phitmp, in_coord='sm', out_coord='j2000'
  erg_cotrans, phitmp, phitmp, in_coord='j2000', out_coord='dsi'
  
  ;; create orthonormal basis set
  tnormalize,mag_temp,out=z_basis
  tcrossp,phitmp, z_basis, out=x_basis
  tnormalize,x_basis,out=x_basis
  tcrossp, z_basis, x_basis, out=y_basis

  ;; clean up the temporary variables
  store_data, delete=[ postmp, phitmp ]
  
  ;create orthonormal basis set
  ;  z_basis = mag/norm(mag)
  ;  x_basis = crossp(phism, z_basis)
  ;  x_basis = x_basis/norm(x_basis)
  ;  y_basis = crossp(z_basis,x_basis)
  
end


pro erg_pgs_xdsi,mag_temp,pos_temp,x_basis,y_basis,z_basis

  compile_opt idl2,hidden


  get_data,mag_temp,data=d

  ;xaxis of this system is X of the gse system. Z is mag field
  x_axis = transpose(rebin([1D,0D,0D],3,n_elements(d.x)))
  
  ;create orthonormal basis set
  tnormalize,mag_temp,out=z_basis
  tcrossp,z_basis,x_axis,out=y_basis
  tnormalize,y_basis,out=y_basis
  tcrossp,y_basis,z_basis,out=x_basis
  
  ;create orthonormal basis set
  ;  z_basis = mag/norm(mag)
  ;  y_basis = crossp(z_basis, DSI-X)
  ;  x_basis = crossp(z_basis,pos_basis)
  ;  x_basis = x_basis/norm(x_basis)
  
end


pro erg_pgs_make_fac, $
   times, $                      ;the time grid of the particle data
   mag_tvar_in, $                ;tplot variable containing the mag data in DSI
   pos_tvar_in, $                ;position variable containing the position data in GSE
   fac_output=fac_output, $      ; output time series field aligned coordinate transform matrix
   fac_type=fac_type, $          ;field aligned coordinate transform type (only mphigeo, atm)
   display_object=display_object ;(optional) dprint display object
  
  compile_opt idl2, hidden
  
  valid_types = ['mphigeo', 'phigeo', 'xgse', 'phism', 'mphism', 'xdsi']
  
  if ~undefined(fac_type) && ~in_set(fac_type, valid_types) then begin
    ;;ensure the user knows that the requested FAC variant is not being used 
    dprint, 'Transform: ' + fac_type + ' not yet implemented.  ' + $
            'Let us know you want it and we can add it ASAP.  ', $
            dlevel=0, display_object=display_object
    return
  endif              
  
  if undefined(mag_tvar_in) || undefined(pos_tvar_in) then begin
    dprint, 'Magnetic field and/or spacecraft position data not specified.  '+ $
            'Please use MAG_NAME and POS_NAME keywords.', $
            dlevel=0, display_object=display_object
    return
  endif
  
  ;;--------------------------------------------------------------------       
  ;;sanitize
  ;;--------------------------------------------------------------------
  
  ;;Note this logic could probably be rolled into
  ;;thm_pgs_clean_support in the future
  ;; Normnally mag_tvar_in should be erg_mgf_l2_mag_8sec_dsi
  if (tnames(mag_tvar_in))[0] ne '' then begin
    mag_tvar = (tnames(mag_tvar_in))[0]
    mag_temp = mag_tvar + '_pgs_temp'
    ;;Right now, magnetic field must be in DSI coordinates
    copy_data, mag_tvar, mag_temp ;;Sanitize it

    tinterpol_mxn, mag_temp, times, newname=mag_temp, /nan_extrapolate
    
  endif else begin
    dprint, 'Magnetic field variable not found: "' + mag_tvar_in + $
            '"; skipping field-aligned outputs', $
            dlevel=1, display_object=display_object
    return
  endelse

  ;; Normally pos_tvar_in should be erg_orb_l2_pos_gse
  if (tnames(pos_tvar_in))[0] ne '' then begin
    pos_tvar = (tnames(pos_tvar_in))[0]
    pos_temp = pos_tvar + '_pgs_temp' 
    ;;spd_cotrans, pos_tvar, pos_temp, in_coord='gse', out_coord='j2000' ;; Sanitize it
    copy_data, pos_tvar, pos_temp ;; Sanitize it

    tinterpol_mxn, pos_temp, times, newname=pos_temp, /nan_extrapolate
    
  endif else begin
    dprint, 'Position variable not found: "' + pos_tvar_in + $
            '"; skipping field-aligned outputs', $
            dlevel=1, display_object=display_object
    return
  endelse
  
  
  
  if fac_type eq 'mphigeo' then begin

    ;;--------------------------------------------------------------------
    ;;mphigeo
    ;;--------------------------------------------------------------------
    
    erg_pgs_mphigeo, mag_temp, pos_temp, x_basis, y_basis, z_basis
     
  endif else if fac_type eq 'phigeo' then begin
    
    ;;--------------------------------------------------------------------
    ;;phigeo
    ;;--------------------------------------------------------------------
    
    erg_pgs_phigeo, mag_temp, pos_temp, x_basis, y_basis, z_basis
    

  endif else if fac_type eq 'xgse' then begin
    
    ;;--------------------------------------------------------------------
    ;;xgse
    ;;--------------------------------------------------------------------
    
    ;;position isn't necessary for this one, but uniformity of interface and requirements trumps here 
    erg_pgs_xgse, mag_temp, pos_temp, x_basis, y_basis, z_basis
    
  endif else if fac_type eq 'phism' then begin
    
    ;;--------------------------------------------------------------------
    ;;phism
    ;;--------------------------------------------------------------------
    
    erg_pgs_phism, mag_temp, pos_temp, x_basis, y_basis, z_basis
    
  endif else if fac_type eq 'mphism' then begin
    
    ;;--------------------------------------------------------------------
    ;;mphism
    ;;--------------------------------------------------------------------
    
    erg_pgs_mphism,mag_temp,pos_temp,x_basis,y_basis,z_basis
    
  endif else if fac_type eq 'xdsi' then begin
    
    ;;--------------------------------------------------------------------
    ;;xdsi
    ;;--------------------------------------------------------------------
    
    erg_pgs_xdsi,mag_temp,pos_temp,x_basis,y_basis,z_basis
    
  endif 
  
  ;;--------------------------------------------------------------------
  ;;create rotation matrix
  ;;--------------------------------------------------------------------

  fac_output = dindgen(n_elements(times), 3, 3) ;;[(times), 3, 3]
  fac_output[*, 0, *] = x_basis                 ;; x/y/z_basis [ time, 3 (?axis_x, ?axis_y, ?axis_z) ]
  fac_output[*, 1, *] = y_basis
  fac_output[*, 2, *] = z_basis
  
  ;;--------------------------------------------------------------------
  ;;cleanup
  ;;--------------------------------------------------------------------
  
  del_data, pos_temp
  del_data, mag_temp
  
end
