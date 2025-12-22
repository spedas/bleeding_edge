;	@(#)ang_from_a2b_about_s.pro	1.2	05/08/02
function ang_from_a2b_about_s, a, b, s

;
; returns the angle between the Nx3 vectors A and B, rotating from
; A to B around the axis S in a right-handed sense. Takes the
; perpendicular projections of A and B, if they are not already in the
; plane perpendicular to S.
;

sa = size(a)
sb = size(b)
ss = size(s)

ok = (sa[0] eq 2) and (sa[2] eq 3) and (sb[0] eq 2) and (sb[2] eq 3)

if not ok then begin
    message, 'not all N x 3 vectors...',/continue
    return,!values.f_nan
endif

ap = normn3(crossn3(s, crossn3(a, s)))
bp = normn3(crossn3(s, crossn3(b, s)))

cosang = total(ap*bp, 2)
axbp = crossn3(ap, bp)
sinang = sqrt(total(axbp^2, 2))
flip = where(total(axbp * s, 2) lt 0, nflip)
if nflip gt 0 then begin
    sinang[flip] = -sinang[flip]
endif
ang = unwrap(atan(sinang, cosang))

return,ang
end
