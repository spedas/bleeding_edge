pro spp_fld_dfb_sc_potential_load_l1, file, prefix = prefix

  if not keyword_set(prefix) then prefix = 'spp_fld_dfb_sc_potential_'

  cdf2tplot, /get_support_data, file, prefix = prefix

  dfb_sc_potential_names = tnames(prefix + '*')

  if dfb_sc_potential_names[0] NE '' then begin

    for i = 0, n_elements(dfb_sc_potential_names)-1 do begin

      name = dfb_sc_potential_names[i]

      title = name.Remove(0, prefix.Strlen()-1)

      title = title.Replace('_v', '')

      options, name, 'ynozero', 1
      options, name, 'ytitle', 'DFB!CSCPOT!C' + title

      options, name, 'max_points', 40000l
      options, name, 'psym_lim', 200

    endfor

  endif

end