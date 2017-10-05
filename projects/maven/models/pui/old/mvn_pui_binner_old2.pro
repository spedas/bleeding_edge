;20160404 Ali
;binning of fluxes according to energy and angular response of SEP, SWIA, STATIC
;to be called by mvn_pui_model

pro mvn_pui_binner_old2,np=np,do3d=do3d,msub=msub,dphi=dphi

@mvn_pui_commonblock.pro ;common mvn_pui_common

inn=pui0.time_steps
onesnp=replicate(1.,np)
sep1ld=transpose(pui.data.sep[0].fov)
sep2ld=transpose(pui.data.sep[1].fov)
staxld=transpose(pui.data.sta.fov.x)
stazld=transpose(pui.data.sta.fov.z)

sep1ldx=sep1ld[*,0]#onesnp; sep look directions
sep1ldy=sep1ld[*,1]#onesnp
sep1ldz=sep1ld[*,2]#onesnp
sep2ldx=sep2ld[*,0]#onesnp
sep2ldy=sep2ld[*,1]#onesnp
sep2ldz=sep2ld[*,2]#onesnp

swiyldx=sep1ldy*sep2ldz-sep2ldy*sep1ldz ;swia look directions
swiyldy=sep1ldz*sep2ldx-sep2ldz*sep1ldx
swiyldz=sep1ldx*sep2ldy-sep2ldx*sep1ldy
swixld=(sep1ld+sep2ld)/sqrt(2.)
swizld=(sep1ld-sep2ld)/sqrt(2.)
swixldx=swixld[*,0]#onesnp
swixldy=swixld[*,1]#onesnp
swixldz=swixld[*,2]#onesnp
swizldx=swizld[*,0]#onesnp
swizldy=swizld[*,1]#onesnp
swizldz=swizld[*,2]#onesnp

staxldx=staxld[*,0]#onesnp; static look directions
staxldy=staxld[*,1]#onesnp
staxldz=staxld[*,2]#onesnp
stazldx=stazld[*,0]#onesnp
stazldy=stazld[*,1]#onesnp
stazldz=stazld[*,2]#onesnp
stayldx=stazldy*staxldz-staxldy*stazldz
stayldy=stazldz*staxldx-staxldz*stazldx
stayldz=stazldx*staxldy-staxldx*stazldy

r3x=pui2.rv[0]
r3y=pui2.rv[1]
r3z=pui2.rv[2]
v3x=pui2.rv[3]
v3y=pui2.rv[4]
v3z=pui2.rv[5]
vxyz=pui2.vxyz
ke=pui2.ke/1e3 ;energy (keV)

cosvsep1=-(sep1ldx*v3x+sep1ldy*v3y+sep1ldz*v3z)/vxyz; cosine of angle between detector FOV and pickup ion -velocity vector
cosvsep2=-(sep2ldx*v3x+sep2ldy*v3y+sep2ldz*v3z)/vxyz;
cosvswix=-(swixldx*v3x+swixldy*v3y+swixldz*v3z)/vxyz;
cosvswiy=-(swiyldx*v3x+swiyldy*v3y+swiyldz*v3z)/vxyz;
cosvswiz=-(swizldx*v3x+swizldy*v3y+swizldz*v3z)/vxyz;
cosvstax=-(staxldx*v3x+staxldy*v3y+staxldz*v3z)/vxyz;
cosvstay=-(stayldx*v3x+stayldy*v3y+stayldz*v3z)/vxyz;
cosvstaz=-(stazldx*v3x+stazldy*v3y+stazldz*v3z)/vxyz;

cosvsep1xy=cosvsep1/sqrt(cosvsep1^2+cosvswiy^2); cosine of angle b/w projected -v on sep1 xy plane and sep1 fov 
cosvsep2xy=cosvsep2/sqrt(cosvsep2^2+cosvswiy^2); cosine of angle b/w projected -v on sep2 xy plane and sep2 fov
cosvsep1xz=cosvsep1/sqrt(cosvsep1^2+cosvsep2^2); cosine of angle b/w projected -v on sep1 xz plane and sep1 fov
cosvsep2xz=cosvsep2/sqrt(cosvsep1^2+cosvsep2^2); cosine of angle b/w projected -v on sep2 xz plane and sep2 fov

phiswipm=!dtor*(360+22.50) ;swia binning parameter
phistapm=!dtor*(360+11.25) ;static binning parameter
phiswixy=!pi+atan(-cosvswiy,-cosvswix); swia phi angles: between 0 and 2pi rad
phistaxy=!pi+atan(-cosvstay,-cosvstax); static phi angles: between 0 and 2pi rad
phiswixy=phiswipm-((phiswipm-phiswixy) mod (2*!pi)); swia phi angles: between 22.5 and 360+22.5 deg
phistaxy=phistapm-((phistapm-phistaxy) mod (2*!pi)); static phi angles: between 11.25 and 360+11.25 deg

kefsep1=replicate(0.,inn,pui0.srmd) ;sep1 flux binning
kefsep2=kefsep1 ;sep2 flux binning
keflux=replicate(0.,inn,pui0.toteb) ;total flux binning
kefswi=replicate(0.,inn,pui0.swieb) ;swia flux binning
kefsta=replicate(0.,inn,pui0.staeb) ;static flux binning

if keyword_set(do3d) then begin
  kefswi3d=replicate(0.,inn,pui0.swieb,pui0.swina,pui0.swine) ;swia 3d flux binning
  kefsta3d=replicate(0.,inn,pui0.staeb,pui0.swina,pui0.swine) ;static 3d flux binning
  krxswi3d=kefswi3d ;swia 3d particle position binning
  kryswi3d=kefswi3d
  krzswi3d=kefswi3d
  knnswi3d=kefswi3d ;swia 3d particle number binning
endif

ke[where(~finite(ke),/null)]=1. ;in case energy is NaN due to bad inputs (eV)
ke[where(ke ge 700,/null)]=1. ;in case energy is too high due to bad inputs (eV)
kestep=floor(ke); %linear energy step binning (keV)
lnkestep=126-floor(alog(1e3*ke)/pui0.totdee); %log energy step ln(eV) for all flux (edges: 328 keV to 14.9 eV with 10% resolution)
lnkeswia= 69-floor(alog(1e3*ke)/pui0.swidee); %log energy step ln(eV) for SWIA (post Nov 2014)
lnkestat= 63-floor(alog(1e3*ke)/pui0.stadee); %log energy step ln(eV) for STATIC (only pickup mode)
lnkestep[where((lnkestep lt 0) or (lnkestep gt pui0.toteb-1),/null)]=pui0.toteb-1 ;if bins are outside the range...
lnkeswia[where((lnkeswia lt 0) or (lnkeswia gt pui0.swieb-1),/null)]=pui0.swieb-1 ;put them at the last bin...
lnkestat[where((lnkestat lt 0) or (lnkestat gt pui0.staeb-1),/null)]=pui0.staeb-1 ;(lowest energy bin)

rfov=1.+(ke-5.)/5.; correction factor for SWIA and STATIC reduced FOV at E>5keV
rfov[where(rfov lt 1.,/null)]=1.

cosfovsep=cos(!dtor*30.) ;sep opening angle (assuming conic)
sinfovswi=sin(!dtor*45./rfov) ;swia and static +Z opening angle
phifovswi=!dtor*findgen(pui0.swina+1,increment=22.5,start=22.50) ;swia anode phi angle bins (azimuth):between 22.5 and 360+22.5 deg
phifovsta=!dtor*findgen(pui0.swina+1,increment=22.5,start=11.25) ;static anode phi angle bins (azimuth):between 11.25 and 360+11.25 deg
thefovswi=!dtor*findgen(pui0.swine+1,increment=22.5,start=-45.0) ;swia and static deflection theta angles (elevation):between -45 and 45 deg

cosfovsepxy=cos(!dtor*21.0) ;sep opening angle (full angular extent) in sep xy plane (s/c xz)
cosfovsepxz=cos(!dtor*15.5) ;sep opening angle (full angular extent) in sep xz plane (s/c yz)

sdea1xy=(cosvsep1xy-cosfovsepxy)/(1-cosfovsepxy) ;sep projected detector effective area on sep1 xy plane
sdea2xy=(cosvsep2xy-cosfovsepxy)/(1-cosfovsepxy)
sdea1xz=(cosvsep1xz-cosfovsepxz)/(1-cosfovsepxz)
sdea2xz=(cosvsep2xz-cosfovsepxz)/(1-cosfovsepxz)

sdea1=sdea1xy*sdea1xz ;sep detector effective area factor (cm2)
sdea2=sdea2xy*sdea2xz

;very small sep detector area within cosfovsep (cm2)
sdea1[where((cosvsep1xy lt cosfovsepxy) or (cosvsep1xz lt cosfovsepxz),/null)]=1e-2
sdea2[where((cosvsep2xy lt cosfovsepxy) or (cosvsep2xz lt cosfovsepxz),/null)]=1e-2
sdea1[where(cosvsep1 lt cosfovsep,/null)]=0.
sdea2[where(cosvsep2 lt cosfovsep,/null)]=0.

secof=(ke-40.)/60. ;sep energy response for oxygen
secof[where(ke lt 40.,/null)]=0.
secof[where(ke gt 100.,/null)]=1.
sdeaecof=sdea1*secof
sep=replicate({sdeaecof:sdeaecof},2)
sep[1].sdeaecof=sdea2*secof

;sep detected particle sources
for i=0,1 do begin ;loop over sep's
  for j=0,5 do begin ;loop over coordinates (rx,ry,rz,vx,vy,vz)
    pui.model[msub].fluxes.sep[i].rv[j]=total(pui2.rv[j]*sep[i].sdeaecof,2,/nan)/total(sep[i].sdeaecof,2,/nan)    
  endfor
endfor

rfovswia=rfov
rfovstat=rfov
rfovswia[where(abs(cosvswiz) gt sinfovswi,/null)]=0.
rfovstat[where(abs(cosvstaz) gt sinfovswi,/null)]=0.
;stop
for it=1,np-1 do begin ;loop over particles
  ntotit=dphi[*,it]
  rfovit=rfov[*,it]
  kestep2=indgen(inn)+inn*kestep[*,it]; going from 2D to 1D array subscripts
  lnkestep2=indgen(inn)+inn*lnkestep[*,it]
  lnkeswia2=indgen(inn)+inn*lnkeswia[*,it]
  lnkestat2=indgen(inn)+inn*lnkestat[*,it]
  
  kefsep1[kestep2]+=ntotit*sdea1[*,it] ;bin pickup ion fluxes that are within the FOV
  kefsep2[kestep2]+=ntotit*sdea2[*,it]
  keflux[lnkestep2]+=ntotit; %total energy flux
  kefswi[lnkeswia2]+=ntotit*rfovswia[*,it]; %energy flux
  kefsta[lnkestat2]+=ntotit*rfovstat[*,it]; %energy flux

  if keyword_set(do3d) then begin
    for k=0,pui0.swine-1 do begin
      sinfovswik0=sin(thefovswi[k]/rfovit)
      sinfovswik1=sin(thefovswi[k+1]/rfovit)
      rfovswi3d=rfovit
      rfovsta3d=rfovit
      rfovswi3d[where((cosvswiz[*,it] lt sinfovswik0) or (cosvswiz[*,it] gt sinfovswik1),/null)]=0.
      rfovsta3d[where((cosvstaz[*,it] lt sinfovswik0) or (cosvstaz[*,it] gt sinfovswik1),/null)]=0.
      for j=0,pui0.swina-1 do begin
          rfovswia3d=rfovswi3d
          rfovstat3d=rfovsta3d
          rfovswia3d[where((phiswixy[*,it] lt phifovswi[j]) or (phiswixy[*,it] gt phifovswi[j+1]),/null)]=0.
          rfovstat3d[where((phistaxy[*,it] lt phifovsta[j]) or (phistaxy[*,it] gt phifovsta[j+1]),/null)]=0.
          lnkeswia3d=lnkeswia2+inn*pui0.swieb*j+inn*pui0.swieb*pui0.swina*k
          lnkestat3d=lnkestat2+inn*pui0.staeb*j+inn*pui0.staeb*pui0.swina*k
          kefswi3d[lnkeswia3d]+=ntotit*rfovswia3d; %energy flux
          kefsta3d[lnkestat3d]+=ntotit*rfovstat3d; %energy flux
          krxswi3d[lnkeswia3d]+=r3x[*,it]*rfovswia3d ;starting positions of pickup ions (m)
          kryswi3d[lnkeswia3d]+=r3y[*,it]*rfovswia3d
          krzswi3d[lnkeswia3d]+=r3z[*,it]*rfovswia3d
          knnswi3d[lnkeswia3d]+=rfovswia3d ;number of particles in this bin (weighted by rfov)
        endfor
      endfor
  endif

endfor

pui.model[msub].fluxes.sep[0].incident_rate=transpose(kefsep1)
pui.model[msub].fluxes.sep[1].incident_rate=transpose(kefsep2)
pui.model[msub].fluxes.toteflux=transpose(keflux)/pui0.totdee; total pickup angle-integrated differential energy flux (eV/[cm2 s eV])
pui.model[msub].fluxes.swi1d.eflux=transpose(kefswi)/pui0.swidee/pui0.swiatsa; %differential energy flux (eV/[cm2 s sr eV])
pui.model[msub].fluxes.sta1d.eflux=transpose(kefsta)/pui0.stadee/pui0.swiatsa; %differential energy flux (eV/[cm2 s sr eV])
if keyword_set(do3d) then begin
  pui.model[msub].fluxes.swi3d.eflux=transpose(kefswi3d,[1,2,3,0])/pui0.stadee/pui0.swiatsa*pui0.swina*pui0.swine; %differential energy flux (eV/[cm2 s sr eV])
  pui.model[msub].fluxes.sta3d.eflux=transpose(kefsta3d,[1,2,3,0])/pui0.stadee/pui0.swiatsa*pui0.swina*pui0.swine; %differential energy flux (eV/[cm2 s sr eV])
  pui.model[msub].fluxes.swi3d.r[0]=transpose(krxswi3d/knnswi3d,[1,2,3,0])
  pui.model[msub].fluxes.swi3d.traj.r[1]=transpose(kryswi3d/knnswi3d,[1,2,3,0])
  pui.model[msub].fluxes.swi3d.traj.r[2]=transpose(krzswi3d/knnswi3d,[1,2,3,0])
endif

end