;+
;PROCEDURE:
;  find_orbits
;
;PURPOSE:
;  Procedure returns indices of perigees and apogees. Apsides are determined as
;  the local minima and maxima based on x,y,z orbit coordinates only. Orbit sets
;  are split into single orbits by node crossings. If nodes are close to or at local
;  minima then cutoffs are shifted to meet local minima and maxima conditions.
;  For orbits sets, arcs that are ascending or decsending only determination of
;  first and last apsides is based on average orbit length and can be off by orbit
;  variation. For a partial orbit this method works only if apside is well
;  insight the arc. This indicated by message 'Orbit is not complete, apogee might
;  not be true'.
;  
;INPUT
;  x
;  y   Components preferrably in GEI
;  z
;
;KEYWORDS:
;  info: if set some details are printed
;  tolerance: Flag to pick orbit variation, period perturbations make orbit size
;             varying from one orbit to another, and
;             different time resolutions might call for different tolerances
;             (orbit length/[3.,10.]) <[100,8]
;             tolerance=3  picks smaller value (low resolution)
;             tolerance>3 picks higher value  (high resolution)
;             This has some heritage
;  halt:      flag to stop
;  test:      selects three test cases (=1,=2,=3)
;  nostop:    flags to not stop if different orbits sizes cause
;             stop if max(abs(diff2),ibad) gt round(median(abs(dstart-astart))/10.)
;             should not be set for maneuver calculation but is helpful when
;             all statevectors from archive are put into one structure and then
;             processed for visualization such as in plot_elements, helps to keep
;             automation as orbits go into final size
;OUTPUT:
;  ind_pg  ; index of perigee passes
;  ind_ap  ; index of apogee passes
;  ind_asnode: index of ascending node
;  orbitnumber: orbit count starts at 1, increments at ascending node
;  norbits:   numbers of orbits
;  ag,pg :    flag to indicate which one is first
;
;AUTHOR:
;  S. Frey, UCB, SSL
;-
pro find_orbits,x,y,z,ind_pg,ind_ag,info=info,ind_asnode=ind_asnode,$
             ind_dsnode=ind_dsnode,orbitnumber=orbitnumber,$
             tolerance=tolerance,norbits=norbits,ag=ag,pg=pg,$
             test=test,halt=halt,nostop=nostop,re=re

tolerance0=[100 ,8]    ;05-27-04
tol_def=tolerance0
if not keyword_set(test) then test=0 else test=test

plot_okay=strupcase(!d.name) eq 'X'
if not keyword_set(re) then re=6378.
last=n_elements(x)-1

nasc=0 & nas=0
ndsc=0 & nds=0
nn=n_elements(x)
rr=sqrt(x^2+y^2+z^2)
ind_asnode=-1
ind_dsnode=-1


if last lt 10 then begin
 tmp=min(rr,ind_pg)
 tmp=max(rr,ind_ag)
 orbitnumber=0
 norbits=0
 if keyword_set(halt) then stop
 return
endif 

dzz=rr-shift(rr,1)
;dzz=z-shift(z,1)  ;is not  good because of aper drift
dzz=dzz[1:*]
asce=where(dzz ge 0,na)	;take only 'ascending' part of orbit
astart=nn	& dstart=astart 
aorb=0 &  dorb=0

if na ne 0 then begin 
 find_interval,asce,astart,aend
 nas=n_elements(astart)
 ;nae=n_elements(aend)    ;redundant
 nasc=aend-astart
 iasc=where(nasc gt 10,nas)  ;10 is a bit arbitrary but same limit as for rr
 
 if nas ge 2 then aorb=max(astart-shift(astart,1))
 if nas ne 0 then begin
  aend=aend[iasc]
  astart=astart[iasc]  
 endif
 nas=n_elements(astart)
endif

dsce=where(dzz lt 0,nd)	;now take descending part of orbit
if nd ne 0 then begin 
 find_interval,dsce,dstart,dend
 nds=n_elements(dstart)
 ;nde=n_elements(dend)   ;redundan
 ndsc=dend-dstart
 idsc=where(ndsc gt 10,nds)  ;see iasc
 if nds ge 2 then dorb=max(dstart-shift(dstart,1))
 if nds ne 0 then begin
  dend=dend[idsc]
  dstart=dstart[idsc]  
 endif
 nds=n_elements(dstart)
endif

norb=(aorb > dorb) 
if norb eq 0 then norb=last

if (nas +nds) eq 1 then begin
 pgtmp=min(rr,ind_pg)
 agtmp=max(rr,ind_ag)
 norbits=0
 orbitnumber=0     ;10-18-05
 if ind_pg eq 0 and ind_ag ne (nn-1) then ag=1 else ag=0
 if ind_pg eq (nn-1) and ind_ag ne 0 then pg=1 else pg=0
 if keyword_set(info) then print,'Apsides are not real, orbit part too is  short.'
 if keyword_set(halt) then stop
 if keyword_set(info) then  stop
 return
endif

;always start with first interval
case 1 of 
astart[0] lt dstart[0] : begin
           cnt=nas
           istart=astart
           iend=aend
           ;iend=dend
           if keyword_set(info) then begin 
              print,'astart,aend '
              print,astart,aend
           endif   
          end
astart[0] gt dstart[0] : begin
           cnt=nds
           istart=dstart
           iend=dend 
           ;iend=aend   
           if keyword_set(info) then begin 
              print,'dstart ',dstart
              print,'dend ',dend
           endif   
          end

endcase

if (nas+nds) ge 4 then tolerance0=round(median(abs(dstart-astart))/[3.,10.]) 
;if (nas+nds) eq 2 then tolerance0=round(abs(dstart[0]-astart[0])/[3.,10.])
if (nas+nds) eq 2 or (nas+nds) eq 3 then tolerance0=round(abs(dstart[0]-astart[0])/[3.,10.])
if (nas+nds) lt 2 then tolerance0=round(iend[0]-istart[0]/[3.,10.])
if total(tolerance0) eq 0 then tolerance0=round(max(abs(dstart-astart))/[3.,10.])
tolerance0=tolerance0 < tol_def	;[100 ,8]

if not keyword_set(tolerance) then tolerance=tolerance0[1] else begin   ;was [0]
 if tolerance eq 3 then  low=1 else low =0
 if tolerance gt 3 then  high=1 else high=0
 if (low) then tolerance=tolerance0[1]
 if (high) then tolerance=tolerance0[0]
endelse

if  tolerance gt norb/4. then begin
  print,'Something is odd, tolerance gt norb/4. This needs a fix.'
  print,'tolerance,dorb,aorb',tolerance,dorb,aorb
  print,'check shifting idz'
  tolerance=round(iend[0]-istart[0]/[10.])	
endif  

pg_tolerance = tolerance
ag_tolerance = tolerance

if n_elements(istart) ge 2 then begin  ;need 2 or more to handle median
 ;istart=dstart
 ;iend=dend 
 idel=median(((istart-shift(istart,1))[1:*]/4))
 cnt=nds
endif else idel=norb/4.	;0 

;get ascending nodes
dzz1=z-shift(z,1)
dzz1=dzz1[1:*]
asce1=where(dzz1 ge 0,na1)
if na1 ne 0 then begin
 find_interval,asce1,a1start,a1end
 cnt1=n_elements(a1start)
 ias=lonarr(cnt1)
 for i=0,cnt1-1 do  begin
       dummy=min(abs(z[a1start[i]:a1end[i]]-0.d), index)
       ias[i]=index    
 endfor       
 ind_asnode=ias+a1start
endif
;get descending nodes

desce1=where(dzz1 lt 0,nd1)
if nd1 ne 0 then begin
 find_interval,desce1,d1start,d1end
 cnt2=n_elements(d1start)
 ids=lonarr(cnt2)
 for i=0,cnt2-1 do  begin
       dummy=min(abs(z[d1start[i]:d1end[i]]-0.d), index)
       ids[i]=index    
 endfor       
 ind_dsnode=ids+d1start
endif

idz=istart
cnti=n_elements(istart)
;check for idz's too close to rp or ap
;should be eindeutig for data le 1 orbit
;should deal with first /last Schnipple

good=0
if not good then begin
idel2=(idel>20)
if (cnti ge 2)  then begin
 yes=0
 for q=1,cnti-1 do $
  if (rr[istart[q]] ge rr[(istart[q]-idel2) >0] and rr[istart[q]] ge rr[(istart[q]+idel2)<(nn-1)]) or $
    (rr[istart[q]] le rr[(istart[q]-idel2) >0] and rr[istart[q]] le rr[(istart[q]+idel2)<(nn-1)]) then yes=yes+1
        
  if yes gt 0 then begin
 
    idz=(istart+idel2)<(nn-1)
    
    ;if abs(idz[0]-mins[0]) gt idel2 or  abs(idz[0]-maxs[0]) lt idel2 then idz[0]=0
  endif  
endif

;ilength=where((iend-istart) ge idel,in)
;if (cnt1 ne 0 or cnt2 ne 0) and in ne 0 then idz=(istart[ilength]+idel)<(nn-1)

cnt=n_elements(idz)
;allow a gap of 6 points 
orbits=nas<nds
if nas eq 2 and nds eq 2 then orbits=1 
if orbits eq 2 and last/float(norb) lt 2 then orbits=1

if keyword_set(info) and !d.name eq 'X' then begin
 if plot_okay then plot,rr
 if plot_okay then plots,idz,rr[idz],psym=4,col=120
 print,'orbits=',orbits
endif 

if cnt gt 2 then begin
 sft=idz-shift(idz,1)
 tmp=where(sft ge 0 and sft le tolerance,iii)
 if iii ne 0 then begin
   for k=0,iii-1 do begin
    tmp2=max([rr[tmp[k]-1],rr[tmp[k]]],jjj)
    idz[tmp[k]-1+jjj]=-1
   endfor
    tmp2=where(idz ne -1,cnt)
    if cnt ne 0 then idz=idz[tmp2]
 endif
 
endif

if orbits gt 1 or n_elements(istart) ge 2 then  begin   ;07-12-04
 if idz[cnt-1] ne (nn-1) then idz=[idz,nn]
 if idz[0] ne 0 then idz=[0,idz]
endif 

cnt=n_elements(idz)
if keyword_set(info)  and !d.name eq 'X' then plots,idz,rr[idz],psym=4,col=250

ind_pg=lonarr((cnt-1)>1)-1   ;minimum is one element 041305
ind_ag=ind_pg

for i=0,cnt-2 do $
  ind_pg[i]=idz[i]+(where(rr[idz[i]:idz[i+1]-1] eq min(rr[idz[i]:idz[i+1]-1])))[0]

ind=where(ind_pg ne -1,npg)  
if npg ne 0 then ind_pg=ind_pg[ind]  

for i=0,cnt-2 do $
  ind_ag[i]=idz[i]+(where(rr[idz[i]:idz[i+1]-1] eq max(rr[idz[i]:idz[i+1]-1])))[0]

ind=where(ind_ag ne -1,nag)  
if nag ne 0 then ind_ag=ind_ag[ind] 
;look whether the determined minimum/maximum of
;an incomplete orbit (first or last piece of arrays is indeed 
if dorb eq 0 then dorb=norb
if nas eq 2 and nds eq 2 and nn/dorb ge 2 then orbits=2
if nas eq 2 and nds eq 2 and nn/dorb lt 2 then orbits=1  ;12-11-06 else

if keyword_set(halt) then stop
pg0=ind_pg
ag0=ind_ag
if orbits eq 2 and (last/float(dorb)) lt 2 then orbits=1	;12-13-06
if keyword_set(info)  then begin

 if !d.name eq 'X' then begin
   plots,ind_pg,rr[ind_pg],psym=2
   plots,ind_ag,rr[ind_ag],psym=7
 endif
 print,'  raw ind_pg ',ind_pg
 print,'  raw ind_ag ',ind_ag
endif

if keyword_set(halt) then stop 

if orbits le 1 then begin     ;01-25-06
 l= n_elements(rr)-1 
 rrl=[x[l],y[l],z[l]]
 minpg=min(rr,ind_pg0)
 maxag=max(rr,ind_ag0)
 dorb0=2*abs(ind_pg0-ind_ag0) 
 ;if dorb0 eq l and (maxag-minpg)/re le 6. then begin
 if dorb0 eq l and n_elements(idz) le 1 and  keyword_set(info)   then begin
  print,'Not enough data to determine Apsides'
  return
 endif
 ;pick the one in the middle of arc     ;12-14-06
; if dorb0 lt (l-tolerance0[1]) and (maxag-minpg)/re le 6. then begin
 if dorb0 lt (l-tolerance0[1]) and n_elements(idz) le 1 then begin
  if rr[0] gt minpg and rr[l] gt minpg then ind_pg=ind_pg0
  if rr[0] lt maxag and rr[l] lt maxag then ind_ag=ind_ag0
  if keyword_set(halt) then stop 
  print,' found one'
  return
 endif
  
 get0=0
 if dorb0 gt (l+tolerance0[1]) then get0=1
 if (abs(dorb0-l) le  tolerance0[1]) then begin
 if ind_pg0 gt tolerance and ind_pg0 lt (l-tolerance) and $
    ind_ag0 gt tolerance and ind_ag0 lt (l-tolerance) or  $
    abs((ind_pg0<ind_ag0)+dorb0-l) le tolerance0[0]   or  $
    abs((ind_pg0>ind_ag0)-dorb0)   le tolerance0[0] then get0=1 else stop ;TBD to remove
 endif  
 if get0 then begin
   orbits = 0
     ind_pg=ind_pg0
     ind_ag=ind_ag0
     nag=1
     npg=1
  endif 
  dorb=dorb0
  
endif    ;orbits le 1 

if keyword_set(halt) then stop 
if orbits eq 1 then begin
;rough throw-out       added 07-21-04
 ind3=where(rr[pg0] lt (2*re),cnt3)
 ind4=where(rr[ag0] gt (max(rr)-re),cnt4)
 if cnt3 ne 0 then ind_pg=pg0[ind3]
 if cnt4 ne 0 then ind_ag=ag0[ind4]
 npg=n_elements(ind_pg)
 nag=n_elements(ind_ag)

 if ind_pg[npg-1] eq ind_ag[nag-1] then begin
  if rr[ind_pg[npg-2]] lt rr[ind_pg[npg-1]] then ind_pg=ind_pg[0:npg-2] $
         else ind_ag=ind_ag[0:nag-2]         

  npg=n_elements(ind_pg)
  nag=n_elements(ind_ag)
 endif

if keyword_set(halt) then stop 
if npg eq 1 or nag eq 1 and npg+nag le 2 then begin  ; orbits eq 1 
 case 1 of
  ind_pg[0] eq 0      and abs((nn-1)-2*ind_ag[0]) le 1: ind_pg=[ind_pg,(2*ind_ag)<(nn-1)]
  ind_ag[0] eq 0      and abs((nn-1)-2*ind_pg[0]) le 1: ind_ag=[ind_ag,(2*ind_pg)<(nn-1)]
  ind_ag[0] eq (nn-1) and abs((nn-1)-2*ind_pg[0]) le 1: ind_ag=[0,ind_ag]
  ind_pg[0] eq (nn-1) and abs((nn-1)-2*ind_ag[0]) le 1: ind_pg=[0,ind_pg]
  
  else: begin
         tmp=min(rr[ind_pg],imin)
         tmp=max(rr[ind_ag],imax)
         ind_pg=ind_pg[imin]
         ind_ag=ind_ag[imax]
        end
 endcase
 
 npg=n_elements(ind_pg)
 nag=n_elements(ind_ag)
endif else begin                   ; end of old orbits eq 1

 if tolerance eq 0 then tolerance=tolerance[1]

  npg=n_elements(ind_pg)
  nag=n_elements(ind_ag)
  diff1=ind_pg-shift(ind_pg,1)
  diff2=ind_ag-shift(ind_ag,1)
  if keyword_set(halt) then stop
  if (npg+nag) ne (nas+nds) or abs(nas-nds) eq 2 then begin
    idiff1=where(abs(abs(diff1)-dorb) gt 2*tolerance,cn1) 
    if cn1 ne 0 then begin
     for i=0,cn1-2,2 do begin
      imax=max([rr[ind_pg[idiff1[i]]],rr[ind_pg[idiff1[i]+1]]],ii)
      ind_pg[idiff1[i]+ii]=-1      
    endfor
   endif
   idiff2=where(abs(abs(diff2)-dorb) gt 2*tolerance,cn2)  
    if cn2 ne 0 then begin
    for i=0,cn2-2,2 do begin
      imin=min([rr[ind_ag[idiff2[i]]],rr[ind_ag[idiff2[i]+1]]],ii)
      ind_ag[idiff2[i]+ii]=-1      
    endfor
   endif
   
   itmp=where(ind_pg ne -1,npg)
   if npg ne 0 then ind_pg=ind_pg[itmp]
   itmp=where(ind_ag ne -1,nag)
   if nag ne 0 then ind_ag=ind_ag[itmp]
    if keyword_set(halt) then stop
  endif
  if keyword_set(halt) then stop
     
  if npg ge 2 then if  abs(abs(ind_pg[0]-ind_pg[1])-dorb) gt tolerance0[1] then begin        
       imax=max([rr[ind_pg[0]],rr[ind_pg[1]]],ii)
       ind_pg[0+ii]=-1      
       itmp=where(ind_pg ne -1,npg)
       if npg ne 0 then ind_pg=ind_pg[itmp]
  endif
   if keyword_set(halt) then stop   
  if nag ge 2 then if abs(abs(ind_ag[0]-ind_ag[1])-dorb) gt tolerance0[1] then begin        
       imin=min([rr[ind_ag[0]],rr[ind_ag[1]]],ii)
       ind_ag[0+ii]=-1      
       itmp=where(ind_ag ne -1,nag)
       if nag ne 0 then ind_ag=ind_ag[itmp]
  endif
   if keyword_set(halt) then stop
   
 
 endelse
 npg=n_elements(ind_pg)
 nag=n_elements(ind_ag)
endif
npg=n_elements(ind_pg)
nag=n_elements(ind_ag)
if keyword_set(halt) then stop

if orbits gt 1 then begin
 if npg ge 2 then  pgorb=ind_pg-shift(ind_pg,1) 
 if nag ge 2 then  agorb=ind_ag-shift(ind_ag,1)
 if npg ge 2 then  pgorb0=median(pgorb[1:*])
 if nag ge 2 then  agorb0=median(agorb[1:*])
 if npg gt 4 then begin
  ;08-03-04 aussreisser von wirklichen maxima
  temp=abs(pgorb[2:npg-2]-shift(pgorb[2:npg-2],1))
  med=median(temp)
  men=mean(temp)
  if abs(med-men) gt tolerance then $
  pg_tolerance = 2*(med >1)		;avoid 0
  itmp=where(temp le pg_tolerance,cnt)
  if cnt ne 0 then pgorb0=pgorb[itmp[0]+2]
  tolerance=tolerance>pg_tolerance
 endif 
 if npg eq 3 then  pg_tolerance=abs(pgorb[1]-pgorb[2])  
 if nag eq 3 then  ag_tolerance=abs(agorb[1]-agorb[2])  

 if nag gt 4 then begin  
  ;Aussreisser 08-03-04
  temp=abs(agorb[2:nag-2]-shift(agorb[2:nag-2],1))
  med=median(temp)
  men=mean(temp)
  if abs(med-men) gt tolerance then $
  ag_tolerance = 2*(med >1)		;avoid 0
  
  itmp=where(temp le ag_tolerance,cnt) 
  if cnt ne 0 then agorb0=agorb[itmp[0]+2]
  tolerance=tolerance>ag_tolerance
 endif

 if keyword_set(info) then begin 
   print,' first and last entries, before removing wrong ones'
   print,ind_pg[[0,npg-1]]
   print,ind_ag[[0,nag-1]]
 endif
if keyword_set(halt) then stop
;next steps rely on average estimates of orbit change hence there is still a wrong one possible
  if npg gt 2 then begin
 
   if abs(ind_pg[npg-1]-ind_pg[npg-2]-pgorb[npg-2]) gt pg_tolerance then begin
      if  ind_pg[npg-1]-ind_pg[npg-2] gt pgorb0/2.   then ind_pg=ind_pg[0:npg-2] else begin
        dtemp=abs(ind_pg[npg-2:*]-ind_pg[npg-3] -pgorb0)
        idiff=where(dtemp gt pg_tolerance,cn)
        if cn ne 0 then ind_pg[idiff+npg-2]=-1
        igood=where(ind_pg ne -1,npg)
        if keyword_set(halt) then stop
        if npg ne 0 then ind_pg=ind_pg[igood]
      endelse
   endif
   npg=n_elements(ind_pg)  
  endif 
  if npg gt 2 then begin  
  if keyword_set(halt) then stop
   if abs(ind_pg[1]-ind_pg[0] -pgorb0) gt pg_tolerance then begin
      if ind_pg[1]-ind_pg[0] gt pgorb0/2. then ind_pg=ind_pg[1:*] else begin
         dtemp=abs(ind_pg[2]-ind_pg[0:1] -pgorb0)
         idiff=where(dtemp gt pg_tolerance,cn)
         if cn ne 0 then ind_pg[idiff]=-1
         igood=where(ind_pg ne -1,npg)
         if keyword_set(halt) then stop
         if npg ne 0 then ind_pg=ind_pg[igood]
      endelse  
    if keyword_set(halt) then stop    
   endif            
   npg=n_elements(ind_pg)    
  endif
  
  if keyword_set(halt) then stop
  if nag gt 2 then begin
  
   if abs(ind_ag[nag-1]-ind_ag[nag-2]-agorb[nag-2])   gt ag_tolerance then begin      
      if  ind_ag[nag-1]-ind_ag[nag-2] gt agorb0/2. then ind_ag=ind_ag[0:nag-2] else begin
        dtemp=abs(ind_ag[nag-2:*]-ind_ag[nag-3] -agorb0)
        idiff=where(dtemp gt ag_tolerance,cn)
        if cn ne 0 then ind_ag[idiff+nag-2]=-1
        igood=where(ind_ag ne -1,nag)
        if keyword_set(halt) then stop
        if nag ne 0 then ind_ag=ind_ag[igood]
      endelse 
   endif
   nag=n_elements(ind_ag)
  endif
  if nag gt 2 then begin
   
   if abs(ind_ag[1]-ind_ag[0] -agorb0) gt ag_tolerance then begin
     if ind_ag[1]-ind_ag[0] gt agorb0/2. then ind_ag=ind_ag[1:*] else begin
        dtemp=abs(ind_ag[2]-ind_ag[0:1] -agorb0)
        idiff=where(dtemp gt ag_tolerance,cn)
        if cn ne 0 then ind_ag[idiff]=-1
        igood=where(ind_ag ne -1,nag) 
        if keyword_set(halt) then stop
        if nag ne 0 then ind_ag=ind_ag[igood]
     endelse 
   
   endif 
   nag=n_elements(ind_ag)       
  endif
    if keyword_set(halt) then stop
  ;update pgorb, agorb
  if npg ge 2 then  pgorb=(ind_pg-shift(ind_pg,1))[1:*]       
  if nag ge 2 then  agorb=(ind_ag-shift(ind_ag,1))[1:*] 
 
  ag_last=ind_ag[nag-1]
  pg_last=ind_pg[npg-1] 
  orb_last=max(agorb)>max(pgorb)
 if  abs(last-(ag_last>pg_last)) lt tolerance then begin

  if abs(abs(ag_last-pg_last)-orb_last/2.) gt (ag_tolerance<pg_tolerance) then begin
    if pg_last gt ag_last then ind_pg=ind_pg[0:npg-2] else  ind_ag=ind_ag[0:nag-2]
    npg=n_elements(ind_pg)
    nag=n_elements(ind_ag)
  endif
 endif
 pg_fst=ind_pg[0]
 ag_fst=ind_ag[0]
 
 if (pg_fst<ag_fst) gt 0 and (pg_fst<ag_fst) le tolerance then begin
 
  if abs(abs(ag_fst-pg_fst)-orb_last/2.) gt (ag_tolerance<pg_tolerance) then begin
    if pg_fst lt ag_fst then ind_pg=ind_pg[1:*] else ind_ag=ind_ag[1:*]
    npg=n_elements(ind_pg)
    nag=n_elements(ind_ag)
  endif
 endif
endif		;orbits gt 1

 if keyword_set(info) then begin 
 print,'first and last entries after '
 print,ind_pg[[0,npg-1]]
 print,ind_ag[[0,nag-1]]
endif

 if npg gt 1 and ind_pg[npg-1] ne (nn-1) then if rr[ind_pg[npg-1]] ne $  
   min([rr[ind_pg[npg-1]-1],rr[ind_pg[npg-1]],rr[ind_pg[npg-1]+1]]) $
  then ind_pg=ind_pg[0:npg-2]
 npg=n_elements(ind_pg)

   
 if ind_pg[0] ne 0 and ind_pg[0] ne (nn-1) and npg gt 1 then $    
  if  rr[ind_pg[0]] ne min([rr[ind_pg[0]-1],rr[ind_pg[0]],rr[ind_pg[0]+1]]) $
    then ind_pg=ind_pg[1:*]
npg=n_elements(ind_pg)
 if nag gt 1 and ind_ag[nag-1] ne (nn-1) then if rr[ind_ag[nag-1]] ne $  
   max([rr[ind_ag[nag-1]-1],rr[ind_ag[nag-1]],rr[ind_ag[nag-1]+1]]) $
   then ind_ag=ind_ag[0:nag-2]
nag=n_elements(ind_ag) 
 if ind_ag[0] ne 0 and ind_ag[0] ne (nn-1) and nag gt 1 then $
  if rr[ind_ag[0]] ne max([rr[ind_ag[0]-1],rr[ind_ag[0]],rr[ind_ag[0]+1]]) $
   then ind_ag=ind_ag[1:*] 
nag=n_elements(ind_ag) 


if orbits eq 0 then if (ind_ag[0] eq 0  or ind_ag[nag-1] eq (nn-1)) $
and keyword_set(info) then $
 print,' Orbit is not complete, apogee might not be true.'

cnt3=n_elements(ind_pg)
cnt4=n_elements(ind_ag)

if keyword_set(info) then begin
   print,'ind_pg= ',ind_pg
   print,'ind_ag= ',ind_ag
endif

if cnt4 ge 4 then begin
 sft=ind_ag-shift(ind_ag,1)
 sft=sft[1:*]
 sft2=abs(sft-shift(sft,1))
 sft2=sft2[1:*] 
 sdag=ag_tolerance
 tmp=where(sft2 gt sdag,nb)
 
 if nb ne 0 then begin
  ibad=-1
  for i=0,((nb-1)<(nag-2)) do $
   if abs(abs(ind_ag[tmp[i]]-ind_ag[tmp[i]+1])-median(sft)) gt ag_tolerance $
   then ibad=[ibad,i]
  itmp=where(ibad ne -1,icnt)
  if icnt ne 0 then tmp=tmp[ibad[itmp]] else tmp=tmp
  nb=n_elements(tmp)
  ;if possible check with exact predecessor  improved 07-14-04
   if tmp[0] gt 0 then crit=sft[tmp[0]-1]-sft[tmp[0]] else $
      crit=abs(sft[tmp[0]+1]-sft[tmp[0]])   
  for k=0,nb-1 do begin      
    
   if crit gt  sdag then begin
     if rr[ind_ag[tmp[k]]] ne $
      max(rr[(ind_ag[tmp[k]]-ag_tolerance)>0:(ind_ag[tmp[k]]+ag_tolerance)<last]) $
     then ind_ag[tmp[k]]=-1
    endif         
  endfor
 endif
endif

if cnt3 ge 4 then begin 
  for l=0,cnt3-2 do begin
  if ind_pg[l]-ind_pg[l+1] gt -5 then begin
    dummy=max([rr[ind_pg[l]],rr[ind_pg[l+1]]],irr)
    ind_pg[l+irr]=-1   
  endif
 endfor
 indagain=where(ind_pg ne -1,cntagain)
 ind_pg=ind_pg[indagain]
 npg=n_elements(ind_pg)
 cnt3=npg
 sft=ind_pg-shift(ind_pg,1)
 sft=sft[1:*]
 sft2=abs(sft-shift(sft,1))
 sft2=sft2[1:*] 
 sdpg=pg_tolerance
 tmp=where(sft2 gt sdpg,iii)

 if iii ne 0 then begin 
 ibad =-1
     for i=0,((iii-1)<(npg-2)) do $
      if abs(abs(ind_pg[tmp[i]]-ind_pg[tmp[i]+1])-median(sft)) gt pg_tolerance $
      then ibad=[ibad,i]
     itmp=where(ibad ne -1,icnt)
     if icnt ne 0 then tmp=tmp[ibad[itmp]] else tmp=tmp
     iii=n_elements(tmp)
  for k=0,iii-1 do begin 
   if tmp[k] gt 0 then crit=abs(sft[tmp[k]-1]-sft[tmp[k]]) else $
    crit=abs(sft[tmp[k]+1]-sft[tmp[k]])
    if crit gt  sdpg then begin
     if rr[ind_pg[tmp[k]]] ne $
      min(rr[(ind_pg[tmp[k]]-pg_tolerance)>0:(ind_pg[tmp[k]]+pg_tolerance)<last]) $
     then ind_pg[tmp[k]]=-1   
    endif
  endfor
 endif
endif

ind=where(ind_ag ne -1,nag)  
if nag ne 0 then ind_ag=ind_ag[ind]  
ind=where(ind_pg ne -1,npg)  
if npg ne 0 then ind_pg=ind_pg[ind]  
orb=npg<nag

pg10=ind_pg
ag10=ind_ag
mins=where(rr[ind_pg] le rr[ind_pg-1] and rr[ind_pg] le rr[ind_pg+1] ,npg1)
maxs=where(rr[ind_ag] ge rr[ind_ag-1] and rr[ind_ag] ge rr[ind_ag+1] ,nag1)

pg00=pg0
ag00=ag0


if npg1 ne 0 then begin
  pg0=ind_pg[mins]
  if ind_pg[0] eq 0 and mins[0] ne 0 then pg0=[0,pgo]
  if ind_pg[npg-1] eq nn-1 and ind_pg[mins[npg1-1]] ne nn-1 then pg0=[pg0,nn-1]
endif else pg0=ind_pg 

if nag1 ne 0 then begin
  ag0=ind_ag[maxs] 
  if ind_ag[0] eq 0 and maxs[0] ne 0 then ag0=[0,ag0]
 
  if ind_ag[nag-1] eq nn-1 and ind_ag[maxs[nag1-1]] ne nn-1 then ag0=[ag0,nn-1]
endif else ag0=ind_ag


ind_pg=pg0[uniq(pg0)]	;well might be obsolete
ind_ag=ag0[uniq(ag0)]

npg=n_elements(ind_pg)
nag=n_elements(ind_ag)



if keyword_set(info) then begin 
  print,'idz ',idz
 print,'ind_pg ',ind_pg
 print,'ind_ag ',ind_ag
 print,'ind_pg-ind_ag='
 print,ind_pg-ind_ag
 print,'orbits',orbits
 if !d.name eq 'X' then begin
  plots,ind_pg,rr[ind_pg],psym=6,col=180
  plots,ind_ag,rr[ind_ag],psym=6,col=180
 endif 
endif

;final check for missing perigee/apogee
;indices must alternate using where_array 11-22-05
;this will not add if both first  or last ones are missed
if test eq 1 then ind_pg=ind_pg[0:npg-2]	
if test eq 2 then ind_pg=[ind_pg[0:5],ind_pg[7:*]]  
   if test eq 3 then begin
  ind_ag=[ind_ag[0:4],ind_ag[6:nag-2]]
  ind_pg=[ind_pg[0:5],ind_pg[7:npg-1]]  
endif
if test ge 1  and !d.name eq 'X' then begin
  plot,rr
  plots,ind_pg,rr[ind_pg],psym=2,col=150
  plots,ind_ag,rr[ind_ag],psym=2,col=150
endif 



 bad =0   
if orb gt 2 then begin
 npg=n_elements(ind_pg)
 nag=n_elements(ind_ag)
 diff1=abs(ind_pg-ind_ag)
 diff2=(diff1-shift(diff1,1))[1:*]
 if max(abs(diff2),ibad) gt tolerance then $
 if max(abs(diff2),ibad) gt round(median(abs(dstart-astart))/10.) then begin
  if ind_pg[npg-1] eq (nn-1) and rr[ind_pg[npg-1]]>2*min(rr[ind_pg[0:npg-2]]) then ind_pg=ind_pg[0:npg-2]
  npg=n_elements(ind_pg)
  if ind_pg[0] eq 0 and rr[ind_pg[0]]>2*max(rr[ind_pg[1:*]]) then ind_pg=ind_pg[1:*]
  npg=n_elements(ind_pg)
  if ind_ag[nag-1] eq (nn-1) and rr[ind_ag[nag-1]]<0.6*min(rr[ind_ag[0:nag-2]]) then ind_ag=ind_ag[0:nag-2]
  nag=n_elements(ind_ag)
  if ind_ag[0] eq 0 and rr[ind_ag[nag-1]]<0.6*min(rr[ind_ag[1:*]]) then ind_ag=ind_ag[1:*]
  nag=n_elements(ind_ag)
 endif
 npg=n_elements(ind_pg)
 nag=n_elements(ind_ag) 
   cnt1=0
   cnt2=0
 if npg gt 2 then begin 
  diff1=abs(ind_pg-ind_ag)
  diff2=(diff1-shift(diff1,1))[1:*]
  if max(abs(diff2),ibad) gt tolerance then $
  if max(abs(diff2),ibad) gt round(median(abs(dstart-astart))/10.) then begin
  if plot_okay then plot,rr
  if plot_okay then plots,ind_ag,rr[ind_ag],psym=2
  if plot_okay then plots,ind_pg,rr[ind_pg],psym=6,col=90
  
  print,'this stop can be caused by having different orbit sizes see plot'
  if not keyword_set(nostop) then print,'ind_ag=',ind_ag
  if not keyword_set(nostop) then print,'ind_pg=',ind_pg
  if not keyword_set(nostop) then print,'idz=',idz
  if plot_okay then plots,idz,rr[idz],psym=4
  
  if not keyword_set(nostop) then print,'ag0=',ag0
  if not keyword_set(nostop) then print,'pg0=',pg0
  if not keyword_set(nostop) then print,'you might reset ind_pg,ind_ag here and continue'
  if not keyword_set(nostop) then stop  ;TBD action
  if keyword_set(nostop) then print,'Nostop=1'
   endif
  alles=ind_pg+ind_ag
  dalles=(alles-shift(alles,1))[1:*]
  if n_elements(dalles) ge 2 then begin
   ddalles=(dalles-shift(dalles,1))[1:*]
   ddalles=abs(ddalles)
   offset=(ag_tolerance+pg_tolerance)
   if abs(mean(ddalles)-median(ddalles)) gt ((ag_tolerance+pg_tolerance)/2.) then begin
    alles2=[ind_pg,ind_ag]
    alles2=alles2[sort(alles2)]
    result1=where_array(alles2,ind_pg,/iA_in_B)
    result2=where_array(alles2,ind_ag,/iA_in_B)
    if result1[0] ge 2  then begin
     dorb_dash=dorb-offset
     for l=0,result1[0]-1 do begin
      dummy=min(rr[l*dorb_dash:(l+1)*dorb_dash],iadd0)
      iadd=l*dorb_dash+iadd0
      if abs(iadd0+offset-median(dalles)/2) le offset then ind_pg=[ind_pg,iadd]
     endfor
    endif
   
    ck2=where(abs((result2-shift(result2,1))[1:*]) ne 2,cnt2)
    ck1=where(abs((result1-shift(result1,1))[1:*]) ne 2,cnt1)
    if keyword_set(halt) then stop	
   endif else begin
   cnt1=0
   cnt2=0
   
  endelse 
 endif 
    if cnt1 ne 0 or cnt2 ne 0 then begin
     diff1=(result1-shift(result1,1))[1:*]
     itmp1=where(diff1 ne 2,cn1)
     last1=n_elements(result1)-1
     diff2=(result2-shift(result2,1))[1:*]
     itmp2=where(diff2 ne 2,cn2)
     last2=n_elements(result2)-1
     lastrr=n_elements(rr)-1
    
     if cnt1 ne 0 then begin
      for i=0,cnt1-1 do begin
       case 1 of
        result1[itmp1[i]] le 1 and diff1[itmp1[i]] eq 1: begin
         dummy= min(rr[0:(alles2[result1[itmp1[i]]]-offset)>1],iadd)
         dummy=min(abs(iadd-ind_pg),ik)
         if abs(dummy-median(dalles)/2) le offset then ind_pg=[ind_pg,iadd]
        end    
      
       itmp1[i] lt last1 : begin            
         if (alles2[result1[itmp1[i]+1]]-alles2[result1[itmp1[i]]]) gt (aorb>dorb) then begin       
          dummy= min(rr[alles2[result1[itmp1[i]]]+offset:alles2[result1[itmp1[i]+1]]-offset],iadd0)
          iadd=alles2[result1[itmp1[i]]]+offset+iadd0
          if abs(iadd0+offset-median(dalles)/2) le offset then ind_pg=[ind_pg,iadd]
         endif
       end
       itmp1[i] eq last1: begin
         dummy=min(rr[(alles2[result1[itmp1[i]]]+offset)>(lastrr-1):lastrr],iadd0)
         iadd=((alles2[result1[itmp1[i]]]+offset)>(lastrr-1))+iadd0
         if abs(iadd0-median(dalles)/2) le offset then ind_pg=[ind_pg,iadd]
       end
       
       else:donothing=1
      endcase  
     endfor
    if cn2 ne 0 then if (itmp2[cn2-1]+1) eq last2 and diff2[itmp2[cn2-1]] eq 1 then begin	;new
        dummy=min(rr[alles2[result2[last2-1]]:alles2[result2[last2]]],iadd0)
        iadd=alles2[result2[last2-1]]+iadd0
        if abs(iadd0-(norb)/2) le offset then ind_ag=[ind_ag,iadd]
     endif
     ind_pg=ind_pg[uniq(ind_pg,sort(ind_pg))]
    endif	;cnt1
    
    
    if cnt2 ne 0 then begin     
     for i=0,cnt2-1 do begin
      case 1 of
       result2[itmp2[i]] le 1 and diff2[itmp2[i]] eq 1: begin    
         dummy= max(rr[0:(alles2[result2[itmp2[i]]]-offset)>1],iadd)
         dummy=min(abs(iadd-ind_ag),il)
         if abs(dummy-median(dalles)/2) le offset then ind_ag=[ind_ag,iadd]
       end    
       
       itmp2[i] lt last2  : begin          
         if (alles2[result2[itmp2[i]+1]]-alles2[result2[itmp2[i]]]) gt (aorb>dorb) then begin
          dummy= max(rr[alles2[result2[itmp2[i]]]+offset:alles2[result2[itmp2[i]+1]]-offset],iadd0)
          iadd=alles2[result2[itmp2[i]]]+offset+iadd0
          if abs(iadd0+offset-median(dalles)/2) le offset then ind_ag=[ind_ag,iadd]
         endif
       end 
       itmp2[i] eq last2: begin
         dummy=max(rr[(alles2[result2[itmp2[i]]]+offset)>(lastrr-1):lastrr],iadd0)
         iadd=((alles2[result2[itmp2[i]]]+offset)>(lastrr-1))+iadd0
         if abs(iadd0-median(dalles)/2) le offset then ind_ag=[ind_ag,iadd]
       end  
      
       else:donothing=1
      endcase
     endfor   
    if cn1 ne 0 then  if (itmp1[cn1-1]+1) eq last1 and diff1[itmp1[cn1-1]] eq 1 then begin   ;new
        dummy=max(rr[alles2[result1[last1-1]]:alles2[result1[last1]]],iadd0)
        iadd=alles2[result1[last1-1]]+iadd0
        if abs(iadd0-(norb)/2) le offset then ind_ag=[ind_ag,iadd]
      
     endif 
     ind_ag=ind_ag[uniq(ind_ag,sort(ind_ag))]
    endif	;cnt2
    if keyword_set(info)  and !d.name eq 'X' then begin
      plots,ind_pg,rr[ind_pg],psym=2,col=250
      plots,ind_ag,rr[ind_ag],psym=2,col=250
    endif 
   endif ;cnt1 ne 0 or cnt2 ne 0
   alles2=[ind_pg,ind_ag]
   alles2=alles2[sort(alles2)]
   result1=where_array(alles2,ind_pg,/iA_in_B)
   result2=where_array(alles2,ind_ag,/iA_in_B)
   ck2=where(abs((result2-shift(result2,1))[1:*]) ne 2,cnt2)
   ck1=where(abs((result1-shift(result1,1))[1:*]) ne 2,cnt1)
   if cnt1 ne 0 or cnt2 ne 0 then bad=1
 endif  ;<ddalles> ne tolerance
endif  ;orb gt 2


if keyword_set(halt) then stop

if bad then begin
  print, 'Some perigee or apogee got lost or added.'
  if not keyword_set(nostop) then begin  
   print,'dalles:',dalles
   print,'ddalles:',ddalles
  endif 
  if keyword_set(nostop) then print,'... but Nostop=1 and we ignore it'
  if !d.name eq 'X' then begin
   plot,rr
   plots,ag0,rr[ag0],psym=2,col=100
   plots,pg0,rr[pg0],psym=2,col=210
   plots,ind_ag,rr[ind_ag],psym=6,col=160
   plots,ind_pg,rr[ind_pg],psym=6,col=60
  endif
  alles2=[ind_pg,ind_ag]
  alles2=alles2[sort(alles2)]
  result1 = where_array(alles2,ind_pg,/iA_in_B	)
  result2=where_array(alles2,ind_ag,/iA_in_B	)
  ck2=where(abs((result2-shift(result2,1))[1:*]) ne 2,cnt2)
  ck1=where(abs((result1-shift(result1,1))[1:*]) ne 2,cnt1)
  if N_elements(agorb0) eq 0 then agorb0=median(agorb)
  if N_elements(pgorb0) eq 0 then pgorb0=median(pgorb)
  
  if cnt1 eq 0 then $  ;if one set is okay
  for l=0,cnt2-1 do begin
   if abs(abs(ind_ag[ck2[l]+1]-ind_ag[ck2[l]])-agorb0) le ag_tolerance then begin
    dummy=min(rr[ind_ag[ck2[l]]:ind_ag[ck2[l]+1]],pg_add)
    ind_pg=[ind_pg,ind_ag[ck2[l]]+pg_add]
    ind_pg=ind_pg[sort(ind_pg)]    
   endif 
 endfor
 if cnt2 eq 0 then $
 for l=0, cnt1-1 do begin
   if abs(abs(ind_pg[ck1[l]+1]-ind_pg[ck1[l]])-pgorb0) le pg_tolerance then begin
    dummy=max(rr[ind_pg[ck1[l]]:ind_pg[ck1[l]+1]],ag_add)
    ind_ag=[ind_ag,ind_pg[ck1[l]]+ag_add]
    ind_ag=ind_ag[sort(ind_ag)]
   endif     
  endfor
   if plot_okay then plots,ind_ag,rr[ind_ag],psym=4,col=250
   if plot_okay then plots,ind_pg,rr[ind_pg],psym=6,col=2500
  print,'See window:',!d.window 
  alles2=[ind_pg,ind_ag]
  alles2=alles2[sort(alles2)]
  result1 = where_array(alles2,ind_pg,/iA_in_B	)
  result2=where_array(alles2,ind_ag,/iA_in_B	)
  ck2=where(abs((result2-shift(result2,1))[1:*]) ne 2,cnt2)
  ck1=where(abs((result1-shift(result1,1))[1:*]) ne 2,cnt1) 
  if cnt1+cnt2 ne 0 and not keyword_set(nostop) then stop 
  if cnt1+cnt2 eq 0 then print,'Corrected'	;TBD action 
  
  
endif
if keyword_set(halt) then stop

;check for missing the very last one
 if orb gt 2 then begin 
 if npg ge 2 then  pgorb=ind_pg-shift(ind_pg,1)
 if nag ge 2 then  agorb=ind_ag-shift(ind_ag,1)
 ag_last=ind_ag[nag-1]
 pg_last=ind_pg[npg-1]
 if nag gt 2 and npg gt 2 then  orb_last=agorb[nag-2]>pgorb[npg-2] $
  else orb_last=agorb[1]>pgorb[1]
   if abs(last-(ag_last>pg_last)) lt 2 then begin
      if abs(abs(ag_last-pg_last)-orb_last/2.) le (ag_tolerance<pg_tolerance) and  keyword_set(info) then begin
         ; if abs(abs(ag_last-pg_last)-orb_last) le (ag_tolerance<pg_tolerance) and  keyword_set(info) then begin
           print, 'The very last one might not be exact but is within data variation'
           print,'abs(abs(ag_last-pg_last)-orb_last/2.) , data variation' ,  $
                 abs(abs(ag_last-pg_last)-orb_last/2.) , (ag_tolerance<pg_tolerance)      
      endif
    
      if abs(abs(ag_last-pg_last)-orb_last/2.) gt (ag_tolerance<pg_tolerance)   then begin   ;12-11-06 back to orb_last/2.
        if pg_last gt ag_last then ind_pg=ind_pg[0:npg-2] else  ind_ag=ind_ag[0:nag-2]
        npg=n_elements(ind_pg)
        nag=n_elements(ind_ag)
      endif
   endif
 endif;orb gt 2 
endif 	;not good
 

;get orbit number
nall=n_elements(x)
orbitnumber=lonarr(nall)
nnode=n_elements(ind_asnode)

if nnode eq 1 then orbitnumber=orbitnumber+1 else begin
 num=lindgen(nnode)+1       ;counting starts at 1
 for i=0,nnode-2 do orbitnumber[ind_asnode[i]:ind_asnode[i+1]-1]=num[i]
 if ind_asnode[nnode-1] lt (nall-1) then  $
     orbitnumber[ind_asnode[nnode-1]:*]=num[nnode-1]
 if ind_asnode[0] ne 0 then begin
  orbitnumber[0:ind_asnode[0]-1]=0
  orbitnumber=orbitnumber+1
 endif
endelse
norbits=orbits

ag=0 & pg=0
;final check for short pieces
if npg eq 1 and nag eq 1 then begin
 if ind_pg eq 0 and ind_ag ne (nn-1) then ag=1 
 if ind_pg eq (nn-1) and ind_ag ne 0 then pg=1 
endif
if norbits gt  1 then begin
 ag=1
 pg=1
endif
if (test ge 1 or keyword_set(info)) and !d.name eq 'X' then begin
  plots,ind_pg,rr[ind_pg],psym=6,col=60
  plots,ind_ag,rr[ind_ag],psym=6,col=60
endif  
if keyword_set(halt) then stop

end
