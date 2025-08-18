; $LastChangedBy: rjolitz $
; $LastChangedDate: 2025-03-04 10:57:07 -0800 (Tue, 04 Mar 2025) $
; $LastChangedRevision: 33161 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_tplot.pro $

; This routine will set appropriate limits for tplot variables and then make a tplot

pro swfo_stis_tplot,name,add=add,setlim=setlim,ionlim=ionlim,eleclim=eleclim,powerlim=powerlim


  if keyword_set(ionlim) then begin
    store_data,'IG_GUN_I',data='iongun_GUN_I*'
    store_data,'IG_GUN_V',data='iongun_GUN_V*'
    store_data,'IG_STEERER',data='iongun_STEERER*'
    store_data,'IG_EXB',data='iongun_EXB*'
    store_data,'IG_LENS',data='iongun_LENS*'
    store_data,'IG_HDEF',data='iongun_HDEF*'
    store_data,'Vac_Pressure',data='gp37_vg_???',dlim={yrange:[1e-7,1e-3],ylog:1}
    store_data,'Beam_Current',data='gse_kpa-?_F1',dlimit={yrange:[1e-13,1e-7],ylog:1,ystyle:3,neg_colors:'r'}
    options,'gp37_vg_??1',colors='b'
    options,'gp37_vg_??2',colors='r'
    options,'iongun_*_CTL_V' , colors = 'r'
    options,'gse_kpa-?_F1',/default,neg_colors='r',/ylog,yrange=[1e-13,1e-6],ystyle=3
    options,'gse_kpa-1_F1',/default,colors='b'
    options,'gp37_vg_IG?',max_value=1000.,/ylog
    options,'gse_cntr_FREQ',yrange=[1.,1.],/ylog,max_value=1e10
    ylim,'stis_???_SPEC_??',0,100,0
  endif

  if keyword_set(eleclim) then begin
    store_data,'Vac_Pressure',data='gp37_vg_???',dlim={yrange:[1e-6,1e-4],ylog:1}
    options,'gp37_vg_??1',colors='b'
    options,'gp37_vg_??2',colors='r'
    options,'gp37_vg_IG?',max_value=1000.,/ylog
    options,'hvs_5_VOLTAGE',neg_colors='r',yrange=[0,42000.]
    options,'hvs_5_CURRENT',yrange = [1e-7,1e-4],/ylog
    options,'stis_l1a_SPEC_??',yrange=[0,100],ylog=0
  endif


  if keyword_set(powerlim) then begin
    ;store_data,'PS_Current',data= 'KEYSIGHT2__I[23]
    ;store_data,'PS_Voltage',data= 'KEYSIGHT2__V[23]
    store_data,'PS_Current',data= 'ks_psu_1_CH[23]_CURRENT'
    store_data,'PS_Voltage',data= 'ks_psu_1_CH[23]_VOLTAGE'
    options,'ks_psu_1_CH2_*' , colors = 'r'
    options,'ks_psu_1_CH3_*' , colors = 'b'
    
  endif


  if keyword_set(setlim) then begin
    if 0 then begin
      nse = swfo_apdat('stis_nse')
      s = nse.struct()
      data= s.data
      data_1a = s.level_1a
      if 0 then data_1a.array = swfo_stis_nse_level_1(data.array)
      store_data,'SWFO_stis_nse_L0',data=data,tagnames = '*'
      options,'SWFO*nse_L0_NHIST',spec=1,zlog=1,yrange=[0,60],constant=findgen(6)*10+4.5,panel_size=5,/no_interp
      store_data,'SWFO_stis_nse_L1',data=data_1a,tagnames='baseline sigma tot *res *per'
      options,'SWFO*L1_BASELINE',constant=0.,colors='bgrmcd'
      options,'SWFO*L1_SIGMA',constant=0.,colors='bgrmcd'
      options,'SWFO*L1_NOISE_RES',yrange=[0,7]
      options,'*DECIMATION_FACTOR_BITS',panel_size=.5
      options,'*SPEC_??',panel_size=1.5
      ;tplot,'SWFO*L1*',/add
    endif

    ylim,'stis_l1a_SPEC*',10,20000.,1
    duration=tnames('swfo_stis_*_DURATION')
    cmds_bad='swfo_stis_hkp1_CMDS_'+['IGNORED','INVALID','UNKNOWN']
    store_data,'swfo_stis_DURATION',data=duration,dlim={labels:duration.substring(10,13),labflag:-1,colors:'rgbk',psym:-1}
    store_data,'swfo_stis_hkp1_CMDS_BAD',data=cmds_bad,dlim={labels:cmds_bad.substring(20),labflag:-1,colors:'rgb',psym:-1}
    store_data,'swfo_stis_RATES_PULSFREQ',data='swfo_stis_'+['sci_RATE6','nse_RATE_DIV_SIX','hkp2_'+['VALID_RATES_PPS','PULSER_FREQUENCY']],dlim={panel_size:3,yrange:[.5,7e5],ylog:1}
    store_data,'swfo_stis_RATES_TOTAL',data='swfo_stis_'+['hkp2_SCIENCE_EVENTS','hkp2_VALID_RATES_TOTAL','sci_TOTAL','sci_RATE2'],dlim={labflag:-1}
    store_data,'swfo_stis_hkp1_RATES_ALL',data=tnames('*hkp1*RATES'),dlim={yrange:[1,7e5],ylog:1}
    store_data,'swfo_stis_hkp2_RATES_ALL',data=tnames('*hkp2*RATES'),dlim={yrange:[1,7e5],ylog:1}
    store_data,'swfo_SEQN_DELTAS',data='swfo_*_SEQN_DELTA',dlim={ylog:1}
    store_data,'swfo_DELAYTIMES',data='swfo_*_DELAYTIME'
    options,/def,'*_BITS *USER_0A',tplot_routine='bitplot',psyms=1
    options,/def,'*nse_HISTOGRAM',spec=1,panel_size=2,/no_interp,/zlog,constant=findgen(6)*10+5;,zrange=[10,4000.]
    options,/def,'*memdump_DATA',spec=1
    options,/def,'*sci_COUNTS',spec=1,panel_size=3,/no_interp,/zlog,zrange=[1,4000.],constant=findgen(15)*48
    options,/def,'*hkp?_ADC_*',constant=0.
    channels=['CH1','CH2','CH3','CH4','CH5','CH6']
    options,/def,'*hkp?_*RATES* *nse_BASELINE *nse_SIGMA',colors='bgrmcd',psym=-1,symsize=.5,labels=channels,labflag=-1,constant=0
    options,/def,'*hkp?_*RATES*',constant=2.^(indgen(4)+16)
    options,/def,'*hkp?_NEGATIVE_PULSE_RATES',labels='total_neg',psym=-2,symsize=1
    options,/def,'*sci_TOTAL *sci_RATE',colors='r',psym=6,symsize=.5,labels='SCI'
    options,/def,'*sci_TOTAL2 *sci_RATE2',colors='m',labels='SCI2'
    options,/def,'*sci_TOTAL14 *sci_RATE14',spec=1,zlog=1,no_interp=1
    options,/def,'*sci_SIGMA14',ylog=1
    ylim,/def,'*sci_RATE6',.1,5e6,1
    options,/def,'*_RATE6',symsize=.2
    options,/def,'*sci_*14',psym=-1,labels=['CH1','CH4','CH2','CH5','CH12','CH45','CH3','CH6','CH13','CH46','CH23','CH56','CH123','CH456'],labflag=1
    options,/def,'*nse_TOTAL *nse_RATE*',colors='r',psym=-2,symsize=.5,labels='NOISE'
    options,/def,'*TOTAL6* *RATE6*',colors='bgrmcd',psym=-6,symsize=.5,labels=channels,labflag=-1
    options,/def,'*_SCALED_RATE6*',constant=[.5,1]
    options,/def,'*hkp?_VALID_RATES_TOTAL',colors='b',psym=-1,symsize=.1,labels='HKP'
    options,/def,'*hkp?_SCIENCE_EVENTS',labels='EVENTS'
    options,/def,'*hkp?_EDAC_ERRORS',colors='bcrmgk',labels=['nse2','nse1','cmd_rec2','cmd_rec1','cmd_fifo2','cmd_fifo1','sci_B2','sci_B1','sci_A2','sci_A1'],labflag=-1
    options,/def,'*hkp?_STATE_MACHINE_ERRORS',panel_size=2,colors='bcrmgk',labels=['cmd','cmd_state','arb','cksm','da','dac','hk','tx','pha','noi','det','scope','noimgr'],labflag=-1
    options,/def,'*hkp?_BUS_TIMEOUT_COUNTERS',colors='bgrk',labels=['memfill','telemetry','event','noise'],labflag=-1
    options,/def,'*hkp?_ADC_BASELINES',colors='bgrmcd',labels=channels,labflag=-1
    options,/def,'*hkp?_ADC_VOLTAGES',colors='bgrmc',labels=['1.5VD','3.3VD','5VD','+5.6VA','-5.6VA'],labflag=-1,constant=[0,1.5,3.3,5,-5]
    options,/def,'*hkp?_ADC_TEMPS',colors='bgr',labels=['DAP','Sensor 1','Sensor 2'],labflag=-1
    dacs=['CH1 thresh','CH2 thresh','CH3 thresh','Baseline','CH4 thresh','CH5 thresh','CH6 thresh','AUX2','CH1-4 pulse height','CH2-5 pulse height','CH3-6 pulse height','Bias Voltage Control']
    options,/def,'*hkp?_DAC_VALUES',panel_size=2,yrange=[0,'ffff'x],colors='bgrmmcdcbgrk',labels=dacs,labflag=-1
    options,/def,'*hkp2_DAC_VALUES',yrange=[0,300]
    options,/def,'*PTCU_BITS',numbits=4,labels=reverse(['P=PPS Missing','T=TOD Missing','C=Compression','U=Use LUT']),colors=[0,1,2,6]
    options,/def,'*AAEE_BITS',numbits=4,labels=reverse(['Attenuator IN','Attenuator OUT','Checksum Error 1','Checksum Error 0']),colors=[0,1,2,6]
    options,/def,'*PULSER_BITS',labels=reverse(['LUT 0:Lower 1:Upper','Pulser Enable',reverse(channels)]),colors='bgrbgrkm'
    options,/def,'*DETECTOR_BITS',labels=reverse(['Decimate','NONLUT 0:Log 1:Linear',reverse(channels)]),colors='bgrbgrcm'
    options,/def,'*DECIMATION_FACTOR_BITS',labels=['CH2','CH2','CH3','CH3','CH5','CH5','CH6','CH6'],colors='ggrrcckk'
    options,/def,'*hkp?_VALID_ENABLE_MASK_BITS',numbits=6,labels=channels,colors='bgrmcd'
    options,/def,'*hkp?_DIGI_FILTER_CLOCK_CYCLES',colors='br',labels=['Valid_Sig to Valid_En','Valid_En to Peak_En'],labflag=-1
    options,/def,'*hkp?_PULSER_DELAY_CLOCK_CYCLES',colors='bgr',labels=['0x17 Pulser1','0x18 Pulser2','0x19 Pulser3'],labflag=1
    options,/def,'*hkp?_TIMEOUTS_*US',colors='bgr',labels=['0x1D Event','0x1E Valid','0x1F Nopeak'],labflag=-1
    options,/def,'*NOISE_BITS',numbits=12,labels=reverse(['ENABLE','RES2','RES1','RES0','PERIOD7','PERIOD6','PERIOD5','PERIOD4','PERIOD3','PERIOD2','PERIOD1','PERIOD0']),colors=[0,1,2,6]
    options,/def,'*swfo_sc_120_INSTRUMENT_*',colors='bgrk',labels=['STIS','CCOR','MAG','SWiPS'],labflag=1,numbits=4
    options,/def,'*swfo_sc_1?0_REACTION_WHEEL_*',colors='bgrk',labels=['1','2','3','4'],labflag=1,numbits=4,constant=0
    options,/def,'*swfo_sc_100_REACTION_WHEEL_OVERSPEED_FAULT_BITS',colors='krgb',labels=reverse(['O1','O2','O3','O4','F1','F2','F3','F4']),numbits=8
    options,/def,'*swfo_sc_110_REACTION_WHEEL_XYZ_TORQUE_ACTUAL_NM',labels=['X','Y','Z']
    options,/def,'*swfo_sc_110_IRU_BITS',labels=reverse(['Misalignment Bypass','Memory Effect Error','X Health','Y Health','Z Health','X Valid','Y Valid','Z Valid']),colors='rgbrgbmc'
    options,/def,'*swfo_sc_100_FSW_POWER_MANAGEMENT_BITS',colors='rgb',labels=reverse(['Battery OverTemp Enable','OverVoltage Enable','UnderVoltage Enable','Battery OverTemp Latched','Overvoltage Latched','UnderVoltage Latched']),numbits=6
    options,/def,'*swfo_sc_120_SUBSYSTEM_*',numbits=6,labels=reverse(['Gimbal Control Electronics','S-Band Transmitter','TWTA','X-Band Modulator','Star Tracker Electronics','IRU']),colors='rgbkmc',labflag=1
    options,/def,'*swfo_sc_120_????_POWER_BITS',numbits=5,labels=reverse(['Power','OC Trip','OC Enable','SH Power','SH OC Trip']),colors=[0,1,2,6]
    options,/def,'*swfo_sc_120_MAG_POWER_BITS swfo_sc_120_SWIPS_POWER_BITS',numbits=6,labels=reverse(['Arm Power','Power','OC Trip','OC Enable','SH Power','SH OC Trip']),colors=[0,1,2,6]
    options,/def,'*swfo_sc_130_STIS_TEMPS',colors='br',labels=['Sensor','SEB'],labflag=-1
    options,/def,'*swfo_sc_160_PPS_OUTPUT_STATUS_BITS',numbits=8,labels=reverse(['CCOR','STIS','SWiPS','MAG','Source0','Source1','Internal','External']),colors='rkbg'
    options,/def,'*swfo_sc_160_FLASH_ERROR_COUNTS',colors='bgrymck',labels=['Error Count','No Power','Not Ready','Address','Read','Write','Erase','EDAC DBE'],labflag=-1
    options,/def,'*swfo_sc_160_FLASH_SUCCESSFUL_BLOCK_COUNTS',colors='bgr',labels=['Read','Write','Erase'],labflag=-1
    options,/def,'*swfo_sc_160_FLASH_EDAC_COUNTS',colors='bgrk',labels=['1B Page Buffer','2B Page Buffer','1B Access','2B Access'],labflag=-1
    options,/def,'*AMPS',constant=0
    options,/def,'*IRU_BITS', negate='111111'b
    ylim,'*nse_SIGMA',.5,4,1
    ylim,'*nse_BASELINE',-3,1
    ylim,'*VALID_RATES',1,1,1
    ylim,'*REACTION_WHEEL_CURRENT_AMPS',0.05,3,1
    ylim,'*REACTION_WHEEL_BUS_CURRENT_AMPS',0.05,3,1
    ylim,'*REACTION_WHEEL_CURRENT_AMPS',0.0,.5,0
    ylim,'*REACTION_WHEEL_BUS_CURRENT_AMPS',0.0,.5,0
    options,'*WHEEL* *_nse_* *_hkp*_RATES *nse_SIGMA *nse_BASELINE',/reverse_order

    options,'swfo_*',ystyle=3
    tplot_options,'wshow',0
    tplot_options,'datagap',60
  endif

  if ~keyword_set(name) then name = 'none'
  plot_name = strupcase(strtrim(name,2))
  case plot_name of
    'SUM1': tplot,add=add,'*hkp1_USER_0A *hkp1_STATE_MACHINE_ERRORS *DURATION_ALL *hkp1_PPS_* *hkp?_DAC_* *_RATES_PULSFREQ *sci_RATE14 *sci_SIGMA14 *sci_AVGBIN14 *nse_HISTOGRAM *nse_BASELINE *nse_SIGMA *nse_*RATE6 *hkp1_CMDS_RECEIVED *hkp1_CMDS_BAD *hkp1_*REMAIN* *hkp1_*BITS *hkp1_*CYCLES *hkp1_TEST_PULSE_WIDTH_1US *hkp1_COINCIDENCE_WINDOW* *hkp1_BIAS_CLOCK_PERIOD_2US *hkp1_ADC_*'
    'SUM2': tplot,add=add,'*hkp2_STATE_MACHINE_ERRORS *hkp?_DAC_* swfo_stis_RATES_TOTAL *hkp2_*RATES *_RATES_PULSFREQ *sci_RATE14 *sci_SIGMA14 *sci_AVGBIN14 *nse_HISTOGRAM *nse_BASELINE *nse_SIGMA *nse_*RATE6 *hkp2_CMDS_RECEIVED *hkp2_*BITS *hkp2_*CYCLES *hkp2_TEST_PULSE_WIDTH_1US *hkp2_COINCIDENCE_WINDOW* *hkp2_BIAS_CLOCK_PERIOD_2US *hkp2_ADC_*'
    'SUM3': tplot,add=add,'*hkp2_*CYCLES *hkp2_BIAS_CLOCK_PERIOD_2US *sci_DECI* *sci_USER_09 *hkp2_COINCIDENCE_WINDOW* *hkp2_TIMEOUTS_2US *hkp?_DAC_* swfo_stis_RATES_TOTAL *hkp2*RATES *_RATES_PULSFREQ *sci_RATE14 *sci_SIGMA14 *sci_AVGBIN14 *nse_HISTOGRAM *nse_BASELINE *nse_SIGMA *nse_*RATE6 *hkp2_CMDS_EXECUTED2 *hkp2_CMD_PACKETS_RECEIVED'
    'NOISE': tplot,add=add,'s*nse_HISTOGRAM s*nse_BASELINE s*nse_SIGMA s*nse_*RA_TE6'
    'NOISE2': tplot,add=add,'s*nse_HISTO_GRAM s*nse_BASELINE s*nse_SIGMA s*hkp2_VALID_RATES s*sci_RATE6'
    'SCI': tplot,add=add,'*sci_COUNTS *sci_RATE14 *sci_SIGMA14 *sci_AVGBIN14'
    'ADC': tplot,add=add,'*hkp2_ADC*'
    'ERRORS' : tplot,add=add,'*hkp2*ERRORS *hkp2_BUS_TIMEOUT_COUNTERS'
    'RATES' : tplot,add=add,'*hkp2_?????_RATES'
    'CMD'   : tplot,add=add,'*hkp2_CMDS_* *hkp2_CMD_PACKETS_RECEIVED'
    'WAIT'  : tplot,add=add,'*hkp1*REMAIN*'
    'DL1':  tplot,add=add,'*sci_RATE6 *nse_HISTOGRAM *nse_SIGMA *nse_BASELINE *hkp1_CMDS_REMAINING *hkp1_CMDS_EXECUTED'
    'DL2':  tplot,add=add,'*sci_RATE6 *nse_SIGMA *nse_BASELINE *hkp1_CMDS_EXECUTED'
    'DL3':  tplot,add=add,'*sci_RATE6 *sci_SCI_* stis_l1a_SPEC_?? *nse_SIGMA *nse_BASELINE *hkp1_CMDS_EXECUTED'
    'DL4':  tplot,add=add,'*sci_RATE6 *hkp2_*BIAS* stis_l1a_SPEC_?? *nse_SIGMA *nse_BASELINE *hkp1_CMDS_EXECUTED'
    'LPT':  tplot,add=add,'*sci_RATE6 *hkp?_DAC_VALUES *sci*COUNTS *hkp3*REMAIN* *hkp1*REMAIN*'
    'SCIHKP': tplot,add=add,'*hkp2*SCI_*'
    'IONGUN': tplot,add=add,'Vac_Pressure gse_kpa-?_F1 IG_* stis_l1a_SPEC_O[13]'
    'IONGUN1': tplot,add=add,'*sci_RATE6 IG_GUN_V stis_l1a_SPEC_O[13]'
    'EGUN' : tplot,add=add,'Vac_Pressure hvs_5*_VOLTAGE hvs_5*_CURRENT *sci_RATE6 stis_l1a_SPEC_F[13] manip_YAW'
    'TV' : tplot,add=add,'*hkp2_ADC_TEMPS *nse_BASELINE *nse_SIGMA *sci_RATE6 *hkp2*EXECUTED2'
    'PS':tplot,add=add,'PS_*'
    'CPT':tplot,add=add,'*_DAC* *FREQ *nse_HISTOGRAM *nse_BASELINE *nse_SIGMA *hkp2_ADC* *hkp2*CM*REMAINING'
    'CPT2':tplot,add=add,'*_DAC* swfo_stis_RATE6 *nse_HISTOGRAM *nse_BASELINE *nse_SIGMA *hkp2_ADC* *hkp2*CM*REMAINING'    
    'SC':tplot,add=add,'swfo_SEQN_DELTAS swfo_DELAYTIMES swfo_sc_100_FSW* swfo_sc_130_STIS_* swfo_sc_120_INSTRUMENT_* swfo_sc_120_SUBSYSTEM_* swfo_sc_*REACTION_WHEEL* swfo_sc_100_BATTERY_*'
    'SC2':tplot,add=add,'swfo_sc_100_FSW* swfo_sc_130_STIS_* swfo_sc_120_INSTRUMENT_* swfo_sc_120_SUBSYSTEM_* *REACTION_WHEEL_*RPM *WHEEL*_AMP *WHEEL*_COMMAND swfo_sc_100_BATTERY_*'
    'TEST':tplot,add=add,'swfo_sc_INST*_CURRENT_AMPS swfo_sc_*WHEEL* *sci_RATE6 *nse_HISTOGRAM *nse_SIGMA *nse_BASELINE *hkp1_CMDS_EXECUTED'
    'DELAY_ALL':tplot,add=add,'*DELAYTIME'
    'DELAY':tplot,add=add,'*2*DELAYTIME'
    'WHEELS': tplot,add=add,'s*WHEEL_TORQUE s*WHEEL_SPEED_RPM s*WHEEL_CURRENT_AMPS s*WHEEL_BUS_CUR* s*IRU_BITS'
    'WHEELS1': tplot,add=add,'s*WHEEL_TOR_QUE s*WHEEL_SPEED_RPM s*WHEEL_BUS_CURRENT_AMPS s*IRU_BITS'
    'WHEEL1':begin
      split_vec,'*WHEEL_SPEED_RPM *WHEEL_CURRENT_AMPS'
      tplot,add=add,'*WHEEL_*_0'
      end
      'WHEEL2':begin
        split_vec,'*WHEEL_SPEED_RPM *WHEEL_CURRENT_AMPS'
        tplot,add=add,'*WHEEL_*_1'
      end
      'WHEEL3':begin
        split_vec,'*WHEEL_SPEED_RPM *WHEEL_CURRENT_AMPS'
        tplot,add=add,'*WHEEL_*_2'
      end
      'WHEEL4':begin
        split_vec,'*WHEEL_SPEED_RPM *WHEEL_CURRENT_AMPS'
        tplot,add=add,'*WHEEL_*_3'
      end
    else: dprint,'Unknown code: '+strtrim(name,2)
  endcase

end

