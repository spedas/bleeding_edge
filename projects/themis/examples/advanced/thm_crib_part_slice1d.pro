
;+
;Name:
;  thm_crib_part_slice1d
;
;Purpose:
;  Demonstrate production of 1D plots from 2D particle distribution contours.
;
;See Also:
;   thm_crib_part_slice2d
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-05-14 14:38:31 -0700 (Thu, 14 May 2015) $
;$LastChangedRevision: 17616 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_part_slice1d.pro $
;-

;================================================
;Notes
;================================================
;
;Calling sequence for thm_part_slice1d:
;
;  thm_part_slice1d, slice, [,xcut=xcut | ,ycut=ycut | ,vcut=vcut | ,ecut=ecut ]
;                           [,angle=angle] [,/overplot] [,data=data] [,window=window]
;
;  IDL graphics keywords may also be used in calls to thm_part_slice1d.
;


;================================================
; SETUP  
;   -Run this section before proceeding to examples
;================================================

;set day and time
day = '2008-02-26/'

start_time = time_double(day + '04:54:00')
end_time = time_double(day + '04:55:00')

trange=[start_time, end_time]

;load support data
thm_load_fgm, probe=probe, datatype='fgl', level=2, coord='dsl', trange=trange

;load particle data
dist_arr = thm_part_dist_array(probe='b',type='peib', trange=trange)

;generate slice plot
; -2D interpolation or 3D interpolation with smoothing are recommended for the best results
thm_part_slice2d, dist_arr, slice_time=start_time, timewin=30, part_slice=slice, $
                  rotation='BV', mag_data='thb_fgl_dsl', /three_d_interp

;plot slice for reference
thm_part_slice2d_plot, slice

stop


;================================================
;Examples
;================================================

;-------------------------------------------
;plot 1D cut along the slice's x axis
;-------------------------------------------

;put 1d plots in a new window
window, 4

;x axis is used by default
thm_part_slice1d, slice

stop

;-------------------------------------------
;plot cut along the y axis
;-------------------------------------------

;Specify linear cuts with the x=x and y=y keywords.
;The cut will be made along the line defined by the
;specified keyword (in km/s).
;  e.g.:  y=0 cuts along the x axis
;         x=0 cuts along the y axis
;         x=500 cuts along the line at x=500 km/s 
thm_part_slice1d, slice, xcut=0

stop

;-------------------------------------------
;plot diagonal cut along y=x
;-------------------------------------------

;Set the angle=angle keyword to specify a right-handed
;rotation for the specified cut.
;
; *Note: Rotated cuts are plotted against their total
;        distance from the origin instead of their value
;        along the original axis. The sign of the original 
;        axis is kept for consistency (cuts at x=0 and 
;        x=0 +180 degrees will be identical)
;
thm_part_slice1d, slice, xcut=0, angle=45

stop

;-------------------------------------------
;plot a radial cut
;-------------------------------------------

;Set the v=v keyword to produce a radial cut at the 
;specified velocity (in km/s)
thm_part_slice1d, slice, vcut=750

stop

;-------------------------------------------
;plot another radial cut
;-------------------------------------------

;Set the e=e keyword to produce a radial cut at the
;specified energy (in eV)
thm_part_slice1d, slice, ecut=4000

stop

;-------------------------------------------
;plot multiple radial cuts
;-------------------------------------------

;use the /overplot keyword to add a trace to the previous plot
thm_part_slice1d, slice, vcut=500
thm_part_slice1d, slice, vcut=1000, /overplot
thm_part_slice1d, slice, ecut=8000, /overplot

stop

;-------------------------------------------
;set plotting options
;-------------------------------------------

;IDL graphics kewords (e.g. color, linestyle, psym) can be used
; (see IDL documentation)
thm_part_slice1d, slice, vcut=500, color=1, linestyle=2

stop

;-------------------------------------------
;set plotting range
;-------------------------------------------

;the plot's range may be specified with the xrange and yrange keywrods
thm_part_slice1d, slice, vcut=500, yrange=[1e-12,1e-8], xrange=[0,180]

stop

;-------------------------------------------
;use simple loops to quickly produce multiple plots
;-------------------------------------------

;plot multiple radial cuts with different colors
v = [500,750,1000,1250,1500]
color = [.25,.35,.45,.55,.65] * 256 ; see IDL documentation for "Graphics System Variables"
for i=0, n_elements(v)-1 do $
  thm_part_slice1d, slice, vcut=v[i], overplot=(i gt 0), yrange=[1e-14,1e-8], color=color[i]

stop

;-------------------------------------------
;return data when plotting
;-------------------------------------------

;use the "data" keyword to return a structure containing 
;the plot's data, ranges, and annotations

thm_part_slice1d, slice, ycut=0, data=data

help, /structure, data

stop

;-------------------------------------------
;plot single count level over data
;-------------------------------------------

;create copy of the original data
thm_part_copy, dist_arr, dist_arr_copy

;set all data in the copy to one count
thm_part_set_counts, dist_arr_copy, 1.

;create 2D slice with single-count data
;  -all keywords here should match original call to thm_part_slice2d
thm_part_slice2d, dist_arr_copy, slice_time=start_time, timewin=30, part_slice=slice_onecnt, $
                  rotation='BV', mag_data='thb_fgl_dsl', /three_d_interp

;any 1D slice can now be compared against the synthetic single-count distribution
thm_part_slice1d, slice, ycut=0
thm_part_slice1d, slice_onecnt, ycut=0, linestyle=2, /overplot

stop


end