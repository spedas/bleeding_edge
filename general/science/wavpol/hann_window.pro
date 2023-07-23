;+
;
; NAME: hann_window
;
;PURPOSE: Return a Hann smoothing window of order M (usually odd).
;
;w(n) = w = 0.5 - 0.5*cos(2 pi n/(m-1))  for 0 <= n <= m-1
;
;EXAMPLE: hann_window(7,/normalize)
;
;CALLING SEQUENCE: hann_window(m, /normalize)
;
;INPUTS:
;       m: length of desired smoothing window
;;
;Keywords:
;  normalize (optional):  If set, divide by the sum of the w(n) values so the weights sum to 1.0
;
;OUTPUTS: M-element double precision array containing the smoothing weights
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2022-08-18 14:05:08 -0700 (Thu, 18 Aug 2022) $
; $LastChangedRevision: 31024 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/wavpol/wavpol.pro $
;-

function hann_window, m, normalize=normalize
   w = 0.5 - 0.5*cos(2.0D * !dpi * dindgen(m)/(m - 1.0D))
   tot = total(w)
   if keyword_set(normalize) then return, w/tot else return, w
   return, w
end