pro circle_5re,start_time,suffix
  ; Generate a circle at 5 RE in the XZ plane
  angle = dindgen(361.0)*!dpi/180.0
  
  pos = dblarr(361,3)
  pos[*,0] = 5.0*sin(angle)
  pos[*,1] = 0.0
  pos[*,2] = 5.0*cos(angle)
  t = time_double(start_time) + dindgen(361.0)
  dl = {data_att:{units:'Re',coord_sys:'GSM'}}
  store_data,'circle_magpoles_5re'+suffix,data={x:t,y:pos},dl=dl
  tkm2re,'circle_magpoles_5re'+suffix,/km
  ;tplot,['circle_magpoles_5re','circle_magpoles_5re_km']
 end 
  


pro geopack_validate,filename=filename

; Load position data for field calculations
timespan,'2007-03-23'
thm_load_state,probe='a',coord='gsm',suffix='_gsm'

; Compute field model at s/c positions

; T89
tt89,'tha_state_pos_gsm',kp=2.0,/exact_tilt_times,newname='bt89',get_tilt='bt89_tilt'
tt89,'tha_state_pos_gsm',kp=2.0,/exact_tilt_times,/igrf_only,newname='bt89_igrf'


; T96
tt96,'tha_state_pos_gsm',pdyn=2.0,dsti=-30.0,yimf=0.0,zimf=-5.0,/exact_tilt_times,newname='bt96'

; T01
tt01,'tha_state_pos_gsm',pdyn=2.0,dsti=-30.0,yimf=0.0,zimf=-5.0,g1=6.0,g2=10.0,/exact_tilt_times,newname='bt01'

; TS04

tt04s,'tha_state_pos_gsm',pdyn=2.0,dsti=-30.0,yimf=0.0,zimf=-5.0,w1=8.0,w2=5.0,w3=9.5,w4=30.0,w5=18.5,w6=60.0,/exact_tilt_times,newname='bts04'

;  For additional test coverage, compute at 5 Re circle in GSM YZ plane

circle_5re,'2026-01-01/06:31:00','_2026'
circle_5re,'2024-01-01/06:31:00','_2024'
circle_5re,'2019-01-01/06:31:00','_2019'
circle_5re,'2014-01-01/06:31:00','_2014'

; T96
tt96,'circle_magpoles_5re_2026_km',pdyn=2.0,dsti=-30.0,yimf=0.0,zimf=-5.0,/exact_tilt_times,newname='tst5re_2026_bt96'
tt96,'circle_magpoles_5re_2024_km',pdyn=2.0,dsti=-30.0,yimf=0.0,zimf=-5.0,/exact_tilt_times,newname='tst5re_2024_bt96'
tt96,'circle_magpoles_5re_2019_km',pdyn=2.0,dsti=-30.0,yimf=0.0,zimf=-5.0,/exact_tilt_times,newname='tst5re_2019_bt96'
tt96,'circle_magpoles_5re_2014_km',pdyn=2.0,dsti=-30.0,yimf=0.0,zimf=-5.0,/exact_tilt_times,newname='tst5re_2014_bt96'

; T01
tt01,'circle_magpoles_5re_2026_km',pdyn=2.0,dsti=-30.0,yimf=0.0,zimf=-5.0,g1=6.0,g2=10.0,/exact_tilt_times,newname='tst5re_2026_bt01'
tt01,'circle_magpoles_5re_2024_km',pdyn=2.0,dsti=-30.0,yimf=0.0,zimf=-5.0,g1=6.0,g2=10.0,/exact_tilt_times,newname='tst5re_2024_bt01'
tt01,'circle_magpoles_5re_2019_km',pdyn=2.0,dsti=-30.0,yimf=0.0,zimf=-5.0,g1=6.0,g2=10.0,/exact_tilt_times,newname='tst5re_2019_bt01'
tt01,'circle_magpoles_5re_2014_km',pdyn=2.0,dsti=-30.0,yimf=0.0,zimf=-5.0,g1=6.0,g2=10.0,/exact_tilt_times,newname='tst5re_2014_bt01'

; TS04

tt04s,'circle_magpoles_5re_2026_km',pdyn=2.0,dsti=-30.0,yimf=0.0,zimf=-5.0,w1=8.0,w2=5.0,w3=9.5,w4=30.0,w5=18.5,w6=60.0,/exact_tilt_times,newname='tst5re_2026_bts04'
tt04s,'circle_magpoles_5re_2024_km',pdyn=2.0,dsti=-30.0,yimf=0.0,zimf=-5.0,w1=8.0,w2=5.0,w3=9.5,w4=30.0,w5=18.5,w6=60.0,/exact_tilt_times,newname='tst5re_2024_bts04'
tt04s,'circle_magpoles_5re_2019_km',pdyn=2.0,dsti=-30.0,yimf=0.0,zimf=-5.0,w1=8.0,w2=5.0,w3=9.5,w4=30.0,w5=18.5,w6=60.0,/exact_tilt_times,newname='tst5re_2019_bts04'
tt04s,'circle_magpoles_5re_2014_km',pdyn=2.0,dsti=-30.0,yimf=0.0,zimf=-5.0,w1=8.0,w2=5.0,w3=9.5,w4=30.0,w5=18.5,w6=60.0,/exact_tilt_times,newname='tst5re_2014_bts04'

; Repeat with actual solar wind parameters

; Expand support timerange by 30 minutes each side

timespan,'2007-03-22/23:30',25,/hours

kyoto_load_dst
omni_load_data
noaa_load_kp

; Use Geopack routines to calculate g1, g2  and w1-w6 parameters for T01 and TS04 models

vsw_tvar = 'OMNI_HRO_1min_flow_speed'
yimf_tvar = 'OMNI_HRO_1min_BY_GSM'
zimf_tvar = 'OMNI_HRO_1min_BZ_GSM'
dens_tvar = 'OMNI_HRO_1min_proton_density'

get_data, 'OMNI_HRO_1min_flow_speed', data=vsw
trange = minmax(vsw.x)
n = fix(trange[1]-trange[0],type=3)/300 +1
;the geopack parameter generating functions only work on 5 minute intervals

;construct a time array
ntimes=dindgen(n)*300+trange[0]

; Interpolate input variables to 5-minute grid, ensuring no NaNs in output
tinterpol_mxn,yimf_tvar,ntimes,/ignore_nans,out=yimf_tvar+'_interp'
tinterpol_mxn,zimf_tvar,ntimes,/ignore_nans,out=zimf_tvar+'_interp'
tinterpol_mxn,vsw_tvar,ntimes,/ignore_nans,out=vsw_tvar + '_interp'
tinterpol_mxn,dens_tvar,ntimes,/ignore_nans,out=dens_tvar + '_interp'

get_data, 'OMNI_HRO_1min_flow_speed_interp', data=vsw
get_data, 'OMNI_HRO_1min_BY_GSM_interp', data=bygsm
get_data, 'OMNI_HRO_1min_BZ_GSM_interp', data=bzgsm
get_data, 'OMNI_HRO_1min_proton_density_interp', data=dens

geopack_getg, vsw.y, bygsm.y, bzgsm.y, g

g1=g[*,0]
g2=g[*,1]

store_data,'g1',data={x:vsw.x, y:g1}
store_data,'g2',data={x:vsw.x, y:g2}

tplot,'OMNI_HRO_1min_BY_GSM OMNI_HRO_1min_BZ_GSM OMNI_HRO_1min_flow_speed g1 g2'

geopack_getw, dens.y, vsw.y, bzgsm.y, w

w1 = w[*,0]
w2 = w[*,1]
w3 = w[*,2]
w4 = w[*,3]
w5 = w[*,4]
w6 = w[*,5]
store_data,'w1',data={x:vsw.x, y:w1}
store_data,'w2',data={x:vsw.x, y:w2}
store_data,'w3',data={x:vsw.x, y:w3}
store_data,'w4',data={x:vsw.x, y:w4}
store_data,'w5',data={x:vsw.x, y:w5}
store_data,'w6',data={x:vsw.x, y:w6}
tplot,'OMNI_HRO_1min_proton_density OMNI_HRO_1min_BZ_GSM OMNI_HRO_1min_flow_speed w1 w2 w3 w4 w5 w6'



; iopt values to check
; 
iopt = kp2iopt('Kp',varname='tha_state_pos_gsm')
get_data,'tha_state_pos_gsm',data=d
store_data,'iopt_interp',data={x: d.x, y:iopt}

; T89
tt89,'tha_state_pos_gsm',kp='Kp',/exact_tilt_times,newname='bt89_actual',get_tilt='bt89_tilt'
tt89,'tha_state_pos_gsm',kp='Kp',/exact_tilt_times,/igrf_only,newname='bt89_igrf_actual'


; T96
tt96,'tha_state_pos_gsm',pdyn='OMNI_HRO_1min_Pressure',dsti='kyoto_dst',yimf='OMNI_HRO_1min_BY_GSM',zimf='OMNI_HRO_1min_BZ_GSM',/exact_tilt_times,newname='bt96_actual'

; T01
tt01,'tha_state_pos_gsm',pdyn='OMNI_HRO_1min_Pressure',dsti='kyoto_dst',yimf='OMNI_HRO_1min_BY_GSM',zimf='OMNI_HRO_1min_BZ_GSM',g1='g1',g2='g2',/exact_tilt_times,newname='bt01_actual'
;tt01,'tha_state_pos_gsm',pdyn=2.0,dsti=-30,yimf='OMNI_HRO_1min_BY_GSM',zimf='OMNI_HRO_1min_BZ_GSM',g1=6.0,g2=10.0,/exact_tilt_times,newname='bt01_actual'

; TS04

tt04s,'tha_state_pos_gsm',pdyn='OMNI_HRO_1min_Pressure',dsti='kyoto_dst',yimf='OMNI_HRO_1min_BY_GSM',zimf='OMNI_HRO_1min_BZ_GSM',w1='w1',w2='w2',w3='w3',w4='w4',w5='w5',w6='w6',/exact_tilt_times,newname='bts04_actual'


;timespan,'2024-01-01/06:31:00',10,/min
;tplot,['circle_magpoles_5re_km','tst5re_bt01','tst5re_bt96','tst5re_bts04']
varlist=['tha_state_pos_gsm','bt89_tilt','bt89','bt89_igrf',$
  'bt96','bt01','bts04','kyoto_dst','OMNI_HRO_1min_BY_GSM',  $
  'Kp', 'iopt_interp','OMNI_HRO_1min_Pressure', 'OMNI_HRO_1min_BZ_GSM', $
  'bt89_actual', 'bt89_igrf_actual', 'bt96_actual', 'bt01_actual', 'bts04_actual', 'g1', 'g2', $
  'w1','w2','w3','w4','w5','w6',$
  'circle_magpoles_5re_2026_km', 'circle_magpoles_5re_2026',$
  'circle_magpoles_5re_2024_km', 'circle_magpoles_5re_2024',$
  'circle_magpoles_5re_2019_km', 'circle_magpoles_5re_2019',$
  'circle_magpoles_5re_2014_km', 'circle_magpoles_5re_2014',$

  'tst5re_2026_bt96',$
  'tst5re_2024_bt96',$
  'tst5re_2019_bt96',$
  'tst5re_2014_bt96',$

  'tst5re_2026_bt01',$
  'tst5re_2024_bt01',$
  'tst5re_2019_bt01',$
  'tst5re_2014_bt01',$

  'tst5re_2026_bts04',$
  'tst5re_2024_bts04',$
  'tst5re_2019_bts04',$
  'tst5re_2014_bts04' ]
  
;tplot2cdf,filename=filename,tvars=varlist,/default_cdf_structure, /use_tplot_names
tplot_save,varlist,filename=filename
end