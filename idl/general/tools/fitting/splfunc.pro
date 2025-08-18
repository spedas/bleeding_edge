;+
;FUNCTION splfunc
;USAGE:
;  p = splfunc(x_old,y_old,/set)
;  y = splfunc(x_new,param=p)
;-

function splfunc, xs,ys, param=p,xlog=xlog,ylog=ylog,lininterp=lininterp,set=set

common splfunc_com,param

xl = keyword_set(xlog)
yl = keyword_set(ylog)
li = keyword_set(lininterp)

if size(/type,p) eq 8 then param=p

if not keyword_set(param) or keyword_set(set) then begin
   w = where(finite(xs) and finite(ys))
   xps = float(xl ? alog10(xs[w]) : xs[w])
   yps = double(yl ? alog10(ys[w]) : ys[w])
   s = sort(xps)
   xps=xps[s]
   yps=yps[s]
;   interp_gap,xps,yps
   param = {func:'splfunc', x: xps,  y: yps, xlog:xl, ylog:yl, li:li}
endif

p = param

if keyword_set(set) then return,p

if p.li then f= interp(p.y,p.x,p.xlog ? alog10(xs) : xs)   else begin
   ys2 = spl_init(p.x,p.y)
   f = spl_interp(p.x,p.y,ys2,p.xlog ? alog10(xs) : xs)
endelse


return, p.ylog ? 10.^f : f
end


