

function find_mpeaks,xval=channels,dat,threshold=threshold,plotwindow=plotwindow,roiw=roiw,binsize=binsize,fitvalue=fitvalue,verbose=verbose

;peak={a:!values.d_nan,x0:!values.d_nan,s:!values.d_nan}
if not keyword_set(dat) then return,0
if ~keyword_set(channels) then channels = dindgen(n_elements(dat))
if n_elements(binsize) eq 0 then binsize=1

yran = 10.^floor(alog10( .5 > minmax(dat))+[0,1])
if n_elements(plotwindow) then begin
    plot,dat,xrange=[0,130],psym=1,/ylog,yrange=yran,/ystyle
endif
nsm = 3
if not keyword_set(roiw) then roiw=4

if not keyword_set(threshold) then threshold = max(dat)/10
sdat = (smooth(float(dat),nsm))
;oplot,sdat,col=6
deriv = sdat - shift(sdat,1)
;oplot,deriv,col=3
pks = where(deriv ge 0 and shift(deriv,-1) lt 0 and sdat gt threshold,np)
pks = reverse(pks)
dprint,pks,/phelp,dlevel=3,verbose=verbose
;ind = indgen(roiw)-roiw/2
;peaks=replicate(peak,np)
par = mgauss(num=np,binsize=binsize)
g = par.g[0]
for i=0,np-1 do begin
   w = where(abs( channels- pks[i]) lt roiw ,nw)
   d = dat[w]

   c = channels[w]
   if n_elements(plotwindow) then oplot,c,d,col= 1,psym=10
   t = total(d)
   avg = total(d*c)/t
   sdev = sqrt(total(d*(c-avg)^2)/t)
   g.a=t
   g.x0=avg
   g.s =sdev
   dprint,dlevel=3,verbose=verbose,i,g.a,g.x0,g.s,g.s*2.35,minmax(w)
   par.g[i] = g
endfor

if keyword_set(fitvalue)  then begin
   fit,channels,dat,param=par,names='g',verbose=verbose

endif


return,par
end

