;20171114 Ali
;backtracer

pro mvn_sep_elec_peri_model,orbit=orbit,lowalt=lowalt,savetraj=savetraj,mhd=mhd

  common mvn_orbit_num_com,alldat,time_cached,filenames
  simtime=systime(1) ;simulation start time, let's do this!
  if keyword_set(mhd) then begin
    lowres=1
    frame='MSO'
    mvn_sep_elec_peri_mhd,mhd=mhd,bxyz=bxyz ;MHD bxyz (MSO)
  endif else begin
    frame='IAU_MARS'
    restore,'/home/rahmati/Desktop/crustalb/bxyziau.dat' ;contains bxyz (IAU_MARS)
;    bxyz=mvn_sep_elec_load_bcrust() ;mag model (IAU_MARS)
  endelse
;  p=image(transpose(reform(bxyz[0,5,*,*])),rgb=colortable(70,/reverse),min=-100,max=100,margin=0)
  if ~keyword_set(orbit) then orbit=5720
  peritimeorb=alldat[orbit-1].peri_time
  trange=peritimeorb+60.*20.*[-1.,1.] ;30 mins before and after
  rmars=3390.;mars radius (km)
;  drmax=10. ;maximum displacement in each direction (km)
  get_data,'mvn_B_1sec_'+frame,data=magdata; magnetic field vector
  time=magdata.x
  if keyword_set(lowalt) then begin
    scposition=transpose(float(spice_body_pos('MAVEN','MARS',frame=frame,utc=time,check_objects=['MARS','MAVEN'],/force_objects))) ;MAVEN position (km)
    altitude=sqrt(total(scposition^2,2))-rmars ;altitude (km)
    peritime=where(altitude lt 1000.)
    scp=scposition[peritime,*]
  endif else begin
  peritime=where(time gt trange[0] and time lt trange[1])
  scp=transpose(float(spice_body_pos('MAVEN','MARS',frame=frame,utc=time[peritime],check_objects=['MARS','MAVEN'],/force_objects))) ;MAVEN position (km)
  endelse
  time2=time[peritime]
  nt=n_elements(time2)
  mag=float(magdata.y[peritime,*])
  sepfov=mvn_sep_elec_peri_fov(time2,frame=frame) ;dim=[nt,nfov,nsep,3]
  get_data,'mvn_sep1_A-F_Eflux_Energy',data=sepedata
  energy=sepedata.v[1:20] ;energy (keV)
  evelocity=float(velocity(1e3*energy,/elec,/true)) ;electron speed (km/s)
 ; qrot=spice_body_att('MSO','IAU_MARS',time2,/quaternion,check_object='MARS',/force_objects)
  sigma=3.85e-16/(energy^.6) ;electron scattering cross-section (cm2)
  fnan=!values.f_nan
  fnan3=replicate(fnan,3)
  nen=n_elements(energy)
  nsep=4
  nfov=5
  bw=replicate({al:0.,it:0,od:0.,rpara:0.,rperp:0.,v1:0.},[nt,nen,nsep,nfov])
  it0=0
  isep0=0
  ifov0=0
  ie0=0
  itermax=10000
  if keyword_set(savetraj) then begin
;    ctime,t0,/silent
;    it0=floor(t0-trange[0]) ;assuming t cadence is 1 sec
    it0=600
    isep0=0
    ifov0=0
    ie0=10
    nt=it0+1
    nsep=isep0+1
    nfov=ifov0+1
    nen=ie0+1
    traj=replicate({x:fnan3,v:fnan3,dt:fnan,od:fnan,b:fnan3,drpara:fnan,drperp:fnan,dtminsub:0L},itermax+1)
  endif
  for it=it0,nt-1 do begin ;loop over times
    magit=reform(mag[it,*]) ;nT
    x0=reform(scp[it,*]) ;km
    magres=magit-mvn_sep_elec_peri_bcrust(x0,bxyz,lowres=lowres,mhd=mhd) ;residual magnetic field (nT)
    if keyword_set(mhd) then magres=0.
    for isep=isep0,nsep-1 do begin ;loop over 4 seps
      for ifov=ifov0,nfov-1 do begin ;loop over sep fov elements
        vhat=reform(sepfov[it,ifov,isep,*])
        for ie=ie0,nen-1 do begin ;loop over energies
          v1=vhat*evelocity[ie]
          sigmaie=sigma[ie]
          x1=x0
          alt=sqrt(total(x1^2))-rmars ;altitude (km)
          iteration=0
          od=0.
          rpara=0.
          rperp=0.
          while (alt lt 1000. and iteration lt itermax and od lt 100.) do begin ;particle tracing loop
            v0=v1
            bcr=magres+mvn_sep_elec_peri_bcrust(x1,bxyz,lowres=lowres,mhd=mhd) ;crustal field model + residual (nT)
            drmax=alt/10. ;maximum displacement in each direction (km)
            mvn_sep_elec_traj_solver,bcr,v0,drmax,v1,dr,dt,drpara,drperp,dtminsub
            if keyword_set(savetraj) then traj[iteration]={x:x1,v:v0,dt:dt,od:od,b:bcr,drpara:drpara,drperp:drperp,dtminsub:dtminsub}
            x1+=dr
            distance=sqrt(total(dr^2)) ;distance traveled during this iteration (km)
            alt=sqrt(total(x1^2))-rmars ;altitude (km)
            iteration++
            nco2=1e16*(10.^(-alt/25.)) ;CO2 density (cm-3)
            od+=nco2*sigmaie*(distance*1e5) ;optical depth
            rpara+=abs(drpara)
            rperp+=abs(drperp)
          endwhile
          if iteration eq itermax then od=fnan ;in order to show up as white in the spectrograms
          bw[it,ie,isep,ifov].al=alt ;final altitude (km)
          bw[it,ie,isep,ifov].it=iteration ;iterations
          bw[it,ie,isep,ifov].od=od ;optical depth
          bw[it,ie,isep,ifov].rpara=rpara ;total distance traveled along the field line (km)
          bw[it,ie,isep,ifov].rperp=rperp ;total distance traveled perp to the field line (km)
          bw[it,ie,isep,ifov].v1=sqrt(total(v1^2)) ;final velocity (km/s)
        endfor
      endfor
    endfor
  endfor
  timespan,trange
  if keyword_set(savetraj) then mvn_sep_elec_peri_tplot,traj=traj,frame=frame else begin
    mvn_sep_elec_peri_tplot,time2,bw,energy,nsep,nfov
    save,time2,bw,energy,nsep,nfov,file='mvn_sep_elec_peri_v02'
  endelse
  dprint,dlevel=2,'Simulation time: '+strtrim(systime(1)-simtime,2)+' seconds'
stop
end