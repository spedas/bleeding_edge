;+
; Procedure: customtickformatexp
;
; Purpose:
;   Forces the format of the numbers on the y-axis to be powers of ten.
;   It can be used to set the IDL YTICKFORMAT option of tplot.
;
; Keywords:
;   The three keywords for this function should not be set or used.
;   They are required internally for the IDL plot procedure.
;
; Examples:
;   This is how it can be used in SPEDAS:
;     options, /def, varname, 'ytickformat', 'customtickformatexp'
;
;   This is how it can be used with the original IDL plot procedure:
;     plot, [1, 1e3], YTickFormat='customtickformatexp'
;     plot, [1,1e3], YTickFormat='customtickformatexp', YLog=1
;
; Notes:
;   Normally, IDL shows the numbers on the plot axis either as decimals or as powers of ten.
;   This is decided by an IDL internal algorithm, but this function can force it
;   to be powers of ten.
;
;   This function is a modification of the following function from idlcoyote.com.
;   It was originally written by Stein Vidar Hagfors Haugan.
;   http://www.idlcoyote.com/tips/exponents.html
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2024-05-10 13:10:49 -0700 (Fri, 10 May 2024) $
; $LastChangedRevision: 32571 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/customtickformatexp.pro $
;-

FUNCTION customtickformatexp, axisn, index, number

  ; A special case.
  IF number EQ 0 THEN RETURN, '0'

  ; Assuming multiples of 10 with format.
  ex = String(number, Format='(e8.0)')
  pt = StrPos(ex, '.')

  first = StrMid(ex, 0, pt)
  sign = StrMid(ex, pt+2, 1)
  thisExponent = StrMid(ex, pt+3)

  ; Shave off leading zero in exponent
  WHILE StrMid(thisExponent, 0, 1) EQ '0' DO thisExponent = StrMid(thisExponent, 1)

  ; Fix for sign and missing zero problem.
  IF (Long(thisExponent) EQ 0) THEN BEGIN
    sign = ''
    thisExponent = '0'
  ENDIF

  ; Make the exponent a superscript.
  IF sign EQ '-' THEN BEGIN
    if first eq 1 then RETURN, '10!U' + sign + thisExponent + '!N' else RETURN, first + 'x10!U' + sign + thisExponent + '!N'
  ENDIF ELSE BEGIN
    if first eq 1 then RETURN, '10!U' + thisExponent + '!N' else RETURN, first + 'x10!U' + thisExponent + '!N'
  ENDELSE

END