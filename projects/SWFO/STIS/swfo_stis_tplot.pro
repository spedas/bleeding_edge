; $LastChangedBy: ali $
; $LastChangedDate: 2022-09-16 13:04:38 -0700 (Fri, 16 Sep 2022) $
; $LastChangedRevision: 31093 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_tplot.pro $

; This routine will set appropriate limits for tplot variables and then make a tplot

pro swfo_stis_tplot,name,add=add,setlim=setlim

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

    options,/def,'*_BITS *USER_0A',tplot_routine='bitplot'
    options,/def,'*nse_HISTOGRAM',spec=1,panel_size=2,/no_interp,/zlog,constant=findgen(6)*10+5;,zrange=[10,4000.]
    options,/def,'*memdump_DATA',spec=1
    options,/def,'*sci_COUNTS',spec=1,panel_size=3,/no_interp,/zlog,zrange=[1,4000.],constant=findgen(15)*48
    options,/def,'*hkp?_ADC_*',constant=0.
    channels=['CH1','CH2','CH3','CH4','CH5','CH6']
    options,/def,'*hkp?_DETECTOR_RATES* *nse_BASELINE *nse_SIGMA',colors='bgrmcd',psym=-1,symsize=.5,labels=channels,labflag=-1
    options,/def,'*sci_TOTAL *sci_RATE',colors='r',psym=-6,symsize=.5,labels='SCI',labflag=-1
    options,/def,'*nse_TOTAL *nse_RATE*',colors='r',psym=-2,symsize=.5,labels='NOISE',labflag=-1
    options,/def,'*TOTAL6* *RATE6*',colors='bgrmcd',psym=-6,symsize=.5,labels=channels,labflag=-1
    options,/def,'*hkp?_DETECTOR_RATES_TOTAL',colors='b',psym=-1,symsize=.5,labels='HKP',labflag=-1
    options,/def,'*hkp?_SCIENCE_EVENTS',labels='EVENTS',labflag=-1
    options,/def,'*hkp?_ADC_BASELINES',colors='bgrmcd',labels=channels,labflag=-1
    options,/def,'*hkp?_ADC_VOLTAGES',colors='bgrmc',labels=['1.5VD','3.3VD','5VD','+5.6VA','-5.6VA'],labflag=-1,constant=[0,1.5,3.3,5,-5]
    options,/def,'*hkp?_ADC_TEMPS',colors='bgr',labels=['DAP','S1','S2'],labflag=-1
    dacs=['CH1 thresh','CH2 thresh','CH3 thresh','Baseline','CH4 thresh','CH5 thresh','CH6 thresh','AUX2','CH1-4 pulse height','CH2-5 pulse height','CH3-6 pulse height','Bias Voltage Control']
    options,/def,'*hkp?_DAC_VALUES',panel_size=2,yrange=[0,'ffff'x],colors='bgrmmcdcbgrk',labels=dacs,labflag=-1
    options,/def,'*hkp2_DAC_VALUES',yrange=[0,300]
    options,/def,'*PTCU_BITS',numbits=4,labels=reverse(['P=PPS Missing','T=TOD Missing','C=Compression','U=Use LUT']),psyms=1,colors=[0,1,2,6]
    options,/def,'*AAEE_BITS',numbits=4,labels=reverse(['Attenuator IN','Attenuator OUT','Checksum Error 1','Checksum Error 0']),psyms=1,colors=[0,1,2,6]
    options,/def,'*PULSER_BITS',panel_size=2,labels=reverse(['LUT 0:Lower 1:Upper','Pulser Enable',reverse(channels)]),psyms=1,colors='bgrbgrkm'
    options,/def,'*DETECTOR_BITS',panel_size=2,labels=reverse(['BLR_MODE1','BLR_MODE0',reverse(channels)]),psyms=1,colors='bgrbgrcm'
    options,/def,'*NOISE_BITS',panel_size=2,numbits=12,labels=reverse(['ENABLE','RES2','RES1','RES0','PERIOD7','PERIOD6','PERIOD5','PERIOD4','PERIOD3','PERIOD2','PERIOD1','PERIOD0']),psyms=1,colors=[0,1,2,6]
    options,/def,'*USER_0A',panel_size=2,labels=['BASELINE_OFFSET','NOISE_RES','NOISE_PERIOD','THRESHOLD_SWEEP','PULSER_SWEEP','BIAS_PERIOD','BIAS_VOLTAGE','RESERVED'],psyms=1,colors=[0,1,2,6]
    store_data,'swfo_stis_RATES_PULSFREQ',data='swfo_stis_'+['sci_RATE6','nse_RATE_DIV_THREE','hkp1_'+['DETECTOR_RATES_PPS','PULSER_FREQUENCY']],dlim={panel_size:3,yrange:[.5,1e5],ylog:1}
    store_data,'swfo_stis_RATES_TOTAL',data='swfo_stis_'+['hkp1_SCIENCE_EVENTS','hkp1_DETECTOR_RATES_TOTAL','sci_RATE'],dlim={labflag:-1}
    duration=tnames('swfo_stis_*_DURATION')
    cmds_bad='swfo_stis_hkp1_CMDS_'+['IGNORED','INVALID','UNKNOWN']
    store_data,'swfo_stis_DURATION',data=duration,dlim={labels:duration.substring(10,13),labflag:-1,colors:'rgbk',psym:-1}
    store_data,'swfo_stis_hkp1_CMDS_BAD',data=cmds_bad,dlim={labels:cmds_bad.substring(20),labflag:-1,colors:'rgb',psym:-1}

    options,'swfo_stis_*',ystyle=3
    tplot_options,'wshow',0
  endif

  if ~keyword_set(name) then name = 'sum'
  plot_name = strupcase(strtrim(name,2))
  case plot_name of
    'SUM': tplot,add=add,'*hkp1_USER_0A *hkp1_DET_TIMEOUT_COUNTER *hkp1_ERRORS_TOTAL swfo_stis_RATES_TOTAL *hkp1_NOPEAK_COUNTER swfo_stis_DURATION *hkp1_PPS_* *hkp?_DAC_* *_RATES_PULSFREQ *sci_COUNTS *nse_HISTOGRAM *nse_BASELINE *nse_SIGMA *nse_RATE6 *hkp1_CMDS_RECEIVED *hkp1_CMDS_BAD *hkp1_*REMAIN* *hkp1_*BITS *hkp1_BIAS_CLOCK_PERIOD *hkp1_ADC_*'; *hkp1_ADC_*'
    else: dprint,'Unknown code: '+strtrim(name,2)
  endcase

end

