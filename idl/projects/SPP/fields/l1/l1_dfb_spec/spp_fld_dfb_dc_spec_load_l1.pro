pro spp_fld_dfb_dc_spec_load_l1, file, prefix = prefix, varformat = varformat

  if not keyword_set(prefix) then return

  if typename(file) EQ 'UNDEFINED' then begin

    dprint, 'No file provided to spp_fld_dfb_dc_spec_load_l1', dlevel = 2

    return

  endif

  spp_fld_dfb_spec_load_l1, file, prefix = prefix, varformat = varformat

end