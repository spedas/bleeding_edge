pro spp_swp_spane_tplot,name,ADD=ADD,setlim=setlim

  if keyword_set(setlim) then begin
    options,'spp_*AF*_SPEC' , spec=1
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
     'SE':   tplot,'*sp?_AF0_ANODE_SPEC *sp?_AF1_*_SPEC spp_sp?_hkp_MRAM_*',ADD=ADD
     'SE_HV': tplot,'*sp?_hkp_ADC_VMON_* *sp?_hkp_ADC_IMON_*',ADD=ADD
     'SE_LV': tplot,'*sp?_hkp_RIO*',ADD=ADD
     'SA_SPEC': tplot, '*spa_*ADC_VMON_HEM *spa_AF0_CNTS *spa_*AF1_ANODE_SPEC spp_spa_AF1_NRG_SPEC spp_spa_AT0_CNTS spp_spa_AT1_ANODE_SPEC spp_spa_AT1_NRG_SPEC spp_spa_AT1_PEAK_BIN', ADD=ADD
     'SB_SPEC': tplot, 'spp_spb_hkp_ADC_VMON_HEM spp_spb_AF0_CNTS spp_spb_AF1_ANODE_SPEC spp_spb_AF1_NRG_SPEC spp_spb_AT0_CNTS spp_spb_AT1_ANODE_SPEC spp_spb_AT1_NRG_SPEC spp_spb_AT1_PEAK_BIN', ADD=ADD
     'SI_RATE': tplot,'*rate*CNTS',ADD=ADD
     'SI_RATE1': tplot,'*rates_'+strsplit(/extract,'VALID_* MULTI_* STARTS_* STOPS_*'),add=add
     'SI_AF0?_1': tplot,'*spani_ar_full_p0_m?_*_SPEC1',add=add
     'SI_MON' : tplot,'*spi_*hkp_MON*',add=add
     'SI_HV' : tplot,'*spi_*' + strsplit(/extract,'RAW_? MCP_? ACC_?'),add=add
     'MANIP':tplot,'manip*_POS',add=add
     'SI_GSE': tplot,add=add,'Igun_* APS3_*'
     'SI': tplot,add=add,'Igun_* manip_*POS *rates_VAL*CNTS *rates_*NO*CNTS '
     'SI_SCAN':tplot,add=add,'*MCP_V *MRAM* *spi_AF0?_NRG_SPEC'
     'SC':  tplot,'spp_*spc*',ADD=ADD
     'SI_COVER': tplot, '*spi_*ACT*CVR* *spi_*ACTSTAT*FLAGS *spi*CMD*UKN* *spi*CLK*NYS', add = add
     'SB_COVER': tplot, '*spb_*ACT*CVR* *spb_*ACTSTAT*FLAG* *spb*CMD*UKN* *spb*CLK*NYS', add = add
     'SA_COVER': tplot, '*spa_*ACT*CVR* *spa_*ACTSTAT*FLAG* *spa*CMD*UKN* *spa*CLK*NYS', add = add
     'SWEM': tplot,'APID PTP_DATA_RATE',add=add
     'SWEM_START': tplot, 'spp_swem_ahkp_SPB_22_TEMP spp_swem_ahkp_SPA_22_TEMP spp_swem_ahkp_SPI_22_TEMP spp_swem_crit_SEQN', add = add
     'TIMING': tplot,'spp_swem_timing_'+['DRIFT_DELTA','CLKS_PER_PPS_DELTA','SCSUBSECSATPPS']      
     'DEF_SPEC': tplot, '*sp?_*AF0*ANODE*SPEC *sp?_*AF1*ANODE*SPEC* *sp?_*AF1*NRG*SPEC *sp?_*AF1*DEF*SPEC', add = add
     'MRAM': tplot, '*spa*MRAM* *spb*MRAM*', add = add
     'GUNS': tplot, '*gun*', add = add
     else:
    endcase
  endif

end
