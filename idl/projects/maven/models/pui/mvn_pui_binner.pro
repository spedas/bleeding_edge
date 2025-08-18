;20160404 Ali
;binning of fluxes according to energy and angular response of SEP, SWIA, STATIC
;to be called by mvn_pui_model

pro mvn_pui_binner,dphi

@mvn_pui_commonblock.pro ;common mvn_pui_common

nt=pui0.nt
np=pui0.np
msub=pui0.msub

sep1ld=transpose(rebin(pui.data.sep[0].fov,[3,nt,np]),[0,2,1])
sep2ld=transpose(rebin(pui.data.sep[1].fov,[3,nt,np]),[0,2,1])
staxld=transpose(rebin(pui.data.sta.fov.x, [3,nt,np]),[0,2,1])
stazld=transpose(rebin(pui.data.sta.fov.z, [3,nt,np]),[0,2,1])
swiyldx=sep1ld[1,*,*]*sep2ld[2,*,*]-sep2ld[1,*,*]*sep1ld[2,*,*]
stayldx=stazld[1,*,*]*staxld[2,*,*]-staxld[1,*,*]*stazld[2,*,*]
swiyldy=sep1ld[2,*,*]*sep2ld[0,*,*]-sep2ld[2,*,*]*sep1ld[0,*,*]
stayldy=stazld[2,*,*]*staxld[0,*,*]-staxld[2,*,*]*stazld[0,*,*]
swiyldz=sep1ld[0,*,*]*sep2ld[1,*,*]-sep2ld[0,*,*]*sep1ld[1,*,*]
stayldz=stazld[0,*,*]*staxld[1,*,*]-staxld[0,*,*]*stazld[1,*,*]
swiyld=[swiyldx,swiyldy,swiyldz]
stayld=[stayldx,stayldy,stayldz]
swixld=(sep1ld+sep2ld)/sqrt(2.)
swizld=(sep1ld-sep2ld)/sqrt(2.)

vxyz=pui.model[msub].rv[3:5,*]
vtot=pui2.vtot
ke=pui2.ke/1e3 ;energy (keV)
ke[where(~finite(ke),/null)]=0. ;in case energy is NaN due to bad inputs
ke[where(ke ge 1000,/null)]=1000. ;in case energy is too high due to bad inputs (keV)
rfov=mvn_pui_reduced_fov(ke) ;correction factor for SWIA and STATIC reduced FOV at E>5keV

cosvsep1=-total(vxyz*sep1ld,1)/vtot ;cosine of angle between detector FOV and pickup ion -velocity vector
cosvsep2=-total(vxyz*sep2ld,1)/vtot
cosvswix=-total(vxyz*swixld,1)/vtot
cosvswiy=-total(vxyz*swiyld,1)/vtot
cosvswiz=-total(vxyz*swizld,1)/vtot
cosvstax=-total(vxyz*staxld,1)/vtot
cosvstay=-total(vxyz*stayld,1)/vtot
cosvstaz=-total(vxyz*stazld,1)/vtot

phiswixy=atan(cosvswiy,cosvswix); swia phi angles (-pi to pi)
phistaxy=atan(cosvstay,cosvstax); stat phi angles (-pi to pi)
thevswiz=!radeg*acos(cosvswiz) ;swia theta angles (0-180 degrees)
thevstaz=!radeg*acos(cosvstaz) ;stat theta angles (0-180 degrees)

phswixy=8. +8.*phiswixy/!pi
phstaxy=8.5+8.*phistaxy/!pi
thvswiz=2.*rfov*(90.-thevswiz)/45.
thvstaz=2.*rfov*(90.-thevstaz)/45.
binswixy=(floor(phswixy)+7) mod 16 ;swia azimuth bin (22.5  to 360+22.5  deg -> 0 to 15)
binstaxy=(floor(phstaxy)+7) mod 16 ;stat azimuth bin (11.25 to 360+11.25 deg -> 0 to 15)
binvswiz=2+floor(thvswiz) ;swia elevation bin (+45 to -45 deg -> 0 to 3)
binvstaz=2+floor(thvstaz) ;stat elevation bin (+45 to -45 deg -> 0 to 3)

disphixy=[phswixy,phstaxy]-floor([phswixy,phstaxy]) ;distance from edge of azimuth bin [0 to 1]
disvthez=[thvswiz,thvstaz]-floor([thvswiz,thvstaz]) ;distance from edge of elevation bin [0 to 1]
dsphixy=1.-abs(2.*disphixy-1.)
dsvthez=1.-abs(2.*disvthez-1.)
qfxyz=dsphixy*dsvthez ;angular quality flag

binsepke=floor(ke); linear energy step binning (keV)
bintotke=126-floor(alog(1e3*ke)/pui0.totdee); log energy step ln(eV) for all flux (edges: 328 keV to 14.9 eV with 10% resolution)
binswike= 69-floor(alog(1e3*ke)/pui0.swidee); log energy step ln(eV) for SWIA (since Nov 27, 2014)
binstake= 63-floor(alog(1e3*ke)/pui0.stadee); log energy step ln(eV) for STATIC (only pickup mode)
binsepke[where(binsepke gt pui0.sormd-1,/null)]=pui0.sormd-1 ;if bins are outside the range, put them at the last energy bin (lowest energy)
bintotke[where((bintotke lt 0) or (bintotke gt pui0.toteb-1),/null)]=pui0.toteb-1 ;(lowest energy)
binswike[where((binswike lt 0) or (binswike gt pui0.swieb-1) or (binswixy lt 0) or (binvswiz lt 0) or (binvswiz gt 3),/null)]=pui0.swieb-1
binstake[where((binstake lt 0) or (binstake gt pui0.staeb-1) or (binstaxy lt 0) or (binvstaz lt 0) or (binvstaz gt 3),/null)]=pui0.staeb-1

sinfovswi=sin(!dtor*45./rfov) ;swia and static +Z opening angle
rfovswia=rfov
rfovstat=rfov
rfovswia[where(abs(cosvswiz) gt sinfovswi,/null)]=0.
rfovstat[where(abs(cosvstaz) gt sinfovswi,/null)]=0.

sdea1=mvn_pui_sep_angular_response(cosvsep1,cosvsep2,cosvswiy)
sdea2=mvn_pui_sep_angular_response(cosvsep2,cosvsep1,cosvswiy)

secof=(ke-40.)/40. ;sep energy response for oxygen, 0 below 40 keV, linearly reaching 1 at 80 keV
secof[where(ke lt 40.,/null)]=0.
secof[where(ke gt 80.,/null)]=1.
sepqf=[[[sdea1*secof]],[[sdea2*secof]]] ;sep quality flag per particle, dim=[np,nt,2]
sqf=max(sepqf,dimension=1,/nan) ;sep quality flag, dim=[nt,2]
pui.model[msub].fluxes.sep.qf=transpose(sqf)
sdeaecof=transpose(rebin(sepqf,[np,nt,2,6]),[3,0,1,2]) ;adding a 6-element dimension for rv, dim=[6,np,nt,2]

;sep detected particle sources
for i=0,1 do begin ;loop over sep's
  pui.model[msub].fluxes.sep[i].rv=total(pui.model[msub].rv*sdeaecof[*,*,*,i],2,/nan)/total(sdeaecof[*,*,*,i],2,/nan)
endfor

kfsep1=replicate(0.,pui0.sormd,nt) ;sep1 flux binning
kfsep2=kfsep1 ;sep2 flux binning
keflux=replicate(0.,pui0.toteb,nt) ;total flux binning
kefswi=replicate(0.,pui0.swieb,nt) ;swia flux binning
kefsta=replicate(0.,pui0.staeb,nt) ;static flux binning
knflux=keflux
indgent=indgen(nt)

for ip=1,np-1 do begin ;loop over particles
  kfsep1[binsepke[ip,*],indgent]+=dphi[ip,*]*sdea1[ip,*] ;bin pickup ion fluxes that are within the FOV
  kfsep2[binsepke[ip,*],indgent]+=dphi[ip,*]*sdea2[ip,*]
  keflux[bintotke[ip,*],indgent]+=dphi[ip,*]; total energy flux
  kefswi[binswike[ip,*],indgent]+=dphi[ip,*]*rfovswia[ip,*]; energy flux
  kefsta[binstake[ip,*],indgent]+=dphi[ip,*]*rfovstat[ip,*]; energy flux
  knflux[bintotke[ip,*],indgent]+=1. ;number of particles in this bin
endfor

keflux[where(knflux gt 0. and knflux lt 3.*pui0.ngps[msub],/null)]=!values.f_nan ;less than 3 counts in each gyro-period means bad statistics!
pui.model[msub].fluxes.sep[0].incident_rate=kfsep1
pui.model[msub].fluxes.sep[1].incident_rate=kfsep2
pui.model[msub].fluxes.toteflux=keflux/pui0.totdee; total pickup angle-integrated differential energy flux (eV/[cm2 s eV])
pui.model[msub].fluxes.swi1d.eflux=kefswi/pui0.swidee/pui0.swiatsa; differential energy flux (eV/[cm2 s sr eV])
pui.model[msub].fluxes.sta1d.eflux=kefsta/pui0.stadee/pui0.swiatsa; differential energy flux (eV/[cm2 s sr eV])

if pui0.do3d then begin
  swi3d=replicate({ef:0.,nn:0.,qf:0.,rv:replicate(0.,6)},pui0.swieb,pui0.swina,pui0.swine,nt) ;swia 3d eflux binning
  sta3d=replicate({ef:0.,nn:0.,qf:0.,rv:replicate(0.,6)},pui0.sd1eb,pui0.swina,pui0.swine,nt) ;stat 3d eflux binning

  d1energy=pui.data.sta.d1.energy ;static d1 energy table
  d1enedge=sqrt(d1energy[0:-2,*]*d1energy[1:-1,*]) ;static d1 energy bin edges (missing the ending points)
  ebinedge=replicate(0.,pui0.sd1eb+1,nt) ;add the ending points
  ebinedge[1:-2,*]=d1enedge
  ebinedge[0,*]=ebinedge[1,*]*(1+pui.data.sta.d1.dee) ;highest energy edge
  ebinedge[-1,*]=ebinedge[-2,*]/(1+pui.data.sta.d1.dee) ;lowest energy edge

  binstake=replicate(pui0.sd1eb-1,np,nt) ;initialize static bins at lowest energy
  for ie=0,pui0.sd1eb-1 do begin ;bin according to energy
    ebin1=replicate(1.,np)#ebinedge[ie,*]
    ebin0=replicate(1.,np)#ebinedge[ie+1,*]
    binstake[where((1e3*ke gt ebin0) and (1e3*ke lt ebin1),/null)]=ie
  endfor

  binstake[where((binstaxy lt 0) or (binvstaz lt 0) or (binvstaz gt 3),/null)]=pui0.sd1eb-1 ;(lowest energy bin)
  binswixy[where((binswixy lt 0),/null)]=0 ;if not in swia's azimuth bin range due to NaN's in phiswixy
  binstaxy[where((binstaxy lt 0),/null)]=0 ;if not in stat's azimuth bin range
  binvswiz[where((binvswiz lt 0) or (binvswiz gt 3),/null)]=0 ;if outside swia's elevation fov
  binvstaz[where((binvstaz lt 0) or (binvstaz gt 3),/null)]=0 ;if outside stat's elevation fov

  for ip=1,np-1 do begin ;loop over particles
    dphirfov=dphi[ip,*]*rfov[ip,*]
    swi3d[binswike[ip,*],binswixy[ip,*],binvswiz[ip,*],indgent].ef+=dphirfov ;energy flux
    sta3d[binstake[ip,*],binstaxy[ip,*],binvstaz[ip,*],indgent].ef+=dphirfov
    swi3d[binswike[ip,*],binswixy[ip,*],binvswiz[ip,*],indgent].nn+=1. ;number of particles in this bin
    sta3d[binstake[ip,*],binstaxy[ip,*],binvstaz[ip,*],indgent].nn+=1.
    swi3d[binswike[ip,*],binswixy[ip,*],binvswiz[ip,*],indgent].qf+=qfxyz[ip,*] ;quality flag
    sta3d[binstake[ip,*],binstaxy[ip,*],binvstaz[ip,*],indgent].qf+=qfxyz[np+ip,*]
;    swi3d[binswike[ip,*],binswixy[ip,*],binvswiz[ip,*],indgent].rv+=pui.model[msub].rv[*,ip] ;swia 3d particle position and velocity binning
;    sta3d[binstake[ip,*],binstaxy[ip,*],binvstaz[ip,*],indgent].rv+=pui.model[msub].rv[*,ip] ;stat 3d particle position and velocity binning
    swi3d[binswike[ip,*],binswixy[ip,*],binvswiz[ip,*],indgent].rv+=pui.model[msub].rv[*,ip]*(replicate(1.,6)#dphirfov) ;binning weighed based on efluxes
    sta3d[binstake[ip,*],binstaxy[ip,*],binvstaz[ip,*],indgent].rv+=pui.model[msub].rv[*,ip]*(replicate(1.,6)#dphirfov)
  endfor

  swi3d[where(swi3d.nn gt 0. and swi3d.nn lt 3.*pui0.ngps[msub],/null)].ef=!values.f_nan ;less than 3 counts in each gyro-period means bad statistics!
  sta3d[where(sta3d.nn gt 0. and sta3d.nn lt 3.*pui0.ngps[msub],/null)].ef=!values.f_nan
  pui.model[msub].fluxes.swi3d.eflux=swi3d.ef/pui0.swiatsa*pui0.swina*pui0.swine/pui0.swidee; differential energy flux (eV/[cm2 s sr eV])
  pui.model[msub].fluxes.sta3d.eflux=sta3d.ef/pui0.swiatsa*pui0.swina*pui0.swine/transpose(rebin(pui.data.sta.d1.dee,[nt,pui0.sd1eb,pui0.swina,pui0.swine]),[1,2,3,0])
  pui.model[msub].fluxes.swi3d.qf=swi3d.qf/swi3d.nn ;average quality flag
  pui.model[msub].fluxes.sta3d.qf=sta3d.qf/sta3d.nn
;  pui.model[msub].fluxes.swi3d.rv=swi3d.rv/transpose(rebin(swi3d.nn,[pui0.swieb,pui0.swina,pui0.swine,nt,6]),[4,0,1,2,3])
;  pui.model[msub].fluxes.sta3d.rv=sta3d.rv/transpose(rebin(sta3d.nn,[pui0.sd1eb,pui0.swina,pui0.swine,nt,6]),[4,0,1,2,3])
  pui.model[msub].fluxes.swi3d.rv=swi3d.rv/transpose(rebin(swi3d.ef,[pui0.swieb,pui0.swina,pui0.swine,nt,6]),[4,0,1,2,3])
  pui.model[msub].fluxes.sta3d.rv=sta3d.rv/transpose(rebin(sta3d.ef,[pui0.sd1eb,pui0.swina,pui0.swine,nt,6]),[4,0,1,2,3])
endif
;stop
end