;+
;Helper function for packet decompression
;-
function mvn_pfdpu_NextD,bfr,bitinx
  n = mvn_pfdpu_GetBits(bfr,bitinx,4);
  switch (n) of
   0: 
   1: 
   2:
   3: return,(n);
   4: return,( 4 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   5: return,( 6 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   6: return,( 8 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   7: if( mvn_pfdpu_GetBits(bfr,bitinx,1) eq 0) then return,(10) $
      else return,( 11 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   8: begin 
      m = mvn_pfdpu_GetBits(bfr,bitinx,4);
      if( m lt 7 ) then return,( 13+m );
      if( m eq 7 ) then return,(  mvn_pfdpu_GetBits(bfr,bitinx,8));
      if( m eq 8 ) then return,( -mvn_pfdpu_GetBits(bfr,bitinx,8));
      if( m gt 8 ) then return,( -28+m );
     end  ; break;
   9: if( mvn_pfdpu_GetBits(bfr,bitinx,1) eq 1) then return,(-10) else $
      return,( -12 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   10: return,( -9 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   11: return,( -7 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   12: return,( -5 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   13: return,( -3 );
   14: return,( -2 );
   15: return,( -1 );
  endswitch
end
