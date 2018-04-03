;20160705 Ali
;routine to plot exospheric density profiles used in mvn_pui_model
;
pro mvn_pui_plot_exoden,hoto=hoto,thermalh=thermalh,h2=h2,overplot=overplot,xrange=xrange,yrange=yrange,xtitle=xtitle,ytitle=ytitle

rmars=3400. ;mars radius (km)

alt=1e3*findgen(3000)/10. ;altitude (km): 100 to ~100,000 km (results not reliable for hot O below ~600 km)
rtot=1e3*(alt+rmars) ;radial distance (m)

nno=mvn_pui_exoden(rtot,species='o') ;O density (cm-3)
nnh=mvn_pui_exoden(rtot,species='h') ;H density (cm-3)
nh2=mvn_pui_exoden(rtot,species='h2') ;H2 density (cm-3)

;if ~keyword_set(xrange) then xrange=[1,1e6]
;if ~keyword_set(yrange) then yrange=[1e2,1e5]
;if ~keyword_set(xtitle) then xtitle='$Mars Exospheric Neutral Density (cm^{-3})$'
;if ~keyword_set(ytitle) then ytitle='Altitude (km)'
;p=plot([0],overplot=overplot,/xlog,/ylog,xrange=xrange,yrange=yrange,xtitle=xtitle,ytitle=ytitle)
if keyword_set(hoto) then p=plot(nno,alt,'k:',name='Rahmati et al. [2014]',/o)
if keyword_set(thermalh) then p=plot(nnh,alt,'b',name='Feldman et al. [2011]',/o)
if keyword_set(h2) then p=plot(nh2,alt,'g',/o)

end