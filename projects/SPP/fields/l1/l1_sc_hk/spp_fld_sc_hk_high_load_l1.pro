pro spp_fld_sc_hk_high_load_l1, file, prefix = prefix, varformat = varformat

  if not keyword_set(prefix) then prefix = 'spp_fld_sc_hk_high_'

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  sc_hk_high_names = tnames(prefix + '*')

  if sc_hk_high_names[0] NE '' then begin

    for i = 0, n_elements(sc_hk_high_names) - 1 do begin

      name = sc_hk_high_names[i]

      ytitle = name

      ytitle = ytitle.Remove(0, prefix.Strlen()-1)

      ytitle = ytitle.Replace('_','!C')

      options, name, 'ynozero', 1
      options, name, 'colors', [2]
      options, name, 'ytitle', ytitle

      options, name, 'psym_lim', 200
      options, name, 'symsize', 0.75
      
      options, name, 'datagap', 1200d

    endfor

  endif

  options, prefix + 'WHLSPD0', 'colors', 6 ; red
  options, prefix + 'WHLSPD1', 'colors', 4 ; green
  options, prefix + 'WHLSPD2', 'colors', 2 ; blue
  options, prefix + 'WHLSPD3', 'colors', 1 ; magenta

  options, prefix + 'WHLSPD0', 'labels', '0'
  options, prefix + 'WHLSPD1', 'labels', '  1'
  options, prefix + 'WHLSPD2', 'labels', '    2'
  options, prefix + 'WHLSPD3', 'labels', '      3'

  store_data, prefix + 'WHLSPD', data = tnames(prefix + 'WHLSPD?')

  options, prefix + 'WHLSPD', 'ytitle', 'SC_HK_HI!CWHLSPD'
  options, prefix + 'WHLSPD', 'ysubtitle', '[Rad/sec]'
  options, prefix + 'WHLSPD', 'panel_size', 2
  options, prefix + 'WHLSPD', 'colors'

  store_data, prefix + 'BUS_VOLT', data = tnames(prefix + 'BUS_?_VOLT')

  options, prefix + 'BUS_A_VOLT', 'labels', 'A'
  options, prefix + 'BUS_B_VOLT', 'labels', '  B'

  options, prefix + 'BUS_A_VOLT', 'colors', 2 ; blue
  options, prefix + 'BUS_B_VOLT', 'colors', 6 ; red

  options, prefix + 'BUS_VOLT', 'ytitle', 'BUS_VOLT'


end