;+
;
;PROCEDURE:
;  epde_plot_wigrf_multispec_overviews
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
; 
;TO DO:
; elb can be done similarly but the code has not been generalized to either a or b yet. But this is straightforward.
;
;-
pro epde_plot_wigrf_multispec_overviews, trange=trange, probe=probe, no_download=no_download, $
  sci_zone=sci_zone

  ; initialize parameters
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

  ; set up plot options
  tplot_options, 'xmargin', [16,11]
  tplot_options, 'ymargin', [4,4]

  timeduration=time_double(trange[1])-time_double(trange[0])
  timespan,tr[0],timeduration,/seconds
  tr=timerange()

  ; close and free any logical units opened by calc
  luns=lindgen(124)+5
  for j=0,n_elements(luns)-1 do free_lun, luns[j]

  ; remove any existing pef tplot vars
  del_data, '*_pef_nflux'
  del_data, '*_all'
  elf_load_epd, probes=probe, datatype='pef', level='l1', type='nflux', no_download=no_download ; DEFAULT UNITS ARE NFLUX THIS ONE IS CPS
  get_data, 'el'+probe+'_pef_nflux', data=pef_nflux
  if size(pef_nflux, /type) NE 8 then begin
    dprint, dlevel=0, 'No data was downloaded for el' + probe + '_pef_nflux.'
    dprint, dlevel=0, 'No plots were producted.
    ;    return
  endif

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Get position data
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  elf_load_state, probes=probe, no_download=no_download
  get_data, 'el'+probe+'_pos_gei', data=dat_gei
  cotrans,'el'+probe+'_pos_gei','el'+probe+'_pos_gse',/GEI2GSE
  cotrans,'el'+probe+'_pos_gse','el'+probe+'_pos_gsm',/GSE2GSM
  cotrans,'el'+probe+'_pos_gsm','el'+probe+'_pos_sm',/GSM2SM ; in SM

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Get MLT amd LAT
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  elf_mlt_l_lat,'el'+probe+'_pos_sm',MLT0=MLT0,L0=L0,lat0=lat0 ;;subroutine to calculate mlt,l,mlat under dipole configuration
  get_data, 'el'+probe+'_pos_sm', data=elfin_pos
  store_data,'el'+probe+'_MLT',data={x:elfin_pos.x,y:MLT0}
  store_data,'el'+probe+'_L',data={x:elfin_pos.x,y:L0}
  store_data,'el'+probe+'_LAT',data={x:elfin_pos.x,y:lat0*180./!pi}
  options,'el'+probe+'_MLT',ytitle='MLT'
  options,'el'+probe+'_L',ytitle='L'
  options,'el'+probe+'_LAT',ytitle='LAT'
  alt = median(sqrt(elfin_pos.y[*,0]^2 + elfin_pos.y[*,1]^2 + elfin_pos.y[*,2]^2))-6371.

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Get Pseudo_ae data
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  elf_load_pseudo_ae, probe=probe, no_download=no_download
  get_data, 'pseudo_ae', data=pseudo_ae
  options, 'pseudo_ae', ysubtitle='[nT]'

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; ... shadow/sunlight bar 0 (shadow) or 1 (sunlight)
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  elf_load_sun_shadow_bar, tplotname='el'+probe+'_pos_sm', no_download=no_download

  ; ... EPD fast bar
  elf_load_epd_fast_segments, tplotname='el'+probe+'_pef_nflux', no_download=no_download
  get_data, 'epdef_fast_bar', data=epdef_fast_bar_x
  ;elf_load_epd_survey_segments, tplotname='el'+probe+'_pes_nflux'
  ;get_data, 'epdes_survey_bar', data=epdes_survey_bar_x

  if isa(epdef_fast_bar_x) && isa(epdes_fast_bar_x) then store_data, 'epd_bar', data=['epdef_fast_bar','epdes_survey_bar']
  if ~isa(epdef_fast_bar_x) && isa(epdes_survey_bar_x) then store_data, 'epd_bar', data=['epdef_survey_bar']
  if isa(epdef_fast_bar_x) && ~isa(epdes_survey_bar_x) then store_data, 'epd_bar', data=['epdef_fast_bar']
  options, 'epd_bar', panel_size=0.1
  options, 'epd_bar',ticklen=0
  options, 'epd_bar', 'ystyle',4
  options, 'epd_bar', 'xstyle',4

  ;if ~keyword_set(sci_zone) then xloc=.25 else xloc=.175
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; ... fgm status bar
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;elf_load_fgm_fast_segments, probe=probe
  ;get_data, 'fgf_bar', data=fgf_bar_x
  ; ... fgf status bar
  ;elf_load_fgm_survey_segments, probe=probe
  ;get_data, 'fgs_bar', data=fgs_bar_x

  ;if isa(fgs_bar_x) && isa(fgf_bar_x) then store_data, 'fgm_bar', data=['fgs_bar','fgf_bar']
  ;if ~isa(fgs_bar_x) && isa(fgf_bar_x) then store_data, 'fgm_bar', data=['fgf_bar']
  ;if isa(fgs_bar_x) && ~isa(fgf_bar_x) then store_data, 'fgm_bar', data=['fgs_bar']

  ;options, 'fgm_bar', panel_size=0.
  ;options, 'fgm_bar',ticklen=0
  ;options, 'fgm_bar', 'ystyle',4
  ;options, 'fgm_bar', 'xstyle',4

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
      this_lbl = ' ' + hr_ststr[m] + ':00 to ' + hr_ststr[m+1] + ':30'
      append_array, plot_lbl, this_lbl
      this_file = '_'+hr_ststr[m]
      append_array, file_lbl, this_file
    endif
  endfor
  ; append info for 24 hour plot
  append_array, min_st, 0
  append_array, min_en, 86399.
  append_array, plot_lbl, ' 00:00 to 24:00'
  append_array, file_lbl, '_24hr'
  
  ; set up for plots by science zone
  if (size(pef_nflux, /type)) EQ 8 then begin
    tdiff = pef_nflux.x[1:n_elements(pef_nflux.x)-1] - pef_nflux.x[0:n_elements(pef_nflux.x)-2]
    idx = where(tdiff GT 40., ncnt)   ; note: 40 seconds is an arbitary time
    if ncnt EQ 0 then begin
      ; if ncnt is zero then there is only one science zone for this time frame
      sz_starttimes=[pef_nflux.x[0]]
      sz_min_st=[0]
      sz_endtimes=pef_nflux.x[n_elements(pef_nflux.x)-1]
      sz_min_en=[n_elements(pef_nflux.x)-1]
      ts=time_struct(starttimes[0])
      te=time_struct(endtimes[0])
      if ts.hour LT 10 then shr='0'+strtrim(string(ts.hour),1) else shr=strtrim(string(ts.hour),1)
      if te.hour LT 10 then ehr='0'+strtrim(string(te.hour),1) else ehr=strtrim(string(te.hour),1)
    endif else begin
      for sz=0,ncnt-1 do begin
        if sz EQ 0 then begin
          this_s = pef_nflux.x[0]
          sidx = 0
          this_e = pef_nflux.x[idx[sz]]
          eidx = idx[sz]
        endif else begin
          this_s = pef_nflux.x[idx[sz-1]+1]
          sidx = idx[sz-1]+1
          this_e = pef_nflux.x[idx[sz]]
          eidx = idx[sz]
        endelse
        if (this_e-this_s) lt 20. then continue
        append_array, sz_starttimes, this_s
        append_array, sz_endtimes, this_e
        append_array, sz_min_st, sidx
        append_array, sz_min_en, eidx
        ts=time_struct(this_s)
        te=time_struct(this_e)
        if ts.hour LT 10 then shr='0'+strtrim(string(ts.hour),1) else shr=strtrim(string(ts.hour),1)
        if te.hour LT 10 then ehr='0'+strtrim(string(te.hour),1) else ehr=strtrim(string(te.hour),1)
        endfor
      endelse
    endif

  nplots = n_elements(min_st)
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; MAIN LOOP for PLOTs
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  for i=22,nplots-1 do begin

    ; set hourly start and stop times
    if min_en[i] GT n_elements(dat_gei.x)-1 then continue
    this_tr=[dat_gei.x[min_st[i]], dat_gei.x[min_en[i]]]
    tdur=this_tr[1]-this_tr[0]
    timespan, this_tr[0], tdur, /sec

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Load state and calculate IGRF
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    elf_load_state, probes=probe, no_download=no_download
    threeones=[1,1,1]
    cotrans,'el'+probe+'_pos_gei','el'+probe+'_pos_gse',/GEI2GSE
    cotrans,'el'+probe+'_pos_gse','el'+probe+'_pos_gsm',/GSE2GSM
    tt89,'el'+probe+'_pos_gsm',/igrf_only,newname='el'+probe+'_bt89_gsm',period=1.
    cotrans,'el'+probe+'_pos_gsm','el'+probe+'_pos_sm',/GSM2SM ; in SM
    get_data, 'el'+probe+'_pos_sm', data=state_pos_sm
    ; calculate IGRF in nT
    cotrans,'el'+probe+'_bt89_gsm','el'+probe+'_bt89_sm',/GSM2SM ; Bfield in SM coords as well
    ;calc,' "bt89_SMdown" = -(total("bt89_sm"*"pos_sm",2)#threeones)/sqrt(total("pos_sm"^2,2)) '
    xyz_to_polar,'el'+probe+'_pos_sm',/co_latitude
    get_data,'el'+probe+'_pos_sm_th',data=pos_sm_th,dlim=myposdlim,lim=myposlim
    get_data,'el'+probe+'_pos_sm_phi',data=pos_sm_phi
    csth=cos(!PI*pos_sm_th.y/180.)
    csph=cos(!PI*pos_sm_phi.y/180.)
    snth=sin(!PI*pos_sm_th.y/180.)
    snph=sin(!PI*pos_sm_phi.y/180.)
    rot2rthph=[[[snth*csph],[csth*csph],[-snph]],[[snth*snph],[csth*snph],[csph]],[[csth],[-snth],[0.*csth]]]
    store_data,'rot2rthph',data={x:pos_sm_th.x,y:rot2rthph},dlim=myposdlim,lim=myposlim
    tvector_rotate,'rot2rthph','el'+probe+'_bt89_sm',newname='el'+probe+'_bt89_sm_sph'
    rotSMSPH2NED=[[[snth*0.],[snth*0.],[snth*0.-1.]],[[snth*0.-1.],[snth*0.],[snth*0.]],[[snth*0.],[snth*0.+1.],[snth*0.]]]
    store_data,'rotSMSPH2NED',data={x:pos_sm_th.x,y:rotSMSPH2NED},dlim=myposdlim,lim=myposlim
    tvector_rotate,'rotSMSPH2NED','el'+probe+'_bt89_sm_sph',newname='el'+probe+'_bt89_sm_NED' ; North (-Spherical_theta), East (Spherical_phi), Down (-Spherical_r)
    options,'el'+probe+'_bt89_sm_NED','ytitle','IGRF [nT]'
    options,'el'+probe+'_bt89_sm_NED','labels',['N','E','D']
    options,'el'+probe+'_bt89_sm_NED','databar',0.
    options,'el'+probe+'_bt89_sm_NED','ysubtitle','North, East, Down'

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; SCI ZONES
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
    ; find all the science zones that are in this hourly range
    sz_idx = where((sz_endtimes GE this_tr[0] AND sz_endtimes LE this_tr[1]) $
      OR (sz_starttimes GE this_tr[0] AND sz_starttimes LE this_tr[1]),ncnt)    

    if ncnt GT 0 then begin
      ; loop for each zone
      for j=0,ncnt-1 do begin
        if file_lbl[i] EQ '_24hr' then break     
        ; set time for this zone
        sz_tr=[sz_starttimes[sz_idx[j]],sz_endtimes[sz_idx[j]]]
        tdur=sz_tr[1]-sz_tr[0]
        timespan, sz_tr[0], tdur, /sec

        ; get EPD data
        del_data, 'el'+probe+'_pef_nflux'
        elf_load_epd, probes=probe, datatype='pef', level='l1', type='nflux',no_download=no_download ; DEFAULT UNITS ARE NFLUX THIS ONE IS CPS

        ; get sector and phase delay for this zone
        phase_delay = elf_find_phase_delay(trange=sz_tr, probe=probe, instrument='epde', no_download=no_download)
        dsect2add=fix(phase_delay.dsect2add[0])
        dphang2add=float(phase_delay.dphang2add[0])
        medianflag=fix(phase_delay.medianflag)
        append_array,mdsect,dsect2add
        append_array,mdphang,dphang2add    
        case medianflag of
          0: phase_msg = 'Phase delay values dSect2add='+strtrim(string(dsect2add),1) + ' and dPhAng2add=' +strmid(strtrim(string(dphang2add),1),0,4)
          1: phase_msg = 'Median Phase delay values dSect2add='+strtrim(string(dsect2add),1) + ' and dPhAng2add=' +strmid(strtrim(string(dphang2add),1),0,4)
          2: phase_msg = 'No phase delay available. Data is not regularized.'
        endcase
    
        if spd_data_exists('el'+probe+'_pef_nflux',sz_tr[0],sz_tr[1]) then begin
          if medianflag NE 2 then begin
            elf_getspec, /regularize, probe=probe, dSect2add=dsect2add, dSpinPh2add=dphang2add, no_download=no_download
          endif else begin
            elf_getspec, probe=probe
          endelse
        endif
    
        ; handle scaling of y axis
        if size(pseudo_ae, /type) EQ 8 then begin
          ae_idx = where(pseudo_ae.x GE sz_tr[0] and pseudo_ae.x LT sz_tr[1], ncnt)
          if ncnt GT 0 then ae_max=minmax(pseudo_ae.y[ae_idx])
          if ncnt EQ 0 then ae_max=[0,140.]
          if ae_max[1] LT 145. then begin
            options, 'pseudo_ae', yrange=[0,150]
            options, 'pseudo_ae', ystyle=1
          endif else begin
            options, 'pseudo_ae', yrange=[0,ae_max[1]+ae_max[1]*.1]
            options, 'pseudo_ae', ystyle=1
          endelse
        endif
            
        ; Figure out which science zone
        get_data,'el'+probe+'_LAT',data=this_lat
        lat_idx=where(this_lat.x GE sz_tr[0] AND this_lat.x LE sz_tr[1], ncnt)
        if ncnt GT 0 then begin
          sz_lat=this_lat.y[lat_idx]
          median_lat=median(sz_lat)
          dlat = sz_lat[1:n_elements(sz_lat)-1] - sz_lat[0:n_elements(sz_lat)-2]
          if median_lat GT 0 then begin
            if median(dlat) GT 0 then sz_plot_lbl = ', North Ascending Zone' else $
              sz_plot_lbl = ', North Descending Zone'
            if median(dlat) GT 0 then sz_file_lbl = file_lbl[i] + '_nasc' else $
              sz_file_lbl = file_lbl[i] + '_ndes'
          endif else begin
            if median(dlat) GT 0 then sz_plot_lbl = ', South Ascending Zone' else $
              sz_plot_lbl = ', South Descending Zone'
            if median(dlat) GT 0 then sz_file_lbl = file_lbl[i] + '_sasc' else $
              sz_file_lbl = file_lbl[i] + '_sdes'
          endelse
        endif
    
        ;;;;;;;;;;;;;;;;;;;;;;
        ; PLOT
        window, xsize=750, ysize=1000
        if tdur Lt 194. then version=6 else version=7
        tplot_options, version=version   ;6
        tplot_options, 'ygap',0
        tplot_options, 'charsize',.9
        elf_set_overview_options, probe=probe            
        tplot,['pseudo_ae', $
          'epd_fast_bar', $
          'sunlight_bar', $
          'el'+probe+'_pef_en_spec2plot_omni', $
          'el'+probe+'_pef_en_spec2plot_anti', $
          'el'+probe+'_pef_en_spec2plot_perp', $
          'el'+probe+'_pef_en_spec2plot_para', $
          'el'+probe+'_pef_pa_reg_spec2plot_ch[0,1]LC', $
          'el'+probe+'_pef_pa_spec2plot_ch[2,3]LC', $
          'el'+probe+'_bt89_sm_NED'], $
          var_label='el'+probe+'_'+['LAT','MLT']
    
        tr=timerange()
        fd=file_dailynames(trange=tr[0], /unique, times=times)
        tstring=strmid(fd,0,4)+'-'+strmid(fd,4,2)+'-'+strmid(fd,6,2)+sz_plot_lbl
        title='PRELIMINARY ELFIN-'+strupcase(probe)+' EPDE, alt='+strmid(strtrim(alt,1),0,3)+'km, '+tstring
        xyouts, .135, .975, title, /normal, charsize=1.2
        tplot_apply_databar
    
        ; add time of creation
        xyouts,  .775, .005, 'Created: '+systime(),/normal,color=10, charsize=.75
        ; add phase delay message
        if spd_data_exists('el'+probe+'_pef_nflux',sz_tr[0],sz_tr[1]) then $
          xyouts, .01, .005, phase_msg, /normal, color=10, charsize=.75
    
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; Create PNG file
        tr=timerange()
        fd=file_dailynames(trange=tr[0], /unique, times=times)
        png_path = !elf.local_data_dir+'el'+probe+'/overplots/'+strmid(fd,0,4)+'/'+strmid(fd,4,2)+'/'+strmid(fd,6,2)+'/'
        file_mkdir, png_path
        png_file = png_path+'el'+probe+'_l2_overview_'+fd+sz_file_lbl
        dprint, 'Making png file '+png_file+'.png'
        makepng, png_file
        
      endfor   ; end of science zones
    endif ; end of sci zone
   
    ;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; START HOURLY plot
    ;;;;;;;;;;;;;;;;;;;;;;;;;;
    tdur=this_tr[1]-this_tr[0]
    timespan, this_tr[0], tdur, /sec

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; get EPD data
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    del_data, 'el'+probe+'_pef_nflux'
    elf_load_epd, probes=probe, datatype='pef', level='l1', type='nflux',no_download=no_download ; DEFAULT UNITS ARE NFLUX THIS ONE IS CPS
    if spd_data_exists('el'+probe+'_pef_nflux',this_tr[0],this_tr[1]) then begin
      if ~undefined(mdsect) && ~undefined(mdphang) then begin
        dsect2add=median(mdsect)
        dphang2add=median(mdphang)
        elf_getspec, /regularize, probe=probe, dSect2add=dsect2add, dSpinPh2add=dphang2add, no_download=no_download
        phase_msg = 'Median Phase delay values dSect2add='+strtrim(string(dsect2add),1) + ' and dPhAng2add=' +strmid(strtrim(string(dphang2add),1),0,4)
      endif else begin
        elf_getspec, probe=probe
        phase_msg = 'No phase delay available. Data is not regularized.'      
      endelse
    endif

    ; handle scaling of y axis
    if size(pseudo_ae, /type) EQ 8 then begin
      idx = where(pseudo_ae.x GE this_tr[0] and pseudo_ae.x LT this_tr[1], ncnt)
      if ncnt GT 0 then ae_max=minmax(pseudo_ae.y[idx])
      if ncnt EQ 0 then ae_max=[0,140.]
      if ae_max[1] LT 145. then begin
        options, 'pseudo_ae', yrange=[0,150]
        options, 'pseudo_ae', ystyle=1
      endif else begin
        options, 'pseudo_ae', yrange=[0,ae_max[1]+ae_max[1]*.1]
        options, 'pseudo_ae', ystyle=1
      endelse
    endif

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; PLOT
    window, xsize=750, ysize=1000
    if tdur Lt 194. then version=6 else version=7
    tplot_options, version=version   ;6
    tplot_options, 'ygap',0
    tplot_options, 'charsize',.9
    elf_set_overview_options, probe=probe
    tplot,['pseudo_ae', $
      'epd_fast_bar', $
      'sunlight_bar', $
      'el'+probe+'_pef_en_spec2plot_omni', $
      'el'+probe+'_pef_en_spec2plot_anti', $
      'el'+probe+'_pef_en_spec2plot_perp', $
      'el'+probe+'_pef_en_spec2plot_para', $
      'el'+probe+'_pef_pa_reg_spec2plot_ch[0,1]LC', $
      'el'+probe+'_pef_pa_spec2plot_ch[2,3]LC', $
      'el'+probe+'_bt89_sm_NED'], $
      var_label='el'+probe+'_'+['LAT','MLT']

    tr=timerange()
    fd=file_dailynames(trange=tr[0], /unique, times=times)
    tstring=strmid(fd,0,4)+'-'+strmid(fd,4,2)+'-'+strmid(fd,6,2)+plot_lbl[i]
    title='PRELIMINARY ELFIN-'+strupcase(probe)+' EPDE, alt='+strmid(strtrim(alt,1),0,3)+'km, '+tstring
    xyouts, .2, .975, title, /normal, charsize=1.2
    tplot_apply_databar

    ; add time of creation
    xyouts,  .775, .005, 'Created: '+systime(),/normal,color=10, charsize=.75
    ; add phase delay message
    if spd_data_exists('el'+probe+'_pef_nflux',this_tr[0],this_tr[1]) then $
      xyouts, .01, .005, phase_msg, /normal, color=10, charsize=.75

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Create PNG file
    tr=timerange()
    fd=file_dailynames(trange=tr[0], /unique, times=times)
    png_path = !elf.local_data_dir+'el'+probe+'/overplots/'+strmid(fd,0,4)+'/'+strmid(fd,4,2)+'/'+strmid(fd,6,2)+'/'
    file_mkdir, png_path
    png_file = png_path+'el'+probe+'_l2_overview_'+fd+file_lbl[i]
    dprint, 'Making png file '+png_file+'.png'
    makepng, png_file

    ;close, /all
    luns=lindgen(124)+5
    for j=0,n_elements(luns)-1 do free_lun, luns[j]

  endfor     ; end of hourly loop

end
