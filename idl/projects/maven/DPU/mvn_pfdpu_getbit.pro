;+
;Helper function for packet decompression
;-
function mvn_pfdpu_getbit,bfr,bitinx
  inx = bitinx / 8
  bit = bitinx mod 8
  bmask = [128b,64b,32b,16b,8b,4b,2b,1b]
  bitinx++
  return ,  (bfr[Inx] and bmask[bit]) ne 0
end
