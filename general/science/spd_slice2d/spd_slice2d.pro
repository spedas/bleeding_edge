
;+
;Function:
;  spd_slice2d
;
;
;Purpose:
;  Return an interpolated 2D slice of 3D particle data for plotting.
;
;
;Interpolation Methods:
;
;   3D Interpolation (default):
;     The entire 3-dimensional distribution is linearly interpolated onto a 
;     regular 3d grid and a slice is extracted from the volume.
;     
;   2D Interpolation:
;     Datapoints within the specified theta or z-axis range are projected onto 
;     the slice plane and linearly interpolated onto a regular 2D grid.      
;    
;   Geometric:
;     Each point on the plot is given the value of the bin it intersects.
;     This allows bin boundaries to be drawn at high resolutions.
;
;
;Calling Sequence:
;  
;  slice = spd_slice2d( data [,data2 [,data3 [,data4]]] $
;                       [,time=time [,window=window | samples=samples]]
;                       [trange=trange] ... )
;
;
;Example Usage:
;  slice = spd_slice2d(data, time=time)            ;get slice from distribution closest to TIME
;  slice = spd_slice2d(data, time=time, samples=4) ;use average of the 4 samples nearest to TIME
;  slice = spd_slice2d(data, time=time, window=10) ;use average of all data within [TIME,TIME+10sec]
;                                                  ;add "/center_time" for [TIME-5sec,TIME+5sec]  
;  slice = spd_slice2d(data, trange=trange)        ;use average of all data within TRANGE
;
;  slice = spd_slice2d(data, time=time, /three_d_interp) ;use 3D interpolation (default) 
;  slice = spd_slice2d(data, time=time, /two_d_interp)   ;use 2D interpolation
;  slice = spd_slice2d(data, time=time, /geometric)      ;use geometric interpolation
;
;  See crib sheets:  
;    THEMIS:  thm_crib_part_slice2d  (called by thm_part_slice2d)
;    MMS:     mms_slice2d_fpi_crib
;             mms_slice2d_hpca_crib
;    
;
;Arguments:
;  DATARR[#]: An array of pointers to 3D data structures.
;            See spd_dist_array.pro for more.
; 
; 
;Basic Keywords:
;  TRANGE: Two-element time range over which data will be averaged. (string or double)
;  TIME: Time at which the slice will be computed. (string or double)
;    SAMPLES: Number of nearest samples to TIME to average. (int/double)
;             If neither SAMPLES nor WINDOW are specified then default=1.
;    WINDOW: Length in seconds from TIME over which data will be averaged. (int/double)  
;      CENTER_TIME: Flag denoting that TIME should be midpoint for window instead of beginning.
;      
;    SUM_SAMPLES: Flag denoting that the data should be summed over the requested trange rather than averaged
;  
;  THREE_D_INTERP: Flag to use 3D interpolation method (described above)      
;  TWO_D_INTERP: Flag to use 2D interpolation method (described above)
;  GEOMETRIC: Flag to use geometric interpolation method (described above)
; 
;
;Orientation Keywords:
;  CUSTOM_ROTATION: Applies a custom rotation matrix to the data.  Input may be a
;                   3x3 rotation matrix or a tplot variable containing matrices.
;                   If the time window covers multiple matrices they will be averaged.
;                   This is applied before other transformations
;  ROTATION: Aligns the data relative to the magnetic field and/or bulk velocity.
;            This is applied after the CUSTOM_ROTATION. (BV and BE are invariant 
;            between coordinate systems)
;
;            Use MAG_DATA keyword to specify magnetic field vector.
;            Use VEL_DATA keyword to specify bulk velocity (optional).
;       
;     'BV':  The x axis is parallel to B field; the bulk velocity defines the x-y plane
;     'BE':  The x axis is parallel to B field; the B x V(bulk) vector defines the x-y plane
;     'xy':  (default) The x axis is along the data's x axis and y is along the data's y axis
;     'xz':  The x axis is along the data's x axis and y is along the data's z axis
;     'yz':  The x axis is along the data's y axis and y is along the data's z axis
;     'xvel':  The x axis is along the data's x axis; the x-y plane is defined by the bulk velocity 
;     'perp':  The x axis is the bulk velocity projected onto the plane normal to the B field; y is B x V(bulk)
;     'perp_xy':  The data's x & y axes are projected onto the plane normal to the B field
;     'perp_xz':  The data's x & z axes are projected onto the plane normal to the B field
;     'perp_yz':  The data's y & z axes are projected onto the plane normal to the B field
;     
;  SLICE_X & SLICE_NORM: These keywords respectively specify the slice plane's 
;                        x-axis and normal within the coordinates specified by  
;                        CUSTOM_ROTATION and ROTATION. Both keywords take 
;                        3-vectors as input.
;                       
;                        If SLICE_X is not specified then the given coordinate's 
;                        x-axis will be used. If SLICE_X is not perpendicular to 
;                        the normal it's projection onto the slice plane will be used.
;                        An error will be thrown if no projection exists.
;                        
;                        If SLICE_NORM is not specified then the given coordinate's
;                        z-axis will be used (slice along by x-y plane in those 
;                        coordinates).
;                 
;       examples:
;         Slice along the data's x-z plane: 
;           ROTATION='xz' 
;         
;         Slice plane's x axis is GSM x and y is in the direction of the bulk velocity:
;           CUSTOM_ROTATION='my_gsm_tvar', ROTATION='xvel'
;
;         Slice is perpendicular to "tvar1" and x axis is defined by projection of "tvar2"
;           SLICE_NORM='tvar1', SLICE_X='tvar2'
;
;
;  MAG_DATA: Name of tplot variable containing magnetic field data or 3-vector.
;            This will be used for slice plane alignment and must be in the 
;            same coordinates as the particle data.
;  VEL_DATA: Name of tplot variable containing the bulk velocity data or 3-vector.
;            This will be used for slice plane alignment and must be in the
;            same coordinates as the particle data.
;            If not set the bulk velocity will be automatically calculated
;            from the distribution (when needed).
;
;
;Other Keywords:
;  RESOLUTION: Integer specifying the resolution along each dimension of the
;              slice (defaults:  2D/3D interpolation: 150, geometric: 500) 
;  SMOOTH: An odd integer >=3 specifying the width of a smoothing window in # 
;          of points.  Smoothing is applied to the final plot using a gaussian 
;          convolution. Even entries will be incremented, 0 and 1 are ignored.
;
;  ENERGY: Flag to plot data against energy (in eV) instead of velocity.
;  LOG: Flag to apply logarithmic scaling to the radial measure (i.e. energy/velocity).
;       (on by default if /ENERGY is set)
;
;  ERANGE: Two element array specifying the energy range to be used in eV.
;
;  THETARANGE: (2D interpolation only)
;              Angle range, in degrees [-90,90], used to calculate slice.
;              Default = [-20,20]; will override ZDIRRANGE. 
;  ZDIRRANGE: (2D interpolation only)
;             Z-Axis range, in km/s, used to calculate slice.
;             Ignored if called with THETARANGE.
;
;  AVERAGE_ANGLE: (geometric interpolation only)
;                 Two element array specifying an angle range over which 
;                 averaging will be applied. The angle is measured 
;                 from the slice plane and about the slice's horizontal axis; 
;                 positive in the right handed direction. This will
;                 average over all data within that range. Note: for the 
;                 default rotation='xy', the angle is measured from the XY 
;                 slice plane and about the x-axis
;                    e.g. rotation='xy', average_angle=[-25,25] will average data within 25 degrees
;                         of the XY slice plane about it's x-axis
;                    or     
;                         rotation='yz', average_angle=[-25,25] will average data within 25 degrees
;                         of the YZ slice plane about it's y-axis
;
;  MSG_OBJ: Reference to dprint display object.
;  
;  DETERM_TOLERANCE:  tolerance of the determinant of the custom rotation matrix 
;           (maximum acceptable difference from determ(C)=1 where C is the 
;           user's custom rotation matrix); default is 1e-6
; 
;
;Output:
; Returns a structure to be passed to spd_slice2d_plot:
;      {
;       data: two dimensional array (NxN) containing the data to be plotted
;       xgrid: N dimensional array of x-axis values for plotting 
;       ygrid: N dimensional array of y-axis values for plotting
; 
;       project_name: name of project
;       spacecraft: spacecraft designation
;       data_name: string or string array containing the type(s) of distribution used
;
;       mass: particle mass in ev/(km/s)^2
;       units: the data's units
;       xyunits: the x & y axes' units
;       coord: placeholder for coordinate system label
;       rot: the applied rotation option
;       type: flag denoting interpolation type (0,2,3 for geometric, 2D, 3D respectively)
;       rlog: flag denoting radial log scaling
;
;       zrange: two-element array containing the range of the un-interpolated data 
;       rrange: two-element array containing the radial range of the data
;       trange: two-element array containing the numerical time range
;        
;       bulk: 3-vector containing the bulk velocity in the slice plane's coordinates
;       bfield: 3-vector containing the B-field in the slice plane's coordinates
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
;NOTES:
;   - Regions containing no data are assigned zeros instead of NaNs.
;   - Interpolation may occur across data gaps or areas with recorded zeroes
;     when using 3D interpolation (use geometric interpolation to see bins).
;   - The center/midpoint time of a distribution is used as it's timestamp
;     when determining it's inclusion in the requested time range.  The full
;     time range of all included samples is stored in the metadata.
;
;
;CREATED BY:
;  Aaron Flores, based on work by Bryan Kerr, Arjun Raj, and Xuzhi Zhou
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-03-26 12:33:55 -0700 (Mon, 26 Mar 2018) $
;$LastChangedRevision: 24954 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/spd_slice2d.pro $
;-

function spd_slice2d, input1, input2, input3, input4, $
                    ; Time options
                      time=time_in, $
                      window=window, $
                      center_time=center_time, $
                      trange=trange_in, $
                      samples=samples, $
                      sum_samples=sum_samples, $ ; sum the data rather than average
                    ; Orientations
                      custom_rotation=custom_rotation, $
                      determ_tolerance=determ_tolerance, $
                      rotation=rotation, $
                      slice_norm=slice_z, $
                      slice_x=slice_x, $
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
                      _extra = _extra

    compile_opt idl2


invalid = 0b
fail = ''


if ~ptr_valid(input1[0]) and ~is_struct(input1[0]) then begin
  fail = 'Invalid data.  Input must be pointer or structure array.'
  dprint, dlevel=1, fail
  return, invalid
endif

if undefined(trange_in) then begin
  if undefined(time_in) then begin
    fail = 'Please specifiy a time or time range over which to compute the slice.  For example: '+ $
           ssl_newline()+'  "TIME=t, WINDOW=w" or "TRANGE=tr" or "TIME=t, SAMPLES=n"'
    dprint, dlevel=1, fail
    return, invalid
  endif else begin
    if undefined(window) && undefined(samples) then begin
      samples = 1 ;use single closest distribution by default
    endif
  endelse
endif

valid_rotations = ['bv', 'be', 'xy', 'xz', 'yz', 'xvel', $
                   'perp', 'perp_xy', 'perp_xz', 'perp_yz']
if ~undefined(rotation) then begin
  if ~in_set(strlowcase(rotation),valid_rotations) then begin
    fail = 'Invalid rotation requested.  See spd_crib_slice2d for examples.'
    dprint, dlevel=1, fail
    return, invalid
  endif
endif



; Set default options
;------------------------------------------------------------
if ~undefined(time_in) then time = time_double(time_in[0])
if undefined(rotation) then rotation='xy'
if keyword_set(energy) && undefined(log) then log = 1
if rotation eq 'xyz' then rotation = 'xy'
if rotation eq 'perp_xyz' then rotation = 'perp_xy'

;Interpolation type:
if keyword_set(geometric) then type=0
if keyword_set(two_d_interp) then type = 2
if keyword_set(three_d_interp) then type = 3
if undefined(type) then type = 3


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
  if undefined(resolution) then resolution = 500
endif

if type ne 0 && keyword_set(average_angle) then begin
  dprint, dlevel=1, 'Angular averaging is only applicable to the geometric method.'+ $
                    'No averaging will be applied.'
  return, invalid
endif


msg = 'Processing slice at ' + time_string(time, tformat='YYYY/MM/DD hh:mm:ss.fff') +'... '
dprint, dlevel=2, msg, display_object=msg_obj 



; Aggregate inputs
;  -multiple inputs are allowed to make things easier on the user
;  -pointer arrays are used as a way of supporting dissimilar 
;   structures, which cannot be concatenated
;------------------------------------------------------------

;copy any structs to new pointer var, other inputs are copied and checked next
switch n_params() of 
  4: if is_struct(input4) then p4 = ptr_new(input4) else p4 = input4 
  3: if is_struct(input3) then p3 = ptr_new(input3) else p3 = input3
  2: if is_struct(input2) then p2 = ptr_new(input2) else p2 = input2
  1: if is_struct(input1) then p1 = ptr_new(input1) else p1 = input1
endswitch

;agregate valid pointers
ds = p1
if ptr_valid(p2) then ds = [ds,p2]
if ptr_valid(p3) then ds = [ds,p3]
if ptr_valid(p4) then ds = [ds,p4]



; Get the slice's time range
;------------------------------------------------------------

; get the time range if one was specified
if ~undefined(trange_in) then begin
  trange = minmax(time_double(trange_in))
endif

; get the time range if a time & window were specified instead
if undefined(trange) && keyword_set(window) then begin
  if keyword_set(center_time) then begin
    trange = [time - window/2d, $
              time + window/2d  ]
  endif else begin
    trange = [time, $
              time + window ]
  endelse
endif

; if no time range or window was specified then get a time range 
; from the N closest samples to the specied time
;   (defaults to 1 if SAMPLES is not defined)
if undefined(trange) then begin
  trange = spd_slice2d_nearest(ds, time, samples)
endif
  

; check that there is data in range before proceeding
for i=0, n_elements(ds)-1 do begin
  times_ind = spd_slice2d_intrange(ds[i], trange, n=ndat)
  n_samples = array_concat(ndat,n_samples)
endfor
n_samples = total(n_samples)
if n_samples lt 1 then begin
  fail = 'No particle data in the time window: '+strjoin(time_string(trange),', ')+ $
         '. Time samples may be at low cadence; try adjusting the time window.'
  dprint, dlevel=1, fail 
  return, invalid
endif
dprint, dlevel=3, strtrim(n_samples,2) + ' samples in time window'


; Extract particle data from structures
;  -apply energy limits
;  -average data over time window
;  -output r, phi, theta and dr, dphi, dtheta arrays
;------------------------------------------------------------
spd_slice2d_get_data, ds, trange=trange, erange=erange, energy=energy, fail=fail, $ 
                 data=datapoints, rad=rad, phi=phi, theta=theta, dr=dr, dp=dp, dt=dt, $
                 sum_samples=sum_samples
if keyword_set(fail) then return, invalid


; Known causes of an empty data variable should be caught before this.
if ~keyword_set(datapoints) then begin
  fail = 'Unknown error extracting data from particle distributions.'
  dprint, dlevel=0, fail
  return, invalid
endif


; Get original data and radial ranges for plotting
;  -ignore outliers that may be the result of sanitizations performed outside this routine
;  -this also effectively removes low-significance outliers at large velocities, which
;   can lead to overly large velocity scales for some instruments 
idx = where(datapoints gt 0,n)
if n gt 0 then begin
  dmoms = moment(alog10(datapoints[idx]),maxmom=2)
  min = 10^(dmoms[0] - 2*sqrt(dmoms[1])) ;ignore if < mean - 2*sigma 
  drange = minmax(datapoints[idx],min_value=min)

;*** affects interpolation in some cases ***
;  ;remove points below the minimum 
;  ;  -these points would be hidden on final plot if left and will only 
;  ;   slow the interpolation
;  idx = where(datapoints gt 0, n)
;  if n gt 0 then begin
;    datapoints = datapoints[idx]
;    rad = rad[idx]
;    phi = phi[idx]
;    theta = theta[idx]
;    dr = dr[idx]
;    dp = dp[idx]
;    dt = dt[idx]
;  endif
;
;  drange = [min(datapoints),max(datapoints)]
endif else begin
  drange = [0,0.]
endelse
rrange = [  min( rad - 0.5*dr ), max( rad + 0.5*dr )  ]


; Apply radial log scaling
if keyword_set(log) then begin
  spd_slice2d_rlog, rad, dr
endif


; Convert spherical data to cartesian coordinates for interpolation
if keyword_set(type) then begin
  spd_slice2d_s2c, rad,theta,phi, xyz
endif



; Get/apply coordinate transformations
;  -for 2D/3D interpolation the data is transformed here
;  -for geometric interpolation the data is transformed in spd_slice2d_geo
;  -support data is always rotated at each step
;------------------------------------------------------------

; Get support data for aligning slice
spd_slice2d_get_support, mag_data, trange, output=bfield
spd_slice2d_get_support, vel_data, trange, output=vbulk
spd_slice2d_get_support, sun_data, trange, output=sunvec
spd_slice2d_get_support, slice_x, trange, output=slice_x_vec
spd_slice2d_get_support, slice_z, trange, output=slice_z_vec


; Custom rotation
spd_slice2d_custom_rotation, custom_rotation=custom_rotation, trange=trange, fail=fail, $
         vectors=xyz, bfield=bfield, vbulk=vbulk, sunvec=sunvec, matrix=custom_matrix, $
         determ_tolerance=determ_tolerance
if keyword_set(fail) then return, invalid


; Built in rotation option
spd_slice2d_rotate, rotation=rotation, fail=fail, $ 
         vectors=xyz, bfield=bfield, vbulk=vbulk, sunvec=sunvec, matrix=rotation_matrix  
if keyword_set(fail) then return, invalid


; Rotation defined by slice normal/x axis options
spd_slice2d_orientslice, slice_x=slice_x_vec, slice_z=slice_z_vec, fail=fail, $ 
         vectors=xyz, bfield=bfield, vbulk=vbulk, sunvec=sunvec, matrix=orient_matrix
if keyword_set(fail) then return, invalid 


; Subtract bulk velocity vector
if keyword_set(subtract_bulk) && ~keyword_set(log) then begin
  spd_slice2d_subtract, vectors=xyz, velocity=vbulk, fail=fail
  if keyword_set(fail) then return, invalid
  ;as with rotations, this will be applied later for geometric interp
  geo_shift = vbulk
endif



; Misc.
;------------------------------------------------------------

; Sort transformed vector grid
;  -this ends up being necessary later 
if ~undefined(xyz) then begin
  sorted = sort(xyz[*,0])
  xyz = xyz[sorted,*]
  datapoints = datapoints[sorted]
endif



; Create slice:
; 
; TYPE=0   Geometric Interpolation
; TYPE=2   2D Linear Interpolation
; TYPE=3   3D Linear Interpolation
;------------------------------------------------------------

; Linear 2D interpolation from thm_esa_slice2D
if type eq 2 then begin

  dprint, dlevel=4, 'Using 2d linear interpolation'
  spd_slice2d_2di, datapoints, xyz, resolution, $
                   thetarange=thetarange, zdirrange=zdirrange, $
                   slice=slice, xgrid=xgrid, ygrid=ygrid, $
                   fail=fail

; Linear 3D Interpolation
endif else if type eq 3 then begin

  dprint, dlevel=4, 'Using 3d linear interpolation'
  spd_slice2d_3di, datapoints, xyz, resolution, drange=drange, $ 
                   slice=slice, xgrid=xgrid, ygrid=ygrid, $
                   fail=fail

; Geometric Method
endif else begin

  dprint, dlevel=4, 'Using geometric method'
  spd_slice2d_geo, data=datapoints, resolution=resolution, $
                   rad=rad, phi=phi, theta=theta, dr=dr, dp=dp, dt=dt, $
                   custom_matrix=custom_matrix, $
                   rotation_matrix=rotation_matrix, $
                   orient_matrix=orient_matrix, $
                   shift = geo_shift, $
                   average_angle=average_angle, $
                   msg_obj=msg_obj, msg_prefix=msg, $
                   slice=slice, xgrid=xgrid, ygrid=ygrid, $
                   fail=fail

endelse

if keyword_set(fail) then begin
  dprint, dlevel=1, fail
  return, invalid
endif


; Apply smoothing
if keyword_set(smooth) then begin
  spd_slice2d_smooth, slice, smooth
endif



; Get metadata and return slice structure
;------------------------------------------------------------

; loop over dist structures to get name(s) and time range
for i=0, n_elements(ds)-1 do begin
  
  ;dist type name
  data_name = array_concat( ((*ds[i]).data_name)[0], data_name )

  ;time range of particle data
  times_ind = spd_slice2d_intrange(ds[i], trange, n=ndat)
  if ndat gt 0 then begin
    trc = [ min((*ds[i])[times_ind].time), $
            max((*ds[i])[times_ind].end_time) ]
    tr = minmax( array_concat(trc,tr) ) 
  endif

endfor

; don't repeat distribution types in name
data_name = strjoin( spd_uniq(data_name), '/')


; Output structure
slice = {  $
         ; Data
          data: temporary(slice), $  ;data values
          xgrid: xgrid, $    ;x-axis values
          ygrid: ygrid, $    ;y-axis values

         ; Metadata
          project_name: ((*ds[0]).project_name)[0], $
          spacecraft: ((*ds[0]).spacecraft)[0], $
          data_name: data_name, $            ;names of distributions used (string)
          n_samples: n_samples, $            ;number of distributions used

          mass: ((*ds[0]).mass)[0], $    ;mass in eV/(km/s)^2
          units: ((*ds[0]).units_name)[0], $   ;data units
          xyunits: keyword_set(energy) ? 'eV':'km/s', $ ;x/y/r units (string)
          coord: '', $       ;placeholder for coordinates used (string)
          rot: rotation, $   ;rotation used (string)
          type: type, $      ;integer specifying slice type (0,2,3)
          energy: keyword_set(energy), $ ;flag for energy plots
          rlog: keyword_set(log), $  ;flag for radial log plot

          trange: tr, $      ;total time range of used distributions
          zrange: drange, $  ;data range after averaging but before interpolation
          rrange: rrange , $ ;instrument velocity/energy range

         ; Support Data
          shift: undefined(subtract_bulk) ? 0:vbulk, $ ;for plotting energy limits
          bulk: undefined(vbulk) ? 0:vbulk, $      ;bulk velocity vector
          bfield: undefined(bfield) ? 0:bfield, $ ;bfield vector
          sunvec: undefined(sunvec) ? 0:sunvec, $  ;sun vector
          custom_matrix: custom_matrix, $ ;applied custom rotation matrix
          rotation_matrix: rotation_matrix, $ ;rotation matrix from ROTATION option 
          orient_matrix: orient_matrix $ ;rotation matrix specified by SLICE_NORM/SLICE_X 
          }


msg = 'Finished slice at '+time_string(time, format=5)
dprint, dlevel=2, msg, display_object=msg_obj


return, slice

end
