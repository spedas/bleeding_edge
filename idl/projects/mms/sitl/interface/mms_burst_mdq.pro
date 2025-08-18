;+
; FUNCTION: MMS_BURST_MDQ, CDQ1, CDQ2, CDQ3, CDQ4, Window=Window 
;
; PURPOSE: Calculates MDQ from CDQ inputs using a sort and convolve.
;
; INPUT:
;   CDQ1,2,3,4       - REQUIRED. Arrays of CDQ values. 
;   Window           - OPTIONAL. Window for sort/convolve. Must be 4 elements.
;                      DEFAULT = [0.1,0.2,0.3,0.4]
;
; CAUTION!             NO INPUT CHECKING WITHIN FUNCTION! CDQ's must have the
;                      same number of elements and values between 0 and 255.
;
; KEYWORDS:
;
; OUTPUT: A floating-point array of MDQ values.
;
; INITIAL VERSION: REE 2010-11-02
; LASP, University of Colorado
;
; MODIFICATION HISTORY:
;
;-

function mms_burst_mdq, CDQ1, CDQ2, CDQ3, CDQ4, Window=Window 

; #### NEED TO CHECK ALL INPUTS ARE SAME SIZE ####
; #### NEED TO CHECK ALL VALUES ARE BETWEEN 0 AND 255. ####
; #### NEED TO CHECK THAT WINDOW HAS 4 ELEMENTS THAT SUM TO 1. ####

npts = n_elements(CDQ1)
MDQ = fltarr(npts)
if not keyword_set(Window) then Window = [0.1, 0.2, 0.3, 0.4]

; CREATE POINT-BY-POINT ARRAY
FOR i = 0, npts-1 DO BEGIN
  A = float([CDQ1(i), CDQ2(i), CDQ3(i), CDQ4(i)])
  MDQ(i) = total(A(sort(A))*Window)
ENDFOR

return, MDQ
end


