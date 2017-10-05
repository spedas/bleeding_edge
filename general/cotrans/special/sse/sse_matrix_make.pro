
;+
;PROCEDURE: sse_matrix_make
;
;Purpose:
;  Creates a set of matrices that will rotate data from GSE coordinate to SSE coordinate
;Arguments: 
;Inputs:
; name_sun_pos_gse: Name of the tplot variable(s) storing the sun position or
;                   as vector data (should be of the form [t,x,y,z] 
; 
; name_lun_pos_gse: Name of the tplot variable(s) storing the lunar position or
;                   as vector data (should be of the form [t,x,y,z] 
;      
; Input names can have globbing or can be arrays of names, but number of elements for
; sun_pos and and lun_pos after globbing must match.
;      
;Outputs:
;  fail: Will be set to 1 if operation failed, returns 0 if operation succeeded.  Will not signal failure if
;        at least one input was processed.
;        
;        
;Keywords
;  suffix: The suffix to be appended to the tplot variables that the output matrices will be stored in.
;         (Default: name_sun_pos_gse + '_sse_mat')
;  newname: The name of the output matrix.  If this keyword is used with multiple input values, the outputs
;          may overwrite each other.  So you should only set this keyword if there is 
;          a single value for the state input. This should be set if vector data is
;          input.
;  ignore_dlimits: If set, will force routine to generate matrix, even if inputs are 
;          labeled as the wrong coordinate system. This flag is ignored if vector data
;          is input.
;         
;Example:
;  timespan,'2007-03-23'
;  thm_load_slp
;  cotrans,'slp_sun_pos','slp_sun_pos_gse',/gei2gse
;  cotrans,'slp_lun_pos','slp_lun_pos_gse',/gei2gse
;  sse_matrix_make,'slp_sun_pos_gse','slp_lun_pos_gse',newname='sse_mat'
;  thm_load_state,probe='a',coord='gse'
;  tvector_rotate,'sse_mat','tha_state_pos'
; 
;  Or for vector data
;
;  sse_matrix_make,sun_pos_gse,lun_pos_gse,newname=sse_mat
;
;NOTES:
;  #1 SSE is defined as:
;        X: Moon->Sun Line
;        Y: Ecliptic North cross X
;        Z: X cross Y
;  #2 SSE coordinate Z-axis is generally not exactly parallel to ecliptic north,
;      as the moon will not always be in the ecliptic plane, and thus the moon->sun line
;      will not always lie in the ecliptic plane.
;      
;  #3  If times in sun_pos_gse and lun_pos_gse do not match,
;  data will be interpolated to match the time grid in sun_pos_gse.
;  
;  #4  If sun_pos_gse begins before or ends after lun_pos_gse, then lun_pos_gse
;  will be extrapolate with NaNs.  This means the that no valid transformations
;  will be available on the intervals where both quantities are not available. 
;
;
;Written by Jenni Kissinger and Patrick Cruce
;
;
;
; $LastChangedBy: cgoethel $
; $LastChangedDate: 2011-11-15 12:50:08 -0800 (Tue, 15 Nov 2011) $
; $LastChangedRevision: 9298 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/special/sse/sse_matrix_make.pro $
;-

pro sse_matrix_make,name_sun_pos_gse,name_lun_pos_gse,newname=newname,suffix=suffix,fail=fail,ignore_dlimits=ignore_dlimits

  fail = 1

  ; check for the the type of data that was input since
  ; tplot variables are handled differently than vector data
  if size(name_sun_pos_gse, /type) eq 7 then tplotvar=1 else tplotvar=0

  if tplotvar then begin
  
      if n_params() ne 2 then begin
        dprint,'ERROR: Requires two parameters'
        return
      endif
      
      sun_varnames = tnames(name_sun_pos_gse)
    
      if n_elements(sun_varnames) eq 1 && sun_varnames[0] eq '' then begin
        dprint,'ERROR: name_sun_pos_gse not a valid tplot variable'
        return
      endif
      
      lun_varnames = tnames(name_lun_pos_gse)
    
      if n_elements(lun_varnames) eq 1 && lun_varnames[0] eq '' then begin
        dprint,'ERROR: name_lun_pos_gse not a valid tplot variable'
        return
      endif
    
      if n_elements(sun_varnames) ne n_elements(lun_varnames) then begin
        dprint,'ERROR: Number of solar and lunar positions does not match'
        return
      endif
    
      if ~keyword_set(suffix) then begin
        suffix = '_sse_mat'
      endif
      
      for i = 0,n_elements(sun_varnames)-1 do begin
     
         coord = cotrans_get_coord(sun_varnames[i])
         
         if coord[0] eq 'unknown' then begin
           dprint,'Warning: ' + sun_varnames[i] + ' coordinate system unknown.  Please be certain input is in GSM coordinates.'
         endif else if coord[0] ne 'gse' then begin
           dprint,sun_varnames[i] + ' is not in GSE coordinates.  Skipping variable.'
           continue
         endif
     
         coord = cotrans_get_coord(lun_varnames[i])
         
         if coord[0] eq 'unknown' then begin
           dprint,'Warning: ' + lun_varnames[i] + ' coordinate system unknown.  Please be certain input is in GSM coordinates.'
         endif else if coord[0] ne 'gse' then begin
           dprint,lun_varnames[i] + ' is not in GSE coordinates.  Skipping variable.'
           continue
         endif
     
         tinterpol_mxn,lun_varnames[i],sun_varnames[i],/nan_extrapolate,out=lun_pos_gse,error=err
         
         if err eq 0 then begin
           dprint,'ERROR interpolating moon position'
           return
         endif
     
         get_data,sun_varnames[i],data=sun_pos_gse,dlimits=dl,limits=l
    
         str_element,sun_pos_gse,'y',success=s
         if s eq 0 then begin
           dprint,sun_varnames[i] + ' is malformed tplot variable.(No Y component)
           continue
         endif
         
         str_element,sun_pos_gse,'x',success=s
         if s eq 0 then begin
           dprint,sun_varnames[i] + ' is malformed tplot variable.(No x component)
           continue
         endif
         
         str_element,lun_pos_gse,'y',success=s
         if s eq 0 then begin
           dprint,lun_varnames[i] + ' is malformed tplot variable.(No Y component)
           continue
         endif
         
         str_element,lun_pos_gse,'x',success=s
         if s eq 0 then begin
           dprint,lun_varnames[i] + ' is malformed tplot variable.(No x component)
           continue
         endif
    
         sun_pos_dim = dimen(sun_pos_gse.y)
         
         if n_elements(sun_pos_dim) ne 2 || sun_pos_dim[1] ne 3 then begin
           dprint,sun_varnames[i] + ' is malformed tplot variable.(Wrong dimensions)
           continue
         endif
         
         lun_pos_dim = dimen(lun_pos_gse.y)
         
         if n_elements(lun_pos_dim) ne 2 || lun_pos_dim[1] ne 3 then begin
           dprint,lun_varnames[i] + ' is malformed tplot variable.(Wrong dimensions)
           continue
         endif
         
         out_data = dblarr(sun_pos_dim[0],3,3)
         
    ; original version, using angular rotation in the ecliptic plane
    ;     
    ;     lun_sun_distance_xy = SQRT((lun_pos_gse.y[*,1])^2+(sun_pos_gse.y[*,0]-lun_pos_gse.y[*,0])^2)
    ;     xyangle = ASIN(lun_pos_gse.y[*,1]/lun_sun_distance_xy)
    ;     
    ;     ;X basis vector
    ;     out_data[*,0,0] = cos(xyangle)
    ;     out_data[*,0,1] = sin(xyangle)
    ;     ;out_data[*,0,2] = 0  ;not needed, since initialized to 0, line here for clarity
    ;     ;Y basis vector
    ;     out_data[*,1,0] = -sin(xyangle)
    ;     out_data[*,1,1] = cos(xyangle)
    ;     ;out_data[*,1,2] = 0 ;not needed, since initialized to 0, line here for clarity
    ;     ;Z basis vector
    ;     ;out_data[*,2,0] = 0 ;not needed, since initialized to 0, line here for clarity
    ;     ;out_data[*,2,1] = 0 ;not needed, since initialized to 0, line here for clarity
    ;     out_data[*,2,2] = 1
    
         
    
    ; new version uses cross product methodology, will not necessarily
    ; rotate only in the ecliptic plane.
    
    
         ;X basis vector
         
         ;normalize vector pointing from moon to sun
         tnormalize,sun_pos_gse.y-lun_pos_gse.y,out=x_axis
         out_data[*,0,*] = x_axis
         
         ;Y basis vector
         
         ecliptic_north = transpose(rebin([0,0,1],3,sun_pos_dim[0]))
         tcrossp,ecliptic_north,x_axis,out=y_axis
         tnormalize,y_axis,out=y_axis
         out_data[*,1,*] = y_axis
         
         ;Z basis vector
         
         tcrossp,x_axis,y_axis,out=z_axis
         out_data[*,2,*] = z_axis ;no need to normalize.  Axes should already be orthogonal
         
         str_element,dl,'labflag',value=0,/add_replace
         str_element,dl,'data_att.coord_sys','sse',/add_replace
         str_element,dl,'data_att.source_sys','gse',/add_replace
         
         if ~keyword_set(newname) then begin
           store_data,varnames[i]+suffix,data={x:sun_pos_gse.x,y:out_data},dlimits=dl,limits=l
         endif else begin
           store_data,newname,data={x:sun_pos_gse.x,y:out_data},dlimits=dl,limits=l
         endelse
         
      endfor

  endif else begin   ; end of tplotvar if statement

    sun_pos_gse = {x:name_sun_pos_gse[*,0], y:name_sun_pos_gse[*,1:3]}
    lun_pos_gse = {x:name_lun_pos_gse[*,0], y:name_lun_pos_gse[*,1:3]}    
    tinterpol_mxn,lun_pos_gse,sun_pos_gse.x,/nan_extrapolate,out=lun_pos_gse,error=err
    sun_pos_dim = dimen(sun_pos_gse.y)
    lun_pos_dim = dimen(lun_pos_gse.y)
    out_data = dblarr(sun_pos_dim[0],3,3)
 
    ;X basis vector       
    ;normalize vector pointing from moon to sun       
    tnormalize,sun_pos_gse.y-lun_pos_gse.y,out=x_axis 
    out_data[*,0,*] = x_axis
       
   ;Y basis vector       
    ecliptic_north = transpose(rebin([0,0,1],3,sun_pos_dim[0]))
    tcrossp,ecliptic_north,x_axis,out=y_axis
    tnormalize,y_axis,out=y_axis
    out_data[*,1,*] = y_axis
       
    ;Z basis vector     
    tcrossp,x_axis,y_axis,out=z_axis
    out_data[*,2,*] = z_axis ;no need to normalize.  Axes should already be orthogonal
     
    newname=out_data
     
  endelse   ; end of vector data if statement

  fail = 0

end