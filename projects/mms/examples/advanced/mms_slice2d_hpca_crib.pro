;+
;Purpose:
;  Crib sheet demonstrating how to obtain particle distribution slices 
;  from MMS HPCA data using spd_slice2d.
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
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-10-12 11:41:08 -0700 (Thu, 12 Oct 2017) $
;$LastChangedRevision: 24148 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_slice2d_hpca_crib.pro $
;-

;===========================================================================
; Basic
;===========================================================================

;setup
probe = '1'
level = 'l2'
species = 'hplus'
data_rate = 'srvy'

name = 'mms'+probe+'_hpca_'+species+'_phase_space_density'

timespan, '2015-10-16/13:06:00', 1, /min  ;time range to load
trange = timerange()
time = trange[0]  ;slice time 

; load data; note that the /center_measurement keyword is required 
; due to assumptions made in mms_get_dist (or the routines it calls)
mms_load_hpca, /center_measurement, probes=probe, trange=trange, data_rate=data_rate, level=level, datatype='ion'

;reformat data from tplot variables into compatible 3D structures
dist = mms_get_dist(name)

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
;slice = spd_slice2d(dist, time=time, /geo, window=20)  ; window (sec) starts at TIME  
;slice = spd_slice2d(dist, time=time, /geo, window=20, /center_time)  ; window centered on TIME

;average specific number of distributions (uses N closest to specified time)
;slice = spd_slice2d(dist, time=time, /geo, samples=3)      
        
;plot
spd_slice2d_plot, slice

stop

;======================================================================
; Field-aligned slices
;======================================================================

probe = '1'
level = 'l2'
species = 'hplus'
data_rate = 'srvy'

name = 'mms'+probe+'_hpca_'+species+'_phase_space_density'
bname = 'mms'+probe+'_fgm_b_gse_srvy_l2_bvec'             ;name of bfield vector
vname = 'mms'+probe+'_hpca_'+species+'_ion_bulk_velocity' ;name of bulk velocity vector

timespan, '2015-10-16/13:06:00', 1, /min  ;time range to load
trange = timerange()
time = trange[0]  ;slice time 

; again, note that the /center_measurement keyword is required
; due to assumptions made in mms_get_dist (or the routines it calls)
mms_load_hpca, /center_measurement, probes=probe, trange=trange, data_rate=data_rate, level=level, datatype='ion'

dist = mms_get_dist(name)

;load B field data
mms_load_fgm, probe=probe, trange=trange, level='l2'

;load velocity moment
mms_load_hpca, probes=probe, trange=trange, data_rate=data_rate, level=level, $
               datatype='moments', varformat='*_'+species+'_ion_bulk_velocity'

;field/velocity aligned slice
;  -the plot's x axis is parallel to the B field
;  -the plot's y axis is defined by the bulk velocity direction
;---------------------------------------------
slice = spd_slice2d(dist, time=time, window=window, $
                    rotation='bv', mag_data=bname, vel_data=vname)

;plot
spd_slice2d_plot, slice

stop

;===========================================================================
;  Export time series
;===========================================================================

probe = '1'
level = 'l2'
species = 'hplus'
data_rate = 'srvy'

name = 'mms'+probe+'_hpca_'+species+'_phase_space_density'

timespan, '2015-10-16/13:06:00', 1, /min  ;time range to load
trange = timerange()

mms_load_hpca, /center_measurement, probes=probe, trange=trange, data_rate=data_rate, level=level, datatype='ion'

dist = mms_get_dist(name)

;produce a plot of the closest 2 distributions every 20 seconds for 1 minute
times = trange[0] + 20 * findgen(4)
samples = 2

for i=0, n_elements(times)-1 do begin

  slice = spd_slice2d(dist, time=times[i], samples=samples)

  filename = 'mms'+probe+'_'+species+'_'+time_string(times[i],format=2)

  ;plot and write .png image to current directory
  spd_slice2d_plot, slice, export=filename ;,/eps

endfor

stop


end