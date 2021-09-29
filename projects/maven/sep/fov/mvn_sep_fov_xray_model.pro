;20191002 Ali
;models the optical depth and transmittance of x-ray through the atmosphere of Mars as seen by MAVEN/SEP

pro mvn_sep_fov_xray_model,bx=bx,whr=whr,fit=fit

  @mvn_sep_fov_common.pro

  if ~keyword_set(mvn_sep_fov) then begin
    dprint,'sep fov data not loaded. Please run mvn_sep_fov first! returning...'
    return
  endif

  t1=systime(1)
  nt=n_elements(mvn_sep_fov)
  if keyword_set(whr) then nt=n_elements(whr) else whr=lindgen(nt)
  if nt eq 0 then return

  rmars=mvn_sep_fov0.rmars
  occalt=mvn_sep_fov0.occalt ;crossing altitude (km) maximum altitude for along path integration
  rad   =mvn_sep_fov[whr].rad
  pos   =mvn_sep_fov[whr].pos
  pdm   =mvn_sep_fov[whr].pdm
  tal   =mvn_sep_fov[whr].tal[2].sx1
  times =mvn_sep_fov[whr].time
  ones3=replicate(1d,3)
  posmar_iau=quaternion_rotation(-pos.mar,mvn_sep_fov[whr].qrot_iau,/last_ind)*(ones3#rad.mar) ;MAVEN position from Mars center in IAU_MARS
  possx1_iau=quaternion_rotation( pos.sx1,mvn_sep_fov[whr].qrot_iau,/last_ind)

  tadsx1=sqrt((rmars+2.*occalt[1])^2-(rmars+tal)^2); distance between tangent altitude and 2*occalt
  psx1n=rad.mar*pdm.sx1 ;distance from MAVEN to tanalt point (km)
  nd=1000 ;integration elements
  np=10 ;different density profiles
  dtad=tadsx1/double(nd) ;distance element (km)
  optdep=replicate(0d,[nt,np^2+2])
  for id=0,nd do begin
    psx1v=(ones3#(psx1n+dtad*double(id)))*possx1_iau+posmar_iau ;sco x-1 path integration vector from Mars center in IAU_MARS coordinates
    mvn_altitude,cart=psx1v,datum='areoid',result=adat
    if keyword_set(fit) then begin
      for jp=0,np-1 do begin
        for ip=0,np-1 do begin
          dens=10^(-6.+ip/5.-(adat.alt-70.)/(15.+jp)) ;density (kg/m3)
          optdep[*,ip+jp*np]+=dens ;kg/m3
        endfor
      endfor
    endif
    dens=10^(16-adat.alt/25.) ;density (cm-3)
    denswarm=10^(-1.3-adat.alt/20.) ;warm density (kg/m3)
    denscold=10^(-1.4-adat.alt/18.) ;cold density (kg/m3)
    optdep[*,np^2:np^2+1]+=[[denswarm],[denscold]] ;kg/m3
  endfor
  alt=findgen(140)
  denswarm=10^(-1.3-alt/20.) ;warm density (kg/m3)
  denscold=10^(-1.4-alt/18.) ;cold density (kg/m3)
  sigma=1e-21 ;x-ray cross section (cm2)
  sco2=2.4 ;12 keV xsec (cm2/g)
  ;sco2=3.6 ;11 keV xsec (cm2/g)
  optdep*=2.*(sco2*1e-3)*(rebin(dtad,[nt,np^2+2])*1e5)
  transm=exp(-optdep)
  if ~keyword_set(bx) then bx=[.6,2.] ;for 2018-03-12 occultation analysis
  cr=bx[0]+bx[1]*transm

  tal[where(tal gt 190,/null)]=!values.f_nan
  p=getwindows('mvn_sep_xray_occ')
  if keyword_set(p) then p.setcurrent else p=window(name='mvn_sep_xray_occ')
  p=plot(tal,cr[*,np^2+0],/o,'r',name='MCD Warm')
  p=plot(tal,cr[*,np^2+1],/o,'b',name='MCD Cold')

  if keyword_set(fit) then begin
    ls=replicate(0.,np^2)
    for ip=0,np^2-1 do begin
      ;p=plot(tal,cr[*,ip],/o,'c.')
      ls[ip]=total((cr[*,ip]-fit)^2)
    endfor
    ;p=plot(ls)
    minls=min(ls,minip)
    densfit2=10^(-6.+(minip mod np)/5.-(alt-70.)/(15.+(minip/np)))
    p=plot(tal,cr[*,minip],/o,'g',name='Least Squares Fit')
    p=legend()

    p=getwindows('mvn_sep_xray_fit_r2')
    if keyword_set(p) then p.setcurrent else p=window(name='mvn_sep_xray_fit_r2')
    p.erase
    p=image(/current,alog10(reform(ls,[np,np])-minls),rgb=33,margin=.1,xtitle='Density',ytitle='Scale Height',axis_style=1)
    p=colorbar(/orient,title='Log10(R2-R2min)')
    totfit=total(fit)
    tot2fit=total(fit^2)
    sstot=tot2fit-(totfit^2)/nt
    r2=1.-(minls/sstot)
  endif

  mcd=read_ascii('/home/rahmati/Desktop/sep/sep x-rays/mcd_atmo.txt') ;rob's version
  mcd=mcd.field1
  mcd_cold=read_ascii('/home/rahmati/Desktop/sep/sep x-rays/mcd_cold.txt',data_start=9)
  mcd_cold=mcd_cold.field1
  mcd_warm=read_ascii('/home/rahmati/Desktop/sep/sep x-rays/mcd_warm.txt',data_start=9)
  mcd_warm=mcd_warm.field1
  p=getwindows('mvn_sep_xray_density_profile')
  if keyword_set(p) then p.setcurrent else p=window(name='mvn_sep_xray_density_profile')
  p.erase
  p=plot(/current,[0],/nodat,ytitle='Altitude (km)',xtitle='Density (kg/m3)',/xlog,xrange=[1e-8,.1],yrange=[0,140])
  ;p=plot(denswarm,alt,/o,'m',name='Fit Warm')
  ;p=plot(denscold,alt,/o,'c',name='Fit Cold')
  p=plot(mcd[2,*],mcd[1,*],/o,'r',name='MCD Warm')
  p=plot(mcd[0,*],mcd[1,*],/o,'b',name='MCD Cold')
  p=plot(mcd_warm[1,*],mcd_warm[0,*]/1e3,/o,'m',name='MCD Warm')
  p=plot(mcd_cold[1,*],mcd_cold[0,*]/1e3,/o,'c',name='MCD Cold')
  if keyword_set(fit) then p=plot(densfit2[50:110],alt[50:110],/o,'g',name='Least Squares Fit')
  p=legend()

  get_data,'mvn_sep_xray_tanalt_sza',t,sza
  get_data,'mvn_sep_xray_tanalt_lat',t,lat
  get_data,'mvn_sep_xray_tanalt_lst',t,lst
  p=getwindows('mvn_sep_xray_tanalt')
  if keyword_set(p) then p.setcurrent else p=window(name='mvn_sep_xray_tanalt')
  p.erase
  p=plot(tal,sza[whr],'b',name='SZA (degrees)',xtitle='Sco X-1 Tangent Altitude (km)',/current)
  p=plot(tal,lat[whr],'g',name='Latitude (degrees)',/o)
  p=plot(tal,lst[whr],'r',name='Local Solar Time (hours)',/o)
  p=legend()

  store_data,'mvn_sep_xray_tanalt_d_(km)',times,tadsx1,dlim={ystyel:3}
  store_data,'mvn_sep_xray_optical_depth',data={x:times,y:optdep},dlim={ylog:1,yrange:[.01,100],constant:1,colors:'rb',labels:['warm','cold'],labflag:-1,ystyel:3}
  store_data,'mvn_sep_xray_transmittance',data={x:times,y:transm},dlim={ylog:1,yrange:[.01,1],colors:'rb',labels:['warm','cold'],labflag:-1,ystyel:3}
  store_data,'mvn_sep_xray_crate_model',data={x:times,y:bx[0]+bx[1]*transm},dlim={ylog:1,yrange:[.1,10],colors:'rb',labels:['warm','cold'],labflag:-1,ystyel:3}
  store_data,'mvn_sep1_xray_model-data',data='mvn_sep1_lowe_crate mvn_sep_xray_crate_model',dlim={yrange:[.1,1e2],ystyel:3}
  store_data,'mvn_sep2_xray_model-data',data='mvn_sep2_lowe_crate mvn_sep_xray_crate_model',dlim={yrange:[.1,1e2],ystyel:3}

  dprint,'elapsed time (s):',systime(1)-t1

end