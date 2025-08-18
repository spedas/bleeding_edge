;+
;Helper function for packet decompression
;-
function mvn_pfdpu_GetBits,bfr,bitinx, leng
  if leng gt (n_elements(bfr)*8 - bitinx) then begin
     return,0
  endif
  r=0
  for i=0,leng-1 do begin              ;  for(i=0;i<leng;i++) 
      r = r*2 + mvn_pfdpu_GetBit(bfr,bitinx)
  endfor
  return, r
end
