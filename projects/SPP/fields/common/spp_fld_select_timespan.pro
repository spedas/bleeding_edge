function spp_fld_select_timespan_define_presets, fm_or_em

  fm_times = orderedhash()
  fm_times['TB_bus_bar_fail'] =                 ['2024-12-19/16:15:00', '2024-12-19/17:15:00']
  fm_times['TC_egse_checkout_MAG'] =            ['2018-02-17/00:43:00', '2018-02-17/00:58:00']
  fm_times['TC_egse_checkout_RFS'] =            ['2018-02-17/01:00:00', '2018-02-17/01:20:00']
  fm_times['TC_mag_scm_intercal'] =             ['2020-04-24/13:40:00', '2020-04-24/15:00:00']
  fm_times['TC_mag_scm_intercal_dfb_gaps'] =    ['2020-04-24/13:58:13', '2020-04-24/14:00:16']
  fm_times['TC_encounter_OITL'] =     ['2020-05-27/20:00:00', '2020-05-28/04:00:00']
  fm_times['TC_enc_DFB_XSPEC_test'] = ['2020-05-28/00:50:00', '2020-05-28/01:20:00']
  fm_times['TC_enc_OITL_magpkt'] =    ['2020-05-28/01:14:00', '2020-05-28/01:16:00']
  fm_times['TC_COLD_CPT_MAG'] =       ['2020-07-17/17:30:00', '2020-07-17/19:00:00']
  fm_times['TC_COLD_CPT_DFB'] =       ['2020-07-17/19:30:00', '2020-07-17/21:00:00']
  fm_times['TC_HOT_CPT_MAG'] =        ['2020-07-20/00:30:00', '2020-07-20/01:30:00']
  fm_times['TC_HOT_CPT_DFB'] =        ['2020-07-19/23:40:00', '2020-07-20/01:00:00']
  fm_times['TC_HOT_CPT_RFS'] =        ['2020-07-20/02:10:00', '2020-07-20/02:20:00']
  fm_times['MAG_SNSRTMP_sinusoid'] =  ['2018-03-18/21:00:00', '2018-03-18/23:00:00']
  fm_times['V1_diagnostic'] =         ['2018-03-18/16:00:00', '2018-03-18/23:00:00']
  fm_times['post_ship_functional'] =  ['2018-04-09/13:30:00', '2018-04-09/17:00:00']
  fm_times['post_ship_functional_DFB_pre'] =  ['2018-04-09/13:30:00', '2018-04-09/14:30:00']
  fm_times['post_ship_CAL_RFS'] =     ['2018-04-16/18:00:00', '2018-04-16/23:00:00']
  fm_times['post_ship_CPT_MAG'] =     ['2018-04-17/19:30:00', '2018-04-17/21:15:00']
  fm_times['post_ship_CPT_DFB'] =     ['2018-04-17/21:10:00', '2018-04-17/22:00:00']
  fm_times['post_ship_CPT_RFS_check_fails'] =     ['2018-04-17/22:30:00', '2018-04-17/23:00:00']
  fm_times['SCM_xtalk_BY_part1'] =    ['2018-04-17/23:30:00', '2018-04-18/00:30:00']
  fm_times['SCM_xtalk_BY_part2'] =    ['2018-04-18/13:00:00', '2018-04-18/14:45:00']
  fm_times['SCM_xtalk_BZ'] =          ['2018-04-18/15:00:00', '2018-04-18/16:00:00']
  fm_times['magboom_fluxcannon'] =    ['2018-05-23/23:50:00', '2018-05-24/00:10:00']
  fm_times['v5_newscrews_Jun05'] =    ['2018-06-04/22:40:00', '2018-06-06/00:20:00']
  fm_times['groundtest_Jun12_OK'] =    ['2018-06-11/22:30:00', '2018-06-12/02:00:00']
  fm_times['aliveness_Jun19_OK'] =    ['2018-06-19/15:20:00', '2018-06-19/16:40:00']
  fm_times['aliveness_V3_anomaly'] =  ['2018-08-01/05:00:00', '2018-08-01/07:30:00']
  fm_times['turn_on_look_at_V3'] =    ['2018-08-04/15:30:00', '2018-08-04/21:30:00']

  fm_times['commissioning_day2'] =            ['2018-08-13/11:00:00', '2018-08-13/18:00:00']
  fm_times['com_d2_boom_frang_tall'] =        ['2018-08-13/11:46:00', '2018-08-13/11:51:00']
  fm_times['com_d2_boom_frang_tall_redun'] =  ['2018-08-13/13:05:00', '2018-08-13/13:10:00']
  fm_times['com_d2_hga_frang'] =              ['2018-08-13/15:05:00', '2018-08-13/15:10:00']
  fm_times['com_d2_rfs_2fullspec_pre_clam'] = ['2018-08-13/15:25:00', '2018-08-13/15:29:00']
  fm_times['com_d2_clamshell_v3v4'] =         ['2018-08-13/15:33:00', '2018-08-13/15:48:00']
  fm_times['com_d2_clamshell_v1v2'] =         ['2018-08-13/15:48:00', '2018-08-13/15:53:00']
  fm_times['com_d2_rfs_5fullspec_pre_boom'] = ['2018-08-13/16:10:00', '2018-08-13/16:35:00']
  fm_times['com_d2_hga_frang_redun'] =        ['2018-08-13/16:43:30', '2018-08-13/16:47:30']
  fm_times['com_d2_thrust_momdump'] =         ['2018-08-13/17:05:00', '2018-08-13/17:15:00']
  fm_times['com_d2_magboom'] =                ['2018-08-13/17:15:00', '2018-08-13/17:25:00']
  fm_times['com_d2_magboom_zoom'] =           ['2018-08-13/17:18:30', '2018-08-13/17:19:30']

  fm_times['commissioning_day3'] =            ['2018-08-14/15:00:00', '2018-08-14/17:10:00']
  fm_times['com_d3_biasing_1'] =              ['2018-08-14/15:30:00', '2018-08-14/15:50:00']
  fm_times['com_d3_scm_cal'] =                ['2018-08-14/15:48:00', '2018-08-14/15:49:00']
  fm_times['com_d3_biasing_2'] =              ['2018-08-14/16:05:00', '2018-08-14/16:20:00']
  fm_times['com_d3_rfs_2fullspec_scm'] =      ['2018-08-14/16:00:00', '2018-08-14/16:15:00']
  fm_times['com_d3_mag_zero'] =               ['2018-08-14/16:20:00', '2018-08-14/16:50:00']

  fm_times['commissioning_day4'] =            ['2018-08-15/15:00:00', '2018-08-15/21:00:00']
  fm_times['com_d4_mom_dump'] =               ['2018-08-15/16:40:00', '2018-08-15/16:41:00']
  fm_times['com_d4_commanded_dump'] =         ['2018-08-15/19:36:45', '2018-08-15/19:37:45']

  fm_times['commissioning_day5'] =            ['2018-08-16/19:50:00', '2018-08-16/22:30:00']


  em_times = orderedhash()

  em_times['EM_test_RFS_v29'] = ['2018-02-22/19:30:00','2018-02-22/21:30:00']
  em_times['EM_test_CPT_DFB'] = ['2018-03-04/23:55:00','2018-03-05/00:22:00']
  em_times['EM_test_MAG_DFB'] = ['2018-03-04/19:25:00','2018-03-04/19:35:00']
  em_times['EM_test_DFB_rotation'] = ['2018-03-22/20:00:00','2018-03-23/01:00:00']
  em_times['EM_test_DFB_rotation_zoom'] = ['2018-03-22/23:05:00','2018-03-22/23:15:00']

  em_times['EM_test_RFS_cal_v1'] = ['2018-04-12/23:30:00','2018-04-13/01:30:00']
  em_times['EM_test_RFS_cal_v2'] = ['2018-04-13/22:30:00','2018-04-13/01:00:00']

  em_times['EM_test_DFB_CBS_for_SCM_CAL'] = ['2018-07-26/18:00:00','2018-07-26/22:30:00']

  em_times['EM_test_1GOhm_Biasing'] = ['2018-08-03/18:00:00','2018-08-03/21:30:00']
  em_times['EM_test_1GOhm_Biasing_zoom'] = ['2018-08-03/20:22:00','2018-08-03/20:36:00']

  em_times['EM_test_1GOhm_Biasing_V1234'] = ['2018-08-07/01:40:00','2018-08-07/01:45:00']

  em_times['EM_test_RFS_5fullspec'] = ['2018-08-06/18:00:00','2018-08-06/18:45:00']


  em_times['EM_test_command_v5_256'] = ['2018-08-16/22:30:00','2018-08-16/23:00:00']


  if fm_or_em EQ 'FM' then return, fm_times else return, em_times

end


function spp_fld_select_timespan_preset, preset_times

  preset_keys = preset_times.Keys()

  preset_str = ''

  foreach preset_time, preset_times, preset_key do begin

    if strlen(preset_str) GT 0 then sep = '|' else sep = ''

    preset_str += sep + string(preset_key,format = '(A30)') + ': ' + strjoin(time_string(preset_time),'-')

  endforeach

  preset_desc = [ $
    '0, DROPLIST,' + preset_str + ', LABEL_TOP = Select a preset time from the drop down list below:, TAG=preset_ind, QUIT']

  preset_select = cw_form(preset_desc,/column)

  return, preset_times[preset_keys[preset_select.preset_ind]]

end

function spp_fld_select_timespan, input_timespan = input_timespan, $
  update = update, preset_times = preset_times, fm_or_em = fm_or_em
  
  if n_elements(fm_or_em) NE 1 then fm_or_em = 'FM'
  
  preset_times = spp_fld_select_timespan_define_presets(fm_or_em)

  @tplot_com.pro
  str_element,tplot_vars,'options.trange_full',trange_full

  if n_elements(trange_full) eq 2 then ts = trange_full

  if n_elements(ts) LT 2 or max(ts) EQ 0. then begin

    ts = [systime(/sec)-60., systime(/sec)]

  endif

  if n_elements(update) GT 0 then begin

    ts = [ts[0], systime(/sec)]

  endif else if n_elements(input_timespan) EQ 2 then begin

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

    if timespan_str.past10m then begin
      ts = systime(/sec) + [-60.d*10., 0.d]
    endif else if timespan_str.past30m then begin
      ts = systime(/sec) + [-60.d*30., 0.d]
    endif else if timespan_str.past30m then begin
      ts = systime(/sec) + [-60.d*30., 0.d]
    endif else if timespan_str.past01h then begin
      ts = systime(/sec) + [-60.d*60., 0.d]
    endif else if timespan_str.past02h then begin
      ts = systime(/sec) + [-60.d*60.*2., 0.d]
    endif else if timespan_str.past04h then begin
      ts = systime(/sec) + [-60.d*60.*4., 0.d]
    endif else if timespan_str.past08h then begin
      ts = systime(/sec) + [-60.d*60.*8., 0.d]
    endif else if timespan_str.past12h then begin
      ts = systime(/sec) + [-60.d*60.*12., 0.d]
    endif else if timespan_str.past24h then begin
      ts = systime(/sec) + [-60.d*60.*24., 0.d]
    endif else if timespan_str.past48h then begin
      ts = systime(/sec) + [-60.d*60.*48., 0.d]
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

  ;print, time_string(ts)

  timespan, ts

  return, ts

end