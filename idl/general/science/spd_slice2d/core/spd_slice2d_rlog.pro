
;+
;Procedure:
;  spd_slice2d_rlog
;
;
;Purpose:
;  Apply radial log scaling to aggregated velocity/energy vectors.
;
;
;Input:
;  r: N element array of radii
;  dr: N element array of radial bin withds (full width)
;  displacement: scalar denoting slice's offset of the origin along the normal
;
;
;Output:
;  None, modifies input variables by tranforming into log space and normalizing
;  along the range of the data. 
;
;
;Notes:
;
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-09-08 18:47:45 -0700 (Tue, 08 Sep 2015) $
;$LastChangedRevision: 18734 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_slice2d_rlog.pro $
;
;-
pro spd_slice2d_rlog, r, dr, displacement=displacement

    compile_opt idl2, hidden


  ;get log of radial boundaries
  rbottom = alog10(r - 0.5 * dr)
  rtop = alog10(r + 0.5 * dr)

  range = [min(rbottom), max(rtop)]
  span = range[1] - range[0]
  
  ;shrink gap between (0,r_min] and normalize
  rbottom = rbottom - range[0]
  rbottom = rbottom / span
  
  rtop = rtop - range[0]
  rtop = rtop / span
  
  ;repalce original vars
  r = (rtop + rbottom) / 2.
  dr = (rtop - rbottom)

  ;scale displacement
  if arg_present(displacement) && displacement ne 0 then begin
    dsign = displacement lt 0 ? -1:1
    displacement = alog10(abs(displacement))
    displacement = (displacement - range[0]) > 0 
    displacement = displacement / span  *  dsign
  endif

  return

end