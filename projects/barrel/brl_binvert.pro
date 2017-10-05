;+  invert bin(energy) relation to find energy(bin)
;
; INPUT: start is an initial estimate of bin value(s)
;        f is a temperature/detector dependent constant
;
; KEYWORD: none
;            
; OUTPUT: returns an object of the same type and dimension
;         as start; object contains energy value(s)
;
; METHOD: two iterations of Newton-Raphson to solve a
;        transcendental equation. A tricky part is the
;        argument for alog() can be negative, due to
;        electronics offsets (say bin 5 is 0 keV). Since only
;        brl_makeedges() calls, we assume some properties
;        of argument start. If start is a scalar, then
;        we're working on the 511keV line, so we won't have
;        start <= 0. For slo, we can have several early
;        start values negative. Force these to be NaN, and
;        proceed with calculations, then force these to
;        ascending negative values on return.
;
;        An accurate approach is to use complex numbers and
;        discard the imaginary part of the result. This gives
;        correct negative energy results for bin edges, but
;        doubles computational effort. It's not worth it.
;
; NOTES: brl_binvert() should be used only by brl_makeedges()
;
; REVISION HISTORY:
;       14Sep2013: first version
;       17Sep2013: added workaround for negative energy
;-
function brl_binvert,start,f
    badvals=where(start le 0.,cnt)
    if (cnt gt 0) then $
      start[badvals]=!values.f_nan

    iter1 = (start + f*start) / (1. + f*(1. + alog(start)))
    badvals=where(iter1 le 0,cnt)
    if (cnt gt 0) then $
      iter1[badvals]=!values.f_nan

    iter2 = (start + f*iter1) / (1. + f*(1. + alog(iter1)))
    badvals=where(iter2 le 0 or finite(iter2) eq 0,cnt)
    if (cnt gt 0) then $
      iter2[0:cnt-1]=findgen(cnt)+1-cnt

    return,iter2
end
