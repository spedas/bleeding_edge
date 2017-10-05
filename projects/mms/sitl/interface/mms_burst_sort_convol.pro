;+
; FUNCTION: MMS_BURST_SORT_CONVOL, DATA, WINDOW, CAP
;
; PURPOSE: CONVOLVES A WINDOW WITH THE DATA LOCALLY IN SORT ORDER.
;
; INPUT:
;   DATA             - REQUIRED. CAUTION: NO NANS!
;   WINDOW           - REQUIRED.
;   CAP              - OPTIONAL. WILL HELP CENTER SPIKES. 
;
; CAUTION!             NO INPUT CHECKING WITHIN FUNCTION! All inputs must
;                      be valid.
;
; KEYWORDS:
;
; OUTPUT: A flaoting-point array the same size as data.
;
; INITIAL VERSION: REE 2010-11-02
; LASP, University of Colorado
;
; MODIFICATION HISTORY:
;
;-



; CALCULATE FOM
function mms_burst_sort_convol, data, window, cap


nwindow = n_elements(window)
ndata   = n_elements(data)
out     = fltarr(ndata)
halfw   = long(nwindow/2)
zeros   = fltarr(halfw)
dataex  = [zeros, float(data), zeros]

; CHECK KEYWORDS
IF ( keyword_set(cap) AND (nwindow GT 1) ) then BEGIN
  cap = (float(cap) < 1) > 0
  CapWindow = 1.0 - $
    abs( 2*(findgen(nwindow)-float(nwindow-1)/2) / (nwindow-1.0)) * cap
ENDIF ELSE CapWindow = 1.0

; PERFORM CONVOL
FOR i = 0L, ndata-1 DO BEGIN
  temp = dataex(i:nwindow-1+i)*CapWindow
  out(i) = total(temp(sort(temp))*window)
ENDFOR
return, out
end

