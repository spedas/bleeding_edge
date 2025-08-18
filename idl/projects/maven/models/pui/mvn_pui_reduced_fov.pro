;20160708 Ali
;routine to calculated and plot dependence of SWIA and STATIC elevation coverage on energy
;to show reduced FOV at high energies
;input: energy in keV
;output: correction factor for SWIA and STATIC reduced FOV at E>5keV
;
function mvn_pui_reduced_fov,ke,plot_fov=plot_fov

if keyword_set(plot_fov) then begin
  ke=.1*findgen(301) ;energy (keV) from 100 eV to 30 keV
  rfov=mvn_pui_reduced_fov(ke)
  fov=45./rfov
  p=plot(1e3*ke,fov,/xlog,/ylog,xtitle='SWIA and STATIC Energy (eV)',ytitle='Elevation Coverage (Degrees)')

  q=1.602e-19; %electron charge (C)
  mp=1.67e-27; %proton mass (kg)
  mamu=16; %mass of [H=1 C=12 N=14 O=16] (amu)
  m=mamu*mp; %pickup ion mass (kg)

  ke25=ke
  ke25[where(ke25 gt 25.,/null)]=25.
  ;uncomment the following two lines to get constant energy contours
  ;ke25=30 ;energy in keV
  ;fov=findgen(91)

  vx=sqrt(2*ke25*1e3*q/m)*cos(!dtor*fov) ;m/s
  vy=sqrt(2*ke25*1e3*q/m)*sin(!dtor*fov) ;m/s

  p=plot([-vx,reverse(-vx)]/1e3,[vy,reverse(-vy)]/1e3,/aspect_ratio,xtitle='Vx (km/s)',ytitle='Vy (km/s)')

  return,'plots created.'
endif

rfov=1.+(ke-5.)/5.; correction factor for SWIA and STATIC reduced FOV at E>5keV
rfov[where(rfov lt 1.,/null)]=1.

return, rfov

end