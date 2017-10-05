pro spp_fld_dfb_xspec_load_l1, file, prefix = prefix

  ; TODO: More X-spectra testing and formatting

  cdf2tplot, file, prefix = prefix, varnames = varnames

  options, prefix + '*string', 'tplot_routine', 'strplot'
  options, prefix + '*string', 'yrange', [-0.1,1.0]
  options, prefix + '*string', 'ystyle', 1
  options, prefix + '*string', 'yticks', 1
  options, prefix + '*string', 'ytickformat', '(A1)'
  options, prefix + '*string', 'noclip', 0

end