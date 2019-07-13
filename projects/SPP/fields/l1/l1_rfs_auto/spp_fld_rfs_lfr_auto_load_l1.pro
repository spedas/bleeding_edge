pro spp_fld_rfs_lfr_auto_load_l1, file, prefix = prefix, varformat = varformat

  if not keyword_set(prefix) then prefix = 'spp_fld_rfs_lfr_auto_'
  spp_fld_rfs_auto_load_l1, file, prefix = prefix, color = 6, varformat = varformat

end