pro spp_fld_sc_hk_temp_load_l1, file, prefix = prefix, varformat = varformat

  if not keyword_set(prefix) then prefix = 'spp_fld_sc_hk_temp_'

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  sc_hk_temp_names = tnames(prefix + '*')

  if sc_hk_temp_names[0] NE '' then begin

    for i = 0, n_elements(sc_hk_temp_names) - 1 do begin

      name = sc_hk_temp_names[i]
      ytitle = name

      ytitle = ytitle.Remove(0, prefix.Strlen()-1)

      ytitle = ytitle.Replace('_','!C')

      options, name, 'ynozero', 1
      options, name, 'colors', [2]
      options, name, 'ytitle', ytitle
      options, name, 'psym_lim', 400
      options, name, 'symsize', 0.5
      options, name, 'datagap', 3600d

    endfor

  endif

  colors = [6,4,2,1]

  for i = 1, 4 do begin

    i_str = string(i, format = '(I1)')

    name = 'spp_fld_sc_hk_temp_FIELDS_PLASMA_WAVE_PRE_AMP_' + i_str + '_TEMP'

    options, name, 'ytitle', 'SC PA' + i_str + '!CTEMP'

    options, name, 'colors', [colors[i-1]]

    labels = i_str

    for j = 1, i do labels = '  ' + labels

    options, name, 'labels', labels

  endfor

end