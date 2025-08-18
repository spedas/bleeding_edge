function spp_fld_select_timespan_define_presets, fm_or_em
  compile_opt idl2

  fm_times = orderedhash()
  fm_times['TB_bus_bar_fail'] = ['2024-12-19/16:15:00', '2024-12-19/17:15:00']
  fm_times['TC_egse_checkout_MAG'] = ['2018-02-17/00:43:00', '2018-02-17/00:58:00']
  fm_times['TC_egse_checkout_RFS'] = ['2018-02-17/01:00:00', '2018-02-17/01:20:00']
  fm_times['TC_mag_scm_intercal'] = ['2020-04-24/13:40:00', '2020-04-24/15:00:00']
  fm_times['TC_mag_scm_intercal_dfb_gaps'] = ['2020-04-24/13:58:13', '2020-04-24/14:00:16']
  fm_times['TC_encounter_OITL'] = ['2020-05-27/20:00:00', '2020-05-28/04:00:00']
  fm_times['TC_enc_DFB_XSPEC_test'] = ['2020-05-28/00:50:00', '2020-05-28/01:20:00']
  fm_times['TC_enc_OITL_magpkt'] = ['2020-05-28/01:14:00', '2020-05-28/01:16:00']
  fm_times['TC_COLD_CPT_MAG'] = ['2020-07-17/17:30:00', '2020-07-17/19:00:00']
  fm_times['TC_COLD_CPT_DFB'] = ['2020-07-17/19:30:00', '2020-07-17/21:00:00']
  fm_times['TC_HOT_CPT_MAG'] = ['2020-07-20/00:30:00', '2020-07-20/01:30:00']
  fm_times['TC_HOT_CPT_DFB'] = ['2020-07-19/23:40:00', '2020-07-20/01:00:00']
  fm_times['TC_HOT_CPT_RFS'] = ['2020-07-20/02:10:00', '2020-07-20/02:20:00']
  fm_times['MAG_SNSRTMP_sinusoid'] = ['2018-03-18/21:00:00', '2018-03-18/23:00:00']
  fm_times['V1_diagnostic'] = ['2018-03-18/16:00:00', '2018-03-18/23:00:00']
  fm_times['post_ship_functional'] = ['2018-04-09/13:30:00', '2018-04-09/17:00:00']
  fm_times['post_ship_functional_DFB_pre'] = ['2018-04-09/13:30:00', '2018-04-09/14:30:00']
  fm_times['post_ship_CAL_RFS'] = ['2018-04-16/18:00:00', '2018-04-16/23:00:00']
  fm_times['post_ship_CPT_MAG'] = ['2018-04-17/19:30:00', '2018-04-17/21:15:00']
  fm_times['post_ship_CPT_DFB'] = ['2018-04-17/21:10:00', '2018-04-17/22:00:00']
  fm_times['post_ship_CPT_RFS_check_fails'] = ['2018-04-17/22:30:00', '2018-04-17/23:00:00']
  fm_times['SCM_xtalk_BY_part1'] = ['2018-04-17/23:30:00', '2018-04-18/00:30:00']
  fm_times['SCM_xtalk_BY_part2'] = ['2018-04-18/13:00:00', '2018-04-18/14:45:00']
  fm_times['SCM_xtalk_BZ'] = ['2018-04-18/15:00:00', '2018-04-18/16:00:00']
  fm_times['magboom_fluxcannon'] = ['2018-05-23/23:50:00', '2018-05-24/00:10:00']
  fm_times['v5_newscrews_Jun05'] = ['2018-06-04/22:40:00', '2018-06-06/00:20:00']
  fm_times['groundtest_Jun12_OK'] = ['2018-06-11/22:30:00', '2018-06-12/02:00:00']
  fm_times['aliveness_Jun19_OK'] = ['2018-06-19/15:20:00', '2018-06-19/16:40:00']
  fm_times['aliveness_V3_anomaly'] = ['2018-08-01/05:00:00', '2018-08-01/07:30:00']
  fm_times['turn_on_look_at_V3'] = ['2018-08-04/15:30:00', '2018-08-04/21:30:00']

  fm_times['commissioning_day2'] = ['2018-08-13/11:00:00', '2018-08-13/18:00:00']
  fm_times['com_d2_boom_frang_tall'] = ['2018-08-13/11:46:00', '2018-08-13/11:51:00']
  fm_times['com_d2_boom_frang_tall_redun'] = ['2018-08-13/13:05:00', '2018-08-13/13:10:00']
  fm_times['com_d2_hga_frang'] = ['2018-08-13/15:05:00', '2018-08-13/15:10:00']
  fm_times['com_d2_rfs_2fullspec_pre_clam'] = ['2018-08-13/15:25:00', '2018-08-13/15:29:00']
  fm_times['com_d2_clamshell_v3v4'] = ['2018-08-13/15:33:00', '2018-08-13/15:48:00']
  fm_times['com_d2_clamshell_v1v2'] = ['2018-08-13/15:48:00', '2018-08-13/15:53:00']
  fm_times['com_d2_rfs_5fullspec_pre_boom'] = ['2018-08-13/16:10:00', '2018-08-13/16:35:00']
  fm_times['com_d2_hga_frang_redun'] = ['2018-08-13/16:43:30', '2018-08-13/16:47:30']
  fm_times['com_d2_thrust_momdump'] = ['2018-08-13/17:05:00', '2018-08-13/17:15:00']
  fm_times['com_d2_magboom'] = ['2018-08-13/17:15:00', '2018-08-13/17:25:00']
  fm_times['com_d2_magboom_zoom'] = ['2018-08-13/17:18:30', '2018-08-13/17:19:30']

  fm_times['commissioning_day3'] = ['2018-08-14/15:00:00', '2018-08-14/17:10:00']
  fm_times['com_d3_biasing_1'] = ['2018-08-14/15:30:00', '2018-08-14/15:50:00']
  fm_times['com_d3_scm_cal'] = ['2018-08-14/15:48:00', '2018-08-14/15:49:00']
  fm_times['com_d3_biasing_2'] = ['2018-08-14/16:05:00', '2018-08-14/16:20:00']
  fm_times['com_d3_rfs_2fullspec_scm'] = ['2018-08-14/16:00:00', '2018-08-14/16:15:00']
  fm_times['com_d3_mag_zero'] = ['2018-08-14/16:20:00', '2018-08-14/16:50:00']
  fm_times['com_d3_mago_2Hz'] = ['2018-08-14/16:47:00', '2018-08-14/17:02:00']

  fm_times['commissioning_day4'] = ['2018-08-15/15:00:00', '2018-08-15/21:00:00']
  fm_times['com_d4_mom_dump'] = ['2018-08-15/16:40:00', '2018-08-15/16:41:00']
  fm_times['com_d4_commanded_dump'] = ['2018-08-15/19:36:45', '2018-08-15/19:37:45']

  fm_times['commissioning_day5'] = ['2018-08-16/19:50:00', '2018-08-17/05:30:00']

  fm_times['com_spc_turnon'] = ['2018-08-30/04:00:00', '2018-08-30/12:00:00']
  fm_times['com_spc_turnon_fields_pre_setup'] = ['2018-08-30/05:26:00', '2018-08-30/05:31:00']

  fm_times['deploy_v1234'] = ['2018-09-02/21:30:00', '2018-09-03/05:30:00']

  deploy_v1_time = time_double('2018-09-02/23:20:20')

  fm_times['deploy_v1_10_min'] = deploy_v1_time + [-60d, 600d]
  fm_times['deploy_v1_01_min'] = deploy_v1_time + [-10d, 60d]
  fm_times['deploy_v1_15_sec'] = deploy_v1_time + [-5d, 15d]

  deploy_v2_time = time_double('2018-09-03/00:07:40')

  fm_times['deploy_v2_10_min'] = deploy_v2_time + [-60d, 600d]
  fm_times['deploy_v2_01_min'] = deploy_v2_time + [-10d, 60d]
  fm_times['deploy_v2_15_sec'] = deploy_v2_time + [-5d, 15d]

  deploy_v3_time = time_double('2018-09-03/00:57:50')

  fm_times['deploy_v3_10_min'] = deploy_v3_time + [-60d, 600d]
  fm_times['deploy_v3_01_min'] = deploy_v3_time + [-10d, 60d]
  fm_times['deploy_v3_15_sec'] = deploy_v3_time + [-5d, 15d]

  deploy_v4_time = time_double('2018-09-03/01:30:35')

  fm_times['deploy_v4_10_min'] = deploy_v4_time + [-60d, 600d]
  fm_times['deploy_v4_01_min'] = deploy_v4_time + [-10d, 60d]
  fm_times['deploy_v4_15_sec'] = deploy_v4_time + [-5d, 15d]

  fm_times['deploy_test_rfs_flags'] = ['2018-09-03/00:57:00', '2018-09-03/01:06:00']

  fm_times['deploy_hfr_lfr_pre_deploys'] = ['2018-09-02/22:20:00', '2018-09-02/22:40:00']
  fm_times['deploy_hfr_lfr_post_v1_deploy'] = ['2018-09-02/23:47:20', '2018-09-02/23:50:35']
  fm_times['deploy_hfr_lfr_post_v2_deploy'] = ['2018-09-03/00:28:20', '2018-09-03/00:35:40']
  fm_times['deploy_hfr_lfr_post_v3_deploy'] = ['2018-09-03/01:18:20', '2018-09-03/01:19:10']
  fm_times['deploy_hfr_lfr_post_v4_deploy'] = ['2018-09-03/01:48:30', '2018-09-03/02:12:00']

  fm_times['rfs_default_hold'] = ['2018-09-03/01:49:00', '2018-09-03/02:12:00']

  fm_times['rfs_electrostatic_wave'] = ['2018-09-03/04:20:00', '2018-09-03/04:40:00']

  fm_times['support_sweap_turnon_rt'] = ['2018-09-05/20:00:00', '2018-09-06/02:00:00']

  fm_times['support_sweap_rfs_typeiii'] = ['2018-09-06/00:00:00', '2018-09-06/04:00:00']

  fm_times['bias_test_rt_interval'] = ['2018-09-07/02:00:00', '2018-09-07/07:00:00']
  fm_times['bias_scm_cal'] = ['2018-09-07/02:27:00', '2018-09-07/02:38:00']
  fm_times['bias_v1_BIAS_stepping'] = ['2018-09-07/02:35:00', '2018-09-07/02:55:00']
  fm_times['bias_v2_BIAS_stepping'] = ['2018-09-07/02:55:00', '2018-09-07/03:05:00']
  fm_times['bias_v3_BIAS_stepping'] = ['2018-09-07/03:10:00', '2018-09-07/03:17:00']
  fm_times['bias_v4_BIAS_stepping'] = ['2018-09-07/03:10:00', '2018-09-07/03:17:00']

  fm_times['bias_v1234_30_pct_photo'] = ['2018-09-07/03:42:00', '2018-09-07/03:52:00']
  fm_times['bias_v1234_20_pct_photo'] = ['2018-09-07/03:56:00', '2018-09-07/04:06:00']

  fm_times['bias_stub_shield_p5V_m5V_0'] = ['2018-09-07/04:04:00', '2018-09-07/04:12:00']
  fm_times['bias_rbias_2'] = ['2018-09-07/04:20:00', '2018-09-07/04:30:00']
  fm_times['bias_rbias_1'] = ['2018-09-07/04:30:00', '2018-09-07/05:20:00']
  fm_times['bias_v5_BIAS_stepping'] = ['2018-09-07/05:20:00', '2018-09-07/05:40:00']
  fm_times['bias_v5_box_p5V_m5V_0'] = ['2018-09-07/05:45:00', '2018-09-07/06:05:00']
  fm_times['bias_v5_box_p5V_m5V_0'] = ['2018-09-07/05:45:00', '2018-09-07/06:05:00']
  fm_times['bias_model_sdt'] = ['2018-09-07/06:09:00', '2018-09-07/06:19:00']
  fm_times['bias_set_20_pct_photo'] = ['2018-09-07/06:20:00', '2018-09-07/06:22:00']

  fm_times['rollslew'] = ['2018-09-08/00:00:00', '2018-09-08/10:00:00']
  fm_times['rollslew_mag_rolls'] = ['2018-09-08/02:00:00', '2018-09-08/04:45:00']
  fm_times['rollslew_sweap_slew'] = ['2018-09-08/04:45:00', '2018-09-08/05:45:00']

  fm_times['rollslew_hfr_noise'] = ['2018-09-08/04:50:00', '2018-09-08/05:40:00']

  fm_times['umbra_pointing'] = ['2018-09-17/06:00:00', '2018-09-17/23:00:00']

  fm_times['umbra_pointing_upp'] = ['2018-09-17/14:00:00', '2018-09-17/17:15:00']

  fm_times['upp_rfs_lfr_noise'] = ['2018-09-17/06:30:00', '2018-09-17/08:30:00']
  fm_times['upp_rfs_jovian_emission'] = ['2018-09-17/09:40:00', '2018-09-17/10:40:00']

  fm_times['multi_instrument'] = ['2018-09-24/12:00:00', '2018-09-28/12:00:00']
  fm_times['multi_instrument_turnons'] = ['2018-09-24/13:00:00', '2018-09-24/18:00:00']

  fm_times['dfb_ac_bpf_double_packet'] = ['2018-09-26/05:35:00', '2018-09-26/05:36:00']

  fm_times['umbra_pointing_2'] = ['2018-10-02/03:15:00', '2018-10-02/17:45:00']

  fm_times['venus_flyby_1'] = ['2018-10-03/01:30:00', '2018-10-03/10:30:00']

  fm_times['dfb_overlap_wf_example'] = ['2018-10-03/16:13:00', '2018-10-03/16:15:00']
  fm_times['fields_rotations'] = ['2018-10-03/16:30:00', '2018-10-03/21:30:00']

  fm_times['v5_hirate_sunsens_test'] = ['2018-10-04/11:00:00', '2018-10-04/15:00:00']
  fm_times['v5_sls_in_umbra'] = ['2018-10-04/11:20:00', '2018-10-04/12:50:00']
  fm_times['v5_sls_to_wiggle_1'] = ['2018-10-04/11:31:30', '2018-10-04/11:43:30']
  fm_times['v5_sls_to_wiggle_2'] = ['2018-10-04/11:43:30', '2018-10-04/11:53:30']
  fm_times['v5_sls_to_wiggle_3'] = ['2018-10-04/11:53:30', '2018-10-04/12:03:30']
  fm_times['v5_sls_to_wiggle_4'] = ['2018-10-04/12:03:30', '2018-10-04/12:14:30']
  fm_times['v5_sls_to_wiggle_5'] = ['2018-10-04/12:14:30', '2018-10-04/12:24:30']
  fm_times['v5_sls_to_wiggle_6'] = ['2018-10-04/12:24:30', '2018-10-04/12:34:30']
  fm_times['v5_sls_to_wiggle_7'] = ['2018-10-04/12:34:30', '2018-10-04/12:44:30']

  fm_times['e01_dcp_reset'] = ['2018-10-05/12:00:00', '2018-10-05/15:00:00']

  fm_times['e01_pre_cruise'] = ['2018-10-05/00:00:00', '2018-10-31/00:00:00']

  fm_times['e01_start_to_perihelion'] = ['2018-10-31/08:30:00', '2018-11-06/08:35:00']

  fm_times['e01_encounter_plus1day'] = ['2018-10-30/11:56:51', '2018-11-12/18:58:51']

  fm_times['e01_encounter'] = ['2018-10-31/11:56:51', '2018-11-11/18:58:51']

  fm_times['e01_rfs_start_peaks'] = ['2018-11-04/09:25:00', '2018-11-04/09:35:00']

  fm_times['e01_big_typeiii'] = ['2018-11-04/16:00:00', '2018-11-04/18:00:00']

  fm_times['e01_possible_jovian'] = ['2018-11-04/16:00:00', '2018-11-04/18:00:00']

  fm_times['e01_mom_dump'] = ['2018-11-06/19:50:00', '2018-11-06/20:30:00']

  fm_times['fields_rolls_post_e01'] = ['2018-11-18/12:00:00', '2018-11-19/00:00:00']
  fm_times['fields_conics_post_e01'] = ['2018-12-17/08:00:00', '2018-12-18/16:00:00']

  fm_times['sls_test_post_e01'] = ['2019-03-03/13:00:00', '2019-03-03/15:30:00']
  fm_times['sls_test_post_e01_zoom'] = ['2019-03-03/13:15:00', '2019-03-03/14:45:00']

  fm_times['e02_encounter'] = ['2019-03-30/04:39:00', '2019-04-10/16:42:00']
  fm_times['e02_encounter_plus1day'] = ['2019-03-29/04:39:00', '2019-04-11/16:42:00']

  fm_times['e02_striated_burst'] = ['2019-04-01/01:50:18', '2019-04-01/02:12:56']
  fm_times['e02_large_burst_flare_Lang'] = ['2019-04-02/15:23:00', '2019-04-02/16:09:00']

  fm_times['sls_test_post_e02'] = ['2019-05-07/04:30:00', '2019-05-07/08:00:00']

  fm_times['fields_rolls_post_e02'] = ['2019-04-13/22:00:00', '2019-04-14/14:00:00']

  fm_times['e03_encounter'] = ['2019-08-20/00:00:00', '2019-09-20/00:00:00']

  fm_times['e04_encounter'] = ['2020-01-15/00:00:00', '2020-02-15/00:00:00']

  em_times = orderedhash()

  em_times['EM_test_RFS_v29'] = ['2018-02-22/19:30:00', '2018-02-22/21:30:00']
  em_times['EM_test_CPT_DFB'] = ['2018-03-04/23:55:00', '2018-03-05/00:22:00']
  em_times['EM_test_MAG_DFB'] = ['2018-03-04/19:25:00', '2018-03-04/19:35:00']
  em_times['EM_test_DFB_rotation'] = ['2018-03-22/20:00:00', '2018-03-23/01:00:00']
  em_times['EM_test_DFB_rotation_zoom'] = ['2018-03-22/23:05:00', '2018-03-22/23:15:00']

  em_times['EM_test_RFS_cal_v1'] = ['2018-04-12/23:30:00', '2018-04-13/01:30:00']
  em_times['EM_test_RFS_cal_v2'] = ['2018-04-13/22:30:00', '2018-04-13/01:00:00']

  em_times['EM_test_DFB_CBS_for_SCM_CAL'] = ['2018-07-26/18:00:00', '2018-07-26/22:30:00']

  em_times['EM_test_1GOhm_Biasing'] = ['2018-08-03/18:00:00', '2018-08-03/21:30:00']
  em_times['EM_test_1GOhm_Biasing_zoom'] = ['2018-08-03/20:22:00', '2018-08-03/20:36:00']

  em_times['EM_test_1GOhm_Biasing_V1234'] = ['2018-08-07/01:40:00', '2018-08-07/01:45:00']

  em_times['EM_test_RFS_5fullspec'] = ['2018-08-06/18:00:00', '2018-08-06/18:45:00']

  em_times['EM_test_command_v5_256'] = ['2018-08-16/22:30:00', '2018-08-16/23:00:00']

  em_times['EM_test_remove_1GOhm'] = ['2018-08-17/16:10:00', '2018-08-16/16:40:00']

  em_times['Venus_7_test'] = ['2024-11-06/18:30:00', '2024-11-06/19:00:00']

  if fm_or_em eq 'FM' then return, fm_times else return, em_times
end

function spp_fld_select_timespan_preset, preset_times
  compile_opt idl2

  preset_keys = preset_times.keys()

  preset_str = ' '

  foreach preset_time, preset_times, preset_key do begin
    if strlen(preset_str) gt 0 then sep = '|' else sep = ''

    preset_str = string(preset_key, format = '(A30)') + ': ' + strjoin(time_string(preset_time), '-') + sep + preset_str
  endforeach

  preset_desc = [ $
    '0, LIST,' + sep + preset_str + ', LABEL_TOP = Select a preset time from the drop down list below:, HEIGHT=40, TAG=preset_ind, QUIT']

  preset_select = cw_form(preset_desc, /column)

  return, preset_times[preset_keys[n_elements(preset_keys) - 1 - preset_select.preset_ind]]
end

function spp_fld_select_timespan, input_timespan = input_timespan, $
  update = update, $
  preset_times = preset_times, $
  fm_or_em = fm_or_em, $
  overall_preset_key = overall_preset_key, $
  sub_presets = sub_presets, $
  tlimit = tlimit, times_only = times_only
  compile_opt idl2

  if n_elements(fm_or_em) ne 1 then fm_or_em = 'FM'

  preset_times = spp_fld_select_timespan_define_presets(fm_or_em)

  if keyword_set(times_only) then return, [0d, 0d]

  if n_elements(overall_preset_key) eq 1 then begin
    sub_presets = orderedhash()

    if preset_times.hasKey(overall_preset_key) then begin
      ts = preset_times[overall_preset_key]

      foreach preset_time, preset_times, preset_key do begin
        if min(preset_time) ge min(ts) and max(preset_time) le max(ts) then begin
          sub_presets[preset_key] = preset_time
        end
      endforeach
    endif else begin
      print, 'No preset times matches input, timespan unchanged'

      return, -1
    endelse
  endif else begin
    @tplot_com.pro
    str_element, tplot_vars, 'options.trange_full', trange_full

    if n_elements(trange_full) eq 2 then ts = trange_full

    if n_elements(ts) lt 2 then ts_maxtest = [0d, 0d] else ts_maxtest = ts

    if n_elements(ts) lt 2 or max(ts_maxtest) eq 0. then begin
      ts = [systime(/sec) - 60., systime(/sec)]
    endif

    if n_elements(update) gt 0 then begin
      ts = [ts[0], systime(/sec)]
    endif else if n_elements(input_timespan) eq 2 then begin
      ts = time_double(input_timespan)

      select_timespan_desc = [ $
        '0, LABEL, Time range will be set to:, CENTER', $
        '0, LABEL, UTC Time (YYYY-MM-DD/hh:mm:ss)', $
        '0, LABEL, ' + time_string(ts[0]), $
        '0, LABEL, ' + time_string(ts[1]), $
        '2, BUTTON, Load intialized UTC time range, QUIT, TAG=UTC_OK']

      timespan_str = cw_form(select_timespan_desc, /column)
    endif else begin
      select_timespan_desc = [ $
        '0, LABEL, Select time range, CENTER', $
        '0, BUTTON, Past 10 minutes, QUIT, TAG=past10m', $
        '0, BUTTON, Past 30 minutes, QUIT, TAG=past30m', $
        '0, BUTTON, Past 1 hour, QUIT, TAG=past01h', $
        '0, BUTTON, Past 2 hours, QUIT, TAG=past02h', $
        '0, BUTTON, Past 4 hours, QUIT, TAG=past04h', $
        '0, BUTTON, Past 8 hours, QUIT, TAG=past08h', $
        '0, BUTTON, Past 12 hours, QUIT, TAG=past12h', $
        '0, BUTTON, Past 24 hours, QUIT, TAG=past24h', $
        '0, BUTTON, Past 48 hours, QUIT, TAG=past48h', $
        '0, BUTTON, Preset Time, QUIT, TAG=preset', $
        '0, LABEL, UTC Time (YYYY-MM-DD/hh:mm:ss)', $
        '0, TEXT, ' + time_string(ts[0]) + ', LABEL_LEFT=Start, WIDTH=19,TAG=start', $
        '0, TEXT, ' + time_string(ts[1]) + ', LABEL_LEFT=Stop_, WIDTH=19,TAG=stop', $
        '0, BUTTON, Use manual UTC time range, QUIT, TAG=UTC_OK', $
        '2, BUTTON, Cancel, QUIT, TAG=CANCEL']

      timespan_str = cw_form(select_timespan_desc, /column)

      if timespan_str.past10M then begin
        ts = systime(/sec) + [-60.d * 10., 0.d]
      endif else if timespan_str.past30M then begin
        ts = systime(/sec) + [-60.d * 30., 0.d]
      endif else if timespan_str.past30M then begin
        ts = systime(/sec) + [-60.d * 30., 0.d]
      endif else if timespan_str.past01H then begin
        ts = systime(/sec) + [-60.d * 60., 0.d]
      endif else if timespan_str.past02H then begin
        ts = systime(/sec) + [-60.d * 60. * 2., 0.d]
      endif else if timespan_str.past04H then begin
        ts = systime(/sec) + [-60.d * 60. * 4., 0.d]
      endif else if timespan_str.past08H then begin
        ts = systime(/sec) + [-60.d * 60. * 8., 0.d]
      endif else if timespan_str.past12H then begin
        ts = systime(/sec) + [-60.d * 60. * 12., 0.d]
      endif else if timespan_str.past24H then begin
        ts = systime(/sec) + [-60.d * 60. * 24., 0.d]
      endif else if timespan_str.past48H then begin
        ts = systime(/sec) + [-60.d * 60. * 48., 0.d]
      endif else if timespan_str.preset then begin
        if keyword_set(preset_times) then begin
          ts = spp_fld_select_timespan_preset(preset_times)
        endif else begin
          print, 'No preset times loaded, timespan unchanged'
        endelse
      endif else if timespan_str.utc_ok then begin
        ts = time_double([timespan_str.start, timespan_str.stop])
      endif else begin
        ts = ts
      endelse
    endelse
  endelse

  ; print, time_string(ts)

  if n_elements(ts) gt 0 and max(ts_maxtest) gt 0d then tlimit, ts else timespan, ts

  return, ts
end