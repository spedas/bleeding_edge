function spp_fld_dfb_psuedo_log_decompress, compressed, type = type

  if not keyword_set(type) then type = ''

  dim_compressed = size(compressed,/dim)

  ; scalar case

  if dim_compressed[0] EQ 0 and n_elements(compressed) EQ 1 then dim_compressed = 1

  compressed = long64(compressed)

  case strlowcase(type) of
    'bandpass': begin
      exp_div = 2ll^4
      man_mod = 2ll^4
    end
    'spectra': begin
      exp_div = 2ll^3
      man_mod = 2ll^3
    end
    else: begin
      print, 'no type specified'
      return, -1
    end
  endcase

  exponent = compressed / exp_div

  mantissa = compressed MOD man_mod

  exp_zero_ind = where(exponent EQ 0, exp_zero_count, $
    complement = exp_nonzero_ind, ncomplement = exp_nonzero_count)

  decompressed = dblarr(dim_compressed)

  if exp_zero_count GT 0 then begin

    decompressed[exp_zero_ind] = mantissa[exp_zero_ind]

  endif

  if exp_nonzero_count GT 0 then begin

    decompressed[exp_nonzero_ind] = $
      (mantissa[exp_nonzero_ind] + 2ll^4l) * 2.^(exponent[exp_nonzero_ind] - 1ll)

  endif

  return, decompressed

end