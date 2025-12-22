;	@(#)spread.pro	1.2	03/22/99
;
; returns max(X) - min(X), where X can be median-filtered with a
;                  window of width WINDOW. 
;
function spread, x, window, mindex = mindex, maxdex = maxdex

if not defined(window) then window = 1

fin = where(finite(x), nfin)
if (window lt 1) or (nfin lt window) then begin
    message, 'Not enough finite values...', /continue
    return, !values.f_nan
endif

if window eq 1 then begin
    big = max(x[fin], min = small, maxdex)
    mindex = where(x[fin] eq small)
endif else begin
    medx = median(x[fin], window)
    big = max(medx, maxdex, min = small)
    mindex = where(medx eq small)
endelse

return, big - small
end

