;+
; NAME:
; dimension
;
; PURPOSE:
; This function returns the dimension of an array.  It returns 0
; if the input variable is scalar.
;
; CATEGORY:
; Array
;
; CALLING SEQUENCE:
; Result = DIMENSION(Inarray)
;
; INPUTS:
; Inarray:  A scalar or array of any type.
;
; OUTPUTS:
; Result:  The dimension of Inarray.  Returns 0 if scalar.
;
; PROCEDURE:
; This function runs the IDL function SIZE.
;
; EXAMPLE:
; Define a 3*4-element array.
;   x = findgen(3,4)
; Calculate the dimension of x.
;   result = dimension(x)
;
;MODIFICATIONS:
; A. Shinbori, 30/10/2011
; 
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2017-12-05 22:14:20 -0800 (Tue, 05 Dec 2017) $
; $LastChangedRevision: 24404 $
; $URL $
;-

;***********************************************************************

function dimension, Inarray

;***********************************************************************
;Calculate the dimension of Inarray.

outdim = (size(inarray))[0]

return, outdim
;***********************************************************************
;The End
end