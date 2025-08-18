;+
;Purpose: A basic overview of how to obtain and plot two-dimentional slices of 
;         SST and/or ESA particle distributions. 
;         
;         Run "thm_ui_slice2d" on the IDL console to use for the GUI version.
;
;
;Methods:
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
;     
;
;Coordinates:
;  The coordinate system in which the slice will be oriented.
;  Options are 'DSL' (default), 'GSM', 'GSE' and the following magnetic
;  field aligned coordinates (field parallel to z axis).
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
;Slice Orientation
;  The slice plane is oriented by using the following options to specify
;  its x and y axes with respect to the coordinate system.
;  ("BV," "BE", and "perp" will be invariant between coordinate systems).
;       
;    'BV':  The x axis is parallel to B field; the bulk velocity defines the x-y plane
;    'BE':  The x axis is parallel to B field; the B x V(bulk) vector defines the x-y plane
;    'perp':  The x axis is the bulk velocity projected onto the plane normal to the B field; y is B x V(bulk)
;    'xy':  (default) The x axis is along the coordinate's x axis and y is along the coordinate's y axis
;    'xz':  The x axis is along the coordinate's x axis and y is along the coordinate's z axis
;    'yz':  The x axis is along the coordinate's y axis and y is along the coordinate's z axis
;    'xvel':  The x axis is along the coordinate's x axis; the x-y plane is defined by the bulk velocity 
;    'perp_xy':  The coordinate's x & y axes are projected onto the plane normal to the B field
;    'perp_xz':  The coordinate's x & z axes are projected onto the plane normal to the B field
;    'perp_yz':  The coordinate's y & z axes are projected onto the plane normal to the B field
;     
;
;OTHER: 
;
;  For more detailed/advanced usage see:
;    thm_crib_part_slice2d_adv.pro
;    thm_crib_part_slice2d_multi.pro
;
;
;NOTES: 
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2016-11-30 11:48:57 -0800 (Wed, 30 Nov 2016) $
;$LastChangedRevision: 22422 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/basic/thm_crib_part_slice2d.pro $
;
;-

compile_opt idl2

thm_init

nl = ssl_newline()

print, nl,'Starting basic 2D particle distribution slice crib.',nl


;--------------------------------------------------------------------------------------
;Generate basic slice from ESA data
;--------------------------------------------------------------------------------------

;set time range
trange = '2008-02-26/' + ['04:54','04:55']

;esa ion burst data
dist_arr = thm_part_dist_array(probe='b',type='peib', trange=trange)

;generate a 30 second slice starting at the beginning of the time range
thm_part_slice2d, dist_arr, slice_time=trange[0], timewin=30, part_slice=slice

;plot the output
thm_part_slice2d_plot, slice

print, nl,'This example shows a basic slice of ESA burst data (ions) along the DSL xy plane.'
print, 'The default method will produce a plot with visible bin boundaries.'
print, 'The red line is the projection of the bulk velocity vector.',nl

stop


;--------------------------------------------------------------------------------------
;Generate basic slice using 2D interpolation
;--------------------------------------------------------------------------------------

;set time range
trange = '2008-02-26/' + ['04:54','04:55']

;esa ion burst data
dist_arr = thm_part_dist_array(probe='b',type='peib', trange=trange)

;generate an identical cut using 2D interpolation
thm_part_slice2d, dist_arr, slice_time=trange[0], timewin=30, part_slice=slice, $
                  /two_d_interp

thm_part_slice2d_plot, slice

print, nl,'This is an identical cut produced using the 2D interplation method.'
print, 'This method linearly interpolates all data within a specified range '
print, 'onto the slice plane (default is +-20 degrees)',nl 

stop


;--------------------------------------------------------------------------------------
;Generate basic slice using 3D interpolation
;--------------------------------------------------------------------------------------

;set time range
trange = '2008-02-26/' + ['04:54','04:55']

;esa ion burst data
dist_arr = thm_part_dist_array(probe='b',type='peib', trange=trange)

;generate an identical cut using 3D interpolation
thm_part_slice2d, dist_arr, slice_time=trange[0], timewin=30, part_slice=slice, $
                  /three_d_interp

thm_part_slice2d_plot, slice

print, nl,'Another identical cut using the 3D interpolation method,'
print, 'Here the entire distribution is linearly interpolated in 
print, 'three dimensions and a slice is extracted.',nl

stop


;--------------------------------------------------------------------------------------
;Basic ESA background removal
;--------------------------------------------------------------------------------------

;set time range
trange = '2008-02-26/' + ['04:54','04:55']

;esa ion burst data
dist_arr = thm_part_dist_array(probe='b',type='peib', trange=trange)

;Background removal is enabled by default with the options listed below.
;See thm_crib_esa_bgnd_remove for more info.
;  bgnd_remove/esa_bgnd_remove:  Flag to switch background removal on/off (set to 0 to disable)
;  bgnd_type:  Type of removal ('anode', 'omni', 'angle')
;  bgnd_npoints:  Number of points used to calculate background
;  bgnd_scale:  Factor to multiply calculated background by
thm_part_slice2d, dist_arr, slice_time=trange[0], timewin=30, part_slice=slice, $
                  /bgnd_remove, bgnd_type='anode', bgnd_npoints=3, bgnd_scale=1.0, $
                  /three_d_interp

thm_part_slice2d_plot, slice

print, nl,'Another identical cut using the 3D interpolation method.'
print, 'Also, the ESA background removal is explicitly applied; '
print, 'you can change settings (or into "eflux" or "counts" as needed.'
print, 'Here main point is: the entire distribution is linearly interpolated in 
print, 'three dimensions and a slice is extracted.',nl

stop



;--------------------------------------------------------------------------------------
;Smoothing
;--------------------------------------------------------------------------------------

;set time range
trange = '2008-02-26/' + ['04:54','04:55']

;esa ion burst data
dist_arr = thm_part_dist_array(probe='b',type='peib', trange=trange)

;Increase the smoothing width to create smoother plots.
;The value supplied to the SMOOTH keyword is the width (in points)
;of the gaussian blur that is applied to the slice data.
;2D interpolate and 3D interpolation use smooth=3 by default.
thm_part_slice2d, dist_arr, slice_time=trange[0], timewin=30, part_slice=slice, $
                  smooth=15, /three_d_interp

;Add contour lines to the plot
thm_part_slice2d_plot, slice

print,nl,'Set the SMOOTH keyword to specify the width of the smoothing window.'
print, '(in # of points).  2D interpolate and 3D interpolation use smooth=3 
print, 'by default.',nl

stop


;--------------------------------------------------------------------------------------
;Units / Show N count level
;--------------------------------------------------------------------------------------

;set time range
trange = '2008-02-26/' + ['04:54','04:55']

;esa ion burst data
dist_arr = thm_part_dist_array(probe='b',type='peib', trange=trange)

;This example uses the UNITS keyword to create a slice in counts.
;   valid units are:  'df', 'flux', 'eflux', 'counts', and 'rate'
thm_part_slice2d, dist_arr, slice_time=trange[0], timewin=30, part_slice=slice_counts, $
                  units='counts', /three_d_interp

;get default phase space density slice
thm_part_slice2d, dist_arr, slice_time=trange[0], timewin=30, part_slice=slice_df, $
                  /two_d_interp

;plot counts slice
thm_part_slice2d_plot, slice_counts, window=2

;plot DF slice with contour line at 1 count
thm_part_slice2d_plot, slice_df, window=1
spd_slice2d_add_line, slice_counts, 0.1

;plot DF slice with dotted colored contour lines at 1, 5, and 10 count
;   see IDL documentation for CONTOUR procedure for valid keywords 
thm_part_slice2d_plot, slice_df, window=0
spd_slice2d_add_line, slice_counts, [1,5,10], c_colors=[60,170,230], c_linestyle=1


print,nl,'Use the UNITS keyword to select what units the data will be presented in.'
print,nl,'Use spd_slice2d_add_line to add annotation in different units'
print, ' (e.g. "Counts", "DF", "Rate", "Flux", "EFlux")',nl

stop


;--------------------------------------------------------------------------------------
;Plot Against Energy
;--------------------------------------------------------------------------------------

;set time range
trange = '2008-02-26/' + ['04:54','04:55']

;esa ion burst data
dist_arr = thm_part_dist_array(probe='b',type='peib', trange=trange)

;Setting the /ENERGY keyword will plot the data against energy instead of velocity.
;By default this will use radial log scaling, to use linear scaling use LOG=0.
thm_part_slice2d, dist_arr, slice_time=trange[0], timewin=30, part_slice=slice, $
                  /energy, /three_d_interp ;, log=0

thm_part_slice2d_plot, slice

print,nl,'Use the ENERGY keyword to plot the data against energy instead of velocity.'
print, 'Energy plots will use radial log scaling; use "log=0" for linear scaling.',nl

stop

;--------------------------------------------------------------------------------------
;Basic Orientation
;--------------------------------------------------------------------------------------

;set time range
trange = '2008-02-26/' + ['04:54','04:55']

;esa ion burst data
dist_arr = thm_part_dist_array(probe='b',type='peib', trange=trange)

;This will produce a slice along the DSL xz plane.
;See the top of this crib for more options.
thm_part_slice2d, dist_arr, slice_time=trange[0], timewin=30, part_slice=slice, $ 
                  rotation='xz', /three_d_interp

thm_part_slice2d_plot, slice


print,nl,'This example cuts along the DSL xz plane instead of xy'
print, 'See the documentation at the top of this crib for a full '
print, 'description of the available rotations.',nl

stop


;--------------------------------------------------------------------------------------
;Basic Field Aligned Orientation
;--------------------------------------------------------------------------------------

;set time range
trange = '2008-02-26/' + ['04:54','04:55']

;esa ion burst data
dist_arr = thm_part_dist_array(probe='b',type='peib', trange=trange)

;Field aligned rotations require magnetic field data to be loaded beforehand.
thm_load_fit, probe='b', datatype='fgs', coord='dsl', suff='_dsl', trange=trange ; could be FGL (averaged later)
 
thm_load_esa, probe='b', datatype='peib_velocity_dsl', trange=trange ; load ground precomputed moments, can be other

;This example aligns the slice plane along the BV plane.
;The MAG_DATA keyword is used to specify a tplot variable containing magnetic field data.
;The VEL_DATA keyword is used to specify a tplot variable containing a bulk velocity vector.
;  -bulk velocity is calculated from distribution if tplot variable is not specified
;These vectors will be averaged over the time range of the slice.
thm_part_slice2d, dist_arr, slice_time=trange[0], timewin=30, part_slice=slice, $
       rotation='BV', mag_data='thb_fgs_dsl', vel_data='thb_peib_velocity_dsl', /three_d_interp

thm_part_slice2d_plot, slice

print, nl,'This example orients the slice along a plane defined by the magnetic'
print, 'field and bulk velocity vectors.  Orientations that use the magnetic ' 
print, 'field will require support data to be loaded first.  Bulk velocity can '
print, 'be calculated automatically or loaded separately.  See the documentation '
print, 'at the top of this crib for a list of valid inputs to the ROTATION keyword.',nl

stop


;--------------------------------------------------------------------------------------
;Basic Orientation and Coordinates
;--------------------------------------------------------------------------------------

;set time range
trange = '2008-02-26/' + ['04:54','04:55']

;esa ion burst data
dist_arr = thm_part_dist_array(probe='b',type='peib', trange=trange)

;This example combines the COORD and ROTATION keywords.
;The COORD keyword specifies GSM coordinates and the ROTATION keyword specifies 
;the slice plane's orientation with respect to those coordinates.
;The 'xvel' rotation aligns the slice's x axis with the (GSM) x axis and the 
;slice's y axis is defined by the bulk velocity.
thm_part_slice2d, dist_arr, slice_time=trange[0], timewin=30, part_slice=slice, $
                  coord='gsm', rotation='xvel', /three_d_interp

thm_part_slice2d_plot, slice

print,nl,'This example plots a slice oriented along the GSM x axis and the ' 
print, 'bulk velocity vector.  See the documentation at the top of this crib '
print, 'for a list of valid inputs to the COORD and ROTATION keywords.',nl

stop


;--------------------------------------------------------------------------------------
;Eclipse Corrections
;--------------------------------------------------------------------------------------

;set time range
trange = '2011-11-28/' + ['21:50','22:55']

;Eclipse corrections are loaded when the raw data is loaded.
;  use_eclipse_corrections = 0  No corrections are loaded (default).
;                          = 1  Load partial corrections (not recommended)
;                          = 2  Load full corrections.
dist_corr = thm_part_dist_array(probe='b',type='peif', trange=trange, $
                                    use_eclipse_corrections=2)

;load data without corrections for comparison
dist_uncorr = thm_part_dist_array(probe='b',type='peif', trange=trange)

;create idential plots from each data set
thm_part_slice2d, dist_corr, slice_time=trange[0], timewin=300, part_slice=slice_corr
thm_part_slice2d, dist_uncorr, slice_time=trange[0], timewin=300, part_slice=slice_uncorr

;compare
zrange = [1e-13,1e-7]
thm_part_slice2d_plot, slice_corr, zrange=zrange, window=0, title='Corrected' 
thm_part_slice2d_plot, slice_uncorr, zrange=zrange, window=1, title='Uncorrected'


print,nl,'This example demonstrates how to use spin corrections when the ' 
print, 'spacecraft is in the Earth''s shadow.  Corrections are loaded with '
print, 'the raw particle data and applied when plot is generated.',nl

stop


;--------------------------------------------------------------------------------------
;Plotting options (standard)
;--------------------------------------------------------------------------------------

;set time range
trange = '2008-02-26/' + ['04:54','04:55']

;esa ion burst data
dist_arr = thm_part_dist_array(probe='b',type='peib', trange=trange)

;generate slice
thm_part_slice2d, dist_arr, slice_time=trange[0], timewin=30, part_slice=slice, $
                  /three_d_interp

;Set tick numbers, character size, and range keywords.
;Keywords with an axis prefix can be set for all axes.
; (e.g. xticks/yticks/zticks)
thm_part_slice2d_plot, slice, $
                       charsize = 1.5, $  ;set charcter size to 1.5 times the default
                       xticks = 6, $  ;set number of major x ticks
                       yminor = 2, $  ;set number of minor y ticks
                       zrange = [1e-15,1e-9]  ;specify the z axis range
                       zprecision = 2 ;specify number of significant digits for 
                                      ;tick annotations

print,nl,'This example demonstrates the keywords that control some of the
print, 'standard annotation options (character size, ticks, ranges, and
print, 'numerical annotations)',nl

stop


;--------------------------------------------------------------------------------------
;Plotting options (miscellaneous)
;--------------------------------------------------------------------------------------

;set time range
trange = '2008-02-26/' + ['04:54','04:55']

;esa ion burst data
;  -use /get_sun_direction keyword to load requisite 
;   data for plotting sun direction vector
dist_arr = thm_part_dist_array(probe='b',type='peib', trange=trange, /get_sun)

;load B field data so it can be plotted on slice 
thm_load_fit, probe='b', datatype='fgs', coord='dsl', suff='_dsl', trange=trange

;generate slice
thm_part_slice2d, dist_arr, slice_time=trange[0], timewin=30, part_slice=slice, $
                  mag_data='thb_fgs_dsl', /three_d_interp

;Various keywords control other aspects of the plot.
;  -/sundir requires that thm_part_dist_array is called with /get_sun_direction
;  -/plotbfield requires that mag_data was specified to thm_part_slice2d
;  -sun direction and B field vectors are scaled to the size of the plotting
;   area, i.e. an in-plane vector will be drawn to the x/y maximum
;   while an orthogonal vector will not appear
thm_part_slice2d_plot, slice, $
                       olines = 0, $     ;do not plot contour lines
                       plotbulk = 0, $   ;do not plot velocity vector 
                       plotaxes = 0, $   ;do not plot axis zeros
                       ecircle = 1, $    ;plot instrument's energy limits
                       sundir = 1, $     ;plot projection of sun direction
                       plotbfield = 1    ;plot projection of B field


print,nl,'This example demonstrates the keywords that control some of the
print, 'non-standard annotations seen on slice plots (plotting of bulk
print, 'velocity, sun direction, energy limits, and contour lines).',nl

stop


;--------------------------------------------------------------------------------------
;Plotting options (exporting)
;--------------------------------------------------------------------------------------

;set time range
trange = '2008-02-26/' + ['04:54','04:55']

;esa ion burst data
dist_arr = thm_part_dist_array(probe='b',type='peib', trange=trange)

;generate slice
thm_part_slice2d, dist_arr, slice_time=trange[0], timewin=30, part_slice=slice, $
                  /three_d_interp

;The EXPORT keyword can be used to automatically produce .png or .eps 
;images of the plot.  Set export='filename' to write a .png file and
;add /EPS to use postscript output.
thm_part_slice2d_plot, slice, export='slice_crib_plot' ;, /eps

print,nl,'This example demostrates how to automatically export a plot '
print, 'to a png image or postscript file.  This should create a '
print, '"slice_crib_plot.png" in your current home directory.',nl

stop



print, 'End of crib.'

end

