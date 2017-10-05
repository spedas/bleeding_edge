function spp_fld_tmlib_item_fillval, item_hash

  ; TODO: Data types other than float

  if item_hash.HasKey('cdf_att') then begin

    cdf_att = item_hash['cdf_att']

    if cdf_att.HasKey('FILLVAL') then begin

      fillval = float(cdf_att['FILLVAL'])

    endif else begin

      fillval = -1.0e30

    endelse

  endif else begin

    fillval = -1.0e30

  endelse

  return, fillval

end