;+
; Helper function -- split out of mvn_ql_pfp_tplot. Generates ytickformat
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2017-02-17 11:57:18 -0800 (Fri, 17 Feb 2017) $
; $LastChangedRevision: 22819 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_ql_pfp_tplot_ytickname_minus_log.pro $
;
;-
FUNCTION mvn_ql_pfp_tplot_ytickname_minus_log, axis, index, number
  times = 'x'
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
  
  IF (first EQ '  1') OR (first EQ ' 1') THEN BEGIN
     first = ''
     times = ''
  ENDIF
  
  ; Make the exponent a superscript.
  IF sign EQ '-' THEN BEGIN
     RETURN, '-' + first + times + '10!U' + sign + thisExponent + '!N'
  ENDIF ELSE BEGIN
     RETURN, '-' + first + times + '10!U' + thisExponent + '!N'
  ENDELSE
END
