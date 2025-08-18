;+
;NAME: SPP_SWP_SPICE
;PURPOSE:
; LOADS SPICE kernels and creates a few tplot variables
; Demonstrates usage of SPP SPICE ROUTINES
;
;  Author:  Davin Larson
; $LastChangedBy: ali $
; $LastChangedDate: 2022-03-23 14:00:06 -0700 (Wed, 23 Mar 2022) $
; $LastChangedRevision: 30713 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spice/spp_swp_spice.pro $
;-

pro spp_swp_spice,trange=trange,res=res,utc=utc,kernels=kernels,download_only=download_only,verbose=verbose,reconstruct=reconstruct,predict=predict,scale=scale,$
  venus=venus,earth=earth,mercury=mercury,mars=mars,jupiter=jupiter,saturn=saturn,planets=planets,no_update=no_update,merged=merged,fields=fields, $
  quaternion=quaternion,no_download=no_download,load=load,position=position,angle_error=angle_error,att_frame=att_frame,ref_frame=ref_frame,test=test

  common spp_spice_kernels_com, last_load_time,last_trange

  if ~keyword_set(body) then BODY = 'SPP'
  if ~keyword_set(ref_frame) then ref_frame ='ECLIPJ2000'
  if ~keyword_set(att_frame) then att_frame ='SPP_RTN'

  if ~keyword_set(res) then res=60d ;1min resolution
  if ~keyword_set(angle_error) then angle_error=1. ;error in degrees
  trange=timerange(trange) ;get default trange

  current_time=systime(1)
  if n_elements(load) eq 0 then begin
    if ~keyword_set(last_load_time) || current_time gt (last_load_time + 24*3600.) then load_anyway=1
    if ~keyword_set(last_trange) || trange[0] lt last_trange[0] || trange[1] gt last_trange[1] then load_anyway=1
  endif

  if keyword_set(position) && position ge 3 then begin
    planets =1
  endif

  if keyword_set(planets) then begin
    mercury=1
    mars=1
    jupiter=1
    earth=1
    venus=1
    saturn=1
  endif
  if n_elements(venus) eq 0 then venus=1

  if keyword_set(load) || keyword_set(load_anyway) then begin
    kernels=spp_spice_kernels(/all,/clear,/load,trange=trange,verbose=verbose,no_download=no_download,fields=fields,$
      reconstruct=reconstruct,predict=predict,attitude=quaternion,merged=merged,mars=mars,jupiter=jupiter,saturn=saturn,no_update=no_update)
    last_load_time=systime(1)
    last_trange=trange
  endif

  if keyword_set(download_only) then return

  if keyword_set(position) then begin
    if ~keyword_set(scale) then scale='r'
    if scale eq 'km' then begin
      scale_sun=1d6
      scale_venus=1d3
      ysub_sun='(Million km)'
      ysub_venus='(1000 km)'
    endif
    if scale eq 'r' then begin
      scale_sun=695700.d
      ;   scale_sun=696340.d  ; km (google)
      scale_venus=6051.8d
      ysub_sun='(R_Sun)'
      ysub_venus='(R_Venus)'
    endif

    if position ge 3 then begin
      spice_position_to_tplot,body,'SSB',frame=ref_frame,res=res,name=nams,trange=trange,check_objects=[body],/force_objects
      xyz_to_polar,nams[0],/ph_0_360
      options,/def,nams[0]+'_mag',ysubtitle='(km)',ystyle=3
      get_data,nams[0],data=pos_ssb
      nams_acc = str_sub(nams[0],'POS_','ACC_')
      deriv_data,nams[1],newname = nams_acc
      xyz_to_polar,/quick_mag,nams_acc
      nams_acc_all = nams_acc
      ftot_m = 0
    endif

    rscale = scale_sun;  km   solar radius
    ysub=ysub_sun
    gm = 1.32712440042d20 / 1e9 ; km^3/s^2
    nam_freefall = 'AccSun'
    observer = 'Sun'
    c = 299792d   ; speed of light km/s
    spice_position_to_tplot,body,observer,frame=ref_frame,res=res,scale=rscale,name=nams,trange=trange,/force_objects ;million km
    xyz_to_polar,nams[0],/ph_0_360
    options,/def,nams[0]+'_mag',ysubtitle=ysub,ystyle=3
    spice_qrot_to_tplot,ref_frame,att_frame,trange=trange,res=res*60.,check_obj=[body,'SUN'],/force_objects,error=angle_error*!pi/180.
    tplot_quaternion_rotate,'SPP_VEL_(Sun-ECLIPJ2000)','ECLIPJ2000_QROT_SPP_RTN',newname='SPP_VEL_RTN_SUN'
    options,/def,'SPP_VEL_RTN_SUN',labels=['V_R','V_T','V_N'],ysubtitle='(km/s)',labflag=-1,constant=0,ystyle=3

    if position ge 2 then begin    ; get "constants" of motion for sun
      get_data,nams[0]     ,data=pos
      dist = sqrt(total( pos.y ^2,2))
      get_data,nams[1] ,data = vel

      ;Caluclate orbital angular momentum - constant of motion (2 body only)
      nam_rxv = str_sub(nams[0],'POS_','RxV_')
      rxv = crossp2(pos.y,vel.y)   ; angular mmomentum / m
      L2 = total(rxv ^2,2)         ;  L^2
      store_data,nam_rxv,pos.x,rxv,dlimit={colors:'bgr'}

      ;look at energy as constant of the motion
      KE = 0.5d * total(vel.y^2,2) - gm/ (rscale*dist) ; - gm  / C^2 * L2 / dist^3 /rscale
      store_data,'SPP_SKE',vel.x,ke
      KE = 0.5d * total(vel.y^2,2) - gm/ (rscale*dist)  - gm  / C^2 * L2 / dist^3 /rscale
      store_data,'SPP_SKE_GR',vel.x,ke
    endif

    if position ge 3 then begin

      ; Estimate acceration due to gravity
      f_m = gm / rscale^2 * pos.y / (dist^3 # [1,1,1])
      ftot_m += f_m
      store_data,nam_freefall,pos.x,f_m
      xyz_to_polar,/quick_mag,nam_freefall
      options,nam_freefall+'_mag',colors='g'
      ;store_data,'|'+nam_freefall+'|' ,pos.x, sqrt(total(f_m^2,2)),dlimit={colors:'b'}
      ;Estimate GR effects
      fgr_m = 3* gm / C^2  / rscale^2 * ( (L2 / dist^5) # [1,1,1]) * pos.y    ; general relativity correction
      ftot_m += Fgr_m
      store_data,'AccSun_gr',pos.x,fgr_m
      xyz_to_polar,'AccSun_gr',/quick_mag
      options,'AccSun_gr'+'_mag',colors='b'

      ;  Estimate radiation pressure
      Gsc = 1361d  ; W/m2   solar constant (at 1 AU)
      AU  = 149.6e6 ;  km   astronomical units
      area_sc = 5.d   ; m^2    fudged this value to make the answer come out correct
      area_sc = 2.5d   ; m^2     fudged this value to make the answer come out correct
      mass_sc = 600d ; kg    (drymass = 555kg   launch mass=685kg
      Pr2 = Gsc/(c*1000) *AU^2        ;          ; pressure * r^2   where r is in km
      fr2_m = 2* Pr2 * area_sc / mass_sc / 1000   ; km^3/s^2
      printdat,fr2_m /gm
      frp_m = - fr2_m  /rscale^2 * pos.y / (dist^3 # [1,1,1])
      ftot_m += Frp_m
      store_data,'AccSun_rp',pos.x,frp_m
      xyz_to_polar,'AccSun_rp',/quick_mag
      options,'AccSun_rp'+'_mag',colors='b'
      nams_acc_all = [nams_acc_all,nam_freefall,'AccSun_gr','AccSun_rp']
    endif

    options,nams[0]+'_mag',ytitle='Rsun'
    tplot_options,var_label=nams[0]+'_mag'

    if keyword_set(venus) then begin
      gm = 0.324859d6  ; km^3/s^2
      rscale = scale_venus
      ysub=ysub_venus
      nam_freefall = 'AccVenus'
      observer = 'Venus'
      spice_position_to_tplot,body,observer,frame=ref_frame,res=res,scale=rscale,name=nams,trange=trange,/force_objects ;million km
      xyz_to_polar,nams[0],/ph_0_360
      options,/def,nams[0]+'_mag',ysubtitle=ysub,ystyle=3
      if position ge 3 then begin
        get_data,nams[0]     ,data=pos
        dist = sqrt(total( pos.y ^2,2))
        get_data,nams[1] ,data = vel
        f_m = gm / rscale^2 * pos.y / (dist^3 # [1,1,1])
        ftot_m += f_m
        store_data,nam_freefall,pos.x,f_m
        xyz_to_polar,/quick_mag,nam_freefall
        ;store_data,'|'+nam_freefall+'|' ,pos.x, sqrt(total(f_m^2,2)),dlimit={colors:'b'}
        nam_rxv = str_sub(nams[0],'_POS_','_RxV_')
        store_data,nam_rxv,pos.x,crossp2(pos.y,vel.y)
        options,nam_freefall+'_mag',colors='c'
        nams_acc_all = [nams_acc_all,nam_freefall]
      endif
    endif

    if keyword_set(earth) then begin
      gm = 3.986004418d5    ; km^3/s^2
      rscale = 6000d
      ysub='(R_Earth)'
      nam_freefall = 'AccEarth'
      observer = 'Earth'
      spice_position_to_tplot,body,observer,frame=ref_frame,res=res,scale=rscale,name=nams,trange=trange,/force_objects ;million km
      xyz_to_polar,nams[0],/ph_0_360,/quick_mag
      options,nams[0]+'_mag',ysubtitle=ysub,ystyle=3
      if position ge 3 then begin
        get_data,nams[0]     ,data=pos
        dist = sqrt(total( pos.y ^2,2))
        get_data,nams[1] ,data = vel
        f_m = gm / rscale^2 * pos.y / (dist^3 # [1,1,1])
        ftot_m += f_m
        store_data,nam_freefall,pos.x,f_m
        xyz_to_polar,/quick_mag,nam_freefall
        ;store_data,'|'+nam_freefall+'|' ,pos.x, sqrt(total(f_m^2,2)),dlimit={colors:'b'}
        nam_rxv = str_sub(nams[0],'_POS_','_RxV_')
        store_data,nam_rxv,pos.x,crossp2(pos.y,vel.y)
        options,nam_freefall+'_mag',colors='m'
        nams_acc_all = [nams_acc_all,nam_freefall]
      endif
    endif

    if keyword_set(mercury) then begin
      gm =  0.022032d6    ;   km^3/s^2
      rscale = 1000d
      ysub='(R_Mercury)'
      nam_freefall = 'AccMercury'
      observer = 'Mercury'
      spice_position_to_tplot,body,observer,frame=ref_frame,res=res,scale=rscale,name=nams,trange=trange,/force_objects ;million km
      xyz_to_polar,nams[0],/ph_0_360,/quick_mag
      options,nams[0]+'_mag',ysubtitle=ysub,ystyle=3
      if position ge 3 then begin
        get_data,nams[0]     ,data=pos
        dist = sqrt(total( pos.y ^2,2))
        get_data,nams[1] ,data = vel
        f_m = gm / rscale^2 * pos.y / (dist^3 # [1,1,1])
        ftot_m += f_m
        store_data,nam_freefall,pos.x,f_m
        xyz_to_polar,/quick_mag,nam_freefall
        ;store_data,'|'+nam_freefall+'|' ,pos.x, sqrt(total(f_m^2,2)),dlimit={colors:'b'}
        nam_rxv = str_sub(nams[0],'_POS_','_RxV_')
        store_data,nam_rxv,pos.x,crossp2(pos.y,vel.y)
        options,nam_freefall+'_mag',colors='y'
        nams_acc_all = [nams_acc_all,nam_freefall]
      endif
    endif

    if keyword_set(mars) then begin
      gm =  4.282837442560939d+04    ;   km^3/s^2
      rscale = 4000d
      ysub='(R_Mars)'
      nam_freefall = 'AccMars'
      observer = 'Mars'
      spice_position_to_tplot,body,observer,frame=ref_frame,res=res,scale=rscale,name=nams,trange=trange,/force_objects ;million km
      xyz_to_polar,nams[0],/ph_0_360,/quick_mag
      options,nams[0]+'_mag',ysubtitle=ysub,ystyle=3
      if position ge 3 then begin
        get_data,nams[0]     ,data=pos
        dist = sqrt(total( pos.y ^2,2))
        get_data,nams[1] ,data = vel
        f_m = gm / rscale^2 * pos.y / (dist^3 # [1,1,1])
        ftot_m += f_m
        store_data,nam_freefall,pos.x,f_m
        xyz_to_polar,/quick_mag,nam_freefall
        ;store_data,'|'+nam_freefall+'|' ,pos.x, sqrt(total(f_m^2,2)),dlimit={colors:'b'}
        nam_rxv = str_sub(nams[0],'_POS_','_RxV_')
        store_data,nam_rxv,pos.x,crossp2(pos.y,vel.y)
        options,nam_freefall+'_mag',colors='b'
        nams_acc_all = [nams_acc_all,nam_freefall]
      endif
    endif

    if keyword_set(jupiter) then begin
      gm =1.266865343447731D+08     ;  126.687d6    ;   km^3/s^2
      rscale = 69911d
      ysub='(R_Jupiter)'
      nam_freefall = 'AccJupiter'
      observer = 'Jupiter'
      spice_position_to_tplot,body,observer,frame=ref_frame,res=res,scale=rscale,name=nams,trange=trange,/force_objects ;million km
      xyz_to_polar,nams[0],/ph_0_360,/quick_mag
      options,nams[0]+'_mag',ysubtitle=ysub,ystyle=3
      if position ge 3 then begin
        get_data,nams[0]     ,data=pos
        dist = sqrt(total( pos.y ^2,2))
        get_data,nams[1] ,data = vel
        f_m = gm / rscale^2 * pos.y / (dist^3 # [1,1,1])
        ftot_m += f_m
        store_data,nam_freefall,pos.x,f_m
        xyz_to_polar,/quick_mag,nam_freefall
        ;store_data,'|'+nam_freefall+'|' ,pos.x, sqrt(total(f_m^2,2)),dlimit={colors:'b'}
        nam_rxv = str_sub(nams[0],'_POS_','_RxV_')
        store_data,nam_rxv,pos.x,crossp2(pos.y,vel.y)
        options,nam_freefall+'_mag',colors='g'
        nams_acc_all = [nams_acc_all,nam_freefall]
      endif
    endif

    if keyword_set(saturn) then begin
      gm =3.794058484179918D+07      ;   km^3/s^2
      rscale = 6.033000000000000d+04
      ysub='(R_Saturn)'
      nam_freefall = 'AccSaturn'
      observer = 'Saturn'
      spice_position_to_tplot,body,observer,frame=ref_frame,res=res,scale=rscale,name=nams,trange=trange,/force_objects ;million km
      xyz_to_polar,nams[0],/ph_0_360,/quick_mag
      options,nams[0]+'_mag',ysubtitle=ysub,ystyle=3
      if position ge 3 then begin
        get_data,nams[0]     ,data=pos
        dist = sqrt(total( pos.y ^2,2))
        get_data,nams[1] ,data = vel
        f_m = gm / rscale^2 * pos.y / (dist^3 # [1,1,1])
        ftot_m += f_m
        store_data,nam_freefall,pos.x,f_m
        xyz_to_polar,/quick_mag,nam_freefall
        ;store_data,'|'+nam_freefall+'|' ,pos.x, sqrt(total(f_m^2,2)),dlimit={colors:'b'}
        nam_rxv = str_sub(nams[0],'_POS_','_RxV_')
        store_data,nam_rxv,pos.x,crossp2(pos.y,vel.y)
        options,nam_freefall+'_mag',colors='g'
        nams_acc_all = [nams_acc_all,nam_freefall]
      endif
    endif

    if position ge 3 then begin
      nam_ftot = 'AccTot'
      nam_diff = nams_acc+'-'+nam_ftot
      get_data, nams_acc,data=acc_ssb
      store_data,nam_ftot,acc_ssb.x,ftot_m
      store_data,nam_diff,acc_ssb.x,acc_ssb.y + ftot_m
      nams_acc_all = [nams_acc_all,nam_ftot,nam_diff]
      ;nams_acc_all = [nams_acc,nam_ftot,nam_diff]
      ;xyz_to_polar,/quick_mag,nams_acc_all
      xyz_to_polar,/quick_mag,[nam_ftot,nam_diff]
      options,nam_ftot+'_mag',colors='b'
      options,nam_diff+'_mag',colors='r'
      store_data,'|ACC|',data=nams_acc_all + '_mag',dlimit={panel_size:3,yrange:[1e-14,1e-2],ylog:1}
    endif

  endif

  if keyword_set(quaternion) then begin
    spice_qrot_to_tplot,'SPP_SPACECRAFT',att_frame,get_omega=3,res=res,names=tn,trange=trange,check_obj=['SPP_SPACECRAFT','SPP','SUN'],/force_objects,error=angle_error*!pi/180.
    get_data,'SPP_SPACECRAFT_QROT_SPP_RTN',dat=dat
    qtime=dat.x
    quat_SC_to_RTN=dat.y
    quat_SC2_to_SC=[.5d,.5d,.5d,-.5d]
    quat_SC_to_SC2=[.5d,-.5d,-.5d,.5d]

    quat_SC2_to_RTN=qmult(quat_SC_to_RTN, replicate(1,n_elements(qtime)) # quat_SC2_to_SC)
    store_data,'SPP_QROT_SC2>RTN',qtime,quat_SC2_to_RTN,dlim={SPICE_FRAME:'SPP_SC2',colors:'dbgr',constant:0.,labels:['Q_W','Q_X','Q_Y','Q_Z'],labflag:-1}
    store_data,'SPP_QROT_SC2>RTN_Euler_angles',qtime,180/!pi*quaternion_to_euler_angles(quat_SC2_to_RTN),dlimit={colors:'bgr',constant:0.,labels:['Roll','Pitch','Yaw'],labflag:-1,spice_frame:'SPP_SPACECRAFT'}
    store_data,'SPP_QROT_RTN>SC2_Euler_angles',qtime,180/!pi*quaternion_to_euler_angles(qconj(quat_SC2_to_RTN)),dlimit={colors:'bgr',constant:0.,labels:['Roll','Pitch','Yaw'],labflag:-1,spice_frame:'SPP_SPACECRAFT'}
    ;tplot

    if keyword_set(test) then begin   ; test routines
      copy_data,'SPP_SPACECRAFT_QROT_SPP_RTN','spp_QROT_SC>RTN'
      if 1 then begin
        dprint,'Select a time interval to test...'
        ctime,tr
        spp_fld_load,trange=tr,type='mag_SC'
        copy_data,'psp_fld_l2_mag_SC','psp_mag_SC'
        options,/default,'psp_mag_SC','ytitle'
        spp_fld_load,trange=tr,type='mag_RTN'

        store_data,'spp_QROT_SC>SC2',[1e9,2e9],replicate(1,2) # quat_sc_to_sc2   ; this rotation is a constant
        tplot_quaternion_rotate,'psp_mag_SC','spp_QROT_SC>SC2'
        tplot_quaternion_rotate,'psp_mag_SC2','spp_QROT_SC2>RTN',newname='psp_mag_test_RTN'
        tplot_quaternion_rotate,'psp_mag_SC','spp_QROT_SC>RTN',name=name
        printdat,name

        dif_data,'psp_fld_l2_mag_RTN','psp_mag_test_RTN'
        dif_data,'psp_fld_l2_mag_RTN','psp_mag_RTN'
        options,'psp_fld_l2_mag_RTN-psp_mag_RTN', ytitle='M1-M2',colors='bgr'

        get_data,'spp_QROT_SC>RTN',data=qdat
        qdat.x += 3.9   ; time shift
        store_data,'shift_QROT_SC>RTN',data=qdat
        tplot_quaternion_rotate,'psp_mag_SC','shift_QROT_SC>RTN',newname = 'psp_shift_mag_RTN'
        ;dif_data,'psp_mag_RTN','test_mag_RTN'
        dif_data,'psp_fld_l2_mag_RTN','psp_shift_mag_RTN'
        options,'*RTN-psp*',yrange=[-.6,.6],ystyle=1,constant=0.
        tplot,['spp_QROT_SC2>RTN','SPP_SPACECRAFT_Q-OMEGA2_SPP_RTN','spp_QROT_RTN>SC2_Euler_angles','psp_mag_SC2','psp_fld_l2_mag_RTN','psp_mag_RTN', $
          'psp_fld_l2_mag_RTN-psp_mag_RTN','psp_fld_l2_mag_RTN-psp_shift_mag_RTN']
        ;tplot,/add,'psp_fld_l2_mag_RTN-shift_mag_RTN'
        ;tplot,/add,'psp_mag_RTN-test_mag_RTN'

        if 0 then begin
          options,'psp_mag_SC',spice_frame='SPP_SPACECRAFT', /default
          spice_vector_rotate_tplot,'psp_mag_SC','SPP_RTN' ;,check_obj=['SPP_SPACECRAFT','SPP','SPP_RTN'];,/force_objects
        endif

      endif else begin
        dprint,'Select a time interval to test...'
        ctime,tr
        spp_fld_load,trange=tr,type='mag_SC_4_Sa_per_Cyc'
        copy_data,'psp_fld_l2_mag_SC_4_Sa_per_Cyc','psp_mag_4NYHz_SC'
        spp_fld_load,trange=tr,type='mag_RTN_4_Sa_per_Cyc'
        ;copy_data,'psp_fld_l2_mag_RTN_4_Sa_per_Cyc','psp_mag_4NYHz_RTN'

        store_data,'spp_QROT_SC>SC2',tr,replicate(1,n_elements(tr)) # quat_sc_to_sc2   ; this rotation is a constant
        tplot_quaternion_rotate,'psp_mag_4NYHz_SC','spp_QROT_SC>SC2'
        tplot_quaternion_rotate,'psp_mag_4NYHz_SC2','spp_QROT_SC2>RTN',newname='psp_mag_4NYHz_test_RTN'
        tplot_quaternion_rotate,'psp_mag_4NYHz_SC','spp_QROT_SC>RTN',name=name
        printdat,name
      endelse
    endif

    if 0 then begin
      store_data,'spp_swp_sc_x',dat.x,replicate(1.,n_elements(dat.x))#[1.,0.,0.],dlim={SPICE_FRAME:'SPP_SPACECRAFT',colors:'bgr',labels:['SC_X','SC_Y','SC_Z'],labflag:-1}
      store_data,'spp_swp_sc_z',dat.x,replicate(1.,n_elements(dat.x))#[0.,0.,1.],dlim={SPICE_FRAME:'SPP_SPACECRAFT',colors:'bgr',labels:['SC_X','SC_Y','SC_Z'],labflag:-1}
      spice_vector_rotate_tplot,'spp_swp_sc_x','SPP_RTN',check_obj=['SPP_SPACECRAFT','SPP','SPP_RTN'];,/force_objects
      spice_vector_rotate_tplot,'spp_swp_sc_z','SPP_RTN',check_obj=['SPP_SPACECRAFT','SPP','SPP_RTN']
      get_data,'spp_swp_sc_x_SPP_RTN',dat=datx
      get_data,'spp_swp_sc_z_SPP_RTN',dat=datz
      store_data,'spp_swp_sc_angle_(degrees)',dat.x,!radeg*[[atan(datx.y[*,2],datx.y[*,1])],[acos(-datz.y[*,0])]],dlim={constant:0.,colors:'br',labels:['SC_X_TN','SC_Z_SUN'],labflag:-1}
    endif
  endif

end
