pro psp_fld_options, type = type, level = level
  compile_opt idl2

  if n_elements(level) eq 0 then level = 2

  ; MARK: Color Table Definition

  psp_fld_sensor_colors = orderedhash()

  psp_fld_sensor_colors['V1'] = 72
  psp_fld_sensor_colors['V2'] = 120
  psp_fld_sensor_colors['V3'] = 104
  psp_fld_sensor_colors['V4'] = 88
  psp_fld_sensor_colors['V5'] = 0

  psp_fld_sensor_colors['V1LG'] = 72
  psp_fld_sensor_colors['V2LG'] = 120
  psp_fld_sensor_colors['V3LG'] = 104
  psp_fld_sensor_colors['V4LG'] = 88
  psp_fld_sensor_colors['V5LG'] = 0

  psp_fld_sensor_colors['V1V2'] = 24
  psp_fld_sensor_colors['V3V4'] = 40

  psp_fld_sensor_colors['V1234'] = 0

  psp_fld_sensor_colors['SCM4'] = 152
  psp_fld_sensor_colors['SCM5'] = 152

  psp_fld_sensor_colors['SCM4LG'] = 152

  psp_fld_sensor_color_table = 133

  ; MARK: Level 1 DCB Analog HK / F2 Digital HK

  if type eq 'dcb_analog_hk' or type eq 'f2_digital_hk' then begin
    if tnames('spp_fld_dcb_analog_hk_LNPS1_P100V') ne '' then begin
      options, 'spp_fld_dcb_analog_hk_LNPS1_?100V', 'colors', 24
      options, 'spp_fld_dcb_analog_hk_LNPS1_?100V', 'labels', 'LNPS1'
    endif

    if tnames('spp_fld_f2_digital_hk_lnps2_p100v') ne '' then begin
      options, 'spp_fld_f2_digital_hk_lnps2_?100v', 'colors', 40

      options, 'spp_fld_f2_digital_hk_lnps2_?100v', 'labels', 'LNPS2'
    endif

    if tnames('spp_fld_dcb_analog_hk_LNPS1_P100V') ne '' and $
      tnames('spp_fld_f2_digital_hk_lnps2_p100v') ne '' then begin
      store_data, 'spp_fld_lnps_p100V', $
        data = ['spp_fld_dcb_analog_hk_LNPS1_P100V', $
          'spp_fld_f2_digital_hk_lnps2_p100v']
      store_data, 'spp_fld_lnps_n100V', $
        data = ['spp_fld_dcb_analog_hk_LNPS1_N100V', $
          'spp_fld_f2_digital_hk_lnps2_n100v']

      options, 'spp_fld_lnps_p100V', 'ytitle', 'LNPS!CP100V'
      options, 'spp_fld_lnps_p100V', 'yrange', [80, 105]
      options, 'spp_fld_lnps_n100V', 'ytitle', 'LNPS!CN100V'
      options, 'spp_fld_lnps_n100V', 'yrange', [-105, -80]
      options, 'spp_fld_lnps_?100V', 'ystyle', 1
      options, 'spp_fld_lnps_?100V', 'datagap', 3600d
      options, 'spp_fld_lnps_?100V', 'color_table', psp_fld_sensor_color_table
    endif
  endif

  ; MARK: Level 1 F1 100bps

  if type eq 'f1_100bps' then begin
    foreach v, ['1', '2', '3', '4'] do begin
      options, 'spp_fld_f1_100bps_' + ['VOLT', 'MNMX_V'] + v, $
        'colors', [psp_fld_sensor_colors['V' + v]]
    endforeach

    options, 'spp_fld_f1_100bps_' + ['V_PEAK', 'V_MNMX'], $
      'color_table', psp_fld_sensor_color_table
  endif

  ; MARK: Level 2 F2 100BPS

  if type eq 'f2_100bps' and level eq 2 then begin
    dfb_vdc_labels0 = ['V1', 'V2', 'V3', 'V4', 'V5']

    get_data, 'PSP_FLD_L2_F2_100bps_DFB_VDC_V1', dat = dfb_vdc_v1, lim = lim_v1
    get_data, 'PSP_FLD_L2_F2_100bps_DFB_VDC_V2', dat = dfb_vdc_v2, lim = lim_v2
    get_data, 'PSP_FLD_L2_F2_100bps_DFB_VDC_V3', dat = dfb_vdc_v3, lim = lim_v3
    get_data, 'PSP_FLD_L2_F2_100bps_DFB_VDC_V4', dat = dfb_vdc_v4, lim = lim_v4

    dfb_vdc_v1234_y = [[dfb_vdc_v1.y], [dfb_vdc_v1.y], [dfb_vdc_v1.y], [dfb_vdc_v1.y]]

    dfb_vdc_v1234_median = median(dfb_vdc_v1234_y, dim = 2)

    store_data, 'PSP_FLD_L2_F2_100bps_DFB_VDC_V1_diff', $
      data = {x: dfb_vdc_v1.x, y: dfb_vdc_v1.y - dfb_vdc_v1234_median}, lim = lim_v1
    store_data, 'PSP_FLD_L2_F2_100bps_DFB_VDC_V2_diff', $
      data = {x: dfb_vdc_v2.x, y: dfb_vdc_v2.y - dfb_vdc_v1234_median}, lim = lim_v2
    store_data, 'PSP_FLD_L2_F2_100bps_DFB_VDC_V3_diff', $
      data = {x: dfb_vdc_v3.x, y: dfb_vdc_v3.y - dfb_vdc_v1234_median}, lim = lim_v3
    store_data, 'PSP_FLD_L2_F2_100bps_DFB_VDC_V4_diff', $
      data = {x: dfb_vdc_v4.x, y: dfb_vdc_v4.y - dfb_vdc_v1234_median}, lim = lim_v4

    ; stop

    dfb_vdc_tnames = []
    dfb_vdc_colors = []
    dfb_vdc_labels = []

    foreach dfb_vdc_label, dfb_vdc_labels0 do begin
      dfb_vdc_tname = tnames('PSP_FLD_L2_F2_100bps_DFB_VDC_' + dfb_vdc_label)

      if dfb_vdc_tname ne '' then begin
        dfb_vdc_tnames = [dfb_vdc_tnames, dfb_vdc_tname]
        dfb_vdc_colors = [dfb_vdc_colors, psp_fld_sensor_colors[dfb_vdc_label]]
        dfb_vdc_labels = [dfb_vdc_labels, dfb_vdc_label]
      endif
    endforeach

    if n_elements(dfb_vdc_tnames) gt 0 then begin
      store_data, 'PSP_FLD_L2_F2_100bps_DFB_VDC', data = dfb_vdc_tnames
      options, 'PSP_FLD_L2_F2_100bps_DFB_VDC', 'labels', dfb_vdc_labels
      options, 'PSP_FLD_L2_F2_100bps_DFB_VDC', 'labflag', 1
      options, 'PSP_FLD_L2_F2_100bps_DFB_VDC', 'colors', dfb_vdc_colors

      options, 'PSP_FLD_L2_F2_100bps_DFB_VDC', 'line_colors', 10

      options, 'PSP_FLD_L2_F2_100bps_DFB_VDC', 'color_table', psp_fld_sensor_color_table

      options, 'PSP_FLD_L2_F2_100bps_DFB_VDC', 'ytitle', 'F2_100BPS!CDFB WF VDC'
    endif
  endif

  ; MARK: Level 2 DFB WF VDC

  if type eq 'dfb_wf_vdc' and level eq 2 then begin
    dfb_vdc_labels0 = ['V1', 'V2', 'V3', 'V4', 'V5']

    dfb_vdc_tnames = []
    dfb_vdc_colors = []
    dfb_vdc_labels = []

    foreach dfb_vdc_label, dfb_vdc_labels0 do begin
      dfb_vdc_tname = tnames('psp_fld_l2_dfb_wf_' + dfb_vdc_label + 'dc')

      if dfb_vdc_tname ne '' then begin
        dfb_vdc_tnames = [dfb_vdc_tnames, dfb_vdc_tname]
        dfb_vdc_colors = [dfb_vdc_colors, psp_fld_sensor_colors[dfb_vdc_label]]
        dfb_vdc_labels = [dfb_vdc_labels, dfb_vdc_label]
      endif
    endforeach

    if n_elements(dfb_vdc_tnames) gt 0 then begin
      store_data, 'psp_fld_l2_dfb_wf_Vdc', data = dfb_vdc_tnames
      options, 'psp_fld_l2_dfb_wf_Vdc', 'labels', dfb_vdc_labels
      options, 'psp_fld_l2_dfb_wf_Vdc', 'labflag', 1
      options, 'psp_fld_l2_dfb_wf_Vdc', 'colors', dfb_vdc_colors

      options, 'psp_fld_l2_dfb_wf_Vdc', 'line_colors', 10

      options, 'psp_fld_l2_dfb_wf_Vdc', 'color_table', psp_fld_sensor_color_table

      options, 'psp_fld_l2_dfb_wf_Vdc', 'ytitle', 'DFB WF VDC'
    endif
  endif

  ; MARK: Level 2 TDS

  if type eq 'tds_wf' and level eq 2 then begin
    pre = 'PSP_FLD_L2_TDS_WF_Burst_'

    peak_mv_vars = tnames(pre + 'Peak_*_Engineering_mV')
    rms_mv_vars = tnames(pre + 'RMS_*_Engineering_mV')
    ; hz_vars = tnames('PSP_FLD_L2_TDS_WF_Burst_Frequency_Peak_*_Hz')

    var_groups = list()
    if peak_mv_vars[0] ne '' then var_groups.add, peak_mv_vars
    if rms_mv_vars[0] ne '' then var_groups.add, rms_mv_vars
    ; if hz_vars[0] ne '' then var_groups.add, hz_vars

    foreach vars, var_groups do begin
      vars_valid = intarr(n_elements(vars))

      foreach var, vars, var_i do begin
        get_data, var, data = d

        if finite(max(d.y, /nan)) then begin
          sensor = (var.split('_'))[7]
          var_type = (var.split('_'))[6]

          store_data, var + '_neg', data = {x: d.x, y: -d.y}

          options, var + ['', '_neg'], 'colors', psp_fld_sensor_colors[sensor]
          ; options, var, 'neg_colors', psp_fld_sensor_colors[sensor]
          options, var + [''], 'psym', 1
          options, var + ['_neg'], 'psym', 4
          ; options, var, 'psym', 1 ; symbols[ch_no]
          ; if symbols[ch_no] eq 1 then symsize = 0.5 else symsize = 0.35

          ; options, var, 'symsize', symsize

          ; options, var, 'thick', 1.5

          ; fmt_str = '(I' + string(ch_no + 1, format = '(I1)') + ')'
          ; fmt_str = '(I1)'

          options, var, 'labels', sensor
          options, var + '_neg', 'labels', ' '
          vars_valid[var_i] = 1
        endif else begin
          vars_valid[var_i] = 0
        endelse
      endforeach

      if total(vars_valid) gt 0 then begin
        nv = total(vars_valid)
        v_store = vars[where(vars_valid)]

        if var_type eq 'Peak' then begin
          v_store = [[v_store], [v_store + '_neg']]
          v_store = reform(transpose(v_store), nv * 2)
        endif

        store_data, pre + var_type + '_Engineering_mV', $
          data = v_store
        options, pre + var_type + '_Engineering_mV', 'ytitle', 'TDS ' + var_type
        options, pre + var_type + '_Engineering_mV', 'ysubtitle', '[mV]'
        options, pre + var_type + '_Engineering_mV', 'labflag', 1
        options, pre + var_type + '_Engineering_mV', 'ylog', 1
        options, pre + var_type + '_Engineering_mV', 'yrange', [0.1, 1e3]
        options, pre + var_type + '_Engineering_mV', 'color_table', $
          psp_fld_sensor_color_table
      endif

      ; if var.contains('Frequency') then begin
      ; store_data, 'SPP_FLD_L1_TDS_WF_Burst_Frequency_Peak_Hz', data = vars
      ; options, 'SPP_FLD_L1_TDS_WF_Burst_Frequency_Peak_Hz', 'ytitle', 'TDS Freq'
      ; options, 'SPP_FLD_L1_TDS_WF_Burst_Frequency_Peak_Hz', 'ysubtitle', '[Hz]'
      ; options, 'SPP_FLD_L1_TDS_WF_Burst_Frequency_Peak_Hz', 'labflag', 1

      ; options, 'SPP_FLD_L1_TDS_WF_Burst_Frequency_Peak_Hz', 'ylog', 1
      ; options, 'SPP_FLD_L1_TDS_WF_Burst_Frequency_Peak_Hz', 'yrange', [1d2, 1d6]
      ; options, 'SPP_FLD_L1_TDS_WF_Burst_Frequency_Peak_Hz', 'ystyle', 1
      ; endif
    endforeach

    ; options, 'PSP_FLD_L2_TDS_WF_Burst*', 'line_colors', 8

    options, pre + 'Total_SWEAP_Counting_Rate', 'psym', 1
    options, pre + 'Total_SWEAP_Counting_Rate', 'symsize', 0.5
    options, pre + 'Total_SWEAP_Counting_Rate', 'ytitle', 'SWEAP Rate'
  endif

  ; MARK: Level 2 AEB

  if type eq 'aeb' and level eq 2 then begin
    ; aeb_labels = ['V1', 'V2', 'V3', 'V4', 'V5']

    aeb_mvar_tnames = ['psp_fld_l2_aeb_WHIP_CURR', $
      'psp_fld_l2_aeb_WHIP_VOLT', $
      'psp_fld_l2_aeb_SHIELD_VOLT', $
      'psp_fld_l2_aeb_STUB_VOLT', $
      'psp_fld_l2_aeb_WHIP_CURR_DAC', $
      'psp_fld_l2_aeb_WHIP_VOLT_DAC', $
      'psp_fld_l2_aeb_SHIELD_VOLT_DAC', $
      'psp_fld_l2_aeb_STUB_VOLT_DAC', $
      'psp_fld_l2_aeb_TEMP', $
      'psp_fld_l2_aeb_RBIAS']

    foreach tname, aeb_mvar_tnames do begin
      yrange = []

      case tname of
        'psp_fld_l2_aeb_WHIP_CURR': begin
          mvar_names = [tnames('psp_fld_l2_aeb?_V?_WHIP_CURR')]
          ytitle = 'AEB!CWHIP!CCURR'
          aeb_labels = mvar_names.subString(16, 17)
        end
        'psp_fld_l2_aeb_WHIP_CURR_DAC': begin
          mvar_names = [tnames('psp_fld_l2_aeb?_V?_WHIP_CURR_DAC')]
          ytitle = 'AEB!CWHIP!CCURR!CDAC'
          aeb_labels = mvar_names.subString(16, 17)
        end
        'psp_fld_l2_aeb_WHIP_VOLT': begin
          mvar_names = [tnames('psp_fld_l2_aeb?_V?_WHIP_VOLT')]
          ytitle = 'AEB!CWHIP!CVOLT'
          aeb_labels = mvar_names.subString(16, 17)
        end
        'psp_fld_l2_aeb_SHIELD_VOLT': begin
          mvar_names = [tnames('psp_fld_l2_aeb?_V?_SHIELD_VOLT')]
          ytitle = 'AEB!CSHIELD!CVOLT'
          aeb_labels = mvar_names.subString(16, 17)
        end
        'psp_fld_l2_aeb_STUB_VOLT': begin
          mvar_names = [tnames('psp_fld_l2_aeb?_V?_STUB_VOLT')]
          ytitle = 'AEB!CSTUB!CVOLT'
          aeb_labels = mvar_names.subString(16, 17)
        end
        'psp_fld_l2_aeb_WHIP_VOLT_DAC': begin
          mvar_names = [tnames('psp_fld_l2_aeb?_V?_WHIP_VOLT_DAC')]
          ytitle = 'AEB!CWHIP!CVOLT!CDAC'
          aeb_labels = mvar_names.subString(16, 17)
        end
        'psp_fld_l2_aeb_SHIELD_VOLT_DAC': begin
          mvar_names = [tnames('psp_fld_l2_aeb?_V?_SHIELD_VOLT_DAC')]
          ytitle = 'AEB!CSHIELD!CVOLT!CDAC'
          aeb_labels = mvar_names.subString(16, 17)
        end
        'psp_fld_l2_aeb_STUB_VOLT_DAC': begin
          mvar_names = [tnames('psp_fld_l2_aeb?_V?_STUB_VOLT_DAC')]
          ytitle = 'AEB!CSTUB!CVOLT!CDAC'
          aeb_labels = mvar_names.subString(16, 17)
        end
        'psp_fld_l2_aeb_TEMP': begin
          mvar_names = [tnames('psp_fld_l2_aeb?_PA?_TEMP')]
          ytitle = 'AEB!CPA!CTEMP'
          aeb_labels = 'V' + mvar_names.subString(18, 18)
        end
        'psp_fld_l2_aeb_RBIAS': begin
          mvar_names = [tnames('psp_fld_l2_aeb?_V?_RBIAS')]
          ytitle = 'AEB!CRBIAS'
          aeb_labels = mvar_names.subString(16, 17)
          yrange = [-0.25, 2.25]
        end
        else: mvar_names = []
      endcase

      if n_elements(mvar_names) gt 0 then begin
        store_data, tname, data = mvar_names

        options, tname, 'labels', aeb_labels

        options, tname, 'labflag', 1
        options, tname, 'colors', $
          (psp_fld_sensor_colors[aeb_labels].values()).toArray()
        options, tname, 'line_colors', 9

        ; options, 'psp_fld_l2_aeb_WHIP_CURR', 'yrange', [-1, 0.25]
        if n_elements(yrange) eq 2 then options, tname, 'yrange', yrange
        options, tname, 'ystyle', 1

        options, tname, 'ytitle', ytitle
        options, tname, 'color_table', psp_fld_sensor_color_table
      endif
    endforeach
  endif
end
