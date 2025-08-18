pro circle_5re
  ; Generate a circle at 5 RE in the XZ plane
  angle = dindgen(361.0)*!dpi/180.0
  
  pos = dblarr(361,3)
  pos[*,0] = 5.0*sin(angle)
  pos[*,1] = 0.0
  pos[*,2] = 5.0*cos(angle)
  t = time_double('2024-01-01/06:31:00') + dindgen(361.0)
  dl = {data_att:{units:'Re',coord_sys:'GSM'}}
  store_data,'circle_magpoles_5re',data={x:t,y:pos},dl=dl
  tkm2re,'circle_magpoles_5re',/km
  ;tplot,['circle_magpoles_5re','circle_magpoles_5re_km']
 end 
  


pro geopack_validate,cdf_filename=cdf_filename

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

circle_5re

; T96
tt96,'circle_magpoles_5re_km',pdyn=2.0,dsti=-30.0,yimf=0.0,zimf=-5.0,/exact_tilt_times,newname='tst5re_bt96'

; T01
tt01,'circle_magpoles_5re_km',pdyn=2.0,dsti=-30.0,yimf=0.0,zimf=-5.0,g1=6.0,g2=10.0,/exact_tilt_times,newname='tst5re_bt01'

; TS04

tt04s,'circle_magpoles_5re_km',pdyn=2.0,dsti=-30.0,yimf=0.0,zimf=-5.0,w1=8.0,w2=5.0,w3=9.5,w4=30.0,w5=18.5,w6=60.0,/exact_tilt_times,newname='tst5re_bts04'

timespan,'2024-01-01/06:31:00',10,/min
tplot,['circle_magpoles_5re_km','tst5re_bt01','tst5re_bt96','tst5re_bts04']
cdf_varlist=['tha_state_pos_gsm','bt89_tilt','bt89','bt89_igrf',$
  'bt96','bt01','bts04','circle_magpoles_5re_km', 'circle_magpoles_5re','tst5re_bt96','tst5re_bt01','tst5re_bts04']
tplot2cdf,filename=cdf_filename,tvars=cdf_varlist,/default_cdf_structure
end