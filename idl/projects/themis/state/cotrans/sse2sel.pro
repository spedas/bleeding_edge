;+
;procedure: sse2sel
;
;Purpose: Coordinate transformation between SSE & SEL coordinates(and the inverse)
;
;     SSE is defined as:
;        X: Moon->Sun Line
;        Y: Ecliptic North cross X
;        Z: X cross Y
;         
;     SEL is defined as:
;        X: TBD
;        Y: TBD
;        Z: TBD
;inputs:
;
;  name_in: 
;    Name of input tplot variable to be transformed
;    or as an array of data [t,x,y,z]
;  name_sun_pos:
;    Name of the sun position tplot variable in GEI coordinates
;    or as an array of data [t,x,y,z]
;  name_moon_pos:
;    Name of the moon position tplot variable in GEI coordinates
;    or as an array of data [t,x,y,z]
;  name_lun_att_x:
;    Name of the SEL X-axis tplot variable in GEI coordinates
;    or as an array of data [t,x,y,z]
;  name_lun_att_z:
;    Name of the SEL Z-axis tplot variable in GEI coordinates
;    or as an array of data [t,x,y,z]
;  name_out:
;    Name that the rotated variable should take.
;    
;keywords:
;
;   /SEL2SSE inverse transformation
;
;   /IGNORE_DLIMITS: Dlimits normally used to determine if coordinate
;   system is correct, to decide if position needs offset, or to 
;   stop incorrect transforms.  This option will stop this behavior. 
;   This keyword is only used with tplot variables and ignored if
;   array data is input
;
;Examples:
;
;      sse2sel,'tha_state_pos_sse','slp_sun_pos','slp_lun_pos','slp_lun_att_x','slp_lun_att_z','tha_state_pos_sel'
;      sse2sel,'tha_state_pos_sel','slp_sun_pos','slp_moon_pos','slp_lun_att_x','slp_lun_att_z','tha_state_pos_sse',/sel2sse,/ignore_dlimits
;
;      Or for vector data
;
;      sse2sel,pos_sse,sun_pos,lun_pos,lun_att_x,lun_att_z,pos_sel
;      sse2sel,pos_sel,sun_pos,lun_pos,lun_att_x,lun_att_z,pos_sse, /sel2sse
; 
;Notes:
;   #1 Uses tvector_rotate, and sse_matrix_make to perform the rotation.
;      tvector_rotate will also interpolate the rotation matrix onto the time-grid of the input.
;      Interpolation done using quaterions and the spherical linear interpolation algorithm (SLERP)
;   #2 If vector data is input the IGNORE_LIMITS keyword is not used.
;      
;Adapted from gse2sse, written by Jenni Kissinger and Patrick Cruce
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2012-06-04 10:25:21 -0700 (Mon, 04 Jun 2012) $
; $LastChangedRevision: 10492 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/state/cotrans/sse2sel.pro $
;-


pro sse2sel,name_in,name_sun_pos,name_moon_pos,name_lun_att_x,name_lun_att_z,name_out,sel2sse=sel2sse,ignore_dlimits=ignore_dlimits

  compile_opt idl2
  
  if n_params() ne 6 then begin
    message,'Aborted: Missing 1 or more required arguments: name_in,name_sun_pos,name_moon_pos,name_lun_att_x,name_lun_att_z,name_out
  end
  
  ; check the input data type (strings are tplot variables)
  if size(name_in, /type) eq 7 then tplotvar=1 else tplotvar=0
  
  if tplotvar then begin
  
      att_x_name = tnames(name_lun_att_x)
      att_z_name = tnames(name_lun_att_z)
      
      if n_elements(att_x_name) ne 1 || n_elements(att_z_name) ne 1 || att_x_name[0] eq '' || att_z_name[0] eq '' then begin
        message,'Aborted: Must load lunar attitude to perform this transformation (Load Routine:"thm_load_slp")'
      endif
    
      sun_pos_name=tnames(name_sun_pos)
      moon_pos_name=tnames(name_moon_pos)
      
      if n_elements(sun_pos_name) ne 1 || n_elements(moon_pos_name) ne 1 || sun_pos_name[0] eq '' || moon_pos_name[0] eq '' then begin
        message,'Aborted: Must load sun and moon positions to perform this transformation (Load Routine:"thm_load_slp")'
      endif
    
      get_data,name_in,dlimit=dl,data=in_d
      get_data,name_sun_pos,data=sun_pos_d,dlimit=sun_pos_dl
      get_data,name_moon_pos,data=moon_pos_d,dlimit=moon_pos_dl
      get_data,att_x_name,data=att_x_d,dlimit=att_x_dl
      get_data,att_z_name,data=att_z_d,dlimit=att_z_dl
    
      if ~is_struct(sun_pos_d) || ~is_struct(moon_pos_d) then begin
        message,'Aborted: Must load sun and moon positions to perform this transformation (Load Routine:"thm_load_slp")'
      endif
      
      if ~is_struct(att_x_d) || ~is_struct(att_z_d) then begin
        message,'Aborted: Must load lunar attitude to perform this transformation (Load Routine:"thm_load_slp")'
      endif
      
      if min(moon_pos_d.x,/nan)-min(in_d.x,/nan) gt 60*60 || max(in_d.x,/nan) - max(moon_pos_d.x,/nan) gt 60*60 then begin
        dprint,'NON-FATAL-ERROR: ' + name_moon_pos  + ' and ' + name_in + ' fail to overlap for time greater than 1 hour. Data may have significant interpolation errors.' 
      endif
      
      if min(sun_pos_d.x,/nan)-min(in_d.x,/nan) gt 60*60 || max(in_d.x,/nan) - max(sun_pos_d.x,/nan) gt 60*60 then begin
        dprint,'NON-FATAL-ERROR: ' + name_sun_pos  + ' and ' + name_in + ' fail to overlap for time greater than 1 hour. Data may have significant interpolation errors.' 
      endif
      
      if min(att_x_d.x,/nan)-min(in_d.x,/nan) gt 60*60 || max(in_d.x,/nan) - max(att_x_d.x,/nan) gt 60*60 then begin
        dprint,'NON-FATAL-ERROR: ' + att_x_name + ' and ' + name_in + ' fail to overlap for time greater than 1 hour. Data may have significant interpolation errors.' 
      endif
      
      if min(att_z_d.x,/nan)-min(in_d.x,/nan) gt 60*60 || max(in_d.x,/nan) - max(att_z_d.x,/nan) gt 60*60 then begin
        dprint,'NON-FATAL-ERROR: ' + att_z_name + ' and ' + name_in + ' fail to overlap for time greater than 1 hour. Data may have significant interpolation errors.' 
      endif
     
      sel_matrix_make,name_sun_pos,name_moon_pos,name_lun_att_x,name_lun_att_z,newname='sel_mat_cotrans',fail=fail,ignore_dlimits=ignore_dlimits
      
      if fail then begin
        message,'Failed to create SEL rotation matrix
      endif
    
      st_type = 'none'
      str_element,dl,'data_att.st_type',st_type
    
      name_one = name_in
      name_two = name_out
    
      if keyword_set(sel2sse) then dprint,'SEL->SSE' else dprint,'SSE->SEL'    
      tvector_rotate,'sel_mat_cotrans',name_one,newname=name_two,error=err,invert=keyword_set(sel2sse),/vector_skip_nonmonotonic,/matrix_skip_nonmonotonic
           if err eq 0 then begin
        message,'Error performing rotation during SEL transformation
      endif

   endif else begin    ; end of tplot var if statement

      sun_struc = {x:name_sun_pos[*,0], y:name_sun_pos[*,1:3]}
      tinterpol_mxn,sun_struc,name_in[*,0],out=sun_pos,error=err
      lun_struc = {x:name_moon_pos[*,0], y:name_moon_pos[*,1:3]}
      tinterpol_mxn,lun_struc,name_in[*,0],out=lun_pos,error=err
      lun_att_x_struc = {x:name_lun_att_x[*,0], y:name_lun_att_x[*,1:3]}
      tinterpol_mxn,lun_att_x_struc,name_in[*,0],out=lun_att_x,error=err
      lun_att_z_struc = {x:name_lun_att_z[*,0], y:name_lun_att_z[*,1:3]}
      tinterpol_mxn,lun_att_z_struc,name_in[*,0],out=lun_att_z,error=err
   
      sun_pos_arr = name_in
      sun_pos_arr[*,1:3] = sun_pos.y
      lun_pos_arr = name_in
      lun_pos_arr[*,1:3] = lun_pos.y
      att_x_arr = name_in
      att_x_arr[*,1:3] = lun_att_x.y
      att_z_arr = name_in
      att_z_arr[*,1:3] = lun_att_z.y
      
      sel_matrix_make,sun_pos_arr,lun_pos_arr,att_x_arr,att_z_arr,newname=sel_mat_cotrans,fail=fail,ignore_dlimits=ignore_dlimits

      if fail then begin
        message,'Failed to create SEL rotation matrix
      endif

      if keyword_set(sel2sse) then dprint,'SEL->SSE' else dprint,'SSE->SEL'
      tvector_rotate,sel_mat_cotrans,name_in[*,1:3],newname=name_two,error=err,invert=keyword_set(sel2sse),/vector_skip_nonmonotonic,/matrix_skip_nonmonotonic      

      if err eq 0 then begin
        message,'Error performing rotation during SEL transformation
      endif
      name_out=name_in
      name_out[*,1:3]=name_two
      
   endelse    ; end of vector data if statement
   
end
