;20170417 Ali
;statistical analysis of pickup ion model results
;can be used to compute exospheric neutral densities using a reverse method

pro mvn_pui_results2

@mvn_pui_commonblock.pro ;common mvn_pui_common

kefswih3d=transpose(pui.model[0].fluxes.swi3d.eflux,[3,0,1,2]) ;pickup energy flux
kefswio3d=transpose(pui.model[1].fluxes.swi3d.eflux,[3,0,1,2])
kefstah3d=transpose(pui.model[0].fluxes.sta3d.eflux,[3,0,1,2])
kefstao3d=transpose(pui.model[1].fluxes.sta3d.eflux,[3,0,1,2])

krvswih3d=transpose(pui.model[0].fluxes.swi3d.rv,[4,1,2,3,0]) ;pickup position,velocity
krvswio3d=transpose(pui.model[1].fluxes.swi3d.rv,[4,1,2,3,0])
krvstah3d=transpose(pui.model[0].fluxes.sta3d.rv,[4,1,2,3,0])
krvstao3d=transpose(pui.model[1].fluxes.sta3d.rv,[4,1,2,3,0])

krrswih3d=sqrt(total(krvswih3d[*,*,*,*,0:3]^2,5))/1e3 ;pickup radial distance (km)
krrswio3d=sqrt(total(krvswio3d[*,*,*,*,0:3]^2,5))/1e3
krrstah3d=sqrt(total(krvstah3d[*,*,*,*,0:3]^2,5))/1e3
krrstao3d=sqrt(total(krvstao3d[*,*,*,*,0:3]^2,5))/1e3

szaswih3d=!radeg*mvn_pui_sza(krvswih3d[*,*,*,*,0],krvswih3d[*,*,*,*,1],krvswih3d[*,*,*,*,2]) ;pickup solar zenith angle (degrees)
szaswio3d=!radeg*mvn_pui_sza(krvswio3d[*,*,*,*,0],krvswio3d[*,*,*,*,1],krvswio3d[*,*,*,*,2])
szastah3d=!radeg*mvn_pui_sza(krvstah3d[*,*,*,*,0],krvstah3d[*,*,*,*,1],krvstah3d[*,*,*,*,2])
szastao3d=!radeg*mvn_pui_sza(krvstao3d[*,*,*,*,0],krvstao3d[*,*,*,*,1],krvstao3d[*,*,*,*,2])

;swap swia dimentions to match the model (time-energy-az-el)
;also, reverse the order of elevation (deflection) angles to start from positive theta (like static)
swiaef3d=reverse(transpose(pui.data.swi.swica.data,[3,0,2,1]),4)
d1eflux=transpose(pui.data.sta.d1.eflux,[4,0,1,2,3])

knnswio3d=swiaef3d/kefswio3d/(~kefswih3d) ;exospheric neutral density (cm-3) data/model ratio
knnswih3d=swiaef3d/kefswih3d/(~kefswio3d)
knnstao3d=d1eflux[*,*,*,*,4]/kefstao3d
knnstah3d=d1eflux[*,*,*,*,0]/kefstah3d

scp=pui.data.scp
szascp=!radeg*mvn_pui_sza(scp[0,*],scp[1,*],scp[2,*]) ;s/c solar zenith angle (degrees)


sep1model=pui.model[1].fluxes.sep[0].model_rate
sep2model=pui.model[1].fluxes.sep[1].model_rate
sep1data=pui.data.sep[0].rate_bo
sep2data=pui.data.sep[1].rate_bo

sep1mtot=total(sep1model[0:15,*],1)
sep2mtot=total(sep2model[0:15,*],1)
sep1dtot=total(sep1data[0:15,*],1)
sep2dtot=total(sep2data[0:15,*],1)

sep1d2m=sep1dtot/sep1mtot
sep2d2m=sep2dtot/sep2mtot

krvsep1=pui.model[1].fluxes.sep[0].rv[0:2]
krvsep2=pui.model[1].fluxes.sep[1].rv[0:2]
krrsep1=sqrt(total(krvsep1^2,1))
krrsep2=sqrt(total(krvsep2^2,1))

nn=sep2d2m
;p=plot(nn,/ylog,'o',yrange=[1e-2,1e2])
index=where((nn gt .01) and (nn lt 100))
avg=exp(mean(alog(nn[index]),/nan))

stop



nnn=knnswih3d[*,0:24,*,*]
rrr=krrswih3d[*,0:24,*,*]
sza=szaswih3d[*,0:24,*,*]
p=plot(transpose(nnn),/ylog,'.')
p=plot(transpose(rrr),/ylog,'.')
p=plot(transpose(sza),/ylog,'.')
p=plot(nnn,rrr,/xlog,/ylog,'.')
avg=exp(mean(alog(nn),/nan))
stop

end
