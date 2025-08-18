;+
; MMS flipbookify - adding 2D distribution slices to arbitrary tplot windows
; May 15, 2019
;
;
; Tentative agenda:
; 1) Basic examples for FPI and HPCA
; 2) Change interpolation method
; 3) Change rotations of slices
; 4) Limit the time range to a subset of the tplot window
; 5) Subtract FPI distribution error, bulk velocity from slices prior to adding them to the window
; 6) Export to high quality postscript files instead of PNGs
; 7) Export to video file
; 8) Include 1-D cuts through the 2-D distributions
; 
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2019-05-15 08:46:22 -0700 (Wed, 15 May 2019) $
; $LastChangedRevision: 27233 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/webinars/mms_flipbook_webinar_may19.pro $
;-

; find burst mode events using the new MMS event search routine
mms_event_search, 'bz', authors=authors, descriptions=descriptions, start_times=start_times, end_times=end_times
stop

; basic example with FPI data
mms_load_fpi, probe=1, trange=['2015-10-16/13:05:30', '2015-10-16/13:08'], data_rate='brst', datatype='dis-moms', /time_clip, /center_measurement
mms_load_fgm, probe=1, trange=['2015-10-16/13:05:30', '2015-10-16/13:08'], data_rate='brst', /time_clip

tplot, ['mms1_dis_energyspectr_omni_brst', 'mms1_fgm_b_gse_brst_l2_bvec', 'mms1_dis_numberdensity_brst']
stop

tlimit, ['2015-10-16/13:06:50', '2015-10-16/13:06:55']
stop

; note: the default time steps are taken from the first panel in the current window
;      warning: if this happens to be a full day of srvy mode FGM data,
;      this will produce > 1 million plots, one at each FGM data point - use the
;      time_step or seconds keywords to avoid this
mms_flipbookify, species='i', trange=['2015-10-16/13:06:50', '2015-10-16/13:06:55']
stop

; change the time step
; (time_step=1 -> plot at every time, time_step=2 -> every other time, etc)
tlimit, ['2015-10-16/13:05:30', '2015-10-16/13:07:40']
mms_flipbookify, species='i', time_step=100
stop

; you can use the number of seconds instead of the number of time steps, e.g.,
; (seconds=1.5 -> plot at every 1.5 seconds)
mms_flipbookify, species='i', seconds=1
stop

; this also works with HPCA data by specifying the 'instrument' keyword, e.g.,
mms_load_hpca, probe=1, trange=['2015-10-16/13:05:30', '2015-10-16/13:07:40'], data_rate='brst', /time_clip

tplot, ['mms1_hpca_hplus_ion_bulk_velocity_GSM', 'mms1_hpca_hplus_number_density', 'mms1_hpca_hplus_tperp', 'mms1_hpca_hplus_tparallel', 'mms1_fgm_b_gse_brst_l2_bvec']
stop

mms_flipbookify, instrument='hpca', species='hplus'
stop

; change the time format in the title
tplot, ['mms1_fgm_b_gse_brst_l2_bvec', 'mms1_dis_numberdensity_brst', 'mms1_dis_bulkv_gse_brst', 'mms1_dis_heatq_gse_brst', 'mms1_dis_energyspectr_omni_brst']

mms_flipbookify, species='i', time_step=1000, title='YYYY-MM-DD/hh:mm:ss.fff'
stop

; by default, the 3-D interpolation method is used for the slices
;     (The entire 3-dimensional distribution is linearly interpolated onto a
;     regular 3d grid and a slice is extracted from the volume.)

; to change the interpolation method to geometric:
;     (Each point on the plot is given the value of the bin it intersects.
;     This allows bin boundaries to be drawn at high resolutions.)
mms_flipbookify, species='i', time_step=2000, /geometric
stop

; or 2-D interpolation:
;     (Datapoints within the specified theta or z-axis range are projected onto
;     the slice plane and linearly interpolated onto a regular 2D grid.)
mms_flipbookify, species='i', time_step=500, /two_d_interp
stop

; change the rotations
; 'perp_yz':  The data's y & z axes are projected onto the plane normal to the B field
; 'bv':  The x axis is parallel to B field; the bulk velocity defines the x-y plane
; 'perp':  The x axis is the bulk velocity projected onto the plane normal to the B field; y is B x V(bulk)
mms_flipbookify, species='i', time_step=500, /two_d_interp, slices=['perp_yz', 'bv', 'perp']
stop

; limit the time range
mms_flipbookify, trange=['2015-10-16/13:06', '2015-10-16/13:07'], species='i', time_step=500, /two_d_interp
stop

; change the "box" characteristics
mms_flipbookify, box_color=2, box_thickness=3, trange=['2015-10-16/13:06', '2015-10-16/13:07'], species='i', time_step=500, /two
stop

; subtract FPI distribution error, bulk velocity from slices
mms_flipbookify, /subtract_error, /subtract_bulk, /subtract_spintone, species='i', time_step=500, /two_d_interp
stop

; save as postscript files
mms_flipbookify, /postscript, species='i', time_step=100, /two_d_interp
stop

; export as a movie
tplot, ['mms1_fgm_b_gse_brst_l2_bvec', 'mms1_dis_numberdensity_brst', 'mms1_dis_bulkv_gse_brst', 'mms1_dis_heatq_gse_brst', 'mms1_dis_energyspectr_omni_brst']

mms_flipbookify, /video, species='i', time_step=100, /two_d_interp
stop

; include 1D cuts through the 2D slices 
mms_flipbookify, /include_1d_vx, species='i', time_step=500, /two_d_interp
stop

mms_flipbookify, /include_1d_vx, /include_1d_vy, species='i', time_step=500, /two_d_interp
stop

; check for and potentially remove old MMS data files 
mms_remove_old_files


end