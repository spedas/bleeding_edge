pro correlate_vect,x,y,n1,a=a,b=b,r=r,c=c

nan=!values.f_nan


if keyword_set(n1) then begin
  ok = finite(x) and finite(y)
  w= where(smooth(ok,n1) eq 0,nw)
  xavg = smooth(x,n1,/nan,/edge_truncate)
  x2avg = smooth(x^2,n1,/nan,/edge_truncate)
  yavg = smooth(y,n1,/nan,/edge_truncate)
  y2avg = smooth(y^2,n1,/nan,/edge_truncate)
  xyavg = smooth(x*y,n1,/nan,/edge_truncate)
  if nw ne 0 then begin
    xavg[w]=nan
    x2avg[w]=nan
    yavg[w]=nan
    y2avg[w]=nan
    xyavg[w]=nan
  endif
endif else begin
  xavg = average(x,/nan)
  x2avg = average(x^2,/nan)
  yavg = average(y,/nan)
  y2avg = average(y^2,/nan)
  xyavg = average(x*y,/nan)
endelse

sx2 = x2avg -xavg^2
a = (yavg*x2avg - xavg*xyavg)/sx2
sxy = (xyavg-xavg*yavg)
b = sxy/sx2
r = sxy/sqrt(sx2*(y2avg-yavg^2))
c = sxy/x2avg


return
end
