;+
;Name
;  thm_crib_part_slice2d_adv
;
;Purpose:
;  A crib showing advanced usage of the 2D velocity slices code.
;     
;See also:
;  thm_crib_part_slice2d
;  thm_crib_part_slice2d_plot
;  thm_crib_part_slice2d_multi
;  thm_crib_part_slice1d
;
;Notes: 
;  Run "thm_ui_slice2d" on the IDL console to use for the GUI version.
;   (Also part of the plugins menu in the SPEDAS GUI) 
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2016-11-30 11:43:37 -0800 (Wed, 30 Nov 2016) $
;$LastChangedRevision: 22421 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_part_slice2d_adv.pro $;
;-

compile_opt idl2

;===========================================================
; Notes
;===========================================================

; Interpolation methods:
;------------------------------------
;  Geomtric:
;    Each point on the plot is given the value of the bin it instersects.
;    This allows bin boundaries to be drawn at high resolutions.
;  
;  2D Interpolation:
;    Datapoints within the specified theta or z-axis range are projected onto 
;    the slice plane and linearly interpolated onto a regular 2D grid. 
;  
;  3D Interpolation:
;    The entire 3-dimensional distribution is linearly interpolated onto a 
;    regular 3D grid and a slice is extracted from the volume.


; Slice Orientation:
;------------------------------------
; There are three options which specify the orientation of the slice plane:
;   Coordinates (COORD):
;     Specifies the starting coordinate system.
;
;   Rotation (ROTATION):
;     Specifies the slice's x and y axes with respect to the coordinate system.
;
;   Custom (SLICE_NORM,SLICE_X):
;     The slice plane's normal and x axis can be specified by passing a vectors
;     into the corresponding keyword.  These vectors are interpreted as being in 
;     system defined by the COORD and ROTATION.  
;
;
; Coordinates:
;   The coordinate system in which the slice will be oriented.
;   Options are 'DSL' (default), 'GSM', 'GSE' and the following magnetic
;   field aligned coordinates (field parallel to z axis).
;        
;    'xgse':  The x axis is the projection of the GSE x-axis
;    'ygsm':  The y axis is the projection of the GSM y-axis
;    'zdsl':  The y axis is the projection of the DSL z-axis
;    'RGeo':  The x is the projection of radial spacecraft position vector (GEI)
;    'mRGeo':  The x axis is the projection of the negative radial spacecraft position vector (GEI)
;    'phiGeo':  The y axis is the projection of the azimuthal spacecraft position vector (GEI), positive eastward
;    'mphiGeo':  The y axis is the projection of the azimuthal spacecraft position vector (GEI), positive westward
;    'phiSM':  The y axis is the projection of the azimuthal spacecraft position vector in Solar Magnetic coords
;    'mphiSM':  The y axis is the projection of the negative azimuthal spacecraft position vector in Solar Magnetic coords
;
;        
; Slice Orientation
;   The slice plane is oriented by using the following options to specify
;   its x and y axes with respect to the coordinate system.
;   ("BV," "BE", and "perp" will be invariant between coordinate systems).
;       
;    'BV':  The x axis is parallel to B field; the bulk velocity defines the x-y plane
;    'BE':  The x axis is parallel to B field; the B x V(bulk) vector defines the x-y plane
;    'xy':  (default) The x axis is along the coordinate's x axis and y is along the coordinate's y axis
;    'xz':  The x axis is along the coordinate's x axis and y is along the coordinate's z axis
;    'yz':  The x axis is along the coordinate's y axis and y is along the coordinate's z axis
;    'xvel':  The x axis is along the coordinate's x axis; the x-y plane is defined by the bulk velocity 
;    'perp':  The x axis is the bulk velocity projected onto the plane normal to the B field; y is B x V(bulk)
;    'perp_xy':  The coordinate's x & y axes are projected onto the plane normal to the B field
;    'perp_xz':  The coordinate's x & z axes are projected onto the plane normal to the B field
;    'perp_yz':  The coordinate's y & z axes are projected onto the plane normal to the B field



;===========================================================
; Keyword list
;   -examples of all keyword options to thm_part_slice2d
;===========================================================

;two_d_interp = 1 ; use 2D interpolation method
                  ; (see description at the top of this document) 

;three_d_interp = 1 ; use 2D interpolation method
                  ; (see description at the top of this document)

;coord = 'GSM' ; use GSM/GSE to use those coordinates
               ; (see description at the top of this document)

;rotation = 'BE' ; use BE rotation to orient slice
                 ; (see description at the top of this document)

;slice_norm = [1,0,0]  ; cut the slice perpendicular to the x-axis, and 
;slice_x    = [0,0,1]  ; use the z-axis as the slice's x-axis
                       ;  -both vectors are interpreted as being in the coordinates
                       ;   defined by COORD and/or ROTATION
                       ;  -SLICE_X is ignored if the normal is not specified
                       ;  -the projection of SLICE_X is used if it is not 
                       ;   already in the slice plane

;erange = [0,5000] ; set this keyword to the desired energy limits in eV
                   ; data outside this range will not be plotted

;units = 'eflux' ; set this keyword to change the units used ('DF' is default)
                 ; 'Counts', 'DF', 'Rate', 'CRate', 'Flux', 'EFlux'

;count_threshold = 1 ; set to 1 to remove any bins that fall below one-count after averaging

;subtract_counts = 2 ; subtract 2 counts from all data after averaging

;smooth = 9   ; apply gaussian smoothing to slice (number specifies window size in points)

;center_time = 1  ; set this keyword to make SLICE_TIME the center of the time window

;resolution = 150  ; set this keyword to change the resolution of the final plot

;average_angle = [-30,30]  ; average all data withing +- 30 degrees of the x axis

;regrid = [24,16,32] ; (2d/3d inerpolation only)
                     ; -The data will be interpolated using the nearest neighbor to
                     ;  24 x 16 x 32 points in phi, theta, and energy respectively.
                     ; -Energy will only be interpolated to an integer multiple of 
                     ;  its original resolution (e.g. 16 energies will only be 
                     ;  interpolated to 32, 64, ... other values will be rounded
                     ;  to these) 



;===========================================================
; Load Data
;===========================================================

; Set probe and time range
probe = 'b'
day = '2008-02-26/'
start_time = time_double(day + '04:52:30')
end_time = time_double(day + '04:53:00')

; Pad time range to ensure enough data is loaded
trange = [start_time - 90, end_time + 90]

; Set the time
slice_time = start_time ; time at which to calculate the slice
timewin = 30.           ; the window over which data will be averaged


; Load magnetic field and l2 velocity data
;  -B data is required for all rotations other than xy/yz/xz.  
;  -Velocity data is required for BV, BE, perp, and xvel. If velocity 
;    data is not loaded explicitly it will be automatically calculated 
;    from the raw distribution.
thm_load_fgm, probe=probe, datatype = 'fgs', level=2, coord='dsl', trange=trange
thm_load_esa, probe=probe, datatype = 'peib_velocity_dsl', trange=trange
mag_data = 'thb_fgs_dsl'
vel_data = 'thb_peib_velocity_dsl'


; Create array of ESA particle distributions
;  -ESA background removal options can be used inthis call (examples later)
peib_arr = thm_part_dist_array(probe=probe, type='peib', trange=trange)

peeb_arr = thm_part_dist_array(probe=probe, type='peeb', trange=trange)

; Create array of SST particle distributions
psif_arr = thm_part_dist_array(probe=probe, type='psif', trange=trange)



;===========================================================
; Examples
;===========================================================


; SST slice in GSM coordinates
; ----------------------------
;  -Use GSM coordinates
;  -Align the slice to the GSM x-z plane
thm_part_slice2d, psif_arr, slice_time=slice_time, timewin=timewin, $
                  /three_d_interp, $
                  COORD='GSM', $
                  rotation='xz', $
                  part_slice=part_slice

thm_part_slice2d_plot, part_slice


stop


; ESA slice using field aligned coordinates
; ----------------------------
;  -Specify field aligned coordinates variant with COORD
;  -By default the slice will be cut along the x-y plane in the 
;   specified FAC.
;  -All field aligned coordinates and roations require a tplot
;   variable containing magnetic field data
thm_part_slice2d, peib_arr, slice_time=slice_time, timewin=timewin, $
                  /three_d_interp, $
                  coord='rGeo', $        ; FAC list/descriptions at top of crib
                  mag_data=mag_data, $   ; must pass in tplot variable with magnetic field
                  part_slice=part_slice

thm_part_slice2d_plot, part_slice



stop


; ESA slice using field aligned coordinates and rotation
; ----------------------------

;  -Use ROTATION to align slice with the rGEO y-z plane, the 
;   slice's x axis will be along the rGEO y axis and its y axis
;   will be along rGEO z. 
thm_part_slice2d, peib_arr, slice_time=slice_time, timewin=timewin, $
                  /three_d_interp, $
                  coord='rGeo', $
                  rotation='yz', $   
                  mag_data=mag_data, $
                  part_slice=part_slice

thm_part_slice2d_plot, part_slice



stop


; ESA slice using field aligned coordinates & custom orientation
; ----------------------------
;  -This example uses the SLICE_NORM and SLICE_X keyword to align the slice.
;   The slice's x-axis will be parallel to the B field and the y-axis 
;   will be in the direction of the positive radial position vector.
thm_part_slice2d, peib_arr, slice_time=slice_time, timewin=timewin, $
                  /three_d_interp, $
                  coord='rGeo', $
                  mag_data=mag_data, $
                  slice_norm=[0,1,0], $   ;slice will be in x-z plane
                  slice_x=[0,0,1], $      ;slice will use z (bfield) as x-axis
                  part_slice=part_slice

thm_part_slice2d_plot, part_slice



stop


; Field/Velocity aligned ESA slice
; ----------------------------
;  -The 'BV' rotation will set the x-axis parallel to the B field, and
;   the y-axis will be in the direction of the bulk velocity vector.
;   This option along with "BE" and "perp" do not depend on the COORD option.
;  -A tplot variable containing velocity data can be specified.  If it is 
;   omitted the bulk velocity will be calculated from the particle distribution.
thm_part_slice2d, peib_arr, slice_time=slice_time, timewin=timewin, $
                  /three_d_interp, $
                  rotation='bv', $
                  mag_data=mag_data, $    ; specify mag data for rotation
                  vel_data=vel_data, $    ; specify velocity data for rotation
                  part_slice=part_slice

thm_part_slice2d_plot, part_slice


stop


; Field/Velocity aligned ESA slice with averaging
; ----------------------------
;  -Setting the AVERAGE_ANGLE keyword will average all data within 
;   the specified angle from the slice plane about the x-axis. 
; - Averaging may take up to 60+ seconds with full resolution (500)
;   this example uses lower range to decrease computation time.
thm_part_slice2d, peeb_arr, slice_time=slice_time, timewin=timewin, $
;                  /three_d_interp, $ ; only for /geometric. For interp this does not work
                  rotation='BV', $
                  mag_data=mag_data, $    ; specify mag data for rotation
                  vel_data=vel_data, $    ; specify velocity data for rotation
                  average_angle=[-30,30], $   ; min/max to avg. about x (B) axis; could be +/- 90 takes long
                  part_slice=part_slice

thm_part_slice2d_plot, part_slice


stop



; Field/Velocity aligned SST slice with averaging
; ----------------------------
;  -The performs the same operation as the last example with SST data.
;  -The averaging range has been increased to include a larger portion of the distribution. 
thm_part_slice2d, psif_arr, slice_time=slice_time, timewin=timewin, $
;                  /three_d_interp, $ ; works only for /geometric (default). For interp this does not wor
                  rotation='bv', $  
                  mag_data=mag_data, $
                  average_angle=[-45,45], $   ; min/max to average about x
                  part_slice=part_slice

thm_part_slice2d_plot, part_slice


stop



; Minimum counts 
; ----------------------------
;  -A minimum count level can be set with the COUNT_THRESHOLD.
;   Any data that falls below the specified number after avaraging
;   will be removed. 
thm_part_slice2d, psif_arr, slice_time=slice_time, timewin=timewin, $
                  COORD='GSE', $             ; GSE coordinates
                  count_threshold = 0.5, $     ; mask bins with less than 0.5 counts/s
                  part_slice=part_slice

thm_part_slice2d_plot, part_slice


stop


; Background subtraction
; ----------------------------
;  -Setting the SUBTRACT_COUNTS keyword instead will subtract the 
;   specified number of counts from the entire distribution. 
thm_part_slice2d, psif_arr, slice_time=slice_time, timewin=timewin, $
                  COORD='GSE', $             ; GSE coordinates
                  subtract_counts = 0.5, $     ; subtract 0.5 counts from all data 
                  part_slice=part_slice

thm_part_slice2d_plot, part_slice


stop


; Plot multiple distributions
; ----------------------------
;  -Up to four distribution arrays can be used to create a single slice.
thm_part_slice2d, psif_arr, peib_arr, $     ; pass in up to four distribution arrays
                  slice_time=slice_time, timewin=timewin, $
                  /three_d_interp, $
                  COORD = 'GSE', $          ; GSE coords
                  erange = [0,200000], $    ; limit energy range to exclude 
                                            ; higher SST energies
                  part_slice=part_slice

; Plot
thm_part_slice2d_plot, part_slice


stop


; Plot multiple distributions against energy
; ----------------------------
;  -By default the /ENERGY option will use radial log scaling,
;   set LOG=0 to use linear scaling.
thm_part_slice2d, psif_arr, peib_arr, $     ; pass in up to four distribution arrays
                  slice_time=slice_time, timewin=timewin, $
                  /three_d_interp, $
                  COORD = 'GSE', $          ; GSE coords
                  erange = [10,200000], $    ; limit energy range
                  /energy, $
;                  log=0, $
                  part_slice=part_slice

; Plot
thm_part_slice2d_plot, part_slice


stop

  
                     

END

