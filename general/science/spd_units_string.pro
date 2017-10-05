;+
;Procedure:
;  spd_units_string
;
;Purpose:
;  Return string describing particle data units for labels etc.
;
;Calling Sequence:
;  string = spd_units_string(units, [,/simple] [,/units_only])
;
;Input:
;  units:  String describing units
;  simple:  Flag to return string with no special formatting
;  units_only:  Flag to return just the units
;
;Output:
; return value:  String containing unit description and breakdown
;
;Notes:
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-10-06 11:44:15 -0700 (Thu, 06 Oct 2016) $
;$LastChangedRevision: 22052 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_units_string.pro $
;-

function spd_units_string, units, simple=simple, units_only=units_only, _extra=_extra

    compile_opt idl2, hidden



;output string = [ prefix, units, suffix]
if keyword_set(simple) then begin
  
  case strlowcase(units) of
  
    'counts' : ustr = ['','Counts','']
    'rate'   : ustr = ['Rate (','#/sec',')']
    'eflux'  : ustr = ['Energy Flux (','eV / sec / cm^2 / ster / eV',')']
    'flux'   : ustr = ['Flux (','# / sec / cm^2 / ster / eV',')']
    'df'     : ustr = ['f (','s^3 / km^6',')']
    'df_cm'  : ustr = ['f (','s^3 / cm^6',')']
    'df_km'  : ustr = ['f (','s^3 / km^6',')']
    'e2flux' : ustr = ['Energy^2 Flux (','eV^2 / sec / cm^2 / ster /ev',')']
    'e3flux' : ustr = ['Energy^3 Flux (','eV^3 / sec / cm^2 / ster /ev',')']
    else: ustr = 'Unknown'
  
  endcase

endif else begin

  case strlowcase(units) of
  
    'counts' : ustr = ['','Counts','']
    'rate'   : ustr = ['Rate (','#/sec',')']
    'eflux'  : ustr = ['Energy Flux (','eV/s/cm!U2!N/str/eV',')']
    'flux'   : ustr = ['Flux (','#/s/cm!U2!N/str/eV',')']
    'df'     : ustr = ['f (','s!U3!N/km!U6!N',')']
    'df_cm'  : ustr = ['f (','s!U3!N/cm!U6!N',')']
    'df_km'  : ustr = ['f (','s!U3!N/km!U6!N',')']
    'e2flux' : ustr = ['Energy!U2!N Flux (','eV!U2!N/s/cm!U2!N/str/eV',')']
    'e3flux' : ustr = ['Energy!U3!N Flux (','eV!U3!N/s/cm!U2!N/str/eV',')']
    else: ustr = 'Unknown'
  
  endcase

endelse

;strip prefix/suffix if requested
if keyword_set(units_only) then begin
  ustr = ustr[1]
endif else begin
  ustr = strjoin(ustr)
endelse

return,ustr

end
