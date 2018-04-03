;20161228 Ali
;calculates Martian exospheric neutral O and H densities (or cometary H2O),
;assuming a spherically symmetric neutral exosphere (cometary netural coma)
;inputs:
;     rtot: radial distance in "meters" from the center of Mars (comet)
;     species: neutral species name (string)
;         o: oxygen
;         h: hydrogen
;         h2: H2
;         css: comet siding spring
;output: density at rtot in "cm-3"
;keyword plot_exoden ignores rtot and plots the radial density profile for the given species

function mvn_pui_exoden,rtot,species=species,plot_exoden=plot_exoden

if keyword_set(plot_exoden) then begin
  rtot=1e6*(3+findgen(98)) ;radius (m) (3000 to 100,000 km)
  p=plot(mvn_pui_exoden(rtot,species=species),rtot/1e3,/xlog,/ylog,xtitle='$Neutral Density (cm^{-3})$',ytitle='Radial Distance (km)')
  return,'plot created.'
endif

qqo=5e22 ; for Mars O exosphere (m-0.9) fit to Rahmati et al., 2014 (Phiesc=9e7 cm-2 s-1)
qqh=4e27 ; for Mars H exosphere (m-0.3) fit to Feldman et al., 2011 (Nexo=2.5e5 cm-3, Texo=200 K, Phiesc=8e7 cm-2 s-1)
qh2=2e38 ; for Mars H2 exosphere (m1.5) fit to Liouville (same exo parameters as H)

nno=qqo/((rtot-2400e3)^2.1) ;O density (m-3)
nnh=qqh/((rtot-2700e3)^2.7) ;H density (m-3)
nh2=qh2/((rtot-2700e3)^4.5) ;H2 density (m-3)

qqcss=1e28 ;comet H2O production rate (s-1)
vout=1e3 ;comet outflow speed (m)
nncss=qqcss/(4.*!pi*rtot^2*vout) ;comet coma H2O density (m-3)

case strlowcase(species) of
  'o':nnn=nno
  'h':nnn=nnh
  'h2':nnn=nh2
  'css':nnn=nncss
endcase

return,1e-6*nnn ;cm-3

end