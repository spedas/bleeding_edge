;20160504 Ali
;creates tplot variables from data and pickup ion model results
;keywords:
;   store: stores model-data comparisons in tplot variables (use with one of the following keywords)
;   tplot: plots the main results (model-data comparison) or saved 3d tplots
;   tohban: plots Tohban-related data
;   savetplot: saves the tplots as png files
;   swia3d: plots SWIA pickup hydrogen and oxygen 3d spectra
;   stah3d: plots STATIC 3d spectra, pickup hydrogen, D1 data product, mass channel=0 or sum of 0,1,2
;   stao3d: plots STATIC 3d spectra,  pickup oxygen,  D1 data product, mass channel=4 or sum of 3,4,5
;   datimage: plots 3d data images instead of tplots (use instead of 'store' or 'tplot' with one of the above 3d keywords)
;   modimage: plots 3d model images instead of tplots
;   d2mimage: plots 3d images of data to model ratios
;   trange: plots the above spectra for the specified trange
; explain these: denprof=denprof,d2mqf=d2mqf,denmap=denmap

pro mvn_pui_tplot,store=store,tplot=tplot,tohban=tohban,savetplot=savetplot,_extra=_extra

  @mvn_pui_commonblock.pro ;common mvn_pui_common

  if ~keyword_set(pui) then begin
    dprint,'Please run mvn_pui_model first. returning...'
    return
  endif

  tplot_options,'no_interp',1
  centertime=pui.centertime

  if keyword_set(store) then begin
    onesnt=replicate(1.,pui0.nt)
    store_data,'mvn_pui_line_1',data={x:centertime,y:onesnt},limits={colors:'g'} ;straight line equal to 1
    store_data,'mvn_pos_(km)',data={x:centertime,y:transpose(pui.data.scp)/1e3},limits={colors:'bgr',labels:['x','y','z'],labflag:1}
    store_data,'mvn_sep1_fov',centertime,transpose(pui.data.sep[0].fov)
    store_data,'mvn_sep2_fov',centertime,transpose(pui.data.sep[1].fov)
    store_data,'mvn_stax_fov',centertime,transpose(pui.data.sta.fov.x)
    store_data,'mvn_staz_fov',centertime,transpose(pui.data.sta.fov.z)
    options,'mvn_*_fov',colors='bgr',panel_size=.5,yrange=[-1,1]

    mag=transpose(pui.data.mag.mso)
    emot=pui.model.params.kemax/pui.model.params.rg/2. ;motional electric field magnitude (V/m)
    nsw=pui.data.swi.swim.density ;solar wind density (cm-3)
    fsw=pui.data.swi.swim2.fsw ;solar wind number flux (cm-2 s-1)
    esw=1e-3*pui.data.swi.swim2.esw ;solar wind proton energy (keV)
    mfsw=pui.data.swi.swim2.mfsw ;solar wind proton momentum flux (g cm-1 s-2)
    efsw=pui.data.swi.swim2.efsw ;solar wind proton energy flux (eV cm-2 s-1)
    sintub=sqrt(pui.model[0:1].params.kemax/(4.*1e3*[1.,16.]#esw))
    eden=pui.data.swe.eden ;swea electron density (cm-3)
    edenpot=pui.data.swe.edenpot ;swea electron density (cm-3)

    store_data,'mvn_mag_MSO_(nT)',data={x:centertime,y:1e9*[[onesnt-1.],[mag],[sqrt(total(mag^2,2))]]},limits={yrange:[-10,10],labels:['0','Bx','By','Bz','Btot'],colors:'cbgrk',labflag:1}
    store_data,'mvn_mag_Btot_(nT)',data={x:centertime,y:1e9*sqrt(total(mag^2,2))},limits={yrange:[.1,1000],ylog:1,ytickunits:'scientific',constant:[1,10,100]}
    store_data,'mvn_Nsw_(cm-3)',data={x:centertime,y:pui.data.swi.swim.density},limits={yrange:[.01,100],ylog:1,ytickunits:'scientific',constant:[.1,1,10]}
    store_data,'mvn_Vsw_MSO_(km/s)',data={x:centertime,y:[[onesnt-1.],[transpose(pui.data.swi.swim.velocity_mso)],[-pui.data.swi.swim2.usw]]},limits={labels:['0','Vx','Vy','Vz','-Vtot'],colors:'cbgrk',labflag:1,constant:[200,0,-200,-400,-600,-800,-1000]}
    store_data,'Sin(thetaUB)',data={x:centertime,y:transpose(sintub)},limits={yrange:[0,1]}
    store_data,'E_Motional_(V/km)',data={x:centertime,y:1e3*transpose(emot)},limits={yrange:[.01,10],ylog:1,ytickunits:'scientific'}
    store_data,'Pickup_Gyro_Period_(sec)',data={x:centertime,y:transpose(pui.model[0:1].params.tg)},limits={yrange:[1,1e3],ylog:1,labels:['H+','O+'],colors:'br',labflag:1,ytickunits:'scientific'}
    store_data,'Pickup_Gyro_Radius_(1000km)',data={x:centertime,y:transpose(pui.model[0:1].params.rg/1e6)},limits={yrange:[.1,100],ylog:1,labels:['H+','O+'],colors:'br',labflag:1,ytickunits:'scientific'}
    store_data,'Pickup_Max_Energy_(keV)',data={x:centertime,y:[[transpose(pui.model[0:1].params.kemax/1e3)],[esw],[4*esw],[4*16*esw]]},limits={yrange:[.1,300],ylog:1,labels:['H+','O+','SWIA','4xSWIA','64xSWIA'],colors:'brgcm',labflag:1,ytickunits:'scientific'}
    store_data,'Pickup_Number_Density_(cm-3)',data={x:centertime,y:[[transpose(pui.model[0:1].params.totnnn)],[nsw],[eden],[edenpot]]},limits={yrange:[.001,100],ylog:1,labels:['H+','O+','SWIA','SWEA','SWEApot'],colors:'brgcm',labflag:1,ytickunits:'scientific'}
    store_data,'Pickup_Number_Flux_(cm-2.s-1)',data={x:centertime,y:[[transpose(pui.model[0:1].params.totphi)],[fsw]]},limits={yrange:[1e4,1e9],ylog:1,labels:['H+','O+','SWIA'],colors:'brg',labflag:1}
    store_data,'Pickup_Momentum_Flux_(g.cm-1.s-2)',data={x:centertime,y:[[transpose(pui.model[0:1].params.totmph)],[mfsw]]},limits={yrange:[1e-11,1e-7],ylog:1,labels:['H+','O+','SWIA'],colors:'brg',labflag:1}
    store_data,'Pickup_Energy_Flux_(eV.cm-2.s-1)',data={x:centertime,y:[[transpose(pui.model[0:1].params.toteph)],[efsw]]},limits={yrange:[1e8,1e12],ylog:1,labels:['H+','O+','SWIA'],colors:'brg',labflag:1}
    store_data,'O+_Max_Energy_(keV)',centertime,pui.model[1].params.kemax/1e3 ;pickup oxygen max energy (keV)

    store_data,'mvn_model_puh_tot',data={x:centertime,y:transpose(pui.model[0].fluxes.toteflux),v:pui1.totet},limits={ylog:1,zlog:1,spec:1,yrange:[10.,30e3],zrange:[1e2,1e6],ztitle:'Eflux'}
    store_data,'mvn_model_puo_tot',data={x:centertime,y:transpose(pui.model[1].fluxes.toteflux),v:pui1.totet},limits={ylog:1,zlog:1,spec:1,yrange:[100.,300e3],zrange:[1e2,1e6],ztitle:'Eflux'}
    ;store_data,'mvn_model_pux_tot',data={x:centertime,y:transpose(pui.model[2].fluxes.toteflux),v:pui1.totet},limits={ylog:1,zlog:1,spec:1,yrange:[10.,300e3],zrange:[1e2,1e6],ztitle:'Eflux'}

    for i=0,1 do begin ;loop over 2 seps
      sepm=pui.model[1].fluxes.sep[i].model_rate
      sepd=pui.data.sep[i].rate_bo
      sepmtot=total(sepm[2:16,*],1) ;sep model tot 10<E<200 keV
      sepdtot=total(sepd[2:16,*],1) ;sep data tot 10<E<200 keV
      sepdcme=total(sepd[16:22,*],1) ;sep high energy data tot (200<E<1000 keV: background due to cme, cir, sir, etc.)
;      sepmtot[where(sepmtot lt 100./pui.data.sep[i].att^7.,/null)]=0. ;get rid of too low model count rate
;      sepdtot[where(sepdcme gt 100./pui.data.sep[i].att^7.,/null)]=0. ;get rid of too high data background count rate
      sepd2m=sepdtot/sepmtot
      pui.d2m[i].sep[0]=sepmtot
      pui.d2m[i].sep[1]=sepdtot
      pui.d2m[i].sep[2]=sepdcme
      sepr=pui.model[1].fluxes.sep[i].rv[0:2]
      sepv=pui.model[1].fluxes.sep[i].rv[3:5]
      store_data,'mvn_model_puo_sep'+strtrim(i+1,2),data={x:centertime,y:transpose(sepm),v:pui1.sepet[i].sepbo},limits={spec:1,ylog:1,zlog:1,yrange:[10,1e3],zrange:[.1,1e4],ztitle:'counts/s',ztickunits:'scientific',ytickunits:'scientific'}
      store_data,'mvn_d2m_puo_sep'+strtrim(i+1,2),data={x:centertime,y:[[sepd2m],[onesnt]]},limits={yrange:[1e-2,1e2],ylog:1,colors:'rg',ytickunits:'scientific'}
      store_data,'mvn_tot_puo_sep'+strtrim(i+1,2),data={x:centertime,y:[[sepmtot],[sepdtot],[sepdcme],[100.*onesnt]]},limits={ylog:1,yrange:[1,1e4],colors:'brgm',labels:['model','data','cme','100'],labflag:1,ytickunits:'scientific'}
      store_data,'mvn_model_puo_sep'+strtrim(i+1,2)+'_Quality_Flag',data={x:centertime,y:pui.model[1].fluxes.sep[i].qf},limits={yrange:[-.1,1.2],ystyle:1}
      store_data,'mvn_model_puo_sep'+strtrim(i+1,2)+'_source_MSO_(Rm)',data={x:centertime,y:[[transpose(sepr)],[sqrt(total(sepr^2,1))]]/pui0.rmars/1e3},limits={labels:['x','y','z','r'],colors:'bgrk',labflag:1}
      store_data,'mvn_model_puo_sep'+strtrim(i+1,2)+'_velocity_MSO_(km/s)',data={x:centertime,y:[[transpose(sepv)],[sqrt(total(sepv^2,1))]]/1e3},limits={labels:['x','y','z','v'],colors:'bgrk',labflag:1}
      store_data,'mvn_model_puh_incident_sep'+strtrim(i+1,2),data={x:centertime,y:transpose(pui.model[0].fluxes.sep[i].incident_rate)},limits={spec:1,zlog:1,yrange:[0,20],zrange:[1,1e4]}
      store_data,'mvn_model_puo_incident_sep'+strtrim(i+1,2),data={x:centertime,y:transpose(pui.model[1].fluxes.sep[i].incident_rate)},limits={spec:1,zlog:1,yrange:[0,200],zrange:[1,1e4]}
      ;store_data,'mvn_model_pux_incident_sep'+strtrim(i+1,2),centertime,transpose(pui.model[2].fluxes.sep[i].incident_rate)
    endfor

    kefswih=transpose(pui.model[0].fluxes.swi1d.eflux)
    kefswio=transpose(pui.model[1].fluxes.swi1d.eflux)
    store_data,'mvn_model_swia',centertime,kefswih+kefswio,pui1.swiet
    store_data,'mvn_model_swia_O',centertime,kefswio,pui1.swiet
    store_data,'mvn_model_swia_H',centertime,kefswih,pui1.swiet
    options,'mvn_model_swia*',spec=1,ztitle='Eflux',ytickunits='scientific'
    ylim,'mvn_model_swia*',25,25e3,1
    zlim,'mvn_model_swia*',1e3,1e8,1

    kefstah=transpose(pui.model[0].fluxes.sta1d.eflux)
    kefstao=transpose(pui.model[1].fluxes.sta1d.eflux)
    store_data,'mvn_model_O_sta_c0',centertime,kefstao,pui1.staet
    store_data,'mvn_model_H_sta_c0',centertime,kefstah,pui1.staet

    options,'mvn_*_sta_c0',spec=1,ztitle='Eflux',ytickunits='scientific'
    ylim,'mvn_*_sta_c0',1,35e3,1
    zlim,'mvn_*_sta_c0',1e3,1e8,1

  endif

  if pui0.do3d then mvn_pui_tplot_3d,store=store,tplot=tplot,_strict_extra=_extra

  if keyword_set(tplot) then begin
    datestr=strmid(time_string(pui0.trange[0]),0,10)
    wi,10 ;tplot raw data
    tplot,window=10,'mvn_pos_(km) swe_a4_pot scpot_comp mvn_swim_density mvn_swim_velocity_mso mvn_swim_atten_state mvn_swim_swi_mode mvn_swis_en_eflux mvn_swicsa_dt_(s) mvn_swi_dt_(s) mvn_B_1sec mvn_SEPS_svy_DURATION mvn_sep?_fov mvn_sep?_B-O_Rate_Energy mvn_euv_l3* mvn_euv_data mvn_staz_fov mvn_sta_att mvn_sta_mode mvn_sta_sweep_index mvn_sta_d0_mass_(amu) mvn_sta_d01_dt_(s) mvn_sta_D01_dE/E'
    if keyword_set(savetplot) then makepng,datestr+'_raw_data'
    wi,20 ;tplot useful pickup ion parameters. for diagnostic purposes, best shown on a vertical screen
    tplot,window=20,'mvn_mag_Btot_(nT) Sin(thetaUB) E_Motional_(V/km) Pickup_* Ionization_Frequencies_(s-1)'
    if keyword_set(savetplot) then makepng,datestr+'_pickup_params'
    wi,30 ;tplot sep-related stuff
    tplot,window=30,'mvn_model_pu*_incident_sep1 mvn_model_puo_sep1_source_MSO_(Rm) mvn_model_puo_sep1_velocity_MSO_(km/s) mvn_data_redures_sep1 mvn_model_puo_sep1 mvn_d2m_puo_sep1 mvn_tot_puo_sep1 mvn_model_puo_sep1_Quality_Flag O+_Max_Energy_(keV) mvn_SEPS_svy_ATT mvn_model_pu*_incident_sep2 mvn_model_puo_sep2_source_MSO_(Rm) mvn_model_puo_sep2_velocity_MSO_(km/s) mvn_data_redures_sep2 mvn_model_puo_sep2 mvn_d2m_puo_sep2 mvn_model_puo_sep2_Quality_Flag mvn_tot_puo_sep2'
    if keyword_set(savetplot) then makepng,datestr+'_sep'
    wi,31 ;tplot swia/static related stuff
    tplot,window=31,'mvn_model_pu?_tot mvn_alt_sw_(km) mvn_redures_swia mvn_model_swia_O mvn_d2m_ratio_swia_O mvn_model_swia_H mvn_d2m_ratio_swia_H mvn_redures_HImass_sta_c0 mvn_model_O_sta_c0 mvn_d2m_ratio_stat_O mvn_redures_LOmass_sta_c0 mvn_model_H_sta_c0 mvn_d2m_ratio_stat_H'
    if keyword_set(savetplot) then makepng,datestr+'_swia_static'
    wi,0 ;tplot main results (model-data comparison)
    tplot,window=0,'alt2 mvn_redures_swea_pot mvn_Nsw_(cm-3) mvn_Vsw_MSO_(km/s) mvn_redures_swia mvn_model_swia mvn_mag_MSO_(nT) mvn_data_redures_sep1 mvn_model_puo_sep1 mvn_SEPS_svy_ATT mvn_data_redures_sep2 mvn_model_puo_sep2 O+_Max_Energy_(keV) mvn_redures_HImass_sta_c0 mvn_model_O_sta_c0 mvn_redures_LOmass_sta_c0 mvn_model_H_sta_c0'
    if keyword_set(savetplot) then makepng,datestr+'_main'
  endif

  if keyword_set(tohban) then begin
    wi,24
    tplot,window=24,'alt2 mvn_euv_l0 swe_a4 mvn_swis_en_eflux mvn_Nsw_(cm-3) mvn_Vsw_MSO_(km/s) mvn_5min_sep1_A-F_Rate_Energy mvn_5min_sep1_B-O_Rate_Energy mvn_mag_MSO_(nT) mvn_mag_Btot_(nT) mvn_redures_LOmass_sta_c0 mvn_redures_HImass_sta_c0 mvn_5min_sep1_arc_ATT'
  endif
end