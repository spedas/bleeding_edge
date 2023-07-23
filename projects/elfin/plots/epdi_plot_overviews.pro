;+
;
;PROCEDURE:
;  epdi_plot_overviews
;
;PURPOSE:
; Loads EPDE and EPDI performs pitch angle determination and plotting of energy and pitch angle spectra
; Including precipitating and trapped spectra separately. 
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
;
;TO DO:
; elb can be done similarly but the code has not been generalized to either a or b yet. But this is straightforward.
;
;-
pro epdi_plot_overviews, trange=trange, probe=probe, no_download=no_download, $
  sci_zone=sci_zone, quick_run=quick_run, one_zone_only=one_zone_only

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
  errmax4specs=1.0

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

  ; close and free any logical units opened by calc
  luns=lindgen(124)+5
  for j=0,n_elements(luns)-1 do free_lun, luns[j]

  ; remove any existing pef tplot vars
  del_data, '*_pef_*'
  del_data, '*_pif_*'
  del_data, '*_all*'
  elf_load_epd, probes=probe, trange=tr, datatype='pef', level='l1', type='nflux', no_download=no_downlaod

  get_data, 'el'+probe+'_pef_nflux', data=pef_nflux
  elf_load_epd, probes=probe, trange=tr, datatype='pif', level='l1', type='nflux', no_download=no_downlaod
  get_data, 'el'+probe+'_pif_nflux', data=pif_nflux

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
  elf_load_state, probes=probe, no_download=no_download
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
  sclet=probe
  pival=!PI
  Rem=6371.0 ; Earth mean radius in km
  cotrans,'el'+sclet+'_pos_gei','elx_pos_gse',/GEI2GSE
  cotrans,'elx_pos_gse','elx_pos_gsm',/GSE2GSM
  get_data, 'elx_pos_gsm',data=datgsm, dlimits=datgsmdl, limits=datgsml
  store_data, 'elx_pos_gsm_mins', data={x: datgsm.x[0:*:60], y: datgsm.y[0:*:60,*]}, dlimits=datgsmdl, limits=datgsml
  tt89,'elx_pos_gsm_mins',/igrf_only,newname='elx_bigrf_gsm_mins',period=0.1; gets IGRF field at ELF location
  ; find igrf coordinates for satellite, same as for footpoint: Ligrf, MLATigrf, MLTigrf
  ttrace2equator,'elx_pos_gsm_mins',external_model='none',internal_model='igrf',/km,in_coord='gsm',out_coord='gsm',rlim=100.*Rem ; native is gsm
  cotrans,'elx_pos_gsm_mins_foot','elx_pos_sm_mins_foot',/GSM2SM ; now in SM
  get_data,'elx_pos_sm_mins_foot',data=elx_pos_sm_foot
  xyz_to_polar,'elx_pos_sm_mins_foot',/co_latitude ; get position in rthphi (polar) coords
  calc," 'Ligrf'=('elx_pos_sm_mins_foot_mag'/Rem)/(sin('elx_pos_sm_mins_foot_th'*pival/180.))^2 " ; uses 1Rem (mean E-radius, the units of L) NOT 1Rem+100km!
  tdotp,'elx_bigrf_gsm_mins','elx_pos_gsm_mins',newname='elx_br_tmp'
  get_data,'elx_br_tmp',data=Br_tmp
  hemisphere=sign(-Br_tmp.y)
  r_ift_dip = (1.+100./Rem)
  calc," 'MLAT' = (180./pival)*arccos(sqrt(Rem*r_ift_dip/'elx_pos_sm_mins_foot_mag')*sin('elx_pos_sm_mins_foot_th'*pival/180.))*hemisphere " ; at footpoint
  ; interpolate the minute-by-minute data back to the full array
  get_data,'MLAT',data=MLAT_mins  
  store_data,'el'+probe+'_MLAT_igrf',data={x: datgsm.x, y: interp(MLAT_mins.y, MLAT_mins.x, datgsm.x)}

  get_data,'elx_pos_gsm_mins_foot',data=elx_pos_eq
  L1=sqrt(total(elx_pos_eq.y^2.0,2,/nan))/Re
  store_data,'el'+probe+'_L_igrf',data={x: datgsm.x, y: interp(L1, elx_pos_eq.x, datgsm.x)}
  elf_mlt_l_lat,'elx_pos_sm_mins_foot',MLT0=MLT0,L0=L0,lat0=lat0
  get_data, 'elx_pos_sm_mins_foot', data=sm_mins
  store_data,'el'+probe+'_MLT_igrf',data={x: datgsm.x, y: interp(MLT0, sm_mins.x, datgsm.x)}
  del_data, '*_mins'

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
  elf_load_proxy_ae, trange=[tr[0],tr[1]+5400.], /smooth, no_download=no_download
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

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Prep FOR ORBITS
  ; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; setup for orbits by the hour
  ; 1 plot at start of each hour (for 1.5 hours) and 1 24 hour plot

  hr_arr = indgen(25)   ;[0, 6*indgen(4), 2*indgen(12)]
  hr_ststr = string(hr_arr, format='(i2.2)')
  ; Strings for labels, filenames
  ; Use smaller array if they are not the same

  for m=0,23 do begin
    this_s = tr[0] + m*3600.
    this_e = this_s + 90.*60. + 1
    idx = where(dat_gei.x GE this_s AND dat_gei.x LT this_e, ncnt)
    if ncnt GT 10 then begin
      append_array, min_st, idx[0]
      append_array, min_en, idx[n_elements(idx)-1]
      if m NE 23 then this_lbl = ' ' + hr_ststr[m] + ':00 to ' + hr_ststr[m+1] + ':30' else $
        this_lbl = ' ' + hr_ststr[m] + ':00 to ' + hr_ststr[m+1] + ':00'
      append_array, plot_lbl, this_lbl
      this_file = '_'+hr_ststr[m]
      append_array, file_lbl, this_file
    endif
  endfor

  ; append info for 24 hour plot
  append_array, min_st, 0
  append_array, min_en, n_elements(dat_gei.x)-1
  append_array, plot_lbl, ' 00:00 to 24:00'
  append_array, file_lbl, '_24hr'
  st_hr = dat_gei.x[min_st]
  en_hr = dat_gei.x[min_en]
  nplots = n_elements(min_st) ;number of starting hours (NOT number of sci zones)

  ; set up for plots by science zone
  if (size(pif_nflux, /type)) EQ 8 then begin
    tdiff = pif_nflux.x[1:n_elements(pif_nflux.x)-1] - pif_nflux.x[0:n_elements(pif_nflux.x)-2]
    idx = where(tdiff GT 270., ncnt)
    append_array, idx, n_elements(pif_nflux.x)-1 ;add on last element (end time of last sci zone) to pick up last sci zone
    if ncnt EQ 0 then begin
      ; if ncnt is zero then there is only one science zone for this time frame
      sz_starttimes=[pif_nflux.x[0]]
      sz_endtimes=pif_nflux.x[n_elements(pif_nflux.x)-1]
      ts=time_struct(sz_starttimes[0])
      te=time_struct(sz_endtimes[0])
    endif else begin
      for sz=0,ncnt do begin ;changed from ncnt-1
        if sz EQ 0 then begin
          this_s = pif_nflux.x[0]
          sidx = 0
          this_e = pif_nflux.x[idx[sz]]
          eidx = idx[sz]
        endif else begin
          this_s = pif_nflux.x[idx[sz-1]+1]
          sidx = idx[sz-1]+1
          this_e = pif_nflux.x[idx[sz]]
          eidx = idx[sz]
        endelse
        if (this_e-this_s) lt 15. then continue
        append_array, sz_starttimes, this_s
        append_array, sz_endtimes, this_e
      endfor
    endelse
  endif

  epdi_sci_zones=get_elf_science_zone_start_end(trange=trange, probe=probe, instrument='epdi')
  fgm_sci_zones=get_elf_science_zone_start_end(trange=trange, probe=probe, instrument='fgm')
  ;  if size(epd_times, /type) EQ 8 then begin
  ;     sz_starttimes=epd_times.starts
  ;     sz_endtimes=epd_times.ends
  ;  endif
  ; also get the data availability time ranges - this is needed later for science zone percent completion
  ;epd_sci_zones=get_elf_science_zone_start_end(trange=[trange[0]-5,trange[1]+5], probe=probe, instrument='epd')
  ;fgm_sci_zones=get_elf_science_zone_start_end(trange=[trange[0]-5,trange[1]+5], probe=probe, instrument='fgm')

  num_szs=n_elements(sz_starttimes)

  ; set up science zone plot options
  tplot_options, 'xmargin', [16,11]
  tplot_options, 'ymargin', [4,3]

  bird=probe
  num=0
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; MAIN LOOP for PLOTs
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  for i=0,num_szs-1 do begin ;changed from 0,nplots-1

    sz_tr=[sz_starttimes[i],sz_endtimes[i]]   ; add 3 seconds to ensure that full spin periods are loaded
    tdur=sz_tr[1]-sz_tr[0]
    timespan, sz_tr[0], tdur, /sec
    this_tr=timerange()

;    med_nsect=median(nsect.y)
    if size(epdi_sci_zones,/type) eq 8 then begin
      idx=where(epdi_sci_zones.starts GT sz_tr[0]-20, scnt)
      if scnt GT 0 then epdi_completeness_str=', EPDI completeness='+epdi_sci_zones.completeness[idx[0]] else $
        epdi_completeness_str=', EPDI Completeness=not available'
    endif else begin
      epdi_completeness_str=', EPDI Completeness=not available'
    endelse
    if size(fgm_sci_zones,/type) eq 8 then begin
      idx=where((fgm_sci_zones.starts GT sz_tr[0]-60), scnt)
      if scnt GT 0 then fgm_completeness_str=', FGM completeness='+fgm_sci_zones.completeness[idx[0]] else $
        fgm_completeness_str=', FGM Completeness=not available'
    endif else begin
      fgm_completeness_str=', FGM Completeness=None'
    endelse

    ; get sector and phase delay for this zone
    phase_delay = elf_find_phase_delay(trange=sz_tr, probe=probe, instrument='epde', no_download=no_download)
    if finite(phase_delay.dsect2add[0]) then dsect2add=fix(phase_delay.dsect2add[0]) $
    else dsect2add=phase_delay.dsect2add[0]
    dphang2add=float(phase_delay.dphang2add[0])
    badflag=fix(phase_delay.badflag)
    if dphang2add LT 0 then dphang_string=strmid(strtrim(string(dphang2add),1),0,5) else $
      dphang_string=strmid(strtrim(string(dphang2add),1),0,4)
    if undefined(badflag) then badflag=2
    if badflag NE 0 then badflag_str=', BadFlag set' else badflag_str=''
    case badflag of
      0: phase_msg = 'Phase delay values dSect2add='+strtrim(string(dsect2add),1) + ' and dPhAng2add=' + dphang_string + ', Good Fit' + epdi_completeness_str 
      1: phase_msg = 'Median Phase delay values dSect2add='+strtrim(string(dsect2add),1) + ' and dPhAng2add=' + dphang_string + ', Bad Fit' + epdi_completeness_str
      2: phase_msg = 'Median Phase delay values dSect2add='+strtrim(string(dsect2add),1) + ' and dPhAng2add=' + dphang_string + ', No Fit' + epdi_completeness_str 
      else: phase_msg = 'Median Phase delay values dSect2add='+strtrim(string(dsect2add),1) + ' and dPhAng2add=' + dphang_string + ', Bad Fit' + epdi_completeness_str
    endcase

    foreach myspecies, ['e','i'] do begin

      elf_load_epd, probes=bird, datatype='p'+myspecies+'f', type='raw' ; DEFAULT UNITS ARE NFLUX
      get_data, 'el'+bird+'_p'+myspecies+'f_raw', data=tdata
      if size(tdata, /type) NE 8 then continue
;      elf_getspec,probe=bird,species=myspecies,type = 'raw'; default is [[0,2],[3,5],[6,8],[9,15]] == [[50,160],[160,345],[345,900],[>900]]
      elf_getspec,probe=bird,species=myspecies,type = 'raw',dSect2add=dsect2add, dSpinPh2add=dphang2add; default is [[0,2],[3,5],[6,8],[9,15]] == [[50,160],[160,345],[345,900],[>900]]
      get_data,'el'+bird+'_p'+myspecies+'f_losscone',data=elx_pxf_losscone ; in order to determine down need to know hemisphere
      if median(elx_pxf_losscone.y) lt 90. then begin
        hemisphere = 'north'
        dnval='para' ; means down or precipitating ("prec")
        upval='anti' ; means up or backscattered ("back")
      endif else begin
        hemisphere = 'south'
        dnval='anti'
        upval='para'
      endelse
      ; here convert the needed quantities to be used into probe='x' and back/prec rather than para/anti
      copy_data,'el'+bird+'_p'+myspecies+'f_en_spec2plot_'+dnval,'elx_pxf_en_spec2plot_prec' ; prec(ipitating) means down-going
      copy_data,'el'+bird+'_p'+myspecies+'f_en_spec2plot_perp','elx_pxf_en_spec2plot_perp'
      ;compute the errors for params to use below for noise removal
      ; Use these raw counts to produce the df/f error estimate = 1/sqrt(counts) for all quantities you need to. Use calc with globing:
      calc," 'elx_pxf_en_spec2plot_prec_err' = 1/sqrt('elx_pxf_en_spec2plot_prec') " ; <-- what I will use below, err means df/f
      calc," 'elx_pxf_en_spec2plot_perp_err' = 1/sqrt('elx_pxf_en_spec2plot_perp') " ; <-- what I will use below, err means df/f
      calc," 'elx_pxf_en_spec2plot_precovrperp_err' = sqrt('elx_pxf_en_spec2plot_prec_err'^2 + 'elx_pxf_en_spec2plot_perp_err'^2)" ; err also means dratio/ratio
      ;
      ; reload electron data in flux units
      elf_load_epd, probes=bird, datatype='p'+myspecies+'f', type='nflux' ; DEFAULT UNITS ARE NFLUX ANYWAY
;      elf_getspec,probe=bird,species=myspecies,type = 'nflux'; default is [[0,2],[3,5],[6,8],[9,15]] == [[50,160],[160,345],[345,900],[>900]]
      elf_getspec,probe=bird,species=myspecies,type = 'nflux',dSect2add=dsect2add, dSpinPh2add=dphang2add; default is [[0,2],[3,5],[6,8],[9,15]] == [[50,160],[160,345],[345,900],[>900]]
      ;
      ; Now calculate and plot the flux ratios for the prec-over-perp energy spectra
      copy_data,'el'+bird+'_p'+myspecies+'f_en_spec2plot_'+dnval,'elx_pxf_en_spec2plot_prec' ; prec(ipitating) means down-going
      copy_data,'el'+bird+'_p'+myspecies+'f_en_spec2plot_perp','elx_pxf_en_spec2plot_perp'
      copy_data,'el'+bird+'_p'+myspecies+'f_en_spec2plot_omni','elx_pxf_en_spec2plot_omni'
      ;
      calc," 'elx_pxf_en_spec2plot_precovrperp' = 'elx_pxf_en_spec2plot_prec' / 'elx_pxf_en_spec2plot_perp' "
      ;
      quants2clean='elx_pxf_en_spec2plot_'+['precovrperp'] ; can add others here, only need this one, code appends 'gterr' to avoid over-writing

      foreach element, quants2clean do begin

        error2use=element+'_err'
        copy_data,element,'quant2clean'
        copy_data,error2use,'error2use'
        get_data,'quant2clean',data=mydata_quant2clean,dlim=mydlim_quant2clean,lim=mylim_quant2clean
        ntimes=n_elements(mydata_quant2clean.y[*,0])
        nvalues=n_elements(mydata_quant2clean.y[0,*])
        mydata_quant2clean_temp=reform(mydata_quant2clean.y,ntimes*nvalues)
        get_data,'error2use',data=mydata_error2use
        mydata_error2use_temp=reform(mydata_error2use.y,ntimes*nvalues)
        ielim=where(abs(mydata_error2use_temp) gt errmax4specs, jelim) ; this takes care of NaNs and +/-Inf's as well!
        if jelim gt 0 then mydata_quant2clean_temp[ielim] = !VALUES.F_NaN ; make them NaNs, not even zeros
        mydata_quant2clean.y = reform(mydata_quant2clean_temp,ntimes,nvalues) ; back to the original array
        store_data,'quant2clean',data=mydata_quant2clean,dlim=mydlim_quant2clean,lim=mylim_quant2clean
        copy_data,'quant2clean',element+'_gterr' ; doesn't overwrite the previous data in the tplot variable, creates new one!
      endforeach

      copy_data,'elx_pxf_en_spec2plot_precovrperp_gterr','el'+probe+'_p'+myspecies+'f_en_spec2plot_precovrperp_gterr'
      copy_data,'elx_pxf_en_spec2plot_precovrperp','el'+probe+'_p'+myspecies+'f_en_spec2plot_precovrperp'
      copy_data,'elx_pxf_en_spec2plot_perp','el'+probe+'_p'+myspecies+'f_en_spec2plot_perp'
      copy_data,'elx_pxf_en_spec2plot_prec','el'+probe+'_p'+myspecies+'f_en_spec2plot_prec'
      copy_data,'elx_pxf_en_spec2plot_omni','el'+probe+'_p'+myspecies+'f_en_spec2plot_omni'
      zlim,'el'+probe+'_p'+myspecies+'f_en_spec2plot_precovrperp*',0.02,2.,1.
      options,'el'+probe+'_p'+myspecies+'f_en_spec2plot_precovrperp*','ytitle','prec!Covr!Cperp'
      ;
    endforeach

    ; find spin period
    get_data, 'el'+probe+'_pif_spinper', data=spin
    spin_med=median(spin.y)
    spin_var=variance(spin.y)/spin_med*100.
    get_data, 'el'+probe+'_pif_nsectors', data=nsectors
    nsect_med=fix(median(nsectors.y))
    nsect_str=', nsectors='+ strtrim(nsect_med, 1)
    get_data, 'el'+probe+'_pif_nspinsinsum', data=spinsum
    spinsum_med=fix(median(spinsum.y))
    spinsum_str=', nspinsinsum='+ strtrim(spinsum_med, 1)
    spin_str='Median Spin Period T: '+strmid(strtrim(string(spin_med), 1),0,4) + 's, sig=' +$
        strmid(strtrim(string(spin_var), 1),0,4)+'% T'+nsect_str+spinsum_str+fgm_completeness_str

    ; handle scaling of y axis
    if size(proxy_ae, /type) EQ 8 then begin
      ae_idx = where(proxy_ae.x GE sz_tr[0] and proxy_ae.x LT sz_tr[1], ncnt)
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
    lat_idx=where(this_lat.x GE sz_tr[0] AND this_lat.x LE sz_tr[1], ncnt)
    if ncnt GT 0 then begin ;change to num_scz?
      sz_tstart=time_string(sz_tr[0])
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
    if tdur Lt 194. then version=6 else version=7
    tplot_options, version=version   ;6
    tplot_options, 'ygap',0
    tplot_options, 'no_vtitle_shift', 1    
    ;For the ratios:
    zlim,'el?_p?f_en_spec2plot_precovrperp*',0.02,2.,1. ; applies to both I, e
    ;For electrons:
    zlim,'el?_pef_en_spec2plot_omni',2e1,2e7,1
    ;For ions:
    zlim,'el?_pif_en_spec2plot_????',1e2,2e6,1
;    zlim,'el?_pif_pa_spec2plot_ch0*',1.e3,2.e6,1
;    zlim,'el?_pif_pa_spec2plot_ch1*',1.e3,2.e5,1
;    zlim,'el?_pif_pa_spec2plot_ch2*',5e2,2.e4,1
;    zlim,'el?_pif_pa_*spec2plot_ch3*',1e2,1e4,1 ; this is not plotted but just in case
    zlim,'el?_pif_pa_spec2plot_ch0',1.e3,2.e6,1
    zlim,'el?_pif_pa_spec2plot_ch1',1.e3,2.e5,1
    zlim,'el?_pif_pa_spec2plot_ch2',5e2,2.e4,1
    zlim,'el?_pif_pa_*spec2plot_ch3',1e2,1e4,1 ; this is not plotted but just in case
    zlim,'el?_pif_pa_spec2plot_ch0LC',1.e3,2.e6,1
    zlim,'el?_pif_pa_spec2plot_ch1LC',1.e3,2.e5,1
    zlim,'el?_pif_pa_spec2plot_ch2LC',5e2,2.e4,1
    zlim,'el?_pif_pa_*spec2plot_ch3LC',1e2,1e4,1 ; this is not plotted but just in case
    options, 'el?_pif_en_spec2plot_????', 'ztitle','nflux'
    options, 'el?_pef_en_spec2plot_omni', 'ztitle','nflux'
    options, 'el?_pif_pa_spec2plot_ch0LC', 'ztitle','nflux'
    options, 'el?_pif_pa_spec2plot_ch1LC', 'ztitle','nflux'
    options, 'el?_pif_pa_spec2plot_ch2LC', 'ztitle','nflux'
    options, 'el?_p?f_en_spec2plot_precovrperp*', ztitle='ratio'
    vars2plot=['proxy_ae']
    vars2plot=[vars2plot,['fgm_survey_bar']]
    vars2plot=[vars2plot,['epdi_fast_bar']]
    vars2plot=[vars2plot,['epde_fast_bar']]
    vars2plot=[vars2plot,['sunlight_bar']]
    vars2plot=[vars2plot,['el'+probe+'_pef_en_spec2plot_'+['omni','precovrperp_gterr']]] ; electron energy spectra
    vars2plot=[vars2plot,['el'+probe+'_pif_en_spec2plot_'+['omni','prec','precovrperp_gterr']]]; ion energy spectra
    vars2plot=[vars2plot,['el'+bird+'_pif_pa_spec2plot_'+['ch0LC','ch1LC','ch2LC']]]

    if spd_data_exists('el'+probe+'_fgs_fsp_res_obw_orig',sz_tr[0],sz_tr[1]) then begin
      copy_data, 'el'+probe+'_fgs_fsp_res_obw_orig', 'el'+probe+'_fgs_fsp_res_obw'
      get_data, 'el'+probe+'_fgs_fsp_res_obw', data=fsp_obw
      idx=where(fsp_obw.x GE sz_tr[0] and fsp_obw.x LE sz_tr[1], ncnt)
      if ncnt GT 0 then begin
        yrng=minmax(fsp_obw.y[idx,*])
        if abs(yrng[0]) LT 100. AND abs(yrng[1]) LT 100. then begin
          ;idx=where(abs(fsp_obw.y[idx,*]) LT 100, tcnt)
          ;if tcnt GT 0 then begin
          ylim, 'el'+probe+'_fgs_fsp_res_obw', -100,100.
        endif
      endif
;    if spd_data_exists('el'+probe+'_fgs_fsp_res_obw_orig',sz_tr[0],sz_tr[1]) then begin
;      copy_data, 'el'+probe+'_fgs_fsp_res_obw_orig', 'el'+probe+'_fgs_fsp_res_obw'
;      get_data, 'el'+probe+'_fgs_fsp_res_obw', data=fsp_obw
;      idx=where(fsp_obw.x GE sz_tr[0] and fsp_obw.x LE sz_tr[1], ncnt)
;      if ncnt GT 0 then begin
;        idx=where(abs(fsp_obw.y[idx,*]) GE 100, tcnt)
;        if tcnt GT 0 then begin
;          ylim, 'el'+probe+'_fgs_fsp_res_obw', -100,100.
;        endif
;      endif
      options,  'el'+probe+'_fgs_fsp_res_obw', ysubtitle='[nT]'
      vars2plot=[vars2plot,['el'+probe+'_fgs_fsp_res_obw']]          
    endif else begin
       vars2plot=[vars2plot,['el'+probe+'_bt89_sm_NEDT']]   
    endelse
        
    if strlowcase(probe) eq 'a' then  $
      varstring=['ela_GLON','ela_MLAT_igrf[ela_MLAT_dip]', 'ela_MLT_igrf[ela_MLT_dip]', 'ela_L_igrf[ela_L_dip]'] else $
      varstring=['elb_GLON','elb_MLAT_igrf[elb_MLAT_dip]', 'elb_MLT_igrf[elb_MLT_dip]', 'elb_L_igrf[elb_L_dip]']

    tplot,vars2plot,var_label=varstring 
    tplot_apply_databar

    tr=timerange()
    fd=file_dailynames(trange=tr[0], /unique, times=times)
    tstring=strmid(fd,0,4)+'-'+strmid(fd,4,2)+'-'+strmid(fd,6,2)+sz_plot_lbl
    title=''
    title='PRELIMINARY ELFIN-'+strupcase(probe)+' EPDE/EPDI, alt='+strmid(strtrim(alt,1),0,3)+'km, '+tstring

    xyouts, .175, .975, title, /normal, charsize=1.1

    ; add time of creation
    xyouts, .76, .012, 'nflux: #/(cm^2 s sr MeV)',/normaL,color=1, charsize=.75
    xyouts,  .76, .001, 'Created: '+systime(/UTC),/normal,color=1, charsize=.75

    if spd_data_exists('el'+probe+'_pef_nflux',sz_tr[0],sz_tr[1]) then begin
      xyouts, .0085, .012, spin_str, /normal, charsize=.75
      xyouts, .0085, .001, phase_msg, /normal, charsize=.75
    endif

    ; save for later
    get_data, 'el'+probe+'_pef_en_spec2plot_omni', data=omnie_d, dlimits=omnie_dl, limits=omnie_1
    get_data, 'el'+probe+'_pif_en_spec2plot_omni', data=omnii_d, dlimits=omnii_dl, limits=omnii_1
    get_data, 'el'+probe+'_pef_en_spec2plot_precovrperp_gterr', data=erre_d, dlimits=erre_dl, limits=erre_1
    get_data, 'el'+probe+'_pif_en_spec2plot_perp', data=perp_d, dlimits=perp_d, limits=perp_1
    get_data, 'el'+probe+'_pif_en_spec2plot_prec', data=prec_d, dlimits=prec_d, limits=prec_1
    get_data, 'el'+probe+'_pif_en_spec2plot_precovrperp_gterr', data=erri_d, dlimits=erri_dl, limits=erri_l
    get_data, 'el'+probe+'_pif_pa_spec2plot_ch0', data=ch0_d, dlimits=ch0_dl, limits=ch0_l
    get_data, 'el'+probe+'_pif_pa_spec2plot_ch1', data=ch1_d, dlimits=ch1_dl, limits=ch1_l
    get_data, 'el'+probe+'_pif_pa_spec2plot_ch2', data=ch2_d, dlimits=ch2_dl, limits=ch2_l
    get_data, 'el'+probe+'_pif_pa_spec2plot_ch0LC', data=ch0LC_d, dlimits=ch0LC_dl, limits=ch0LC_l
    get_data, 'el'+probe+'_pif_pa_spec2plot_ch1LC', data=ch1LC_d, dlimits=ch1LC_dl, limits=ch1LC_l
    get_data, 'el'+probe+'_pif_pa_spec2plot_ch2LC', data=ch2LC_d, dlimits=ch2LC_dl, limits=ch2LC_l
    get_data, 'el'+probe+'_pif_losscone', data=lc_d, dlimits=lc_dl, limits=lc_l
    get_data, 'el'+probe+'_pif_antilosscone', data=alc_d, dlimits=alc_dl, limits=alc_l

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
    for nhrs=0,23 do begin
      idx=where((sz_tr[0] GE st_hr[nhrs] AND sz_tr[0] LE en_hr[nhrs]) OR $
        (sz_tr[1] GE st_hr[nhrs] AND sz_tr[1] LE en_hr[nhrs]),ncnt)
      if ncnt LE 0 then continue
      sz_file_lbl = file_lbl[i] + '_sasc'
      gif_file = gif_path+'el'+probe+'_l2_ionoverview_'+fd+file_lbl[nhrs]+sz_name
      dprint, 'Making gif file '+gif_file+'.gif'
      write_gif, gif_file+'.gif',image,r,g,b
      print, 'Sci Zone plot time: '+strtrim(systime(/sec)-t0,2)+' sec'
    endfor

    ;*************************;
    ;  ADD TPLOT APPEND HERE
    ;*************************;
    ;Now store as unique tplot variables with diff sz number
    num+=1
    copy_data, 'el'+probe+'_pef_en_spec2plot_omni', 'el'+probe+'_pef_en_spec2plot_omni_sz'+strtrim(string(num),2)
    copy_data, 'el'+probe+'_pif_en_spec2plot_omni', 'el'+probe+'_pif_en_spec2plot_omni_sz'+strtrim(string(num),2)
    copy_data, 'el'+probe+'_pef_en_spec2plot_precovrperp_gterr','el'+probe+'_pef_en_spec2plot_precovrperp_gterr_sz'+strtrim(string(num),2)
    copy_data, 'el'+probe+'_pif_en_spec2plot_perp', 'el'+probe+'_pif_en_spec2plot_perp_sz'+strtrim(string(num),2)
    copy_data, 'el'+probe+'_pif_en_spec2plot_prec', 'el'+probe+'_pif_en_spec2plot_prec_sz'+strtrim(string(num),2)
    copy_data, 'el'+probe+'_pif_en_spec2plot_precovrperp_gterr', 'el'+probe+'_pif_en_spec2plot_precovrperp_gterr_sz'+strtrim(string(num),2)
    copy_data, 'el'+probe+'_pif_pa_spec2plot_ch0', 'el'+probe+'_pif_pa_spec2plot_ch0_sz'+strtrim(string(num),2)
    copy_data, 'el'+probe+'_pif_pa_spec2plot_ch1', 'el'+probe+'_pif_pa_spec2plot_ch1_sz'+strtrim(string(num),2)
    copy_data, 'el'+probe+'_pif_pa_spec2plot_ch2', 'el'+probe+'_pif_pa_spec2plot_ch2_sz'+strtrim(string(num),2)
    copy_data, 'el'+probe+'_pif_pa_spec2plot_ch0LC', 'el'+probe+'_pif_pa_spec2plot_ch0LC_sz'+strtrim(string(num),2)
    copy_data, 'el'+probe+'_pif_pa_spec2plot_ch1LC', 'el'+probe+'_pif_pa_spec2plot_ch1LC_sz'+strtrim(string(num),2)
    copy_data, 'el'+probe+'_pif_pa_spec2plot_ch2LC', 'el'+probe+'_pif_pa_spec2plot_ch2LC_sz'+strtrim(string(num),2)
    copy_data, 'el'+probe+'_losscone', 'el'+probe+'_losscone'+strtrim(string(num),2)
    copy_data, 'el'+probe+'_antilosscone', 'el'+probe+'_antilosscone'+strtrim(string(num),2)

    if keyword_set(one_zone_only) then break

  endfor

  ; Create concatenating (24-hour) tplot variables
  omnie_str=''
  omnii_str=''
  erre_str=''
  perp_str=''
  prec_str=''
  erri_str=''
  ch0_str=''
  ch1_str=''
  ch2_str=''
  ch0LC_str=''
  ch1LC_str=''
  ch2LC_str=''
  lc_str=''
  alc_str=''

  for n=1,num do begin ;append all science zone data
    omnie_str+=' el'+probe+'_pef_en_spec2plot_omni_sz'+strtrim(string(n),2)
    omnii_str+=' el'+probe+'_pif_en_spec2plot_omni_sz'+strtrim(string(n),2)
    erre_str+=' el'+probe+'_pef_en_spec2plot_precovrperp_gterr_sz'+strtrim(string(n),2)
    perp_str+=' el'+probe+'_pif_en_spec2plot_perp_sz'+strtrim(string(n),2)
    prec_str+=' el'+probe+'_pif_en_spec2plot_prec_sz'+strtrim(string(n),2)
    erri_str+=' el'+probe+'_pif_en_spec2plot_precovrperp_gterr_sz'+strtrim(string(n),2)
    ch0_str+=' el'+probe+'_pif_pa_spec2plot_ch0_sz'+strtrim(string(n),2)
    ch1_str+=' el'+probe+'_pif_pa_spec2plot_ch1_sz'+strtrim(string(n),2)
    ch2_str+=' el'+probe+'_pif_pa_spec2plot_ch2_sz'+strtrim(string(n),2)
    ch0LC_str+=' el'+probe+'_pif_pa_spec2plot_ch0LC_sz'+strtrim(string(n),2)
    ch1LC_str+=' el'+probe+'_pif_pa_spec2plot_ch1LC_sz'+strtrim(string(n),2)
    ch2LC_str+=' el'+probe+'_pif_pa_spec2plot_ch2LC_sz'+strtrim(string(n),2)
    lc_str+=' el'+probe+'_losscone'+strtrim(string(n),2)
    alc_str+=' el'+probe+'_antilosscone'+strtrim(string(n),2)
   endfor

   store_data, 'el'+probe+'_pef_en_spec2plot_omni_all', data=omnie_str, dlimits=omnie_dl, limits=omnie_1
   store_data, 'el'+probe+'_pif_en_spec2plot_omni_all', data=omnii_str, dlimits=omnii_dl, limits=omnii_1
   store_data, 'el'+probe+'_pef_en_spec2plot_precovrperp_gterr_all', data=erre_str, dlimits=erre_dl, limits=erre_1
   store_data, 'el'+probe+'_pif_en_spec2plot_perp_all', data=perp_str, dlimits=perp_d, limits=perp_1
   store_data, 'el'+probe+'_pif_en_spec2plot_prec_all', data=prec_str, dlimits=prec_d, limits=prec_1
   store_data, 'el'+probe+'_pif_en_spec2plot_precovrperp_gterr_all', data=erri_str, dlimits=erri_dl, limits=erri_l
   store_data, 'el'+probe+'_pif_pa_spec2plot_ch0_all', data=ch0_str, dlimits=ch0_dl, limits=ch0_l
   store_data, 'el'+probe+'_pif_pa_spec2plot_ch1_all', data=ch1_str, dlimits=ch1_dl, limits=ch1_l
   store_data, 'el'+probe+'_pif_pa_spec2plot_ch2_all', data=ch2_str, dlimits=ch2_dl, limits=ch2_l
   store_data, 'el'+probe+'_pif_pa_spec2plot_ch0LC_all', data=ch0LC_str, dlimits=ch0LC_dl, limits=ch0LC_l
   store_data, 'el'+probe+'_pif_pa_spec2plot_ch1LC_all', data=ch1LC_str, dlimits=ch1LC_dl, limits=ch1LC_l
   store_data, 'el'+probe+'_pif_pa_spec2plot_ch2LC_all', data=ch2LC_str, dlimits=ch2LC_dl, limits=ch2LC_l
   store_data, 'el'+probe+'_losscone_all', data=lc_str, dlimits=lc_dl, limits=lc_l
   store_data, 'el'+probe+'_antilosscone_all', data=alc_str, dlimits=alc_dl, limits=alc_l

  ; Overwrite losscone/antilosscone tplot variable with full day from elf_getspec
  if nplots eq 25 then this_tr=[dat_gei.x[min_st[24]], dat_gei.x[min_en[24]]] $
  else this_tr=trange
  tdur=this_tr[1]-this_tr[0]
  elf_load_epd, probes=probe, datatype='pif', level='l1', type='nflux', no_download=1
  if spd_data_exists('el'+probe+'_pif_nflux',this_tr[0],this_tr[1]) then begin
    batch_procedure_error_handler, 'elf_getspec', probe=probe, /only_loss_cone
  endif

  for jthchan=0,2 do begin ;non-reg
    if jthchan eq 0 then mystr=ch0_str
    if jthchan eq 1 then mystr=ch1_str
    if jthchan eq 2 then mystr=ch2_str
    datastr=mystr+' lossconedeg antilossconedeg'
    str2exec="store_data,'el"+probe+"_pif_pa_spec2plot_ch"+strtrim(string(jthchan),2)+"LC_all',data=datastr"
    dummy=execute(str2exec)
  endfor

  ; this chunk might not be necessary since it's repeated later
  ylim,'el?_pef_pa*spec2plot* *losscone* el?_pef_pa*spec2plot_ch?LC*',0,180.
  ylim,'el?_pif_pa*spec2plot* *losscone* el?_pif_pa*spec2plot_ch?LC*',0,180.

  ; handle scaling of y axis
  get_data,'proxy_ae',data=proxy_ae
  if size(proxy_ae, /type) EQ 8 then begin
    idx = where(proxy_ae.x GE this_tr[0] and proxy_ae.x LT this_tr[1], ncnt)
    if ncnt GT 0 then ae_max=minmax(proxy_ae.y)
    if ncnt EQ 0 then ae_max=[0,140.]
    if ae_max[1] LT 145. then options, 'proxy_ae', yrange=[0,150] $
    else options, 'proxy_ae', yrange=[0,ae_max[1]+ae_max[1]*.1]
  endif

  if strlowcase(probe) eq 'a' then  $
    varstring=['ela_GLON','ela_MLAT_igrf[ela_MLAT_dip]', 'ela_MLT_igrf[ela_MLT_dip]', 'ela_L_igrf[ela_L_dip]'] else $
    varstring=['elb_GLON','elb_MLAT_igrf[elb_MLAT_dip]', 'elb_MLT_igrf[elb_MLT_dip]', 'elb_L_igrf[elb_L_dip]']

  if strlowcase(probe) eq 'a' then  $
    varstring=['ela_GLON','ela_MLAT_igrf[ela_MLAT_dip]', 'ela_MLT_igrf[ela_MLT_dip]', 'ela_L_igrf[ela_L_dip]'] else $
    varstring=['elb_GLON','elb_MLAT_igrf[elb_MLAT_dip]', 'elb_MLT_igrf[elb_MLT_dip]', 'elb_L_igrf[elb_L_dip]']

  ; Do hourly plots and 24hr plot
  for i=0,nplots-1 do begin ; plots full day on hr=24
    ; Set hourly start and stop times
    if min_en[i] GT n_elements(dat_gei.x)-1 then continue
    this_tr=[dat_gei.x[min_st[i]], dat_gei.x[min_en[i]]]
    tdur=this_tr[1]-this_tr[0]
    timespan, this_tr[0], tdur, /sec

    ;elf_load_state, probes=probe, /no_download

    if size(proxy_ae,/type) eq 8 then begin
      proxy_ae_sub=proxy_ae.y(where(proxy_ae.x ge time_double(this_tr[0]) and proxy_ae.x le time_double(this_tr[1])))
      ae_max=minmax(proxy_ae_sub)
      if ae_max[1] LT 145. then options, 'proxy_ae', yrange=[0,150] $
      else options, 'proxy_ae', yrange=[0,ae_max[1]+ae_max[1]*.1]
    endif

    ; use copy_data instead
    copy_data, 'el'+probe+'_pef_en_spec2plot_omni_all', 'el'+probe+'_pef_en_spec2plot_omni'
    copy_data, 'el'+probe+'_pif_en_spec2plot_omni_all', 'el'+probe+'_pif_en_spec2plot_omni'
    copy_data, 'el'+probe+'_pef_en_spec2plot_precovrperp_gterr_all', 'el'+probe+'_pef_en_spec2plot_precovrperp_gterr'
    copy_data, 'el'+probe+'_pif_en_spec2plot_perp_all', 'el'+probe+'_pif_en_spec2plot_perp'
    copy_data, 'el'+probe+'_pif_en_spec2plot_prec_all', 'el'+probe+'_pif_en_spec2plot_prec'
    copy_data, 'el'+probe+'_pif_en_spec2plot_precovrperp_gterr_all', 'el'+probe+'_pif_en_spec2plot_precovrperp_gterr'
    copy_data, 'el'+probe+'_pif_pa_spec2plot_ch0_all', 'el'+probe+'_pif_pa_spec2plot_ch0'
    copy_data, 'el'+probe+'_pif_pa_spec2plot_ch1_all', 'el'+probe+'_pif_pa_spec2plot_ch1'
    copy_data, 'el'+probe+'_pif_pa_spec2plot_ch2_all', 'el'+probe+'_pif_pa_spec2plot_ch2'
    copy_data, 'el'+probe+'_pif_pa_spec2plot_ch0LC_all', 'el'+probe+'_pif_pa_spec2plot_ch0LC'
    copy_data, 'el'+probe+'_pif_pa_spec2plot_ch1LC_all', 'el'+probe+'_pif_pa_spec2plot_ch1LC'
    copy_data, 'el'+probe+'_pif_pa_spec2plot_ch2LC_all', 'el'+probe+'_pif_pa_spec2plot_ch2LC'
    copy_data, 'el'+probe+'_losscone_all', 'el'+probe+'_losscone'
    copy_data, 'el'+probe+'_antilosscone_all', 'el'+probe+'_antilosscone'

    options, 'el'+probe+'_pef_en_spec2plot_omni', 'ysubtitle', '[keV]'
    options, 'el'+probe+'_pif_en_spec2plot_omni', 'ysubtitle', '[keV]'
    options, 'el'+probe+'_pef_en_spec2plot_precovrperp_gterr', '[keV]'
    options, 'el'+probe+'_pef_en_spec2plot_perp', 'ysubtitle', '[keV]'
    options, 'el'+probe+'_pef_en_spec2plot_prec', 'ysubtitle', '[keV]'
    options, 'el'+probe+'_pef_pa_spec2plot_ch0', 'ysubtitle', '[deg]'
    options, 'el'+probe+'_pef_pa_spec2plot_ch1', 'ysubtitle', '[deg]'
    options, 'el'+probe+'_pef_pa_spec2plot_ch2', 'ysubtitle', '[deg]'
    options, 'el'+probe+'_pef_pa_spec2plot_ch0LC', 'ysubtitle', '[deg]'
    options, 'el'+probe+'_pef_pa_spec2plot_ch1LC', 'ysubtitle', '[deg]'
    options, 'el'+probe+'_pef_pa_spec2plot_ch2LC', 'ysubtitle', '[deg]'
    options, 'el'+probe+'_losscone', 'ysubtitle', '[deg]'
    options, 'el'+probe+'_antilosscone', 'ysubtitle', '[deg]'

    ylim,'el?_p?f_pa*spec2plot* *losscone* el?_p?f_pa*spec2plot_ch?LC*',0,180.    
    options,'el?_p?f_pa*spec2plot_ch0LC*','ztitle',''
    options,'el?_p?f_pa*spec2plot_ch0LC*','ztitle','nflux'
    options,'el?_p?f_pa*spec2plot_ch1LC*','ztitle',''
    options,'el?_p?f_pa*spec2plot_ch1LC*','ztitle','nflux'
    options,'el?_p?f_pa*spec2plot_ch*LC*','ztitle',''
    options,'el?_p?f_pa*spec2plot_ch0*','ztitle',''
    options,'el?_p?f_pa*spec2plot_ch0*','ztitle','nflux'
    options,'el?_p?f_pa*spec2plot_ch1*','ztitle',''
    options,'el?_p?f_pa*spec2plot_ch1*','ztitle','nflux'
    options,'el?_p?f_pa*spec2plot_ch*LC*','ztitle',''
    options,'el?_p?f_pa*spec2plot_ch*LC*','ztitle','nflux'
    options,'el?_p?f_pa*spec2plot_ch*LC*','ztitle','nflux'
    options,'el?_p?f_en*spec2plot_omni','ztitle',''
    options,'el?_p?f_en*spec2plot_omni','ztitle','nflux'
    options,'el?_p?f_en*spec2plot_perp','ztitle',''
    options,'el?_p?f_en*spec2plot_perp','ztitle','nflux'
    options,'el?_p?f_en*spec2plot_prec','ztitle',''
    options,'el?_p?f_en*spec2plot_prec','ztitle','nflux'
    options, 'antilossconedeg', 'linestyle', 2
    options, 'el?_p?f_en_spec2plot_precovrperp_gterr', 'ztitle', 'ratio'

    ;For the ratios:
    zlim,'el?_p?f_en_spec2plot_precovrperp*',0.02,2.,1. ; applies to both I, e
    ;For electrons:
    zlim,'el?_pef_en_spec2plot_omni',2e1,2e7,1
    ;For ions:
    zlim,'el?_pif_en_spec2plot_????',1e2,2e6,1
    zlim,'el?_pif_pa_spec2plot_ch0*',1.e3,2.e6,1
    zlim,'el?_pif_pa_spec2plot_ch1*',1.e3,2.e5,1
    zlim,'el?_pif_pa_spec2plot_ch2*',5e2,2.e4,1
    zlim,'el?_pif_pa_spec2plot_ch0LC',1.e3,2.e6,1
    zlim,'el?_pif_pa_spec2plot_ch1LC',1.e3,2.e5,1
    zlim,'el?_pif_pa_spec2plot_ch2LC',5e2,2.e4,1
    zlim,'el?_pif_pa_*spec2plot_ch3*',1e2,1e4,1 ; this is not plotted but just in case
    options, 'el?_pif_en_spec2plot_????', 'ztitle','nflux'
    options, 'el?_pef_en_spec2plot_omni', 'ztitle','nflux'
    options, 'el?_pif_en_spec2plot_ch0*', 'ztitle','nflux'
    options, 'el?_pif_en_spec2plot_ch1*', 'ztitle','nflux'
    options, 'el?_pif_en_spec2plot_ch2*', 'ztitle','nflux'
    options, 'el?_p?f_en_spec2plot_precovrperp*', ztitle='ratio'
    vars2plot=['proxy_ae']
    vars2plot=[vars2plot,['fgm_survey_bar']]
    vars2plot=[vars2plot,['epdi_fast_bar']]
    vars2plot=[vars2plot,['epde_fast_bar']]
    vars2plot=[vars2plot,['sunlight_bar']]
    vars2plot=[vars2plot,['el'+probe+'_pef_en_spec2plot_'+['omni','precovrperp_gterr']]] ; electron energy spectra
    vars2plot=[vars2plot,['el'+probe+'_pif_en_spec2plot_'+['omni','prec','precovrperp_gterr']]]; ion energy spectra
    vars2plot=[vars2plot,['el'+probe+'_pif_pa_spec2plot_'+['ch0LC','ch1LC','ch2LC']]]
    vars2plot=[vars2plot,['el'+probe+'_bt89_sm_NEDT']]
    if tdur GT 10802. or i EQ 24 then begin   ; at least need to orbits for 24 hour plots
      tr=timerange()
      tr[1]=tr[1]+5400.
    endif
    ; Below chunk of code to fix y-labels might be messing up 24hr loss cone? If not, likely caused by interpolation in elf_getspec_v2
    ;

    if tdur Lt 194. then version=6 else version=7
    options,'el?_p?f_pa*spec2plot_ch*LC*','databar',90.
    tplot_options, version=version   ;6
    tplot_options, 'ygap',0
    tplot_options, 'no_vtitle_shift', 1

    if tdur LT 10802. then begin
      tplot,['proxy_ae', $
          'fgm_survey_bar', $
          'epdi_fast_bar', $
          'epde_fast_bar', $
          'sunlight_bar', $
          'el'+probe+'_pef_en_spec2plot_omni', $
          'el'+probe+'_pef_en_spec2plot_precovrperp_gterr', $
          'el'+probe+'_pif_en_spec2plot_omni', $
          'el'+probe+'_pif_en_spec2plot_prec', $
          'el'+probe+'_pif_en_spec2plot_precovrperp_gterr', $
          'el'+probe+'_pif_pa_spec2plot_ch0LC', $
          'el'+probe+'_pif_pa_spec2plot_ch1LC', $
          'el'+probe+'_pif_pa_spec2plot_ch2LC', $
          'el'+probe+'_bt89_sm_NEDT'], $
          var_label=varstring

      tplot_apply_databar

      tr=timerange()

      fd=file_dailynames(trange=tr[0], /unique, times=times)
      tstring=strmid(fd,0,4)+'-'+strmid(fd,4,2)+'-'+strmid(fd,6,2)+plot_lbl[i]
      title=''
      title='PRELIMINARY ELFIN-'+strupcase(probe)+' EPDI, alt='+strmid(strtrim(alt,1),0,3)+'km, '+tstring
      xyouts, .175, .975, title, /normal, charsize=1.1
      ; add time of creation
      xyouts, .76, .012, 'nflux: #/(cm^2 s sr MeV)',/normaL,color=1, charsize=.75
      xyouts,  .76, .001, 'Created: '+systime(/UTC),/normal,color=1, charsize=.75

  endif else begin
    vars2plot=['proxy_ae']
    vars2plot=[vars2plot,['elf_kp']]
    vars2plot=[vars2plot,['dst']]
    vars2plot=[vars2plot,['fgm_survey_bar']]
    vars2plot=[vars2plot,['epdi_fast_bar']]
    vars2plot=[vars2plot,['epde_fast_bar']]
    vars2plot=[vars2plot,['sunlight_bar']]
    vars2plot=[vars2plot,['el'+probe+'_pef_en_spec2plot_'+['omni','precovrperp_gterr']]] ; electron energy spectra
    vars2plot=[vars2plot,['el'+probe+'_pif_en_spec2plot_'+['omni','prec','precovrperp_gterr']]]; ion energy spectra
    vars2plot=[vars2plot,['el'+probe+'_pif_pa_spec2plot_'+['ch0LC','ch1LC','ch2LC']]]
    vars2plot=[vars2plot,['el'+probe+'_bt89_sm_NEDT']]
    if strlowcase(probe) eq 'a' then  $
      varstring=['ela_GLON','ela_MLAT_igrf[ela_MLAT_dip]', 'ela_MLT_igrf[ela_MLT_dip]', 'ela_L_igrf[ela_L_dip]'] else $
      varstring=['elb_GLON','elb_MLAT_igrf[elb_MLAT_dip]', 'elb_MLT_igrf[elb_MLT_dip]', 'elb_L_igrf[elb_L_dip]']

    ;tplot,vars2plot,var_label=varstring
    tplot,['proxy_ae', $
      'elf_kp', $
      'dst', $
      'fgm_survey_bar', $
      'epdi_fast_bar', $
      'epde_fast_bar', $
      'sunlight_bar', $
      'el'+probe+'_pef_en_spec2plot_omni', $
      'el'+probe+'_pef_en_spec2plot_precovrperp_gterr', $
      'el'+probe+'_pif_en_spec2plot_omni', $
      'el'+probe+'_pif_en_spec2plot_prec', $
      'el'+probe+'_pif_en_spec2plot_precovrperp_gterr', $
      'el'+probe+'_pif_pa_spec2plot_ch0LC', $
      'el'+probe+'_pif_pa_spec2plot_ch1LC', $
      'el'+probe+'_pif_pa_spec2plot_ch2LC', $
      'el'+probe+'_bt89_sm_NEDT'], $
      var_label=varstring

    tplot_apply_databar
    
    tr=timerange()
    fd=file_dailynames(trange=tr[0], /unique, times=times)
    tstring=strmid(fd,0,4)+'-'+strmid(fd,4,2)+'-'+strmid(fd,6,2)+plot_lbl[i]
    title=''
    title='PRELIMINARY ELFIN-'+strupcase(probe)+' EPDE/EPDI, alt='+strmid(strtrim(alt,1),0,3)+'km, '+tstring
    xyouts, .175, .975, title, /normal, charsize=1.1
    ; add time of creation
    xyouts, .76, .012, 'nflux: #/(cm^2 s sr MeV)',/normaL,color=1, charsize=.75
    xyouts,  .76, .001, 'Created: '+systime(/UTC),/normal,color=1, charsize=.75
  endelse

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Create GIF file
    ; Create small plot
    image=tvrd()
    device,/close
    set_plot,'z'
    image[where(image eq 255)]=1
    image[where(image eq 0)]=255
    gif_path = !elf.local_data_dir+'el'+probe+'/overplots/'+strmid(fd,0,4)+'/'+strmid(fd,4,2)+'/'+strmid(fd,6,2)+'/'
    file_mkdir, gif_path
    gif_file = gif_path+'el'+probe+'_l2_ionoverview_'+fd+file_lbl[i]
    dprint, 'Making gif file '+gif_file+'.gif'
    write_gif, gif_file+'.gif',image,r,g,b
    luns=lindgen(124)+5
    print, 'Hourly plot time: '+strtrim(systime(/sec)-t0,2)+' sec'

    if keyword_set(one_zone_only) then break

  endfor

  del_data, 'epd_fast_bar
  dprint, dlevel=2, 'Total time: '+strtrim(systime(/sec)-t0,2)+' sec'

end
