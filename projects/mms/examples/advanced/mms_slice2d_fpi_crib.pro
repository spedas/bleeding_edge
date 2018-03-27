;+
;Purpose:
;  Crib sheet demonstrating how to obtain particle distribution slices 
;  from MMS FPI data using spd_slice2d.
;  
;  This version is meant to work with v3.0.0+ of the FPI CDFs
;
;  Run as script or copy-paste to command line.
;    (examples containing loops cannot be copy-pasted to command line)
;
;
;Field-aligned coordinate descriptions:
;  'BV':  The x axis is parallel to B field; the bulk velocity defines the x-y plane
;  'BE':  The x axis is parallel to B field; the B x V(bulk) vector defines the x-y plane
;  'xy':  (default) The x axis is along the coordinate's x axis and y is along the coordinate's y axis
;  'xz':  The x axis is along the coordinate's x axis and y is along the coordinate's z axis
;  'yz':  The x axis is along the coordinate's y axis and y is along the coordinate's z axis
;  'xvel':  The x axis is along the coordinate's x axis; the x-y plane is defined by the bulk velocity 
;  'perp':  The x axis is the bulk velocity projected onto the plane normal to the B field; y is B x V(bulk)
;  'perp_xy':  The coordinate's x & y axes are projected onto the plane normal to the B field
;  'perp_xz':  The coordinate's x & z axes are projected onto the plane normal to the B field
;  'perp_yz':  The coordinate's y & z axes are projected onto the plane normal to the B field
;
;Notes:
;  -FPI data is large and can be very memory intensive!  It is recommended 
;   that no more than a few minutes of data is loaded at a time for ions
;   and less for electrons.
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-03-26 12:48:52 -0700 (Mon, 26 Mar 2018) $
;$LastChangedRevision: 24955 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_slice2d_fpi_crib.pro $
;-



;======================================================================
; Basic
;======================================================================

;setup
probe='1'
level='l2'
species='i'
data_rate='brst'

name =  'mms'+probe+'_d'+species+'s_dist_'+data_rate

trange=['2015-10-16/13:06', '2015-10-16/13:07'] ;time range to load
time = '2015-10-16/13:06:00' ;slice time

;load particle data into tplot
mms_load_fpi, data_rate=data_rate, level=level, datatype='d'+species+'s-dist', $
              probe=probe, trange=trange, min_version='2.2.0'

;reformat data from tplot variable into compatible 3D structures
dist = mms_get_dist(name, trange=trange)

;get single distribution
;  -3d/2d interpolation show smooth contours
;  -3d interpolates entire volume
;  -2d interpolates projection of a subset of data near the slice plane 
;  -geometric interpolation is slow but shows bin boundaries
;---------------------------------------------
slice = spd_slice2d(dist, time=time) ;3D interpolation
;slice = spd_slice2d(dist, time=time, /two) ;2D interpolation
;slice = spd_slice2d(dist, time=time, /geo) ;geometric interpolation

;average all data in specified time window
;slice = spd_slice2d(dist, time=time, /geo, window=0.5)  ; window (sec) starts at TIME  
;slice = spd_slice2d(dist, time=time, /geo, window=0.5, /center_time)  ; window centered on TIME
 
;average specific number of distributions (uses N closest to specified time)
;slice = spd_slice2d(dist, time=time, /geo, samples=3)

;plot
spd_slice2d_plot, slice


stop


;======================================================================
; Field-aligned slices
;======================================================================

probe='1'
level='l2'
species='i'
data_rate='brst'

name =  'mms'+probe+'_d'+species+'s_dist_'+data_rate
bname = 'mms'+probe+'_fgm_b_gse_'+data_rate+'_l2_bvec' ;name of bfield vector
vname = 'mms'+probe+'_d'+species+'s_bulkv_gse_'+data_rate     ;name of bulk velocity vector

trange=['2015-10-16/13:06', '2015-10-16/13:07']
time = '2015-10-16/13:06:00'

mms_load_fpi, data_rate=data_rate, level=level, datatype='d'+species+'s-dist', $
              probe=probe, trange=trange, min_version='2.2.0'

dist = mms_get_dist(name, trange=trange)

;load B field data
mms_load_fgm, probe=probe, trange=trange, level='l2', data_rate=data_rate

;load velocity moment
mms_load_fpi, data_rate=data_rate, level=level, datatype='d'+species+'s-moms', $
              probe=probe, trange=trange, min_version='2.2.0'

;combine separate velocity components
;join_vec, vname + ['x','y','z']+'_dbcs_brst', vname

;field/velocity aligned slice
;  -the plot's x axis is parallel to the B field
;  -the plot's y axis is defined by the bulk velocity direction
;---------------------------------------------
slice = spd_slice2d(dist, time=time, window=window, $
                    rotation='bv', mag_data=bname, vel_data=vname)

;plot
spd_slice2d_plot, slice


stop


;======================================================================
; Export time series
;======================================================================
probe='1'
level='l2'
species='i'
data_rate='brst'

name =  'mms'+probe+'_d'+species+'s_dist_'+data_rate

trange=['2015-10-16/13:06', '2015-10-16/13:07']

mms_load_fpi, data_rate=data_rate, level=level, datatype='d'+species+'s-dist', $
              probe=probe, trange=trange, min_version='2.2.0'

dist = mms_get_dist(name, trange=trange)

;produce a plot of 0.5 seconds of data every 10 seconds for 1 minute
times = time_double(trange[0]) + 10 * findgen(7)
window = 0.5

for i=0, n_elements(times)-1 do begin

  slice = spd_slice2d(dist, time=times[i], window=window)

  filename = 'mms'+probe+'_'+species+'_'+time_string(times[i],format=2)

  ;plot and write .png image to current directory
  spd_slice2d_plot, slice, export=filename ;,/eps

endfor

;======================================================================
; Subtract error and subtract bulk velocity from the data prior to plotting
;======================================================================

probe='1'
level='l2'
species='i'
data_rate='brst'

name =  'mms'+probe+'_d'+species+'s_dist_'+data_rate
error_name = 'mms'+probe+'_d'+species+'s_disterr_'+data_rate
vel_name = 'mms'+probe+'_d'+species+'s_bulkv_gse_'+data_rate

trange=['2015-10-16/13:06', '2015-10-16/13:07']
time = '2015-10-16/13:06:00'

mms_load_fpi, data_rate=data_rate, level=level, datatype=['d'+species+'s-dist', 'd'+species+'s-moms'], probe=probe, trange=trange

; note: both error and /subtract_error keywords required; 'error' keyword specifies the disterr variable name
dist = mms_get_dist(name, trange=trange, error=error_name, /subtract_error)

; vel_data and /subtract_bulk keywords are required to subtract the bulk velocity
slice = spd_slice2d(dist, time=time, vel_data=vel_name, /subtract_bulk)

; plot the slice with error and bulk velocity subtracted
spd_slice2d_plot, slice

stop

;======================================================================
; Sum over the requested trange rather than averaging
; using the keyword /sum_samples in the call to spd_slice2d
;======================================================================

probe='1'
level='l2'
species='i'
data_rate='brst'

name =  'mms'+probe+'_d'+species+'s_dist_'+data_rate
trange=['2015-10-16/13:06', '2015-10-16/13:07']
time = '2015-10-16/13:06:00'

mms_load_fpi, data_rate=data_rate, level=level, datatype='d'+species+'s-dist', probe=probe, trange=trange

dist = mms_get_dist(name, trange=trange)

; /sum_samples keyword required to sum over the trange instead of averaging
; the following sums over 100 samples, starting a time set via time keyword
slice = spd_slice2d(dist, time=time, samples=100, /sum_samples)

; plot the slice 
spd_slice2d_plot, slice

stop

end