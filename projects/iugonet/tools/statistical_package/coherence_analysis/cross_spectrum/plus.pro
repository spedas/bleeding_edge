;+
; NAME:
; plus
;
; PURPOSE:
; This function returns 1 if the input is positive, 0 otherwise.
;
; CATEGORY:
; Mathematics
;
; CALLING SEQUENCE:
; Result = PLUS( Y )
;
; INPUTS:
; Y:  A scalar or array of type integer or floating point.
;
; OUTPUTS:
; Result:  Returns 1 if Y is positive, 0 otherwise.
;
; PROCEDURE:
; This function determines whether Y is greater than 0.
;
; EXAMPLE:
; Determine if 3 is positive.
;   result = plus( 3 )
;
;CODE:
; A. Shinbori, 30/09/2011.
;
;MODIFICATIONS:
; A. Shinbori, 30/10/2011
; 
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2016-05-12 16:56:35 -0700 (Thu, 12 May 2016) $
; $LastChangedRevision: 21069 $
; $URL $
;-

function plus, Y

;***********************************************************************
;Determine if Y is positive.

;Output variable
ans = 0 * fix(y)

id = where( y gt 0, siz )
if siz gt 0 then ans[id] = 1

;***********************************************************************

return, ans

;The End
end