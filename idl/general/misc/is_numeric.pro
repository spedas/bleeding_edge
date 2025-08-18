;+
;
;Name: is_numeric
;
;Purpose: determines if input string is a validly formatted number.  Does
;
;Inputs: s:  the string to be checked
;
;Outputs: 1: if it is validly formatted
;         0: if it is not
;         
;Keywords: 
;    sci_notation: add support for scientific notation (3*10^6)
;    decimal: when set, only return 1 for decimal numeric values, such as 1.0, 0.000004, 
;             returns 0 for scientific, exponential, engineering, etc. notations
;
;Notes:  Does not consider numbers in complex notation or numbers with trailing type codes to be valid.
;
;Examples:
;   print,is_numeric('1')
;   1
;   print,is_numeric('1.23e45')
;   1
;   print,is_numeric('1.2c34')
;   0
;   print,is_numeric('1B')
;   0
;   print,is_numeric('-1.23d-3')
;   1
;   print,is_numeric('5e+4')
;   1
;   print,is_numeric('5.e2')
;   1
;   print,is_numeric('5.e3.2')
;   0
;   
;   Examples using scientific notation:
;   print,is_numeric('4*10^2', /sci)
;   1
;   print,is_numeric('4*10^-6', /sci)
;   1
;   print,is_numeric('4*10^(-12)', /sci)
;   1
;   print,is_numeric('12.3*10^2', /sci)
;   1
;   print,is_numeric('10^-2.2', /sci)
;   1
;   print,is_numeric('10.^-2.2', /sci)
;   1
;   print,is_numeric('12.3*10^', /sci)
;   0
;   print,is_numeric('12.3*', /sci)
;   0
;   
; $LastChangedBy: nikos $
; $LastChangedDate: 2014-05-13 09:46:59 -0700 (Tue, 13 May 2014) $
; $LastChangedRevision: 15109 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/is_numeric.pro $
;-

function is_numeric,s, sci_notation=sci_notation, decimal=decimal
  if keyword_set(sci_notation) then begin
    if s eq '' then return, 0
    if STREGEX(s, '\\', /BOOLEAN) then return, 0
    if ~STREGEX(s, '[0-9]', /BOOLEAN) then return, 0
    return,stregex(strtrim(s,2),'^[-+]?([0-9.]*\.?[0-9.]*|([0-9.]*\*?[0-9.]+)|([0-9]*\.?[0-9]+))(([EeDd][-+]?[0-9]+)|(\*?[0-9\.?]+(\^)?[(]*[+-]?[0-9\.?]+[)]*))?$') eq 0
  endif else if keyword_set(decimal) then begin
    if s eq '' then return, 0
    if STREGEX(s, '\\', /BOOLEAN)  then return, 0
    if ~STREGEX(s, '[0-9]', /BOOLEAN) then return, 0
    return, stregex(strtrim(s,2),'^[-+]?[0-9]*\.?[0-9]*$') eq 0
  endif else begin
    ; old regex, before adding support for scientific notation (3*10^6)
    return,stregex(strtrim(s,2),'^[-+]?(([0-9]+\.?[0-9]*)|([0-9]*\.?[0-9]+))([EeDd][-+]?[0-9]+)?$') eq 0
  endelse
end
