;+
;FUNCTION:
;  spd_ui_getlengthvars
;
;PURPOSE:
;
;  helper function for formatannotation
;   
;Inputs:
;
;Example:
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_getlengthvars.pro $
;-


pro spd_ui_getlengthvars, val, dec, neg

    compile_opt idl2, hidden

  ;extra length for '-' sign 
    neg = val lt 0 
  ;number of digits left of the decimal
    if val eq 0 then begin
      dec = 1
    endif else begin
      dec = floor(alog10(abs(val)) > 0)+1
    endelse
  ;if the size of the exponent is greater than 99, both OS's
    ;will use three digit output
    ;if floor(abs(alog10(abs(val))))+1  gt 99 then os = 1

end
