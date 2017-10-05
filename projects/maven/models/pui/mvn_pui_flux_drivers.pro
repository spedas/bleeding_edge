;20160706 Ali
;models pickup ion fluxes using given constant upstream driver parameters

pro mvn_pui_flux_drivers,do3d=do3d

@mvn_pui_commonblock.pro ;common mvn_pui_common

nt=1 ;number of time steps
np=10000 ;number of simulated particles (1000 is enough for one gyro-period)
ns=2;  number of simulated species. default is 2 (H and O)
get_timespan,trange
mvn_pui_aos,nt=nt,np=np,ns=ns,trange=trange,do3d=do3d ;initializes the array of structures for time series (pui) and defines intrument constants

pui0.msub=1 ;species subscript (0=H, 1=O)
pui0.mamu[pui0.msub]=16. ;mass of [H=1 C=12 N=14 O=16] (amu)
pui0.ngps[pui0.msub]=1.49 ;for SEP one full gyro-period is necessary, a few gyro-periods required for pickup hydrogen

pui.centertime=dgen(nt,range=timerange(trange))
pui.data.mag.mso=1e-9*[0,4,0] ;magnetic field (T)
;pui.data.mag.mso[0]=1e-9*findgen(nt)
pui.data.swi.swim.velocity_mso=[-500,0,0] ;solar wind velocity (km/s)
pui.data.scp=[7000e3,0,0] ;s/c position (m)
pui.data.swi.swim.density=5. ;solar wind density (cm-3)
pui.data.sep[0].fov=[1,-1,0]/sqrt(2)
pui.data.sep[1].fov=[1,+1,0]/sqrt(2)

mvn_pui_data_analyze
pui.model[pui0.msub].ifreq.tot=3e-7*replicate(1.,nt) ;ionization frequency (s-1)

mvn_pui_solver ;solve pickup ion trajectories

;csspos=1e3*spice_body_pos('CSS','MARS',frame='MSO',utc='14-10-19/18:30') ;CSS position MSO (m)

;rcss=sqrt((r3x-csspos[0])^2+(r3y-csspos[1])^2+(r3z-csspos[2])^2) ;pickup ion distance from CSS (m)

nnh=mvn_pui_exoden(pui2.rtot,species='h') ;neutral exospheric density (cm-3)
nno=mvn_pui_exoden(pui2.rtot,species='o')
;nncss=mvn_pui_exoden(rcss,'css')

;nden=nncss
nden=nno
dphi=mvn_pui_flux_calculator(nden) ;pickup ion differential number flux (cm-2 s-1)
mvn_pui_binner,dphi ;bin the results
if pui0.msub eq 1 then mvn_pui_sep_energy_response
if nt gt 1 then mvn_pui_tplot,/store,/tplot

if nt eq 1 then begin
  times=dgen(np,range=timerange(trange))
  rxyz=transpose(pui.model[pui0.msub].rv[0:2,*])
  vxyz=transpose(pui.model[pui0.msub].rv[3:5,*])
  deph=pui2.ke*dphi ;differential energy flux (eV cm-2 s-1)
  dnnn=dphi/(1e2*pui2.vtot) ;differential density (cm-3)
  nnn=total(dnnn,/nan,/cumulative) ;cumulative density (cm-3)
  phi=total(dphi,/cumulative) ;cumulative phi (cm-2 s-1)
  store_data,'pui_r_(km)',data={x:times,y:[[rxyz],[pui2.rtot]]/1e3},limits={labels:['x','y','z','r'],colors:'bgrk',labflag:1}
  store_data,'pui_v_(km/s)',data={x:times,y:[[vxyz],[pui2.vtot]]/1e3},limits={labels:['x','y','z','v'],colors:'bgrk',labflag:1}
  ;  store_data,'pui_R_(km)',data={x:times,y:transpose([pui2.rtot,rcss]/1e3)},limits={colors:'br',labels:['Mars','CSS'],labflag:1}
  store_data,'pui_source_neutral_n_(cm-3)',data={x:times,y:[[nnh],[nno]]},limits={labels:['H','O','CSS'],colors:'brg',labflag:1,ylog:1}
  store_data,'pui_dr_(km)',times,pui2.dr/1e3
  store_data,'pui_E_(keV)',times,pui2.ke/1e3
  store_data,'pui_dE_(keV)',times,pui2.de/1e3
  store_data,'pui_E/dE',data={x:times,y:pui2.ke/abs(pui2.de)},limits={ylog:1}
  store_data,'pui_dr/dE_(m/eV)',data={x:times,y:pui2.dr/abs(pui2.de)},limits={ylog:1}
  store_data,'pui_dphi/dE_(/cm2.s.eV)',data={x:times,y:dphi/abs(pui2.de)},limits={ylog:1}
  store_data,'pui_dphi_(/cm2.s)',data={x:times,y:dphi},limits={ylog:1}
  store_data,'pui_cumulative_phi_(/cm2.s)',data={x:times,y:phi}
  store_data,'pui_dEphi/dE_(eV/cm2.s.eV)',data={x:times,y:deph/abs(pui2.de)},limits={ylog:1}
  store_data,'pui_dn/dE_(/cm3.eV)',data={x:times,y:dnnn/abs(pui2.de)},limits={ylog:1}
  store_data,'pui_dn_(cm-3)',data={x:times,y:dnnn},limits={ylog:1}
  store_data,'pui_cumulative_n_(cm-3)',times,nnn
  
;  p=plot([0],/nodata,/xlog,/ylog,xrange=[100,100e3],yrange=[1000,1000e3],xtitle='Pickup Ion Energy (eV)',ytitle='Differential Energy Flux (eV/[cm2 s eV])')
;  p=plot(pui2.ke,deph/abs(pui2.de),/o,'b')
;  p=plot(pui1.totet,pui.model[pui0.msub].fluxes.toteflux,/o,'r')

  p=plot([0],/nodata,/xlog,/ylog,xrange=[1,100],yrange=[10,1e5],xtitle='Pickup Ion Energy (keV)',ytitle='Differential Flux $(/[cm^2 s keV])$')
;  p=plot(pui2.ke/1e3,dphi/abs(pui2.de/1e3),/o,'b')
flux=1e3*pui.model[pui0.msub].fluxes.toteflux/pui1.totet ;Differential Flux (/[cm2 s keV])
  p=plot(pui1.totet/1e3,flux,/o,'b')

 ; p=plot([0],/nodata,/ylog,xtitle='Pickup Ion Energy (keV)',ytitle='Differential Density (/[cm3 keV])')
 ; p=plot(pui2.ke/1e3,1e3*dnnn/abs(pui2.de),/o,'b')
 ; p=plot(pui2.ke/1e3,nnn,/o,'r')

;  p=plot3d(vxyz[*,0]/1e3,vxyz[*,1]/1e3,vxyz[*,2]/1e3,/aspect_ratio,/aspect_z,xtitle='Vx (km/s)',ytitle='Vy (km/s)',ztitle='Vz (km/s)')
;  rmars=3400e3 ;radius of mars (m)
;  p=plot3d(rxyz[*,0]/rmars,rxyz[*,1]/rmars,rxyz[*,2]/rmars)
;  p=scatterplot3d(/o,csspos[0]/rmars,csspos[1]/rmars,csspos[2]/rmars)
;  mvn_pui_plot_mars_bow_shock,/rm,/p3d
endif

duration=33.*30.5*24.*60.*60. ;seconds in 33 months
fluence=16.*1e3*duration*flux ;fluence (/[cm2 sr MeV/nucleon])
energy=pui1.totet/1e6/16. ;Energy (MeV/nucleon)

p=plot([0],/nodata,/xlog,/ylog,xrange=[1e-4,1e-2],xtitle='Pickup O+ Energy (MeV/nucleon)',ytitle='33 Month Fluence $(/[cm^2 MeV/nucleon])$',xtickunits='scientific')
p=plot(energy,fluence,/o,'b')

stop
end