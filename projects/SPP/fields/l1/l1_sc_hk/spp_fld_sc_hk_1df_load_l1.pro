pro spp_fld_sc_hk_1df_load_l1, file, prefix = prefix, varformat = varformat

  if not keyword_set(prefix) then prefix = 'spp_fld_sc_hk_1df_'

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  sc_hk_1df_names = tnames(prefix + '*')

  if sc_hk_1df_names[0] NE '' then begin

    for i = 0, n_elements(sc_hk_1df_names) - 1 do begin

      name = sc_hk_1df_names[i]

      ytitle = name

      ytitle = ytitle.Remove(0, prefix.Strlen()-1)

      ytitle = ytitle.Replace('_','!C')

      options, name, 'ynozero', 1
      options, name, 'colors', [2]
      options, name, 'ytitle', ytitle

      options, name, 'psym_lim', 200
      options, name, 'symsize', 0.5

    endfor

  endif

  get_data, prefix + 'sc_hk_subseconds', data = d_hk_ss

end