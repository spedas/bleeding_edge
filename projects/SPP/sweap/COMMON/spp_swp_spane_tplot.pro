;--------------------------------------------------------------------
; PSP SPAN-E TPLOT ROUTINE
;
; $LastChangedBy: phyllisw2 $
; $LastChangedDate: 2018-10-02 16:22:01 -0700 (Tue, 02 Oct 2018) $
; $LastChangedRevision: 25887 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/COMMON/spp_swp_spane_tplot.pro $
;--------------------------------------------------------------------

pro spp_swp_spane_tplot,name,ADD=ADD,setlim=setlim

  if keyword_set(setlim) then begin
    options,'*ACT_FLAG',colors='ddgrgrbb'
    options,'spp_*AF*_SPEC' , spec=1
    options, '*spp*sp[a,b]*SPEC', spec = 1
    zlim, '*spp*sp[a,b]*SPEC', 1,1,1
    options,'*MASK',tplot_routine='bitplot'
    options,'*_FLAG',tplot_routine='bitplot'
    tplot_options,'no_interp',1
    ;  options,'*SPEC23',panel_size=3
    options,'*rates*CNTS',spec=1,zrange=[1,1],/zlog,yrange=[0,0],ylog=0 
    options,'*rates*CNTS',spec=0,yrange=[1,1],ylog=1
    options,'*hkp_HV_MODE',tplot_routine= 'bitplot'
    options,'*TEMPS',/ynozero
    options,'*events*',psym=3
    options,'manip_YAW_POS',ytitle='YAW (deg)'
    options,'manip_ROT_POS',ytitle='ROT (deg)'
    options,'manip_LIN_POS',ytitle='LIN (cm)'
    options,'Igun_VOLTS',ytitle='Energy (eV)'
    options,'Igun_CURRENT',ytitle ='Ie- (uA)'
    options,'spp_spi_hkp_DAC_DEFL',ytitle='DEFL (dac)'

    tplot,var_label=tnames('manip*_POS *DAC_DEFL Egun_VOLTS Egun_CURRENT')
    !y.style=3
    dprint,setd=3


  endif


  if keyword_set(name) then begin

    plot_name = strupcase(strtrim(name,2))
    case plot_name of
     'SPEHV': tplot, '*sp[a,b]*MCP* *sp[a,b]*RAW*', add = add
     'SWEMC': tplot, 'spp_swem_ahkp_SPC_22_C spp_swem_ahkp_SPB_22_C spp_swem_ahkp_SPA_22_C spp_swem_ahkp_SPI_22_C', add = add
     'SUMPLOT': tplot, 'spp_spa_hkp_CMD_REC spp_spb_hkp_CMD_REC spp_spa_hkp_HV_CONF_FLAG spp_spb_hkp_HV_CONF_FLAG spp_spa_SF1_CNTS spp_spb_SF1_CNTS spp_spa_SF1_NRG_SPEC spp_spb_SF1_NRG_SPEC spp_spa_SF0_NRG_SPEC spp_spb_SF0_NRG_SPEC', add = add
     'SUMPLOTSA' : tplot, 'spp_spa_hkp_HV_CONF_FLAG spp_spa_SF1_CNTS spp_spa_hkp_CMD_REC spp_spa_SF1_ANODE_SPEC spp_spa_SF0_NRG_SPEC', add = add 
     'SUMPLOTSB' : tplot, 'spp_spb_hkp_HV_CONF_FLAG spp_spb_SF1_CNTS spp_spb_hkp_CMD_REC spp_spb_SF1_ANODE_SPEC spp_spb_SF0_NRG_SPEC', add = add 
     'HVRAMP' : tplot, 'spp_spa_hkp_ADC_VMON_MCP spp_spa_hkp_ADC_IMON_MCP spp_spa_hkp_ADC_VMON_RAW spp_spa_hkp_ADC_IMON_RAW', add = add 
     'SE':   tplot,'*sp?_SF1_ANODE_SPEC *sp?_SF1_*_SPEC spp_sp?_hkp_MRAM_*',ADD=ADD
     'SE_HV': tplot,'*sp?_hkp_ADC_VMON_* *sp?_hkp_ADC_IMON_*',ADD=ADD
     'SE_LV': tplot,'*sp?_hkp_RIO*',ADD=ADD
     'SA_SPEC': tplot, '*spa_*ADC_VMON_HEM *spa_*SF0*_CNTS *spa_*AF1_ANODE_SPEC spp_spa_AF1_NRG_SPEC spp_spa_AT0_CNTS spp_spa_AT1_ANODE_SPEC spp_spa_AT1_NRG_SPEC spp_spa_AT1_PEAK_BIN', ADD=ADD
     'SB_SPEC': tplot, 'spp_spb_hkp_ADC_VMON_HEM spp_spb_AF0_CNTS spp_spb_AF1_ANODE_SPEC spp_spb_AF1_NRG_SPEC spp_spb_AT0_CNTS spp_spb_AT1_ANODE_SPEC spp_spb_AT1_NRG_SPEC spp_spb_AT1_PEAK_BIN', ADD=ADD
     'MANIP':tplot,'manip*_POS',add=add
     'SC':  tplot,'spp_*spc*',ADD=ADD
     'SB_COVER': tplot, '*spb_*ACT*CVR* *spb_*ACT*FLAG* *spb*CMD*UKN* *spb*CLK*NYS', add = add
     'SA_COVER': tplot, '*spa_*ACT*CVR* *spa_*ACT*FLAG* *spa*CMD*UKN* *spa*CLK*NYS', add = add
     'SWEM': tplot,'APID PTP_DATA_RATE',add=add
     'SWEM_START': tplot, 'spp_swem_ahkp_SPB_22_TEMP spp_swem_ahkp_SPA_22_TEMP spp_swem_ahkp_SPI_22_TEMP spp_swem_crit_SEQN', add = add
     'TIMING': tplot,'spp_swem_timing_'+['DRIFT_DELTA','CLKS_PER_PPS_DELTA','SCSUBSECSATPPS']      
     'DEF_SPEC': tplot, '*sp?_*AF0*ANODE*SPEC *sp?_*AF1*ANODE*SPEC* *sp?_*AF1*NRG*SPEC *sp?_*AF1*DEF*SPEC', add = add
     'MRAM': tplot, '*spa*MRAM* *spb*MRAM*', add = add
     'GUNS': tplot, '*gun*', add = add
     'MONITOR': tplot, 'spp_spa_hkp_CMD_REC spp_spa_hkp_ACT_FLAG spp_spa_hkp_HV_CONF_FLAG spp_spa_SF1_ANODE_SPEC spp_spa_ST1_ANODE_SPEC spp_spb_hkp_CMD_REC spp_spb_hkp_HV_CONF_FLAG spp_spb_hkp_ACT_FLAG spp_spb_SF1_ANODE_SPEC spp_spb_ST1_ANODE_SPEC', add = add
     'TEMP' : tplot, '
     else:
    endcase
  endif

end
