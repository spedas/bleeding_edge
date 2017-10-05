pro spp_fld_example_crib

  cdf_dir = getenv('SPP_FLD_CDF_DIR')
  
  store_data, '*', /del

  ;dprint, setdebug = 2
  dprint, setdebug = 3

  ;spp_fld_tmlib_init, server = 'rflab.ssl.berkeley.edu'
  spp_fld_tmlib_init, server = 'spffmdb.ssl.berkeley.edu'

  ;timespan, '2016-01-21/20:00:00', 1./24
  ;timespan, '2016-01-21/22:00:00', 1./24
  ;timespan, '2015-11-02/20:00:00', 1./24/5.
  ;timespan, '2016-11-22/21:45:00', 1./24./3

  ;timespan, '2015-12-13/00:00:00';, 1./24

  ; MAGO spike

  ;timespan, '2016-12-00/19:00:00', 30.
  timespan, '2016-12-09/17:24:00', 1./24.;/12

  timespan, '2016-12-09/17:59:10', 1./24./60./4;/12

;
  spp_fld_make_cdf_l1, 'mago_survey', varformat = ["mag_by", $
    "mag_bz", "avg_period_raw", "mag_bx", "range_bits"], filename = mago_fi

  spp_fld_mago_survey_load_l1, mago_fi

  tplot, 'spp_fld_mago_survey_' + ['mag_bx', 'mag_by', 'mag_bz', 'packet_index', 'range']

;  spp_fld_mago_survey_load_l1, '~/box/06_SOC/cdf/' + fi

;
;
;
;  timespan, '2016-01-08', 1./24
;
;  spp_fld_make_cdf_l1, 'f1_analog_hk'

;  timespan, '2016-05-19/23:40:00', 1./24/10.

  ;spp_fld_make_cdf_l1, 'f1_analog_hk', filename = fi

;  spp_fld_make_cdf_l1, 'rfs_hfr_auto', filename = fi

  ;return

  ;fi = '~/box/06_SOC/cdf/spp_fld_l1_rfs_hfr_auto_20160519_234000_20160519_234130_v00.cdf'

  ;spp_fld_rfs_hfr_load_l1, '~/box/06_SOC/cdf/' + fi

  ;spp_fld_dcb_hk_load_l1, fi

  ;stop

end