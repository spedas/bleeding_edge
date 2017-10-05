pro mav_sep_gse_statistics,s,t,png=png
wi,0
if not keyword_set(s) then s= tsample('SEP_SCIENCE_DATA',times=t)
tr = minmax(t)
if keyword_set(png) then makepng,'LT_tplot',time=tr[0]

dt = tr[1]-tr[0]
title = time_string(tr[0]) + strtrim(dt)+' sec integration'

wi,1
s1 = total(s,1,/preserve)
plot,s1,xrange = [0,256],xstyle=3,ystyle=3,psym=10,xtitle='ADC Bin',ytitle='Counts',title = title
if keyword_set(png) then makepng,'LT_spec',time=tr[0]


wi,2
s2 = total(s,2,/preserve)
hs2 =histbins(s2,xb,binsize=1)
plot,xb,hs2,psym=10,/ylog,yrange = minmax(hs2 >.1),ystyle=2,title=title,xtitle='Events per sample',ytitle='Counts'
pois = poisson()
pois.avg = total(s2) / (tr[1]-tr[0])
pois.h  = n_elements(s2)
xv = dgen()
oplot,xv,poisson(xv,param=pois),psym=10,col=6
for i=0,n_elements(hs2)-1 do print,xb[i],hs2[i],poisson(xb[i],param=pois)
printdat,pois,out=out
xyouts,.5,.85,/norm,strjoin(out+'!c')
if keyword_set(png) then makepng,'LT_poisson',time=tr[0]

wi,3
w = where(s2 ne 0)
wt = t[w]
dt = wt-shift(wt,1)
dt = dt[1:*]
hdt = histbins(dt,tbin,binsize=1)

w = where(s2 gt 1,nw)
if nw gt 0 then hdt[0] = nw
plot,tbin,hdt,psym=10,yrange=minmax(hdt) > .1,ystyle=2,/ylog,xstyle=2,title=title,xtitle='Delta time (sec)'
xv = dgen()
oplot,xv, exp(-xv * pois.avg) * total(s2)*pois.avg,color=6
if keyword_set(png) then  makepng,'LT_deltaT',time=tr[0]



end


mav_sep_gse_statistics
end