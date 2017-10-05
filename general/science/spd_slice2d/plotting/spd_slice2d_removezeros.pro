;+
;Procedure:
;  spd_slice2d_removezeros
;
;
;Purpose:
;  Helper routine for spd_slice2d_plot.
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
;$LastChangedDate: 2015-09-08 18:47:45 -0700 (Tue, 08 Sep 2015) $
;$LastChangedRevision: 18734 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/plotting/spd_slice2d_removezeros.pro $
;
;-

; Removes trailing zeros and/or decimal from string,
; Assumes trailing spaces have already been removed.
function spd_slice2d_removezeros, sval

    compile_opt idl2, hidden
  
  if ~stregex(sval, '\.', /bool) then return, sval

  f = stregex(sval, '0*$',length=len)

  if stregex(sval, '\.0*$', /bool) then len++

  return, strmid(sval, 0, (strlen(sval)-len) )

end

