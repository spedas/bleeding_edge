;;  @(#)fastorbstation.pro	1.2 12/15/94   Fast orbit display program

pro fastorbstation
; IDL procedure to calculate look angles and ranges to satellite from various 
; ground stations.  Call after reading in a new set of orbital vectors.

@fastorb.cmn
@fastorbdisp.cmn

re=6378.14
; Get status for each position.
stat=intarr(n_elements(rdvec))
statone=where(abs(rdvec.ilat) ge azonloc(rdvec.mlt,q,/lat,/deg),nstatone)
if(nstatone gt 0) then stat(statone)=1
gstatlook=fltarr(3,n_elements(rdvec),n_elements(tmstation))
for i=0,n_elements(tmstation)-1 do begin
; Next statement replaced because (x,y,z) is in useless GEI.  Approx by
; footpoint traced to altitude.
;  rgsfast=[[rdvec.x-re*tmstation(i).unit(0)],[rdvec.y-re*tmstation(i).unit(1)], $
;           [rdvec.z-re*tmstation(i).unit(2)]]
  gstatlook(*,*,i)=transpose( $
           [[(re+rdvec.alt)*(cos(rdvec.lat*!dtor)*cos(rdvec.lng*!dtor))-re*tmstation(i).unit(0)], $
           [(re+rdvec.alt)*(cos(rdvec.lat*!dtor)*sin(rdvec.lng*!dtor))-re*tmstation(i).unit(1)], $
           [(re+rdvec.alt)*sin(rdvec.lat*!dtor)-re*tmstation(i).unit(2)]])
  range=sqrt(total(gstatlook(*,*,i)^2,1))
  elev=90-!radeg*acos(transpose(gstatlook(*,*,i))#tmstation(i).unit/range)
  gstatlook(0,*,i)=range
  gstatlook(1,*,i)=elev
  gstatlook(2,*,i)=0.0
  stattwo=where(elev ge tmstation(i).elevmin,nstattwo)
;  if(i eq 0) then begin
;    statrange=replicate(9e9,n_elements(range))
;    statelev=statrange
;    statstat=lonarr(n_elements(range))
;  endif
  if(nstattwo gt 0l) then begin
    stat(stattwo)=stat(stattwo) or 2
;    ind=where(range(stattwo) lt statrange(stattwo),nind)
;    if(nind gt 0) then begin
;      statrange(stattwo(ind))=range(stattwo(ind))
;      statelev(stattwo(ind))=elev(stattwo(ind))
;      statstat(stattwo(ind))=i
;    endif
  endif
endfor

return
end
