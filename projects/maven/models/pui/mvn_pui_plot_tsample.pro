;20170216 Ali
;line plots and 3D representations of model and data at the times specified by cursor
;keywords:
;avrg: for averaged values over a time period
;tplot: for selecting the data from the current tplot window

pro mvn_pui_plot_tsample,all=all,tplot=tplot,avrg=avrg,overplot=overplot,xrange=xr,yrange=yr,zeros=zeros,$
  sep=sep,traj=traj,eflux=eflux,swia3d=swia3d,stah3d=stah3d,stao3d=stao3d

@mvn_pui_commonblock.pro ;common mvn_pui_common

if n_elements(zeros) eq 0 then zeros=1e-7 ;to fix the stairs

if keyword_set(tplot) then begin
  var=tsample(val=en,aver=avrg,/silent)
  var[where(var eq 0,/null)]=zeros
  p=plot(en,var,/xlog,/ylog,/stairs,xrange=xr,yrange=yr,xtickunits='scientific',ytickunits='scientific',overplot=overplot)
  return
endif

if keyword_set(avrg) then np=2 else np=1

if keyword_set(all) then begin
  sep=1
  traj=1
  eflux=1
endif

ctime,t,np=np,/silent
tstep=floor((t-pui[0].centertime+pui0.tbin/2.)/pui0.tbin)
if n_elements(tstep) eq 1 then tstep=[tstep,tstep]
tstep[where(tstep lt 0,/null)]=0
tstep[where(tstep gt pui0.nt-1,/null)]=pui0.nt-1
if tstep[0] gt tstep[1] then tstep=reverse(tstep)
tstring=time_string(pui[tstep].centertime)
if ~keyword_set(avrg) then tstring=tstring[0] 
tsteps=lindgen(1l+tstep[1]-tstep[0],start=tstep[0])

rv=1e-3*transpose(average(pui[tsteps].model.rv,4,/nan),[1,2,0]) ;rv (km, km/s)
seprv=1e-3*transpose(average(pui[tsteps].model[1].fluxes.sep.rv,3,/nan)) ;sep rv (km, km/s)
seprv[where(~finite(seprv),/null)]=0. ;for scatterplot to handle NaN's
sepfov=average(pui[tsteps].data.sep.fov,3,/nan) ;sep fov
sep1fov=sepfov[*,0]
sep2fov=sepfov[*,1]
swiyfov=crossp(sep1fov,sep2fov)
vxyz=reform(rv[*,1,3:5])
vtot=sqrt(total(vxyz^2,2))
cosvsep1=-total(vxyz*(replicate(1.,pui0.np)#sep1fov),2)/vtot
cosvsep2=-total(vxyz*(replicate(1.,pui0.np)#sep2fov),2)/vtot
cosvswiy=-total(vxyz*(replicate(1.,pui0.np)#swiyfov),2)/vtot

orbit=1e-3*transpose(pui.data.scp) ;spacecraft position: orbit (km)
stxfov=average(pui[tsteps].data.sta.fov.x,2,/nan) ;static x-fov
stzfov=average(pui[tsteps].data.sta.fov.z,2,/nan) ;static z-fov
scp=1e-3*average(pui[tsteps].data.scp,2,/nan) ;spacecraft position (km)
mag=average(pui[tsteps].data.mag.mso,2,/nan) ;mag field (T)
magdir=mag/sqrt(total(mag^2)) ;mag direction
usw=average(pui[tsteps].data.swi.swim.velocity_mso,2,/nan) ;solar wind velocity (km/s)
uswtot=sqrt(total(usw^2)) ;solar wind speed (km/s)
esw=crossp(-usw,magdir) ;motional electric field direction (km/s)
drf=crossp(esw,magdir) ;drift velocity (km/s)
alfrm=[0.,10.*3400.] ;fov arrow length factor in R_M (km)
vmax=[0.,-max(sqrt(total(rv[*,1,3:5]^2,3)))] ;max pickup speed (km/s)

uswsep=[total(usw*sep1fov),-total(usw*swiyfov),total(usw*sep2fov)]/uswtot
magsep=[total(mag*sep1fov),-total(mag*swiyfov),total(mag*sep2fov)]/sqrt(total(mag^2))
eswsep=[total(esw*sep1fov),-total(esw*swiyfov),total(esw*sep2fov)]/sqrt(total(esw^2))
drfsep=[total(drf*sep1fov),-total(drf*swiyfov),total(drf*sep2fov)]/sqrt(total(drf^2))

if keyword_set(sep) then begin ;SEP
  sepet=pui1.sepet.sepbo ;sep energy table (keV)
  sepie=.5+findgen(500) ;sep incident energy table (keV)
  entot=pui1.totet/1e3 ;tot energy table (keV)

  sepd=average(pui[tsteps].data.sep.rate_bo,3,/nan) ;sep data
  sepm=average(pui[tsteps].model[1].fluxes.sep.model_rate,3,/nan) ;sep model
  sepi=average(pui[tsteps].model[1].fluxes.sep.incident_rate,3,/nan) ;incident in sep fov /[s keV]
  ftot=average(pui[tsteps].model[1].fluxes.toteflux,2,/nan)/entot ;total flux /[s cm2 keV]

  sepd[where(sepd eq 0.,/null)]=zeros
  sepm[where(sepm eq 0.,/null)]=zeros
  sepi[where(sepi eq 0.,/null)]=zeros
  ftot[where(ftot eq 0.,/null)]=zeros

  xr=[0,1e4]
  yr=[.01,1e4]
  xt='Energy (keV)'
  yt='Count Rate/Energy Bin (Hz)'
  ;SEP1F
  p=getwindows('sepflux')
  if keyword_set(p) then p.setcurrent else p=window(name='sepflux')
  p.erase
  p=plot(/current,[0],/nodata,/xlog,/ylog,xrange=xr,yrange=yr,margin=.1,layout=[2,1,1],title='SEP1F',xtitle=xt,ytitle=yt,xtickunits='scientific',ytickunits='scientific')
  p=plot(/o,sepet[*,0],sepd[*,0],/stairs,'r',name='Data (Hz)')
  p=plot(/o,sepet[*,0],sepm[*,0],/stairs,'b',name='Model (Hz)')
  p=plot(/o,sepie,sepi[*,0],'m',name='in FOV (s keV)$^{-1}$')
  p=plot(/o,entot,ftot,'g',name='O+ Flux $(s cm^2 keV)^{-1}$')
  p=legend()
  p=text(0,0,tstring)
  ;SEP2F
  p=plot(/current,[0],/nodata,/xlog,/ylog,xrange=xr,yrange=yr,margin=.1,layout=[2,1,2],title='SEP2F',xtitle=xt,ytitle=yt,xtickunits='scientific',ytickunits='scientific')
  p=plot(/o,sepet[*,1],sepd[*,1],/stairs,'r')
  p=plot(/o,sepet[*,1],sepm[*,1],/stairs,'b')
  p=plot(/o,sepie,sepi[*,1],'m')
  p=plot(/o,entot,ftot,'g')

  ke=average(pui2[*,tsteps].ke,2,/nan)/1e3 ;pickup O+ energy (keV)
  p=mvn_pui_sep_angular_response(cosvsep1,cosvsep2,cosvswiy,plot_colors=ke)
  time=pui[tsteps[0]].centertime
  range=[-2,2] ;10 eV to 100 keV
  kescaled=bytscl(alog10(ke),min=range[0],max=range[1])
  mvn_sep_fov_snap,time=time
  mvn_sep_fov_plot,pos=transpose([[cosvsep1],[-cosvswiy],[cosvsep2]]),cr=kescaled,overplot=keyword_set(time) ;pos is [x,-y,z] in mvn_sep_fov codes (right handed in sep1 coordinates)
  mvn_sep_fov_plot,pos=-magsep,sym={symbol:'D',name:'B in',color:'b'},/overplot
  mvn_sep_fov_plot,pos=+magsep,sym={symbol:'o',name:'Bout',color:'r'},/overplot
  mvn_sep_fov_plot,pos=-uswsep,sym={symbol:'S',name:'V sw',color:'r'},/overplot
  mvn_sep_fov_plot,pos=-eswsep,sym={symbol:'s',name:'E sw',color:'r'},/overplot
  mvn_sep_fov_plot,pos=-drfsep,sym={symbol:'d',name:'Vdrf',color:'b'},/overplot
  p=colorbar(rgb=33,range=range,title='Log10 Pickup O+ Energy (keV)',position=[0.7,.2,.95,.22])
  p=text(0,0.03,tstring+'pui time')
  p=legend(sample_width=0,position=[1.09,1.72])

  if keyword_set(avrg) then begin
    p=getwindows('sepqf')
    if keyword_set(p) then p.setcurrent else p=window(name='sepqf')
    p.erase
    p=plot(/current,[0],/nodata,/ylog,xtitle='Quality Flag',ytitle='d2m Ratio')
    p=plot(/o,[pui[tsteps].model[1].fluxes.sep[0].qf],[pui[tsteps].d2m[0].sep[1]/pui[tsteps].d2m[0].sep[0]],'bo',name='SEP1F')
    p=plot(/o,[pui[tsteps].model[1].fluxes.sep[1].qf],[pui[tsteps].d2m[1].sep[1]/pui[tsteps].d2m[1].sep[0]],'ro',name='SEP2F')
    p=legend()
    p=text(0,0,tstring)
  endif
endif

if keyword_set(eflux) then begin ;SWEA/SWIA and pickup ion Efluxes
  xswepot=average(pui[tsteps].data.swe.enpot,2,/nan) ;swea s/c potential corrected energy table (eV)
  yswepot=average(pui[tsteps].data.swe.efpot,2,/nan) ;swea pot eflux
  xswe=pui1.sweet ;swea energy table (eV)
  yswe=average(pui[tsteps].data.swe.eflux,2,/nan) ;swea eflux
  xswi=average(info_str[pui[tsteps].data.swi.swis.info_index].energy_coarse,2,/nan) ;swia energy table (eV)
  yswi=average(pui[tsteps].data.swi.swis.data,2,/nan) ;swia energy flux
  eftot=average(pui[tsteps].model.fluxes.toteflux,3,/nan) ;total flux /[s cm2 keV]

  yswepot[where(yswepot eq 0,/null)]=zeros
  yswe[where(yswe eq 0,/null)]=zeros
  yswi[where(yswi eq 0,/null)]=zeros
  eftot[where(eftot eq 0.,/null)]=zeros

  xr=[1,300e3]
  yr=[1e1,5e9]
  xt='Energy (eV)'
  yt='Eflux (eV/[cm2 s eV])'
  p=getwindows('swe_swi_pui_eflux')
  if keyword_set(p) then p.setcurrent else p=window(name='swe_swi_pui_eflux')
  p.erase
  p=plot(/current,[0],/nodata,/xlog,/ylog,xrange=xr,yrange=yr,title='SWEA/SWIA (/sr) and PUI',xtitle=xt,ytitle=yt,xtickunits='scientific',ytickunits='scientific')
  p=plot(/o,xswepot,yswepot,/stairs,'m',name='SWEA (potential corrected)')
  p=plot(/o,xswe,yswe,/stairs,'k',name='SWEA (raw)')
  p=plot(/o,xswi,yswi,/stairs,'g',name='SWIA')

  p=plot(pui1.totet,eftot[*,0],/o,color='b',name='H+') ;pickup H+
  p=plot(pui1.totet,eftot[*,1],/o,color='r',name='O+') ;pickup O+
  if pui0.ns ge 3 then p=plot(pui1.totet,eftot[*,2],/o,color='g',name='(H2)+') ;pickup (H2)+

  p=legend()
  p=text(0,0,tstring)
  
endif

if keyword_set(traj) then begin ;Trajectories and Ring Distribution
  npf=floor(pui0.np/1.1) ;fraction of number of simulated particles
  p=getwindows('trajxyz')
  if keyword_set(p) then p.setcurrent else p=window(name='trajxyz')
  p.erase
  p=plot3d(/current,orbit[*,0],orbit[*,1],orbit[*,2],'k',axis_style=2,name='Orbit')
  p=plot3d(rv[*,0,0],rv[*,0,1],rv[*,0,2],'b',/o,name='H Birth Curve') ;H birth curve
  p=plot3d(rv[0:npf,1,0],rv[0:npf,1,1],rv[0:npf,1,2],'r',/o,name='O Birth Curve') ;O birth curve
  p=plot3d(scp[0]+alfrm*sep1fov[0],scp[1]+alfrm*sep1fov[1],scp[2]+alfrm*sep1fov[2],/o,'b',name='SEP1F FOV') ;SEP1F fov (blue)
  p=plot3d(scp[0]+alfrm*sep2fov[0],scp[1]+alfrm*sep2fov[1],scp[2]+alfrm*sep2fov[2],/o,'r',name='SEP2F FOV') ;SEP2F fov (red)
  p=plot3d(scp[0]+alfrm*stxfov[0],scp[1]+alfrm*stxfov[1],scp[2]+alfrm*stxfov[2],/o,'c',name='STATIC-X FOV') ;static x fov (cyan)
  p=plot3d(scp[0]+alfrm*stzfov[0],scp[1]+alfrm*stzfov[1],scp[2]+alfrm*stzfov[2],/o,'m',name='STATIC-Z FOV') ;static z fov (magenta)
  p=plot3d(scp[0]+alfrm*magdir[0],scp[1]+alfrm*magdir[1],scp[2]+alfrm*magdir[2],/o,'g',name='MAG Direction') ;mag direction
  p=plot3d(scp[0]+alfrm*usw[0]/uswtot,scp[1]+alfrm*usw[1]/uswtot,scp[2]+alfrm*usw[2]/uswtot,/o,'k',name='Solar Wind Velocity Direction') ;solar wind velocity direction
  p=plot3d(scp[0]+alfrm*drf[0]/uswtot,scp[1]+alfrm*drf[1]/uswtot,scp[2]+alfrm*drf[2]/uswtot,/o,color=!color.gray,name='Drift Velocity Direction') ;drift velocity direction
  p=plot3d(scp[0]+alfrm*esw[0]/uswtot,scp[1]+alfrm*esw[1]/uswtot,scp[2]+alfrm*esw[2]/uswtot,/o,color=!color.orange,name='E Direction') ;motional electric field direction
  p=scatterplot3d([0,seprv[*,0]],[0,seprv[*,1]],[0,seprv[*,2]],/o,rgb=34,magnitude=[1,0,2],name='SEP Source') ;SEP on birth curve (SEP1F: blue, SEP2F, red)
  p=legend()
  p=text(0,0,tstring)
  mvn_pui_plot_mars_bow_shock,/p3d,/km

  p=getwindows('trajring')
  if keyword_set(p) then p.setcurrent else p=window(name='trajring')
  p.erase
  p=plot3d(/current,rv[0:npf,1,3],rv[0:npf,1,4],rv[0:npf,1,5],axis_style=2,aspect_ratio=1,aspect_z=1,xtitle='X (km/s)',ytitle='Y (km/s)',ztitle='Z (km/s)',name='Ring-Beam') ;ring-beam distribution
  p=plot3d(vmax*sepfov[0,0],vmax*sepfov[1,0],vmax*sepfov[2,0],/o,'b',name='SEP1F Reversed FOV') ;SEP1F reversed fov
  p=plot3d(vmax*sepfov[0,1],vmax*sepfov[1,1],vmax*sepfov[2,1],/o,'r',name='SEP2F Reversed FOV') ;SEP2F reversed fov
  p=plot3d(vmax*stxfov[0],vmax*stxfov[1],vmax*stxfov[2],/o,'c',name='STATIC-X Reversed FOV') ;static x reversed fov
  p=plot3d(vmax*stzfov[0],vmax*stzfov[1],vmax*stzfov[2],/o,'m',name='STATIC-Z Reversed FOV') ;static z reversed fov
  p=plot3d(-vmax*magdir[0],-vmax*magdir[1],-vmax*magdir[2],/o,'g',name='MAG Direction') ;mag direction
  p=plot3d([0,usw[0]],[0,usw[1]],[0,usw[2]],/o,'k',name='Solar Wind Velocity (km s-1)') ;solar wind velocity (km/s)
  p=plot3d([0,drf[0]],[0,drf[1]],[0,drf[2]],/o,color=!color.gray,name='Drift Velocity (km s-1)') ;drift velocity (km/s)
  p=plot3d([0,esw[0]],[0,esw[1]],[0,esw[2]],/o,color=!color.orange,name='E Direction') ;motional electric field direction
  p=scatterplot3d([0,seprv[*,3]],[0,seprv[*,4]],[0,seprv[*,5]],/o,rgb=34,magnitude=[1,0,2],name='SEP Source') ;SEP on ring (SEP1F: blue, SEP2F, red)
  p=legend()
  p=text(0,0,tstring)
endif

if keyword_set(swia3d) or keyword_set(stah3d) or keyword_set(stao3d) then mvn_pui_tplot_3d,swia3d=swia3d,stah3d=stah3d,stao3d=stao3d,lineplot=tsteps

end