;+
;  Procedure:  wavelet2,y,dt
;  Purpose:  Wrapper of IDL wavelet routine
;            Uses Morlet mother wavelet.
;
;  rewritten by: Davin Larson
;$LastChangedBy: davin-mac $
;$LastChangedDate: 2014-12-11 11:04:24 -0800 (Thu, 11 Dec 2014) $
;$LastChangedRevision: 16459 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/tplot/wvlt/wavelet2.pro $
;
;-




function wavelet2,y,dt,prange=prange,frange=frange, pad=pad, $
    period=period,dj=dj,param=w0,verbose=verbose

dimen = size(/dimen,y)
nd = size(/n_dimen,y)
d2 = (nd eq 2) ? dimen[1] : 1
;help,nd
n = dimen[0]

if not keyword_set(w0) then w0 = 2.*!pi

dj= 1/8.*(2.*!pi/w0)

if keyword_set(frange) then prange=minmax(1/frange)
if not keyword_set(prange) then prange=[2.*dt,0.05*n*dt]  ; default range = nyquist period - 5% of time interval
if prange[0] eq 0 then prange[0] = 2.*dt

srange = (2.*dt > prange < n*dt) * (w0+sqrt(2+w0^2))/4/!pi
srange = (prange) * (w0+sqrt(2+w0^2))/4/!pi

jv=FIX((ALOG(srange[1]/srange[0])/ALOG(2))/dj)

;If not enough time samples are chosen, then jv < 0
If(jv Le 0) Then Return, -1

wdimen = [n,jv+1,d2]

vb = keyword_set(verbose) ? verbose : 0

wave = make_array(/complex,dimen=wdimen,/noz)
for d=0,d2-1 do $
  wave[*,*,d] = wavelet(y[*,d],dt,period=period,pad=pad, $
      dj=dj,s0=srange[0],j=jv,param=w0,verbose= vb ge 5) * sqrt(2*dt)

;if keyword_set(tint) then  $
;  for d=0,d2-1 do $
;    for j=0,jv do wave[*,j,d] = wave[*,j,d] *  sqrt(1/period[j])

return,wave
end
