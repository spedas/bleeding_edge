;20170804 Ali
;creates 2D maps of pickup ion d2m ratios
;inputs:
; krv: positions (xyz)
; knn: d2m ratios
; dim: map dimensions
;output:
; map2d: 2d map

function mvn_pui_2d_map,krv,knn,dim,sep=sep

finswi=where(finite(knn),/null,fincount)
if fincount eq 0 then return,!values.f_nan

if keyword_set(sep) then begin
  binrx0=floor(krv[0,*]/1e6) ;position binning (1000 km)
  binyz0=floor(sqrt(total(krv[1:2,*]^2,1))/1e6)
endif else begin
  binrx0=floor(krv[*,*,*,*,*,0]/1e6) ;position binning (1000 km)
  binyz0=floor(sqrt(total(krv[*,*,*,*,*,1:2]^2,6))/1e6)
endelse
knn2=knn[finswi]
binrx=binrx0[finswi]
binyz=binyz0[finswi]
binrx[where((binrx lt 0) or (binrx gt dim-1),/null)]=-1 ;if outside the binning limit, put it in the last bin
binyz[where((binyz lt 0) or (binyz gt dim-1),/null)]=-1

d2mr=replicate(0.,[dim,dim])
d2mn=d2mr
for i=0,fincount-1 do begin
  d2mr[binrx[i],binyz[i]]+=knn2[i]
  d2mn[binrx[i],binyz[i]]+=1.
endfor

map2d=d2mr/d2mn
return,map2d

end