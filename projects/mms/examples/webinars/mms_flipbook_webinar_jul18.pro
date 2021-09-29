;+
; MMS flipbookify - adding 2D distribution slices to arbitrary tplot windows
; July 18, 2018
;
; Please be sure to mute your phone during the webinar!
;
; questions? feel free to unmute and ask during the presentation or email egrimes@igpp.ucla.edu after!
; 
; this file can be found on the web at:
;     http://spedas.org/mms/mms_flipbook_webinar_jul18.pro
;     
; -----> Phone to use: 510-643-3817
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
; $LastChangedDate: 2018-07-18 10:58:32 -0700 (Wed, 18 Jul 2018) $
; $LastChangedRevision: 25487 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/webinars/mms_flipbook_webinar_jul18.pro $
;-

; basic example with FPI data
; 
mms_load_fpi, probe=1, trange=['2015-10-16/13:05:30', '2015-10-16/13:08'], data_rate='brst', datatype='dis-moms', /time_clip
mms_load_fgm, probe=1, trange=['2015-10-16/13:05:30', '2015-10-16/13:08'], data_rate='brst', /time_clip

tplot, ['mms1_dis_energyspectr_omni_brst', 'mms1_fgm_b_gse_brst_l2_bvec', 'mms1_dis_numberdensity_brst']
stop

tlimit, ['2015-10-16/13:06:50', '2015-10-16/13:06:55']
stop

mms_flipbookify, species='i', trange=['2015-10-16/13:06:50', '2015-10-16/13:06:55']
stop

; change the time step
tlimit, ['2015-10-16/13:05:30', '2015-10-16/13:07:40']
mms_flipbookify, species='i', time_step=100
stop

; basic example with HPCA data
mms_load_hpca, probe=1, trange=['2015-10-16/13:05:30', '2015-10-16/13:07:40'], data_rate='brst', /time_clip

tplot, ['mms1_hpca_hplus_ion_bulk_velocity_GSM', 'mms1_hpca_hplus_number_density', 'mms1_hpca_hplus_tperp', 'mms1_hpca_hplus_tparallel', 'mms1_fgm_b_gse_brst_l2_bvec']
stop

mms_flipbookify, instrument='hpca', species='hplus'
stop

; change the time format in the title
tplot, ['mms1_fgm_b_gse_brst_l2_bvec', 'mms1_dis_numberdensity_brst', 'mms1_dis_bulkv_gse_brst', 'mms1_dis_heatq_gse_brst', 'mms1_dis_energyspectr_omni_brst']

mms_flipbookify, species='i', time_step=1000, title='YYYY-MM-DD/hh:mm:ss.fff'
stop

; change the interpolation method
mms_flipbookify, species='i', time_step=2000, /geometric
stop

mms_flipbookify, species='i', time_step=500, /two_d_interp
stop

; change the rotations
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

end