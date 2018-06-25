;+
;Procedure:
;  thm_part_slice2d
;
;Purpose:
;   Wrapper for using spd_slice2d to create particle distribution contours.
;   This essentially performs all THEMIS-specific operations that occured
;   in the original thm_part_slice2d and should be backward-compatible.
;   
;   Returns a 2-D slice of THEMIS ESA/SST particle distributions.
;   This procedure works in conjunction with thm_part_dist_array.pro and 
;   thm_part_slice2d_plot.pro.
;
;   There are three methods for generating slices:
;
;   Geomtric:
;     Each point on the plot is given the value of the bin it instersects.
;     This allows bin boundaries to be drawn at high resolutions.
;
;   2D Interpolation:
;     Datapoints within the specified theta or z-axis range are projected onto 
;     the slice plane and linearly interpolated onto a regular 2D grid. 
;
;   3D Interpolation:
;     The entire 3-dimensional distribution is linearly interpolated onto a 
;     regular 3d grid and a slice is extracted from the volume.
;
;    
;Calling Sequence:
;    thm_part_slice2d, datArr, [datArr2, [datArr3, [datArr4]]], $
;                      timewin = timewin, slice_time=slice_time, $
;                      part_slice=part_slice
;
;
;Arguments:
; DATARR[#]: An array of pointers to 3D data structures.
;            See thm_part_dist_array.pro for more.
; 
; 
;Keywords:
;
; SLICE_TIME: Beginning of time window in seconds since Jan. 1, 1970.  If
;             CENTER_TIME keyword set, then TIME is the center of the time widow
;             specified by the TIMEWIN keyword.
; TIMEWIN: Length in seconds over which to compute the slice.
; CENTER_TIME: Flag that, when set, centers the time window around the time 
;              specified by SLICE_TIME keyword. 
; UNITS: A string specifying the units to be used.
;        ('counts', 'DF' (default), 'rate', 'crate', 'flux', 'eflux')
; ENERGY: Flag to plot data against energy (in eV) instead of velocity.
; LOG: Flag to apply logarithmic scaling to the radial mesure (i.e. energy/velocity).
;      (on by default if /ENERGY is set)
;        
; TWO_D_INTERP: Flag to use 2D interpolation method (described above)
; THREE_D_INTERP: Flag to use 3D interpolation method (described above)
; 
; COORD: A string designating the coordinate system in which the slice will be 
;        oriented.  Options are 'DSL', 'GSM', 'GSE' and the following magnetic
;        field aligned coordinates (field parallel to z axis).
;        
;      'xgse':  The x axis is the projection of the GSE x-axis
;      'ygsm':  The y axis is the projection of the GSM y-axis
;      'zdsl':  The y axis is the projection of the DSL z-axis
;      'RGeo':  The x is the projection of radial spacecraft position vector (GEI)
;      'mRGeo':  The x axis is the projection of the negative radial spacecraft position vector (GEI)
;      'phiGeo':  The y axis is the projection of the azimuthal spacecraft position vector (GEI), positive eastward
;      'mphiGeo':  The y axis is the projection of the azimuthal spacecraft position vector (GEI), positive westward
;      'phiSM':  The y axis is the projection of the azimuthal spacecraft position vector in Solar Magnetic coords
;      'mphiSM':  The y axis is the projection of the negative azimuthal spacecraft position vector in Solar Magnetic coords
;
;        
; ROTATION: The rotation keyword specifies the orientation of the slice plane 
;           within the given coordinates (BV and BE will be invariant between
;           coordinate systems).
;       
;     'BV':  The x axis is parallel to B field; the bulk velocity defines the x-y plane
;     'BE':  The x axis is parallel to B field; the B x V(bulk) vector defines the x-y plane
;     'xy':  (default) The x axis is along the coordinate's x axis and y is along the coordinate's y axis
;     'xz':  The x axis is along the coordinate's x axis and y is along the coordinate's z axis
;     'yz':  The x axis is along the coordinate's y axis and y is along the coordinate's z axis
;     'xvel':  The x axis is along the coordinate's x axis; the x-y plane is defined by the bulk velocity 
;     'perp':  The x axis is the bulk velocity projected onto the plane normal to the B field; y is B x V(bulk)
;     'perp_xy':  The coordinate's x & y axes are projected onto the plane normal to the B field
;     'perp_xz':  The coordinate's x & z axes are projected onto the plane normal to the B field
;     'perp_yz':  The coordinate's y & z axes are projected onto the plane normal to the B field
;     
;
; SLICE_X/SLICE_NORM: These keywords respectively specify the slice plane's 
;               x-axis and normal within the coordinates specified by 
;               COORD and ROTATION. Both keywords take 3-vectors as input.
;               
;               If SLICE_X is not specified then the given coordinate's 
;               x-axis will be used. If SLICE_X is not perpendicular to 
;               the normal it's projection onto the slice plane will be used.
;               An error will be thrown if no projection exists.
;               
;               If SLICE_NORM is not specified then the given coordinate's
;               z-axis will be used (slice along by x-y plane in those 
;               coordinates).
;                 
;       examples:
;         Slice plane perpendicular to DSL z-axis using [3,2,0] as plane's x-axis: 
;         (this is the same as only using SLICE_X=[3,2,1])
;           COORD='dsl' (default), ROTATION='xyz' (default), SLICE_X=[3,2,1]
;         
;         Slice plane perp. to GSE x-axis, bulk velocity used to define plane's x-axis:
;           COORD='gse', ROTATION='xvel', SLICE_NORM=[1,0,0], SLICE_X=[0,1,0]
;
;         Slice plane along the B field and radial position vectors, B field used as slice's x-axis:
;           COORD='rgeo', SLICE_NORM=[0,1,0], SLICE_X=[0,0,1]
; DISPLACEMENT: Vector. New center of the coordinate system.
;       example:
;         Slice at the point x=0.5, y = 0.5 and z=0.1.
;         DISPLACEMENT = [0.5, 0.5. 0.1]
;         
;    
; VEL_DATA: Name of tplot variable containing the bulk velocity data.
;           This will be used for slice plane alignment and subtraction.
;           If not set the bulk velocity will be automatically calculated
;           from the distribution (when needed).
; MAG_DATA: Name of tplot variable containing magnetic field data.
;           This will be used for slice plane alignment.
; ERANGE: Two element array specifying the energy range to be used.
; COUNT_THRESHOLD: Mask bins that fall below this number of counts after averaging.
;                (e.g. COUNT_THRESHOLD=1 masks bins with counts below 1)
; RESOLUTION: Integer specifying the resolution along each dimension of the
;             slice (defaults:  2D/3D interpolation: 150, geometric: 500) 
; SMOOTH: An odd integer >=3 specifying the width of the smoothing window in # 
;         of points. Even entries will be incremented, 0 and 1 are ignored.
;         Smoothing is performed with a gaussian convolution.
;
; THETARANGE: (2D interpolation only)
;             Angle range, in degrees [-90,90], used to calculate slice.
;             Default = [-20,20]; will override ZDIRRANGE. 
; ZDIRRANGE: (2D interpolation only)
;            Z-Axis range, in km/s, used to calculate slice.
;            Ignored if called with THETARANGE.
;
; AVERAGE_ANGLE: (geometric only)
;                Two element array specifying an angle range over which 
;                averaging will be applied. The angle is measured 
;                from the slice plane and about the slice's x-axis; 
;                positive in the right handed direction. This will
;                average over all data within that range.
;                    e.g. [-25,25] will average data within 25 degrees
;                         of the slice plane about it's x-axis
;
; MSG_OBJ: Object reference to GUI message bar. If included useful
;          console messages will also be output to GUI.
; 
;
;Output:
; PART_SLICE: Structure to be passed to thm_part_slice2d_plot.
;      {
;       data: two dimensional array (NxN) containing the data to be plotted
;       xgrid: N dimensional array of x-axis values for plotting 
;       ygrid: N dimensional array of y-axis values for plotting
; 
;       project_name: name of project
;       spacecraft: spacecraft designation
;       data_name: string or string array containing the type(s) of distribution used
;       n_samples: number of distributions averaged to create slice
;
;       mass: partile mass in ev/(km/s)^2
;       units: the data's units
;       xyunits: the x & y axes' units
;       coord: placeholder for coordinate system label
;       rot: the applied rotation option
;       type: flag denoting interpolation type (0=geo, 2=2D interp, 3=3D interp);
;       energy: flag that x and y are energy instead of velocity
;       rlog: flag denoting radial log scaling
;
;       zrange: two-element array containing the range of the un-interpolated data 
;       rrange: two-element array containing the radial range of the data
;       trange: two-element array containing the numerical time range
;        
;       bulk: 3-vector containing the bulk velocity in the slice plane's coordinates
;       bfield: 3-vector containing the bfiend in the slice plane's coordinates
;       sunvec: 3-vector containing the sun direction in the slice plane's coordinates
;       custom_matrix: The applied custom rotation matrix.
;       rotation_matrix: Rotation matrix from the the original or custom coordinates 
;                        to those defined by ROTATION.
;       orient_matrix: Rotation matrix from the coordinates defined by ROTATION to 
;                      the coordinates defined by SLICE_NORM and SLICE_X 
;                      (column matrix of new coord's basis).
;       }
; 
;
;
;NOTES:
;   - Regions containting no data are assigned zeros instead of NaNs.
;   - Interpolation may occur across data gaps or areas with recorded zeroes
;     when using 3D interpolation (use geometric interpolation to see bins).
;   - The center/midpoint time of a distribution is used as it's timestamp
;     when determining it's inclusion in the requested time range.  The full
;     time range of all included samples is stored in the metadata.
;      
;
;CREATED BY: 
;  A. Flores Based on work by Bryan Kerr and Arjun Raj, and Xuzhi Zhou
;
;
;EXAMPLES:
;  See the crib file: thm_crib_part_slice2d.pro
;
;
;$LastChangedBy: adrozdov $
;$LastChangedDate: 2018-06-04 17:46:48 -0700 (Mon, 04 Jun 2018) $
;$LastChangedRevision: 25322 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/thm_part_slice2d.pro $
;-
pro thm_part_slice2d, ptrArray, ptrArray2, ptrArray3, ptrArray4, $
                    ; Time options
                      timewin=timewin, slice_time=slice_time_in, $
                      center_time=center_time, $
                    ; Range limits
                      erange=erange, $
                      thetarange=thetarange, zdirrange=zdirrange, $
                    ; Orientations
                      coord=coord_in, rotation=rotation, $
                      slice_x=slice_x, slice_norm=slice_z, $
                      displacement=displacement_in, $  
                    ; Support Data
                      mag_data=mag_data, vel_data=vel_data, $
                    ; Type options
                      type=type, two_d_interp=two_d_interp, $
                      three_d_interp=three_d_interp, $
                    ; Other options
                      units=units, resolution=resolution, $
                      average_angle=average_angle, smooth=smooth,  $
                      count_threshold=count_threshold, $
                      subtract_counts=subtract_counts, $
                      subtract_bulk=subtract_bulk, $
                      log=log, energy=energy, $
                    ; Output
                      part_slice=slice, $
                    ; Dummy vars to conserve backwards compatibility 
                    ; (should allow oldscripts to be run withouth issue)
                      xgrid=xgrid, ygrid=ygrid, slice_info=slice_info, $
                      onecount=onecount, $
                    ; Other
                      fix_counts=fix_counts, $
                      msg_obj=msg_obj, fail=fail, $
                      _extra = _extra

    compile_opt idl2


fail = ''

if size(ptrArray,/type) ne 10 then begin
  fail = 'Invalid data structure.  Input must be valid array of pointers to arrays of '+ $
          'ESA or SST distributions with required tags. '+ $
          'See thm_part_dist_array.'
  dprint, dlevel=1, fail
  return
endif

if undefined(slice_time_in) then begin
  fail = 'Please specifiy a time at which to compute the slice.'
  dprint, dlevel=1, fail
  return
endif

if undefined(timewin) then begin
  fail = 'Please specifiy a time window for the slice."
  dprint, dlevel=1, fail
  return
endif

valid_coords = ['dsl','gse','gsm','xgse','ygsm','zdsl','rgeo', $
                'mrgeo','phigeo','mphigeo','phism','mphism']
if ~undefined(coord_in) then begin
  coord = strlowcase(coord_in)
  if ~in_set(coord,valid_coords) then begin
    fail = 'Invalid coordinates requested.  See thm_crib_part_slice2d for examples.'
    dprint, dlevel=1, fail
    return
  endif
endif


; Defaults
;------------------------------------------------------------

slice_time = time_double(slice_time_in[0])
if undefined(coord) then coord='dsl'
if undefined(units) then units = 'df'

;Interpolation type:
if undefined(type) then begin
  three_d_interp = 1
endif else begin
  if type[0] eq 0 then geometric = 1
  if type[0] eq 2 then two_d_interp = 1
  if type[0] eq 3 then three_d_interp = 1
endelse

probe = keyword_set((*ptrArray[0])[0].spacecraft) ? (*ptrArray[0])[0].spacecraft : $
                 strmid((*ptrArray[0])[0].project_name, 0, /reverse_offset)
if ~stregex(probe, '[abcde]', /bool, /fold_case) then probe = ''

;preserve backward compatability
if ~keyword_set(count_threshold) && keyword_set(onecount) then count_threshold = onecount



; Get data & info
;------------------------------------------------------------

;aggregate pointers here to make the unit conversion easier
ds = ptrArray
if ptr_valid(ptrArray2) then ds = [ds,ptrArray2]
if ptr_valid(ptrArray3) then ds = [ds,ptrArray3]
if ptr_valid(ptrArray4) then ds = [ds,ptrArray4]

; get the boundaries of the time window to retrieve support data
if keyword_set(center_time) then begin
  trange = [slice_time - timewin/2, $
            slice_time + timewin/2  ]
endif else begin
  trange = [slice_time, $
            slice_time + timewin ]
endelse


; Get any support data that's stored in the distribution structures
; (backward compatibility)
;------------------------------------------------------------

; Get bulk velocity calculated from dist struct if none is specified
if undefined(vel_data) then begin
  vel_data = thm_part_slice2d_getvel(ds, trange=trange, energy=energy, fail=fail)
endif

; Get sun vector if present in structures
sun_data = thm_part_slice2d_getsun(ds, trange=trange, fail=fail)
if n_elements(sun_data) ne 3 then undefine, sun_data


; Get THEMIS specific rotation matrices
;------------------------------------------------------------

if in_set(coord,['dsl','gse','gsm']) then begin
  thm_part_slice2d_cotrans, probe=probe, coord=coord, trange=trange, fail=fail, $
                            matrix=custom_rotation
endif else begin
  thm_part_slice2d_fac, probe=probe, coord=coord, trange=trange, fail=fail, $
                        mag_data=mag_data, matrix=custom_rotation          
endelse
if keyword_set(fail) then return



; Process the data and generate the slice
;------------------------------------------------------------

; perform unit conversion, remove sst contamination, apply eclipse corrections, etc
thm_part_process, ds, processed, trange=trange, units=units, _extra=_extra 


slice = spd_slice2d(processed, $
                  ; Time options
                    time=slice_time, $
                    window=timewin, $
                    center_time=center_time, $
                  ; Orientations
                    custom_rotation=custom_rotation, $
                    rotation=rotation, $
                    slice_norm=slice_z, $
                    slice_x=slice_x, $
                    displacement=displacement_in, $  
                  ; Support Data
                    mag_data=mag_data, $
                    vel_data=vel_data, $
                    sun_data=sun_data, $
                  ; Interpolation options
                    geometric=geometric, $
                    two_d_interp=two_d_interp, $
                    three_d_interp=three_d_interp, $
                  ; 2D interpolation options
                    thetarange=thetarange, $
                    zdirrange=zdirrange, $
                  ; Range limits
                    erange=erange, $
                  ; Other options
                    resolution=resolution, $
                    smooth=smooth,  $
                    log=log, $
                    energy=energy, $
                  ; TBD
                    subtract_bulk=subtract_bulk, $
                    average_angle=average_angle, $
                  ; Other
                    msg_obj=msg_obj, $
                    fail=fail, $
                    _extra = _extra)

if keyword_set(fail) then begin
  fail = 'Error producing slice:  ' + fail
  dprint, dlevel=0, fail
  return
endif

;set coordinates for plot labels
slice.coord=coord


; Apply N-count threshold/subtraction if requested
;  -create copy of the data set to N counts
;  -produce identical slice from the synthetic data
;  -use new slice as mask 
;------------------------------------------------------------
if keyword_set(count_threshold) or keyword_set(subtract_counts) then begin

  fix_counts = keyword_set(subtract_counts) ? subtract_counts:count_threshold

  thm_part_copy, ds, fixed

  thm_part_set_counts, fixed, fix_counts, /set_units

  ;no background or contamination removal should be performed here!
  thm_part_process, fixed, fixed_processed, units=units, esa_bgnd_remove=0

  mask = spd_slice2d(fixed_processed, $
                  ; Time options
                    time=slice_time, $
                    window=timewin, $
                    center_time=center_time, $
                  ; Orientations
                    custom_rotation=custom_rotation, $
                    rotation=rotation, $
                    slice_norm=slice_z, $
                    slice_x=slice_x, $
                    displacement=displacement_in, $  
                  ; Support Data
                    mag_data=mag_data, $
                    vel_data=vel_data, $
                    sun_data=sun_data, $
                  ; Interpolation options
                    geometric=geometric, $
                    two_d_interp=two_d_interp, $
                    three_d_interp=three_d_interp, $
                  ; 2D interpolation options
                    thetarange=thetarange, $
                    zdirrange=zdirrange, $
                  ; Range limits
                    erange=erange, $
                  ; Other options
                    resolution=resolution, $
                    smooth=smooth,  $
                    log=log, $
                    energy=energy, $
                  ; TBD
                    subtract_bulk=subtract_bulk, $
                    average_angle=average_angle, $
                  ; Other
                    msg_obj=msg_obj, $
                    fail=fail, $
                    _extra = _extra)

  if keyword_set(fail) then begin
    fail = 'Error calculating count threshold:  ' + fail
    dprint, dlevel=0, fail
    return
  endif

  if keyword_set(count_threshold) then begin
    btidx = where(slice.data lt mask.data,nbt)
    if nbt gt 0 then begin
      slice.data[btidx] = 0
    endif
  endif else if keyword_set(subtract_counts) then begin
    slice.data = (slice.data - mask.data) > 0
  endif

endif


end