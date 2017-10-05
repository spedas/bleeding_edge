;20160705 Ali
;routine to plot exospheric density profiles used in mvn_pui_model
;
pro mvn_pui_plot_exoden,hoto=hoto,thermalh=thermalh,h2=h2,overplot=overplot,xrange=xrange,yrange=yrange

rmars=3400. ;mars radius (km)

alt=1e3*findgen(1000)/10. ;altitude (km): 100 to ~100,000 km (results not reliable for hot O below ~600 km)
rtot=1e3*(alt+rmars) ;radial distance (m)

nno=mvn_pui_exoden(rtot,species='o') ;O density (cm-3)
nnh=mvn_pui_exoden(rtot,species='h') ;H density (cm-3)
nh2=mvn_pui_exoden(rtot,species='h2') ;H2 density (cm-3)

if ~keyword_set(xrange) then xrange=[1,1e6]
if ~keyword_set(yrange) then yrange=[1e2,1e5]
p=plot([0],overplot=overplot,/xlog,/ylog,xrange=xrange,yrange=yrange,title='',xtitle='$Mars Exospheric Neutral Density (cm^{-3})$',ytitle='Altitude (km)')
if keyword_set(hoto) then p=plot(nno,alt,color='r',/o)
if keyword_set(thermalh) then p=plot(nnh,alt,color='b',/o)
if keyword_set(h2) then p=plot(nh2,alt,color='g',/o)

end