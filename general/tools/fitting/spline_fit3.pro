;+
;FUNCTION splinef
;USAGE:
;  y_new = spline_fit3(x_new,x_old,y_old)
;-

function spline_fit3, xt,xs,ys, param=p, xlog=xlog, ylog=ylog

if keyword_set(xs) then begin
   xlog=keyword_set(xlog)
   ylog=keyword_set(ylog)
   xs0 = xlog ? alog10(xs) : xs
   ys0 = ylog ? alog10(ys) : ys
   ys2= spl_init(xs0,ys0)
   p = {func:'spline_fit3',xs:float(xs0),ys:double(ys0),ys2:float(ys2), xlog:xlog, ylog:ylog, recalc:1}
endif

if p.recalc then p.ys2 = spl_init(p.xs,p.ys)
f = spl_interp(p.xs,p.ys,p.ys2,  p.xlog ? alog10(xt) : xt)

return,p.ylog ? 10^f : f
end


