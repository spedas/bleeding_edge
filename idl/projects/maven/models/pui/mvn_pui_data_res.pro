;20160404 Ali
;change the data resolution and load instrument pointings
;and puts them in an array of structures in common block "mvn_pui_com"
;to be called by mvn_pui_model

pro mvn_pui_data_res

@mvn_pui_commonblock.pro ;common mvn_pui_common
binsize=pui0.tbin
trange=pui0.trange

;get data from tplot variables (commented out, now getting data directly from instrument common blocks or spice)
;get_data,'mvn_swim_density',data=swian; %solar wind density (cm-3)
;get_data,'mvn_swim_velocity_mso',data=swiav; %solar wind velocity MSO (km/s)
;get_data,'mvn_swis_en_eflux',data=swiaefdata; %swia energy spectrum
;get_data,'mvn_B_1sec_MAVEN_MSO',data=mag; magnetic field vector, MSO (nT)
;get_data,'SepAnc_mvn_pos_mso',data=pos; maven position (km)
;get_data,'SepAnc_sep_1f_fov_mso',data=dld1; %sep1f fov
;get_data,'SepAnc_sep_2f_fov_mso',data=dld2; %sep2f fov
;get_data,'mvn_sta_c0_H_E',data=sta_c0_H_E_data ; STATIC m>12 energy spectra
;get_data,'mvn_sta_c0_L_E',data=sta_c0_L_E_data ; STATIC m<12 energy spectra

;----------MAG----------
get_data,'mvn_B_1sec',data=magdata; magnetic field vector, payload coordinates (nT)
if ~keyword_set(magdata) then begin
  dprint,'No MAG data available, using !values.f_nan'
;  dprint,'No MAG data available, using default B=[0,3,0] nT'
;  pui.data.mag.mso=1e-9*[0,3,0] ;magnetic field (T)
  centertime=dgen(pui0.nt,range=timerange(trange))
  pui.centertime=centertime
endif else begin
  magpayload=1e-9*average_hist2(magdata.y,magdata.x,binsize=binsize,trange=trange,centertime=centertime); magnetic field vector payload (T)
  pui.data.mag.payload=transpose(magpayload)
  pui.centertime=centertime

  ;rotate MAG data into MSO coordinates (Tesla)
  pui.data.mag.mso=spice_vector_rotate(pui.data.mag.payload,centertime,'MAVEN_SPACECRAFT','MAVEN_MSO',check_objects='MAVEN_SPACECRAFT',/force_objects)
endelse

;----------SWIA----------
if ~keyword_set(swim) then begin
  dprint,'No SWIA data available, using !values.f_nan'
;  dprint,'No SWIA data available, using default values: Usw = 500 km/s, Nsw = 2 cm-3'
;  pui.data.swi.swim.velocity_mso=[-500,0,0] ;solar wind velocity (km/s)
;  pui.data.swi.swim.density=2. ;solar wind density (cm-3)
endif else begin
  pui.data.swi.swim=average_hist(swim,swim.time_unix+2.,binsize=binsize,range=trange,xbins=centertime,/nan); swia moments
  pui.data.swi.swis=average_hist(swis,swis.time_unix+2.,binsize=binsize,range=trange,xbins=centertime,/nan); swia spectra
  ;nsw=average_hist2(swian.y,swian.x,binsize=binsize,trange=trange,centertime=centertime); solar wind density (cm-3)
  ;vsw=1e3*average_hist2(swiav.y,swiav.x,binsize=binsize,trange=trange,centertime=centertime); solar wind velocity (m/s)
  ;swiaef=average_hist2(swiaefdata.y,swiaefdata.x,binsize=binsize,trange=trange,centertime=centertime); swia energy flux
  ;swiaet=average_hist2(swiaefdata.v,swiaefdata.x,binsize=binsize,trange=trange,centertime=centertime); swia energy table

  swisen=transpose(info_str[pui.data.swi.swis.info_index].energy_coarse)
  store_data,'mvn_redures_swia',data={x:centertime,y:transpose(pui.data.swi.swis.data),v:swisen},limits={ylog:1,zlog:1,spec:1,yrange:[25.,25e3],ystyle:1,zrange:[1e3,1e8],ztitle:'Eflux',ytickunits:'scientific'}

  if n_elements(swics) gt 1 then begin ;swia survey data
    swicstime=swics.time_unix+4.*swics.num_accum/2. ;center time of sample/sum
    swicsdt=swics.time_unix-shift(swics.time_unix,1)
    swicsdt[0]=swicsdt[1]
    swicsav=average_hist(swics,swicstime,binsize=binsize,range=trange,xbins=centertime,/nan); swia coarse survey
    swicsdtav=average_hist(swicsdt,swicstime,binsize=binsize,range=trange,xbins=centertime,/nan)
    store_data,'mvn_swics_dt_(s)',data={x:swicstime,y:swicsdt},limits={ylog:1,panel_size:.5,colors:'b',labels:'swics'}

    if n_elements(swica) gt 1 then begin ;swia archive (burst) data
      swicatime=swica.time_unix+4.*swica.num_accum/2. ;center time of sample/sum
      swicadt=swica.time_unix-shift(swica.time_unix,1)
      swicadt[0]=swicadt[1]
      pui.data.swi.swica=average_hist(swica,swicatime,binsize=binsize,range=trange,xbins=centertime,/nan); swia coarse archive
      pui.data.swi.dt=average_hist(swicadt,swicatime,binsize=binsize,range=trange,xbins=centertime,/nan)
      store_data,'mvn_swica_dt_(s)',data={x:swicatime,y:swicadt},limits={ylog:1,panel_size:.5,colors:'r',psym:3,labels:'swica'}
      badindex=where(~finite(pui.data.swi.swica.time_unix),/null,countswi) ;no archive available index
      if countswi gt 0 then begin ;use survey instead
        pui[badindex].data.swi.swica=swicsav[badindex]
        pui[badindex].data.swi.dt=swicsdtav[badindex]
      endif
    endif else begin ;if no archive available at all, use survey instead
      pui.data.swi.swica=swicsav
      pui.data.swi.dt=swicsdtav
    endelse
    store_data,'mvn_swi_dt_(s)',data={x:centertime,y:pui.data.swi.dt},limits={ylog:1,panel_size:.5,colors:'r',psym:3}
    store_data,'mvn_swicsa_dt_(s)',data='mvn_swic?_dt_(s)',limits={labflag:-1,panel_size:.5}
  endif
endelse

;----------SWEA----------
get_data,'swe_a4',data=sweaefdata; %swea energy spectrum
if keyword_set(sweaefdata) then begin
  sweaef=average_hist2(sweaefdata.y,sweaefdata.x,binsize=binsize,trange=trange,centertime=centertime); swea energy flux
  pui.data.swe.eflux=transpose(sweaef)
  
  sweadata=mvn_swe_engy
  swescpot=sweadata.sc_pot
  swescpot[where(~finite(swescpot),/null)]=0. ;when SWEA s/c potential is unknown, assume it's zero.
  
  mvn_swe_convert_units,sweadata,'df' ;convert SWEA units to phase-space density
  sweadata.energy-=replicate(1.,pui0.sweeb)#swescpot ;correct for s/c potential
  mvn_swe_convert_units,sweadata,'eflux' ;convert back to eflux
  
  store_data,'mvn_swea_pot',data={x:sweadata.time,y:transpose(sweadata.data),v:transpose(sweadata.energy)},limits={spec:1,ylog:1,zlog:1,ystyle:1,yrange:[1.,5e3],zrange:[1e4,1e9],ztitle:'Eflux',ytickunits:'scientific'}
  sweaefpot=average_hist2(transpose(sweadata.data),sweadata.time,binsize=binsize,trange=trange,centertime=centertime); swea energy flux corrected for s/c potential
  sweaenpot=average_hist2(transpose(sweadata.energy),sweadata.time,binsize=binsize,trange=trange,centertime=centertime); swea energy bins corrected for s/c potential
  sweascpot=average_hist2(swescpot,sweadata.time,binsize=binsize,trange=trange,centertime=centertime); swea composite s/c potential
  pui.data.swe.efpot=transpose(sweaefpot)
  pui.data.swe.enpot=transpose(sweaenpot)
  pui.data.swe.scpot=sweascpot
  
  ;pui.data.swe=average_hist(mvn_swe_engy,mvn_swe_engy.time,binsize=binsize,range=trange,xbins=centertime,do_stdev=0); swea energy flux
  store_data,'mvn_redures_swea',data={x:centertime,y:sweaef,v:sweaefdata.v},limits={spec:1,ystyle:1,yrange:[3.,5e3],zrange:[1e4,1e9],ylog:1,zlog:1,ztitle:'Eflux',ytickunits:'scientific'}
  store_data,'mvn_redures_swea_pot',data={x:centertime,y:sweaefpot,v:sweaenpot},limits={spec:1,ystyle:1,yrange:[1.,5e3],zrange:[1e4,1e9],ylog:1,zlog:1,ztitle:'Eflux',ytickunits:'scientific'}
endif

;----------STATIC----------
if keyword_set(mvn_c0_dat) then begin ;static 1d data (64e2m)
  c0time=(mvn_c0_dat.time+mvn_c0_dat.end_time)/2.
  c0eflux=average_hist2(mvn_c0_dat.eflux,c0time,binsize=binsize,trange=trange,centertime=centertime); static c0 energy flux
  c0energy=average_hist2(mvn_c0_dat.energy[mvn_c0_dat.swp_ind,*,0],c0time,binsize=binsize,trange=trange,centertime=centertime); static c0 energy table
  pui.data.sta.c0.eflux=transpose(c0eflux,[1,2,0])
  pui.data.sta.c0.energy=transpose(c0energy)
  store_data,'mvn_redures_HImass_sta_c0',centertime,c0eflux[*,*,1],c0energy
  store_data,'mvn_redures_LOmass_sta_c0',centertime,c0eflux[*,*,0],c0energy
  store_data,'mvn_sta_att',data={x:c0time,y:mvn_c0_dat.att_ind},limits={yrange:[-1,4],panel_size:.5,colors:'r'}
  store_data,'mvn_sta_mode',data={x:c0time,y:mvn_c0_dat.mode},limits={yrange:[-1,7],ystyle:1,panel_size:.5,colors:'r'}
  store_data,'mvn_sta_sweep_index',data={x:c0time,y:mvn_c0_dat.swp_ind},limits={ylog:1,panel_size:.5,colors:'r'}
endif

if keyword_set(mvn_d0_dat) and (pui0.do3d or pui0.d0) then begin ;static 3d survey data (d0: 32e4a16d8m 128s)
  d0time=(mvn_d0_dat.time+mvn_d0_dat.end_time)/2.
  d0ef=average_hist2(mvn_d0_dat.eflux,d0time,binsize=binsize,trange=trange,centertime=centertime); static d0 energy flux
  d0en=average_hist2(mvn_d0_dat.energy[mvn_d0_dat.swp_ind,*,0,0],d0time,binsize=binsize,trange=trange,centertime=centertime); static d0 energy table
  d0ms=average_hist2(reform(mvn_d0_dat.mass_arr[mvn_d0_dat.swp_ind,0,0,*]),d0time,binsize=binsize,trange=trange,centertime=centertime); static d0 mass array
  d0dt=average_hist2(mvn_d0_dat.delta_t,d0time,binsize=binsize,trange=trange,centertime=centertime); static d0 dt
  pui.data.sta.d1.mass=transpose(d0ms)
  store_data,'mvn_sta_d0_mass_(amu)',data={x:d0time,y:reform(mvn_d0_dat.mass_arr[mvn_d0_dat.swp_ind,0,0,*])},limits={ylog:1,labels:['0','1','2','3','4','5','6','7'],psym:3}

  if keyword_set(mvn_d1_dat) then begin ;static 3d archive (burst) data (d1: 32e4a16d8m 16s)
    d1time=(mvn_d1_dat.time+mvn_d1_dat.end_time)/2.
    d1ef=average_hist2(mvn_d1_dat.eflux,d1time,binsize=binsize,trange=trange,centertime=centertime); static d1 energy flux
    d1en=average_hist2(mvn_d1_dat.energy[mvn_d1_dat.swp_ind,*,0,0],d1time,binsize=binsize,trange=trange,centertime=centertime); static d1 energy table
    d1dt=average_hist2(mvn_d1_dat.delta_t,d1time,binsize=binsize,trange=trange,centertime=centertime); static d0 dt
    nod1ind=where(~finite(d1dt),/null,countsta) ;no archive available index
    if countsta gt 0 then begin ;use survey instead
      d1ef[nod1ind,*,*,*]=d0ef[nod1ind,*,*,*]
      d1en[nod1ind,*]=d0en[nod1ind,*]
      d1dt[nod1ind]=d0dt[nod1ind]
    endif
  endif else begin ;if no archive available at all, use survey instead
    d1ef=d0ef
    d1en=d0en
    d1dt=d0dt
  endelse
  pui.data.sta.d1.eflux=transpose(reform(d1ef,[pui0.nt,pui0.sd1eb,pui0.swine,pui0.swina,8]),[1,3,2,4,0])
  pui.data.sta.d1.energy=transpose(d1en)
  pui.data.sta.d1.dt=d1dt
  pui.data.sta.d1.dee=mean(-1.+(d1en[*,0:-2]/d1en[*,1:-1]),dim=2,/nan) ;static d1 dE/E
  store_data,'mvn_sta_d01_dt_(s)',data={x:centertime,y:d1dt},limits={ylog:1,panel_size:.5,colors:'r',psym:3}
  store_data,'mvn_sta_D01_dE/E',data={x:centertime,y:pui.data.sta.d1.dee},limits={ylog:1,panel_size:.5,colors:'r',psym:3}
endif

;----------SEP----------
get_data,'mvn_sep1_B-O_Rate_Energy',data=sep1data ; SEP1 count rates
get_data,'mvn_sep2_B-O_Rate_Energy',data=sep2data ; SEP2 count rates
get_data,'mvn_sep1_svy_ATT',data=sep1att ; SEP1 attenuator state
get_data,'mvn_sep2_svy_ATT',data=sep2att ; SEP2 attenuator state
get_data,'mvn_sep1_svy_DURATION',data=sep1dt ; SEP1 dt (s)
get_data,'mvn_sep2_svy_DURATION',data=sep2dt ; SEP1 dt (s)
if keyword_set(sep1data) then begin
  pui.data.sep[0].att=average_hist(sep1att.y,sep1att.x,binsize=binsize,range=trange,xbins=centertime,/nan)
  pui.data.sep[1].att=average_hist(sep2att.y,sep2att.x,binsize=binsize,range=trange,xbins=centertime,/nan)
  pui.data.sep[0].dt=average_hist(sep1dt.y,sep1dt.x,binsize=binsize,range=trange,xbins=centertime,/nan)
  pui.data.sep[1].dt=average_hist(sep2dt.y,sep2dt.x,binsize=binsize,range=trange,xbins=centertime,/nan)
  sep1cps=average_hist2(sep1data.y,sep1data.x,binsize=binsize,trange=trange,centertime=centertime); sep1 counts/sec
  sep2cps=average_hist2(sep2data.y,sep2data.x,binsize=binsize,trange=trange,centertime=centertime); sep1 counts/sec
  pui.data.sep[0].rate_bo=transpose(sep1cps)
  pui.data.sep[1].rate_bo=transpose(sep2cps)
  pui1.sepet[0].sepbo=sep1data.v
  pui1.sepet[1].sepbo=sep2data.v

  store_data,'mvn_data_redures_sep1',centertime,sep1cps,sep1data.v
  store_data,'mvn_data_redures_sep2',centertime,sep2cps,sep2data.v
  options,'mvn_data_redures_sep?',yrange=[10,1e3],zrange=[.1,1e4],ylog=1,zlog=1,spec=1,ztitle='counts/s',ytickunits='scientific',ztickunits='scientific'
endif

;----------EUV----------
;EUV 3 channels
get_data,'mvn_euv_data',data=euvdata ;EUV level 2 data (1 second cadence)
if keyword_set(euvdata) then pui.data.euv.l2=transpose(average_hist2(euvdata.y,euvdata.x,binsize=binsize,trange=trange,centertime=centertime))
;FISM irradiances (W/cm2/nm)
get_data,'mvn_euv_l3_minute',data=fismdata ;FISM minute data
if keyword_set(fismdata) then begin
  fismtime=fismdata.x
  if (centertime[0] gt fismtime[0]-6000.) and (centertime[-1] lt fismtime[-1]+6000.) then $ ;only if centertime edges within 100 minutes of fismdata edges,
    pui.data.euv.l3=transpose(interp(fismdata.y,fismdata.x,centertime)) ;otherwise, interpolation will give unreasonable results
endif

;----------SPICE check----------
kinfo=spice_kernel_info(use_cache=1)
if n_elements(kinfo) gt 3 then begin ;at least a few spice files loaded

;----------Boundaries----------
;get_data,'wind',data=wind ;s/c altitude when in the solar wind (km)
mvn_pui_sw_orbit_coverage,times=centertime,alt_sw=alt_sw,/conservative
;pui.data.swalt=alt_sw ;s/c altitude when in the solar wind (km)
;----------Positions----------
pui.data.scp=1e3*spice_body_pos('MAVEN','MARS',frame='MSO',utc=centertime,check_objects=['MARS','MAVEN'],/force_objects) ;MAVEN position MSO (m)

;mvn_pui_au_ls,times=centertime,mars_au=mars_au,mars_ls=mars_ls
;pui.data.mars_au=mars_au ;Mars heliocentric distance (AU)
;pui.data.mars_ls=mars_ls ;Mars Solar Longitude (Ls)

;----------FOV----------
xdir=[1.,0,0]#replicate(1.,pui0.nt) ;X-direction (SEP front FOV)
ydir=[0,1.,0]#replicate(1.,pui0.nt) ;Y-direction
zdir=[0,0,1.]#replicate(1.,pui0.nt) ;Z-direction (symmetry axis of SWIA and STATIC)
pui.data.sep[0].fov=spice_vector_rotate(xdir,centertime,'MAVEN_SEP1','MSO',check_objects='MAVEN_SPACECRAFT',/force_objects); sep1 look direction MSO
pui.data.sep[1].fov=spice_vector_rotate(xdir,centertime,'MAVEN_SEP2','MSO',check_objects='MAVEN_SPACECRAFT',/force_objects); sep2 look direction MSO
;swizld=transpose(spice_vector_rotate(zdir,centertime,'MAVEN_SWIA','MSO',check_objects='MAVEN_SPACECRAFT')); SWIA-Z look direction
pui.data.sta.fov.x=spice_vector_rotate(xdir,centertime,'MAVEN_STATIC','MSO',check_objects=['MAVEN_APP_OG','MAVEN_SPACECRAFT'],/force_objects); STATIC-X look direction
pui.data.sta.fov.z=spice_vector_rotate(zdir,centertime,'MAVEN_STATIC','MSO',check_objects=['MAVEN_APP_OG','MAVEN_SPACECRAFT'],/force_objects); STATIC-Z look direction
endif

tplot_options,'no_interp',1

end