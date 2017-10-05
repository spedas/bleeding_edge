;+
;Helper function for packet decompression
;-
function mvn_pfdpu_NextB,bfr,bitinx
  n = mvn_pfdpu_GetBits(bfr,bitinx,3);

  case n of 
     0: return, (0)
     1: return, (1)  
     2: return,( 2 + mvn_pfdpu_GetBits(bfr,bitinx,1));
     3: return,( 4 + mvn_pfdpu_GetBits(bfr,bitinx,2));
     4: begin
         m = mvn_pfdpu_GetBits(bfr,bitinx,2);
         if( m eq 0 )  then return,( 8 );
         if( m eq 1 )  then begin
             p = mvn_pfdpu_GetBits(bfr,bitinx,2);
             if( p lt 3) then return,( 9 + p);
             return,( mvn_pfdpu_GetBits(bfr,bitinx, 8 )); 
         endif
         if( m eq 2 ) then begin
             p = mvn_pfdpu_GetBits(bfr,bitinx,2);
             if( p gt 0) then return,( -12 + p);
             return,( - mvn_pfdpu_GetBits(bfr,bitinx, 8 ));
         endif
         if( m eq 3 ) then return,( -8 );
       end;
     5: return,( -7 + mvn_pfdpu_GetBits(bfr,bitinx,2));
     6: return,( -3 + mvn_pfdpu_GetBits(bfr,bitinx,1));
     7: return,( -1 );
   endcase
end
