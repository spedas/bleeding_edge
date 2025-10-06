pro spp_fld_f2_digital_hk_load_l1, file, prefix = prefix, varformat = varformat
  compile_opt idl2

  ; if not keyword_set(prefix) then prefix = 'spp_fld_f2_100bps_'
  if not keyword_set(prefix) then prefix = 'spp_fld_f2_digital_hk_'

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat
end
