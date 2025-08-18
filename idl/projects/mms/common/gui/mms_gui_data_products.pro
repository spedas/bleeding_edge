;+
; FUNCTION:
;     mms_gui_data_products
;
; PURPOSE:
;     Returns list of tplot variables to be loaded into the GUI
; 
; NOTES:
;     This routine will need to be updated when:
;     1) variable names change
;     2) adding new levels or data rates to the GUI
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-04-16 08:53:47 -0700 (Mon, 16 Apr 2018) $
; $LastChangedRevision: 25049 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/gui/mms_gui_data_products.pro $
;-

function mms_gui_data_products, probes, instrument, rate, level
    ; maps instrument-rate-level to list of valid tplot variables to load into the GUI
    valid_products = hash()

    valid_products['fgm-srvy-l2'] = ['_fgm_b_dmpa_srvy_l2_bvec', $
                                    '_fgm_b_dmpa_srvy_l2_btot', $
                                    '_fgm_b_gse_srvy_l2_bvec', $
                                    '_fgm_b_gse_srvy_l2_btot', $
                                    '_fgm_b_gsm_srvy_l2_bvec', $
                                    '_fgm_b_gsm_srvy_l2_btot']
      
    valid_products['fgm-brst-l2'] = ['_fgm_b_dmpa_brst_l2_bvec', $
                                    '_fgm_b_dmpa_brst_l2_btot', $
                                    '_fgm_b_gse_brst_l2_bvec', $
                                    '_fgm_b_gse_brst_l2_btot', $
                                    '_fgm_b_gsm_brst_l2_bvec', $
                                    '_fgm_b_gsm_brst_l2_btot']
    
    valid_products['eis-brst-l2'] = ['_epd_eis_extof_proton_flux_omni_spin', $
                                     '_epd_eis_extof_alpha_flux_omni_spin', $
                                     '_epd_eis_extof_oxygen_flux_omni_spin', $
                                     '_epd_eis_phxtof_proton_flux_omni_spin', $
                                     '_epd_eis_phxtof_alpha_flux_omni_spin', $
                                     '_epd_eis_phxtof_oxygen_flux_omni_spin', $
                                     '_epd_eis_brst_electronenergy_electron_flux_omni_spin']

    valid_products['eis-srvy-l2'] = ['_epd_eis_extof_proton_flux_omni_spin', $
                                     '_epd_eis_extof_alpha_flux_omni_spin', $
                                     '_epd_eis_extof_oxygen_flux_omni_spin', $
                                     '_epd_eis_phxtof_proton_flux_omni_spin', $
                                     '_epd_eis_phxtof_oxygen_flux_omni_spin', $
                                     '_epd_eis_electronenergy_electron_flux_omni_spin']
     
    valid_products['hpca-srvy-l2'] = ['_hpca_hplus_number_density', $
                                     '_hpca_hplus_ion_bulk_velocity', $
                                     '_hpca_hplus_scalar_temperature', $
                                     '_hpca_hplus_ion_pressure', $
                                     '_hpca_hplus_temperature_tensor', $
                                     '_hpca_heplus_number_density', $
                                     '_hpca_heplus_ion_bulk_velocity', $
                                     '_hpca_heplus_scalar_temperature', $
                                     '_hpca_heplus_ion_pressure', $
                                     '_hpca_heplus_temperature_tensor', $
                                     '_hpca_heplusplus_number_density', $
                                     '_hpca_heplusplus_ion_bulk_velocity', $
                                     '_hpca_heplusplus_scalar_temperature', $
                                     '_hpca_heplusplus_ion_pressure', $
                                     '_hpca_heplusplus_temperature_tensor', $
                                     '_hpca_oplus_number_density', $
                                     '_hpca_oplus_ion_bulk_velocity', $
                                     '_hpca_oplus_scalar_temperature', $
                                     '_hpca_oplus_ion_pressure', $
                                     '_hpca_oplus_temperature_tensor', $
                                     '_hpca_hplus_ion_bulk_velocity_GSM', $
                                     '_hpca_hplus_tperp', $', $
                                     '_hpca_hplus_tparallel', $
                                     '_hpca_hplus_vperp', $', $
                                     '_hpca_hplus_vparallel', $
                                     '_hpca_hplus_vperp_GSM', $
                                     '_hpca_hplus_vparallel_GSM', $
                                     '_hpca_heplus_ion_bulk_velocity_GSM', $
                                     '_hpca_heplus_tperp', $', $
                                     '_hpca_heplus_tparallel', $
                                     '_hpca_heplus_vperp', $', $
                                     '_hpca_heplus_vparallel', $
                                     '_hpca_heplus_vperp_GSM', $
                                     '_hpca_heplus_vparallel_GSM', $
                                     '_hpca_heplusplus_ion_bulk_velocity_GSM', $
                                     '_hpca_heplusplus_tperp', $
                                     '_hpca_heplusplus_tparallel', $
                                     '_hpca_heplusplus_vperp', $
                                     '_hpca_heplusplus_vparallel', $
                                     '_hpca_heplusplus_vperp_GSM', $
                                     '_hpca_heplusplus_vparallel_GSM', $
                                     '_hpca_oplus_ion_bulk_velocity_GSM', $
                                     '_hpca_oplus_tperp', $', $
                                     '_hpca_oplus_tparallel', $
                                     '_hpca_oplus_vperp', $', $
                                     '_hpca_oplus_vparallel', $
                                     '_hpca_oplus_vperp_GSM', $
                                     '_hpca_oplus_vparallel_GSM']
                                     
    ; HPCA brst and srvy products should be the same (no brst data yet, so unconfirmed, 3/29)
    valid_products['hpca-srvy-l2'] = valid_products['hpca-srvy-l2']

    valid_products['fpi-fast-l2'] = ['_des_pitchangdist_lowen_fast', $
                                    '_des_pitchangdist_miden_fast', $
                                    '_des_pitchangdist_highen_fast', $
                                    '_des_numberdensity_fast', $
                                    '_des_numberdensity_dbcs_fast', $
                                    '_des_numberdensity_gse_fast', $
                                    '_des_numberdensity_err_fast', $
                                    '_des_bulkspeed_dbcs_fast', $
                                    '_des_bulkspeed_gse_fast', $
                                    '_des_bulkspeed_err_fast', $
                                    '_des_bulkazimuth_dbcs_fast', $
                                    '_des_bulkazimuth_gse_fast', $
                                    '_des_bulkazimuth_err_fast', $
                                    '_des_bulkzenith_dbcs_fast', $
                                    '_des_bulkzenith_gse_fast', $
                                    '_des_bulkzenith_err_fast', $
                                    '_des_bulkx_dbcs_fast', $
                                    '_des_bulkx_gse_fast', $
                                    '_des_bulkx_err_fast', $
                                    '_des_bulky_dbcs_fast', $
                                    '_des_bulky_gse_fast', $
                                    '_des_bulky_err_fast', $
                                    '_des_bulkz_dbcs_fast', $
                                    '_des_bulkz_gse_fast', $
                                    '_des_bulkz_err_fast', $
                                    '_des_bulkv_dbcs_fast', $
                                    '_des_bulkv_gse_fast', $
                                    '_des_bulkv_err_fast', $
                                    '_des_energyspectr_px_fast', $
                                    '_des_energyspectr_mx_fast', $
                                    '_des_energyspectr_py_fast', $
                                    '_des_energyspectr_my_fast', $
                                    '_des_energyspectr_pz_fast', $
                                    '_des_energyspectr_mz_fast', $
                                    '_des_energyspectr_par_fast', $
                                    '_des_energyspectr_anti_fast', $
                                    '_des_energyspectr_perp_fast', $
                                    '_des_energyspectr_omni_fast', $
                                    '_des_pitchangdist_avg', $
                                    '_des_temptensor_err_fast_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_des_temptensor_gse_fast_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_des_prestensor_err_fast_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_des_prestensor_gse_fast_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_des_temppara_fast', $
                                    '_des_tempperp_fast', $
                                    '_dis_pitchangdist_lowen_fast', $
                                    '_dis_pitchangdist_miden_fast', $
                                    '_dis_pitchangdist_highen_fast', $
                                    '_dis_numberdensity_fast', $
                                    '_dis_numberdensity_dbcs_fast', $
                                    '_dis_numberdensity_gse_fast', $
                                    '_dis_numberdensity_err_fast', $
                                    '_dis_bulkspeed_dbcs_fast', $
                                    '_dis_bulkspeed_gse_fast', $
                                    '_dis_bulkspeed_err_fast', $
                                    '_dis_bulkazimuth_dbcs_fast', $
                                    '_dis_bulkazimuth_gse_fast', $
                                    '_dis_bulkazimuth_err_fast', $
                                    '_dis_bulkzenith_dbcs_fast', $
                                    '_dis_bulkzenith_gse_fast', $
                                    '_dis_bulkzenith_err_fast', $
                                    '_dis_bulkx_dbcs_fast', $
                                    '_dis_bulkx_gse_fast', $
                                    '_dis_bulkx_err_fast', $
                                    '_dis_bulky_dbcs_fast', $
                                    '_dis_bulky_gse_fast', $
                                    '_dis_bulky_err_fast', $
                                    '_dis_bulkz_dbcs_fast', $
                                    '_dis_bulkz_gse_fast', $
                                    '_dis_bulkz_err_fast', $
                                    '_dis_bulkv_dbcs_fast', $
                                    '_dis_bulkv_gse_fast', $
                                    '_dis_bulkv_err_fast', $
                                    '_dis_energyspectr_px_fast', $
                                    '_dis_energyspectr_mx_fast', $
                                    '_dis_energyspectr_py_fast', $
                                    '_dis_energyspectr_my_fast', $
                                    '_dis_energyspectr_pz_fast', $
                                    '_dis_energyspectr_mz_fast', $
                                    '_dis_energyspectr_par_fast', $
                                    '_dis_energyspectr_anti_fast', $
                                    '_dis_energyspectr_perp_fast', $
                                    '_dis_energyspectr_omni_fast', $
                                    '_dis_temptensor_err_fast_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_dis_temptensor_gse_fast_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_dis_prestensor_err_fast_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_dis_prestensor_gse_fast_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_dis_pitchangdist_avg', $
                                    '_dis_temppara_fast', $
                                    '_dis_tempperp_fast']

                                  valid_products['fpi-slow-l2'] = ['_des_pitchangdist_lowen_slow', $
                                    '_des_pitchangdist_miden_slow', $
                                    '_des_pitchangdist_highen_slow', $
                                    '_des_numberdensity_slow', $
                                    '_des_numberdensity_dbcs_slow', $
                                    '_des_numberdensity_gse_slow', $
                                    '_des_numberdensity_err_slow', $
                                    '_des_bulkspeed_dbcs_slow', $
                                    '_des_bulkspeed_gse_slow', $
                                    '_des_bulkspeed_err_slow', $
                                    '_des_bulkazimuth_dbcs_slow', $
                                    '_des_bulkazimuth_gse_slow', $
                                    '_des_bulkazimuth_err_slow', $
                                    '_des_bulkzenith_dbcs_slow', $
                                    '_des_bulkzenith_gse_slow', $
                                    '_des_bulkzenith_err_slow', $
                                    '_des_bulkx_dbcs_slow', $
                                    '_des_bulkx_gse_slow', $
                                    '_des_bulkx_err_slow', $
                                    '_des_bulky_dbcs_slow', $
                                    '_des_bulky_gse_slow', $
                                    '_des_bulky_err_slow', $
                                    '_des_bulkz_dbcs_slow', $
                                    '_des_bulkz_gse_slow', $
                                    '_des_bulkz_err_slow', $
                                    '_des_bulkv_dbcs_slow', $
                                    '_des_bulkv_gse_slow', $
                                    '_des_bulkv_err_slow', $
                                    '_des_energyspectr_px_slow', $
                                    '_des_energyspectr_mx_slow', $
                                    '_des_energyspectr_py_slow', $
                                    '_des_energyspectr_my_slow', $
                                    '_des_energyspectr_pz_slow', $
                                    '_des_energyspectr_mz_slow', $
                                    '_des_energyspectr_par_slow', $
                                    '_des_energyspectr_anti_slow', $
                                    '_des_energyspectr_perp_slow', $
                                    '_des_energyspectr_omni_slow', $
                                    '_des_pitchangdist_avg', $
                                    '_des_temptensor_err_slow_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_des_temptensor_gse_slow_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_des_prestensor_err_slow_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_des_prestensor_gse_slow_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_des_temppara_slow', $
                                    '_des_tempperp_slow', $
                                    '_dis_pitchangdist_lowen_slow', $
                                    '_dis_pitchangdist_miden_slow', $
                                    '_dis_pitchangdist_highen_slow', $
                                    '_dis_numberdensity_slow', $
                                    '_dis_numberdensity_dbcs_slow', $
                                    '_dis_numberdensity_gse_slow', $
                                    '_dis_numberdensity_err_slow', $
                                    '_dis_bulkspeed_dbcs_slow', $
                                    '_dis_bulkspeed_gse_slow', $
                                    '_dis_bulkspeed_err_slow', $
                                    '_dis_bulkazimuth_dbcs_slow', $
                                    '_dis_bulkazimuth_gse_slow', $
                                    '_dis_bulkazimuth_err_slow', $
                                    '_dis_bulkzenith_dbcs_slow', $
                                    '_dis_bulkzenith_gse_slow', $
                                    '_dis_bulkzenith_err_slow', $
                                    '_dis_bulkx_dbcs_slow', $
                                    '_dis_bulkx_gse_slow', $
                                    '_dis_bulkx_err_slow', $
                                    '_dis_bulky_dbcs_slow', $
                                    '_dis_bulky_gse_slow', $
                                    '_dis_bulky_err_slow', $
                                    '_dis_bulkz_dbcs_slow', $
                                    '_dis_bulkz_gse_slow', $
                                    '_dis_bulkz_err_slow', $
                                    '_dis_bulkv_dbcs_slow', $
                                    '_dis_bulkv_gse_slow', $
                                    '_dis_bulkv_err_slow', $
                                    '_dis_energyspectr_px_slow', $
                                    '_dis_energyspectr_mx_slow', $
                                    '_dis_energyspectr_py_slow', $
                                    '_dis_energyspectr_my_slow', $
                                    '_dis_energyspectr_pz_slow', $
                                    '_dis_energyspectr_mz_slow', $
                                    '_dis_energyspectr_par_slow', $
                                    '_dis_energyspectr_anti_slow', $
                                    '_dis_energyspectr_perp_slow', $
                                    '_dis_energyspectr_omni_slow', $
                                    '_dis_temptensor_err_slow_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_dis_temptensor_gse_slow_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_dis_prestensor_err_slow_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_dis_prestensor_gse_slow_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_dis_pitchangdist_avg', $
                                    '_dis_temppara_slow', $
                                    '_dis_tempperp_slow']

    valid_products['fpi-brst-l2'] = ['_des_pitchangdist_lowen_brst', $
                                    '_des_pitchangdist_miden_brst', $
                                    '_des_pitchangdist_highen_brst', $
                                    '_des_numberdensity_dbcs_brst', $
                                    '_des_numberdensity_brst', $
                                    '_des_numberdensity_gse_brst', $
                                    '_des_numberdensity_err_brst', $
                                    '_des_bulkspeed_dbcs_brst', $
                                    '_des_bulkspeed_gse_brst', $
                                    '_des_bulkspeed_err_brst', $
                                    '_des_bulkazimuth_dbcs_brst', $
                                    '_des_bulkazimuth_gse_brst', $
                                    '_des_bulkazimuth_err_brst', $
                                    '_des_bulkzenith_dbcs_brst', $
                                    '_des_bulkzenith_gse_brst', $
                                    '_des_bulkzenith_err_brst', $
                                    '_des_bulkx_dbcs_brst', $
                                    '_des_bulkx_gse_brst', $
                                    '_des_bulkx_err_brst', $
                                    '_des_bulky_dbcs_brst', $
                                    '_des_bulky_gse_brst', $
                                    '_des_bulky_err_brst', $
                                    '_des_bulkz_dbcs_brst', $
                                    '_des_bulkz_gse_brst', $
                                    '_des_bulkz_err_brst', $
                                    '_des_bulkv_dbcs_brst', $
                                    '_des_bulkv_gse_brst', $
                                    '_des_bulkv_err_brst', $
                                    '_des_energyspectr_px_brst', $
                                    '_des_energyspectr_mx_brst', $
                                    '_des_energyspectr_py_brst', $
                                    '_des_energyspectr_my_brst', $
                                    '_des_energyspectr_pz_brst', $
                                    '_des_energyspectr_mz_brst', $
                                    '_des_energyspectr_par_brst', $
                                    '_des_energyspectr_anti_brst', $
                                    '_des_energyspectr_perp_brst', $
                                    '_des_energyspectr_omni_brst', $
                                    '_des_pitchangdist_avg', $
                                    '_des_temptensor_err_brst_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_des_temptensor_gse_brst_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_des_prestensor_err_brst_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_des_prestensor_gse_brst_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_des_temppara_brst', $
                                    '_des_tempperp_brst', $
                                    '_dis_pitchangdist_lowen_brst', $
                                    '_dis_pitchangdist_miden_brst', $
                                    '_dis_pitchangdist_highen_brst', $
                                    '_dis_numberdensity_dbcs_brst', $
                                    '_dis_numberdensity_brst', $
                                    '_dis_numberdensity_gse_brst', $
                                    '_dis_numberdensity_err_brst', $
                                    '_dis_bulkspeed_dbcs_brst', $
                                    '_dis_bulkspeed_gse_brst', $
                                    '_dis_bulkspeed_err_brst', $
                                    '_dis_bulkazimuth_dbcs_brst', $
                                    '_dis_bulkazimuth_gse_brst', $
                                    '_dis_bulkazimuth_err_brst', $
                                    '_dis_bulkzenith_dbcs_brst', $
                                    '_dis_bulkzenith_gse_brst', $
                                    '_dis_bulkzenith_err_brst', $
                                    '_dis_bulkx_dbcs_brst', $
                                    '_dis_bulkx_gse_brst', $
                                    '_dis_bulkx_err_brst', $
                                    '_dis_bulky_dbcs_brst', $
                                    '_dis_bulky_gse_brst', $
                                    '_dis_bulky_err_brst', $
                                    '_dis_bulkz_dbcs_brst', $
                                    '_dis_bulkz_gse_brst', $
                                    '_dis_bulkz_err_brst', $
                                    '_dis_bulkv_dbcs_brst', $
                                    '_dis_bulkv_gse_brst', $
                                    '_dis_bulkv_err_brst', $
                                    '_dis_energyspectr_px_brst', $
                                    '_dis_energyspectr_mx_brst', $
                                    '_dis_energyspectr_py_brst', $
                                    '_dis_energyspectr_my_brst', $
                                    '_dis_energyspectr_pz_brst', $
                                    '_dis_energyspectr_mz_brst', $
                                    '_dis_energyspectr_par_brst', $
                                    '_dis_energyspectr_anti_brst', $
                                    '_dis_energyspectr_perp_brst', $
                                    '_dis_energyspectr_omni_brst', $
                                    '_dis_pitchangdist_avg', $
                                    '_dis_temptensor_err_brst_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_dis_temptensor_gse_brst_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_dis_prestensor_err_brst_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_dis_prestensor_gse_brst_'+['xx', 'xy', 'xz', 'yx', 'yy', 'yz', 'zx', 'zy', 'zz'], $
                                    '_dis_temppara_brst', $
                                    '_dis_tempperp_brst']
                                    
    valid_products['feeps-srvy-l2'] = ['_epd_feeps_srvy_l2_electron_intensity_omni', $
                                      '_epd_feeps_srvy_l2_electron_intensity_omni_spin', $
                                      '_epd_feeps_srvy_l2_ion_intensity_omni', $
                                      '_epd_feeps_srvy_l2_ion_intensity_omni_spin', $
                                      '_epd_feeps_srvy_l2_electron_top_count_rate_sensorid_1_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_top_count_rate_sensorid_2_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_top_count_rate_sensorid_3_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_top_count_rate_sensorid_4_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_top_count_rate_sensorid_5_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_top_count_rate_sensorid_9_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_top_count_rate_sensorid_10_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_top_count_rate_sensorid_11_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_top_count_rate_sensorid_12_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_bottom_count_rate_sensorid_1_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_bottom_count_rate_sensorid_2_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_bottom_count_rate_sensorid_3_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_bottom_count_rate_sensorid_4_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_bottom_count_rate_sensorid_5_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_bottom_count_rate_sensorid_9_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_bottom_count_rate_sensorid_10_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_bottom_count_rate_sensorid_11_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_bottom_count_rate_sensorid_12_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_top_intensity_sensorid_1_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_top_intensity_sensorid_2_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_top_intensity_sensorid_3_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_top_intensity_sensorid_4_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_top_intensity_sensorid_5_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_top_intensity_sensorid_9_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_top_intensity_sensorid_10_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_top_intensity_sensorid_11_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_top_intensity_sensorid_12_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_bottom_intensity_sensorid_1_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_bottom_intensity_sensorid_2_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_bottom_intensity_sensorid_3_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_bottom_intensity_sensorid_4_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_bottom_intensity_sensorid_5_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_bottom_intensity_sensorid_9_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_bottom_intensity_sensorid_10_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_bottom_intensity_sensorid_11_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_electron_bottom_intensity_sensorid_12_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_ion_top_count_rate_sensorid_6_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_ion_top_count_rate_sensorid_7_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_ion_top_count_rate_sensorid_8_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_ion_bottom_count_rate_sensorid_6_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_ion_bottom_count_rate_sensorid_7_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_ion_bottom_count_rate_sensorid_8_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_ion_top_intensity_sensorid_6_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_ion_top_intensity_sensorid_7_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_ion_top_intensity_sensorid_8_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_ion_bottom_intensity_sensorid_6_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_ion_bottom_intensity_sensorid_7_clean_sun_removed', $
                                      '_epd_feeps_srvy_l2_ion_bottom_intensity_sensorid_8_clean_sun_removed']
    
    valid_products['feeps-brst-l2'] = ['_epd_feeps_brst_l2_electron_intensity_omni', $
                                      '_epd_feeps_brst_l2_electron_intensity_omni_spin', $
                                      '_epd_feeps_brst_l2_ion_intensity_omni', $
                                      '_epd_feeps_brst_l2_ion_intensity_omni_spin', $
                                      '_epd_feeps_brst_l2_electron_top_count_rate_sensorid_1_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_top_count_rate_sensorid_2_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_top_count_rate_sensorid_3_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_top_count_rate_sensorid_4_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_top_count_rate_sensorid_5_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_top_count_rate_sensorid_9_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_top_count_rate_sensorid_10_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_top_count_rate_sensorid_11_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_top_count_rate_sensorid_12_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_bottom_count_rate_sensorid_1_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_bottom_count_rate_sensorid_2_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_bottom_count_rate_sensorid_3_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_bottom_count_rate_sensorid_4_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_bottom_count_rate_sensorid_5_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_bottom_count_rate_sensorid_9_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_bottom_count_rate_sensorid_10_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_bottom_count_rate_sensorid_11_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_bottom_count_rate_sensorid_12_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_top_intensity_sensorid_1_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_top_intensity_sensorid_2_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_top_intensity_sensorid_3_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_top_intensity_sensorid_4_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_top_intensity_sensorid_5_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_top_intensity_sensorid_9_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_top_intensity_sensorid_10_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_top_intensity_sensorid_11_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_top_intensity_sensorid_12_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_bottom_intensity_sensorid_1_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_bottom_intensity_sensorid_2_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_bottom_intensity_sensorid_3_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_bottom_intensity_sensorid_4_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_bottom_intensity_sensorid_5_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_bottom_intensity_sensorid_9_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_bottom_intensity_sensorid_10_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_bottom_intensity_sensorid_11_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_electron_bottom_intensity_sensorid_12_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_ion_top_count_rate_sensorid_6_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_ion_top_count_rate_sensorid_7_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_ion_top_count_rate_sensorid_8_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_ion_bottom_count_rate_sensorid_6_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_ion_bottom_count_rate_sensorid_7_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_ion_bottom_count_rate_sensorid_8_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_ion_top_intensity_sensorid_6_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_ion_top_intensity_sensorid_7_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_ion_top_intensity_sensorid_8_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_ion_bottom_intensity_sensorid_6_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_ion_bottom_intensity_sensorid_7_clean_sun_removed', $
                                      '_epd_feeps_brst_l2_ion_bottom_intensity_sensorid_8_clean_sun_removed']
    
    valid_products['scm-srvy-l2'] = ['_scm_acb_gse_scsrvy_srvy_l2']
    
    valid_products['scm-brst-l2'] = ['_scm_acb_gse_scb_brst_l2', $
                                    '_scm_acb_gse_schb_brst_l2']
    
    valid_products['edi-srvy-l2'] = ['_edi_vdrift_dsl_srvy_l2', $
                                     '_edi_vdrift_gse_srvy_l2', $
                                     '_edi_vdrift_gsm_srvy_l2', $
                                     '_edi_e_dsl_srvy_l2', $
                                     '_edi_e_gse_srvy_l2', $
                                     '_edi_e_gsm_srvy_l2']

    valid_products['edi-brst-l2'] = ['_edi_vdrift_dsl_brst_l2', $
                                     '_edi_vdrift_gse_brst_l2', $
                                     '_edi_vdrift_gsm_brst_l2', $
                                     '_edi_e_dsl_brst_l2', $
                                     '_edi_e_gse_brst_l2', $
                                     '_edi_e_gsm_brst_l2']

                                    
    valid_products['edp-fast-l2'] = ['_edp_dce_gse_fast_l2', '_edp_dce_dsl_fast_l2', '_edp_scpot_fast_l2', $
                                    '_edp_hfesp_fast_l2']
    valid_products['edp-slow-l2'] = ['_edp_dce_gse_slow_l2', '_edp_dce_dsl_slow_l2', '_edp_scpot_slow_l2', $
                                    '_edp_hfesp_slow_l2']
    valid_products['edp-brst-l2'] = ['_edp_dce_gse_brst_l2', '_edp_dce_dsl_brst_l2', '_edp_scpot_brst_l2', $
                                    '_edp_hmfe_dsl_brst_l2']
    valid_products['edp-srvy-l2'] = ['_edp_hfesp_srvy_l2']

    valid_products['dsp-fast-l2'] = ['_dsp_epsd_x', '_dsp_epsd_y', '_dsp_epsd_z', $
                                    '_dsp_epsd_omni', '_dsp_bpsd_scm1_fast_l2', $
                                    '_dsp_bpsd_scm2_fast_l2', '_dsp_bpsd_scm3_fast_l2', $
                                    '_dsp_bpsd_omni_fast_l2']
                                    
    valid_products['dsp-slow-l2'] = ['_dsp_epsd_x', '_dsp_epsd_y', '_dsp_epsd_z', $
                                    '_dsp_epsd_omni', '_dsp_bpsd_scm1_slow_l2', $
                                    '_dsp_bpsd_scm2_slow_l2', '_dsp_bpsd_scm3_slow_l2', $
                                    '_dsp_bpsd_omni_slow_l2']
                                    
    valid_products['mec-srvy-l2'] =['_mec_dipole_tilt', $
                                    '_mec_gmst', $
                                    '_mec_mlat', $
                                    '_mec_mlt', $
                                    '_mec_l_dipole', $
                                    '_mec_quat_eci_to_bcs', $
                                    '_mec_quat_eci_to_dbcs', $
                                    '_mec_quat_eci_to_dmpa', $
                                    '_mec_quat_eci_to_smpa', $
                                    '_mec_quat_eci_to_dsl', $
                                    '_mec_quat_eci_to_ssl', $
                                    '_mec_L_vec', $
                                    '_mec_Z_vec', $
                                    '_mec_P_vec', $
                                    '_mec_L_phase', $
                                    '_mec_Z_phase', $
                                    '_mec_P_phase', $
                                    '_mec_kp', $
                                    '_mec_dst', $
                                    '_mec_earth_eclipse_flag', $
                                    '_mec_moon_eclipse_flag', $
                                    '_mec_r_eci', $
                                    '_mec_v_eci', $
                                    '_mec_r_gsm', $
                                    '_mec_v_gsm', $
                                    '_mec_quat_eci_to_gsm', $
                                    '_mec_r_geo', $
                                    '_mec_v_geo', $
                                    '_mec_quat_eci_to_geo', $
                                    '_mec_r_sm', $', $
                                    '_mec_v_sm', $', $
                                    '_mec_quat_eci_to_sm', $
                                    '_mec_r_gse', $
                                    '_mec_v_gse', $
                                    '_mec_quat_eci_to_gse', $
                                    '_mec_r_gse2000', $
                                    '_mec_v_gse2000', $
                                    '_mec_quat_eci_to_gse2000', $
                                    '_mec_geod_lat', $
                                    '_mec_geod_lon', $
                                    '_mec_geod_height', $
                                    '_mec_r_sun_de421_eci', $
                                    '_mec_r_moon_de421_eci', $
                                    '_mec_fieldline_type', $
                                    '_mec_bsc_gsm', $
                                    '_mec_loss_cone_angle_s', $
                                    '_mec_loss_cone_angle_n', $
                                    '_mec_pfs_geod_latlon', $
                                    '_mec_pfn_geod_latlon', $
                                    '_mec_pfs_gsm', $
                                    '_mec_bfs_gsm', $
                                    '_mec_pfn_gsm', $
                                    '_mec_bfn_gsm', $
                                    '_mec_pmin_gsm', $
                                    '_mec_bmin_gsm', $
                                    '_defatt_spinras', $
                                    '_defatt_spindec']
    
    ; assuming MEC names are the same for srvy and brst
    valid_products['mec-brst-l2'] = valid_products['mec-srvy-l2']
    
    valid_products['aspoc-srvy-l2'] = ['_aspoc_ionc_l2', $
                                      '_asp1_ionc_l2', $
                                      '_asp2_ionc_l2', $
                                      '_asp1_energy_l2', $
                                      '_asp2_energy_l2', $
                                      '_aspoc_status_l2']

    for probe_idx = 0, n_elements(probes)-1 do begin
        this_probe = strcompress(string(probes[probe_idx]), /rem)
        append_array, products_out, 'mms'+this_probe+valid_products[instrument+'-'+rate+'-'+level]
    endfor

    if valid_products.haskey(instrument+'-'+rate+'-'+level) then begin
      return, products_out
    endif else begin
      return, -1 ; not found
    endelse
end
