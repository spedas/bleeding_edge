;+
; NAME:
;	f2pl
; CALLING SEQUENCE:
;	f=f2pl(ax,x)
; PURPOSE:
;	Calculates values the double power law
; INPUT:
;	ax= fit parameters, [slope, intercept, slope, intercept]
;	x = value input
; OUTPUT:
;	f=ax[0]+ax[1]*x, below xbr
;	f=ax[2]+ax[3]*x, above xbr, where
;       xbr = (ax[2]-ax[0])/(ax[1]-ax[3])
; HISTORY:
;	Spring '92 JMcT

;-
FUNCTION f2pl, ax, x
   
  xbr = (ax[2]-ax[0])/(ax[1]-ax[3])
  f = x & f[*] = 0
  lo =  where(x LT xbr)
  IF(lo[0] NE -1) THEN f[lo] =  ax[0]+ax[1]*x[lo]
  hi =  where(x GE xbr)
  IF(hi[0] NE -1) THEN f[hi] =  ax[2]+ax[3]*x[hi]
  RETURN, f

END

