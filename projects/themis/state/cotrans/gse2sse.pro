;+
;procedure: gse2sse
;
;Purpose: Coordinate transformation between GSE & SSE coordinates(and the inverse)
;
;     SSE is defined as:
;        X: Moon->Sun Line
;        Y: Ecliptic North cross X
;        Z: X cross Y
;         
;     GSE is defined as:
;        X: Earth Sun Line(naturally in the ecliptic plane)
;        Y: Z x X
;        Z: Ecliptic North
;inputs:
;
;  name_in: 
;    Name of input tplot variable to be transformed or an array of data [t,x,y,z]
;  name_sun_pos:
;    Name of the solar position tplot variable in GEI coordinates
;    or as an array of data [t,x,y,z]
;  name_lun_pos:
;    Name of the lunar position tplot variable in GEI coordinates
;    or as an array of data [t,x,y,z]
;  name_out:
;    Name that the rotated variable should take.
;    
;keywords:
;
;   /SSE2GSE inverse transformation
;
;   /IGNORE_DLIMITS: Dlimits normally used to determine if coordinate
;   system is correct, to decide if position needs offset, or to 
;   stop incorrect transforms.  This option will stop this behavior. 
;   This keyword is only used with tplot variables and ignored if
;   array data is input
;
;   /ROTATION_ONLY: Set this flag when to only do the rotation, and not
;   the translation from geocentric to selenocentric coordinates.
;   That is used for sse2sel transform when creating the sel rotation
;   matrix 

;Examples:

;      gse2sse,'tha_state_pos','slp_sun_pos_gse','slp_lun_pos_gse','tha_state_pos_sse'
;      gse2sse,'tha_state_pos_sse','slp_sun_pos_gse','slp_lun_pos_gse','tha_state_pos_gse',/sse2gse,/ignore_dlimits
;
;      OR (with vector data [t,x,y,z]

;      gse2sse, pos_gse,sun_gse,lun_pos,pos_sse
;      gse2sse,pos_sse,sun_gse,lun_pos,pos_gse,/sse2gse
;     
;Notes:
;   #1 SSE coordinate Z-axis is generally not exactly parallel to ecliptic north,
;      as the moon will not always be in the ecliptic plane, and thus the moon->sun line
;      will not always lie in the ecliptic plane.
;   #2 If dlimit-labeled position passed in without /ignore_dlimits,
;      input will be offset to account for relative position of frames of reference.
;   #3 If dlimit-labeled velocity passed in without /ignore_dlimits,
;      input will be offset to account for relative motion of frames of reference
;   #4 If dlimit-labeled acceleration passed in without /ignore_dlimits,
;      warning will be raise, but offset will not be applied automatically
;   #5 Uses tvector_rotate, and sse_matrix_make to perform the rotation.
;      tvector_rotate will also interpolate the rotation matrix onto the time-grid of the input.
;      Interpolation done using quaterions and the spherical linear interpolation algorithm (SLERP)
;   #6 dlimits are automatically ignored if vector data is input
;      
;Written by Jenni Kissinger and Patrick Cruce
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2012-06-04 10:26:03 -0700 (Mon, 04 Jun 2012) $
; $LastChangedRevision: 10493 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/state/cotrans/gse2sse.pro $
;-



pro gse2sse,name_in,name_sun_pos,name_lun_pos,name_out,sse2gse=sse2gse,$
    ignore_dlimits=ignore_dlimits, rotation_only=rotation_only

  compile_opt idl2

  if n_params() ne 4 then begin
    message,'Aborted: Missing 1 or more required arguments: name_in,name_out,name_sun_pos,name_lun_pos
  end
  
  ; check the type of data that is input (strings are tplot variables)
  if size(name_in, /type) eq 7 then tplotvar=1 else tplotvar=0
  
  if tplotvar then begin

      sun_name = tnames(name_sun_pos)
      lun_name = tnames(name_lun_pos)
      
      if n_elements(sun_name) ne 1 || n_elements(lun_name) ne 1 || sun_name[0] eq '' || lun_name[0] eq '' then begin
        message,'Aborted: Must load Sun/Moon position to perform this transformation (Load Routine:"thm_load_slp")'
      endif
      
      get_data,name_in,dlimit=dl,data=in_d
      get_data,sun_name,data=sun_d,dlimit=sun_dl
      get_data,lun_name,data=lun_d,dlimit=lun_dl
      
      if ~is_struct(sun_d) || ~is_struct(lun_d) then begin
        message,'Aborted: Must load Sun/Moon position to perform this transformation (Load Routine:"thm_load_slp")'
      endif
      
      if min(sun_d.x,/nan)-min(in_d.x,/nan) gt 60*60 || max(in_d.x,/nan) - max(sun_d.x,/nan) gt 60*60 then begin
        dprint,'NON-FATAL-ERROR: ' + sun_name + ' and ' + name_in + ' fail to overlap for time greater than 1 hour. Data may have significant interpolation errors.' 
      endif
      
      if min(lun_d.x,/nan)-min(in_d.x,/nan) gt 60*60 || max(in_d.x,/nan) - max(lun_d.x,/nan) gt 60*60 then begin
        dprint,'NON-FATAL-ERROR: ' + lun_name + ' and ' + name_in + ' fail to overlap for time greater than 1 hour. Data may have significant interpolation errors.' 
      endif
      
      sun_pos_coord = 'none' ;setting default, if data_att.coordsys not present
      str_element,sun_dl,'data_att.coord_sys',sun_pos_coord
      
      ;assumes sun pos in gei coordinates if ignore dlimits set
      if keyword_set(ignore_dlimits) || sun_pos_coord eq 'gei' then begin
        cotrans,sun_name,sun_name+'_gse_cotrans',/gei2gse,ignore_dlimits=ignore_dlimits
        sun_name = sun_name+'_gse_cotrans'
      endif else if sun_pos_coord ne 'gse' then begin
        message,'ERROR: ' + sun_name + ' needs to be in GSE or GEI coordinates'
      endif
     
      lun_pos_coord = 'none' ;setting default, if data_att.coordsys not present
      str_element,lun_dl,'data_att.coord_sys',lun_pos_coord
      
      ;assumes sun pos in gei coordinates if ignore dlimits set
      if keyword_set(ignore_dlimits) || lun_pos_coord eq 'gei' then begin
        cotrans,lun_name,lun_name+'_gse_cotrans',/gei2gse,ignore_dlimits=ignore_dlimits
        lun_name = lun_name+'_gse_cotrans'
      endif else if lun_pos_coord ne 'gse' then begin
        message,'ERROR: ' + lun_name + ' needs to be in GSE or GEI coordinates'
      endif else begin
        copy_data,lun_name,lun_name+'_gse_cotrans' ;working copy of data
        lun_name = lun_name+'_gse_cotrans'
      endelse
     
      sse_matrix_make,sun_name,lun_name,newname='sse_mat_cotrans',fail=fail,ignore_dlimits=ignore_dlimits
     
      if fail then begin
        message,'Failed to create SSE rotation matrix
      endif
    
      st_type = 'none'
      str_element,dl,'data_att.st_type',st_type
    
      name_one = name_in
      name_two = name_out

  endif else begin   ; end of tplotvar if statement

    sun_struc = {x:name_sun_pos[*,0], y:name_sun_pos[*,1:3]}
    tinterpol_mxn,sun_struc,name_in[*,0],out=sun_gei,error=err
    cotrans,sun_gei.y,sun_gse,sun_gei.x,/gei2gse,ignore_dlimits=ignore_dlimits

    lun_struc = {x:name_lun_pos[*,0], y:name_lun_pos[*,1:3]}
    tinterpol_mxn,lun_struc,name_in[*,0],out=lun_gei,error=err
    cotrans,lun_gei.y,lun_gse,lun_gei.x,/gei2gse,ignore_dlimits=ignore_dlimits

    sun_gse_arr=name_in
    sun_gse_arr[*,1:3]=sun_gse
    lun_gse_arr=name_in
    lun_gse_arr[*,1:3]=lun_gse
    sse_matrix_make,sun_gse_arr,lun_gse_arr,newname=sse_mat_cotrans,fail=fail,ignore_dlimits=ignore_dlimits

  endelse   ; end of vector data if statement
  
  ;perform affine offsets for forward transform
  if ~keyword_set(sse2gse) then begin
  
    dprint,'GSE-->SSE'
 
    ; again check if we are dealing with a tplot variable (it needs to be
    ; handled differently)
    if tplotvar then begin  
 
      if st_type eq 'pos' then begin
        if keyword_set(ignore_dlimits) then begin
          dprint,'WARNING: dlimits indicates data is a position.  Full transformation between SSE coords requires offset that will not be performed because IGNORE_DLIMITS is set'
        endif else begin
          dprint,'GSE2SSE: Performing position offset.'
          tinterpol_mxn,lun_name,name_one,error=err,/overwrite
          if err eq 0 then begin
            message,'Error performing position offset during SSE transformation(interpolation operation)'
          endif
          
          calc,'"'+name_two+'" = "' + name_one + '"-"'+lun_name+'"',error=err
          if keyword_set(err) then begin
            message,'Error performing position offset during SSE transformation(subtraction operation)'
          endif
          
          name_one = name_two
        endelse
      endif else if st_type eq 'vel' then begin
        if keyword_set(ignore_dlimits) then begin
          dprint,'WARNING: dlimits indicates data is a velocity.  Full transformation between SSE coords requires offset that will not be performed because IGNORE_DLIMITS is set'
        endif else begin
          
          deriv_data,lun_name,/replace
          
          tinterpol_mxn,lun_name,name_one,/overwrite,error=err
          if err eq 0 then begin
            message,'Error performing velocity offset during SSE transformation(interpolation operation)'
          endif
          
          calc,'"'+name_two+'" = "' + name_one + '"-"' + lun_name + '"',error=err
          if keyword_set(err) then begin
            message,'Error performing velocity offset during SSE transformation(subtraction operation)'
          endif
          
          name_one = name_two
          
        endelse
      endif else if st_type eq 'acc' then begin
        dprint,'WARNING dlimits indicates data is an acceleration.  Full transformation between SSE coords requires offset that must be performed manually.'
      endif else begin
        dprint,'GSE2SSE: NOT performing position offset'
      endelse
  
    endif else begin   ; end of tplotvar if statement
 
      if ~keyword_set(ROTATION_ONLY) then begin

          lun_gse_struc = {x:lun_gse_arr[*,0], y:lun_gse_arr[*,1:3]}
          tinterpol_mxn,lun_gse_struc,name_in[*,0],out=lun_gse_new,error=err
                  
          name_two = dblarr(n_elements(lun_gse_new.x),4)
          name_two[*,0]=lun_gse_new.x
          name_two[*,1]=name_in[*,1]-lun_gse_new.y[*,0]
          name_two[*,2]=name_in[*,2]-lun_gse_new.y[*,1]
          name_two[*,3]=name_in[*,3]-lun_gse_new.y[*,2]
          name_one=name_two

      endif else begin 

          name_one=name_in

      endelse

    endelse    ; end of vector data if statement
  
  endif   ; end of gse2sse conversion

  if tplotvar then begin
     tvector_rotate,'sse_mat_cotrans',name_one,newname=name_two,error=err,invert=keyword_set(sse2gse),/vector_skip_nonmonotonic,/matrix_skip_nonmonotonic  
  endif else begin

     if keyword_set(sse2gse) then name_one=name_in
     tvector_rotate,sse_mat_cotrans,name_one[*,1:3],newname=name_two,error=err,invert=keyword_set(sse2gse);,/vector_skip_nonmonotonic,/matrix_skip_nonmonotonic

     name_out = name_one
     name_out[*,1:3] = name_two
     name_one = name_out
  endelse
 
  if err eq 0 then begin  
    message,'Error performing rotation during SSE transformation  
  endif
  
  ;performing affine offsets for inverse transform
  if keyword_set(sse2gse) then begin
  
    dprint,'SSE-->GSE'

    ; handle tplotvars differently than vector data
    if tplotvar then begin  
    
      if st_type eq 'pos' then begin
        if keyword_set(ignore_dlimits) then begin
          dprint,'WARNING: dlimits indicates data is a position.  Full transformation between SSE coords requires offset that will not be performed because IGNORE_DLIMITS is set'
        endif else begin

          tinterpol_mxn,lun_name,name_two,/overwrite,error=err

          if err eq 0 then begin
            message,'Error performing position offset during SSE transformation(interpolation operation)'
          endif
          
          calc,'"'+name_two+'" = "' + name_two + '"+"'+lun_name+'"',error=err

          if keyword_set(err) then begin
            message,'Error performing position offset during SSE transformation(subtraction operation)'
          endif
          
        endelse
      endif else if st_type eq 'vel' then begin
        if keyword_set(ignore_dlimits) then begin
          dprint,'WARNING: dlimits indicates data is a velocity.  Full transformation between SSE coords requires offset that will not be performed because IGNORE_DLIMITS is set'
        endif else begin
          
          deriv_data,lun_name,/replace
                  
          tinterpol_mxn,lun_name,name_two,/overwrite,error=err
          
          if err eq 0 then begin
            message,'Error performing velocity offset during SSE transformation(interpolation operation)'
          endif
          
          calc,'"'+name_two+'" = "' + name_two + '"+"'+lun_name+'"',error=err
          if keyword_set(err) then begin
            message,'Error performing velocity offset during SSE transformation(subtraction operation)'
          endif
          
        endelse
      endif else if st_type eq 'acc' then begin
        dprint,'WARNING dlimits indicates data is an acceleration.  Full transformation between SSE coords requires offset that must be performed manually.'
      endif   

    endif else begin    ; end of tplotvar if statement

      if ~keyword_set(ROTATION_ONLY) then begin
      
        lun_gse_struc = {x:lun_gse_arr[*,0], y:lun_gse_arr[*,1:3]}
        tinterpol_mxn,lun_gse_struc,name_one[*,0],out=lun_gse_new,error=err

        if err eq 0 then begin
          message,'Error performing position offset during SSE transformation(interpolation operation)'
        endif
        
        name_out = dblarr(n_elements(lun_gse_new.x),4)
        name_out[*,0]=lun_gse_new.x
        name_out[*,1]=lun_gse_new.y[*,0]+name_one[*,1]
        name_out[*,2]=lun_gse_new.y[*,1]+name_one[*,2]
        name_out[*,3]=lun_gse_new.y[*,2]+name_one[*,3]
      endif 
        
    endelse     ; end of vector data if statement

  endif     ; end of sse2gse conversion
  
end

