;Ali: August 2020
;+
; $LastChangedBy: ali $
; $LastChangedDate: 2021-08-27 12:49:50 -0700 (Fri, 27 Aug 2021) $
; $LastChangedRevision: 30264 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/sc/spp_sc_hk_tplot.pro $
;-

pro spp_sc_hk_tplot,prefix=prefix,default=default

  if ~keyword_set(prefix) then prefix='spp_sc_hkp_'
  pre262=prefix+'0x262_SWEAP_CRIT_SW_'
  options,default=default,verbose=0,pre262+'58',tplot_routine='bitplot',numbits=8,yticks=9,psyms=1,labels=['SPC_PWR','SPANAI_PWR','SPANAE_PWR','SPANB_PWR','SPANA_HTR','SPANB_HTR','ACTR_PWR','OVERCURR_DETECT'],colors=[0,1,2,6],yticklen=1,ygridstyle=1,yminor=1,panel_size=2
  options,default=default,verbose=0,pre262+'59',tplot_routine='bitplot',numbits=4,yticks=5,psyms=1,labels=['LINK_B_ACTIVE','LINK_A_ACTIVE','FIELDS_CLOCK','FLASH_PLBK_IN_PROGRESS'],colors=[0,1,2,6],yticklen=1,ygridstyle=1,yminor=1
  options,default=default,verbose=0,pre262+'60',tplot_routine='bitplot',numbits=4,yticks=5,psyms=1,labels=['WDOG_RESET_DETECTED','BOOT_MODE','FSW_CSCI','OP_OVERRUN'],colors=[0,1,2,6],yticklen=1,ygridstyle=1,yminor=1
  options,default=default,verbose=0,pre262+['SPANAI','SPANAE','SPANB'],tplot_routine='bitplot',numbits=4,yticks=5,psyms=1,labels=['HV_ENABLED','ATT_OR_IN1_IN2','CVR_OR_EOT1_EOT2','HK_MON_TRIP'],colors=[0,1,2,6],yticklen=1,ygridstyle=1,yminor=1
  options,default=default,verbose=0,pre262+'SPC',tplot_routine='bitplot',numbits=4,yticks=5,psyms=1,labels=['RAIL_DAC_GT_LIMIT','OR_ELEC_FA_CALON','HV_ENABLED','MODE'],colors=[0,1,2,6],yticklen=1,ygridstyle=1,yminor=1
  options,default=default,verbose=0,pre262+['LAST_FSW_EVENT','SPANAI_HV_MODE','SPANAE_HV_MODE','SPANB_HV_MODE'],tplot_routine='bitplot',numbits=4,yticks=5,psyms=1,yticklen=1,ygridstyle=1,yminor=1

  options,default=default,prefix+'0x???_'+['MET','SEQN','PKT_SIZE'],panel_size=.5
  options,default=default,prefix+'0x081_*',labels='0x081',colors='r',psym=-2
  options,default=default,prefix+'0x1c4_FSW_REC_HK_ALLOC_ERR_RAM_SSR_SWEAP_FIELDS_WISPR_EPIHI_LO',labels=reverse(['RAM','SSR','SWEAP','FIELDS','WISPR','EPI_HI','EPI_LO']),tplot_routine='bitplot',numbits=7,yticks=8,psyms=1,colors=[0,1,2,6],yticklen=1,ygridstyle=1,yminor=1
  options,default=default,prefix+'0x1c5_*',labels='0x1c5',colors='g',psym=-1
  deriv_data,prefix+'0x1c5_FSW_REC_ALLOC_USED_SWEAP'
  options,default=default,prefix+'0x1c5_FSW_REC_ALLOC_USED_SWEAP_ddt',yrange=[-1e-5,4e-5],constant=0.,psym=0
  options,default=default,prefix+'0x1c5_FSW_REC_ALLOC_GBITS',labels=['EPILO','EPIHI','WISPR','FIELDS','SWEAP','CDH_SSR_HK','CDH_RAM_HK'],colors='bcgmrkybcgmrky',labflag=-1,panel_size=2,yrange=[0,100]
  options,default=default,prefix+'0x1df_FSW_SPP_SOLAR_DIST_RS',yticks=0,psym=-2 ;yticks=2 creates a much more pleasant looking plot, but sometimes fails (hsk_spp_2020064_01.ptp.gz): PLOT: Data range for axis has zero length.
  options,default=default,prefix+'0x1df_FSW_SPP_*_SSR_ALLOC_STATUS',labels='0x1df',colors='b',psym=-2
  options,default=default,prefix+'0x1df_FSW_SPP_FIELDS1_2_SWEAP_WISPR_EPIHI_LO_PWR_OFF_WARN',labels=reverse(['FIELDS1','FIELDS2','SWEAP','WISPR','EPI_HI','EPI_LO']),tplot_routine='bitplot',numbits=6,yticks=7,psyms=1,colors=[0,1,2,6],yticklen=1,ygridstyle=1,yminor=1
  options,default=default,prefix+'0x257_FSW_SPP_*_SSR_ALLOC_STATUS',labels='0x257',colors='r',psym=-4
  options,default=default,prefix+'0x257_FSW_REC_HK_ALLOC_ERR_SSR_SWEAP_FIELDS_WISPR_EPIHI_LO',labels=reverse(['SSR','SWEAP','FIELDS','WISPR','EPI_HI','EPI_LO']),tplot_routine='bitplot',numbits=6,yticks=7,psyms=1,colors=[0,1,2,6],yticklen=1,ygridstyle=1,yminor=1
  options,default=default,prefix+'0x254_HK_WHL*',labels=['WHL0','WHL1','WHL2','WHL3'],colors='kbgr',labflag=-1
  ;storing the below hybrid plots outside the ptp_files loop causes weird autoscale-in-time issues with tlimit!
  store_data,prefix+'FSW_SPP_SOLAR_DIST',data=prefix+['0x1df_FSW_SPP_SOLAR_DIST','0x254_FSW_GC_HK_HK_DIST_BODY_TO_SUN_QUANTIZED'],dlim={colors:'br',labels:['0x1df','0x254'],labflag:-1}
  store_data,prefix+'FSW_SPP_SWEAP_SSR_ALLOC_STATUS',data=prefix+['0x1df_FSW_SPP_SWEAP_SSR_ALLOC_STATUS','0x257_FSW_SPP_SWEAP_SSR_ALLOC_STATUS','0x1c5_FSW_REC_ALLOC_PERCENT_USED_SWEAP'],dlim={labflag:-1,panel_size:2,yrange:[0,100]}
  store_data,prefix+'0x255_PDU_SWEAP_CURRENT',data=prefix+'0x255_PDU_SWEAP_*CURR ',dlim={colors:'bgr',labels:['SWEAP_CURR','SPAN_AB_SURV_HTRS_CURR','SPC_SURV_HTR_CURR'],labflag:-1,panel_size:2}
  labels_a=['SPC_PRE_AMP_TEMP','SPAN_A_POS_PEDESTAL_TEMP','SPAN_A_POS_ELECT_BOX_TEMP','SPAN_A_POS_TOP_ANALYZER_TEMP']
  labels_b=['SWEM_TEMP',           'SPAN_B_PEDESTAL_TEMP',    'SPAN_B_ELECT_BOX_TEMP',    'SPAN_B_TOP_ANALYZER_TEMP']
  store_data,prefix+'0x256_SWEAP_SPAN_A_TEMP',data=prefix+'0x256_SWEAP_'+labels_a,dlim={colors:'rbgm',labels:labels_a,labflag:-1,panel_size:2}
  store_data,prefix+'0x256_SWEAP_SPAN_B_TEMP',data=prefix+'0x256_SWEAP_'+labels_b,dlim={colors:'rbgm',labels:labels_b,labflag:-1,panel_size:2}
  options,'*',ystyle=3

end


;SWEAP_CRIT_SW_OVERCURR_DETECT,                                 58,    7,    1;
;SWEAP_CRIT_SW_ACTR_PWR,                                        58,    6,    1;
;SWEAP_CRIT_SW_SPANB_HTR,                                       58,    5,    1;
;SWEAP_CRIT_SW_SPANA_HTR,                                       58,    4,    1;
;SWEAP_CRIT_SW_SPANB_PWR,                                       58,    3,    1;
;SWEAP_CRIT_SW_SPANAE_PWR,                                      58,    2,    1;
;SWEAP_CRIT_SW_SPANAI_PWR,                                      58,    1,    1;
;SWEAP_CRIT_SW_SPC_PWR,                                         58,    0,    1;
;SWEAP_CRIT_SW_EVENT_CNTR,                                      59,    7,    4;
;SWEAP_CRIT_SW_FLASH_PLBK_IN_PROGRESS,                          59,    3,    1;
;SWEAP_CRIT_SW_FIELDS_CLOCK,                                    59,    2,    1;
;SWEAP_CRIT_SW_LINK_A_ACTIVE,                                   59,    1,    1;
;SWEAP_CRIT_SW_LINK_B_ACTIVE,                                   59,    0,    1;
;SWEAP_CRIT_SW_LAST_FSW_EVENT,                                  60,    7,    4;
;SWEAP_CRIT_SW_OP_OVERRUN,                                      60,    3,    1;
;SWEAP_CRIT_SW_FSW_CSCI,                                        60,    2,    1;
;SWEAP_CRIT_SW_BOOT_MODE,                                       60,    1,    1;
;SWEAP_CRIT_SW_WDOG_RESET_DETECTED,                             60,    0,    1;
;SWEAP_CRIT_SW_SWEM3P3V,                                        61,    7,    8;
;SWEAP_CRIT_SW_SPANAI_HK_MON_TRIP,                              62,    7,    1;
;SWEAP_CRIT_SW_SPANAI_CVR_OR_EOT1_EOT2,                         62,    6,    1;
;SWEAP_CRIT_SW_SPANAI_ATT_OR_IN1_IN2,                           62,    5,    1;
;SWEAP_CRIT_SW_SPANAI_HV_ENABLED,                               62,    4,    1;
;SWEAP_CRIT_SW_SPANAI_HV_MODE,                                  62,    3,    4;
;SWEAP_CRIT_SW_SPANAE_HK_MON_TRIP,                              63,    7,    1;
;SWEAP_CRIT_SW_SPANAE_CVR_OR_EOT1_EOT2,                         63,    6,    1;
;SWEAP_CRIT_SW_SPANAE_ATT_OR_IN1_IN2,                           63,    5,    1;
;SWEAP_CRIT_SW_SPANAE_HV_ENABLED,                               63,    4,    1;
;SWEAP_CRIT_SW_SPANAE_HV_MODE,                                  63,    3,    4;
;SWEAP_CRIT_SW_SPANB_HK_MON_TRIP,                               64,    7,    1;
;SWEAP_CRIT_SW_SPANB_CVR_OR_EOT1_EOT2,                          64,    6,    1;
;SWEAP_CRIT_SW_SPANB_ATT_OR_IN1_IN2,                            64,    5,    1;
;SWEAP_CRIT_SW_SPANB_HV_ENABLED,                                64,    4,    1;
;SWEAP_CRIT_SW_SPANB_HV_MODE,                                   64,    3,    4;
;SWEAP_CRIT_SW_SPC_MODE,                                        65,    7,    1;
;SWEAP_CRIT_SW_SPC_HV_ENABLED,                                  65,    6,    1;
;SWEAP_CRIT_SW_SPC_OR_ELEC_FA_CALON,                            65,    5,    1;
;SWEAP_CRIT_SW_SPC_RAIL_DAC_GT_LIMIT,                           65,    4,    1;
;SWEAP_CRIT_SW_SPC_ERR_CNTR,                                    65,    3,    4;
