;;  @(#)fastorbgetdata.pro	1.2 12/15/94   Fast orbit display program

pro fastorbgetdata

@fastorb.cmn

; Define temporary read variables.
rdtime=0.0d0 & rdx=0.0d0 & rdy=0.0d0 & rdz=0.0d0 & rdvx=0.0d0 & rdvy=0.0d0  
rdvz=0.0d0 & rdlat=0.0d0 & rdlng=0.0d0 & rdalt=0.0d0 & rdmlat=0.0d0 
rdmlng=0.0d0 & rdmlt=0.0d0 & rdilat=0.0d0 & rdilng=0.0d0 & rdbx=0.0d0
rdby=0.0d0 & rdbz=0.0d0

if(tpmode eq 0l) then begin
  orbs=[satdescindx]
  norbs=1l
  ndata=satdesc(satdescindx).ndata
endif else begin
  getyear=satdesc(0).epochyr
  orbs=where((satdesc.epochyr eq getyear) and (satdesc.epochdoy eq tpdoy),norbs)
  if(min(orbs) gt 0l) then begin
    orbs=[orbs(0)-1,orbs]
    norbs=norbs+1
  endif
  ndata=long(total(satdesc(orbs).ndata))
endelse

if(putdata eq 0) then rdvec=replicate({orbvec},ndata) $
else rdvectp=replicate({orbvec},ndata)
ird=0l
openr,lun,/get_lun,curfile
for k=0,norbs-1 do begin
  i=orbs(k)
  delepoch=((((satdesc(i).epochyr-satdesc(orbs(0)).epochyr)*365l+ $
              (satdesc(i).epochdoy-satdesc(orbs(0)).epochdoy))*24l+ $
              (satdesc(i).epochhr-satdesc(orbs(0)).epochhr))*60l+ $
              (satdesc(i).epochmin-satdesc(orbs(0)).epochmin))*60l+ $
              (satdesc(i).epochsec-satdesc(orbs(0)).epochsec)
  point_lun,lun,satdesc(i).firstdata
  for j=0l,satdesc(i).ndata-1 do begin
    readf,lun,rdtime,rdx,rdy,rdz,rdvx,rdvy,rdvz,rdlat,rdlng,rdalt, $
                rdmlat,rdmlng,rdmlt,rdilat,rdilng,rdbx,rdby,rdbz
    if(putdata eq 0) then begin
      rdvec(ird).satptr=i
      rdvec(ird).time=rdtime+delepoch & rdvec(ird).x=rdx & rdvec(ird).y=rdy
      rdvec(ird).z=rdz & rdvec(ird).vx=rdvx & rdvec(ird).vy=rdvy
      rdvec(ird).vz=rdvz & rdvec(ird).lat=rdlat & rdvec(ird).lng=rdlng
      rdvec(ird).alt=rdalt & rdvec(ird).mlat=rdmlat & rdvec(ird).mlng=rdmlng
      rdvec(ird).mlt=rdmlt & rdvec(ird).ilat=rdilat & rdvec(ird).ilng=rdilng
      rdvec(ird).bx=rdbx & rdvec(ird).by=rdby & rdvec(ird).bz=rdbz
    endif else begin
      rdvectp(ird).satptr=i
      rdvectp(ird).time=rdtime+delepoch & rdvectp(ird).x=rdx & rdvectp(ird).y=rdy
      rdvectp(ird).z=rdz & rdvectp(ird).vx=rdvx & rdvectp(ird).vy=rdvy
      rdvectp(ird).vz=rdvz & rdvectp(ird).lat=rdlat & rdvectp(ird).lng=rdlng
      rdvectp(ird).alt=rdalt & rdvectp(ird).mlat=rdmlat & rdvectp(ird).mlng=rdmlng
      rdvectp(ird).mlt=rdmlt & rdvectp(ird).ilat=rdilat & rdvectp(ird).ilng=rdilng
      rdvectp(ird).bx=rdbx & rdvectp(ird).by=rdby & rdvectp(ird).bz=rdbz
    endelse
    ird=ird+1
  endfor
endfor
close,lun
free_lun,lun
; Calculate orbital position w.r.t ground station(s)
if(putdata eq 0) then fastorbstation
return
end
