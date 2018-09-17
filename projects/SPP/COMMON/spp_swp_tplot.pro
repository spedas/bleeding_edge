;--------------------------------------------------------------------
; PSP SPAN TPLOT ROUTINE
;
; $LastChangedBy: phyllisw2 $
; $LastChangedDate: 2018-09-11 11:57:19 -0700 (Tue, 11 Sep 2018) $
; $LastChangedRevision: 25773 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spp_swp_tplot.pro $
;--------------------------------------------------------------------


pro spp_swp_tplot,name,ADD=ADD,setlim=setlim

if keyword_set(setlim) then begin
  options, '*spp*sp[a,b]*SPEC', spec = 1
  zlim, '*spp*sp[a,b]*SPEC', 1,1,1
  options,'spp_*AF*_SPEC' , spec=1
  options,'*MASK',tplot_routine='bitplot'
  options,'*_FLAGS',tplot_routine='bitplot'
  options,'*_FLAG',tplot_routine='bitplot'
  options,'*_BITS',tplot_routine='bitplot'
  tplot_options,'no_interp',1
;  options,'*SPEC23',panel_size=3
  options,'*rates*CNTS',spec=1,zrange=[.8,1e3],/zlog,yrange=[0,0],ylog=0
;  options,'*rates*CNTS',spec=0,yrange=[1,1],ylog=1
  options,'*hkp_HV_MODE',tplot_routine= 'bitplot'
  options,'*TEMPS',/ynozero
  options,'*events*',psym=3
  options,'manip_YAW_POS',ytitle='YAW (deg)'
  options,'manip_ROT_POS',ytitle='ROT (deg)'
  options,'manip_LIN_POS',ytitle='LIN (cm)'
  options,'Igun_VOLTS',ytitle='Energy (eV)'
  options,'Igun_CURRENT',ytitle ='Ie- (uA)'
  options,'*ACT_FLAG',colors='ddgrgrbb'
  options,'spp_spi_hkp_DAC_DEFL',ytitle='DEFL (dac)'
  options,'*NRG_SPEC',spec=1
  options,'*DEF_SPEC',spec=1
  options,'*tof_TOF',spec=1
  options,'spp_event_log_CODE',psym=4,symsize=.1
  
  options,'*_MSG',tplot_routine='strplot'


  ;tplot,var_label=tnames('manip*_POS *DAC_DEFL Igun_VOLTS Igun_CURRENT')
  !y.style=3
  dprint,setd=2
  store_data,'APID',data='APIDS_*'
  ylim,'APID',820,960
  options,'APID',panel_size=2.5
  if setlim eq 2 then begin
    
  endif
  
  
endif


if keyword_set(name) then begin
  
  plot_name =  strupcase(strtrim(name,2)) 
  case plot_name of
    'CMDCTR': tplot,'*swem_dhkp_SW_CMDCOUNTER *CMD_REC *CMDS_REC',add=add
    'SE':   tplot,'*sp?_AF0_ANODE_SPEC *sp?_AF1_*_SPEC spp_sp?_hkp_MRAM_*',ADD=ADD
    'SE_HV': tplot,'*sp?_hkp_ADC_VMON_* *sp?_hkp_ADC_IMON_*',ADD=ADD
    'SA_SUM' : tplot, 'spp_spa_hkp_HV_CONF_FLAG spp_spa_SF1_CNTS spp_spa_hkp_CMD_REC spp_spa_SF1_NRG_SPEC spp_spa_SF0_NRG_SPEC',add=add
    'SA_HV': tplot,'*CMDCOUNTER *spa_*CMD_REC *spa_hkp_HV_CONF_FLAG *spa_hkp_???_DAC *spa_hkp_ADC_VMON_* *spa_hkp_ADC_IMON_* *spa_*SF1_ANODE_SPEC',ADD=ADD
    'SB_HV': tplot,'*CMDCOUNTER *spb_*CMD_REC *spb_hkp_HV_CONF_FLAG *spb_hkp_???_DAC *spb_hkp_ADC_VMON_* *spb_hkp_ADC_IMON_* *spb_*SF1_ANODE_SPEC',ADD=ADD
    'SAB_HV': tplot,'*CMDCOUNTER *sp[ab]_*CMD_REC *sp[ab]_hkp_HV_CONF_FLAG *sp[ab]_hkp_???_DAC *sp[ab]_hkp_ADC_VMON_* *sp[ab]_hkp_ADC_IMON_* *sp[ab]_*SF1_ANODE_SPEC',ADD=ADD
    'SC_HV': tplot,'spp_spc_hkp_ADC*',add=add
    'SE_LV': tplot,'*sp?_hkp_RIO*',ADD=ADD
    'SE_SPEC': tplot,'*spa_*ADC_VMON_HEM *spa_SF0_CNTS *spa_*SF1_ANODE_SPEC spp_spa_SF1_NRG_SPEC', ADD=ADD
    'SA_SPEC': tplot, '*spa_SF?_CNTS spp_spa_SF?_NRG_SPEC spp_spa_SF?_DEF_SPEC', ADD=ADD
    'SB_SPEC': tplot, '*spb_SF?_CNTS spp_spb_SF?_NRG_SPEC spp_spb_SF?_DEF_SPEC', ADD=ADD
;    'SB_SPEC': tplot, 'spp_spb_hkp_ADC_VMON_HEM spp_spb_SF0_CNTS spp_spb_SF1_ANODE_SPEC spp_spb_SF1_NRG_SPEC', ADD=ADD
    'SE_A_SPEC': tplot,'*spa_*ADC_VMON_HEM *spa_AF0_CNTS *spa_*AF1_ANODE_SPEC spp_spa_AF1_NRG_SPEC spp_spa_AT0_CNTS spp_spa_AT1_ANODE_SPEC spp_spa_AT1_NRG_SPEC spp_spa_AT1_PEAK_BIN', ADD=ADD
    'SA_A_SPEC': tplot, '*spa_*ADC_VMON_HEM *spa_AF0_CNTS *spa_*AF1_ANODE_SPEC spp_spa_AF1_NRG_SPEC spp_spa_AT0_CNTS spp_spa_AT1_ANODE_SPEC spp_spa_AT1_NRG_SPEC spp_spa_AT1_PEAK_BIN', ADD=ADD
    'SB_A_SPEC': tplot, 'spp_spb_hkp_ADC_VMON_HEM spp_spb_AF0_CNTS spp_spb_AF1_ANODE_SPEC spp_spb_AF1_NRG_SPEC spp_spb_AT0_CNTS spp_spb_AT1_ANODE_SPEC spp_spb_AT1_NRG_SPEC spp_spb_AT1_PEAK_BIN', ADD=ADD
    'SI_RATE': tplot,'*rate*CNTS',ADD=ADD 
    'SI_RATE1': tplot,'*rates_'+strsplit(/extract,'VALID_* STARTS_* STOPS_*'),add=add
;    'SI_RATE1': tplot,'*rates_'+strsplit(/extract,'VALID_* MULTI_* STARTS_* STOPS_*'),add=add
    'SI_AF0?_1': tplot,'*spani_ar_full_p0_m?_*_SPEC1',add=add
    'SI_HV2': tplot,'*CMDCOUNTER *spi_hkp_HV_CONF_FLAG *spi_hkp_???_DAC *spi_hkp_ADC_VMON_* *spi_hkp_ADC_IMON_*',ADD=ADD
    'SI_MON' : tplot,'*spi_*hkp_MON*',add=add
    'SI_HV' : tplot,['*CMDCOUNTER','*spi_*CMDS_REC','*spi*DACS*','*spi_hkp_HV_MODE','*spi_*' + strsplit(/extract,'RAW_? MCP_? ACC_?')],add=add
    'MANIP':tplot,'manip*_POS',add=add
    'SI_GSE': tplot,add=add,'Igun_* APS3_*'
    'SI': tplot,add=add,'Igun_* manip_*POS *rates_VAL*CNTS *rates_*NO*CNTS '
    'SI_SCAN':tplot,add=add,'*MCP_V *MRAM* *spi_AF0?_NRG_SPEC'
    'SC':  tplot,'spp_*spc*',ADD=ADD
    'ACT': tplot,'spp*_ACT_FLAG spp_*SP?_22_C
    'SI_COVER': tplot, '*spi*CMD*REC spp_spi_*_ACT_FLAG spp_*SPI_22_C spp_spi_hkp*ANAL_TEMP', add = add
    'SA_COVER': tplot, '*spa*CMD*REC spp_spa_*_ACT_FLAG spp_*SPA_22_C spp_spa_hkp*ANAL_TEMP', add = add
    'SB_COVER': tplot, '*spb*CMD*REC spp_spb_*_ACT_FLAG spp_*SPB_22_C spp_spb_hkp*ANAL_TEMP', add = add
    'SB_COVER': tplot, '*spb_*ACT*CVR* *spb_*ACTSTAT*FLAG *spb*CMD*REC', add = add
 ;   'SA_COVER': tplot, '*spa_*ACT*CVR* *spa_*ACTSTAT*FLAG *spa*CMD*REC', add = add
    'SWEM': tplot,'spp_swem_dhkp_*WRADDR APID spp_swem_dhkp_SW_CMDCOUNTER',add=add
    'SWEM2': tplot,'spp_swem_dhkp_SW_OSCPUUSAGE spp_event_log_BRATE spp_event_log_CODE spp_swem_dhkp_SW_SSRWRADDR APID spp_swem_dhkp_SW_CMDCOUNTER',add=add
    'TIMING': tplot,'spp_swem_timing_'+['TIME_DELTA','SAMPLE_MET_DELTA','DRIFT_DELTA','CLKS_PER_PPS_DELTA'],add=add
    'TEMP': tplot,'*TEMP',add=add
    'TEMPS': tplot,'*ALL_TEMPS',add=add
    'CRIT':tplot,'*SF1_ANODE_SPEC *ACC_? *22_C *HVOUT *RAIL*',add=add
    'SPE_QL': tplot, 'spp_spa_hkp_CMD_REC spp_spb_hkp_CMD_REC spp_spa_hkp_HV_CONF_FLAG spp_spb_hkp_HV_CONF_FLAG spp_spa_SF1_CNTS spp_spb_SF1_CNTS spp_spa_SF1_NRG_SPEC spp_spb_SF1_NRG_SPEC spp_spa_SF0_NRG_SPEC spp_spb_SF0_NRG_SPEC', add = add
    'SPI_QL' : tplot,['*CMDCOUNTER','*spi_*CMDS_REC','*spi_hkp_HV_MODE','*spi_*' + strsplit(/extract,'RAW_? MCP_? ACC_?'),'*rate*CNTS'],add=add

    else:
  endcase
  wshow,i=0,0
endif
  
end
