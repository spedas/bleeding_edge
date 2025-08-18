pro wavelet_data,tname,dimen=dimenn,kolom=kol,trange=trange,j=j,pdens=pdens
get_data,tname,t,y
name=tname
if dimen2(y) gt 1 then begin
   if n_elements(dimenn) eq 0 then message,"Need dimen!"
   y = y[*,dimenn]
   name = name+'('+strtrim(dimenn,2)+')'
endif

if n_elements(trange) eq 2 then begin
   w = where((t le trange[1]) and (t ge trange[0]),nw)
   if nw eq 0 then begin
      dprint,'No data in time range'
      return
   endif
   t=t[w]
   y=y[w]
endif
nt = n_elements(t)
dt = (t[nt-1]-t[0])/(nt-1)
interp_gap,t,y,/verbose
n = n_elements(y)
wave = wavelet(y,dt,pad=2,period=period,coi=coi,signif=signif,/verb,j=j)
;print,signif
pwave=abs(wave)^2
;p=average(pwave,1)
freq=1/period
pkg = .0003 * freq^(-5./3.)
if keyword_set(kol) then pwave = pwave/(replicate(1.,n) # pkg)
if keyword_set(pdens) then pwave = pwave/(replicate(1.,n) # (1/freq))
;specplot,t,freq,pwave,lim={ylog:1},/no_inter
store_data,name+'_wvlt',data={x:t,y:pwave,v:period},dlim={spec:1,ylog:1,zlog:1,ystyle:1,no_interp:1}
;store_data,name+'_coi' , data={x:t,y:coi}
;store_data,name+'_wvs',data=name+'_wvlt '+name+'_coi',dlim={yrange:minmax(period),ystyle:1}
end

