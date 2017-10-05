;+
; NAME:
;	sswhere_arr
; CALLING SEQUENCE:
;	ss=sswhere_arr(arr1, arr2)
; PURPOSE:
;	gives the subscripts in the array arr1 that are for elements
;	of arr2.
; INPUT:
;	arr1, arr2 = two arrays
; OUTPUT:
;	ss = the subscripts of arr1 that are also in arr2
; KEYWORD:
;       notequal = if set, return the array elements of arr1 that are
;                  not in arr2
; HISTORY
;	Spring '92 JMcT
;       Added notequal, extra, jun 2007, jmm
;       Testing SVN, 20-jan-2009, jmm
;-
FUNCTION sswhere_arr, arr1, arr2, notequal = notequal, _extra = _extra
   
   otp = -1
   n1 = n_elements(arr1)
   n2 = n_elements(arr2)
   If(n1 Eq 0 Or n2 Eq 0) Then Return, otp
   in_arr2 = bytarr(n1)
   not_in_arr2 = in_arr2+1

   FOR j = 0l, n1-1 DO BEGIN
      ok = where(arr2 Eq arr1[j])
      IF(ok(0) NE -1) THEN BEGIN
         in_arr2[j] = 1b
         not_in_arr2[j] = 0b
      ENDIF
   ENDFOR
   
   IF(keyword_set(notequal)) THEN BEGIN
      otp = where(not_in_arr2 Eq 1)
   ENDIF ELSE BEGIN
      otp = where(in_arr2 Eq 1)
   ENDELSE
   RETURN, otp
END
