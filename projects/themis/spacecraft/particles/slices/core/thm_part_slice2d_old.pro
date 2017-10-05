
;+
;Procedure:
;   thm_part_slice2d_old
;
;Purpose:
;
;   **** Deprecated - Use THM_PART_SLICE2D ****
;   
;   Returns a 2-D slice of THEMIS ESA/SST particle distributions.
;   This procedure works in conjunction with thm_part_dist_array.pro and 
;   thm_part_slice2d_plot_old.pro.
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
;       Notes: - Interpolation may occur across data gaps or areas with recorded zeroes
;              - Higher resolution regridding will severely slow this method
;     
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
;
; DISPLACEMENT: Value in m/s that specifies how far from the origin the slice 
;               plane will be cut.
;               
;       example:
;         Slice plane cut at Z_gse = 500
;           COORD='gse', ROTATION='xyz' (default), DISPLACEMENT=500.
;
; AVERAGE_ANGLE: Two element array specifying an angle range over which 
;                averaging will be applied. The angle is measured 
;                from the slice plane and about the slice's x-axis; 
;                positive in the right handed direction. This will
;                average over all data within that range.
;                    e.g. [-25,25] will average data within 25 degrees
;                         of the slice plane about it's x-axis
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
; REGRID: (2D/3D Interpolation only)
;         A three element array specifying regrid dimensions in phi, theta, and 
;         energy respectively. If set, all distributions' data will first be 
;         spherically interpolated to the requested reslotution using the 
;         nearest neighbor.  The resolution in energy will only be interpolated 
;         to integer multiples of the original resolution (e.g. data with 16 
;         energies will be interpolated to 32, 48, ...)
;
; THETARANGE: (2D interpolation only)
;             Angle range, in degrees [-90,90], used to calculate slice.
;             Default = [-20,20]; will override ZDIRRANGE. 
; ZDIRRANGE: (2D interpolation only)
;            Z-Axis range, in km/s, used to calculate slice.
;            Ignored if called with THETARANGE.
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
;       probe: string containing the probe
;       dist: string or string array containing the type(s) of distribution used
;       mass: assumed particle mass from original distributions
;       coord: string describing the coordinate system used for the slice
;       rot: string describing the user specified rotation (N/A for 2D interp)
;       units: string describing the units
;       twin: time window of the slice
;       rlog: flag denoting radial log scaling
;       ndists: number time samples included in slice
;       type: flag denoting slice type (0=geo, 2=2D interp, 3=3D interp)
;       zrange: two-element array containing the range of the un-interpolated data 
;       rrange: two-element array containing the radial range of the data
;       trange: two-element array containing the numerical time range
;       shift: 3-vector containing any translations made in addition to 
;              requested rotations (e.g. subtracted bulk velocity)
;       bulk: 3-vector containing the bulk velocity in the slice plane's coordinates
;       sunvec: 3-vector containing the sun direction in the slice plane's coordinates
;       coord_m: Rotation matrix from original data's coordinates (DSL) to
;                those specified by the COORD keyword.
;       rot_m: Rotation matrix from the the specified coordinates to those 
;            defined by ROTATION.
;       orient_m: Rotation matrix from the coordinates defined by ROTATION to 
;                 the coordinates defined by SLICE_NORM and SLICE_X 
;                 (column matrix of new coord's basis).
;       }
;
;
;CAVEATS: Due to IDL software constraints regions containing no data 
;         are assigned zeros instead of NaNs.  
;
;NOTES:
;  In general this code makes the following assumptions about the particle data:
;    - Look directions, energies, and assumed particle mass may vary between 
;      modes but not within a mode (this is checked within the code).
;    - If assumed mass varies greatly between modes then the mass field in
;      the output structure should be ignored.  This will prevent 1D slice 
;      plots from being made with the output
;      
;
;
;CREATED BY: A. Flores
;            Based on work by Bryan Kerr and Arjun Raj 
;
;EXAMPLES:  see the crib file: thm_crib_part_slice2d.pro
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-04 18:05:22 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20331 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/core/thm_part_slice2d_old.pro $
;-

pro thm_part_slice2d_old, ptrArray, ptrArray2, ptrArray3, ptrArray4, $
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
                      regrid=regrid_in, slice_width=slice_width, $
                      log=log, energy=energy, $
                    ; Output
                      part_slice=slice_struct, $
                    ; Dummy vars to conserve backwards compatibility 
                    ; (should allow oldscripts to be run withouth issue)
                      xgrid=xgrid, ygrid=ygrid, slice_info=slice_info, $
                      onecount=onecount, $
                    ; Other
                      fix_counts=fix_counts, $
                      msg_obj=msg_obj, fail=fail, $
                      _extra = _extra

    compile_opt idl2

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

valid_rotations = ['bv', 'be', 'xy', 'xz', 'yz', 'xvel', $
                   'perp', 'perp_xy', 'perp_xz', 'perp_yz']
if ~undefined(rotation) then begin
  if ~in_set(strlowcase(rotation),valid_rotations) then begin
    fail = 'Invalid rotation requested.  See thm_crib_part_slice2d for examples.'
    dprint, dlevel=1, fail
    return
  endif
endif

d_set = [keyword_set(ptrArray), keyword_set(ptrArray2), $
         keyword_set(ptrArray3), keyword_set(ptrArray4)]

fail = ''


; Defaults
;------------------------------------------------------------
slice_time = time_double(slice_time_in[0])
if undefined(coord) then coord='dsl'
if undefined(rotation) then rotation='xy'
if undefined(units) then units = 'df'
if undefined(slice_z) then slice_z = [0,0,1.]
if keyword_set(regrid_in) then regrid = regrid_in
if keyword_set(energy) && undefined(log) then log = 1
if rotation eq 'xyz' then rotation = 'xy'
if rotation eq 'perp_xyz' then rotation = 'perp_xy'
displacement = keyword_set(displacement_in) ? displacement_in:0.

;attempt to get probe, this is a bit messy
probe = keyword_set((*ptrArray[0])[0].spacecraft) ? (*ptrArray[0])[0].spacecraft : $
                 strmid((*ptrArray[0])[0].project_name, 0, /reverse_offset)
if ~stregex(probe, '[abcde]', /bool, /fold_case) then probe = ''

;Type specific:
if keyword_set(two_d_interp) then type = 2
if keyword_set(three_d_interp) then type = 3
if undefined(type) then type = 0
if type gt 3 then type = 0

if keyword_set(type) && keyword_set(average_angle) then begin
  dprint, dlevel=1, 'Angular averaging is only applicable to the geometric method.'+ $
                    'No averaging will be applied.'
  return
endif

; 2d interp
if type eq 2 then begin 
  if undefined(smooth) then smooth = 7
  if undefined(resolution) then resolution = 150
  if ~keyword_set(thetarange) and ~keyword_set(zdirrange) then begin
    thetarange = [-20.,20]
  endif
endif 

; 3D interp
if type eq 3 then begin 
  if undefined(smooth) then smooth = 7
  if undefined(resolution) then resolution = 150
endif 

; geometric
if ~keyword_set(type) then begin
  regrid = 0 ;incompatible with regridding
  if undefined(resolution) then resolution = 500
endif


;preserve backward compatability
if ~keyword_set(count_threshold) && keyword_set(onecount) then count_threshold = onecount



msg = 'Processing slice at ' + time_string(slice_time, format=5) +'... '
dprint, dlevel=2, msg 
if obj_valid(msg_obj) then msg_obj->update, msg 



; Account for multiple data types & mode changes.
;  -Each ptrArray[#] input will be a pointer or pointer array.
;  -The user may pass in up to 4 of such variables if requesting
;   multiple data types (e.g. psif & peif).  If the data spans 
;   a mode change then ptrArray[#] will be an array.
;------------------------------------------------------------
temp=where(d_set,c)

if c eq 1 then begin
  ds = [ptrArray]
endif else if c eq 2 then begin
  ds = [ptrArray,ptrArray2]
endif else if c eq 3 then begin
  ds = [ptrArray,ptrArray2,ptrArray3]
endif else if c eq 4 then begin
  ds = [ptrArray,ptrArray2,ptrArray3,ptrArray4]
endif else begin
  fail = "Unknown error collating data, please report to the TDAS software team."
  dprint,dlevel=0, fail
  return
endelse



; Get the slice's time range
;------------------------------------------------------------

; get the boundaries of the time window
if keyword_set(center_time) then begin
  trange = [slice_time - timewin/2, $
            slice_time + timewin/2  ]
endif else begin
  trange = [slice_time, $
            slice_time + timewin ]
endelse

; check that there is data in range before proceeding
for i=0, n_elements(ds)-1 do begin
  times_ind = thm_part_slice2d_intrange(ds[i], trange, n=ndat)
  n_samples = array_concat(ndat,n_samples)
endfor
if total(n_samples) lt 1 then begin
  fail = 'No particle data in the time window: '+strjoin(time_string(trange),', ')+ $
         '. Time samples may be at low cadence; try adjusting the time window.'
  dprint, dlevel=1, fail 
  return
endif



; Get support data
;------------------------------------------------------------

; Get mag data
bfield = thm_part_slice2d_getmag(ds, mag_data=mag_data, trange=trange, fail=fail)
if n_elements(bfield) eq 1 then return


; Get bulk velocity (in km/s or eV depending on slice type) 
vbulk = thm_part_slice2d_getvel(ds, vel_data=vel_data, trange=trange, energy=energy, fail=fail)
if n_elements(vbulk) eq 1 then return


; Get Sun vector
sunvec = thm_part_slice2d_getsun(ds, trange=trange, fail=fail)



; Extract data from structures
;  -apply energy limits
;  -average date over time window
;  -output r, phi, theta and dr, dphi, dtheta arrays
;------------------------------------------------------------
thm_part_slice2d_getdata, ds, units=units, trange=trange, regrid=regrid, erange=erange, energy=energy, $ 
                 data=datapoints, rad=rad, phi=phi, theta=theta, dr=dr, dp=dp, dt=dt, $
                 fix_counts=fix_counts, fail=fail, _extra=_extra
if keyword_set(fail) then return


; Known causes of an empty data variable should be caught before this.
if ~keyword_set(datapoints) then begin
  fail = 'Unknown error extracting data from particle distributions.'
  dprint, dlevel=0, fail
  return
endif


; Get original data and radial ranges for plotting
;  -attempt to ignore small values created from interpolation
;   (useful with SST contamination removal on)
idx = where(datapoints gt 0,n)
if n gt 0 then begin
  dmoms = moment(alog10(datapoints[idx]),maxmom=2)
  min = 10^(dmoms[0] - 2*sqrt(dmoms[1])) ;ignore if < mean - 2*sigma 
  drange = minmax(datapoints[idx],min_value=min)
endif else begin
  drange = [0,0.]
endelse
rrange = [  min( rad - 0.5*dr ), max( rad + 0.5*dr )  ]


; Apply radial log scaling
if keyword_set(log) then begin
  thm_part_slice2d_rlog, rad, dr, displacement=displacement
endif


; Convert spherical data to cartesian coordinates for interpolation
if keyword_set(type) then begin
  thm_part_slice2d_s2c, rad,theta,phi, xyz
endif




; Get/apply coordinate transformations
;  -For geometric mode, transformations will be
;   applied inside thm_part_slice2d_geo instead.
;------------------------------------------------------------

; Subtract bulk velocity vector
;  -invalid for geometric method
;  -incompatible with radial log scaling
if keyword_set(subtract_bulk) and (type ne 0) and ~keyword_set(log) then begin
  thm_part_slice2d_subtract,  vectors=xyz, vbulk=vbulk, vel_data=vel_data, energy=energy
endif


; Transform to GSM, GSE, or field aligned coordinates
if in_set(coord,['dsl','gse','gsm']) then begin
  thm_part_slice2d_cotrans, probe=probe, coord=coord, trange=trange, fail=fail, $
                vectors=xyz, bfield=bfield, vbulk=vbulk, sunvec=sunvec, matrix=ct
endif else begin
  thm_part_slice2d_fac, probe=probe, coord=coord, trange=trange, mag_data=mag_data, fail=fail, $
                vectors=xyz, bfield=bfield, vbulk=vbulk, sunvec=sunvec, matrix=ct
endelse
if keyword_set(fail) then return


; Transform data to the slice plane's coordinates
thm_part_slice2d_rotate, rotation=rotation, fail=fail, $ 
                vectors=xyz, bfield=bfield, vbulk=vbulk, sunvec=sunvec, matrix=rot  
                         
if keyword_set(fail) then return


; Apply custom transformation on top of the predefined ones 
thm_part_slice2d_orientslice, slice_x=slice_x, slice_z=slice_z, fail=fail, $ 
                vectors=xyz, bfield=bfield, vbulk=vbulk, sunvec=sunvec, matrix=mt
if keyword_set(fail) then return 



; Misc.
;------------------------------------------------------------

; Sort transformed vector grid
if keyword_set(xyz) then begin
  sorted = sort(xyz[*,0])
  xyz = xyz[sorted,*]
  datapoints = datapoints[sorted]
endif



; Create slice:
; 
; TYPE=0   Geometric Method
; TYPE=1   2D Nearest Neighbor Interpolation (testing only)
; TYPE=2   2D Linear Interpolation
; TYPE=3   3D Linear Interpolation
;------------------------------------------------------------


; Linear 2D interpolation from thm_esa_slice2D
if type eq 2 then begin

  dprint, dlevel=4, 'Using 2d linear interpolation'
  thm_part_slice2d_2di, datapoints, xyz, resolution, $
                          thetarange=thetarange, zdirrange=zdirrange, $
                          part_slice=part_slice, $
                          xgrid=xgrid, ygrid=ygrid, $
                          fail=fail

; Linear 3D Interpolation
endif else if type eq 3 then begin

  dprint, dlevel=4, 'Using 3d linear interpolation'
  thm_part_slice2d_3di, datapoints, xyz, resolution, $
                          drange=drange, displacement=displacement, $
                          part_slice=part_slice, $
                          xgrid=xgrid, ygrid=ygrid, $
                          fail=fail


; 2D Nearest Neighbor (for testing only)
endif else if type eq 1 then  begin

  dprint, dlevel=4, 'Using 2d nearest neighbor'
  thm_part_slice2d_nn, datapoints, xyz, resolution, slice_orient, $
                          part_slice=part_slice, $
                          xgrid=xgrid, ygrid=ygrid, $
                          slice_width=slice_width, $
                          shift=keyword_set(subtract_bulk) ? vbulk:0, $
                          fail=fail

; Geometric Method
endif else begin

  dprint, dlevel=4, 'Using geometric method'
  thm_part_slice2d_geo, data=datapoints, resolution=resolution, $
                        rad=rad, phi=phi, theta=theta, dr=dr, dp=dp, dt=dt, $ 
                        ct=ct, rot=rot, mt=mt, $
                        displacement=displacement, average_angle=average_angle, $
                        msg_obj=msg_obj, msg_prefix=msg, $
                        part_slice=part_slice, $
                        xgrid=xgrid, ygrid=ygrid, $
                        fail=fail

endelse

if keyword_set(fail) then begin
  dprint, dlevel=1, fail
  return
endif


; Apply smoothing
if keyword_set(smooth) then begin
  thm_part_slice2d_smooth, part_slice, smooth
endif



; If this run was used to calculate a flat-count slice then return through the same var
if keyword_set(fix_counts) then begin
  fix_counts = part_slice
  return
endif


; Apply count threshold/subtraction
; This will create a copy of the slice with all bins set to the specified
; threshold and use it for masking/subtraction. 
if keyword_set(count_threshold) or keyword_set(subtract_counts) then begin

  fix_counts = keyword_set(subtract_counts) ? subtract_counts:count_threshold

  thm_part_slice2d, ptrArray, ptrArray2, ptrArray3, ptrArray4, $
    ; Use a flat distribution at N counts
    fix_counts=fix_counts, $
    ; Time
    timewin=timewin, slice_time=slice_time_in, center_time=center_time, $
    ; Range
    erange=erange, thetarange=thetarange, zdirrange=zdirrange, $
    ; Orientations
    coord=coord_in, rotation=rotation, slice_x=slice_x, slice_norm=slice_z,  displacement=displacement_in, $
    ; Support Data
    mag_data=mag_data, vel_data=vel_data, $
    ; Type
    type=type, two_d_interp=two_d_interp, three_d_interp=three_d_interp, $
    ; Other
    units=units, resolution=resolution, average_angle=average_angle, smooth=smooth, $
    subtract_bulk=subtract_bulk, regrid=regrid_in, slice_width=slice_width, log=log, energy=energy, $
    fail=fail

  if ~array_equal(size(/dim,part_slice),size(/dim,fix_counts)) and ~keyword_set(fail) then begin
    fail = 'Dimension of reference slice do not match data'
  endif

  if keyword_set(fail) then begin
    fail = 'Error calculating count threshold:  ' + fail
    dprint, dlevel=1, fail
    return
  endif
  
  if keyword_set(subtract_counts) then begin
    part_slice = (part_slice - fix_counts) > 0
  endif
  
  if keyword_set(count_threshold) then begin
    btidx = where(part_slice lt fix_counts,nbt)
    if nbt gt 0 then begin
      part_slice[btidx] = 0
    endif
  endif

endif


; Pass out slice information for plotting
;------------------------------------------------------------

;loop over dist structures to get name(s), time range, and mass
for i=0, n_elements(ds)-1 do begin
  
  ;dist type name
  dname = array_concat( ((*ds[i]).data_name)[0], dname )
  
  ;time range of particle data
  times_ind = thm_part_slice2d_intrange(ds[i], trange, n=ndat)
  if ndat gt 0 then begin
    trc = [ min((*ds[i])[times_ind].time), $
            max((*ds[i])[times_ind].end_time) ]
    tr = minmax( array_concat(trc,tr) ) 
  endif
  
  ;mass, intra-mode mass differences checked elsewhere
  mass_arr = array_concat( ((*ds[i]).mass)[0], mass )

endfor

;don't repeat distribution types in name
dname = strjoin( dname[uniq(dname,sort(dname))],'/')

;warn if masses vary by more than 1% of the median
;this is primarily in case of distributions assuming different species
mass = median(mass_arr)
if max(abs(mass-mass_arr)/mass) gt .01 then begin
  dprint, dlevel=4, 'Assumed particle mass varies between distributions by > 1%.  '+ $
                    'Mass omitted from slice metadata.'
  mass = !values.f_nan  
endif 

;adjust radial range
if keyword_set(displacement) then begin
  rrange = sqrt(  (rrange^2 - displacement^2) > 0. )
endif 


slice_struct = {  $
             ; Data
              data: temporary(part_slice), $  ;data values
              xgrid: xgrid, $    ;x-axis values
              ygrid: ygrid, $    ;y-axis values
             ; Metadata
              probe: probe, $    ;probe
              dist: dname, $     ;type of distribution (string)
              mass: mass, $      ;mass in eV/(km/s)^2, will be NaN if mass varies too much
              coord: coord, $    ;coordinates used (string)
              rot: rotation, $   ;rotation used (string)
              units: units, $    ;units (string)
              xyunits: keyword_set(energy) ? 'eV':'km/s', $ ;vector units (string)
              twin: timewin, $   ;length of slice in sec
              type: type, $      ;integer specifying slice type (0,2,3)
              energy: keyword_set(energy), $ ;flag for energy plots
              zrange: drange, $  ;data range before interpolation
              trange: tr, $      ;total time range of used distributions
              rrange: rrange , $ ;instrument velocity/energy range
              rlog: keyword_set(log), $  ;flag for radial log plot
             ; Support Data
              shift: keyword_set(subtract_bulk) ? vbulk:0, $ ;for plotting energy limits
              bulk: keyword_set(vbulk) ? vbulk:0, $      ;averaged bulk velocity vector (km/s)
              bfield: keyword_set(bfield) ? bfield: 0, $ ;averaged bfield vector (nT)
              sunvec: keyword_set(sunvec) ? sunvec:0, $  ;sun vector
              coord_m: keyword_set(ct) ? ct:-1, $ ;DSL to COORD matrix
              rot_m: keyword_set(rot) ? rot:-1, $ ;COORD to ROTATION matrix
              orient_m: keyword_set(mt) ? mt:-1 $ ;COORD/ROTATION to slice plane coords matrix 
              }


msg = 'Finished slice at '+time_string(slice_time, format=5)
dprint, dlevel=2, msg 
if obj_valid(msg_obj) then msg_obj->update, msg 


; Fill dummy vars if present to preserve backwards compatibility
if arg_present(xgrid) then xgrid = 0
if arg_present(ygrid) then ygrid = 0
if arg_present(slice_info) then slice_info = 0


return

end
