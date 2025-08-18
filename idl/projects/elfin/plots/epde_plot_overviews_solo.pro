;+
;
;PROCEDURE:
;  epde_plot_overviews_solo
;
;PURPOSE:
; Loads EPDE, performs pitch angle determination and plotting of energy and pitch angle spectra
; Including precipitating and trapped spectra separately. EPDI can be treated similarly, but not done yet
; Regularize keyword performs rebinning of data on regular sector centers starting at zero (rel.to the time
; of dBzdt 0 crossing which corresponds to Pitch Angle = 90 deg and Spin Phase angle = 0 deg.).
; If the data has already been collected at regular sectors there is no need to perform this.
;
;KEYWORDS:
; trange - time range of interest [starttime, endtime] with the format
;          ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;          ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
; probe - 'a' or 'b'
; no_download - set this flag to not download data from the server and use local files only
; sci_zone - if set this flag will plot epd overview plots by science zone (rather than by day)
;            not yet implemented
; quick_run - set this flag to reduce the resolution of t89/ttrace2equator (from 1 sec to 1 min)
; one_zone_only - set this keyword to only plot the first sci zone (this is a kluge for the pink plots)
; regularize - set this keyword to use the regularize keyword when calling elf_getspec
;
;TO DO:
; implement plots by sci zone only
;
;-
pro epde_plot_overviews_solo, trange=trange, probe=probe, no_download=no_download, $
   quick_run=quick_run, regularize=regularize

  for sciidx=0,1 do begin
  ; initialize parameters
  num=0 ; keeps track of number of science zones in entire time range (a whole day) for appending purposes
  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init

  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
    return
  endif
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr = timerange(trange) $
  else tr = timerange()
  if undefined(probe) then probe = 'a'
  if ~undefined(no_download) then no_download=1 else no_download=0
  t0=systime(/sec)
  if ~keyword_set(one_zone_only) then one_zone_only=0 else one_zone_only=1

  timeduration=(time_double(trange[1])-time_double(trange[0]))
  timespan,tr[0],timeduration,/seconds
  tr=timerange()
  rundate=tr[0]

  elf_init

  ; set up plot options
  loadct,39
  thm_init

  set_plot,'z'
  device,/close
  set_plot,'z'
  device,set_resolution=[775,1000]
  tvlct,r,g,b,/get

  tvlct,r,g,b
  set_plot,'z'
  charsize=1
  tplot_options, 'xmargin', [16,11]
  ;tplot_options, 'ymargin', [7,4]

  ; close and free any logical units opened by calc
  luns=lindgen(124)+5
  for j=0,n_elements(luns)-1 do free_lun, luns[j]

  ; remove any existing pef tplot vars
  del_data, '*_pef_nflux'
  del_data, '*_all'
  elf_load_epd, probes=probe, trange=tr, datatype='pef', level='l1', type='nflux', no_download=no_downlaod
  get_data, 'el'+probe+'_pef_nflux', data=pef_nflux
  elf_load_epd, probes=probe, trange=tr, datatype='pif', level='l1', type='nflux', no_download=no_downlaod
  get_data, 'el'+probe+'_pif_nflux', data=pif_nflux

  if size(pef_nflux,/type) ne 8 then begin
    dprint, 'There is no EPD data for timerange ' +time_string(tr[0]) + ' to '+time_string(tr[1])
    return
  endif
  tr[0]=pef_nflux.x[0]
  tr[1]=pef_nflux.x[n_elements(pef_nflux.x)-1]
  tdur=tr[1]-tr[0]
  timespan, tr[0], tdur/86400.  
  
  if size(pef_nflux, /type) NE 8 then begin
    dprint, dlevel=0, 'No data was downloaded for el' + probe + '_pef_nflux.'
    dprint, dlevel=0, 'No plots were producted.
  endif

  del_data, '*_fgs*'
  elf_load_fgm, probes=probe, trange=tr, datatype='fgs', no_download=no_download
  get_data, 'el'+probe+'_fgs', data=elx_fgs
  copy_data, 'el'+probe+'_fgs_fsp_res_obw', 'el'+probe+'_fgs_fsp_res_obw_orig'

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; GET KP and DST values
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  kp_tr=[tr[0]-10800.,tr[1]+10800.]
  elf_load_kp, trange=[kp_tr]
  get_data, 'elf_kp', data=kp_d, dlimits=kp_dl, limits=kp_l
  store_data, 'elf_kp', data={x:kp_d.x+5400, y:kp_d.y}, dlimits=kp_dl, limits=kp_l
  elf_load_dst,trange=tr

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Get position data
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  elf_load_state, probes=probe, trange=tr, no_download=no_download
  get_data, 'el'+probe+'_pos_gei', data=dat_gei
  cotrans,'el'+probe+'_pos_gei','el'+probe+'_pos_gse',/GEI2GSE
  cotrans,'el'+probe+'_pos_gse','el'+probe+'_pos_gsm',/GSE2GSM
  cotrans,'el'+probe+'_pos_gsm','el'+probe+'_pos_sm',/GSM2SM ; in SM
  cotrans,'el'+probe+'_pos_gei','el'+probe+'_pos_geo',/GEI2GEO
  cotrans,'el'+probe+'_pos_geo','el'+probe+'_pos_mag',/GEO2MAG

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Calculate IGRF
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  threeones=[1,1,1]
  ; quick_run -> do only every 60th point (i.e. per minute)
  if keyword_set(quick_run) then begin
    get_data, 'el'+probe+'_pos_gsm', data=datgsm, dlimits=dl, limits=l
    store_data, 'el'+probe+'_pos_gsm_mins', data={x: datgsm.x[0:*:60], y: datgsm.y[0:*:60,*]}, dlimits=dl, limits=l
    tt89,'el'+probe+'_pos_gsm_mins',/igrf_only,newname='el'+probe+'_bt89_gsm_mins',period=1.
    ; interpolate the minute-by-minute data back to the full array
    get_data,'el'+probe+'_bt89_gsm_mins',data=gsm_mins, dlimits=dl, limits=l
    store_data,'el'+probe+'_bt89_gsm',data={x: datgsm.x, y: interp(gsm_mins.y[*,*], gsm_mins.x, datgsm.x)},dlimits=dl, limits=l
    ; clean up the temporary data
    del_data, '*_mins'
  endif else begin
    tt89,'el'+probe+'_pos_gsm',/igrf_only,newname='el'+probe+'_bt89_gsm',period=1.
  endelse

  get_data, 'el'+probe+'_pos_sm', data=state_pos_sm, dlimits=dl, limits=l
  ; calculate IGRF in nT
  cotrans,'el'+probe+'_bt89_gsm','el'+probe+'_bt89_sm',/GSM2SM ; Bfield in SM coords as well
  xyz_to_polar,'el'+probe+'_pos_sm',/co_latitude
  get_data,'el'+probe+'_pos_sm_th',data=pos_sm_th;,dlim=myposdlim,lim=myposlim
  get_data,'el'+probe+'_pos_sm_phi',data=pos_sm_phi
  csth=cos(!PI*pos_sm_th.y/180.)
  csph=cos(!PI*pos_sm_phi.y/180.)
  snth=sin(!PI*pos_sm_th.y/180.)
  snph=sin(!PI*pos_sm_phi.y/180.)
  rot2rthph=[[[snth*csph],[csth*csph],[-snph]],[[snth*snph],[csth*snph],[csph]],[[csth],[-snth],[0.*csth]]]
  store_data,'rot2rthph',data={x:pos_sm_th.x,y:rot2rthph},dlimits=dl, limits=l ;dlim=myposdlim,lim=myposlim
  tvector_rotate,'rot2rthph','el'+probe+'_bt89_sm',newname='el'+probe+'_bt89_sm_sph'
  rotSMSPH2NED=[[[snth*0.],[snth*0.],[snth*0.-1.]],[[snth*0.-1.],[snth*0.],[snth*0.]],[[snth*0.],[snth*0.+1.],[snth*0.]]]
  store_data,'rotSMSPH2NED',data={x:pos_sm_th.x,y:rotSMSPH2NED},dlimits=dl, limits=l;dlim=myposdlim,lim=myposlim
  tvector_rotate,'rotSMSPH2NED','el'+probe+'_bt89_sm_sph',newname='el'+probe+'_bt89_sm_NED' ; North (-Spherical_theta), East (Spherical_phi), Down (-Spherical_r)
  tvectot,'el'+probe+'_bt89_sm_NED',newname='el'+probe+'_bt89_sm_NEDT'
  get_data, 'el'+probe+'_bt89_sm_NEDT', data=d, dlimits=dl, limits=l
  dl.labels=['N','E','D','T']
  dl.colors=[60,155,254,1]
  store_data, 'el'+probe+'_bt89_sm_NEDT', data=d, dlimits=dl, limits=l
  options,'el'+probe+'_bt89_sm_N*','ytitle', 'IGRF'
  options,'el'+probe+'_bt89_sm_N*','ysubtitle','[nT]'
  options,'el'+probe+'_bt89_sm_NED','labels',['N','E','D']
  options,'el'+probe+'_bt89_sm_NEDT','labels',['N','E','D','T']
  options,'el'+probe+'_bt89_sm_NEDT','colors',[60,155,254,1]
  options,'el'+probe+'_bt89_sm_N*','databar',0.

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Get MLT amd LAT (dipole)
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  elf_mlt_l_lat,'el'+probe+'_pos_sm',MLT0=MLT0,L0=L0,lat0=lat0 ;;subroutine to calculate mlt,l,mlat under dipole configuration
  get_data, 'el'+probe+'_pos_sm', data=elfin_pos
  store_data,'el'+probe+'_MLT_dip',data={x:elfin_pos.x,y:MLT0}
  store_data,'el'+probe+'_L_dip',data={x:elfin_pos.x,y:L0}
  store_data,'el'+probe+'_MLAT_dip',data={x:elfin_pos.x,y:lat0*180./!pi}
  options,'el'+probe+'_MLT_dip',ytitle='dip'
  options,'el'+probe+'_L_dip',ytitle='dip'
  options,'el'+probe+'_MLAT_dip',ytitle='dip'
  options,'el'+probe+'_MLT_dip',charsize=.7
  options,'el'+probe+'_L_dip',charsize=.7
  options,'el'+probe+'_MLAT_dip',charsize=.7
  alt = median(sqrt(elfin_pos.y[*,0]^2 + elfin_pos.y[*,1]^2 + elfin_pos.y[*,2]^2))-6371.

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; GLON
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  GLON=lat0
  get_data, 'el'+probe+'_pos_geo', data=dat_geo
  cart_to_sphere,dat_geo.y[*,0],dat_geo.y[*,1],dat_geo.y[*,2],r_geo,theta_geo,phi_geo
  gidx=where(phi_geo LT 0, ncnt)
  if ncnt GT 0 then phi_geo[gidx]=360.+phi_geo[gidx]
  store_data,'el'+probe+'_GLON',data={x:dat_geo.x,y:phi_geo}
  options,'el'+probe+'_GLON',ytitle='GLON (east)'
  options,'el'+probe+'_GLON', charsize=.7

  re=6378.

  ;;;;;;;;;;;;;;;;;;;;
  ; MLT IGRF
  ;;;;;;;;;;;;;;;;;;;;
  sclet = probe
  ;;trace to equator to get L, MLAT, and MLT in IGRF
  ttrace2equator,'el'+sclet+'_pos_gsm',external_model='none',internal_model='igrf',/km,in_coord='gsm',out_coord='gsm',rlim=100.*Re
  cotrans,'el'+sclet+'_pos_gsm_foot','el'+sclet+'_pos_sm_foot',/GSM2SM
  get_data,'el'+sclet+'_pos_gsm_foot',data=elx_pos_eq
  L1=sqrt(total(elx_pos_eq.y^2.0,2,/nan))/Re
  store_data,'el'+sclet+'_L_igrf',data={x:elx_pos_eq.x,y:L1}
  get_data,'el'+sclet+'_pos_gsm',data=elx_pos
  rnew=sqrt(elx_pos.y[*,0]^2.0+elx_pos.y[*,1]^2.0+(elx_pos.y[*,2]-elx_pos_eq.y[*,2])^2.0)
  lat3=asin((elx_pos.y[*,2]-elx_pos_eq.y[*,2])/rnew)/!dtor
  store_data,'el'+sclet+'_MLAT_igrf',data={x:elx_pos_eq.x,y:lat3};;did not pass the validation
  elf_mlt_l_lat,'el'+sclet+'_pos_sm_foot',MLT0=MLT0,L0=L0,lat0=lat0
  store_data,'el'+sclet+'_MLT_igrf',data={x:elx_pos_eq.x,y:MLT0}

  options,'el'+probe+'_L_igrf',ytitle='L-igrf'
  options,'el'+probe+'_L_igrf',charsize=.7
  options,'el'+probe+'_MLAT_igrf',ytitle='MLAT-igrf'
  options,'el'+probe+'_MLAT_igrf',charsize=.7
  options,'el'+probe+'_MLT_igrf',ytitle='MLT-igrf'
  options,'el'+probe+'_MLT_igrf',charsize=.7

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Get proxy_ae data
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  del_data, 'proxy_ae'
  tr=timerange()
  elf_load_proxy_ae, trange=[tr[0]-5400,tr[1]+5400.], /smooth, no_download=no_download
  get_data, 'proxy_ae', data=proxy_ae, dlimits=dl, limits=l
  if size(proxy_ae,/type) NE 8 then begin
    elf_load_proxy_ae, trange=['2019-12-05','2019-12-06']
    get_data, 'proxy_ae', data=proxy_ae, dlimits=ae_dl, limits=ae_l
  endif
  
  if ~undefined(proxy_ae) && size(proxy_ae, /type) EQ 8 then begin
    proxy_ae.y = median(proxy_ae.y, 10.)
    store_data, 'proxy_ae', data=proxy_ae, dlimits=ae_dl, limits=ae_l
    options, 'proxy_ae', ysubtitle='[nT]'
    options, 'proxy_ae', yrange=[0,150]
  endif else begin
    print, 'No data available for proxy_ae'
    options, 'proxy_ae', ztitle=''
  endelse

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; ... shadow/sunlight bar 0 (shadow) or 1 (sunlight)
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  elf_load_sun_shadow_bar, tplotname='el'+probe+'_pos_gse', no_download=no_download
  options,'shadow_bar',thick=5.5,xstyle=4,ystyle=4,yrange=[-0.1,0.1],ytitle='',$
    ticklen=0,panel_size=0.1, charsize=2., ztitle=''
  options,'sun_bar',thick=5.5,xstyle=4,ystyle=4,yrange=[-0.1,0.1],ytitle='',$
    ticklen=0,panel_size=0.1,colors=195, charsize=2., ztitle=''

  ; create one bar for both sun and shadow
  store_data, 'sunlight_bar', data=['sun_bar','shadow_bar']
  options, 'sunlight_bar', panel_size=0.1
  options, 'sunlight_bar',ticklen=0
  options, 'sunlight_bar', 'ystyle',4
  options, 'sunlight_bar', 'xstyle',4
  options, 'sunlight_bar', 'ztitle',''
  options, 'sunlight_bar', yrange=[-0.1,0.1]

  ;;;;;;;;;;;;;;;;;;;;;;;;;
  ; EPD status bars
  ;;;;;;;;;;;;;;;;;;;;;;;;;
  ;get eletron data first
  del_data, 'epde_fast_bar'
  elf_load_epd_fast_segments, tplotname='el'+probe+'_pef_nflux', no_download=no_download
  get_data, 'epde_fast_bar', data=epdef_fast_bar_x
  options, 'epde_fast_bar', panel_size=0.1
  options, 'epde_fast_bar',ticklen=0
  options, 'epde_fast_bar', 'ystyle',4
  options, 'epde_fast_bar', 'xstyle',4
  options, 'epde_fast_bar', 'color',254
  options, 'epde_fast_bar', 'ztitle',''

  ;get ion data next
  del_data, 'epdi_fast_bar'
  elf_load_epd_fast_segments, tplotname='el'+probe+'_pif_nflux', no_download=no_download
  get_data, 'epdi_fast_bar', data=epdif_fast_bar_x
  options, 'epdi_fast_bar', panel_size=0.1
  options, 'epdi_fast_bar',ticklen=0
  options, 'epdi_fast_bar', 'ystyle',4
  options, 'epdi_fast_bar', 'xstyle',4
  options, 'epdi_fast_bar', 'color',140
  options, 'epdi_fast_bar', 'ztitle',''

  ;;;;;;;;;;;;;;;;;;;;;;;;;
  ; FGM status bar
  ;;;;;;;;;;;;;;;;;;;;;;;;;
  del_data, 'fgm_survey_bar'
  elf_load_fgm_survey_segments, tplotname='el'+probe+'_fgs', no_download=no_download
  get_data, 'fgm_survey_bar', data=fgm_survey_bar_x

  options, 'fgm_survey_bar', panel_size=0.1
  options, 'fgm_survey_bar',ticklen=0
  options, 'fgm_survey_bar', 'ystyle',4
  options, 'fgm_survey_bar', 'xstyle',4
  options, 'fgm_survey_bar', 'color',80
  options, 'fgm_survey_bar', 'ztitle',''

  ; set up science zone plot options
  tplot_options, 'xmargin', [16,11]
  tplot_options, 'ymargin', [4,3]

    ; get EPD data
    elf_load_epd, trange=tr, probes=probe, datatype='pef', level='l1', type='nflux',no_download=no_download
    sc='el'+probe
    get_data, sc+'_pef_nflux', data=pef
    get_data, sc+'_pef_nsectors', data= nsect

    ; get sector and phase delay for this zone
    phase_delay = elf_find_phase_delay(trange=tr, probe=probe, instrument='epde', no_download=no_download)
    if finite(phase_delay.dsect2add[0]) then dsect2add=fix(phase_delay.dsect2add[0]) $
    else dsect2add=phase_delay.dsect2add[0]
    dphang2add=float(phase_delay.dphang2add[0])
    badflag=fix(phase_delay.badflag)
    if dphang2add LT 0 then dphang_string=strmid(strtrim(string(dphang2add),1),0,5) else $
      dphang_string=strmid(strtrim(string(dphang2add),1),0,4)
    if undefined(badflag) then badflag=2
    if badflag NE 0 then badflag_str=', BadFlag set' else badflag_str=''
    case badflag of
      0: phase_msg = 'Phase delay values dSect2add='+strtrim(string(dsect2add),1) + ' and dPhAng2add=' + dphang_string + ', Good Fit' 
      1: phase_msg = 'Median Phase delay values dSect2add='+strtrim(string(dsect2add),1) + ' and dPhAng2add=' + dphang_string + ', Bad Fit'
      2: phase_msg = 'Median Phase delay values dSect2add='+strtrim(string(dsect2add),1) + ' and dPhAng2add=' + dphang_string + ', No Fit' 
      else: phase_msg = 'Median Phase delay values dSect2add='+strtrim(string(dsect2add),1) + ' and dPhAng2add=' + dphang_string + ', Bad Fit'
    endcase

    spin_str=''
    if spd_data_exists('el'+probe+'_pef_nflux',tr[0],tr[1]) then begin
      get_data, 'el'+probe+'_pef_nspinsinsum', data=my_nspinsinsum
      if keyword_set(regularize) then begin
        batch_procedure_error_handler, 'elf_getspec', /regularize, probe=probe, dSect2add=dsect2add, dSpinPh2add=dphang2add, nspinsinsum=my_nspinsinsum.y, no_download=no_download
        if not spd_data_exists('el'+probe+'_pef_pa_reg_spec2plot_ch0',tr[0],tr[1]) then begin
          elf_getspec, probe=probe, nspinsinsum=my_nspinsinsum.y
        endif
        copy_data, 'el'+probe+'_pef_en_reg_spec2plot_omni', 'el'+probe+'_pef_en_spec2plot_omni'
        copy_data, 'el'+probe+'_pef_en_reg_spec2plot_anti', 'el'+probe+'_pef_en_spec2plot_anti'
        copy_data, 'el'+probe+'_pef_en_reg_spec2plot_perp', 'el'+probe+'_pef_en_spec2plot_perp'
        copy_data, 'el'+probe+'_pef_en_reg_spec2plot_para', 'el'+probe+'_pef_en_spec2plot_para'
        copy_data, 'el'+probe+'_pef_pa_reg_spec2plot_ch0', 'el'+probe+'_pef_pa_spec2plot_ch0'
        copy_data, 'el'+probe+'_pef_pa_reg_spec2plot_ch1', 'el'+probe+'_pef_pa_spec2plot_ch1'
        copy_data, 'el'+probe+'_pef_pa_reg_spec2plot_ch2', 'el'+probe+'_pef_pa_spec2plot_ch2'
        copy_data, 'el'+probe+'_pef_pa_reg_spec2plot_ch3', 'el'+probe+'_pef_pa_spec2plot_ch3'
        del_data, '*_pef_en_reg_spec2plot_*'
        del_data, '*_pef_pa_reg_spec2plot_*'
      endif else begin
        batch_procedure_error_handler, 'elf_getspec', probe=probe, dSect2add=dsect2add, dSpinPh2add=dphang2add, nspinsinsum=my_nspinsinsum.y, no_download=no_download
        if not spd_data_exists('el'+probe+'_pef_pa_spec2plot_ch0',tr[0],tr[1]) then begin
          elf_getspec, probe=probe, nspinsinsum=my_nspinsinsum.y
        endif
      endelse

      ; find spin period
      get_data, 'el'+probe+'_pef_spinper', data=spin
      spin_med=median(spin.y)
      spin_var=variance(spin.y)/spin_med*100.
      get_data, 'el'+probe+'_pef_nsectors', data=nsectors
      nsect_med=fix(median(nsectors.y))
      nsect_str=', nsectors='+ strtrim(nsect_med, 1)
      get_data, 'el'+probe+'_pef_nspinsinsum', data=spinsum
      spinsum_med=fix(median(spinsum.y))
      spinsum_str=', nspinsinsum='+ strtrim(spinsum_med, 1)
      spin_str='Median Spin Period T: '+strmid(strtrim(string(spin_med), 1),0,4) + 's, sig=' +$
        strmid(strtrim(string(spin_var), 1),0,4)+'% T'+nsect_str+spinsum_str
    endif

    ; handle scaling of y axis
    if size(proxy_ae, /type) EQ 8 then begin
      ae_idx = where(proxy_ae.x GE tr[0] and proxy_ae.x LT tr[1], ncnt)
      if ncnt GT 0 then ae_max=minmax(proxy_ae.y[ae_idx])
      if ncnt EQ 0 then ae_max=[0,140.]
      if ae_max[1] LT 145. then options, 'proxy_ae', yrange=[0,150] $
      else options, 'proxy_ae', yrange=[0,ae_max[1]+ae_max[1]*.1]
      if ae_max[1] LT 145. then options, 'proxy_ae', yrange=[0,150] $
      else options, 'proxy_ae', yrange=[0,ae_max[1]+ae_max[1]*.1]
    endif else begin
      options, 'proxy_ae', yrange=[0,150]
    endelse

    ; Figure out which hourly label to assign
    ; Figure out which science zone
    get_data,'el'+probe+'_MLAT_dip',data=this_lat
    lat_idx=where(this_lat.x GE tr[0] AND this_lat.x LE tr[1], ncnt)
    if ncnt GT 0 then begin ;change to num_scz?
      sz_tstart=time_string(tr[0])
      sz_lat=this_lat.y[lat_idx]
      median_lat=median(sz_lat)
      dlat = sz_lat[1:n_elements(sz_lat)-1] - sz_lat[0:n_elements(sz_lat)-2]
      if median_lat GT 0 then begin
        if median(dlat) GT 0 then sz_plot_lbl = ', North Ascending' else $
          sz_plot_lbl = ', North Descending'
        if median(dlat) GT 0 then sz_name = '_nasc' else $
          sz_name = '_ndes'
      endif else begin
        if median(dlat) GT 0 then sz_plot_lbl = ', South Ascending' else $
          sz_plot_lbl = ', South Descending'
        if median(dlat) GT 0 then sz_name = '_sasc' else $
          sz_name =  '_sdes'
      endelse
    endif

    ;;;;;;;;;;;;;;;;;;;;;;
    ; PLOT
    ;if tdur Lt 194. then version=6 else version=7
    tplot_options, version=6
    tplot_options, 'ygap',0
    tplot_options, 'no_vtitle_shift', 1
    elf_set_overview_options, probe=probe, trange=tr,/no_switch
    options, 'el'+probe+'_MLAT_igrf', 'format', '(1F5.1)'
    options, 'el'+probe+'_MLT_igrf', 'format', '(1F4.1)'
    options, 'el'+probe+'_L_igrf', 'format', '(1F4.1)'
    options, 'el'+probe+'_MLAT_dip', 'format', '(1F5.1)'
    options, 'el'+probe+'_MLT_dip', 'format', '(1F4.1)'
    options, 'el'+probe+'_L_dip', 'format', '(1F4.1)'

    if strlowcase(probe) eq 'a' then  $
      varstring=['ela_GLON','ela_MLAT_igrf[ela_MLAT_dip]', 'ela_MLT_igrf[ela_MLT_dip]', 'ela_L_igrf[ela_L_dip]'] else $
      varstring=['elb_GLON','elb_MLAT_igrf[elb_MLAT_dip]', 'elb_MLT_igrf[elb_MLT_dip]', 'elb_L_igrf[elb_L_dip]']

    if spd_data_exists('el'+probe+'_fgs_fsp_res_obw_orig',tr[0],tr[1]) then begin
      copy_data, 'el'+probe+'_fgs_fsp_res_obw_orig', 'el'+probe+'_fgs_fsp_res_obw'
      get_data, 'el'+probe+'_fgs_fsp_res_obw', data=fsp_obw
      idx=where(fsp_obw.x GE tr[0] and fsp_obw.x LE tr[1], ncnt)
      if ncnt GT 0 then begin
        yrng=minmax(fsp_obw.y[idx,*])
        if abs(yrng[0]) LT 100. AND abs(yrng[1]) LT 100. then begin
          ;idx=where(abs(fsp_obw.y[idx,*]) LT 100, tcnt)
          ;if tcnt GT 0 then begin
          ylim, 'el'+probe+'_fgs_fsp_res_obw', -100,100.
        endif
      endif
      options,  'el'+probe+'_fgs_fsp_res_obw', ysubtitle='[nT]'
      tplot,['proxy_ae', $
        'fgm_survey_bar', $
        'epdi_fast_bar', $
        'epde_fast_bar', $
        'sunlight_bar', $
        'el'+probe+'_pef_en_spec2plot_omni', $
        'el'+probe+'_pef_en_spec2plot_anti', $
        'el'+probe+'_pef_en_spec2plot_perp', $
        'el'+probe+'_pef_en_spec2plot_para', $
        'el'+probe+'_pef_pa_spec2plot_ch[0,1]LC', $
        'el'+probe+'_pef_pa_spec2plot_ch[2,3]LC', $
        'el'+probe+'_fgs_fsp_res_obw'], $
        var_label=varstring     ;'el'+probe+'_'+['LAT','MLT','L_dip','MLT_igrf','L_igrf']
    endif else begin
      tplot,['proxy_ae', $
        'fgm_survey_bar', $
        'epdi_fast_bar', $
        'epde_fast_bar', $
        'sunlight_bar', $
        'el'+probe+'_pef_en_spec2plot_omni', $
        'el'+probe+'_pef_en_spec2plot_anti', $
        'el'+probe+'_pef_en_spec2plot_perp', $
        'el'+probe+'_pef_en_spec2plot_para', $
        'el'+probe+'_pef_pa_spec2plot_ch[0,1]LC', $
        'el'+probe+'_pef_pa_spec2plot_ch[2,3]LC', $
        'el'+probe+'_bt89_sm_NEDT'], $
        var_label=varstring
    endelse
    tr=timerange()
    fd=file_dailynames(trange=tr[0], /unique, times=times)
    tstring=strmid(fd,0,4)+'-'+strmid(fd,4,2)+'-'+strmid(fd,6,2)+sz_plot_lbl
    title='PRELIMINARY ELFIN-'+strupcase(probe)+' EPDE, alt='+strmid(strtrim(alt,1),0,3)+'km, '+tstring

    xyouts, .175, .975, title, /normal, charsize=1.1
    tplot_apply_databar

    ; add time of creation
    xyouts, .76, .012, 'nflux: #/(cm^2 s sr MeV)',/normaL,color=1, charsize=.75
    xyouts,  .76, .001, 'Created: '+systime(/UTC),/normal,color=1, charsize=.75
    ; add phase delay message

    if spd_data_exists('el'+probe+'_pef_nflux',tr[0],tr[1]) then begin
      xyouts, .0085, .012, spin_str, /normal, charsize=.75
      xyouts, .0085, .001, phase_msg, /normal, charsize=.75
    endif

    ; save for later
    get_data, 'el'+probe+'_pef_en_spec2plot_omni', data=omni_d, dlimits=omni_dl, limits=omni_l
    get_data, 'el'+probe+'_pef_en_spec2plot_anti', data=anti_d, dlimits=anti_dl, limits=anti_l
    get_data, 'el'+probe+'_pef_en_spec2plot_perp', data=perp_d, dlimits=perp_dl, limits=perp_l
    get_data, 'el'+probe+'_pef_en_spec2plot_para', data=para_d, dlimits=para_dl, limits=para_l
    get_data, 'el'+probe+'_pef_pa_spec2plot_ch0LC', data=ch0_d, dlimits=ch0_dl, limits=ch0_l
    get_data, 'el'+probe+'_pef_pa_spec2plot_ch1LC', data=ch1_d, dlimits=ch1_dl, limits=ch1_l
    get_data, 'el'+probe+'_pef_pa_spec2plot_ch2LC', data=ch2_d, dlimits=ch2_dl, limits=ch2_l
    get_data, 'el'+probe+'_pef_pa_spec2plot_ch3LC', data=ch3_d, dlimits=ch3_dl, limits=ch3_l

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Create GIF file
    tr=timerange()
    fd=file_dailynames(trange=tr[0], /unique, times=times)
    ; Create small plot
    image=tvrd()
    device,/close
    set_plot,'z'
    image[where(image eq 255)]=1
    image[where(image eq 0)]=255
    gif_path = !elf.local_data_dir+'el'+probe+'/overplots/'+strmid(fd,0,4)+'/'+strmid(fd,4,2)+'/'+strmid(fd,6,2)+'/'
    file_mkdir, gif_path

    ; Figure out which sci zone numbers need to be created
      gif_file = gif_path+'el'+probe+'_l2_overview_'+fd+sz_name
      dprint, 'Making gif file '+gif_file+'.gif'
      write_gif, gif_file+'.gif',image,r,g,b
      print, 'Sci Zone plot time: '+strtrim(systime(/sec)-t0,2)+' sec'

  del_data, 'epdi_fast_bar'
  del_data, 'epde_fast_bar'
  dprint, dlevel=2, 'Total time: '+strtrim(systime(/sec)-t0,2)+' sec'
 endfor
 
end
