;+
;Purpose:
;  Crib sheet demonstrating how to obtain particle distribution slices 
;  from MMS FPI data using mms_part_slice2d.
;  
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
;$LastChangedDate: 2018-11-08 15:07:06 -0800 (Thu, 08 Nov 2018) $
;$LastChangedRevision: 26075 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_slice2d_fpi_crib.pro $
;-

;======================================================================
; Basic
;======================================================================

;get single distribution
;  -3d/2d interpolation show smooth contours
;  -3d interpolates entire volume
;  -2d interpolates projection of a subset of data near the slice plane 
;  -geometric interpolation is slow but shows bin boundaries
;---------------------------------------------
; 3D interpolation (default)
mms_part_slice2d, time='2015-10-16/13:06:00', rotation='yz', probe=1, species='i', data_rate='brst'
stop
; 2D interpolation
mms_part_slice2d, /two, time='2015-10-16/13:06:00', rotation='yz', probe=1, species='i', data_rate='brst'
stop
; geometric interpolation
mms_part_slice2d, /geo, time='2015-10-16/13:06:00', rotation='yz', probe=1, species='i', data_rate='brst'
stop

;average all data in specified time window
; - window (sec) starts at TIME  
mms_part_slice2d, /geo, window=0.5, time='2015-10-16/13:06:00', rotation='yz', probe=1, species='i', data_rate='brst'
stop
; - window centered on TIME
mms_part_slice2d, /center_time, /geo, window=0.5, time='2015-10-16/13:06:00', rotation='yz', probe=1, species='i', data_rate='brst'
stop
 
;average specific number of distributions (uses N closest to specified time)
mms_part_slice2d, /geo, samples=3, time='2015-10-16/13:06:00', rotation='yz', probe=1, species='i', data_rate='brst'
stop

;======================================================================
; Field-aligned slices
;======================================================================

;field/velocity aligned slice
;  -the plot's x axis is parallel to the B field
;  -the plot's y axis is defined by the bulk velocity direction
;---------------------------------------------
mms_part_slice2d, rotation='bv', samples=3, time='2015-10-16/13:06:00', probe=1, species='i', data_rate='brst'
stop

;======================================================================
; Export time series
;======================================================================

;produce a plot of 0.5 seconds of data every 10 seconds for 1 minute
trange=['2015-10-16/13:06', '2015-10-16/13:07'] 
times = time_double(trange[0]) + 10 * findgen(7)
window = 0.5

for i=0, n_elements(times)-1 do mms_part_slice2d, window=window, time=times[i], probe=1, species='i', data_rate='brst', export='mms1_i_'+time_string(times[i],format=2) ;,/eps
stop

;======================================================================
; Subtract error and subtract bulk velocity from the data prior to plotting
;======================================================================

mms_part_slice2d, /subtract_bulk, /subtract_error, time='2015-10-16/13:06:00', probe=1, species='i', data_rate='brst'
stop

;======================================================================
; Sum over the requested trange rather than averaging
; using the keyword /sum_samples in the call to spd_slice2d
;======================================================================

mms_part_slice2d, samples=100, /sum_samples, time='2015-10-16/13:06:00', probe=1, species='i', data_rate='brst'
stop

end