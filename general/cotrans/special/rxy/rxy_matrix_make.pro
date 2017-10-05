;+
;PROCEDURE: rxy_matrix_make
;
;Purpose:
;  Creates a set of matrices that will rotate data from GSM coordinates into a GSM coordinate system variant with the X axis of the X-Y plane pointing along the earth->spacecraft direction.
;  Specifically:
;  X-Axis: Radial position vector projected into the X-Y plane of the GSM coordinate system, and normalized to length = 1, Positive values point from Earth to Spacecraft.
;  Z-Axis: Z-axis of the GSM coordinate system
;  Y-Axis: X x Z(X cross Z, cross product of X & Z)
;  
;Arguments: 
;Inputs:
;  state:  The name of a tplot variable or variables that will be used to create the transformation matrices.
;             These data must be in GSM coordinates for the operation to work correctly.  Can use globbing('?',or '*') in
;             names, can use tplot variable indexes, can pass arrays of inputs.
;      
;Outputs:
;  fail: Will be set to 1 if operation failed, returns 0 if operation succeeded.  Will not signal failure if
;        at least one input was processed.
;        
;        
;Keywords
;  suffix: The suffix to be appended to the tplot variables that the output matrices will be stored in.
;         (Default: '_rxy_mat')
;  newname: The name of the output matrix.  If this keyword is used with multiple input values, the outputs
;          may overwrite each other.  So you should only set this keyword if there is a single value for the state input.
;         
;Example:
;  timespan,'2007-03-23'
;  thm_load_state,probe='a',coord='gsm'
;  rxy_matrix_make,'tha_state_pos'
;  thm_load_fgm,probe='a',coord='gsm'
;  tvector_rotate,'tha_state_pos_rxy_mat','tha_fgs_gsm'
;
;
;NOTES:
;    Code heavily based on make_mat_Rxy.pro & transform_gsm_to_rxy.pro by Christine Gabrielse(cgabrielse@ucla.edu)
;
;
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2009-09-15 15:55:43 -0700 (Tue, 15 Sep 2009) $
; $LastChangedRevision: 6734 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/special/rxy/rxy_matrix_make.pro $
;-

;helper function

pro rxy_matrix_make,state,fail=fail,suffix=suffix,newname=newname

  compile_opt idl2

  fail = 1

  if ~keyword_set(state) then begin
    dprint,'Failed, state not set'
    return
  endif
  
  varnames = tnames(state)
  
  if varnames[0] eq '' then begin
    dprint,'Failed, no tvars match state'
    return
  endif
  
  if ~keyword_set(suffix) then begin
    suffix = '_rxy_mat'
  endif
  
  for i = 0,n_elements(varnames) - 1 do begin
  
    undefine,vdata
  
    coord = cotrans_get_coord(varnames[i])
    
    if coord[0] eq 'unknown' then begin
      dprint,'Warning: ' + varnames[i] + ' coordinate system unknown.  Please be certain input is in GSM coordinates.'
    endif else if coord[0] ne 'gsm' then begin
      dprint,varnames[i] + ' is not in GSM coordinates.  Skipping variable.'
      continue
    endif
 
    get_data,varnames[i],data=d,dlimits=dl,limits=l
    
    if ~is_struct(d) then begin
      dprint,varnames[i] + ' does not have a valid data component.  Skipping variable.'
      continue
    endif
  
    if ~in_set(strlowcase(tag_names(d)),'y') then begin
      dprint,varnames[i] + ' does not have a valid data component.  Skipping variable.'
      continue
    endif
    
    if ~in_set(strlowcase(tag_names(d)),'x') then begin
      dprint,varnames[i] + ' does not have a valid time component.  Skipping variable.'
      continue
    endif
    
    if in_set(strlowcase(tag_names(d)),'v') then begin
      vdata = d.v
    endif
    
    tdata = d.x
    
    dim = dimen(d.y)
    
    dData = d.y
       
    undefine,d      
    
    if n_elements(dim) ne 2 || dim[1] ne 3 then begin
      dprint,varnames[i] + ' data component has incorrect dimensions. Skipping variable.'
      continue
    endif
    
    dData[*,2] = 0           ;d.y[0,2] is set to zero so that xy is the radial projection on the xyplane
    
    tnormalize,dData,out=UnitX

    UnitZ = [0,0,1]
                 ;1440
    UnitZ = transpose(rebin(UnitZ,dim[1],dim[0]))  ;1440 x 3
  
    tcrossp,UnitZ,UnitX,out=UnitY

    ;generate output variable and store it
    out = dblarr(dim[0],3,3)
  
    out[*,0,*] = temporary(UnitX)
    out[*,1,*] = temporary(UnitY)
    out[*,2,*] = temporary(UnitZ)
     
    if n_elements(vData) gt 0 then begin
      outd = {x:temporary(tData),y:temporary(out),v:temporary(vData)}
    endif else begin
      outd = {x:temporary(tData),y:temporary(out)}
    endelse
  
    ;tvector rotate uses this flag to determine if it should take axes
    ;labels from the transformation matrix
   
    str_element,dl,'labflag',value=0,/add_replace
    str_element,dl,'data_att.coord_sys','rxy',/add_replace
    str_element,dl,'data_att.source_sys','gsm',/add_replace
  
    if ~keyword_set(newname) then begin
      store_data,varnames[i]+suffix,data=outd,dlimits=dl,limits=l
    endif else begin
      store_data,newname,data=outd,dlimits=dl,limits=l
    endelse
  
    success=1
  
  endfor
  
  ;if at least one output is processed,
  ;then set fail = 0
  if keyword_set(success) then begin
    fail = 0
  endif

end