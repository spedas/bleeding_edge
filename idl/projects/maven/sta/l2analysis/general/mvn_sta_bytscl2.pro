;+
;CMF bytscl routine that includes a bottom color bar indice keyword.
;
;INPUTS:
;data: array to be scaled.
;
;minv, maxv: min and max data values to be considered. Any values below min are set to min; any above max are set to max.
;
;top, bottom: top and bottom color bar indices to be used. MAx range is 0 - 255 (the default). Top > bottom.
;
;Routine ignores NaNs in data.
;
;
;NOTES:
;data must contain at least two real numbers.
;
;
;.r /Users/cmfowler/IDL/my_routines/mvn_sta_bytscl2.pro
;-
;

function mvn_sta_bytscl2, data, minv=minv, maxv=maxv, top=top, bottom=bottom, success=success

rtot = total(finite(data),/nan)  ;total number of real numbers in data

ireal = where(finite(data) eq 1, nnans)  ;find real numbers

if rtot lt 2 then begin
  print, "There are not 2+ real numbers in data."
  success=0
  retall
endif

;Set numbers < min to min
if not keyword_set(minv) then minv = min(data,/nan)
im = where(data lt minv, nim)
if nim gt 0 then data[im] = minv


;Set numbers > max to max
if not keyword_set(maxv) then maxv = max(data,/nan)
im = where(data gt maxv, nim)
if nim gt 0 then data[im] = maxv


if not keyword_set(top) then top = 255.
if not keyword_set(bottom) then bottom = 0.

;Scale:
nvals = top-bottom ;number of colorbar values
delv = (maxv-minv)/nvals  ;the size of each resized bin, to have nvals total

;Use empty 
data2 = ((data-minv)/delv) + bottom   ;don't use floor just yet, as it screws up nans

data2[ireal] = floor(data2[ireal])  ;just floor the real numbers

;data2 = floor((data-minv)/delv) + bottom  ;this doesn't work when nans are present - floor screws them up

success=1

return, data2

end

