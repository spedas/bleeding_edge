;+
;
; This crib sheet shows how to save MMS data loaded into tplot variables to a CDF file
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-12-13 09:12:59 -0800 (Thu, 13 Dec 2018) $
; $LastChangedRevision: 26324 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_tplot2cdf_crib.pro $
;-

trange = ['2015-10-16', '2015-10-17']

; load MMS data and get electron fluxes and pitch angles distributions 
mms_load_feeps, trange=trange, /tt2000
mms_feeps_pad
mms_load_fgm, trange=trange, /tt2000

; /tt2000 saves the TT2000 timestamps (note: this keyword is also required on the load routine calls)
tplot2cdf, /tt2000, filename='cdf_file_with_tt2000_times', $
  tvars=['mms1_epd_feeps_srvy_l2_electron_intensity_omni', 'mms1_epd_feeps_srvy_l2_electron_intensity_omni_spin', 'mms1_epd_feeps_srvy_l2_electron_intensity_70-600keV_pad', 'mms1_epd_feeps_srvy_l2_electron_intensity_70-600keV_pad_spin', 'mms1_fgm_b_gsm_srvy_l2_bvec']

stop

; delete the previously loaded data
del_data, '*'

; reload and plot the saved data from the CDF file
spd_cdf2tplot, 'cdf_file_with_tt2000_times.cdf'

tplot, ['mms1_fgm_b_gsm_srvy_l2_bvec', 'mms1_epd_feeps_srvy_l2_electron_intensity_omni', 'mms1_epd_feeps_srvy_l2_electron_intensity_omni_spin', 'mms1_epd_feeps_srvy_l2_electron_intensity_70_600keV_pad', 'mms1_epd_feeps_srvy_l2_electron_intensity_70_600keV_pad_spin']
stop
end