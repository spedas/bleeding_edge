pro psp_fld_options, type = type, level = level
  compile_opt idl2

  if n_elements(level) eq 0 then level = 2

  ; MARK: Color Table Definition

  psp_fld_sensor_colors = orderedhash()

  matplotlib_indices = [25 * indgen(12) + 8]

  psp_fld_sensor_colors['V1'] = matplotlib_indices[1]
  psp_fld_sensor_colors['V2'] = matplotlib_indices[2]
  psp_fld_sensor_colors['V3'] = matplotlib_indices[4]
  psp_fld_sensor_colors['V4'] = matplotlib_indices[6]
  psp_fld_sensor_colors['V5'] = matplotlib_indices[5]

  psp_fld_sensor_colors['V1LG'] = matplotlib_indices[1]
  psp_fld_sensor_colors['V2LG'] = matplotlib_indices[2]
  psp_fld_sensor_colors['V3LG'] = matplotlib_indices[4]
  psp_fld_sensor_colors['V4LG'] = matplotlib_indices[6]
  psp_fld_sensor_colors['V5LG'] = matplotlib_indices[5]

  psp_fld_sensor_colors['V1V2'] = matplotlib_indices[0]
  psp_fld_sensor_colors['V3V4'] = matplotlib_indices[3]

  psp_fld_sensor_colors['V1234'] = 0

  psp_fld_sensor_colors['SCM4'] = matplotlib_indices[6]
  psp_fld_sensor_colors['SCM5'] = matplotlib_indices[8]

  psp_fld_sensor_colors['SCM4LG'] = matplotlib_indices[6]

  psp_fld_sensor_color_table = 134

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
    store_data, 'psp_fld_l2_aeb_WHIP_CURR', $
      data = [tnames('psp_fld_l2_aeb?_V?_WHIP_CURR'), $
        'psp_fld_l2_aeb1_V5_SENSOR_CURR']

    aeb_labels = ['V1', 'V2', 'V3', 'V4', 'V5']

    options, 'psp_fld_l2_aeb_WHIP_CURR', 'labels', aeb_labels

    options, 'psp_fld_l2_aeb_WHIP_CURR', 'labflag', 1
    options, 'psp_fld_l2_aeb_WHIP_CURR', 'colors', $
      (psp_fld_sensor_colors[aeb_labels].values()).toArray()
    options, 'psp_fld_l2_aeb_WHIP_CURR', 'line_colors', 9

    ; options, 'psp_fld_l2_aeb_WHIP_CURR', 'yrange', [-1, 0.25]
    options, 'psp_fld_l2_aeb_WHIP_CURR', 'ystyle', 1

    options, 'psp_fld_l2_aeb_WHIP_CURR', 'ytitle', 'AEB BIAS'
    options, 'psp_fld_l2_aeb_WHIP_CURR', 'color_table', psp_fld_sensor_color_table
  endif
end
