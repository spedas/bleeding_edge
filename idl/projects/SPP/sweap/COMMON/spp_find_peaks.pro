

function spp_find_peaks,verbose=verbose,$
                        xval=xval,dat,$
                        threshold=threshold,$
                        plotwindow=plotwindow,$
                        roiw=roiw,$
                        nsmooth = nsm

  peak={a:!values.d_nan,x0:!values.d_nan,s:!values.d_nan}
  if not keyword_set(dat) then return,0 
  if n_elements(dat) eq 1 then return,peak
  channels = dindgen(n_elements(dat))
  
  yran = 10.^floor(alog10(minmax(dat,/pos) > .1 )+[0,1])
  if n_elements(plotwindow) then begin
     plot,dat,xrange=[0,130],psym=1,/ylog,yrange=yran
  endif
  if not keyword_set(nsm) then nsm = 3
  if not keyword_set(roiw) then roiw = 9
  
  if not keyword_set(threshold) then threshold = average(dat)
  sdat = (smooth(float(dat),nsm))
;oplot,sdat,col=6
  deriv = sdat - shift(sdat,1)
;oplot,deriv,col=3
  pks = where(deriv ge 0 and shift(deriv,-1) lt 0 and sdat gt threshold,np)
  dprint,verbose=verbose,dlevel=4,pks
  ind = indgen(roiw)-roiw/2
  if np eq 0 then return,peak
  peaks=replicate(peak,np)
  for i=0,np-1 do begin
     d = dat[ind+pks[i]]
     c = channels[ind+pks[i]]
     if n_elements(plotwindow) then oplot,c,d,col= 1,psym=10
     t = total(d)
     avg = total(d*c)/t
     sdev = sqrt(total(d*(c-avg)^2)/t)
     peak.a=t
     peak.x0=avg
     peak.s=sdev
     peaks[i]=peak
     dprint,verbose=verbose,dlevel=5,i,peak.a,peak.x0,peak.s,peak.s*2.35
  endfor
  
  return,peaks

end

