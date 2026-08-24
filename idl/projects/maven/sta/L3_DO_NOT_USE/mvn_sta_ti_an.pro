pro mvn_sta_ti_an, DOFIT=dofit

  starttime = systime(1)

  loadct2,43
  cols=get_colors()

  mass_o2 = [24,40.]
  m_o2 = 32.
  engy_o2 = [0.0,30]
  min_o2 = 50.
  
common mvn_sta_temp_error, sta_c6_errtime, sta_c6error, sta_c8_errtime, sta_c8error
  sta_c8error = []
  sta_c8_errtime = []

  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;; uncorrected
  ;;; first calculate the beamwidth temp with tp2
  ; it will also have the temperature from the maxwellian fit 
  
  get_4dt,'tp2_4dl3','mvn_sta_get_c8',mass=mass_o2,name='mvn_sta_c8_tperpu',energy=engy_o2,m_int=m_o2,mincnt=min_o2;,gap_time=5.
  options,'mvn_sta_c8_tperpu',ytitle='sta c8!CTp eV',colors=cols.black;,labels='c8_tp2',labpos=.04
  ylim,'mvn_sta_c8_tperpu',.01,1,1
  
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;; calculate the corrections

 ;;;  get characteristic energy, temperature and attenuator arrays

  get_data, 'mvn_sta_c8_tperpu', tp_times, untempdata ;;uncorrected temp from the data
  store_data,'mvn_sta_c8_temp_statunc',data={x:sta_c8_errtime,y:sta_c8error}
  
;  get_data,'mvn_sta_c6_o2+_ec',data=tmp1
;  if size(tmp1,/type) ne 8 then begin
;    get_4dt,'ec_4d','mvn_sta_get_c6',mass=mass_o2,name='mvn_sta_c6_o2+_ec',energy=engy_o2,m_int=m_o2,gap_time=5.
;    options,'mvn_sta_c6_o2+_ec',ytitle='sta c6!CEc O2+!CeV',colors=cols.black;,labels='c6',labpos=1.
;    ylim,'mvn_sta_c6_o2+_ec',1,30,1
   get_data,'mvn_sta_c6_o2+_ec',data=tmp1
;  endif
  get_data,'mvn_sta_c6_att',data=tmp3
  ec_tp = interp(tmp1.y,tmp1.x,tp_times)
  att_tp = round(interp(tmp3.y,tmp3.x,tp_times))
  
  ;*************************

  ; input the parameters for analyzer response and scattering

  scale_tp = 1.0
  scale_tp2 = 1.0

  scat = .0010  & tp_offset=4.1 & ana_dth_fwhm=[8.0,5.0,6.0,4.0] & scat_exp=.1    ; testing
  scat = .0030  & tp_offset=4.0 & ana_dth_fwhm=[8.0,5.0,6.0,4.0] & scat_exp=.5    ; testing
  scat = .0000  & tp_offset=4.0 & ana_dth_fwhm=[8.0,5.0,6.0,4.0] & scat_exp=.5    ; testing
  scat = .0030  & tp_offset=4.0 & ana_dth_fwhm=[7.0,8.0,6.0,8.0] & scat_exp=.5    ; testing
  scat = .0015  & tp_offset=4.0 & ana_dth_fwhm=[7.0,8.0,4.0,10.0] & scat_exp=.5   ; testing
  scat = .0015  & tp_offset=4.0 & ana_dth_fwhm=[7.0,8.0,4.0,6.0] & scat_exp=.5    ; testing
  scat = .0015  & tp_offset=4.0 & ana_dth_fwhm=[7.0,8.0,4.0,7.0] & scat_exp=.5    ; testing
  scat = .0015  & tp_offset=4.0 & ana_dth_fwhm=[7.0,8.0,4.0,7.0] & scat_exp=.5    ; testing

  scat = .0030  & tp_offset=4.0 & ana_dth_fwhm=[6.5,8.0,4.0,6.0] & scat_exp=.8    ; testing - works for 20190405
  scat = .0025  & tp_offset=4.0 & ana_dth_fwhm=[6.5,8.0,4.0,7.0] & scat_exp=.8    ; testing - works for 20190918
; scat = .0025  & tp_offset=4.0 & ana_dth_fwhm=[6.5,8.0,4.0,12.0] & scat_exp=.8   ; testing - works for 20190818
  ;*************************
  ; estimate ion suppression broadening contribution - only in att=0,2 states due to variation across aperture, att=1,3 only have ions at edges of FOV

  tr=timerange()
  kk3 = mvn_sta_get_kk3((tr[0]+tr[1])/2.) ; ion suppression correction
  kk3_c8 = kk3[att_tp]
  de_att = [1.,0.3,1.,0.3]
  de_att = [1.,0.0,1.,0.0]
  ; de_att_scale = .020 & tp_kk3_exp=1.         ; this is determined emperically at attenuator boundaries
; de_att_scale = .022 & tp_kk3_exp=1.         ; this is determined emperically at attenuator boundaries
; de_att_scale = .025 & tp_kk3_exp=1.       ; this is determined emperically at attenuator boundaries
  de_att_scale = .020 & tp_kk3_exp=0.5          ; this works for better for 20190814 at scpot=0.
; de_att_scale = .018 & tp_kk3_exp=0.5          ; this works for better for 20190511 at scpot=1.
  
  
  ;;;; this 'if' was added 1/22
  if 1 then begin
  scat = .0025  & tp_offset=4.0 & ana_dth_fwhm=[7.5,9.0,4.0,7.0] & scat_exp=.8    ; testing - works better for 20190705
  de_att = [1.,0.2,1.,0.2]
  de_att_scale = .015 & tp_kk3_exp=0.5              ; this works for better for 20190705 at scpot=0.
  de_att = [1.,0.1,1.,0.1] & de_att_scale = .025 &  tp_kk3_exp=0.5      ; 20180410 at scpot=0.
endif
   
  de_kk3 = de_att_scale*de_att[att_tp]
 ; tp_kk3 = de_kk3*(kk3_c8/ec_tp)
  tp_kk3 = de_kk3*(kk3_c8/ec_tp)^tp_kk3_exp    ;;; UPDATED 11/30 TO REMOVE DISCONTINUITIES AT SC_POT = 0,2
  store_data,'mvn_sta_c8_tp_kk3',data={x:tp_times,y:tp_kk3}
  ylim,'mvn_sta_c8_tp_kk3',0.001,0.04,1
  
  ;*************************

  ; estimate particle scattering contribution to analyzer broadening for c8

  scat_c8 = ec_tp*scat*(((ec_tp-tp_offset)>0.)/(ec_tp+.000001))^scat_exp

  tp_full = tp_offset+2.
  scat_c8 = ec_tp*scat*((tp_full<(ec_tp-tp_offset)>0.)/(tp_offset+.000001))^scat_exp

  store_data,'mvn_sta_c8_o2+_de_fwhm_scat',data={x:tp_times,y:scat_c8}
  ylim,'mvn_sta_c8_o2+_de_fwhm_scat',0,0.04,0

  ;*************************

  ; get the analyzer dth_fwhm based on attenuator state

  dth_fwhm = ana_dth_fwhm[att_tp]
  store_data,'ana_dth_fwhm',data={x:tp_times,y:dth_fwhm}
  options,'ana_dth_fwhm',colors=cols.black,labels='fwhm';,labpos=4

  dth_fwhm = dth_fwhm*(1. - dth_fwhm/(!radeg*asin((untempdata/(scale_tp2*ec_tp))^.5)+dth_fwhm))     ; correction for energy-angle broadening, this works better for nightside
  store_data,'ana_dth_fwhm_corr',data={x:tp_times,y:dth_fwhm}
  options,'ana_dth_fwhm_corr',colors=cols.green,labels='fwhm_corr';,labpos=2
  store_data,'ana_dth_fwhm_compare',data=['ana_dth_fwhm','ana_dth_fwhm_corr']
  ylim,'ana_dth_fwhm_compare',1.,7.,1

  ;*************************

  ; add the analyzer response broadening to the scattering broadening

  ana_c8 = scale_tp*ec_tp*sin(dth_fwhm/!radeg)^2
  
  temp_ana_c8 = ana_c8 + scat_c8 + tp_kk3    ; all corrections - analyzer broadening and scattering
  
  aa=where(finite(untempdata))
  ab=where(finite(temp_ana_c8))
  ac=where(finite(untempdata) and ~finite(temp_ana_c8))
  if total(ac) ne -1 then begin
    ad = ec_tp[ac]
    ae = tp_times[ac]
    
    
;    stop
  endif
  store_data,'mvn_sta_c8_o2+_tp_ana_response',data={x:tp_times,y:ana_c8}

  store_data,'mvn_sta_c8_o2+_temp_ac',data={x:tp_times,y: temp_ana_c8}   ; changed 20190719 to be like the energy scattering term
  options,'mvn_sta_c8_o2+_temp_ac',ylog=1,yrange=[.001,.1]
         
  ; now correct   
  tempdata = untempdata - temp_ana_c8
  aa=where(~finite(tempdata) and finite(untempdata))
  tempdata[aa] = !values.F_NAN
;  aa=where(untempdata/tempdata ge 5)
;  tempdata[aa] = !values.F_NAN
  
  ;*************************
  ; finally make the tplot structures of corrected temperature

  ;store_data, 'mvn_sta_c8_o2+_untempd', data={x:tp_times, y:untempdata}

  store_data,'mvn_sta_c8_temp',data={x:tp_times,y:tempdata}  
  
  store_data, 'tperp_w_corr', data=['mvn_sta_c8_tperpu', $
    'mvn_sta_c8_temp', 'mvn_sta_c8_o2+_temp_ac' ]
  options, 'tperp_w_corr', 'colors', [cols.blue, cols.cyan,  200]
  options, 'tperp_w_corr', 'labels', ['Uncorrected', $
    'Corrected', 'Analyzer']
  options, 'tperp_w_corr', 'labflag', -1
  ylim, 'tperp_w_corr', 0.001, 10, 1
  
  ;;; if doing the fit, do that now
  dofit=0
  if dofit then begin
    get_4dt,'tp2f_4d2','mvn_sta_get_c8',mass=mass_o2,name='mvn_sta_c8_tp_fit_params',energy=engy_o2,m_int=m_o2,mincnt=min_o2
    get_data, 'mvn_sta_c8_tp_fit_params', fittimes, fitparams

    store_data, 'mvn_sta_c8_tp_fit', data={x:fittimes, y:fitparams[*,1]}
    store_data, 'mvn_sta_c8_fit_n', data={x:fittimes, y:fitparams[*,0]}
    store_data, 'mvn_sta_c8_fit_vb', data={x:fittimes, y:fitparams[*,2]}
    
    get_data, 'mvn_sta_c8_tp_fit', tpf_times, untempfit ;;uncorrect temp from the fit
    
    tempfitc8 = untempfit - temp_ana_c8
    
    store_data, 'mvn_sta_c8_o2+_untempf', data={x:tp_times, y:untempfit}
    store_data,'mvn_sta_c8_o2+_tempf',data={x:tp_times,y:tempfitc8>untempfit/5.}
    
    store_data, 'tperp_compare', data=['mvn_sta_c8_o2+_untempd', 'mvn_sta_c8_o2+_untempf', $
      'mvn_sta_c8_o2+_tempd', 'mvn_sta_c8_o2+_tempf']
    options, 'tperp_compare', 'colors', [cols.blue, cols.black, cols.cyan, cols.red]
    options, 'tperp_compare', 'labels', ['Data Uncorrected', 'Fit Uncorrected', $
      'Data Corrected', 'Fit Corrected']
    options, 'tperp_compare', 'labflag', -1
    ylim, 'tperp_compare', 0.001, 10, 1
    
    store_data, 'tperp_w_corr', data=['mvn_sta_c8_o2+_untempd', 'mvn_sta_c8_o2+_untempf', $
      'mvn_sta_c8_o2+_tempd', 'mvn_sta_c8_o2+_tempf', 'mvn_sta_c8_o2+_tp_ana' ]
    options, 'tperp_w_corr', 'colors', [cols.blue, cols.black, cols.cyan, cols.red, 200]
    options, 'tperp_w_corr', 'labels', ['Data Uncorrected', 'Fit Uncorrected', $
      'Data Corrected', 'Fit Corrected', 'Analyzer']
    options, 'tperp_w_corr', 'labflag', -1
    ylim, 'tperp_w_corr', 0.001, 10, 1
  endif
  
  print,'ti_an load successful'
  print,'run time = ',systime(1)-starttime


end
