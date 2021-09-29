;+
; PURPOSE:
;  Crib sheet demonstrating how to create 1D plots of 2D distribution slices created by spd_slice2d
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2020-01-28 18:03:30 -0800 (Tue, 28 Jan 2020) $
;$LastChangedRevision: 28248 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_slice2d_1d_plot_crib.pro $
;-

;======================================================================
; Basic setup for FPI / copy+pasted from mms_slice2d_fpi_crib
;======================================================================

probe='1'
level='l2'
species='i'
data_rate='brst'

name =  'mms'+probe+'_d'+species+'s_dist_'+data_rate

trange = ['2018-01-08/06', '2018-01-08/07']
time = '2018-01-08/06:41:11.272'

;load particle data into tplot
mms_load_fpi, data_rate=data_rate, level=level, datatype='d'+species+'s-dist', $
  probe=probe, trange=trange, min_version='2.2.0'

;reformat data from tplot variable into compatible 3D structures
dist = mms_get_dist(name, trange=trange, /subtract_error, error='mms'+probe+'_d'+species+'s_disterr_'+data_rate)

;get single distribution
;  -3d/2d interpolation show smooth contours
;  -3d interpolates entire volume
;  -2d interpolates projection of a subset of data near the slice plane
;  -geometric interpolation is slow but shows bin boundaries
;---------------------------------------------

mms_load_fpi, data_rate=data_rate, level=level, datatype='d'+species+'s-moms', probe=probe, trange=trange
mms_load_fgm, probe=probe, trange=trange

slice = spd_slice2d(dist, /two, time=time, rotation='bv', vel_data='mms'+probe+'_d'+species+'s_bulkv_gse_'+data_rate, mag_data='mms'+probe+'_fgm_b_gse_srvy_l2_bvec') ;3D interpolation

;======================================================================
; Create the 1D plots from the slice (x and y directions)
;======================================================================

; note: spd_slice1d_plot accepts most keywords the PLOT procedure accepts, e.g., title
; the input arguments are slice, direction ('x' or 'y'), value to create the plot at
window, 0, xsize=500, ysize=500
spd_slice1d_plot, slice, 'x', [-1000, 1000], color=2, yminor=10, window=0, xrange=[-1000, 1000], yrange=[1e-26, 1e-18], /ylog, ystyle=1;, title='Vx at Vy=0'
spd_slice1d_plot, slice, 'y', [-1000, 1000], color=6, /noerase, yminor=10, window=0, xrange=[-1000, 1000], yrange=[1e-26, 1e-18], /ylog, ystyle=1;, title='Vx at Vy=0'

; plot the slice as well
wi, 1
spd_slice2d_plot, slice, window=1, xrange=[-1000, 1000], yrange=[-1000, 1000]
stop

;======================================================================
; Create the 1D plots from the slice (x and y directions)
;======================================================================

;V (BxV) v. VB
slice = spd_slice2d(dist, /center, samples=1, /two, resolution=150, time=time, rotation='be', vel_data='mms'+probe+'_d'+species+'s_bulkv_gse_'+data_rate, mag_data='mms'+probe+'_fgm_b_gse_srvy_l2_bvec') ;3D interpolation

; note: spd_slice1d_plot accepts most keywords the PLOT procedure accepts, e.g., title
; the input arguments are slice, direction ('x' or 'y'), value to create the plot at
window, 0, xsize=500, ysize=500
spd_slice1d_plot, slice, 'x', [-1000, 1000], color=2, yminor=10, window=0, xrange=[-1000, 1000], yrange=[1e-26, 1e-18], /ylog, ystyle=1;, title='Vx at Vy=0'
spd_slice1d_plot, slice, 'y', [-1000, 1000], color=6, /noerase, yminor=10, window=0, xrange=[-1000, 1000], yrange=[1e-26, 1e-18], /ylog, ystyle=1;, title='Vx at Vy=0'

; plot the slice as well
wi, 1
spd_slice2d_plot, slice, window=1, xrange=[-1000, 1000], yrange=[-1000, 1000]
stop

;======================================================================
; Create the 1D plots from the slice (x and y directions)
;======================================================================

;V (BxV) v. V (VperpB)
slice = spd_slice2d(dist, /center, samples=1, /two, resolution=150, time=time, rotation='perp', vel_data='mms'+probe+'_d'+species+'s_bulkv_gse_'+data_rate, mag_data='mms'+probe+'_fgm_b_gse_srvy_l2_bvec') ;3D interpolation

; note: spd_slice1d_plot accepts most keywords the PLOT procedure accepts, e.g., title
; the input arguments are slice, direction ('x' or 'y'), value to create the plot at
window, 0, xsize=500, ysize=500
spd_slice1d_plot, slice, 'x', [-1000, 1000], color=2, yminor=10, window=0, xrange=[-1000, 1000], yrange=[1e-26, 1e-18], /ylog, ystyle=1;, title='Vx at Vy=0'
spd_slice1d_plot, slice, 'y', [-1000, 1000], color=6, /noerase, yminor=10, window=0, xrange=[-1000, 1000], yrange=[1e-26, 1e-18], /ylog, ystyle=1;, title='Vx at Vy=0'

; plot the slice as well
wi, 1
spd_slice2d_plot, slice, window=1, xrange=[-1000, 1000], yrange=[-1000, 1000]
stop

;======================================================================
; Create the 1D plot from the slice with bulk velocity subtracted
;======================================================================

; load velocity data from the moments files
mms_load_fpi, data_rate=data_rate, level=level, datatype='d'+species+'s-moms', probe=probe, trange=trange
  
slice = spd_slice2d(dist, time=time, /subtract_bulk, vel_data='mms'+probe+'_d'+species+'s_bulkv_gse_brst')

window, 0, xsize=500, ysize=500
spd_slice1d_plot, slice, 'x', 0.0, title='Vx at Vy=0 (bulk V frame)', xrange=[-400, 400]

stop

;======================================================================
; Create a 1D plot of the integral over a certain angle section using mms_slice1d_plot_fpi
;======================================================================

slice = spd_slice2d(dist, /two, time=time, rotation='perp', vel_data='mms'+probe+'_d'+species+'s_bulkv_gse_'+data_rate, mag_data='mms'+probe+'_fgm_b_gse_srvy_l2_bvec') ;3D interpolation

spd_slice2d_plot, slice
mms_slice1d_plot_fpi, slice, species='i', alpha=[0,0], width=[30,30], xrange=[-2500, 2500], yrange=[1e-26, 1d-19], export=export_dir

stop
end