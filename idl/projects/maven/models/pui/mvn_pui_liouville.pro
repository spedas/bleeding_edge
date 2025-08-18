;08/28/2013 Ali
;this code takes in the energy distribution function
;at the exobase and uses the Liouville equation
;[Schunk and Nagy, 2009] eqs: 10.102-104 (simplified) 
;to calculate the exospheric density

pro mvn_pui_liouville,nexo=nexo,texo=texo,nr=nr,phiesc=phiesc

;------Constants------
kb=1.381e-16; %Boltzmann constant (erg K-1)
qe=1.602e-12; %electron charge (erg/eV)
an=6.022e23; %Avogadro's number (mol-1)
gc=6.674e-8; %gravitational constant (cm3 g-1 s-2)
mmars=6.4185e26; %mass of Mars (g)
rmars=3400e5; %radius of mars (cm)
zexo=200e5 ;exobase altitude (cm)
mamu=1. ;particle mass (amu or g/mol)
mp=mamu/an ;particle mass (g)
avmu=.5; %<mu>: average of cosine of pitch angle

g0=gc*mmars/rmars^2; %gravitational acceleration at Mars' surface (cm s-2)
rexo=rmars+zexo; %radial distance at exobase (cm)
gexo=g0*(rmars/rexo)^2; %g @ rexo (cm s-2)
vesc=sqrt(2.*gexo*rexo); %escape velocity (cm s-1)
enesc=mp*gexo*rexo/qe; %escape energy of particle (eV)

;------Parameters------
if ~keyword_set(texo) then texo=200.; Temperature at the exobase (K)
if ~keyword_set(nexo) then nexo=2.5e5; Density at the exobase (cm-3)
kt=kb*texo/qe ;KT (eV)

enbins=3000 ;energy bins
de=0.0001; %energy increment (eV)
escbin=floor(enesc/de)
en=de*findgen(enbins); energies (eV)
ve=(2*en*qe/mp)^.5; %particle velocities (cm s-1)
fe=nexo*2.*((en/!pi/kt^3)^.5)*exp(-en/kt) ;energy distribution function (cm-3 eV-1)
phiup=.5*fe*ve ;differential up-flux (cm-2 s-1 eV-1) half goes up!
phiesc=avmu*de*total(phiup[escbin:*]) ;escape flux (cm-2 s-1)
fe[escbin:*]/=2. ;no phi-down for escape energies
ntot=de*total(fe) ;check: should be almost equal to nexo, otherwise something's wrong!
nesc=de*total(fe[escbin:*]) ;escaping density (cm-3)

;------Liouville------
zbins=1000 ;altitude bins above exobase
dz=100e5 ;altitude increment (cm)
rr=rexo+dz*findgen(zbins); radial distances above the exobase (cm)
yy=rexo/rr; %rc/r (or y in Schunk and Nagy, 2009)
zz=rr-rmars; altitudes starting at the exobase (cm)
v1=vesc*sqrt(1-yy);
v2=vesc/sqrt(1+yy);

ner=replicate(0.,zbins,enbins); %preallocating ne(r) (cm-3 eV-1)
for i=0,zbins-1 do begin
  for j=1,enbins-1 do begin
    q=0;
    if ve[j] gt v1[i] then q=sqrt(ve[j]^2-v1[i]^2);
    if ve[j] ge v2[i] then q=q-sqrt((1-yy[i]^2)*ve[j]^2-v1[i]^2);
;    if ve(j) ge vesc  then q=q/2 ;if velocity greater than escape velocity they never come back!
    ;the above line should be commented out if already taken care of in "fe"
    ner[i,j]=fe[j]*q/ve[j];
  endfor
endfor

nrtot=de*total(ner,2) ;density profile (cm-3)
nresc=de*total(ner[*,escbin:*],2) ;escaping density profile (cm-3)

p=plot(en,fe,/xlog,/ylog,yrange=[1,1e7],xtitle='Energy (eV)',ytitle='Distribution Function (cm-3 eV-1)')
p=plot(nrtot,zz/1e5,/ylog,/xlog) ;total
p=plot(nresc,zz/1e5,/ylog,/xlog,/o,c='r') ;escaping
p=plot(nrtot-nresc,zz/1e5,/ylog,/xlog,/o,c='b') ;bound
mvn_pui_plot_exoden,/overplot,/thermalh

;nr=nrtot[10] ;density at 10200 km (cm-3)
stop

end