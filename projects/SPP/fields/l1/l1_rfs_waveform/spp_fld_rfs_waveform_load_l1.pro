pro spp_fld_rfs_waveform_load_l1, file, prefix = prefix, varformat = varformat

  if not keyword_set(prefix) then prefix = 'spp_fld_rfs_waveform_'

  if typename(file) EQ 'UNDEFINED' then begin

    dprint, 'No file provided to spp_fld_rfs_rawspectra_load_l1', dlevel = 2

    return

  endif

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

end