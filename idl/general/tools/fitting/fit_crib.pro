;+
; Crib sheet to show how to use fit routine.

;-


n=5000
mean=.95d
sigma=.3d
printdat,n,mean,sigma

xr = (randomn(seed,n)*sigma)+mean

dprint,'average=' , average(xr,stdev=stdev),'    StDev=',stdev

if 0 then begin
binsize = 1
yb = histbins(xr,bins=binsize,xb,range=[-10,10])

plot,xb,yb,psym=10,/ylog,yrange=[.5,n/sigma];,xrange=[-3,3]*sigma+mean

printdat,xb,yb
dyb = sqrt(yb+.1)

plotxyerr,xb,yb,xb*0,dyb,/overplot

;stop

p1 = mgauss()   ;  get structure
p1.g.a = n      ; initialize structure
p1.g.s=.5
fit,xb,yb,dy=dyb,param=p1,verbose=verbose
pf,p1,color=2
oplot,xb,func(xb,param=p1),/psym,color=2
printdat,p1
;stop


p2 = mgauss()
p2.binsize=binsize
p2.g.a = n
fit,xb,yb,dy=dyb,param=p2,verbose=verbose
pf,p2,color=6,psym=10
oplot,xb,func(xb,param=p2),psym=4,color=6
printdat,p1,p2
;stop
endif

; Build extra gaussian peaks
xr = [xr,(randomn(seed,1000)*.25)-4.5]
xr = [xr,(randomn(seed,2000)*.15)+5.5]

binsize=.25d
shift = 1

yb = histbins(xr,bins=binsize,shift=shift,xb,range=range) / binsize

plot,xb,yb,psym=10,yrange=[.5,n/sigma],/ylog;,xrange=[-3,3]*sigma+mean

printdat,xb,yb
dyb = sqrt(yb+.1)
p3 = mgauss(n=3)
p3.g.x0 = [-5,0,5]
p3.g.s=.3
p3.g.a = 2000


dyb = sqrt(yb+.1)
plotxyerr,/overplot,xb,yb,xb*0,dyb
p_limits=0
fit , xb,yb,dy=dyb, param=p3 , p_limits = p_limits   ;,/logfit
p3a=p3
pf,p3,color=4
p_limits[0].bkg = 0.          ; set allowable ranges
p_limits[0].g.s = 0.1          ; set allowable range
p_limits[1].g.s = 5
p_limits[0].g.a = 0.1
p_limits[0].g.x0 = -10
p_limits[1].g.x0 = 10
;dyb = sqrt(func(xb,param=p3) > 0.01)
fit , xb,yb,dy=dyb, param=p3 , p_limits = p_limits    ;,/logfit
pf,p3,color=2
;printdat,p3,nstr=3


p4=p3
p4.binsize=binsize
p4.shift = shift
fit , xb,yb,dy=dyb, param=p4
pf,p4,color=6,psym=10
;printdat,p4,nstr=3

printdat,p3.g.s
printdat,p4.g.s

end