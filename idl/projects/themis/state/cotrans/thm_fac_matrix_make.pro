;+
;Procedure: thm_fac_matrix_make
;
;Purpose:  generates a field aligned coordinate transformation matrix
;from an input B vector array(and sometimes a position vector array)
;then stores it in a tplot variable.
;
;This code has been modified from fac_matrix_make to handle input data that are
;in DSL coordinates.
;
;Arguments:
;   mag_var_name=the name of the tplot variable storing the magnetic field
;   vectors to be used in transformation matrix generation
;   pos_var_name(optional)=the name of the tplot variable storing the position
;   vectors to be used in transformation matrix generation
;   newname(optional)=the name of the tplot variable in which to store
;   the output
;   error(optional) = named variable that holds the error state of the
;   computation 1 = success 0 = failure
;   other_dim(optional) = the second axis for the field aligned
;   coordinate system.
;   probe=probe(optional) = string indicating the THEMIS probe for systems that use the DSL system.
;     If this keyword is not specified and probe name is required, thm_fac_matrix_make will infer the probe
;     from the 3rd letter of the magnetic field variable. (eg. 'tha_fgs_gsm')  If the tplot variable doesn't have
;     a probe label in the name, this can lead to very irregular behavior, so it is recommended that you
;     always specify probe.
;   
;   /DEGAP: Set to call TDEGAP to remove any gaps from the data. See TDEGAP for
;           for other options that can be invoked using the _extra keyword.
;           E.g. thm_fac_matrix_make, 'tha_fgs', other_dim='xgse', /degap, dt=3
;
;   ************For all transformations Z = B************
;
;   Warning about coordinate systems:
;   B field tplot variable must be in gse,gsm, or dsl coordinates,
;   depending on what transformation has been selected.
;   Position tplot variable must be in gei coordinates. Gei is the default coordinate
;   system of thm_load_state.
;
;   Warning:  The resulting transformation matrices will only correctly
;   transform data from the coordinate system of the input variable to
;   the field aligned coordinate system.  So if mag_var_name is in dsl
;   coordinates then you should only use the output matrices to transform
;   other data in dsl coordinates.
;
;
;   valid second coord(other_dim) options:
;
;         'Xgse', (DEFAULT) translates from gse or gsm into FAC
;                    Definition(works on GSE, or GSM):
;                    X Axis = on plane defined by Xgse - Z
;                    Second coordinate definition: Y = Z x X_gse
;                    Third coordinate, X completes orthogonal RHS
;                    (right hand system) triad: XYZ
;                    Note: X_gse is a unit vector pointing in direction from
;                          earth to the sun
;         'Rgeo',translate from geo into FAC using radial position vector
;                    Rgeo is radial position vector, positive radialy outwards.
;                    Second coordinate definition: Y = Z x Rgeo (eastward)
;                    Third coordinate, X completes orthogonal RHS XYZ.
;         'mRgeo',translate into FAC using radial position vector
;                    mRgeo is radial position vector, positive radially inwards.
;                    Second coordinate definition: Y = Z x mRgeo (westward)
;                    Third coordinate, X completes orthogonal RHS XYZ.
;         'Phigeo', translate into FAC using azimuthal position vector
;                    Phigeo is the azimuthal geo position vector, positive Eastward
;                    First coordinate definition: X = Phigeo x Z (positive outwards)
;                    Second coordinate, Y ~ Phigeo (eastward) completes orthogonal RHS XYZ
;         'mPhigeo', translate into FAC using azimuthal position vector
;                    mPhigeo is minus the azimuthal geo position vector; positive Westward
;                    First coordinate definition: X = mPhigeo x Z (positive inwards)
;                    Second coordinate, Y ~ mPhigeo (Westward) completes orthogonal RHS XYZ
;         'Phism', translate into FAC using azimuthal Solar Magnetospheric vector.
;                 Phism is "phi" vector of satellite position in SM coordinates.
;                 Y Axis = on plane defined by Phism-Z, normal to Z
;                 Second coordinate definition: X = Phism x Z
;                 Third completes orthogonal RHS XYZ
;         'mPhism', translate into FAC using azimuthal Solar Magnetospheric vector.
;                 mPhism is minus "phi" vector of satellite position in SM coordinates.
;                 Y Axis = on plane defined by Phism-Z, normal to Z
;                 Second coordinate definition: X = mPhism x Z
;                 Third completes orthogonal RHS XYZ
;         'Ygsm', translate into FAC using cartesian Ygsm position as other dimension.
;                 Y Axis on plane defined by Ygsm and Z
;                 First coordinate definition: X = Ygsm x Z
;                 Third completes orthogonal RHS XYZ
;         'Zdsl', translates from dsl into FAC
;                    Definition:
;                    X Axis = on plane defined by Zdsl - Z
;                    Second coordinate definition: X = Z x Zdsl 
;                    Third coordinate, Y completes orthogonal RHS
;                    (right hand system) triad: XYZ
; Example:
;  fac_matrix_make,'tha_fgs',other_dim='Xgse',pos_var_name='tha_pos',out_var_name='tha_fgs_fac_mat',probe='a'
;
;--> Should filter NaNs to supress floating point errors
;--> Contains coordinate transformation specific code, if new
;    coordinate systems are added, this code should be updated
;
;  See also:
;     thm_cotrans,cotrans_get_coord,tvector_rotate,minvar_matrix_make,fac_crib,thm_crib_fac
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2014-02-04 17:46:10 -0800 (Tue, 04 Feb 2014) $
; $LastChangedRevision: 14159 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/state/cotrans/thm_fac_matrix_make.pro $
;-

pro thm_fac_matrix_make,mag_var_name,other_dim=other_dim, pos_var_name=pos_var_name, $
                        newname=newname, error=error, degap=degap,probe=probe, _extra=ex

;the valid_coords array is positional...so the order of coordnames
;should match their processing order in the code below

if ~keyword_set(probe) then begin
  probe = strmid(mag_var_name,2,1)
endif

;valid_coords = ['xgse','rgeo','ygeo','ysm','ygsm']
;valid_coords = ['xgse','rgeo','mrgeo','phigeo','mphigeo','phism','mphism','ygsm']
valid_coords = ['xgse','rgeo','mrgeo','phigeo','mphigeo','phism','mphism','ygsm','zdsl']

error = 0

if not keyword_set(mag_var_name) then begin
    dprint,' fx requires mag_var_name to be set'

    return
endif

if tnames(mag_var_name) eq '' then begin
    dprint,' fx requires mag_var_name to be set'

    return
endif

if not keyword_set(other_dim) then begin
    other_dim='xgse'
endif

if not keyword_set(newname) then newname = mag_var_name + '_fac_mat'

other_dim_l = strlowcase(other_dim)

co_idx = where(strmatch(valid_coords, other_dim_l) ne 0)

if(co_idx[0] eq -1L) then begin
    dprint,' fx was passed an illegal output coordinate'+other_dim
    dprint,' fx requires output other_dim to be: ' + strjoin(valid_coords,',')

    return
end

get_data,mag_var_name,data=d,limits=l,dlimits=dl

;temp variable, needs to be here, cause if there are no gaps tdegap
;fails, otherwise tdegap will overwrite
store_data,mag_var_name+'_ctv_temp',data=d,limits=l,dlimits=dl

;remove any gaps in the data
if keyword_set(degap) then tdegap,mag_var_name,newname=mag_var_name+'_ctv_temp', _extra=ex


tnormalize,mag_var_name+'_ctv_temp',newname='fac_mat_z_temp',error=error_state

if error_state eq 0 then begin
    dprint,' fx failed to normalize magnetic field vector'

    return
endif

del_data,mag_var_name+'_ctv_temp'

get_data,'fac_mat_z_temp',data=d,dlimits=dl

d_s = size(d.y,/dimensions)

if(n_elements(d_s) ne 2 || d_s[1] ne 3) then begin
       dprint,' fx requires mag_var_name data to be an Nx3 Array'
       return
endif

;adding position variable validation
;2008/05/06
if keyword_set(pos_var_name) then begin
  if tnames(pos_var_name) eq '' then begin
     dprint,'illegal position tplot variable name'
     return
  endif

  if n_elements(tnames(pos_var_name)) ne 1 then begin
     dprint,'can only input a single position tplot variable'
     return
  endif

  if cotrans_get_coord(pos_var_name) ne 'gei' then begin
     dprint,'position tplot variable must be in gei coordinates'
     return
  endif

endif

case other_dim_l of

  ;rhs coordinates constructed on plane Xgse - B
  valid_coords[0] : begin

    if(dl.data_att.coord_sys ne 'gse' && $
       dl.data_att.coord_sys ne 'gsm' && $
       dl.data_att.coord_sys ne 'dsl') then begin

        dprint,' fx requires mag_var_name to be in GSE, GSM, or DSL to generate a Xgse field aligned coordinate matrix'
        return
    endif

    get_data,'fac_mat_z_temp',data=d,dlimits=dl

    ;constructs an array of unit vectors
    ;for use in generation of series of
    ;unit vector cross products
    x_axis = transpose(rebin([1D,0D,0D],3,n_elements(d.x)))

    str_element,d,'v',SUCCESS=s
    dl_temp=dl
    dl_temp.data_att.coord_sys = 'gse'

    if(s) then $
      store_data,'fac_mat_x_temp',data={x:d.x,y:x_axis,v:d.v},dlimits=dl_temp $
    else $
      store_data,'fac_mat_x_temp',data={x:d.x,y:x_axis},dlimits=dl_temp

    case dl.data_att.coord_sys of
     'gse' : ; no rotation required
     'gsm' : ; no rotation required
     'dsl' : begin
               thm_cotrans,'fac_mat_x_temp','fac_mat_x_temp',in_coord='gse',out_coord='dsl',$
                           probe=probe
             end
      else : begin
               dprint,' FX failed to rotate Xgse vector onto input mag field system'
               return
             end
    endcase

    tcrossp,'fac_mat_z_temp','fac_mat_x_temp',newname='fac_mat_y_temp',error=error_state

    if(error_state eq 0) then begin
         dprint,' FX  failed to create zx cross product in ' + valid_coords[0]
        return
    endif

    tnormalize,'fac_mat_y_temp',newname='fac_mat_y_temp',error=error_state

    if(error_state eq 0) then begin
         dprint,' FX  failed to create zx cross product in Xgse'
        return
    endif

    tcrossp,'fac_mat_y_temp','fac_mat_z_temp',newname='fac_mat_x_temp',error=error_state

    if(error_state eq 0) then begin
        dprint,' FX  failed to create yz cross product in Xgse'
        return
    endif

    str_element,dl,'labels',success=s1

    if s1 eq 1 then $
      dl.labels = ['Y x B','B x Xgse','B']

  end
  
  
  ;coordinates constructed on rhs coordinate system defined by B - Rgeo
  valid_coords[1] : begin

    if not keyword_set(pos_var_name) then begin
        dprint,' FX  requires pos_var_name to be set for Rgeo coordinate transformation'
        return
    endif

    if tnames(pos_var_name) eq '' then begin
        dprint,' FX  requires pos_var_name to be set for Rgeo coordinate transformation'
        return
    endif

    ;create temp variable so position vector is not overwritten
    get_data, pos_var_name, data=d_2,limits=l_2,dlimits=dl_2
    pos_var_name_temp = pos_var_name+'_temp'
    store_data, pos_var_name_temp, data=d_2,limits=l_2,dlimits=dl_2

    ;remove any gaps in the data
    if keyword_set(degap) then tdegap,pos_var_name_temp,newname=pos_var_name_temp, _extra=ex

    get_data,pos_var_name_temp,data=d_2,dlimits=dl_2

    d_2_s = size(d_2.y,/dimensions)

    if(n_elements(d_2_s) ne 2 || d_2_s[1] ne 3) then begin
        dprint,' FX  requires pos_var_name data to be an Nx3 Array'
        return
    endif

    if dl_2.data_att.coord_sys ne 'gei' then begin

      if dl_2.data_att.coord_sys eq 'dsl' then begin
        thm_cotrans,pos_var_name_temp,pos_var_name_temp,in_coord='dsl',out_coord='gei'
      endif else begin
        dprint,' FX  requires position data to be in gei or dsl coordinates to generate Rgeo transformation'
        return
      endelse

    endif

    tinterpol_mxn,pos_var_name_temp,'fac_mat_z_temp',newname='fac_mat_pos_temp',error=error_state

    if error_state eq 0 then begin
        dprint,' FX  failed to interpolate position data onto mag field data'
        return
    endif

    tnormalize,'fac_mat_pos_temp',newname='fac_mat_pos_temp',error=error_state

    if error_state eq 0 then begin
        dprint,' FX  failed to normalize interpolated position data'
        return
    endif

    case dl.data_att.coord_sys of
     'gse' : begin
               cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',/gei2gse
             end
     'gsm' : begin
               cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',/gei2gse
               cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',/gse2gsm
             end
     'dsl' : begin
               thm_cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',in_coord='gei',out_coord='dsl',$
                           probe=probe
             end
      else : begin
               dprint,' FX  failed to rotate data onto mag field system'
               return
             end
    endcase

    tcrossp,'fac_mat_z_temp','fac_mat_pos_temp',newname='fac_mat_y_temp',error=error_state

    if(error_state eq 0) then begin
        dprint,' FX  failed to generate B x Rgeo vector'
        return
    endif
    
    tnormalize,'fac_mat_y_temp',newname='fac_mat_y_temp',error=error_state
    
    if error_state eq 0 then begin
      dprint,' FX  failed to normalize y-vector after cross-product'
      return
    endif  

    tcrossp,'fac_mat_y_temp','fac_mat_z_temp',newname='fac_mat_x_temp',error=error_state

    if(error_state eq 0) then begin
        dprint,' FX  failed to generate Y x Z vector'
        return
    endif

    del_data,'fac_mat_pos_temp'
    del_data,pos_var_name_temp

    str_element,dl,'labels',success=s1

    if s1 eq 1 then $
      dl.labels = ['Y x B','B x Rgeo','B']

  end
  
  ;coordinates constructed on rhs coordinate system defined by B - mRgeo
  valid_coords[2] : begin

    if not keyword_set(pos_var_name) then begin
        dprint,' FX  requires pos_var_name to be set for mRgeo coordinate transformation'
        return
    endif

    if tnames(pos_var_name) eq '' then begin
        dprint,' FX  requires pos_var_name to be set for mRgeo coordinate transformation'
        return
    endif

    ;create temp variable so position vector is not overwritten
    get_data, pos_var_name, data=d_2,limits=l_2,dlimits=dl_2
    pos_var_name_temp = pos_var_name+'_temp'
    store_data, pos_var_name_temp, data=d_2,limits=l_2,dlimits=dl_2

    ;remove any gaps in the data
    if keyword_set(degap) then tdegap,pos_var_name_temp,newname=pos_var_name_temp, _extra=ex

    get_data,pos_var_name_temp,data=d_2,dlimits=dl_2

    d_2_s = size(d_2.y,/dimensions)

    if(n_elements(d_2_s) ne 2 || d_2_s[1] ne 3) then begin
        dprint,' FX  requires pos_var_name data to be an Nx3 Array'
        return
    endif

    if dl_2.data_att.coord_sys ne 'gei' then begin

      if dl_2.data_att.coord_sys eq 'dsl' then begin
        thm_cotrans,pos_var_name_temp,pos_var_name_temp,in_coord='dsl',out_coord='gei'
      endif else begin
        dprint,' FX  requires position data to be in gei or dsl coordinates to generate mRgeo transformation'
        return
      endelse

    endif

    tinterpol_mxn,pos_var_name_temp,'fac_mat_z_temp',newname='fac_mat_pos_temp',error=error_state

    if error_state eq 0 then begin
        dprint,' FX  failed to interpolate position data onto mag field data'
        return
    endif

    tnormalize,'fac_mat_pos_temp',newname='fac_mat_pos_temp',error=error_state

    if error_state eq 0 then begin
        dprint,' FX  failed to normalize interpolated position data'
        return
    endif

    case dl.data_att.coord_sys of
     'gse' : begin
               cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',/gei2gse
             end
     'gsm' : begin
               cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',/gei2gse
               cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',/gse2gsm
             end
     'dsl' : begin
               thm_cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',in_coord='gei',out_coord='dsl',$
                           probe=probe
             end
      else : begin
               dprint,' FX  failed to rotate data onto mag field system'
               return
             end
    endcase

    tcrossp,'fac_mat_pos_temp','fac_mat_z_temp',newname='fac_mat_y_temp',error=error_state

    if(error_state eq 0) then begin
        dprint,' FX  failed to generate Rgeo x B = B x mRgeo vector'
        return
    endif
    
    tnormalize,'fac_mat_y_temp',newname='fac_mat_y_temp',error=error_state
    
    if error_state eq 0 then begin
      dprint,' FX  failed to normalize y-vector after cross-product'
      return
    endif  

    tcrossp,'fac_mat_y_temp','fac_mat_z_temp',newname='fac_mat_x_temp',error=error_state

    if(error_state eq 0) then begin
        dprint,' FX  failed to generate Y x Z vector'
        return
    endif

    del_data,'fac_mat_pos_temp'
    del_data,pos_var_name_temp

    str_element,dl,'labels',success=s1

    if s1 eq 1 then $
      dl.labels = ['Y x B','B x mRgeo','B']

  end
  
  
  ;begin Phigeo transformation
  valid_coords[3] : begin

    if not keyword_set(pos_var_name) then begin
        dprint,' FX requires pos_var_name to be set for Phigeo coordinate transformation'
        return
    endif

    if tnames(pos_var_name) eq '' then begin
        dprint,' FX requires pos_var_name to be set for Phigeo coordinate transformation'
        return
    endif

    ;create temp variable so position vector is not overwritten
    get_data, pos_var_name, data=d_2,limits=l_2,dlimits=dl_2
    pos_var_name_temp = pos_var_name+'_temp'
    store_data, pos_var_name_temp, data=d_2,limits=l_2,dlimits=dl_2

    ;remove any gaps in the data
    if keyword_set(degap) then tdegap,pos_var_name_temp,newname=pos_var_name_temp, _extra=ex

    get_data,pos_var_name_temp,data=d_2,dlimits=dl_2

    d_2_s = size(d_2.y,/dimensions)

    if(n_elements(d_2_s) ne 2 || d_2_s[1] ne 3) then begin
        dprint,' FX  requires pos_var_name data to be an Nx3 Array'
        return
    endif

    if dl_2.data_att.coord_sys ne 'gei' then begin

      if dl_2.data_att.coord_sys eq 'dsl' then begin
        thm_cotrans,pos_var_name_temp,pos_var_name_temp,in_coord='dsl',out_coord='gei'
      endif else begin
        dprint,' FX  requires position data to be in gei or dsl coordinates to generate Phigeo transformation'
        return
      endelse

    endif

    tinterpol_mxn,pos_var_name_temp,'fac_mat_z_temp',newname='fac_mat_pos_temp',error=error_state

    if(error_state eq 0) then begin
        dprint,' FX  failed to interpolate position data onto mag field data'
        return
    endif

    ;obtain spherical coordinate unit vector phi in GEI (it is identical to phi GEO)
    ;first get theta,phi
    ;for some reason it truncates the names on this call so the names
    ;of the output variables are stored explicitly to make sure we can
    ;keep track of them
    xyz_to_polar,'fac_mat_pos_temp', magnitude = mag_name, theta = th_name,phi = phi_name
    get_data,phi_name,phi_t,phi_d
    get_data,th_name,theta_t,theta_d
    del_data, mag_name
    del_data, th_name
    del_data, phi_name

    ;allocate temporary storage variable
    y_2 = dindgen(n_elements(theta_t),3)

    ; next get unit vector phi coordinates in GEI system (overwrite y_2)
    y_2[*,0]=-sin(phi_d*!PI/180.)
    y_2[*,1]=cos(phi_d*!PI/180.)
    y_2[*,2]=0.

    ; transform into mag field coordinate system


    str_element,d,'v',SUCCESS=s

    if(s) then $
      store_data,'fac_mat_pos_temp',data={x:d.x,y:y_2, v:d.v} $
    else $
      store_data,'fac_mat_pos_temp',data={x:d.x,y:y_2}

    case dl.data_att.coord_sys of
     'gse' : begin
               cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',/gei2gse
             end
     'gsm' : begin
               cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',/gei2gse
               cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',/gse2gsm
             end
     'dsl' : begin
               thm_cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',in_coord='gei',out_coord='dsl',$
                           probe=probe
             end
      else : begin
               dprint,' FX  failed to rotate data onto mag field system'
               return
             end
    endcase

    tcrossp,'fac_mat_pos_temp','fac_mat_z_temp',newname='fac_mat_x_temp',error=error_state

    if(error_state eq 0) then begin
        dprint,'FX failed to calculate Phigeo by z cross product'
        return
    endif

    tnormalize,'fac_mat_x_temp',newname='fac_mat_x_temp',error=error_state

    if(error_state eq 0) then begin
        dprint,'FX failed to normalize x temp'
        return
    endif

    tcrossp,'fac_mat_z_temp','fac_mat_x_temp',newname='fac_mat_y_temp',error=error_state

    if(error_state eq 0) then begin
        dprint,'FX failed to calculate z by x cross product'
        return
    endif

    del_data,'fac_mat_pos_temp'
    del_data,pos_var_name_temp

    str_element,dl,'labels',success=s1

    if s1 eq 1 then $
      dl.labels=['Phigeo x B','B x X','B']

  end
  
  
  ;begin mPhigeo transformation
  valid_coords[4] : begin

    if not keyword_set(pos_var_name) then begin
        dprint,' FX  requires pos_var_name to be set for mPhigeo coordinate transformation'
        return
    endif

    if tnames(pos_var_name) eq '' then begin
        dprint,' FX  requires pos_var_name to be set for mPhigeo coordinate transformation'
        return
    endif

    ;create temp variable so position vector is not overwritten
    get_data, pos_var_name, data=d_2,limits=l_2,dlimits=dl_2
    pos_var_name_temp = pos_var_name+'_temp'
    store_data, pos_var_name_temp, data=d_2,limits=l_2,dlimits=dl_2

    ;remove any gaps in the data
    if keyword_set(degap) then tdegap,pos_var_name_temp,newname=pos_var_name_temp, _extra=ex

    get_data,pos_var_name_temp,data=d_2,dlimits=dl_2

    d_2_s = size(d_2.y,/dimensions)

    if(n_elements(d_2_s) ne 2 || d_2_s[1] ne 3) then begin
        dprint,' FX  requires pos_var_name data to be an Nx3 Array'
        return
    endif

    if dl_2.data_att.coord_sys ne 'gei' then begin

      if dl_2.data_att.coord_sys eq 'dsl' then begin
        thm_cotrans,pos_var_name_temp,pos_var_name_temp,in_coord='dsl',out_coord='gei'
      endif else begin
        dprint,' FX  requires position data to be in gei or dsl coordinates to generate Rpos transformation'
        return
      endelse

    endif

    tinterpol_mxn,pos_var_name_temp,'fac_mat_z_temp',newname='fac_mat_pos_temp',error=error_state

    if(error_state eq 0) then begin
        dprint,' FX  failed to interpolate position data onto mag field data'
        return
    endif

    ;obtain spherical coordinate unit vector phi in GEI (it is identical to phi GEO)
    ;first get theta,phi
    ;for some reason it truncates the names on this call so the names
    ;of the output variables are stored explicitly to make sure we can
    ;keep track of them
    xyz_to_polar,'fac_mat_pos_temp', magnitude = mag_name, theta = th_name,phi = phi_name
    get_data,phi_name,phi_t,phi_d
    get_data,th_name,theta_t,theta_d
    del_data, mag_name
    del_data, th_name
    del_data, phi_name

    ;allocate temporary storage variable
    y_2 = dindgen(n_elements(theta_t),3)

    ; next get unit vector phi coordinates in GEI system (overwrite y_2)
    y_2[*,0]=-sin(phi_d*!PI/180.)
    y_2[*,1]=cos(phi_d*!PI/180.)
    y_2[*,2]=0.

    ; transform into mag field coordinate system


    str_element,d,'v',SUCCESS=s

    if(s) then $
      store_data,'fac_mat_pos_temp',data={x:d.x,y:y_2, v:d.v} $
    else $
      store_data,'fac_mat_pos_temp',data={x:d.x,y:y_2}

    case dl.data_att.coord_sys of
     'gse' : begin
               cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',/gei2gse
             end
     'gsm' : begin
               cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',/gei2gse
               cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',/gse2gsm
             end
     'dsl' : begin
               thm_cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',in_coord='gei',out_coord='dsl',$
                           probe=probe
             end
      else : begin
               dprint,' FX  failed to rotate data onto mag field system'
               return
             end
    endcase

    tcrossp,'fac_mat_z_temp','fac_mat_pos_temp',newname='fac_mat_x_temp',error=error_state

    if(error_state eq 0) then begin
        dprint,'FX failed to calculate mPhigeo by z cross product'
        return
    endif

    tnormalize,'fac_mat_x_temp',newname='fac_mat_x_temp',error=error_state

    if(error_state eq 0) then begin
        dprint,'FX failed to normalize x temp'
        return
    endif

    tcrossp,'fac_mat_z_temp','fac_mat_x_temp',newname='fac_mat_y_temp',error=error_state

    if(error_state eq 0) then begin
        dprint,'FX failed to calculate z by x cross product'
        return
    endif

    del_data,'fac_mat_pos_temp'
    del_data,pos_var_name_temp

    str_element,dl,'labels',success=s1

    if s1 eq 1 then $
      dl.labels=['mPhigeo x B','B x X','B']

  end
  
  
  ;begin Phism transformation
  valid_coords[5]: begin

    if not keyword_set(pos_var_name) then begin
        dprint,' FX  requires pos_var_name to be set for Phism coordinate transformation'
        return
    endif

    if tnames(pos_var_name) eq '' then begin
        dprint,' FX  requires pos_var_name to be set for Phism coordinate transformation'
        return
    endif

    ;create temp variable so position vector is not overwritten
    get_data, pos_var_name, data=d_2,limits=l_2,dlimits=dl_2
    pos_var_name_temp = pos_var_name+'_temp'
    store_data, pos_var_name_temp, data=d_2,limits=l_2,dlimits=dl_2

    ;remove any gaps in the data
    if keyword_set(degap) then tdegap,pos_var_name_temp,newname=pos_var_name_temp, _extra=ex

    get_data,pos_var_name_temp,data=d_2,dlimits=dl_2

    d_2_s = size(d_2.y,/dimensions)

    if(n_elements(d_2_s) ne 2 || d_2_s[1] ne 3) then begin
        dprint,' FX  requires pos_var_name data to be an Nx3 Array'
        return
    endif

    if dl_2.data_att.coord_sys ne 'gei' then begin

      if dl_2.data_att.coord_sys eq 'dsl' then begin
        thm_cotrans,pos_var_name_temp,pos_var_name_temp,in_coord='dsl',out_coord='gei'
      endif else begin
        dprint,' FX  requires position data to be in gei or dsl coordinates to generate Phism transformation'
        return
      endelse

    endif

    cotrans,pos_var_name_temp,pos_var_name_temp,/gei2gse
    cotrans,pos_var_name_temp,pos_var_name_temp,/gse2gsm
    cotrans,pos_var_name_temp,pos_var_name_temp,/gsm2sm

    tinterpol_mxn,pos_var_name_temp,'fac_mat_z_temp',newname='fac_mat_pos_temp',error=error_state

    if(error_state eq 0) then begin
        dprint,' FX  failed to interpolate position data onto mag field data'
        return
    endif

    ;obtain spherical coordinate unit vector phi in SM
    ;first get theta,phi
    ;for some reason it truncates the names on this call so the names
    ;of the output variables are stored explicitly to make sure we can
    ;keep track of them
    xyz_to_polar,'fac_mat_pos_temp', magnitude = mag_name, theta = th_name,phi = phi_name
    get_data,phi_name,phi_t,phi_d
    get_data,th_name,theta_t,theta_d
    del_data, mag_name
    del_data, th_name
    del_data, phi_name

    ;allocate temporary storage variable
    y_2 = dindgen(n_elements(theta_t),3)

    ; next get unit vector phi coordinates in SM system (overwrite y_2)
    y_2[*,0]=-sin(phi_d*!PI/180.)
    y_2[*,1]=cos(phi_d*!PI/180.)
    y_2[*,2]=0.

    str_element,d,'v',SUCCESS=s

    if(s) then $
      store_data,'fac_mat_pos_temp',data={x:d.x,y:y_2, v:d.v} $
    else $
      store_data,'fac_mat_pos_temp',data={x:d.x,y:y_2}

    case dl.data_att.coord_sys of
     'gse' : begin
               cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',/sm2gsm
               cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',/gsm2gse
             end
     'gsm' : begin
               cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',/sm2gsm
             end
     'dsl' : begin
               thm_cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',in_coord='sm',out_coord='dsl',$
                           probe=probe
             end
      else : begin
               dprint,' FX  failed to rotate data onto mag field system'
               return
             end
    endcase

    tcrossp,'fac_mat_pos_temp','fac_mat_z_temp',newname='fac_mat_x_temp',error=error_state

    if(error_state eq 0) then begin
        dprint,'FX failed to calculate pos by z cross product'
        return
    endif

    tnormalize,'fac_mat_x_temp',newname='fac_mat_x_temp',error=error_state

    if(error_state eq 0) then begin
        dprint,'FX failed to normalize x temp'
        return
    endif

    tcrossp,'fac_mat_z_temp','fac_mat_x_temp',newname='fac_mat_y_temp',error=error_state

    if(error_state eq 0) then begin
        dprint,'FX failed to calculate z by x cross product'
        return
    endif

    del_data,'fac_mat_pos_temp'
    del_data,pos_var_name_temp

    str_element,dl,'labels',success=s1

    ;what are the labels?
    if s1 eq 1 then $
      dl.labels=['Phism x B','B x X','B']

  end


  ;begin mPhism transformation
  valid_coords[6]: begin

    if not keyword_set(pos_var_name) then begin
        dprint,' FX  requires pos_var_name to be set for mPhism coordinate transformation'
        return
    endif

    if tnames(pos_var_name) eq '' then begin
        dprint,' FX  requires pos_var_name to be set for mPhism coordinate transformation'
        return
    endif

    ;create temp variable so position vector is not overwritten
    get_data, pos_var_name, data=d_2,limits=l_2,dlimits=dl_2
    pos_var_name_temp = pos_var_name+'_temp'
    store_data, pos_var_name_temp, data=d_2,limits=l_2,dlimits=dl_2

    ;remove any gaps in the data
    if keyword_set(degap) then tdegap,pos_var_name_temp,newname=pos_var_name_temp, _extra=ex

    get_data,pos_var_name_temp,data=d_2,dlimits=dl_2

    d_2_s = size(d_2.y,/dimensions)

    if(n_elements(d_2_s) ne 2 || d_2_s[1] ne 3) then begin
        dprint,' FX  requires pos_var_name data to be an Nx3 Array'
        return
    endif

    if dl_2.data_att.coord_sys ne 'gei' then begin

      if dl_2.data_att.coord_sys eq 'dsl' then begin
        thm_cotrans,pos_var_name_temp,pos_var_name_temp,in_coord='dsl',out_coord='gei'
      endif else begin
        dprint,' FX  requires position data to be in gei or dsl coordinates to generate Phism transformation'
        return
      endelse

    endif

    cotrans,pos_var_name_temp,pos_var_name_temp,/gei2gse
    cotrans,pos_var_name_temp,pos_var_name_temp,/gse2gsm
    cotrans,pos_var_name_temp,pos_var_name_temp,/gsm2sm

    tinterpol_mxn,pos_var_name_temp,'fac_mat_z_temp',newname='fac_mat_pos_temp',error=error_state

    if(error_state eq 0) then begin
        dprint,' FX  failed to interpolate position data onto mag field data'
        return
    endif

    ;obtain spherical coordinate unit vector phi in SM
    ;first get theta,phi
    ;for some reason it truncates the names on this call so the names
    ;of the output variables are stored explicitly to make sure we can
    ;keep track of them
    xyz_to_polar,'fac_mat_pos_temp', magnitude = mag_name, theta = th_name,phi = phi_name
    get_data,phi_name,phi_t,phi_d
    get_data,th_name,theta_t,theta_d
    del_data, mag_name
    del_data, th_name
    del_data, phi_name

    ;allocate temporary storage variable
    y_2 = dindgen(n_elements(theta_t),3)

    ; next get unit vector phi coordinates in SM system (overwrite y_2)
    y_2[*,0]=-sin(phi_d*!PI/180.)
    y_2[*,1]=cos(phi_d*!PI/180.)
    y_2[*,2]=0.

    str_element,d,'v',SUCCESS=s

    if(s) then $
      store_data,'fac_mat_pos_temp',data={x:d.x,y:y_2, v:d.v} $
    else $
      store_data,'fac_mat_pos_temp',data={x:d.x,y:y_2}

    case dl.data_att.coord_sys of
     'gse' : begin
               cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',/sm2gsm
               cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',/gsm2gse
             end
     'gsm' : begin
               cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',/sm2gsm
             end
     'dsl' : begin
               thm_cotrans,'fac_mat_pos_temp','fac_mat_pos_temp',in_coord='sm',out_coord='dsl',$
                           probe=probe
             end
      else : begin
               dprint,' FX  failed to rotate data onto mag field system'
               return
             end
    endcase

    tcrossp,'fac_mat_z_temp','fac_mat_pos_temp',newname='fac_mat_x_temp',error=error_state

    if(error_state eq 0) then begin
        dprint,'FX failed to calculate mPhism by z cross product'
        return
    endif

    tnormalize,'fac_mat_x_temp',newname='fac_mat_x_temp',error=error_state

    if(error_state eq 0) then begin
        dprint,'FX failed to normalize x temp'
        return
    endif

    tcrossp,'fac_mat_z_temp','fac_mat_x_temp',newname='fac_mat_y_temp',error=error_state

    if(error_state eq 0) then begin
        dprint,'FX failed to calculate z by x cross product'
        return
    endif

    del_data,'fac_mat_pos_temp'
    del_data,pos_var_name_temp

    str_element,dl,'labels',success=s1

    if s1 eq 1 then $
      dl.labels=['mPhism x B','B x X','B']

  end


  ;begin Ygsm transformation (similar to other_dim=Xgse)
  valid_coords[7]: begin

    if(dl.data_att.coord_sys ne 'gse' && $
       dl.data_att.coord_sys ne 'gsm' && $
       dl.data_att.coord_sys ne 'dsl') then begin
        dprint,' fx requires mag_var_name to be in GSE, GSM, or DSL to generate a Ygsm field aligned coordinate matrix'
        return
    endif

    get_data,'fac_mat_z_temp',data=d,dlimits=dl

    ;constructs an array of unit vectors
    ;for use in generation of series of
    ;unit vector cross products
    y_axis = transpose(rebin([0D,1D,0D],3,n_elements(d.x)))

    str_element,d,'v',SUCCESS=s
    dl_temp=dl
    dl_temp.data_att.coord_sys = 'gsm'

    if(s) then $
      store_data,'fac_mat_y_temp',data={x:d.x,y:y_axis,v:d.v},dlimits=dl_temp $
    else $
      store_data,'fac_mat_y_temp',data={x:d.x,y:y_axis},dlimits=dl_temp

    case dl.data_att.coord_sys of
     'gse' : begin
               thm_cotrans,'fac_mat_y_temp','fac_mat_y_temp',in_coord='gsm',out_coord='gse',$
                           probe=probe
             end
     'gsm' : ; no rotation required
     'dsl' : begin
               thm_cotrans,'fac_mat_y_temp','fac_mat_y_temp',in_coord='gsm',out_coord='dsl',$
                           probe=probe
             end
      else : begin
               dprint,' FX failed to rotate Ygsm vector onto input mag field system'
               return
             end
    endcase

    tcrossp,'fac_mat_y_temp','fac_mat_z_temp',newname='fac_mat_x_temp',error=error_state

    if(error_state eq 0) then begin
         dprint,' FX  failed to create yz cross product in Ygsm'
        return
    endif

    tnormalize,'fac_mat_x_temp',newname='fac_mat_x_temp',error=error_state

    if(error_state eq 0) then begin
         dprint,' FX  failed to normalize Ygsm in Ygsm'
        return
    endif

    tcrossp,'fac_mat_z_temp','fac_mat_x_temp',newname='fac_mat_y_temp',error=error_state

    if(error_state eq 0) then begin
        dprint,' FX  failed to create zx cross product in Ygsm'
        return
    endif

    str_element,dl,'labels',success=s1

    if s1 eq 1 then $
      dl.labels = ['Ygsm x B','B x X','B']

  end

  ;rhs coordinates constructed on plane zdsl - B
  valid_coords[8] : begin

    if(dl.data_att.coord_sys ne 'gse' && $
       dl.data_att.coord_sys ne 'gsm' && $
       dl.data_att.coord_sys ne 'dsc' && $   ; For RBSP
       dl.data_att.coord_sys ne 'dsl') then begin

        dprint,' fx requires mag_var_name to be in GSE, GSM, or DSL to generate a Xgse field aligned coordinate matrix'
        error = 1
        return
    endif

    get_data,'fac_mat_z_temp',data=d,dlimits=dl
    dprint, 'working on zdsl'

    ;constructs an array of unit vectors
    ;for use in generation of series of
    ;unit vector cross products
    x_axis = transpose(rebin([0D,0D,1D],3,n_elements(d.x)))

    str_element,d,'v',SUCCESS=s
    dl_temp=dl
    dl_temp.data_att.coord_sys = 'gse'

    if(s) then $
      store_data,'fac_mat_y_temp',data={x:d.x,y:x_axis,v:d.v},dlimits=dl_temp $
    else $
      store_data,'fac_mat_y_temp',data={x:d.x,y:x_axis},dlimits=dl_temp

;    case dl.data_att.coord_sys of
;     'gse' : ; no rotation required
;     'gsm' : ; no rotation required
;     'dsl' : begin
;               thm_cotrans,'fac_mat_x_temp','fac_mat_x_temp',in_coord='gse',out_coord='dsl',$
;                           probe=probe
;             end
;      else : begin
;               message,/continue,' FX failed to rotate Xgse vector onto input mag field system'
;               return
;             end
;    endcase

    tcrossp,'fac_mat_y_temp','fac_mat_z_temp',newname='fac_mat_x_temp',error=error_state

    if(error_state eq 0) then begin
         dprint,' FX  failed to create zx cross product in ' + valid_coords[0]
        return
    endif

    tnormalize,'fac_mat_x_temp',newname='fac_mat_x_temp',error=error_state

    if(error_state eq 0) then begin
         dprint,' FX  failed to create zx cross product in Xgse'
        return
    endif

    tcrossp,'fac_mat_z_temp','fac_mat_x_temp',newname='fac_mat_y_temp',error=error_state

    if(error_state eq 0) then begin
        dprint,' FX  failed to create yz cross product in Xgse'
        return
    endif

    str_element,dl,'labels',success=s1

    if s1 eq 1 then $
      dl.labels = ['Zdsl x B','B x X','B']

  end
  
  else: begin
      dprint,'no valid other_dimension'
               return
  end
endcase


get_data,'fac_mat_x_temp',data=d_x

del_data,'fac_mat_x_temp'

get_data,'fac_mat_y_temp',data=d_y

del_data,'fac_mat_y_temp'

get_data,'fac_mat_z_temp',data=d_z

del_data,'fac_mat_z_temp'

;generate output variable and store it
out = dindgen(d_s[0],3,3)

out[*,0,*] = d_x.y
out[*,1,*] = d_y.y
out[*,2,*] = d_z.y

;out = transpose(out, [0, 2, 1])


str_element,d,'v',SUCCESS=s

if(s) then $
  d = {x:d.x,y:out,v:d.v} $
else $
  d = {x:d.x,y:out}

;dl.data_att.coord_sys=valid_coords[0]
str_element,dl,'data_att.source_sys',dl.data_att.coord_sys,/add
dl.data_att.coord_sys=other_dim_l

;tvector rotate uses this flag to determine if it should take axes
;labels from the transformation matrix

str_element,dl,'labflag',success=s

if s eq 1 then $
  dl.labflag = 1 $
else $
  str_element,dl,'labflag',value=1,/add_replace


store_data,newname,data=d,dlimits=dl

error = 1

return

end
