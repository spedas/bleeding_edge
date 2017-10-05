;+
; Helper function for packet decompressions
;-
function mvn_pfdpu_NextC,bfr,bitinx
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
      m = mvn_pfdpu_GetBits(bfr,bitinx,2);
      if( m eq 0 ) then return,( 13 );
      if( m eq 1 ) then begin
          p = mvn_pfdpu_GetBits(bfr,bitinx,1);
          if( p eq 0) then return,( 14 );
          return,( mvn_pfdpu_GetBits(bfr,bitinx,8 ));
      endif
      if( m eq 2 ) then begin
          p = mvn_pfdpu_GetBits(bfr,bitinx,1);
          if( p eq 1) then return,( -14 );
          return,( -mvn_pfdpu_GetBits(bfr,bitinx,8 ));
      endif
      if( m eq 3 ) then return,( -13 ); break;
      end
   9: if( mvn_pfdpu_GetBits(bfr,bitinx,1) eq 1) then return,(-10) $
      else  return,( -12 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   10: return,( -9 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   11: return,( -7 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   12: return,( -5 + mvn_pfdpu_GetBits(bfr,bitinx,1));
   13: return,( -3 );
   14: return,( -2 );
   15: return,( -1 );
  endswitch
end
