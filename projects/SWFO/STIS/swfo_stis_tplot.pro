; $LastChangedBy: ali $
; $LastChangedDate: 2022-07-11 15:25:41 -0700 (Mon, 11 Jul 2022) $
; $LastChangedRevision: 30923 $
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

    options,/def,'*_BITS',tplot_routine='bitplot'
    options,/def,'*nse_NHIST',spec=1,panel_size=2,/no_interp,/zlog,constant=findgen(6)*10+5;,zrange=[10,4000.]
    options,/def,'*sci_COUNTS',spec=1,panel_size=4,/no_interp,/zlog,zrange=[1,4000.],constant=findgen(15)*48
    options,/def,'*hkp?_ADC_*',constant=0.
    channels=['CH1','CH2','CH3','CH4','CH5','CH6']
    options,/def,'*hkp?_RATES_COUNTER',panel_size=2,/ylog,yrange=[.5,1e5],colors='bgrmcd',psym=-1,symsize=.5,labels=channels,labflag=-1
    options,/def,'*sci_TOTAL6 *sci_RATE6',/ylog,colors='bgrmcd',psym=-6,symsize=.5,labels=channels,labflag=-1
    options,/def,'*hkp?_ADC_BASELINES',panel_size=2,colors='bgrmcd',labels=channels,labflag=-1
    options,/def,'*hkp?_ADC_VOLTAGES',panel_size=1.5,colors='bgrmc',labels=['1.5VD','3.3VD','5VD','+6VA','-6VA'],labflag=-1,constant=[0,1.5,3.3,5,-5]
    options,/def,'*hkp?_ADC_TEMPS',colors='bgr',labels=['DAP','S1','S2'],labflag=-1
    dacs=['CH1 thresh','CH2 thresh','CH3 thresh','Baseline','CH4 thresh','CH5 thresh','CH6 thresh','AUX2','CH1-4 pulse height','CH2-5 pulse height','CH3-6 pulse height','Bias Voltage Control']
    options,/def,'*hkp1_DAC_VALUES',panel_size=2,yrange=[0,'ffff'x],colors='bgrmmcdcbgrk',labels=dacs,labflag=-1
    options,/def,'*hkp2_DAC_VALUES',panel_size=2,yrange=[0,'ff'x  ],colors='bgrmmcdcbgrk',labels=dacs,labflag=-1
    options,/def,'*LCCS_BITS',numbits=4,panel_size=.5,labels=reverse(['L=Log compressed','C=Compression Type','C=Compression Type','S=Use LUT']),psyms=1,colors=[0,1,2,6]
    options,/def,'*AAEE_BITS',numbits=4,panel_size=.5,labels=reverse(['Attenuator IN','Attenuator OUT','Checksum Error 1','Checksum Error 0']),psyms=1,colors=[0,1,2,6]
    options,/def,'*PPS_BITS',numbits=2,panel_size=.5,labels=reverse(['MISSING','SELF-ENABLE']),psyms=1,colors=[0,1]
    options,/def,'*PULSER_BITS',labels=reverse(['LUT 0:Lower 1:Upper','Pulser Enable',reverse(channels)]),psyms=1,colors='bgrbgrkm'
    options,/def,'*DETECTOR_BITS',labels=reverse(['BLR_MODE1','BLR_MODE0',reverse(channels)]),psyms=1,colors='bgrbgrcm'
    options,/def,'*NOISE_BITS',numbits=12,panel_size=1.5,labels=reverse(['ENABLE','RES2','RES1','RES0','PERIOD7','PERIOD6','PERIOD5','PERIOD4','PERIOD3','PERIOD2','PERIOD1','PERIOD0']),psyms=1,colors=[0,1,2,6]
    store_data,'swfo_stis_hkp1_RATES_PULSFREQ',data=['swfo_stis_sci_RATE6','swfo_stis_hkp1_'+['RATES_COUNTER','PULSER_FREQUENCY']],dlim={panel_size:2,yrange:[.5,1e5]}
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
    'SUM': tplot,add=add,'swfo_stis_DURATION *hkp1_PPS_PERIOD_* *hkp?_DAC_* *hkp1_RATES_PULSFREQ *sci_COUNTS *NHIST *hkp1_CMDS_RECEIVED *hkp1_CMDS_BAD *hkp1_*REMAIN* *hkp1_*BITS *hkp1_BIAS_CLOCK_PERIOD *hkp1_ADC_*'; *hkp1_ADC_*'
    else: dprint,'Unknown code: '+strtrim(name,2)
  endcase

end

