pro pf,pp,_extra=ex,dimensions=dimensions
if n_elements(dimensions) ne 0  && dimensions eq 2 then begin
  xv = dgen(/xrange)
  yv = dgen(/yrange)
  xv2 = xv # replicate(1,n_elements(yv))
  yv2 = replicate(1,n_elements(xv)) # yv
  f = func(xv2,yv2,param=pp)
  contour,f,xv2,yv2,_extra=ex,/over
  return
endif
xv = dgen(600)
oplot,xv,func(xv,param=pp),_extra=ex
end
