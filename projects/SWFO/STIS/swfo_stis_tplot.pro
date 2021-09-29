; $LastChangedBy: davin-mac $
; $LastChangedDate: 2021-09-02 01:37:26 -0700 (Thu, 02 Sep 2021) $
; $LastChangedRevision: 30276 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_tplot.pro $
; $ID: $



; This routine will set appropriate limits for tplot variables and then make a tplot


pro swfo_stis_tplot
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
  options,'*sci_COUNTS',spec=1,panel_size=7,/no_interp,/zlog  ;,zrange=[100,4000.]
  options,'*hkp?_ADC_*',constant=0.
  options,'*1_RATES_CNTR',panel_size=3,/ylog,yrange=[.5,1e5],/ystyle,colors='bgrmcd',psym=-1,symsize=.5
  options,'*hkp1_DAC_VALS',panel_size=2,/ystyle,ylog=0,yrange=[0,2.^16],colors='bgrymcdybgry'
  options,'*hkp2_DAC_VALS',panel_size=2,/ystyle,ylog=0,yrange=[0,200.],colors='bgrymcdybgry'
  tplot,'*hkp?_DAC_VALS *1_RATES_CNTR *sci_COUNTS *NHIST *hkp1_CMDS *hkp1_MAPID *hkp1*BITS *hkp1_ADC_BIAS_* *hkp1_ADC_TEMP*'; *hkp1_ADC_*'
  tplot_options,'wshow',0
end

