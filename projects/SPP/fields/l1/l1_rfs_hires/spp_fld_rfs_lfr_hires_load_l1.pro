pro spp_fld_rfs_lfr_hires_load_l1, file, prefix = prefix

  if not keyword_set(prefix) then prefix = 'spp_fld_rfs_lfr_hires_'
  spp_fld_rfs_hires_load_l1, file, prefix = prefix, color = 6

end