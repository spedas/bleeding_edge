; $LastChangedBy: ali $
; $LastChangedDate: 2022-03-26 12:02:39 -0700 (Sat, 26 Mar 2022) $
; $LastChangedRevision: 30720 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_tplot.pro $

; This routine will set appropriate limits for tplot variables and then make a tplot

pro swfo_stis_tplot,name,add=add,setlim=setlim

  if keyword_set(setlim) then begin
    if 0 then begin
      nse = swfo_apdat('stis_nse')
      s = nse.struct()
      data= s.data
      data_1a = s.level_1a
      if 0 then $
        data_1a.array = swfo_stis_nse_level_1(data.array)

      store_data,'SWFO_stis_nse_L0',data=data,tagnames = '*'
      options,'SWFO*nse_L0_NHIST',spec=1,zlog=1,yrange=[0,60],constant=findgen(6)*10+4.5,panel_size=5,/no_interp
      store_data,'SWFO_stis_nse_L1',data=data_1a,tagnames='baseline sigma tot *res *per'
      options,'SWFO*L1_BASELINE',constant=0.,colors='bgrmcd'
      options,'SWFO*L1_SIGMA',constant=0.,colors='bgrmcd'
      options,'SWFO*L1_NOISE_RES',yrange=[0,7],ystyle=3
      ;tvars = tnames('SWFO*_nse_L0
      tplot,'SWFO*L1*',/add
    endif

    ;tplot,'*HIST *hkp1_PPS_CNTR *hkp1_CMDS *hkp1_MAPID *hkp1*BITS *hkp1_ADC_*'
    options,'*_BITS',tplot_routine='bitplot'
    options,'*nse_NHIST',spec=1,panel_size=4,/no_interp,/zlog,zrange=[10,4000.],constant=findgen(6)*10+5
    options,'*sci_COUNTS',spec=1,panel_size=7,/no_interp,/zlog,zrange=[1,4000.],constant=findgen(14)*48
    options,'*hkp?_ADC_*',constant=0.
    options,'*1_RATES_CNTR',panel_size=3,/ylog,yrange=[.5,1e5],/ystyle,colors='bgrmcd',psym=-1,symsize=.5
    options,'*hkp1_DAC_VALS',panel_size=2,/ystyle,ylog=0,yrange=[0,2.^16],colors='bgrymcdybgry'
    options,'*hkp2_DAC_VALS',panel_size=2,/ystyle,ylog=0,yrange=[0,200.],colors='bgrymcdybgry'
    options,'*LCCS_BITS',tplot_routine='bitplot',numbits=4,panel_size=.5,labels=reverse(['L=Log compressed','C=Compression Type','C=Compression Type','S=Use LUT']),psyms=1,colors=[0,1,2,6]
    options,'*PULSER_BITS',tplot_routine='bitplot',labels=reverse(['LUT 0:Lower 1:Upper','Pulser Enable','F2','T2','O2','F1','T1','O1']),psyms=1,colors=[0,1,2]
    options,'*DETECTOR_BITS',tplot_routine='bitplot',labels=reverse(['BLR_MODE1','BLR_MODE0','F2','T2','O2','F1','T1','O1']),psyms=1,colors=[0,1,2]
    options,'*NOISE_BITS',tplot_routine='bitplot',numbits=12,panel_size=1.5,labels=reverse(['ENABLE','RES2','RES1','RES0','PERIOD7','PERIOD6','PERIOD5','PERIOD4','PERIOD3','PERIOD2','PERIOD1','PERIOD0']),psyms=1,colors=[0,1,2,6]

    tplot_options,'wshow',0
  endif

  if ~keyword_set(name) then name = 'sum'
  plot_name = strupcase(strtrim(name,2))
  case plot_name of
    'SUM': tplot,add=add,'*hkp?_DAC_VALS *1_RATES_CNTR *sci_COUNTS *NHIST *hkp1_CMDS *hkp1_MAPID *hkp1*BITS *hkp1_ADC_BIAS_* *hkp1_ADC_TEMP*'; *hkp1_ADC_*'
    'SUM2': tplot,add=add,'swemul_tns_TIME_DELAY_PTP *hkp1_ADC_TEMP_S1 *hkp1_ADC_BIAS_* *hkp1_ADC_?5? swfo_stis_hkp1_RATES_CNTR swfo_stis_sci_COUNTS swfo_stis_nse_NHIST swfo_stis_hkp1_CMDS'
    'ERR1': tplot,add=add,'*hkp1*ERRORS* *hkp1_BUS_TIMEOUT_CNTR *hkp1_DET_TIMEOUT_CNTR *hkp1_NOPEAK_CNTR *hkp1_CMDS_IGNORED *hkp1_CMDS_UKNOWN hkp1_MEM_CHKSUM'
    'HKP1': tplot,add=add,'*hkp1_ADC_*'
    'ERR2': tplot,add=add,'*hkp2*ERRORS* *hkp2_BUS_TIMEOUT_CNTR *hkp2_DET_TIMEOUT_CNTR *hkp2_NOPEAK_CNTR *hkp2_CMDS_IGNORED *hkp2_CMDS_UKNOWN hkp2_MEM_CHKSUM'
    '1':   tplot,'mvn_SEPS_hkp_VCMD_CNTR mvn_sep?_svy_DATA mvn_sep?_noise_SIGMA mvn_sep?_hkp_RATE_CNTR',ADD=ADD
    ;'SUM': tplot,'mvn_pfp_TEMPS mvn_SEPS_svy_ATT mvn_sep?_svy_DATA mvn_sep?_noise_SIGMA mvn_sep?_hkp_RATE_CNTR',ADD=ADD
    'SEPS':tplot,'mvn_SEPS_TEMP mvn_SEPS_svy_ATT mvn_SEPS_svy_COUNTS_TOTAL mvn_SEPS_hkp_VCMD_CNTR mvn_sep?_noise_SIGMA mvn_sep?_hkp_RATE_CNTR',ADD=ADD
    '1A':  tplot,'mvn_sep1_svy_ATT mvn_sep1_A*',ADD=ADD
    '1B':  tplot,'mvn_sep1_svy_ATT mvn_sep1_B*',ADD=ADD
    '2A':  tplot,'mvn_sep2_svy_ATT mvn_sep2_A*',ADD=ADD
    '2B':  tplot,'mvn_sep2_svy_ATT mvn_sep2_B*',ADD=ADD
    'TID': tplot,'mvn_sep?_?_*_tot',ADD=ADD
    'FOIL':tplot,'mvn_sep?_?-F_*',ADD=ADD
    'OPEN':tplot,'mvn_sep?_?-O_*',ADD=ADD
    'ION': tplot,'mvn_SEP??_ion_eflux',ADD=ADD
    'ELEC': tplot,'mvn_SEP??_elec_eflux',ADD=ADD
    'ION5': tplot,'mvn_5min_SEP??_ion_eflux',ADD=ADD
    'ELEC5': tplot,'mvn_5min_SEP??_elec_eflux',ADD=ADD
    'ION1H': tplot,'mvn_01hr_SEP??_ion_eflux',ADD=ADD
    'ELEC1H': tplot,'mvn_01hr_SEP??_elec_eflux',ADD=ADD
    'THICK':tplot,'mvn_sep?_?-T_*',ADD=ADD
    'FTO':tplot,'mvn_sep?_?-FTO_*',ADD=ADD
    'FT':tplot,'mvn_sep?_?-FT_*',ADD=ADD
    'OT':tplot,'mvn_sep?_?-OT_*',ADD=ADD
    'HKP': tplot,'mvn_sep?_hkp_AMON_*',ADD=ADD
    'TEMP':tplot,'mvn_SEPS_TEMP mvn_DPU_TEMP',add=add
    'NS1' : tplot,'mvn_sep1_noise_*',ADD=ADD
    'MAG1': tplot,'mvn_mag1_svy_BRAW',ADD=ADD
    'MAG2': tplot,'mvn_mag2_svy_BRAW',ADD=ADD
    'QL' : tplot,'mvn_mag1_svy_BRAW* mvn_mag2_svy_BRAW* mvn_SEPS_QL mvn_pfdpu_oper_ACT_STATUS_FLAG mvn_lpw_euv*',add=add   ; example QL plot
    else: dprint,'Unknown code: '+strtrim(name,2)
  endcase

end

