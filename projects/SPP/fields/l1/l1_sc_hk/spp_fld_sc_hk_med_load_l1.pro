pro spp_fld_sc_hk_med_load_l1, file, prefix = prefix, varformat = varformat

  if not keyword_set(prefix) then prefix = 'spp_fld_sc_hk_med_'

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  sc_hk_med_names = tnames(prefix + '*')

  if sc_hk_med_names[0] NE '' then begin

    for i = 0, n_elements(sc_hk_med_names) - 1 do begin

      name = sc_hk_med_names[i]
      ytitle = name

      ytitle = ytitle.Remove(0, prefix.Strlen()-1)

      ytitle = ytitle.Replace('_','!C')

      options, name, 'ynozero', 1
      options, name, 'colors', [2]
      options, name, 'ytitle', ytitle
      ;options, name, 'psym', 4
      options, name, 'psym_lim', 200
      options, name, 'symsize', 0.75
      options, name, 'datagap', 1200d

    endfor

  endif

  store_data, prefix + 'F_CURR', data = tnames(prefix + 'F?_CURR')

  options, prefix + 'F1_CURR', 'labels', '1'
  options, prefix + 'F2_CURR', 'labels', '  2'

  options, prefix + 'F1_CURR', 'colors', [2] ; blue
  options, prefix + 'F2_CURR', 'colors', [6] ; red

  options, prefix + 'F_CURR', 'yrange', [0,0.5]
  options, prefix + 'F_CURR', 'ytitle', 'F_CURR'
  options, prefix + 'F_CURR', 'colors'  ; multi-item should not have colors
                                         ; or they will override


  store_data, prefix + 'F_PRE_SRV_HTR_CURR', $
    data = tnames(prefix + 'F?_PRE_SRV_HTR_CURR')

  options, prefix + 'F1_PRE_SRV_HTR_CURR', 'labels', '1'
  options, prefix + 'F2_PRE_SRV_HTR_CURR', 'labels', '  2'

  options, prefix + 'F1_PRE_SRV_HTR_CURR', 'colors', [2] ; blue
  options, prefix + 'F2_PRE_SRV_HTR_CURR', 'colors', [6] ; red

  ;options, prefix + 'F_PRE_SRV_HTR_CURR', 'yrange', [0,0.5]
  options, prefix + 'F_PRE_SRV_HTR_CURR', 'ytitle', 'PRE_SRV!CHTR_CURR'
  options, prefix + 'F_PRE_SRV_HTR_CURR', 'colors'


  store_data, prefix + 'F_MAG_SRV_HTR_CURR', $
    data = tnames(prefix + 'F?_MAG_SRV_HTR_CURR')

  options, prefix + 'F1_MAG_SRV_HTR_CURR', 'labels', '1'
  options, prefix + 'F2_MAG_SRV_HTR_CURR', 'labels', '  2'

  options, prefix + 'F1_MAG_SRV_HTR_CURR', 'colors', [2] ; blue
  options, prefix + 'F2_MAG_SRV_HTR_CURR', 'colors', [6] ; red

  options, prefix + 'F_MAG_SRV_HTR_CURR', 'ytitle', 'MAG_SRV!CHTR_CURR'
  options, prefix + 'F_MAG_SRV_HTR_CURR', 'colors'

  ; If this routine was called in the standard SPEDAS method of setting
  ; a timespan and using spp_fld_load, then create a variable 'on indicator'
  ; showing FIELDS1 and FIELDS2 status during the specified timespan.

  @tplot_com.pro
  str_element,tplot_vars,'options.trange_full',trange_full
  if n_elements(trange_full) EQ 2 then begin

    get_timespan, ts

    t = double(time_intervals(trange=ts, /minute))

    f1_ts = tsample('spp_fld_sc_hk_med_F1_CURR', ts, times = f1_t)

    if n_elements(f1_t) GT 10 then begin

      ; Fill with NaNs during data gaps (these fill in when we have full
      ; Ka downlink, but are initially sparse when we only have X band contacts)
      ; The gap_dist parameter in the data_cut routine is based on a constant
      ; delta t, the next few lines adjust the gap parameter to make it work when
      ; data is not constant.

      dt_mean = (f1_t[-1] - f1_t[0]) / n_elements(f1_t)

      dt_median = median(f1_t[1:-1] - f1_t[0:-2])

      gap_dist = (dt_median / dt_mean * 15) > 15
      
      ; the > 15 catches some odd cases like on 2021-05-15, when cadence
      ; is irregular

      f1 = data_cut('spp_fld_sc_hk_med_F1_CURR', t, gap_dist = gap_dist, interp_gap = 1)

      f2 = data_cut('spp_fld_sc_hk_med_F2_CURR', t, gap_dist = gap_dist, interp_gap = 1)

      f1_scaled = (f1 GT 0.3) * (f1 / f1) ; last bit is just so NaN -> NaN

      f2_scaled = (f2 GT 0.1) * (f2 / f2)

      store_data, prefix + 'fields_on_indicator', $
        data = {x:t, y:[[f1_scaled], [f2_scaled]]}

      options, prefix + 'fields_on_indicator', 'spec', 1
      options, prefix + 'fields_on_indicator', 'no_interp', 2
      options, prefix + 'fields_on_indicator', 'color_table', 4
      options, prefix + 'fields_on_indicator', 'reverse_color_table', 1

      ;options, prefix + 'fields_on_indicator', 'no_color_scale', 1
      options, prefix + 'fields_on_indicator', 'yrange', [0,1]
      options, prefix + 'fields_on_indicator', 'zrange', [0.,1.]
      options, prefix + 'fields_on_indicator', 'yticklen', 1
      options, prefix + 'fields_on_indicator', 'ygridstyle', 1
      options, prefix + 'fields_on_indicator', 'yticks', 1
      options, prefix + 'fields_on_indicator', 'yminor', 1
      options, prefix + 'fields_on_indicator', 'panel_size', 0.25
      options, prefix + 'fields_on_indicator', 'top', 255 - 112
      options, prefix + 'fields_on_indicator', 'bottom', 255 - 144

      options, prefix + 'fields_on_indicator', 'ytitle', 'FLD!CON'

      if file_basename(getenv('IDL_CT_FILE')) EQ 'spp_fld_colors.tbl' then $
        set_colors = 1 else set_colors = 0

      if set_colors then begin

        options, prefix + 'fields_on_indicator', 'no_color_scale', 0
        options, prefix + 'fields_on_indicator', 'color_table', 131
        options, prefix + 'fields_on_indicator', 'top'
        options, prefix + 'fields_on_indicator', 'bottom'

        options, prefix + 'fields_on_indicator', 'zticks', 1
        options, prefix + 'fields_on_indicator', 'ztickv', [0.25, 0.75]
        options, prefix + 'fields_on_indicator', 'ztickname', ['OFF','ON']


      endif

      y_vals = ['1 ', ' 2']

      n_y = n_elements(y_vals)

      yticks = n_elements(y_vals)+1
      ytickname = [' ', y_vals, ' ']
      yticknamelen = fltarr(n_elements(ytickname))
      ytickv = [0., (0.5+findgen(n_y))/n_y, 1.]

      options, prefix + 'fields_on_indicator', 'yticks', yticks
      options, prefix + 'fields_on_indicator', 'ytickname', ytickname
      options, prefix + 'fields_on_indicator', 'ytickv', ytickv

    endif
  endif

end