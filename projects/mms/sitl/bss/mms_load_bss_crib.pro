PRO mms_load_bss_crib
  compile_opt idl2
  
  ;------------------
  ; time range
  ;-------------------
  timespan,'2015-09-25/00:00',24,/hours

  ;-----------------------
  ; some science data
  ;-----------------------   
  sc='mms3'
  mms_sitl_get_dfg,sc=sc
  options,sc+'_dfg_srvy_gsm_dmpa',constant=0,colors=[2,4,6],ystyle=1,yrange=[-100,100]
  mms_sitl_get_fpi_basic, sc=sc
  options,sc+'_fpi_iEnergySpectr_omni',spec=1,ylog=1,zlog=1,yrange=[10,26000],ystyle=1
  
  ;----------------------------
  ; Burst Segment Status (BSS)
  ;----------------------------
  mms_load_bss
  
  ;----------------------------
  ; Tplot
  ;----------------------------
  
  ; display fast survey period (red) and SITL selections (green)
  tplot,[sc+'_dfg_srvy_gsm_dmpa','mms_bss_fast','mms_bss_burst',sc+'_fpi_iEnergySpectr_omni']
  stop
  
  ; display fast survey period (red), burst segment status (usually black or yellow),
  ; and FOM values (histogram)
  tplot,[sc+'_dfg_srvy_gsm_dmpa',sc+'_fpi_iEnergySpectr_omni',$
    'mms_bss_fast','mms_bss_status','mms_bss_fom']
  stop
END