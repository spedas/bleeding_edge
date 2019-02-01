pro spp_fld_dfb_dbm_load_l1, file, prefix = prefix

  cdf2tplot, /get_support_data, file, prefix = prefix

  options, prefix + 'compression', 'yrange', [-0.5, 1.5]
  options, prefix + 'compression', 'psym', 4
  options, prefix + 'compression', 'symsize', 0.5

  options, prefix + 'acdc', 'yrange', [-0.5, 1.5]
  options, prefix + 'acdc', 'psym', 4
  options, prefix + 'acdc', 'symsize', 0.5

  options, prefix + 'ftap', 'yrange', [-0.5, 6.5]
  options, prefix + 'ftap', 'psym', 4
  options, prefix + 'ftap', 'symsize', 0.5

  options, prefix + 'src_sel', 'yrange', [-0.5, 15.5]
  options, prefix + 'src_sel', 'psym', 4
  options, prefix + 'src_sel', 'symsize', 0.5

end