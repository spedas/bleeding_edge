function padfftarray,x,pad
n=n_elements(x)
if not keyword_set(pad) then return,x
   pd = abs(round(pad))
   if pad lt 0 then begin
endif

if n lt 2l^pd then return,x

f = alog(n)/alog(2d)
b = floor(f)
e = 2^(f-b)
e = ceil(e*2^pd)
n2 = 2l^(b-pd) * e
x2 = fltarr(n2)
x2[0:n-1] = x
dn = n2-n
if dn gt 0 then $
   x2[n:n2-1] = dgen(dn,range=[x2[n-1],x2[0]])

;help,x,x2

return,x2
end

