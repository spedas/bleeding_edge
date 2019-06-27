function spp_fld_dfb_psuedo_log_decompress, compressed, type = type, $
  high_gain = high_gain

  ;  if not keyword_set(high_gain) then high_gain = 0

  case ndimen(high_gain) of
    -1: high_gain_2d = rebin([0],size(reform(compressed),/dim))
    0:high_gain_2d = rebin([high_gain],size(reform(compressed),/dim))
    1:high_gain_2d = rebin(high_gain,size(reform(compressed),/dim))
    2:high_gain_2d = high_gain
  endcase


  if not keyword_set(type) then type = ''

  dim_compressed = size(compressed,/dim)

  ; scalar case

  if dim_compressed[0] EQ 0 and n_elements(compressed) EQ 1 then $
    dim_compressed = 1

  compressed = long64(compressed)

  ; DFB compression scheme:

  ; BP    EEEE MMMM
  ; SP    EEEE EMMM
  ; XSP   SEEE EEMM MMMM MMMM

  ; Some examples:

  ; TODO: These examples are out of date, need updating!

  ; bp_comp = [0x00,0x07,0x0F,0x20,0x57,0xFF]
  ; bp = spp_fld_dfb_psuedo_log_decompress(bp_comp, type = 'bandpass')
  ; print, long64(bp)
  ; 0           7          15          32         368      507904

  ; sp_comp = [0x00,0x07,0x0F,0x20,0x57,0xFF]
  ; sp = spp_fld_dfb_psuedo_log_decompress(bp_comp, type = 'spectra')
  ; print, long64(sp)
  ;  0                     7                    15
  ; 64                  7680           16106127360

  ; Positive
  ; xs_comp = [0x0000, 0x000F, 0x00FF, 0x03FF, 0x07FF, 0x5555, 0x7FFF]
  ; xs = spp_fld_dfb_psuedo_log_decompress(xs_comp, type = 'xspectra')
  ; print, long64(xs)
  ;              0                    15                   255
  ;           1023                  2047            1431306240
  ;  2197949513728

  ;
  ; Negative
  ; xs_comp = [0x8000, 0x800F, 0x80FF, 0x83FF, 0x87FF, 0xD555, 0xFFFF]
  ; xs = spp_fld_dfb_psuedo_log_decompress(xs_comp, type = 'xspectra')
  ; print, long64(xs)
  ;              0                   -15                  -255
  ;          -1023                 -2047           -1431306240
  ; -2197949513728

  case strlowcase(type) of
    'bandpass': begin
      signed = 0
      man_mod = 2ll^4
      high_gain_divide = 1d ; no high gain division for bandpass
      decompress_divide = 1d
    end
    'spectra': begin
      signed = 0
      man_mod = 2ll^3
      high_gain_divide = 2048d
      decompress_divide = 64d
    end
    'xspectra': begin
      signed = 1
      sign_div = 2ll^15
      man_mod = 2ll^10
      high_gain_divide = 128d
      decompress_divide = 4096d
    end
    else: begin
      print, 'no type specified'
      return, -1
    end
  endcase

  if signed EQ 1 then begin

    sign_bit = compressed / sign_div

    compressed = compressed MOD sign_div

    neg_ind = where(sign_bit NE 0, neg_count)

  endif else begin

    neg_count = 0

  endelse

  exponent = compressed / man_mod

  mantissa = compressed MOD man_mod

  exp_zero_ind = where(exponent EQ 0, exp_zero_count, $
    complement = exp_nonzero_ind, ncomplement = exp_nonzero_count)

  decompressed = dblarr(dim_compressed)

  if exp_zero_count GT 0 then begin

    decompressed[exp_zero_ind] = mantissa[exp_zero_ind]

  endif

  if exp_nonzero_count GT 0 then begin

    decompressed[exp_nonzero_ind] = $
      (mantissa[exp_nonzero_ind] + man_mod) * $
      2d^(exponent[exp_nonzero_ind] - 1ll)

  endif

  if neg_count GT 0 then begin

    decompressed[neg_ind] *= -1.d

  endif

  high_gain_ind = where(high_gain_2d EQ 1, high_gain_count)

  if high_gain_count GT 0 then begin

    decompressed[high_gain_ind] /= high_gain_divide[high_gain_ind]

  endif

  decompressed /= decompress_divide

  return, decompressed

end