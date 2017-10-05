;+
;Procedure: enp_matrix_make
;
;Purpose: 
;  Creates a set of matrices that will rotate data from the input coordinate system into
;  ENP.(ie creates a GEI->ENP transformation matrix),
;  You can use the invert keyword on tvector rotate to go from ENP->GEI
;   E: sat to earth (in orbtial plane)
;   N: east (in orbital plane)
;   P: north (perpendicular to orbtial plane).
;
;  Defined relative to another coordinate system:
;   P_sat = spacecraft position in geocentric inertial coordinate system
;   V_sat = deriv(P_sat)   (spacecraft velocity in the same coordinate system.)
;
;   P_enp = P_sat cross V_sat
;   E_enp = -P_sat
;   N_enp = P_enp cross P_sat
;   
;Inputs:
;  pos_tvarname:  Tplot Variable storing the spacecraft position in an intertial earth-centered cartesian coordinate system(like gei)
;                 You can use globbing to pass multiple position vectors simultaneously. ('th?_state_pos')  
;  
;Outputs: 
;  xxx2enp transformation matrix
;  
; Keywords:
;
;   fail=fail: Will be set to 1 if operation failed, returns 0 if operation succeeded.  Will not signal failure if
;        at least one input was processed.
;  suffix: The suffix to be appended to the tplot variables that the output matrices will be stored in.
;         (Default: '_enp_mat' or '_pen_mat')
;  newname: The name of the output matrix.  If this keyword is used with multiple input values, the outputs
;          may overwrite each other.  So you should only set this keyword if there is a single value for the state input.
;  velocity_tvar:  Set this keyword to the name of a tplot variable or variables that store velocities matching the positions.
;           This way the routine doesn't need to calculate the velocity using derivatives  
;   
;  orbital_elements: Set this keyword to a 3-element array with orbital elements so the transformation can be generated without reference to the velocity at all.
;                    If this keyword is set, this method will take precedence over velocity_tvar method, or position derivative method.
;     orbital_elements[0] = time in double precision seconds since 1970, (can use time_double('2007-03-23') to generate)                 
;     orbital_elements[1] = right ascension of the ascending node and
;     orbital_elements[2] = inclination
;     
;     Can also pass in a 2xN element array if you want orbital elements
;     to be interpolated to the specific time. Finally, can be a
;     2xNxM element array, if you want to provide orbital elements for each tplot variable being processed.
;     
;     
;Examples:
;
;  enp_matrix_make,'g10_pos_gei'
;  tvector_rotate,'g10_pos_gei_enp_mat','g10_b_gei'  ;GEI->ENP
;  -OR-
;  tvector_rotate,'g10_pos_gei_enp_mat','g10_b_enp',/invert ;ENP->GEI
;  
;  See ssl_general/cotrans/special/enp/enp_crib.pro
;   
;Notes:
;  1. Because velocity is calculated using the derivative of position,
;  there should be a small numerical error at the end points of the time series
;  
;  2. Orbital elements method is based upon technique from Paul Lotaniu's C-based GEI2ENP transformation.
;
;  3. Note, the assumption of constant orbital elements means there will be an error at the GEI-POS-Z 0-crossing, that
;  is proportional to the error in the orbital elements, if the single orbital element method is used.
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2010-10-26 16:26:08 -0700 (Tue, 26 Oct 2010) $
; $LastChangedRevision: 7886 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/special/enp/enp_matrix_make.pro $
;-

;propagate orbital elements
pro enp_matrix_propagate_orbit,tms,elements,ras=ras,inc=inc

  compile_opt idl2,hidden

  dim = dimen(elements)

  if n_elements(dim) eq 1 then begin
    ras = elements[1]
    inc = elements[2]
  endif else begin
  
    otms = reform(elements[0,*])
    ras = interpol(reform(elements[1,*]),otms,tms)
    inc = interpol(reform(elements[2,*]),otms,tms)
  
  endelse

end

pro enp_matrix_make,pos_tvarname,fail=fail,suffix=suffix,newname=newname,velocity_tvar=velocity_tvar,orbital_elements=orbital_elements

  compile_opt idl2
  
  fail = 1
  
  if ~keyword_set(pos_tvarname) then begin
    dprint,'pos_tvarname not set'
    return
  endif
  
  varnames = tnames(pos_tvarname)
  
  if varnames[0] eq '' then begin
    dprint,'Failed, no tvars match pos_tvarname'
    return
  endif
  
  if keyword_set(velocity_tvar) then begin
    velnames = tnames(velocity_tvar)
    
    if velnames[0] eq '' then begin
      dprint,'Failed, velocity_tvar is invalid tplot variable.'
      return
    endif
    
    if n_elements(velnames) ne n_elements(varnames) then begin
      dprint,'Failed, number of position tvars and velocity tvars does not match'
      return
    endif
  
  endif

  if ~keyword_set(suffix) then begin
    suffix = '_enp_mat' 
  endif
  
  if keyword_set(orbital_elements) then begin
   
    if ~is_num(orbital_elements) then begin
      dprint,'Failed, orbital_elements has illegal type'
      return
    endif
    
    orb_dim = dimen(orbital_elements)
    
    if orb_dim[0] ne 3 then begin
      dprint,'Failed, orbital_elements has wrong dimensions
      return
    endif
    
    if n_elements(orb_dim) eq 3 && orb_dim[2] ne n_elements(varnames) && orb_dim[2] ne 1 then begin
      dprint,'Failed, number of orbital_elements provided must match number of variables being transformed'
      return
    endif
    
  endif
  
  for i = 0,n_elements(varnames)-1 do begin
  
    undefine,vdata
  
    source_sys = cotrans_get_coord(varnames[i])
    
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
    
    dData = double(d.y)
    
    undefine,d      
  
    if n_elements(dim) ne 2 || dim[1] ne 3 || dim[0] eq 1 then begin
      dprint,varnames[i] + ' data component has incorrect dimensions. Skipping variable.'
      continue
    endif
  
    ; Method is based upon technique from Paul Lotaniu's C-based GEI2ENP transformation.
    if keyword_set(orbital_elements) then begin
    
      out = dblarr(dim[0],3,3)
      
      if n_elements(orb_dim) eq 3 then begin
        eles = reform(orbital_elements[*,*,i])
      endif else begin
        eles = orbital_elements
      endelse
      
      enp_matrix_propagate_orbit,tData,eles,ras=ras,inc=inc
            
      cosi=cos(inc*!DTOR)
      sini=sin(inc*!DTOR)
      cosnod=cos(ras*!DTOR)
      sinnod=sin(ras*!DTOR)
      rs=sqrt(total(dData^2,2))
      cosw = (dData[*,0]/rs)*cosnod + (dData[*,1]/rs)*sinnod
      sinw = -(dData[*,0]/rs)*sinnod + (dData[*,1]/rs)*cosnod
              
      out[*,0,0] = -cosnod*cosw + sinnod*sinw*cosi
      out[*,0,1] = -cosnod*sinw - sinnod*cosw*cosi
      out[*,0,2] =  sinnod*sini
      out[*,1,0] = -sinnod*cosw - cosnod*sinw*cosi
      out[*,1,1] = -sinnod*sinw + cosnod*cosw*cosi
      out[*,1,2] = -cosnod*sini
      out[*,2,0] = -sini*sinw
      out[*,2,1] =  sini*cosw
      out[*,2,2] =  cosi

      ;the transform above is enp->gei
      out = transpose(out,[0,2,1])

    endif else begin
    
      if ~keyword_set(velnames) then begin
        velData = dblarr(dim)
      
        velData[*,0] = deriv(tData,dData[*,0])
        velData[*,1] = deriv(tData,dData[*,1])
        velData[*,2] = deriv(tData,dData[*,2])
      endif else begin
      
        tinterpol_mxn,velnames[i],varnames[i],out=d
        
        if ~is_struct(d) then begin
          dprint,velnames[i] + ' does not have a valid data component.  Skipping variable.'
          continue
        endif
      
        if ~in_set(strlowcase(tag_names(d)),'y') then begin
          dprint,velnames[i] + ' does not have a valid data component.  Skipping variable.'
          continue
        endif
  
        velData = d.y
       
      endelse
        
      tcrossp,dData,velData,out=pData
      eData = -dData
      tcrossp,pData,dData,out=nData
      
      ;waits till the end to normalize, cross products produce reliable directions indepedent of vector magnitude
      tnormalize,pData,out=pUnit
      tnormalize,eData,out=eUnit
      tnormalize,nData,out=nUnit
      
      out = dblarr(dim[0],3,3)

      out[*,0,*] = eUnit
      out[*,1,*] = nUnit
      out[*,2,*] = pUnit
     
    endelse
    
    if n_elements(vData) gt 0 then begin
      outd = {x:temporary(tData),y:temporary(out),v:temporary(vData)}
    endif else begin
      outd = {x:temporary(tData),y:temporary(out)}
    endelse
   
    ;tvector rotate uses this flag to determine if it should take axes
    ;labels from the transformation matrix
   
    str_element,dl,'labflag',value=0,/add_replace
    str_element,dl,'data_att.coord_sys',coord_sys,/add_replace
    str_element,dl,'data_att.source_sys',source_sys,/add_replace
    
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