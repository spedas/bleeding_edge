;+
; NAME: rbsp_efw_poynting_flux_survey_crib.pro
; SYNTAX:
; PURPOSE: Crib sheet for creating Poynting flux tplot variables from EFW and
;          EMFISIS data.
;          This is called by the program rbsp_efw_make_pflux.pro, but can
;          be used independently.
; INPUT:  smoothing -> period (sec) to smooth over
;         detrending -> period (sec) to detrend over
;         cadence_mag -> '1sec','4sec','hires'
;         spinfit -> spinfit the Efield data? Otherwise uses the 32 S/s MGSE data
; OUTPUT: tplot variables of Poynting flux in various coord systems
; KEYWORDS:
; NOTES:  The burst and tt0 and tt1 keywords were added (by Aaron) to test the
;         results of this crib sheet with rbsp_poynting_flux.pro. They compare
;         almost identically for a test chorus event. (see aaron_scott_pflux_comparison.pro)
;
; HISTORY: Adapted from Scott Thaller's Poynting flux crib by Aaron Breneman
;
; VERSION:
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2020-09-11 13:39:29 -0700 (Fri, 11 Sep 2020) $
;   $LastChangedRevision: 29142 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/examples/rbsp_efw_poynting_flux_survey_crib.pro $
;-


pro rbsp_efw_poynting_flux_survey_crib,date,sc,smoothing,detrending,$
  cadence_mag=cadence_mag,$
  spinfit=spinfit,$
  use_l2_spinfitdata=use_l2_spinfitdata,$
  use_again=use_again,edb=edb,$
  default_omni_values=default_omni_values,$
  freq=freq,no_smooth=no_smooth,$
  no_detrend=no_detrend,$
  burst=burst,$
  tt0=tt0,$
  tt1=tt1


  smoothing = float(smoothing)
  detrending = float(detrending)

  if ~keyword_set(cadence_mag) then cadence_mag = '4sec'

  rbx = 'rbsp'+sc+'_'

  if not keyword_set(use_again) then begin ;if statement #1

     timespan,date,1,/day

     get_timespan,ts
     date=time_string(ts[0])

     rbsp_efw_init
     cdf_leap_second_init


    rbsp_load_spice_cdf_file,sc



;--------------------------------------------------------------------
;Loads EMFISIS GSE
;--------------------------------------------------------------------

     if cadence_mag eq 'hires' then brate = 64.
     if cadence_mag eq 'quicklook' or cadence_mag eq 'ql' then brate = 64.
     if cadence_mag eq '1sec' then brate = 1/1.
     if cadence_mag eq '4sec' then brate = 1/4.

     ;;Decimate the Bfield values based on smoothing period
     dec_val = 10.*(1/smoothing) ;limit to the decimation.

     nn=1
     while brate ge dec_val do begin
        nn++
        brate = brate/2.
     endwhile
     nn=nn-2

     if nn gt 1 then level=nn else level=0



     ;load the EMFISIS data and the model magnetic field
     ;Also loads the ephemeris data
     rbsp_efw_dcfield_removal_crib,sc,/no_spice_load,/noplot,$
       cadence=cadence_mag,model='t01',/nodelete,$
       decimate_level=level

     get_data,rbx+'mag'+'_mgse_for_subtract',data=Bmag_l3
     copy_data,rbx+'mag'+'_mgse_for_subtract','Mag_mgse'

     get_data,'rbsp'+sc+'_spinaxis_direction_gse',data=wsc_gse


     ;Downsample the ephermeris data to 1min cadence
     tinterpol_mxn,rbx+'state_vel_mgse','rbsp'+sc+'_spinaxis_direction_gse',/spline,/overwrite
     tinterpol_mxn,rbx+'state_pos_gsm','rbsp'+sc+'_spinaxis_direction_gse',/spline,/overwrite
     tinterpol_mxn,rbx+'state_mlat','rbsp'+sc+'_spinaxis_direction_gse',/spline,/overwrite

;-------------------------------------------------------------------------
;Load electric field data
;--------------------------------------------------



     if keyword_set(spinfit) then begin
;        if not KEYWORD_SET(use_l2_spinfitdata) then begin
        rbsp_load_efw_waveform_l3,probe=sc
        copy_data,'rbsp'+sc+'_efw_efield_inertial_frame_mgse','Efield_mgse'
;        endif else begin
;          rbsp_load_efw_waveform_l2,probe=sc,datatype='e-spinfit-mgse'
;          copy_data,'rbsp'+sc+'_efw_e-spinfit-mgse_efield_spinfit_mgse','Efield_mgse'
;        endelse
     endif else begin
        rbsp_load_efw_esvy_mgse,probe=sc,/no_spice_load
        rbsp_vxb_subtract,rbx+'state_vel_mgse','Mag_mgse',rbx+'efw_esvy_mgse'
        copy_data,'Esvy_mgse_vxb_removed','Efield_mgse'
     endelse



     get_data,'Efield_mgse',data=efield_mgse

     ;Decimate the Efield and Bfield values based on smoothing period
     erate = rbsp_sample_rate(efield_mgse.x,OUT_MED_AVG=medavg)
     erate = medavg[0]

     nn=1
     while erate ge dec_val do begin
        nn++
        erate = erate/2.
     endwhile
     nn=nn-2
     if nn gt 1 then rbsp_decimate,'Efield_mgse',level=nn,newname='Efield_mgse'


     get_data,'Efield_mgse',data=efield_mgse
     get_data,'Mag_mgse',data=mag_mgse
     Ey = efield_mgse.y[*,1]
     Ez = efield_mgse.y[*,2]
     etimes = efield_mgse.x


;-------------------------------------------------------------------------------
;OMNI data
;-------------------------------------------------------------------------------

     modpars='t01_par'
     copy_data,rbx+'mag_gse_t01_omni','B_t01_gse'



     ttrace2equator,rbx+'state_pos_gsm',newname=rbx+'out_foot',/km
     ttrace2iono,rbx+'state_pos_gsm',newname=rbx+'out_iono_foot',/km
;     get_data,rbx+'state_out_foot',data=d
     get_data,rbx+'out_foot',data=d
     tt01,rbx+'out_iono_foot',parmod=modpars;,period=0.5
     get_data,rbx+'out_iono_foot_bt01',data=Bt01_iono
     Bt01_iono_mag = SQRT((Bt01_iono.y[*,0])^2+(Bt01_iono.y[*,1])^2+(Bt01_iono.y[*,2])^2)

     ;-----------------------------------------------------------------------------------------------
     ;; get_tsy_params,'OMNI_HRO_1min_SYM_H','omni_imf','OMNI_HRO_1min_proton_density','OMNI_HRO_1min_flow_speed','t01',/speed,/imf_yz
     ;; modpars='t01_par'

     ttrace2iono,rbx+'state_pos_gsm',external_model=model,par=modpars,$
      newname=rbx+'out_iono_foot_loc',/km

     cotrans,rbx+'out_iono_foot_loc',rbx+'out_iono_foot_loc_sm',/GSM2SM
     get_data,rbx+'out_iono_foot_loc_sm',data=pos_sm

     radius_t01_foot = sqrt(pos_sm.y[*,0]^2 + pos_sm.y[*,1]^2 +pos_sm.y[*,2]^2)/6371.

     dr2 = sqrt(pos_sm.y[*,0]^2 + pos_sm.y[*,1]^2)
     dz2 = pos_sm.y[*,2]

     mlat_t01_foot = atan(dz2,dr2)
     mlat_t01_foot = mlat_t01_foot/!dtor

     cotrans,rbx+'out_iono_foot_loc',rbx+'out_iono_foot_loc_gse',/GSM2GSE
     get_data,rbx+'out_iono_foot_loc_gse',data=pos_gse

     angle_tmp = atan(pos_gse.y[*,1],pos_gse.y[*,0])/!dtor
     goo = where(angle_tmp lt 0.)
     if goo[0] ne -1 then angle_tmp[goo] = 360. - abs(angle_tmp[goo])
     angle_rad_t01 = angle_tmp * 12/180. + 12.
     goo = where(angle_rad_t01 ge 24.)
     if goo[0] ne -1 then angle_rad_t01[goo] = angle_rad_t01[goo] - 24

     store_data,'R_t01',data={x:pos_sm.x,y:radius_t01_foot}
     store_data,'MLT_t01',data={x:pos_gse.x,y:angle_rad_t01}
     store_data,'MLAT_t01',data={x:pos_sm.x,y:mlat_t01_foot}

     rbsp_gse2mgse,'B_t01_gse',reform(wsc_gse.y[0,*]),newname='Mag_mgse_mod'
     get_data,'Mag_mgse',data=B_mgse
     copy_data,rbx+'mag_mgse_t96_dif','B_mgse!Cmodel_subtracted'

     B_mag = SQRT((B_mgse.y[*,0])^2+(B_mgse.y[*,1])^2+(B_mgse.y[*,2])^2)
     store_data,'|B|!CnT',data={x:B_mgse.x,y:B_mag}



  endif else begin  ;if reloading

     get_data,'Efield_mgse',data=efield_mgse
     get_data,'Mag_mgse',data=b_mgse
     Ey = efield_mgse.y[*,1]
     Ez = efield_mgse.y[*,2]

     etimes = efield_mgse.x
     get_data,rbx+'spinaxis_direction_gse',data=wsc_gse

  endelse



  get_data,rbx+'out_iono_foot_bt01',data=Bt01_iono
  Bt01_iono_mag = SQRT((Bt01_iono.y[*,0])^2+(Bt01_iono.y[*,1])^2+(Bt01_iono.y[*,2])^2)



  ;---------------------------------------------------------------
  ;get fields to filter for Poynting flux


  get_data,rbx+'mag_mgse_t01_omni_dif',data=B_mgse_mm
  Bx=(B_mgse_mm.y)[*,0]
  By=(B_mgse_mm.y)[*,1]
  Bz=(B_mgse_mm.y)[*,2]


  if keyword_set(burst) then begin
     Bxmm = Bx
     Bymm = By
     Bzmm = Bz
  endif else begin
     Bxmm=interp(Bx,B_mgse_mm.x,etimes,/no_extrap)
     Bymm=interp(By,B_mgse_mm.x,etimes,/no_extrap)
     Bzmm=interp(Bz,B_mgse_mm.x,etimes,/no_extrap)
  endelse


  Bx=(B_mgse.y)[*,0]
  By=(B_mgse.y)[*,1]
  Bz=(B_mgse.y)[*,2]

  if ~keyword_set(burst) then begin
     Bx=interp(Bx,B_mgse.x,etimes,/no_extrap)
     By=interp(By,B_mgse.x,etimes,/no_extrap)
     Bz=interp(Bz,B_mgse.x,etimes,/no_extrap)
  endif
  B_mag = SQRT(Bx^2+By^2+Bz^2)

  theta = ABS((180./!pi)*asin(Bx/B_mag))
  store_data,'theta',data={x:etimes,y:theta}

  Ex = -(Ey*By+Ez*Bz)/Bx
  if keyword_set(edb) then begin
     goo = where(theta lt 15.0)
     if goo[0] ne -1 then Ex[goo] = 0.0
     store_data,'Ex-from-EdotB!CB>15!eo!nfrom-SP!CmV/m',data={x:etimes,y:Ex}
  endif


  file_flag = Ex
  goo = where(theta lt 15.0)
  if goo[0] ne -1 then file_flag[goo] = 0
  goo = where(theta gt 15.0)
  if goo[0] ne -1 then file_flag[goo] = 1


  flag0 = Ex
  flag1 = Ex
  goo = where(theta lt 15.0)
  if goo[0] ne -1 then flag0[goo] = 0.0
  goo = where(theta ge 15.0)
  if goo[0] ne -1 then flag0[goo] = !values.f_nan

  goo = where(theta ge 15.0)
  if goo[0] ne -1 then flag1[goo] = 1.0
  goo = where(theta lt 15.0)
  if goo[0] ne -1 then flag1[goo] = !values.f_nan


  store_data,'E-dot-B!Cflag',data={x:etimes,y:[[flag0],[flag1]]},$
             dlim={thick:[3],colors:[6,4],labels:['NO E-dot-B','OK E-dot-B']}
  options,'E-dot-B!Cflag',panel_size=0.3
  ylim,['E-dot-B!Cflag'],-0.5,1.5


  if not keyword_set(edb) then Ex[*]=0.0



  ;-----------------------------------------------------------------------------
  ;Determine points to detrend and smooth the data to obtain the desired
  ;wave period range

  rate = rbsp_sample_rate(etimes,out_med_avg=medavg)
  cadence = 1/medavg[0]


  if keyword_set(freq) then unit='mHz'
  if not keyword_set(freq) then unit='sec'

  detpts=detrending/cadence
;  detren=round(detpts)
  detren=detpts

  if keyword_set(freq) then detrend=string(format='(f0.1)',1000.0/(detren*cadence))
  if not keyword_set(freq) then begin
     if cadence_mag ne 'hires' then detrend=string(format='(i0.1)',round(detren*cadence))
     if cadence_mag eq 'hires' then detrend=string(format='(f0.1)',(detren*cadence))
  endif
  detrend = strtrim(floor(float(detrend)),2)

  print,'Detrending the data '+detrend+ unit

  smopts=smoothing/cadence
;  smoo=round(smopts)            ;< (n_elements(etimes)-1) & print,'number of points smoothed over is ' & print,smoo
  smoo=smopts            ;< (n_elements(etimes)-1) & print,'number of points smoothed over is ' & print,smoo


  if keyword_set(freq) then smoothed=string(format='(f0.1)',1000.0/(smoo*cadence))
  if not keyword_set(freq) then begin
     if cadence_mag eq 'hires' then smoothed=string(format='(f0.1)',(smoo*cadence))
     if cadence_mag ne 'hires' then smoothed=string(format='(i0.1)',round(smoo*cadence))
  endif
  smoothed = strtrim(floor(float(smoothed)),2)


  print,'Smoothing data '+smoothed+unit

  range=smoothed+'-'+detrend+unit


  print,detren
  print,smoo

  if ~keyword_set(no_detrend) then begin

     dEx=Ex-smooth(Ex,detren,/nan)
     dEy=Ey-smooth(Ey,detren,/nan)
     dEz=Ez-smooth(Ez,detren,/nan)
     dBx=Bxmm-smooth(Bxmm,detren,/nan)
     dBy=Bymm-smooth(Bymm,detren,/nan)
     dBz=Bzmm-smooth(Bzmm,detren,/nan)

  endif else begin

     detren = 1
     detrend ='no-detrending!C'

     dEx=Ex & dEy=Ey & dEz=Ez
     dBx=Bxmm & dBy=Bymm & dBz=Bzmm

  endelse

  if ~keyword_set(no_smooth) then begin

     fEx=smooth(dEx,smoo,/nan)
     fEy=smooth(dEy,smoo,/nan)
     fEz=smooth(dEz,smoo,/nan)
     fBx=smooth(dBx,smoo,/nan)
     fBy=smooth(dBy,smoo,/nan)
     fBz=smooth(dBz,smoo,/nan)

  endif else begin

     smoo = 1
     smoothed = 'no-smoothing'

     fEx = dEx & fEy = dEy & fEz = dEz
     fBx = dBx & fBy = dBy & fBz = dBz

  endelse


  range=smoothed+'-'+detrend+unit
  Bxbg=smooth((Bx/B_mag),detren,/nan)
  Bybg=smooth((By/B_mag),detren,/nan)
  Bzbg=smooth((Bz/B_mag),detren,/nan)

  Bx_bkgrd = smooth(Bx,smoo,/nan)
  By_bkgrd = smooth(By,smoo,/nan)
  Bz_bkgrd = smooth(Bz,smoo,/nan)

  store_data,'Back-ground!CB-field',$
    data={x:etimes,y:[[Bx_bkgrd],[By_bkgrd],[Bz_bkgrd]]},$
    dlim={colors:[2,4,6],labels:['Bx','By','Bz']}

  mu=0.0000001*4.0*!Pi

  Sx=(fEy*fBz-fEz*fBy)/(mu*1e9)
  Sy=(fEz*fBx-fEx*fBz)/(mu*1e9)
  Sz=(fEx*fBy-fEy*fBx)/(mu*1e9)

  S_para = Sx*Bxbg+Sy*Bybg+Sz*Bzbg
  E_para =  fEx*Bxbg+fEy*Bybg+fEz*Bzbg
  B_para =  fBx*Bxbg+fBy*Bybg+fBz*Bzbg


  edb_stat=''
  if keyword_set(edb) then edb_stat='E-dot-B'
  if not keyword_set(edb) then edb_stat='Ex-eq-0'

  spcr = 'rbsp'+sc

  store_data,spcr+'-S-para!CS!imgse!n-dot-B!imgse!n!C'+range+'!Cergs/cm!e2!ns',$
             data={x:etimes,y:S_para},dlim={colors:[0],labels:['S-para']}
  store_data,spcr+'-B-para-FAC!C'+range+'!CnT',data={x:etimes,y:B_para},dlim={colors:[0],labels:['B-para']}
  store_data,spcr+'-E-para-FAC!C'+range+'!CmV/m',data={x:etimes,y:E_para},dlim={colors:[0],labels:['E-para']}


  store_data,spcr+'-Ex-mgse!CE-dot-B!C'+range+'!CmV/m',data={x:etimes,y:fEx},dlim={colors:[0],labels:['Ex']}
  store_data,spcr+'-Ey-mgse!C'+range+'!CmV/m',data={x:etimes,y:fEy},dlim={colors:[0],labels:['Ey']}
  store_data,spcr+'-Ez-mgse!C'+range+'!CmV/m',data={x:etimes,y:fEz},dlim={colors:[0],labels:['Ez']}

  store_data,spcr+'-Bx-mgse!Cmodel-sub!C'+range+'!CnT',data={x:etimes,y:fBx},dlim={colors:[0],labels:['Bx']}
  store_data,spcr+'-By-mgse!Cmodel-sub!C'+range+'!CnT',data={x:etimes,y:fBy},dlim={colors:[0],labels:['By']}
  store_data,spcr+'-Bz-mgse!Cmodel-sub!C'+range+'!CnT',data={x:etimes,y:fBz},dlim={colors:[0],labels:['Bz']}

  edb_stat=''
  if keyword_set(edb) then edb_stat='E-dot-B'
  if not keyword_set(edb) then edb_stat='Ex-eq-0'

  store_data,spcr+'-Sx-mgse!C'+range+'!Cergs/cm!e2!ns',data={x:etimes,y:Sx},dlim={colors:[0],labels:['Sx']}
  store_data,spcr+'-Sy-mgse!C'+edb_stat+'!C'+range+'!Cergs/cm!e2!ns',data={x:etimes,y:Sy},dlim={colors:[0],labels:['Sy']}
  store_data,spcr+'-Sz-mgse!C'+edb_stat+'!C'+range+'!Cergs/cm!e2!ns',data={x:etimes,y:Sz},dlim={colors:[0],labels:['Sz']}

;--------------------------------------------------
;calc mapped Poynting flux
;--------------------------------------------------

  Bt01_iono_mag = interp(Bt01_iono_mag,Bt01_iono.x,etimes,/no_extrap)

  S_para_mapped = S_para*ABS(Bt01_iono_mag/B_mag)

  get_data,[rbx+'state_mlat'],data=mlat
  mtimes = mlat.x
  mlat = mlat.y
  mlat = interp(mlat,mtimes,etimes,/no_extrap)

  goo = where(mlat lt 0)
  if goo[0] ne -1 then S_para_mapped[goo] *= -1
  ;; S_para_mapped[where(mlat lt 0)] = -S_para_mapped[where(mlat lt 0)]
  ;; S_para_mapped[where(mlat lt 0)] = -S_para_mapped[where(mlat lt 0)]




  store_data,'Poynting-flux!C'+range+'!C'+edb_stat+'!Cfield-aligned!CEarthward=positive!Cmapped-100km!Cergs/cm!e2!ns',$
             data={x:etimes,y:S_para_mapped}

  date2=(strsplit(time_string(etimes[0]),'/',/extract))[0]


  ;Find SC velocity perp to B field
  get_data,rbx+'state_vel_mgse',data=vel
  vtimes = vel.x
  vx = vel.y[*,0] & vy = vel.y[*,1] & vz = vel.y[*,2]

  vx = interp(vx,vtimes,etimes,/no_extrap)
  vy = interp(vy,vtimes,etimes,/no_extrap)
  vz = interp(vz,vtimes,etimes,/no_extrap)

  vx_para = (vx*Bxbg+vy*Bybg+vz*Bzbg)*Bxbg
  vy_para = (vx*Bxbg+vy*Bybg+vz*Bzbg)*Bybg
  vz_para = (vx*Bxbg+vy*Bybg+vz*Bzbg)*Bzbg

  vx_perp = vx - vx_para
  vy_perp = vy - vy_para
  vz_perp = vz - vz_para

  v_perp_mag = SQRT(vx_perp^2 + vy_perp^2 + vz_perp^2)
  store_data,'v_perp',data={x:etimes,y:v_perp_mag}

  rate = rbsp_sample_rate(etimes,out_med_avg=medavg)
  cadence = 1/medavg[0]


  dl_perp_mapped_space = v_perp_mag*1000.*100.*cadence*SQRT(ABS(B_mag/Bt01_iono_mag))
  dl_perp_mapped_time  = cadence

  S_int_space = total(S_para_mapped*dl_perp_mapped_space,/nan,/cumulative)
  S_int_time = total(S_para_mapped*dl_perp_mapped_time,/nan,/cumulative)

  store_data,'Spatial-Int.-Poynting-flux!C'+range+'!C'+edb_stat+'!Cfield-aligned!Cmapped-100km!Cergs/cm-s',$
             data={x:etimes,y:S_int_space}
  store_data,'Time-Int.-Poynting-flux!C'+range+'!C'+edb_stat+'!Cfield-aligned!Cmapped-100km!Cergs/cm!e2!n',$
             data={x:etimes,y:S_int_time}



  tplot_var = 'Poynting-flux!C'+range+'!C'+edb_stat+'!Cfield-aligned!CEarthward=positive!Cmapped-100km!Cergs/cm!e2!ns'
  tplot_var2 = 'Spatial-Int.-Poynting-flux!C'+range+'!C'+edb_stat+'!Cfield-aligned!Cmapped-100km!Cergs/cm-s'
  tplot_var3 = 'Time-Int.-Poynting-flux!C'+range+'!C'+edb_stat+'!Cfield-aligned!Cmapped-100km!Cergs/cm!e2!n'


  get_data,tplot_var,data=mpf_dat
  mstimes = mpf_dat.x

  emppf = mpf_dat.y
  goo = where(emppf lt 0)
  if goo[0] ne -1 then emppf[goo] = !values.f_nan

  umppf = mpf_dat.y

  goo = where(umppf gt 0)
  if goo[0] ne -1 then umppf[goo] = !values.f_nan
  umppf = ABS(umppf)

  store_data,'Earthward-Poynting-flux!Cfield-aligned!Cmapped=100-km!C'+range+'!C'+edb_stat+'!Cergs/cm!e2!ns',$
             data={x:mstimes,y:emppf}
  store_data,'Upwards-Poynting-flux!Cfield-aligned!Cmapped=100-km!C'+range+'!C'+edb_stat+'!Cergs/cm!e2!ns',$
             data={x:mstimes,y:umppf}

  max_n = max(umppf,/nan)
  max_p = max(emppf,/nan)
  the_max = max([max_n,max_p])

  ylim,['Upwards-Poynting-flux!Cfield-aligned!Cmapped=100-km!C'+range+'!C'+edb_stat+'!Cergs/cm!e2!ns'],the_max,0.01
  ylim,['Earthward-Poynting-flux!Cfield-aligned!Cmapped=100-km!C'+range+'!C'+edb_stat+'!Cergs/cm!e2!ns'],0.01,the_max
  options,['Earthward-Poynting-flux!Cfield-aligned!Cmapped=100-km!C'+range+'!C'+edb_stat+'!Cergs/cm!e2!ns',$
           'Upwards-Poynting-flux!Cfield-aligned!Cmapped=100-km!C'+range+'!C'+edb_stat+'!Cergs/cm!e2!ns'],'ylog',1


;date2=(strsplit(time_string(etimes[0]),'/',/extract))[0]
;dtime=0D
;time2str,dtime
;today=time_string(dtime)
;time = (strsplit(today,'/',/extract))[1]
;today = (strsplit(today,'/',/extract))[0]

;options,['Upwards-Poynting-flux!Cfield-aligned!Cmapped=100-km!C'+range+'!C'+edb_stat+'!Cergs/cm!e2!ns'],subtitle=subtitle


;plot integrated Poynting flux

;get_data,tplot_var2,data=ipf_dat
;get_data,tplot_var2+'_tclip',data=ipf_dat_clip
;mstimes = ipf_dat.x
;ipf0 = (ipf_dat_clip.y)[0]
;ipf = ipf_dat.y-ipf0
;store_data,'Spatial-Int.-Poynting-flux!C'+range+'!C'+edb_stat+'!Cfield-aligned!Cmapped-100km!Cergs/cm-s',data={x:mstimes,y:ipf}


;get_data,tplot_var3,data=ipf_dat
;get_data,tplot_var3+'_tclip',data=ipf_dat_clip
;mstimes = ipf_dat.x
;ipf0 = (ipf_dat_clip.y)[0]
;ipf = ipf_dat.y-ipf0
;store_data,'Time-Int.-Poynting-flux!C'+range+'!C'+edb_stat+'!Cfield-aligned!Cmapped-100km!Cergs/cm!e2!n',data={x:mstimes,y:ipf}



;----------------------------------------------------------------------------------------

;FIND E, B and S in Field Aligned Coordinates (FAC)

;calculate background B fields


  fac_detren = detren

  fBxbg=smooth((Bx/B_mag),fac_detren,/nan)
  fBybg=smooth((By/B_mag),fac_detren,/nan)
  fBzbg=smooth((Bz/B_mag),fac_detren,/nan)

  nb= n_elements(fBxbg)
  bg_field = fltarr(nb,3)
  bg_field[*,0]  = fBxbg & bg_field[*,1]  = fBybg & bg_field[*,2]  = fBzbg

  nef = n_elements(fEy)
  dE_field = fltarr(nef,3)
  dE_field[*,0] = fEx & dE_field[*,1] = fEy & dE_field[*,2] = fEz

  nbf = n_elements(fBx)
  dB_field = fltarr(nbf,3)
  dB_field[*,0] = fBx & dB_field[*,1] = fBy & dB_field[*,2] = fBz


  rbsp_gse2mgse,rbx+'state_pos_gse',reform(wsc_gse.y[0,*]),$
                newname=rbx+'state_pos_mgse'
  get_data,rbx+'state_pos_mgse',data=mgse_pos
  mptimes = mgse_pos.x
  xmgse = mgse_pos.y[*,0] & ymgse = mgse_pos.y[*,1] & zmgse = mgse_pos.y[*,2]
  radial_pos = SQRT(xmgse^2+ymgse^2+zmgse^2)

  xmgse = interp(xmgse,mptimes,etimes,/no_extrap)
  ymgse = interp(ymgse,mptimes,etimes,/no_extrap)
  zmgse = interp(zmgse,mptimes,etimes,/no_extrap)
  radial_pos = interp(radial_pos,mptimes,etimes,/no_extrap)

  q56_vec = fltarr(nbf,3)         ;the vectors along the spin axis
  q56_vec[*,0] = xmgse/radial_pos ;REPLACE WITH RADIAL VECTOR MGSE
  q56_vec[*,1] = ymgse/radial_pos
  q56_vec[*,2] = zmgse/radial_pos

  ;find the E perp to B
  BXE = fltarr(nef,3)
  for xx=0L,nef-1 do BXE[xx,*] = crossp(bg_field[xx,*],dE_field[xx,*])
  BXEXB= fltarr(nef,3)
  for xx=0L,nef-1 do BXEXB[xx,*] = crossp(BXE[xx,*],bg_field[xx,*])

  ;define orthogonal perpendicular unit vectors
  perp1_dir = fltarr(nef,3)
  for xx=0L,nef-1 do perp1_dir[xx,*] = crossp(bg_field[xx,*],q56_vec[xx,*])

  perp2_dir = fltarr(nef,3)
  for xx=0L,nef-1 do perp2_dir[xx,*] = crossp(perp1_dir[xx,*],bg_field[xx,*])


  ;need to normalize perp 1 and perp2 direction
  bdot56 = fltarr(nef)
  for xx=0L,nef-1 do bdot56[xx] = bg_field[xx,0]*q56_vec[xx,0]+ bg_field[xx,1]*q56_vec[xx,1]+ bg_field[xx,2]*q56_vec[xx,2]
  one_array = fltarr(nef)
  one_array[*] = 1.0
  perp_norm_fac1 = SQRT(one_array - (bdot56*bdot56))
  perp_norm_fac = fltarr(nef,3)
  perp_norm_fac[*,0] = perp_norm_fac1
  perp_norm_fac[*,1] = perp_norm_fac1
  perp_norm_fac[*,2] = perp_norm_fac1

  perp1_dir = perp1_dir/(perp_norm_fac)
  perp2_dir = perp2_dir/(perp_norm_fac)


  ;take dot product of E perp into the two perp unit vecs to find perp E in FAC
  E_perp_1  = fltarr(nef)
  for xx=0L,nef-1 do E_perp_1[xx] = BXEXB[xx,0]*perp1_dir[xx,0] +  BXEXB[xx,1]*perp1_dir[xx,1] +  BXEXB[xx,2]*perp1_dir[xx,2]
  E_perp_2  = fltarr(nef)
  for xx=0L,nef-1 do E_perp_2[xx] = BXEXB[xx,0]*perp2_dir[xx,0] +  BXEXB[xx,1]*perp2_dir[xx,1] +  BXEXB[xx,2]*perp2_dir[xx,2]

  perp_1 = 'azimuthal!C(eastward)'
  perp_2 = 'radial!C(outward)'

  store_data,'dE-'+perp_1+'!C'+edb_stat+'!C'+range+'!CmV/m',data = {x:etimes,y:E_perp_1},$
             dlim={constant:[0],colors:[0],labels:[perp_1]}
  store_data,'dE-'+perp_2+'!C'+edb_stat+'!C'+range+'!CmV/m',data = {x:etimes,y:E_perp_2},$
             dlim={constant:[0],colors:[0],labels:[perp_2]}


  ;put B perturbations into FAC
  BXdB = fltarr(nef,3)
  for xx=0L,nef-1 do BXdB[xx,*] = crossp(bg_field[xx,*],dB_field[xx,*])
  BXdBXB= fltarr(nef,3)
  for xx=0L,nef-1 do BXdBXB[xx,*] = crossp(BXdB[xx,*],bg_field[xx,*])

  dB_perp_1  = fltarr(nef)
  for xx=0L,nef-1 do dB_perp_1[xx] = BXdBXB[xx,0]*perp1_dir[xx,0] +  BXdBXB[xx,1]*perp1_dir[xx,1] +  BXdBXB[xx,2]*perp1_dir[xx,2]
  dB_perp_2  = fltarr(nef)
  for xx=0L,nef-1 do dB_perp_2[xx] = BXdBXB[xx,0]*perp2_dir[xx,0] +  BXdBXB[xx,1]*perp2_dir[xx,1] +  BXdBXB[xx,2]*perp2_dir[xx,2]


  store_data,'dB-'+perp_1+'!C'+range+'!CnT',data = {x:etimes,y:dB_perp_1},dlim={constant:[0],colors:[0],labels:[perp_1]}
  store_data,'dB-'+perp_2+'!C'+range+'!CnT',data = {x:etimes,y:dB_perp_2},dlim={constant:[0],colors:[0],labels:[perp_2]}


  ;use the perp dE and dB to find parallel Poynting flux
  eperp2xbperp1 = (E_perp_2*dB_perp_1)/(mu*1e9)
  eperp1xbperp2 =(-E_perp_1*dB_perp_2)/(mu*1e9)

  store_data,'S!i||!n(in-situ)!CdE-perp-2XdB-perp-1!C'+edb_stat+'!C'+range+'!Cergs/cm!e2!ns',$
             data={x:etimes,y:eperp2xbperp1},dlim={constant:[0]}
  store_data,'S!i||!n(in-situ)!CdE-perp-1XdB-perp-2!C'+edb_stat+'!C'+range+'!Cergs/cm!e2!ns',$
             data={x:etimes,y:eperp1xbperp2},dlim={constant:[0]}

  S_p1 = (-E_perp_2*B_para)/(mu*1e9)
  S_p2 =  (E_perp_1*B_para)/(mu*1e9)

  store_data,'S-'+perp_1+'!C'+edb_stat+'!C'+range+'!Cergs/cm!e2!ns',data={x:etimes,y:S_p1},$
             dlim={constant:[0],colors:[0],labels:[perp_1]}
  store_data,'S-'+perp_2+'!C'+edb_stat+'!C'+range+'!Cergs/cm!e2!ns',data={x:etimes,y:S_p2},$
             dlim={constant:[0],colors:[0],labels:[perp_2]}


  S_perp1_perp2_para = eperp2xbperp1 + eperp1xbperp2
  store_data,'S!i||!n(in-situ)!CdEperp2XdBperp1-dEperp1XdBperp2!C'+edb_stat+'!C'+range+'!Cergs/cm!e2!ns',$
             data={x:etimes,y:S_perp1_perp2_para},dlim={constant:[0]}

  title='FAC Perp1 is in the B cross X R direction (azimuthal) and!CPerp2 is in the perp1 cross B direction (radial)'



  ;---------------------------------------------------------------------
  ;find ExB drift velocities with 5 min averaged E and B field

  if not keyword_set(burst) then begin

     smoo = round(5.*60./cadence)

     Ex_smooth = smooth(Ex,smoo,/nan)
     Ey_smooth = smooth(Ey,smoo,/nan)
     Ez_smooth = smooth(Ez,smoo,/nan)
     Bx_bkgrd = smooth(Bx,smoo,/nan)
     By_bkgrd = smooth(By,smoo,/nan)
     Bz_bkgrd = smooth(Bz,smoo,/nan)

     B_field_mag = SQRT(Bx_bkgrd^2 + By_bkgrd^2 + Bz_bkgrd^2)

     vx = 1000.*(Ey_smooth*Bz_bkgrd - Ez_smooth*By_bkgrd)/B_field_mag^2
     vy = 1000.*(Ez_smooth*Bx_bkgrd - Ex_smooth*Bz_bkgrd)/B_field_mag^2
     vz = 1000.*(Ex_smooth*By_bkgrd - Ey_smooth*Bx_bkgrd)/B_field_mag^2

     store_data,'Vx!CExB-drift!C5min-ave!Ckm/s',data={x:etimes,y:vx}
     store_data,'Vy!CExB-drift!C5min-ave!C'+edb_stat+'!Ckm/s',data={x:etimes,y:vy}
     store_data,'Vz!CExB-drift!Csmin-ave!C'+edb_stat+'!Ckm/s',data={x:etimes,y:vz}
     options,['*'],constant=0

  endif


  ;; tplot,['rbspb-Bx-mgse!Cmodel-sub!C-!CnT',$
  ;;        'rbspb-By-mgse!Cmodel-sub!C-!CnT'   ,$
  ;;        'rbspb-Bz-mgse!Cmodel-sub!C-!CnT' ,$
  ;;        'rbspb-Ey-mgse!C-!CmV/m',$
  ;;        'rbspb-Ez-mgse!C-!CmV/m']

end
