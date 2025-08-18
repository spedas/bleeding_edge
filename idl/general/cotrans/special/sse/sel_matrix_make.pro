;+
;PROCEDURE: sel_matrix_make
;
;Purpose:
;  Creates a set of matrices that will rotate data from SSE coordinate to SEL coordinate
;Arguments: 
;Inputs:
; name_lun_att_x: Name of the tplot variable(s) storing the SEL-X basis vectors in 
;                 GEI coords. Vector data can also be input and should be of the 
;                 form [t,x,y,z] .
; 
; name_lun_att_z: Name of the tplot variable(s) storing the SEL-Z basis vectors in 
;                 GEI coords. Vector data can also be input and should be of the 
;                 form [t,x,y,z].
;      
; Input names can have globbing or can be arrays of names, but number of elements for
; lun_att_x and and lun_att_z after globbing must match.
;      
;Outputs:
;  fail: Will be set to 1 if operation failed, returns 0 if operation succeeded.  Will not signal failure if
;        at least one input was processed.
;        
;        
;Keywords
;  suffix: The suffix to be appended to the tplot variables that the output matrices will be stored in.
;         (Default: sse_sel_mat)
;  newname: The name of the output matrix.  If this keyword is used with multiple input values, the outputs
;          may overwrite each other.  So you should only set this keyword if there is 
;          a single value for the state input. This variable should be used if  
;          vector data is input
;  ignore_dlimits: If set, will force routine to generate matrix, even if inputs are 
;          labeled as the wrong coordinate system. This flag is ignored if vector
;          data in input.
;         
;Example:
;
;  timespan,'2007-03-23'
;  thm_load_slp
;  sel_matrix_make,'slp_lun_att_x','slp_lun_att_z',newname='sel_mat'
;  thm_load_state,probe='a'
;  thm_cotrans,'tha_pos',out_coord='sse',out_suff='_sse'
;  tvector_rotate,'sel_mat','tha_state_pos_sse'
; 
;  Or if using vector data
;
;  sel_matrix_make,lun_att_x,lun_att_z,newname=sel_mat
;
;
;NOTES:
;  #1 SEL is defined as:
;        X: TBD
;        Y: TBD
;        Z: TBD
;  
;
;Adapted from sse_matrix_make, written by Jenni Kissinger and Patrick Cruce
;
;
;
; $LastChangedBy: cgoethel $
; $LastChangedDate: 2011-11-15 12:50:08 -0800 (Tue, 15 Nov 2011) $
; $LastChangedRevision: 9298 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/special/sse/sel_matrix_make.pro $
;-


pro sel_matrix_make,name_sun_pos,name_moon_pos,name_lun_att_x,name_lun_att_z,newname=newname,suffix=suffix,fail=fail,ignore_dlimits=ignore_dlimits

  fail = 1
  
  if n_params() ne 4 then begin
    dprint,'ERROR: Requires two parameters'
    return
  endif
  
  if size(name_sun_pos, /type) eq 7 then tplotvar=1 else tplotvar=0
  
  if tplotvar then begin
  
      att_x_varnames = tnames(name_lun_att_x)
    
      if n_elements(att_x_varnames) eq 1 && att_x_varnames[0] eq '' then begin
        dprint,'ERROR: name_lun_att_x not a valid tplot variable'
        return
      endif
      
      att_z_varnames = tnames(name_lun_att_z)
    
      if n_elements(att_z_varnames) eq 1 && att_z_varnames[0] eq '' then begin
        dprint,'ERROR: name_lun_att_z not a valid tplot variable'
        return
      endif
    
      if n_elements(att_x_varnames) ne n_elements(att_z_varnames) then begin
        dprint,'ERROR: Number of solar and lunar positions does not match'
        return
      endif
    
      if ~keyword_set(suffix) then begin
        suffix = '_sel_mat'
      endif
      
      for i = 0,n_elements(att_x_varnames)-1 do begin
     
         coord = cotrans_get_coord(att_x_varnames[i])
         
         if coord[0] eq 'unknown' then begin
           dprint,'Warning: ' + att_x_varnames[i] + ' coordinate system unknown.  Please be certain input is in GEI coordinates.'
         endif else if coord[0] ne 'gei' then begin
           dprint,att_x_varnames[i] + ' is not in GEI coordinates.  Skipping variable.'
           continue
         endif
     
         coord = cotrans_get_coord(att_z_varnames[i])
         
         if coord[0] eq 'unknown' then begin
           dprint,'Warning: ' + att_z_varnames[i] + ' coordinate system unknown.  Please be certain input is in GEI coordinates.'
         endif else if coord[0] ne 'gei' then begin
           dprint,att_z_varnames[i] + ' is not in GEI coordinates.  Skipping variable.'
           continue
         endif
     
         get_data,att_x_varnames[i],data=att_x_gei,dlimits=dl,limits=l
    
         str_element,att_x_gei,'y',success=s
         if s eq 0 then begin
           dprint,att_x_varnames[i] + ' is malformed tplot variable.(No Y component)
           continue
         endif
         
         str_element,att_x_gei,'x',success=s
         if s eq 0 then begin
           dprint,att_x_varnames[i] + ' is malformed tplot variable.(No x component)
           continue
         endif
         
         get_data,att_z_varnames[i],data=att_z_gei,dlimits=dl,limits=l
    
         str_element,att_z_gei,'y',success=s
         if s eq 0 then begin
           dprint,att_z_varnames[i] + ' is malformed tplot variable.(No Y component)
           continue
         endif
         
         str_element,att_z_gei,'x',success=s
         if s eq 0 then begin
           dprint,att_z_varnames[i] + ' is malformed tplot variable.(No x component)
           continue
         endif
    
         att_x_dim = dimen(att_x_gei.y)
         
         if n_elements(att_x_dim) ne 2 || att_x_dim[1] ne 3 then begin
           dprint,att_x_varnames[i] + ' is malformed tplot variable.(Wrong dimensions)
           continue
         endif
         
         att_z_dim = dimen(att_z_gei.y)
         
         if n_elements(att_z_dim) ne 2 || att_z_dim[1] ne 3 then begin
           dprint,att_z_varnames[i] + ' is malformed tplot variable.(Wrong dimensions)
           continue
         endif
         
         out_data = dblarr(att_x_dim[0],3,3)
         
    ; original version, using angular rotation in the ecliptic plane
    ;     
    ;     lun_sun_distance_xy = SQRT((att_z_gei.y[*,1])^2+(att_x_gei.y[*,0]-att_z_gei.y[*,0])^2)
    ;     xyangle = ASIN(att_z_gei.y[*,1]/lun_sun_distance_xy)
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
         
         ;normalize X basis vector
         tnormalize,att_x_varnames[i],newname='sel_x_gei'
         cotrans,'sel_x_gei','sel_x_gse',/gei2gse
    
         ; Note that since sel_x_gse is *not* marked as a "position" variable
         ; via its dlimits, gse2sse will only do the rotation, and not
         ; the translation from geocentric to selenocentric coordinates.
         ; That happens to be exactly what we want here, and for
         ; sel_z_gse below.
    
         gse2sse,'sel_x_gse',name_sun_pos,name_moon_pos,'sel_x_sse',ignore_dlimits=ignore_dlimits
         get_data,'sel_x_sse',data=x_axis
         out_data[*,0,*] = x_axis.y
        
         ;Z basis vector
         
         tnormalize,att_z_varnames[i],newname='sel_z_gei'
         cotrans,'sel_z_gei','sel_z_gse',/gei2gse
         gse2sse,'sel_z_gse',name_sun_pos,name_moon_pos,'sel_z_sse',ignore_dlimits=ignore_dlimits
         get_data,'sel_z_sse',data=z_axis
         out_data[*,2,*] = z_axis.y
         
         ;Y basis vector
         
         tcrossp,'sel_z_sse','sel_x_sse',newname='sel_y_sse'
         get_data,'sel_y_sse',data=y_axis
         out_data[*,1,*] = y_axis.y ;no need to normalize.  Axes should already be orthogonal
         
         str_element,dl,'labflag',value=0,/add_replace
         str_element,dl,'data_att.coord_sys','sel',/add_replace
         str_element,dl,'data_att.source_sys','sse',/add_replace
         
         if ~keyword_set(newname) then begin
           store_data,att_x_varnames[i]+suffix,data={x:att_x_gei.x,y:out_data},dlimits=dl,limits=l
         endif else begin
           store_data,newname,data={x:att_x_gei.x,y:out_data},dlimits=dl,limits=l
         endelse
         
      endfor


  endif else begin ; end of tplot var

         att_x_dim = dimen(name_lun_att_x)
         out_data = dblarr(att_x_dim[0],3,3)

         ;X basis vector         
         ;normalize X basis vector
         tnormalize,name_lun_att_x[*,1:3],out=sel_x_gei
         cotrans,sel_x_gei,sel_x_gse,name_lun_att_x[*,0],/gei2gse
         sel_x = name_lun_att_x
         sel_x[*,1:3]=sel_x_gse
         gse2sse,sel_x,name_sun_pos,name_moon_pos,sel_x_sse, /rotation_only
         out_data[*,0,*] = sel_x_sse[*,1:3]
       
         ;Z basis vector         
         tnormalize,name_lun_att_z[*,1:3],out=sel_z_gei
         cotrans,sel_z_gei,sel_z_gse,name_lun_att_z[*,0],/gei2gse
         sel_z = name_lun_att_z
         sel_z[*,1:3]=sel_z_gse
         gse2sse,sel_z,name_sun_pos,name_moon_pos,sel_z_sse,/rotation_only
         out_data[*,2,*] = sel_z_sse[*,1:3]
        
         ;Y basis vector
         tcrossp,sel_z_sse[*,1:3],sel_x_sse[*,1:3],out=sel_y_sse
         out_data[*,1,*] = sel_y_sse ;no need to normalize.  Axes should already be orthogonal

         newname = out_data
          
  endelse  ; end of vector data
  
  fail = 0

end
