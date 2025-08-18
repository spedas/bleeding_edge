;20170412 Ali
;models pickup ion fluxes and creates a pickup ion density map using given constant upstream driver parameters

pro mvn_pui_density_map
simtime=systime(1) ;simulation start time, let's do this!
  @mvn_pui_commonblock.pro ;common mvn_pui_common

  nt=1 ;number of time steps
  np=1000 ;number of simulated particles (1000 is enough for one gyro-period)
  ns=1;  number of simulated species. default is 2 (H and O)
  mvn_pui_aos,nt=nt,np=np,ns=ns,binsize=1.,trange=trange,do3d=do3d ;initializes the array of structures for time series (pui) and defines intrument constants

  pui0.msub=0 ;species subscript
  pui0.mamu[pui0.msub]=16. ;mass of [H=1 C=12 N=14 O=16] (amu)
  pui0.ngps[pui0.msub]=2.999 ;for SEP one full gyro-period is necessary, a few gyro-periods required for pickup hydrogen

  pui.data.mag.mso=1e-9*[0,3,0] ;magnetic field (T)
  pui.data.swi.swim.velocity_mso=[-400,0,0] ;solar wind velocity (km/s)
  pui.model[pui0.msub].ifreq.tot=3e-7*replicate(1.,nt) ;ionization frequency (s-1)

nx=400
ny=200
rmars=3400. ;mars radius (km)
nxrm=60. ;map dimentions in rm
nyrm=30.
denmap=replicate(0.,nx,ny)
;dnnmap=replicate(0.,nx,ny)
scx=nxrm*(-1.7+2.*findgen(nx)/nx)
scy=nyrm*(-0.7+2.*findgen(ny)/ny)
for ix=0,nx-1 do begin
  for iy=0,ny-1 do begin
    pui.data.scp=1e3*rmars*[scx[ix],0,scy[iy]] ;s/c position (m)
    mvn_pui_solver ;solve pickup ion trajectories
    rxyz=transpose(pui.model[pui0.msub].rv[0:2,*])
    nden=mvn_pui_exoden(pui2.rtot,species='o') ;neutral exospheric density (cm-3)
    nfac=replicate(1.,np) ;neutral density scale factor
    nfac[where(pui2.rtot lt 6000e3,/null)]=3. ;increase in electron impact ionization rate inside the bow shock due to increased electron flux
    nfac[where(pui2.rtot lt 3600e3,/null)]=0. ;to exclude stuff below the exobase
    nfac[where(pui.data.scp[2] gt -3600e3 and rxyz[*,0] lt 3600e3 and rxyz[*,0] gt -3600e3 and rxyz[*,2] lt 0 and rxyz[*,2] gt -10000e3,/null)]=0. ;to exclude precipitating stuff
;    nfac[where(rxyz[*,0] lt 0.,/null)]=0. ;to exclude stuff downstream of the terminator
    sza=mvn_pui_sza(rxyz[*,0],rxyz[*,1],rxyz[*,2])
    chap=cos(sza/1.5) ;chapman function
    chap[where(chap lt 1e-10,/null)]=1e-10
    nden*=nfac*chap
    dphi=mvn_pui_flux_calculator(nden)
    denmap[ix,iy]=pui.model[pui0.msub].params.totnnn
;    sza=mvn_pui_sza(pui.data.scp[0],pui.data.scp[1],pui.data.scp[2])
;    chap=cos(sza/1.5) ;chapman function
;    chap[where(chap lt 1e-10,/null)]=1e-10
;    dnnmap[ix,iy]=chap*mvn_pui_exoden(sqrt(total(pui.data.scp^2)),species='o')
  endfor
endfor
g=image(alog10(denmap),scx-nxrm/nx,scy-nyrm/ny,rgb_table=colortable(33),axis_style=2,margin=.2,max=-1.,min=-4.,title='$Log_{10} [Pickup O^+ Density (cm^{-3})]$')
;g=image(alog10(dnnmap),scx-nxrm/nx,scy-nyrm/ny,rgb_table=colortable(33),axis_style=2,margin=.1,max=4.,min=0.)
c=colorbar(target=g,/orientation)
mvn_pui_plot_mars_bow_shock,/rm,lbst=17
dprint,dlevel=2,'Simulation time: '+strtrim(systime(1)-simtime,2)+' seconds'
stop

end