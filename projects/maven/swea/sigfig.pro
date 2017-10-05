;+
;FUNCTION:   sigfig
;PURPOSE:
;  Simple function for rounding off.
;
;USAGE:
;  y = sigfig(x,n)
;
;INPUTS:
;       x:      The value to be rounded.  Can be an array.
;
;       n:      Number of significant figures (>= 1).
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-03-31 18:06:44 -0700 (Mon, 31 Mar 2014) $
; $LastChangedRevision: 14725 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/sigfig.pro $
;
;CREATED BY:    David L. Mitchell  A Long Time Ago
;-
function sigfig, data, nfigs

  nfigs = (round(nfigs) - 1L) > 0L

  rdata = data
  indx = where(data ne 0., count)
  
  if (count gt 0L) then begin
    fpow = 10.^(floor(alog10(abs(data[indx]))) - nfigs)
    rdata[indx] = round(data[indx]/fpow)*fpow
  endif

  return, rdata

end
