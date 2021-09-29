;+
; NAME:
;	f3pl
; CALLING SEQUENCE:
;	f=f3pl(ax,x)
; PURPOSE:
;	Calculates values for the triple power law
; INPUT:
;	ax= fit parameters, [slope, intercept, slope, intercept,
;	slope, intercept]
;	x = value input
; OUTPUT:
;	f=ax[0]+ax[1]*x, below xbr1
;	f=ax[2]+ax[3]*x, above xbr1, where
;       xbr1 = (ax[2]-ax[0])/(ax[1]-ax[3])
;       f=ax[4]+ax[5]*x, above xbr2, where
;       xbr2 = (ax[4]-ax[2])/(ax[3]-ax[5])
; HISTORY:
;	Spring '92 JMcT

;-
FUNCTION f3pl, ax, x
   
  xbr1 = (ax[2]-ax[0])/(ax[1]-ax[3])
  xbr2 = (ax[4]-ax[2])/(ax[3]-ax[5])
  f = x & f[*] = 0
  lo =  where(x LT xbr1)
  IF(lo[0] NE -1) THEN f[lo] =  ax[0]+ax[1]*x[lo]
  mi =  where(x GE xbr1 and x LT xbr2)
  IF(mi[0] NE -1) THEN f[mi] =  ax[2]+ax[3]*x[mi]
  hi =  where(x GE xbr2)
  IF(hi[0] NE -1) THEN f[hi] =  ax[4]+ax[5]*x[hi]
  RETURN, f

END

