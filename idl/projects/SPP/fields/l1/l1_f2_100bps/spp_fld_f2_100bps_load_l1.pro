pro spp_fld_f2_100bps_load_l1, file, prefix = prefix, varformat = varformat

  ;if not keyword_set(prefix) then prefix = 'spp_fld_f2_100bps_'
  prefix = ''

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

end