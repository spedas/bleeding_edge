pro mvn_sta_ti_en, DOFIT=dofit

  starttime = systime(1)

  loadct2,43
  cols=get_colors()

  mass_o2 = [24,40.]
  m_o2 = 32.
  engy_o2 = [0.0,30.]
  min_o2 = 50.
  
  tt=timerange()
  d1_loaded = 0
  common mvn_d1,mvn_d1_ind,mvn_d1_dat
  common mvn_sta_temp_error, sta_c6_errtime, sta_c6error, sta_c8_errtime, sta_c8error
  common mvn_sta_vd_cmn, do_vd, sta_c6_vd, sta_c6_vd_errtime, sta_c6_vd_error, sta_c8_vd, sta_c8_vd_errtime, sta_c8_vd_error
  sta_c6error = [!values.D_NAN]
  sta_c6_vd_error = [!values.D_NAN]
  sta_c6_errtime = [!values.D_NAN]
  sta_c6_vd_errtime = [!values.D_NAN]
  if size(mvn_d1_dat,/type) eq 8 then d1_loaded = 1

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;; uncorrected
  ;;; first calculate the beamwidth temp with tbc
  
  do_vd=1
  sta_c6_vd=[]

  get_4dt,'tbc_4dl3','mvn_sta_get_c6',mass=mass_o2,name='mvn_sta_c6_o2+_tparu',energy=engy_o2,m_int=m_o2,mincnt=min_o2,gap_time=5.
  options,'mvn_sta_c6_o2+_tparu',ytitle='sta c6!CT eV';,colors=cols.black;,labels='c8_tp2',labpos=.04
  ylim,'mvn_sta_c6_o2+_tparu',.01,1,1
  
  do_vd=0
  
  get_data,'mvn_sta_c6_o2+_tparu',tpar_times,untempdata
  sta_c6error = sta_c6error[1:-1]
  store_data,'mvn_sta_c6_o2+_temp_statunc',data={x:sta_c6_errtime[1:-1],y:sta_c6error}

  ;; beamwidth without lpw correction
   get_4dt,'tbc_nolpw_4d','mvn_sta_get_c6',mass=mass_o2,name='mvn_sta_c6_o2+_temp_nolpw',energy=engy_o2,m_int=m_o2,mincnt=min_o2
  ylim,'mvn_sta_c6_o2+_temp_nolpw',0.01,10,1
  store_data,'mvn_sta_temp_lpwcorr', data=['mvn_sta_c6_o2+_tparu','mvn_sta_c6_o2+_temp_nolpw']
  ylim,'mvn_sta_temp_lpwcorr',0.01,10,1
  options,'mvn_sta_temp_lpwcorr',colors=[cols.black,cols.cyan]
    
  ;; repeat for the hot beam
  get_4dt,'tbc_4dl3','mvn_sta_get_c6',mass=mass_o2,name='mvn_sta_c6_o2+_tparu_hot',energy=[0.,30000.],m_int=m_o2,mincnt=min_o2,gap_time=5.
  options,'mvn_sta_c6_o2+_tparu_hot',ytitle='sta c6!CT eV';,colors=cols.black;,labels='c8_tp2',labpos=.04
  ylim,'mvn_sta_c6_o2+_tparu_hot',.01,1,1

;  get_4dt,'tbc_nolpw_4d','mvn_sta_get_c6',mass=mass_o2,name='mvn_sta_c6_o2+_temp_nolpw_hot',energy=[0.,30000.],m_int=m_o2,mincnt=min_o2
;  ylim,'mvn_sta_c6_o2+_temp_nolpw_hot',0.01,10,1
;
;  store_data,'mvn_sta_temp_lpwcorr_hot', data=['mvn_sta_c6_o2+_tparu_hot','mvn_sta_c6_o2+_temp_nolpw_hot']
;  ylim,'mvn_sta_temp_lpwcorr_hot',0.01,10,1
;  options,'mvn_sta_temp_lpwcorr_hot',colors=[cols.black,cols.cyan]
  
  ;; O+ 
;  get_4dt,'tbc_4dg3','mvn_sta_get_c6',mass=[12.,20.],name='mvn_sta_c6_o+_tparu',energy=engy_o2,m_int=16.,mincnt=min_o2,gap_time=5.

  
;  if keyword_set(d1_loaded) then begin
;    bins=bytarr(64) & bins[24:35]=1
;    get_4dt,'tbc_4d','mvn_sta_get_d1',mass=mass_o2,name='mvn_sta_d1_o2+_temp',energy=engy_o2,m_int=m_o2,mincnt=min_o2,bins=bins
;    options,'mvn_sta_d1_o2+_temp',ytitle='sta c6!C O2+!CTi eV',colors=cols.black;,labels='d1',labpos=.64
;    ylim,'mvn_sta_d1_o2+_temp',.01,1,1
;  endif
;
;  get_4dt,'tbc_4dg3','mvn_sta_get_c6',mass=mass_o2,name='mvn_sta_c6_o2+_ti_hot',m_int=m_o2,energy=[0,100]
;  options,'mvn_sta_c6_o2+_ti_hot',ytitle='sta c6!C O2+!CTi eV';,colors=cols.red,labels='c6_hot',labpos=.32
;  ylim,'mvn_sta_c6_o2+_ti_hot',.01,100,1

;  if d1_loaded then begin
;    get_4dt,'t_nodiag_4d','mvn_sta_get_d1',mass=mass_o2,name='mvn_sta_d1_o2+_ti_hot',m_int=m_o2,energy=[0,100]
;    options,'mvn_sta_d1_o2+_ti_hot',ytitle='sta d1!C O2+!Cno diag!CTi eV',colors=[cols.blue,cols.green,cols.red,cols.cyan];,labels='d1_no_diag',labpos=1.28
;    ylim,'mvn_sta_d1_o2+_ti_hot',.01,100,1
;  endif else begin
;    tt=timerange()
;    d0_loaded = 0
;    dat_d0 = mvn_sta_get_d0(total(tt)/2.)
;    if size(dat_d0,/type) eq 8 then d0_loaded = 1
;    if d0_loaded then begin
;      get_4dt,'t_nodiag_4d','mvn_sta_get_d0',mass=mass_o2,name='mvn_sta_o2+_d0_ti_hot',m_int=m_o2,energy=[0,100]
;      options,'mvn_sta_o2+_d0_ti_hot',ytitle='sta d0!C O2+!Cno diag!CTi eV',colors=[cols.blue,cols.green,cols.red,cols.cyan];,labels='c6_hot',labpos=1.28
;      ylim,'mvn_sta_o2+_d0_ti_hot',.01,100,1
;    endif
;  endelse

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;; calculate the corections

  ;;;  get characteristic energy, temperature and attenuator arrays for c6 and d1

   

  get_data,'mvn_sta_c6_o2+_ec',data=tmp_c6_ec

  
;  if size(tmp_c6_ec,/type) ne 8 then begin
    get_4dt,'ec_4d','mvn_sta_get_c6',mass=mass_o2,name='mvn_sta_c6_o2+_ec',energy=engy_o2,m_int=m_o2,mincnt=min_o2,gap_time=5.
    options,'mvn_sta_c6_o2+_ec',ytitle='sta c6!CEc O2+!CeV',colors=cols.black;,labels='c6',labpos=1.
    ylim,'mvn_sta_c6_o2+_ec',1,30,1
    get_data,'mvn_sta_c6_o2+_ec',data=tmp_c6_ec
 ; endif
  
  ec_c6 = tmp_c6_ec.y

    get_4dt,'de_swp_4d','mvn_sta_get_c6',name='mvn_sta_c6_o2+_de_swp'
    options,'mvn_sta_c6_o2+_de_swp',ytitle='sta c6!C!CdE/E !C!Cswp avg',colors=cols.black & ylim,'mvn_sta_c6_o2+_de_swp',.02,1,1
    
  get_data,'mvn_sta_c6_att',data=tmp3
  att_c6 = round(interp(tmp3.y,tmp3.x,tmp_c6_ec.x))


  ;*************************

  ; input the parameters for analyzer response and scattering

    scat=0.0065 & ti_offset=4.0 & ripple=0 & ti_noise=0.0 & scat_exp=0.80 & ana_de_fwhm=[.13,.10,.09,.07]  & swp_de_c6_scale = 1.0
  
  ;*************************
  
  ; estimate ion suppression broadening contribution - only in att=0,2 states due to variation across aperture, att=1,3 only have ions at edges of FOV

  tr=timerange()
  kk3 = mvn_sta_get_kk3((tr[0]+tr[1])/2.)
  ;;; TO TEST THE ION SUPPRESSION CORRECTION CHANGE KK3 TO A # IN EV'S
  ;kk3[*] = 1.5 
  kk3_c6 = kk3[att_c6]
  de_att = [1.,0.,1.,0.]

  de_att_scale = .006       ; this is determined emperically at attenuator boundaries
  de_kk3 = de_att_scale*de_att[att_c6]
  ti_kk3 = de_kk3*(kk3_c6/ec_c6)
  store_data,'mvn_sta_c6_ti_kk3',data={x:tmp_c6_ec.x,y:ti_kk3}
  ylim,'mvn_sta_c6_ti_kk3',0.001,0.04,1

  ;*************************

  ; estimate particle scattering contribution to analyzer broadening for c6

  scat_c6 = ec_c6*scat*(((ec_c6-ti_offset)>0.)/(ec_c6+.000001))^scat_exp

  ti_full = ti_offset+2.
  scat_c6 = ec_c6*scat*((ti_full<(ec_c6-ti_offset)>0.)/(ti_offset+.000001))^scat_exp

  store_data,'mvn_sta_c6_o2+_de_fwhm_scat',data={x:tmp_c6_ec.x,y:scat_c6}
  ylim,'mvn_sta_c6_o2+_de_fwhm_scat',0,0.04,0

  ;*************************

  ; get the analyzer de_fwhm based on attenuator state, corrected for HV broadening by noise/ripple
  scale_de_fwhm=1.0   
  de_fwhm_c6 = scale_de_fwhm*ana_de_fwhm[att_c6]
  store_data,'ana_de_fwhm_c6',data={x:tmp_c6_ec.x,y:de_fwhm_c6}

  ;*************************

  ; correct de_fwhm for each product based on beam width - effective DE/E is reduced by a factor of ~2 for narrow beams

  fwhm_scale=4.*alog(2)^.5  ; check that this is correct
  ; ana_scale=8.*alog(2)^.5   ; check that this is correct
  ana_scale=16.*alog(2)   ; check that this is correct

  get_data,'mvn_sta_c6_o2+_de_swp',data=swp_data

  ; the de_fwhm_c6 is overestimated if ti/ec is small, and in the limit of ti->0, de_fwhm->.5*de_fwhm_broad_beam
  ; not sure how to do this so turn it off for now
  ; de_fwhm_c6  = de_fwhm_c6* (1. - de_fwhm_c6 /(fwhm_scale*(ti_c6 /(ec_c6>2.7))^.5  +de_fwhm_c6) )   ; 2.7 is the ram characteristic energy of O2+ in eV
  ; de_fwhm_c6  = de_fwhm_c6* (1. - .5*de_fwhm_c6 /(fwhm_scale*(ti_c6 /(ec_c6>2.7))^.5  +de_fwhm_c6) )  ; as ti_c6->0, de_fwhm_c6->.5*de_fwhm_c6

   swp_de_c6 = swp_de_c6_scale*swp_data.y          ; swp_data.y is the 64 swp result
   if n_elements(swp_de_c6) ne n_elements(tmp_c6_ec.x) then swp_de_c6 = swp_de_c6_scale*interp(swp_data.y,swp_data.x,tmp_c6_ec.x)

  ti_ana = (de_fwhm_c6 + ripple)^2*ec_c6/ana_scale
;  de_fwhm_c6_corr2  = de_fwhm_c6* (1. - .5*de_fwhm_c6 /(fwhm_scale*(((ti_c6-ti_ana)>0.)/(ec_c6>2.7))^.5  +de_fwhm_c6) ) ; changed 20190721 as ti_c6->0, de_fwhm_c6->.5*de_fwhm_c6
  de_fwhm_c6_corr2  = de_fwhm_c6      ; turn off any reduction in effective de from a narrow beam

; correct de_fwhm for data averaging and HVPS ripple and noise

; de_fwhm_c6_corr  = (de_fwhm_c6_corr2^2 + swp_de_c6^2 + ripple^2)^.5 
  de_fwhm_c6_corr  = (de_fwhm_c6_corr2 + swp_de_c6 + ripple) 
; + de_fwhm_offset            ; not used, but might be needed

;  store_data,'ana_de_fwhm_c6_corr2',data={x:tmp_c6_ec.x,y:de_fwhm_c6_corr2}
;    options,'ana_de_fwhm_c6_corr2',colors=cols.green
;  store_data,'ana_de_fwhm_c6_corr',data={x:tmp_c6_ec.x,y:de_fwhm_c6_corr}
;    options,'ana_de_fwhm_c6_corr',colors=cols.red
;  store_data,'ana_de_fwhm_c6_compare',data=['ana_de_fwhm_c6','ana_de_fwhm_c6_corr','ana_de_fwhm_c6_corr2']
;    ylim,'ana_de_fwhm_c6_compare',.02,.4,1

;*************************
; add the analyzer response broadening to the scattering broadening

correction = de_fwhm_c6_corr^2*ec_c6/ana_scale + scat_c6 + ti_noise + ti_kk3

;if total(finite(correction)) eq 0 then stop

    store_data,'mvn_sta_c6_o2+_temp_ac' ,data={x:tmp_c6_ec.x,y:correction}
      options,'mvn_sta_c6_o2+_temp_ac',colors=cols.magenta,yrange=[.005,.1],ylog=1;,labels='c6_ana',labpos=.004
    store_data,'mvn_sta_c6_o2+_temp_ana_response',data={x:tmp_c6_ec.x,y:((de_fwhm_c6_corr^2*ec_c6/ana_scale))}      ; without scattering
      options,'mvn_sta_c6_o2+_temp_ana_response',colors=cols.red,yrange=[.001,1],ylog=1;,labels='c6_ana2',labpos=.04
; 
    get_data,'mvn_sta_c6_o2+_temp_ac',data=tmp4
    temp_ac_c6 = interp(tmp4.y,tmp4.x,tmp_c6_ec.x)     ; they should have same time resolution, but for some reason the arrays can differ, this prevents failure   
    store_data,'mvn_sta_c6_o2+_temp_ana2',data={x: tmp_c6_ec.x, y: temp_ac_c6}
    get_data,'mvn_sta_c6_o2+_temp_ana_response',data=tmp4
    temp_ana_response_c6 = interp(tmp4.y,tmp4.x,tmp_c6_ec.x)      ; they should have same time resolution, but for some reason the arrays can differ, this prevents failure   

  ; now correct the data

  tempdata = untempdata - temp_ac_c6
  
  ;; correct the hot data too 
   get_data, 'mvn_sta_c6_o2+_tparu_hot', thot, untempdatahot
   temp_ana_c6_hot = interp(tmp4.y,tmp4.x,thot)
   tempdatahot = untempdatahot - temp_ana_c6_hot
  
;stop

    ;; recalculate the calibrations with different values of sc potential.
    ;; this is for error estimation. 

  ;*************************
  ; finally make the tplot structures of corrected temperature

 ; store_data, 'mvn_sta_c6_o2+_untempd', data={x:tpar_times, y:untempdata}
  ; don't allow corrections more than a factor of 5 
;  bigcorr = where(tempdata lt untempdata/5.)
;  tempdata[bigcorr] = !values.F_NAN
;  
;  bigcorr = where(tempdatahot lt untempdatahot/5.)
;  tempdatahot[bigcorr] = !values.F_NAN

  store_data,'mvn_sta_c6_o2+_temp',data={x:tpar_times,y:tempdata}   
  store_data,'mvn_sta_c6_o2+_tpar',data={x:tpar_times,y:tempdata}
  store_data, 'mvn_sta_c6_o2+_tpar_hot', data={x:thot, y:tempdatahot}
  
  ;; if doing the fit, do that now
  dofit=0

  if dofit then begin

    get_4dt,'tbcf_4d2','mvn_sta_get_c6',mass=mass_o2,name='mvn_sta_c6_o2+_tpar_fit_params',energy=engy_o2,m_int=m_o2,mincnt=min_o2

    get_data, 'mvn_sta_c6_o2+_tpar_fit_params', fittimes, fitparams

    store_data, 'mvn_sta_c6_o2+_tpar_fit', data={x:fittimes, y:fitparams[*,1]}
    store_data, 'mvn_sta_c6_fit_n', data={x:fittimes, y:fitparams[*,0]}
    store_data, 'mvn_sta_c6_fit_vb', data={x:fittimes, y:fitparams[*,2]}

    get_data,'mvn_sta_c6_o2+_tpar_fit', tparf_times, untempfit

    tempfitc6 = untempfit - temp_ana_c6
    store_data, 'mvn_sta_c6_o2+_untempf', data={x:tpar_times, y:untempfit}
    store_data,'mvn_sta_c6_o2+_tempf',data={x:tpar_times,y:tempfitc6>untempfit/5.}
  endif
  
  ;;;; make comparison plots....these will break if the fit variable doesn't exist...


;  store_data, 'tpar_compare', data=['mvn_sta_c6_o2+_untempd', 'mvn_sta_c6_o2+_untempf', $
;    'mvn_sta_c6_o2+_tempd', 'mvn_sta_c6_o2+_tempf']
;  options, 'tpar_compare', 'colors', [cols.blue, cols.black, cols.cyan, cols.red]
;  options, 'tpar_compare', 'labels', ['Data Uncorrected', 'Fit Uncorrected', $
;    'Data Corrected', 'Fit Corrected']
;  options, 'tpar_compare', 'labflag', -1
;  ylim, 'tpar_compare', 0.001, 10, 1

  store_data, 'tpar_w_corr', data=['mvn_sta_c6_o2+_tparu', $
    'mvn_sta_c6_o2+_temp', 'mvn_sta_c6_o2+_temp_ac' ]
  options, 'tpar_w_corr', 'colors', [cols.blue, cols.cyan, 200]
  options, 'tpar_w_corr', 'labels', ['Uncorrected', $
    'Corrected', 'Analyzer']
  options, 'tpar_w_corr', 'labflag', -1
  ylim, 'tpar_w_corr', 0.001, 10, 1
  

  print,'ti_en load successful'
  print,'run time = ',systime(1)-starttime

end
