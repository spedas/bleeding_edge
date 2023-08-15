;+
;
;  This crib sheet shows how to create a figure with multiple panels, one
;  of which contains 2 variables with independent axes (FPI DES perpendicular temp and density)
;     i.e., line plots of two tplot variables in a single panel where one has its 
;     y-axis/title on the left and the other has its y-axis/title on the right
;
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-08-14 12:51:35 -0700 (Mon, 14 Aug 2023) $
; $LastChangedRevision: 31999 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_multiaxis_crib.pro $
;-

; load the data
mms_load_fgm, trange=['2015-10-16/13:00', '2015-10-16/14:00'], probe=1, /time_clip
mms_load_fpi, trange=['2015-10-16/13:00', '2015-10-16/14:00'], probe=1, datatype='des-moms', /time_clip

; remove the ytitle/labels
options, 'mms1_des_numberdensity_fast', labels='', colors=0 ; black
options, 'mms1_des_tempperp_fast', labels='', colors=2 ; blue

; turn off the time stamp for these examples
time_stamp, /off

; plot temperature and density on the same plot
tplot_multiaxis, ['mms1_fgm_b_gse_srvy_l2_bvec', 'mms1_des_numberdensity_fast', 'mms1_des_bulkv_gse_fast', 'mms1_des_energyspectr_omni_fast'], $ ; left plots
                'mms1_des_tempperp_fast', $ ; right plots
                2 ; panel of the right plot (starts at 1)
stop

; you can also plot line plots over spectra
tplot_multiaxis, ['mms1_fgm_b_gse_srvy_l2_bvec', 'mms1_des_numberdensity_fast', 'mms1_des_bulkv_gse_fast', 'mms1_des_energyspectr_omni_fast'], $ ; left plots
  'mms1_des_tempperp_fast', 4
stop

; to get the color bar back for the spectra, simply increase the margins:
tplot_options, 'xmargin', [15, 25]
tplot_multiaxis, ['mms1_fgm_b_gse_srvy_l2_bvec', 'mms1_des_numberdensity_fast', 'mms1_des_bulkv_gse_fast', 'mms1_des_energyspectr_omni_fast'], $ ; left plots
  'mms1_des_tempperp_fast', 4
stop

end