;$Author: moka $
;$Date: 2015-09-10 15:20:40 -0700 (Thu, 10 Sep 2015) $
;$Header: /home/cdaweb/dev/control/RCS/compare_struct.pro,v 1.3 2012/05/03 16:15:17 johnson Exp johnson $
;$Locker: johnson $
;$Revision: 18763 $
; Compare the two structures.  If they are the same return 1 else return 0
;
;Copyright 1996-2013 United States Government as represented by the
;Administrator of the National Aeronautics and Space Administration.
;All Rights Reserved.
;
;------------------------------------------------------------------
FUNCTION mms_compare_struct, a, b
  same=1L & as=size(a) & bs=size(b) & na=n_elements(as) & nb=n_elements(bs)
  if (as(na-2) ne bs(nb-2)) then return,0 $ ; different types
  else begin
    if (as(na-2) ne 8) then begin ; both types are not structures
      if (total(a ne b) ne 0.0) then return,0 else return,1
    endif else begin ; both a and b are structures, compare all fields
      ta = tag_names(a) & tb = tag_names(b)
      if (n_elements(ta) ne n_elements(tb)) then return,0 $ ; different # of tags
      else begin ; compare each tag name and then each tag field
        i=0L & j=0L & nta = n_elements(ta)
        while ((i le (nta-1)) AND (same eq 1)) do begin
          if (ta[i] ne tb[i]) then return,0 else i=i+1
        endwhile
        while ((j le (nta-1)) AND (same eq 1)) do begin
          same = mms_compare_struct(a.(j),b.(j)) & j=j+1
        endwhile
      endelse
    endelse
  endelse
  return,same
end


