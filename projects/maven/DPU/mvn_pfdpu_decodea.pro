;+
;Helper function for packet decompression
;-
function mvn_pfdpu_DecodeA, bfr,bitinx 
  dst = bytarr(32)
;  dprint,bitinx,dlevel=3
  for i=0,32-1 do begin            ;  for(i=0;i<32;i++)
    dst[i] =  mvn_pfdpu_NextA(bfr,bitinx)
;    dprint,bitinx,dst[i],format='(i4," ",z02)',dlevel=3
  endfor
  return,dst 
end
