;+
;Helper function for packet decompression
;-
function mvn_pfdpu_DecodeB, bfr,bitinx
  dst = bytarr(32)
  R =  mvn_pfdpu_GetBits(bfr,bitinx,8)
  dst[0] = R
  for i=1,32-1 do begin    ;  for(i=0;i<31;i++)
    Del = mvn_pfdpu_NextB( bfr,bitinx);    // Each B value is a delta
    R += Del;
    dst[i] = R;
  endfor
  return,dst
end
