;+
; $LastChangedDate: 2021-03-25 13:26:37 -0700 (Thu, 25 Mar 2021) $
; $LastChangedRevision: 29823 $
;-

FUNCTION PWR10TICK, axis, index, value

   expval=FIX(ROUND(ALOG10(value)))


   RETURN, STRJOIN('10!U'+STRTRIM(STRING(expval),2)+'!N')
END
