;+
;
; mms_flipbook_crib
;
; This crib sheet shows how to create "flipbook" style figures containing
; line/spectra plots and 2D distribution slices, with a vertical line at
; each slice location
;
;
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2020-03-13 16:28:37 -0700 (Fri, 13 Mar 2020) $
; $LastChangedRevision: 28413 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_flipbook_crib.pro $
;-
;

;------------------------------------------------------
; Basic FPI example
;------------------------------------------------------
trange=['2015-10-16/13:06:00', '2015-10-16/13:06:30']
probe=1
data_rate = 'brst'
fgm_data_rate = 'brst'
species = 'i'

mms_load_fgm, trange=trange, probe=probe, data_rate=fgm_data_rate, /time_clip
mms_load_fpi, trange=trange, probe=probe, datatype='d'+species+'s-moms', /time_clip, data_rate=data_rate

; be sure to make the window large enough in the x-direction for the slices
window, xsize=1000, ysize=650

; store the temperature in the same panel
store_data, 'temp', data=['mms1_d'+species+'s_temppara_'+data_rate, 'mms1_d'+species+'s_tempperp_'+data_rate]

tplot, ['mms1_fgm_b_gse_'+fgm_data_rate+'_l2_bvec', 'mms1_d'+species+'s_heatq_gse_'+data_rate, 'temp', 'mms1_d'+species+'s_bulkv_gse_'+data_rate, $
  'mms1_d'+species+'s_numberdensity_'+data_rate, 'mms1_d'+species+'s_energyspectr_omni_'+data_rate]

mms_flipbookify, time_step=100, probe=1, species=species, data_rate=data_rate
stop

;------------------------------------------------------
; Basic HPCA example
;------------------------------------------------------
trange=['2015-10-16/12', '2015-10-16/14']
probe=1
data_rate = 'srvy'
fgm_data_rate = 'srvy'
species = 'hplus'

mms_load_fgm, trange=trange, probe=probe, data_rate=fgm_data_rate, /time_clip
mms_load_hpca, trange=trange, probe=probe, datatype='moments', data_rate=data_rate, /time_clip

window, xsize=1200, ysize=650

tplot, ['mms1_hpca_'+species+'_number_density', 'mms1_hpca_'+species+'_ion_bulk_velocity', 'mms1_hpca_'+species+'_scalar_temperature', 'mms1_hpca_'+species+'_ion_pressure', 'mms1_fgm_b_gse_'+fgm_data_rate+'_l2_bvec']

mms_flipbookify, probe=1, species=species, instrument='hpca', time_step=100, data_rate=data_rate
stop

;------------------------------------------------------
; Create plots every N seconds with the seconds keyword
;------------------------------------------------------
trange=['2015-10-16/13:06:00', '2015-10-16/13:06:30']
probe=1
data_rate = 'brst'
fgm_data_rate = 'brst'
species = 'i'

mms_load_fgm, trange=trange, probe=probe, data_rate=fgm_data_rate, /time_clip
mms_load_fpi, trange=trange, probe=probe, datatype='d'+species+'s-moms', /time_clip, data_rate=data_rate

window, xsize=1000, ysize=650

; store the temperature in the same panel
store_data, 'temp', data=['mms1_d'+species+'s_temppara_'+data_rate, 'mms1_d'+species+'s_tempperp_'+data_rate]

tplot, ['mms1_fgm_b_gse_'+fgm_data_rate+'_l2_bvec', 'mms1_dis_heatq_gse_'+data_rate, 'temp', 'mms1_d'+species+'s_bulkv_gse_'+data_rate, $
  'mms1_d'+species+'s_numberdensity_'+data_rate, 'mms1_d'+species+'s_energyspectr_omni_'+data_rate]

; use the seconds keyword to create a figure with slices every N seconds (N=1 in this case)
mms_flipbookify, seconds=1, probe=1, species='i'
stop

;------------------------------------------------------
; Save the FPI plots to postscript instead of PNG
;------------------------------------------------------
trange=['2015-10-16/13:06:00', '2015-10-16/13:06:30']
probe=1
data_rate = 'brst'
fgm_data_rate = 'brst'
species = 'i'

mms_load_fgm, trange=trange, probe=probe, data_rate=fgm_data_rate, /time_clip
mms_load_fpi, trange=trange, probe=probe, datatype='d'+species+'s-moms', /time_clip, data_rate=data_rate

window, xsize=1000, ysize=650

; store the temperature in the same panel
store_data, 'temp', data=['mms1_d'+species+'s_temppara_'+data_rate, 'mms1_d'+species+'s_tempperp_'+data_rate]

tplot, ['mms1_fgm_b_gse_'+fgm_data_rate+'_l2_bvec', 'mms1_dis_heatq_gse_'+data_rate, 'temp', 'mms1_d'+species+'s_bulkv_gse_'+data_rate, $
  'mms1_d'+species+'s_numberdensity_'+data_rate, 'mms1_d'+species+'s_energyspectr_omni_'+data_rate]

; note: the slices may not show up in the tplot window when saving to postscript
; --> they will be in the files, though
mms_flipbookify, time_step=100, probe=1, species='i', /postscript
stop

;------------------------------------------------------
; FPI example with limited trange
;------------------------------------------------------
trange=['2015-10-16/13:06:00', '2015-10-16/13:06:30']
probe=1
data_rate = 'brst'
fgm_data_rate = 'brst'
species = 'i'

mms_load_fgm, trange=trange, probe=probe, data_rate=fgm_data_rate, /time_clip
mms_load_fpi, trange=trange, probe=probe, datatype='d'+species+'s-moms', /time_clip, data_rate=data_rate

; be sure to make the window large enough in the x-direction for the slices
window, xsize=1000, ysize=650

; store the temperature in the same panel
store_data, 'temp', data=['mms1_d'+species+'s_temppara_'+data_rate, 'mms1_d'+species+'s_tempperp_'+data_rate]

tplot, ['mms1_fgm_b_gse_'+fgm_data_rate+'_l2_bvec', 'mms1_d'+species+'s_heatq_gse_'+data_rate, 'temp', 'mms1_d'+species+'s_bulkv_gse_'+data_rate, $
  'mms1_d'+species+'s_numberdensity_'+data_rate, 'mms1_d'+species+'s_energyspectr_omni_'+data_rate]

mms_flipbookify, time_step=100, probe=1, species=species, trange=['2015-10-16/13:06:10', '2015-10-16/13:06:20']
stop

;------------------------------------------------------
; FPI example with different slices
;------------------------------------------------------
trange=['2015-10-16/13:06:00', '2015-10-16/13:06:30']
probe=1
data_rate = 'brst'
fgm_data_rate = 'brst'
species = 'i'

mms_load_fgm, trange=trange, probe=probe, data_rate=fgm_data_rate, /time_clip
mms_load_fpi, trange=trange, probe=probe, datatype='d'+species+'s-moms', /time_clip, data_rate=data_rate

; be sure to make the window large enough in the x-direction for the slices
window, xsize=1000, ysize=650

; store the temperature in the same panel
store_data, 'temp', data=['mms1_d'+species+'s_temppara_'+data_rate, 'mms1_d'+species+'s_tempperp_'+data_rate]

tplot, ['mms1_fgm_b_gse_'+fgm_data_rate+'_l2_bvec', 'mms1_d'+species+'s_heatq_gse_'+data_rate, 'temp', 'mms1_d'+species+'s_bulkv_gse_'+data_rate, $
  'mms1_d'+species+'s_numberdensity_'+data_rate, 'mms1_d'+species+'s_energyspectr_omni_'+data_rate]

mms_flipbookify, slices=['bv', 'be', 'perp'], time_step=100, probe=1, species=species
stop

;------------------------------------------------------
; FPI example with video
;------------------------------------------------------
trange=['2015-10-16/13:06:00', '2015-10-16/13:06:30']
probe=1
data_rate = 'brst'
fgm_data_rate = 'brst'
species = 'i'

mms_load_fgm, trange=trange, probe=probe, data_rate=fgm_data_rate, /time_clip
mms_load_fpi, trange=trange, probe=probe, datatype='d'+species+'s-moms', /time_clip, data_rate=data_rate

; be sure to make the window large enough in the x-direction for the slices
window, xsize=1000, ysize=650

; store the temperature in the same panel
store_data, 'temp', data=['mms1_d'+species+'s_temppara_'+data_rate, 'mms1_d'+species+'s_tempperp_'+data_rate]

tplot, ['mms1_fgm_b_gse_'+fgm_data_rate+'_l2_bvec', 'mms1_d'+species+'s_heatq_gse_'+data_rate, 'temp', 'mms1_d'+species+'s_bulkv_gse_'+data_rate, $
  'mms1_d'+species+'s_numberdensity_'+data_rate, 'mms1_d'+species+'s_energyspectr_omni_'+data_rate]

mms_flipbookify, /video, time_step=100, probe=1, species=species
stop

;------------------------------------------------------
; FPI example with 1D cuts through 2D slices
;------------------------------------------------------

trange=['2015-10-16/13:06:00', '2015-10-16/13:06:30']
probe=1
data_rate = 'brst'
fgm_data_rate = 'brst'
species = 'i'

mms_load_fgm, trange=trange, probe=probe, data_rate=fgm_data_rate, /time_clip
mms_load_fpi, trange=trange, probe=probe, datatype='d'+species+'s-moms', /time_clip, data_rate=data_rate

; store the temperature in the same panel
store_data, 'temp', data=['mms1_d'+species+'s_temppara_'+data_rate, 'mms1_d'+species+'s_tempperp_'+data_rate]

tplot, ['mms1_fgm_b_gse_'+fgm_data_rate+'_l2_bvec', 'mms1_d'+species+'s_heatq_gse_'+data_rate, 'temp', 'mms1_d'+species+'s_bulkv_gse_'+data_rate, $
  'mms1_d'+species+'s_numberdensity_'+data_rate, 'mms1_d'+species+'s_energyspectr_omni_'+data_rate]

mms_flipbookify, slices=['xy', 'yz', 'xz'], time_step=100, probe=1, species=species, /include_1d_vx, /include_1d_vy


end