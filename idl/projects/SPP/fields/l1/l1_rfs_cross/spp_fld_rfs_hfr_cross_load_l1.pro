pro spp_fld_rfs_hfr_cross_load_l1, file, prefix = prefix, varformat = varformat

  if not keyword_set(prefix) then prefix = 'spp_fld_rfs_hfr_cross_'
  spp_fld_rfs_cross_load_l1, file, prefix = prefix, color = 2, varformat = varformat

end