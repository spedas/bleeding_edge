function roundsig, x, sigfig=sig, uncertainty = unc

if keyword_set(unc) then begin
   return, unc*round(x/unc)
endif


if n_elements(sig) ne 1 then sig = 1

lx = x

neg = lx lt 0
wn = where(neg,nn)

wz = where(lx eq 0, nz)
if nz ne 0 then lx[wz] = 1.

lx = alog10(abs(lx))
e = floor(lx-sig)
f = lx-e

man = round(10^f)

if size(/type,x) eq 5 then ten=10.d else ten=10.

rx = man * ten^e

if nn ne 0 then rx[wn] = -rx[wn]
if nz ne 0 then rx[wz] = 0

return,rx
end

;  .r roundsig

