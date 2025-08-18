;+
;Helper function for packet decompression
;-
function  mvn_pfdpu_NextA,bfr,bitinx
  if(mvn_pfdpu_GetBits(bfr,bitinx,1) eq 0) then return,0  ;  // 0
  if(mvn_pfdpu_GetBits(bfr,bitinx,1) eq 0) then return,1  ;  // 10    
  n = mvn_pfdpu_GetBits(bfr,bitinx,2)    
  if( n lt 3 ) then return, n+2            ;  // 1100-1110 
  n = mvn_pfdpu_GetBits(bfr,bitinx,8)    
  return,n                                ;     // 1111xxxxxxxx
end
