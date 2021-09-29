;
; Loads EPDE, performs pitch angle determination and plotting of energy and pitch angle spectra
; Including precipitating and trapped spectra separately. EPDI can be treated similarly, but not done yet
; Regularize keyword performs rebinning of data on regular sector centers starting at zero (rel.to the time
; of dBzdt 0 crossing which corresponds to Pitch Angle = 90 deg and Spin Phase angle = 0 deg.).
; If the data has already been collected at regular sectors there is no need to perform this.
; 
; elb can be done similarly but the code has not been generalized to either a or b yet. But this is straightforward.
;
pro epde_plot_wigrf_multispec_overviews, trange=trange, probe=probe, no_download=no_download
  
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

  ; remove any existing pef tplot vars
  del_data, 'el'+probe+'_pef_nflux'
  elf_load_epd, probes=probe, datatype='pef', level='l1', type='nflux', no_download=no_download ; DEFAULT UNITS ARE NFLUX THIS ONE IS CPS
  get_data, 'el'+probe+'_pef_nflux', data=d
  if size(d, /type) NE 8 then begin
     dprint, dlevel=0, 'No data was downloaded for el' + probe + '_pef_nflux.'
     dprint, dlevel=0, 'No plots were producted. 
     return
  endif

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Get position data
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  elf_load_state, probes=probe, no_download=no_download
  get_data, 'el'+probe+'_pos_gei', data=dat_gei
  cotrans,'el'+probe+'_pos_gei','el'+probe+'_pos_gse',/GEI2GSE
  cotrans,'el'+probe+'_pos_gse','el'+probe+'_pos_gsm',/GSE2GSM
  cotrans,'el'+probe+'_pos_gsm','el'+probe+'_pos_sm',/GSM2SM ; in SM
  
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
  ; setup for orbits
  ; 1 24 hour plot, 4 6 hr plots, 12 2 hr plots
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
 
  nplots = n_elements(min_st)

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; MAIN LOOP for PLOTs
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  for i=0,nplots-1 do begin
     
    this_tr=[dat_gei.x[min_st[i]], dat_gei.x[min_en[i]]]
    tdur=this_tr[1]-this_tr[0]
    timespan, this_tr[0], tdur, /sec
    elf_load_state, probes=probe, no_download=no_download 

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Load state and calculate IGRF
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
       
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; get EPD data
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    elf_load_epd, probes=probe, datatype='pef', level='l1', type='nflux', no_download=no_download ; DEFAULT UNITS ARE NFLUX THIS ONE IS CPS
    
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
    
    phase_delay = elf_find_phase_delay(trange=tr, probe=probe, instrument='epde', no_download=no_download)
    if size(phase_delay, /type) NE 8 then elf_getspec,/regularize, no_download=no_download $
      else elf_getspec, /regularize, dSect2add=phase_delay.dsect2add, dSpinPh2add=phase_delay.dphang2add, no_download=no_download

    ; handle scaling of y axis 
    if size(pseudo_ae, /type) EQ 8 then begin 
      idx = where(pseudo_ae.x GE this_tr[0] and pseudo_ae.x LT this_tr[1], ncnt)
      if ncnt GT 0 then ae_max=max(pseudo_ae.y[idx])
      if ncnt LE 0 then continue
      if ae_max LT 150. then begin
        options, 'pseudo_ae', yrange=[0,150] 
        options, 'pseudo_ae', ystyle=1
      endif else begin
        options, 'pseudo_ae', yrange=[0,ae_max]
        options, 'pseudo_ae', ystyle=1
      endelse 
    endif 

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; PLOT
    window, xsize=750, ysize=1000
    tplot_options, version=7   ;6
    tplot_options, 'ygap',0
    tplot_options, 'charsize',.9
    options, 'el'+probe+'_pef_en_spec2plot_omni', charsize=.9
    options, 'el'+probe+'_pef_en_spec2plot_anti', charsize=.9
    options, 'el'+probe+'_pef_en_spec2plot_perp', charsize=.9
    options, 'el'+probe+'_pef_en_spec2plot_para', charsize=.9
    options, 'el'+probe+'_bt89_sm_NED', charsize=.9
    
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
    title='ELFIN-'+strupcase(probe)+' EPDE, alt='+strmid(strtrim(alt,1),0,3)+'km, '+tstring
    xyouts, .25, .975, title, /normal, charsize=1.2 
    tplot_apply_databar

    ; add time of creation
    xyouts,  .775, .005, 'Created: '+systime(),/normal,color=10, charsize=.75
        
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Create PNG file
    tr=timerange()
    fd=file_dailynames(trange=tr[0], /unique, times=times)
    png_path = !elf.local_data_dir+'overplots/'+strmid(fd,0,4)+'/'+strmid(fd,4,2)+'/'+strmid(fd,6,2)+'/'
    file_mkdir, png_path
    png_file = png_path+'el'+probe+'_l2_overview_'+fd+file_lbl[i]  
    dprint, 'Making png file '+png_file+'.png'

    makepng, png_file
stop    
    ; close any luns opened by calc
    for j=100,128 do free_lun, j
    
  endfor
   
end
