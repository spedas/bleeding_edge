if keyword_set(do3d) then begin
  phiswixynt=phiswixy[in,it]
  phistaxynt=phistaxy[in,it]
  for j=0,swina-1 do begin
    for k=0,swine-1 do begin
      if ((phiswixynt gt phifovswi[j]) && (phiswixynt lt phifovswi[j+1]) && (cosvswiznt gt sin(thefovswi[k]/rfovnt)) $
        && (cosvswiznt lt sin(thefovswi[k+1]/rfovnt)) && (lnkeswiant ge 0) && (lnkeswiant le swieb-1)) then begin
        kefswi3d[in,lnkeswiant,j,k]+=ntotnt*rfovnt; %energy flux
        krrswi3d[in,lnkeswiant,j,k,*]+=[r3x[in,it],r3y[in,it],r3z[in,it]] ;starting positions of pickup ions (m)
        knnswi3d[in,lnkeswiant,j,k]+=1 ;number of particles in this bin
      endif
      if ((phistaxynt gt phifovsta[j]) && (phistaxynt lt phifovsta[j+1]) && (cosvstaznt gt sin(thefovswi[k]/rfovnt)) $
        && (cosvstaznt lt sin(thefovswi[k+1]/rfovnt)) && (lnkestatnt ge 0) && (lnkestatnt le staeb-1)) then begin
        kefsta3d[in,lnkestatnt,j,k]+=ntotnt*rfovnt; %energy flux
      endif
    endfor
  endfor
endif

for in=0,inn-1 do begin ;loop over time

  ntotnt=ntot[in,it]
  rfovnt=rfov[in,it]
  kestepnt=kestep[in,it]
  lnkestepnt=lnkestep[in,it]
  lnkeswiant=lnkeswia[in,it]
  lnkestatnt=lnkestat[in,it]
  sinfovswint=sinfovswi[in,it]
  cosvswiznt=cosvswiz[in,it]
  cosvstaznt=cosvstaz[in,it]

  ;    if (cosvsep1[in,it] gt cosfovsep) then keflux1[in,kestepnt]+=ntotnt*sdea1[in,it]; bin pickup ion fluxes that are within the FOV
  ;    if (cosvsep2[in,it] gt cosfovsep) then keflux2[in,kestepnt]+=ntotnt*sdea2[in,it]
  ;    if ((lnkestepnt ge 0) && (lnkestepnt le toteb-1)) then keflux[in,lnkestepnt]+=ntotnt; %total energy flux
  ;    if ((abs(cosvswiznt) lt sinfovswint) && (lnkeswiant ge 0) && (lnkeswiant le swieb-1)) then kefswi[in,lnkeswiant]+=ntotnt*rfovnt; %energy flux
  ;    if ((abs(cosvstaznt) lt sinfovswint) && (lnkestatnt ge 0) && (lnkestatnt le staeb-1)) then kefsta[in,lnkestatnt]+=ntotnt*rfovnt; %energy flux


endfor