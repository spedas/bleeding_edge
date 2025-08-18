;+
;Procedure:
;  erg_units_string
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
;Author:
;  Tomo Hori, ERG Science Center, Nagoya Univ.
;  (E-mail tomo.hori _at_ nagoya-u.jp)
;
;History:
;  ver.0.0: The 1st experimental release
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2019-10-23 14:19:14 -0700 (Wed, 23 Oct 2019) $
;$LastChangedRevision: 27922 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/satellite/erg/particle/erg_units_string.pro $
;-

function erg_units_string, units, simple=simple, units_only=units_only, $
                           relativistic=relativistic, _extra=_extra

    compile_opt idl2, hidden



;output string = [ prefix, units, suffix]
if keyword_set(simple) then begin
  
  case strlowcase(units) of
  
    'counts' : ustr = ['','Counts','']
    'rate'   : ustr = ['Rate (','#/sec',')']
    'eflux'  : ustr = ['Energy Flux (','eV / sec / cm^2 / ster / eV',')']
    'flux'   : ustr = ['Flux (','# / sec / cm^2 / ster / eV',')']
    'df'     : begin
      if keyword_set(relativistic) then ustr = ['PSD (', '(c/MeV/cm)^3', ')'] else ustr = ['PSD (', 's^3 / km^6', ')']
    end
    'psd'     : begin
      if keyword_set(relativistic) then ustr = ['PSD (', '(c/MeV/cm)^3', ')'] else ustr = ['PSD (', 's^3 / km^6', ')']
    end
    'df_cm'  : ustr = ['PSD (','s^3 / cm^6',')']
    'df_km'  : ustr = ['PSD (','s^3 / km^6',')']
    'e2flux' : ustr = ['Energy^2 Flux (','eV^2 / sec / cm^2 / ster /eV',')']
    'e3flux' : ustr = ['Energy^3 Flux (','eV^3 / sec / cm^2 / ster /eV',')']
    else: ustr = 'Unknown'
  
  endcase

endif else begin

  case strlowcase(units) of
  
    'counts' : ustr = ['','Counts','']
    'rate'   : ustr = ['Rate (','#/sec',')']
    'eflux'  : ustr = ['Energy Flux (','eV/s/cm!U2!N/str/eV',')']
    'flux'   : ustr = ['Flux (','#/s/cm!U2!N/str/eV',')']
    'df'     : begin
      if keyword_set(relativistic) then ustr = ['Phase space density (', '(c/MeV/cm)!U3!N', ')'] else ustr = ['Phase space density (', 's!U3!N/km!U6!N', ')']
    end
    'psd'     : begin
      if keyword_set(relativistic) then ustr = ['Phase space density (', '(c/MeV/cm)!U3!N', ')'] else ustr = ['Phase space density (', 's!U3!N/km!U6!N', ')']
    end
    'df_cm'  : ustr = ['Phase space density (','s!U3!N/cm!U6!N',')']
    'df_km'  : ustr = ['Phase space density (','s!U3!N/km!U6!N',')']
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
