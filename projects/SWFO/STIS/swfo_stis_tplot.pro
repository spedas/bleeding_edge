; $LastChangedBy: ali $
; $LastChangedDate: 2023-04-28 12:24:11 -0700 (Fri, 28 Apr 2023) $
; $LastChangedRevision: 31812 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_tplot.pro $

; This routine will set appropriate limits for tplot variables and then make a tplot

pro swfo_stis_tplot,name,add=add,setlim=setlim,ionlim=ionlim,powerlim=powerlim

  
  if keyword_set(ionlim) then begin
    store_data,'IG_GUN_I',data='IonGun1_GUN_I*'
    store_data,'IG_GUN_V',data='IonGun1_GUN_V*'
    store_data,'IG_STEERER',data='IonGun1_STEERER*'
    store_data,'IG_EXB',data='IonGun1_EXB*'
    store_data,'IG_LENS',data='IonGun1_LENS*'
    store_data,'IG_HDEF',data='IonGun1_HDEF*'
    options,'IonGun1_*_CTL_V' , colors = 'r'
  endif

  if keyword_set(powerlim) then begin
    store_data,'PS_Current',data= 'KEYSIGHT2__I[23]
    store_data,'PS_Voltage',data= 'KEYSIGHT2__V[23]
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
      tplot,'SWFO*L1*',/add
    endif

    ylim,'stis_l1a_SPEC*',10,20000.,1
    options,/def,'*_BITS *USER_0A',tplot_routine='bitplot'
    options,/def,'*nse_HISTOGRAM',spec=1,panel_size=2,/no_interp,/zlog,constant=findgen(6)*10+5;,zrange=[10,4000.]
    options,/def,'*memdump_DATA',spec=1
    options,/def,'*sci_COUNTS',spec=1,panel_size=3,/no_interp,/zlog,zrange=[1,4000.],constant=findgen(15)*48
    options,/def,'*hkp?_ADC_*',constant=0.
    channels=['CH1','CH2','CH3','CH4','CH5','CH6']
    options,/def,'*hkp?_*RATES* *nse_BASELINE *nse_SIGMA',colors='bgrmcd',psym=-1,symsize=.5,labels=channels,labflag=-1,constant=0
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
    options,/def,'*_SCALED_RATE6*',constant=1
    options,/def,'*hkp?_VALID_RATES_TOTAL',colors='b',psym=-1,symsize=.1,labels='HKP'
    options,/def,'*hkp?_SCIENCE_EVENTS',labels='EVENTS'
    options,/def,'*hkp?_EDAC_ERRORS',colors='bcrmgk',labels=['nse2','nse1','cmd_rec2','cmd_rec1','cmd_fifo2','cmd_fifo1','sci_B2','sci_B1','sci_A2','sci_A1'],labflag=-1
    options,/def,'*hkp?_STATE_MACHINE_ERRORS',panel_size=2,colors='bcrmgk',labels=['cmd','cmd_state','arb','cksm','da','dac','hk','tx','pha','noi','det','scope','noimgr'],labflag=-1
    options,/def,'*hkp?_BUS_TIMEOUT_COUNTERS',colors='bgrk',labels=['memfill','telemetry','event','noise'],labflag=-1
    options,/def,'*hkp?_ADC_BASELINES',colors='bgrmcd',labels=channels,labflag=-1
    options,/def,'*hkp?_ADC_VOLTAGES',colors='bgrmc',labels=['1.5VD','3.3VD','5VD','+5.6VA','-5.6VA'],labflag=-1,constant=[0,1.5,3.3,5,-5]
    options,/def,'*hkp?_ADC_TEMPS',colors='bgr',labels=['DAP','S1','S2'],labflag=-1
    dacs=['CH1 thresh','CH2 thresh','CH3 thresh','Baseline','CH4 thresh','CH5 thresh','CH6 thresh','AUX2','CH1-4 pulse height','CH2-5 pulse height','CH3-6 pulse height','Bias Voltage Control']
    options,/def,'*hkp?_DAC_VALUES',panel_size=2,yrange=[0,'ffff'x],colors='bgrmmcdcbgrk',labels=dacs,labflag=-1
    options,/def,'*hkp2_DAC_VALUES',yrange=[0,300]
    options,/def,'*PTCU_BITS',numbits=4,labels=reverse(['P=PPS Missing','T=TOD Missing','C=Compression','U=Use LUT']),psyms=1,colors=[0,1,2,6]
    options,/def,'*AAEE_BITS',numbits=4,labels=reverse(['Attenuator IN','Attenuator OUT','Checksum Error 1','Checksum Error 0']),psyms=1,colors=[0,1,2,6]
    options,/def,'*PULSER_BITS',labels=reverse(['LUT 0:Lower 1:Upper','Pulser Enable',reverse(channels)]),psyms=1,colors='bgrbgrkm'
    options,/def,'*DETECTOR_BITS',labels=reverse(['Decimate','NONLUT 0:Log 1:Linear',reverse(channels)]),psyms=1,colors='bgrbgrcm'
    options,/def,'*DECIMATION_FACTOR_BITS',labels=['CH2','CH2','CH3','CH3','CH5','CH5','CH6','CH6'],psyms=1,colors='ggrrcckk'
    options,/def,'*hkp?_VALID_ENABLE_MASK_BITS',numbits=6,labels=channels,psyms=1,colors='bgrmcd'
    options,/def,'*hkp?_DIGI_FILTER_CLOCK_CYCLES',colors='br',labels=['Valid_Sig to Valid_En','Valid_En to Peak_En'],labflag=-1
    options,/def,'*hkp?_PULSER_DELAY_CLOCK_CYCLES',colors='bgr',labels=['0x17 Pulser1','0x18 Pulser2','0x19 Pulser3'],labflag=-1
    options,/def,'*hkp?_TIMEOUTS_*US',colors='bgr',labels=['0x1D Event','0x1E Valid','0x1F Nopeak'],labflag=-1
    options,/def,'*NOISE_BITS',numbits=12,labels=reverse(['ENABLE','RES2','RES1','RES0','PERIOD7','PERIOD6','PERIOD5','PERIOD4','PERIOD3','PERIOD2','PERIOD1','PERIOD0']),psyms=1,colors=[0,1,2,6]
    options,/def,'*USER_0A',labels=['BASELINE_OFFSET','NOISE_RES','NOISE_PERIOD','THRESHOLD','PULSER_HEIGHT','BIAS_PERIOD','BIAS_VOLTAGE','DIGITAL_FILTER']+'_SWEEP',psyms=1,colors=[0,1,2,6]
    store_data,'swfo_stis_RATES_PULSFREQ',data='swfo_stis_'+['sci_RATE6','nse_RATE_DIV_SIX','hkp1_'+['VALID_RATES_PPS','PULSER_FREQUENCY']],dlim={panel_size:3,yrange:[.5,7e5],ylog:1,constant:2.^19}
    store_data,'swfo_stis_RATES_TOTAL',data='swfo_stis_'+['hkp2_SCIENCE_EVENTS','hkp2_VALID_RATES_TOTAL','sci_TOTAL','sci_RATE2'],dlim={labflag:-1}
    store_data,'swfo_stis_hkp1_RATES_ALL',data=tnames('*hkp1*RATES'),dlim={yrange:[1,7e5],ylog:1,constant:5e5}
    store_data,'swfo_stis_hkp2_RATES_ALL',data=tnames('*hkp2*RATES'),dlim={yrange:[1,7e5],ylog:1,constant:5e5}
    duration=tnames('swfo_stis_*_DURATION')
    cmds_bad='swfo_stis_hkp1_CMDS_'+['IGNORED','INVALID','UNKNOWN']
    store_data,'swfo_stis_DURATION',data=duration,dlim={labels:duration.substring(10,13),labflag:-1,colors:'rgbk',psym:-1}
    store_data,'swfo_stis_hkp1_CMDS_BAD',data=cmds_bad,dlim={labels:cmds_bad.substring(20),labflag:-1,colors:'rgb',psym:-1}

    options,'swfo_stis_*',ystyle=3
    tplot_options,'wshow',0
  endif

  if ~keyword_set(name) then name = 'sum2'
  plot_name = strupcase(strtrim(name,2))
  case plot_name of
    'SUM1': tplot,add=add,'*hkp1_USER_0A *hkp1_STATE_MACHINE_ERRORS swfo_stis_DURATION *hkp1_PPS_* *hkp?_DAC_* *_RATES_PULSFREQ *sci_RATE14 *sci_SIGMA14 *sci_AVGBIN14 *nse_HISTOGRAM *nse_BASELINE *nse_SIGMA *nse_*RATE6 *hkp1_CMDS_RECEIVED *hkp1_CMDS_BAD *hkp1_*REMAIN* *hkp1_*BITS *hkp1_*CYCLES *hkp1_TEST_PULSE_WIDTH_1US *hkp1_ADC_*'
    'SUM2': tplot,add=add,'*hkp2_STATE_MACHINE_ERRORS *hkp?_DAC_* swfo_stis_RATES_TOTAL *hkp2_*RATES *_RATES_PULSFREQ *sci_RATE14 *sci_SIGMA14 *sci_AVGBIN14 *nse_HISTOGRAM *nse_BASELINE *nse_SIGMA *nse_*RATE6 *hkp2_CMDS_RECEIVED *hkp2_*BITS *hkp2_*CYCLES *hkp2_ADC_*'
    'SUM3': tplot,add=add,'*hkp2_*CYCLES *hkp2_TIMEOUTS_2US *hkp?_DAC_* swfo_stis_RATES_TOTAL *hkp2*RATES *_RATES_PULSFREQ *sci_RATE14 *sci_SIGMA14 *sci_AVGBIN14 *nse_HISTOGRAM *nse_BASELINE *nse_SIGMA *nse_*RATE6 *hkp2_CMDS_EXECUTED2
    'NOISE': tplot,add=add,'*nse_HISTOGRAM *nse_BASELINE *nse_SIGMA *nse_*RATE6'
    'SCI': tplot,add=add,'*sci_COUNTS *sci_RATE14 *sci_SIGMA14 *sci_AVGBIN14'
    'ADC': tplot,add=add,'*hkp1_ADC*
    'ERRORS' : tplot,add=add,'*hkp2*ERRORS *hkp2_BUS_TIMEOUT_COUNTERS'
    'RATES' : tplot,add=add,'*hkp2_?????_RATES'
    'CMD'   : tplot,add=add,'*hkp1_CMDS_*'
    'WAIT'  : tplot,add=add,'*hkp1*REMAIN*'
    'DL1':  tplot,add=add,'*sci*COUNTS *nse_HISTOGRAM *nse_SIGMA *nse_BASELINE swfo_stis_hkp1_CMDS_REMAINING swfo_stis_hkp1_CMDS_EXECUTED'
    'DL2':  tplot,add=add,'*sci_RATE6 *sci*COUNTS *nse_SIGMA *nse_BASELINE swfo_stis_hkp1_CMDS_EXECUTED'
    'DL3':  tplot,add=add,'*sci_RATE6 *sci_SCI_* stis_l1a_SPEC_?? *nse_SIGMA *nse_BASELINE swfo_stis_hkp1_CMDS_EXECUTED'
    'DL4':  tplot,add=add,'*sci_RATE6 *hkp2_*BIAS* stis_l1a_SPEC_?? *nse_SIGMA *nse_BASELINE swfo_stis_hkp1_CMDS_EXECUTED'
    'LPT':  tplot,add=add,'*sci_RATE6 *hkp?_DAC_VALUES *sci*COUNTS *hkp3*REMAIN* *hkp1*REMAIN*'
    'SCIHKP': tplot,add=add,'*hkp2*SCI_*'
    'IONGUN': tplot,add=add,'pico_I IG_*'
    'PS':tplot,add=add,'PS_*'
    
    else: dprint,'Unknown code: '+strtrim(name,2)
  endcase

end

