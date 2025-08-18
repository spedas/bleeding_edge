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
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2023-08-14 12:51:35 -0700 (Mon, 14 Aug 2023) $
;$LastChangedRevision: 31999 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_slice2d_hpca_crib.pro $
;-

;===========================================================================
; Basic
;===========================================================================

;get single distribution
;  -3d/2d interpolation show smooth contours
;  -3d interpolates entire volume
;  -2d interpolates projection of a subset of data near the slice plane
;  -geometric interpolation is slow but shows bin boundaries
;---------------------------------------------
; 3D interpolation (default)
mms_part_slice2d, time='2016-10-16/17:40:00', probe=1, species='hplus', data_rate='brst', instrument='hpca'
stop
; 2D interpolation
mms_part_slice2d, /two, time='2016-10-16/17:40:00', probe=1, species='hplus', data_rate='brst', instrument='hpca'
stop
; geometric interpolation
mms_part_slice2d, /geo, time='2016-10-16/17:40:00', probe=1, species='hplus', data_rate='brst', instrument='hpca'
stop

;average all data in specified time window
; - window (sec) starts at TIME
mms_part_slice2d, /geo, window=20, time='2016-10-16/17:40:00', probe=1, species='hplus', data_rate='brst', instrument='hpca'
stop
; - window centered on TIME
mms_part_slice2d, /center_time, /geo, window=20, time='2016-10-16/17:40:00', probe=1, species='hplus', data_rate='brst', instrument='hpca'
stop

;average specific number of distributions (uses N closest to specified time)
mms_part_slice2d, /geo, samples=3, time='2016-10-16/17:40:00', probe=1, species='hplus', data_rate='brst', instrument='hpca'
stop

;======================================================================
; Field-aligned slices
;======================================================================

mms_part_slice2d, rotation='bv', samples=3, time='2016-10-16/17:40:00', probe=1, species='hplus', data_rate='brst', instrument='hpca'
stop

;===========================================================================
;  Export time series
;===========================================================================

;produce a plot of 20 seconds of data every 20 seconds for 2 minutes
trange=['2017-09-10/09:32', '2017-09-10/09:34'] 
times = time_double(trange[0]) + 20 * findgen(7)
window = 20

for i=0, n_elements(times)-1 do mms_part_slice2d, window=window, time=times[i], probe=1, species='hplus', data_rate='srvy', instrument='hpca', export='mms1_hplus_'+time_string(times[i],format=2) ;,/eps
stop


end