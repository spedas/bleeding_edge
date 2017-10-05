;+
;Function:
; h = histbins2d(x,y,xval,yval)
;Input:
;   x, y, random variables to bin.
;Output:
;   h  number of events within bin
;   xval, yval,  center locations of the bins.
;
;-

function histbins2d,x,y,xval,yval,xrange=xrange,yrange=yrange,xnbins=xnbins,ynbins=ynbins, $
  reverse=ri,nbins=nbins,xbinsize=xbinsize,ybinsize=ybinsize, $
  xlog = xlog, ylog=ylog, $
  flux=flux,stdev=flux_stdev,average=flux_average, $
  retbins=retbins,shift=shift,normalize=normal

xbins = histbins(x,xval,/retbins,range=xrange,nbins=xnbins,binsize=xbinsize,log=xlog,shift=shift)
ybins = histbins(y,yval,/retbins,range=yrange,nbins=ynbins,binsize=ybinsize,log=ylog,shift=shift)

wx = where(xbins ge xnbins or xbins lt 0,cx)
wy = where(ybins ge ynbins or ybins lt 0,cy)

bins = ybins*xnbins+xbins
if cx ne 0 then bins[wx]=-1
if cy ne 0 then bins[wy]=-1

nbins = long(xnbins) * ynbins

if keyword_set(retbins) then return,bins

h = histogram(bins,min=0,max=nbins-1,reverse=ri)

h = reform(h,xnbins,ynbins,/over)

if keyword_set(flux) then begin
  flux_average= replicate(fill_nan(flux[0]) ,size(/dimen,h) ) ; !values.f_nan * h
  flux_stdev = flux_average
  whne0 = where(h ne 0,nbins0)
  for b=0L,nbins0-1 do begin   ; loop over non zero bins
     i = whne0[b]
     ind = ri[ ri[i]: ri[i+1]-1 ]
     flux_average[i] = average(flux[ind],stdev=stdev)
     flux_stdev[i]  = stdev
  endfor
endif

if keyword_set(normal) then h=h/total(h)/xbinsize/ybinsize

return,h
end






; Test routines

if not keyword_set(n) then n = 1000
if not keyword_set(nbins) then nbins=50

dprint,/print_dtime,dlevel=dl,'Starting run ',n
xrange = [-1d,1d]
yrange = xrange
x = randomu(seed,n)*(xrange[1]-xrange[0])+xrange[0]
y = randomu(seed,n)*(yrange[1]-yrange[0])+yrange[0]
noise = .2 + .01*(x-.2)^2 +.005*(y-.5)^2
flux = exp(-((x^2+y^2))/.5)+noise*randomn(seed,n)
dprint,dlevel=dl,'Done with data generation'

h=histbins2d(x,y,xb,yb,flux=flux,xrange=xrange,yrange=yrange ,xnbins=nbins,ynbins=nbins,stdev=flux_stdev,average=flux_average)  ;,/shift)

dprint,dlevel=dl,'Done with flux binning'

!p.multi=[0,2,2] & !p.charsize=1.2
;specplot,xb,yb,h,/no_interp
options,lim,/no_interp,title="Number of Samples per bin"
specplot,xb,yb,h,lim=lim
if n le 20000 then oplot,x,y,psym=3
if n le 1000 then oplot,x,y,psym=1

lim2=lim
options,lim2,title = "Signal"
specplot,xb,yb,flux_average,lim=lim2

lim3=lim
options,lim3,title="Noise"
zlim,lim3,0,0,0
specplot,xb,yb,(flux_stdev^2)/flux_stdev,/no_interp,lim=lim3

lim3=lim
options,lim3,title="Signal/Noise"
zlim,lim3,0,0,0
specplot,xb,yb,(flux_average)/flux_stdev,/no_interp,lim=lim3

dprint,'Done with plot',dlevel=dl
wshow
end

