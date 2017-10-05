;+
;Function: THM_FFT_DECOMPRESS
;
;Purpose:  Decompresses DFB FFT spectral data.
;Arguements:
;	DATA, any BYTE data type (scalar or array), 8-bit compressed FFT spectral estimates.
;keywords:
;   VERBOSE.
;Example:
;   result = thm_fft_compress( data)
;
;Notes:
;	-- Stub version, to allow for testing.
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2007-11-16 12:28:13 -0800 (Fri, 16 Nov 2007) $
; $LastChangedRevision: 2043 $
; $URL $
;-
function thm_fft_decompress, data, verbose=verbose

thm_init

;----------------------------------------
; Vectorized decompression from 8-bit pseudolog
; to 34-bit unsigned.
;----------------------------------------

  ;--- separate mantissa/exponent ---
  data64 = ulong64(data)
  n = data64 / 8ULL
  y = data64 and 7ULL

  ;--- decompress ---
  z = fltarr( size( data, /dim) > 1)
  indx = where(n eq 0, count, complement=indx2, ncomplement=count2)
  if (count gt 0)  then z[indx] = y[indx]
  if (count2 gt 0) then $
    z[indx2]=(y[indx2]+8ULL)*2ULL^(n[indx2]-1ULL)

return, z
end
