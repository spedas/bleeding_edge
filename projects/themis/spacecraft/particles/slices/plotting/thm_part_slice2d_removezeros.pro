;+
;Procedure:
;  thm_part_slice2d_removezeros
;
;
;Purpose:
;  Helper routine for thm_part_slice2d_plot.
;  Removes trailing zeros and/or decimal from string.
;  
;  This could probably be repurposed into a general routine.
;
;
;Input:
;  sval: (string) Numerical string to be modified
;
;
;Output:
;  return value: (string) copy of input string with trailing 
;                 zeros and/or decimal removed.
;
;
;Notes:
;  -Assumes trailing spaces have already been removed.
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-04 18:05:22 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20331 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/plotting/thm_part_slice2d_removezeros.pro $
;
;-

; Removes trailing zeros and/or decimal from string,
; Assumes trailing spaces have already been removed.
function thm_part_slice2d_removezeros, sval

    compile_opt idl2, hidden
  
  if ~stregex(sval, '\.', /bool) then return, sval

  f = stregex(sval, '0*$',length=len)

  if stregex(sval, '\.0*$', /bool) then len++

  return, strmid(sval, 0, (strlen(sval)-len) )

end

