; crude routine to invert a function


function solve,y,xguess=x0,parameter=par  ,funct=funct

if ~keyword_set(funct) then funct = par.func
;y0 = call_function(funct,double(x0),param=par)
y0 = func(x0,param=par)
x1 = x0*1.001+ 1e-4                  ; crude,  and can fail

for i=0,20 do begin
;  y1 = call_function(funct,x1,param=par)
  y1 = func(x1,param=par)

  dydx = (y1-y0)/(x1-x0)
  dx = (y - y0)/dydx

  w= where((y0 eq y1) or (x1 eq x0),c)
  if c ne 0 then dx[w]=0

  y0=y1
  foo = x0
  x0 = x1
  x1=foo+dx
endfor

;w = where(abs(dx/x1) gt 1e-5,c)
;if c ne 0 then x1[w] = !values.f_nan


return, x1
end