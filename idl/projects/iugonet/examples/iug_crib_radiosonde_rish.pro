;+
;PROCEDURE: IUG_CRIB_RADIOSONDE_RISH.PRO
;    A sample crib sheet that explains how to use the "iug_load_radiosonde_rish.pro" 
;    procedure. You can run this crib sheet by copying & pasting each 
;    command below (except for stop and end) into the IDL command line. 
;    Or alternatively compile and run using the command:
;        .run iug_crib_ltr_rish
;
;Written by: A. Shinbori,  Apr 12, 2013
;Last Updated:  A. Shinbori,  Oct 27, 2014
;-

;Initializes system variables for themis:
;=========================================
thm_init

;**********************
;DAWEX radiosonde data:
;**********************

;Specify timespan:
;=================
timespan,'2001-10-13',5,/day


;Load preessure, temperature, dew point temperature, relative humidity, 
;zonal, and meridional winds at Darwin in timespan:
;We can select the parameters as 'press', 'temp', 'dewp','rh','uwnd', and 'vwnd':
;  press = pressure
;  temp = temperature
;  dewp = dew point temperature
;  rh = relative humidity
;  uwnd = zonal wind:
;  vwnd = meridional wind
;===============================================================================
iug_load_radiosonde_rish,datatype ='DAWEX', site = 'drw'


;Plot time-height distribution of temperature, relative humidity, zonal and meridional winds:
;============================================================================================
tplot,['iug_radiosonde_drw_temp','iug_radiosonde_drw_dewp','iug_radiosonde_drw_rh',$
       'iug_radiosonde_drw_uwnd','iug_radiosonde_drw_vwnd']

stop

;Substract the average data of zonal and meridional winds:
;=========================================================
tsub_average, 'iug_radiosonde_drw_uwnd'
tsub_average, 'iug_radiosonde_drw_vwnd'
tplot, ['iug_radiosonde_drw_uwnd-d','iug_radiosonde_drw_vwnd-d']

stop

; Set up the plot time range of zonal, meridional and vertical winds in the troposphere:
;=======================================================================================
tlimit, '2001-10-15 00:00:00', '2001-10-16 00:00:00'
tplot

;**************************
;Shigaraki radiosonde data:
;**************************

;Specify timespan:
;=================
timespan,'2009-07-01',62,/day


;Load preessure, temperature, relative humidity, 
;zonal, and meridional winds at Shigaraki in timespan:
;We can select the parameters as 'press', 'temp', 'dewp','rh','uwnd', and 'vwnd':
;  press = pressure
;  temp = temperature
;  rh = relative humidity
;  uwnd = zonal wind:
;  vwnd = meridional wind
;===============================================================================
iug_load_radiosonde_rish,datatype ='misc', site = 'sgk'


;Plot time-height distribution of temperature, relative humidity, zonal and meridional winds:
;============================================================================================
tplot,['iug_radiosonde_sgk_press','iug_radiosonde_sgk_temp','iug_radiosonde_sgk_rh',$
       'iug_radiosonde_sgk_uwnd','iug_radiosonde_sgk_vwnd']

stop

;Substract the average data of zonal and meridional winds:
;=========================================================
tsub_average, 'iug_radiosonde_sgk_uwnd'
tsub_average, 'iug_radiosonde_sgk_vwnd'
tplot, ['iug_radiosonde_sgk_uwnd-d','iug_radiosonde_sgk_vwnd-d']

stop

; Set up the plot time range of zonal, meridional and vertical winds in the troposphere:
;=======================================================================================
tlimit, '2009-07-31 00:00:00', '2009-08-03 00:00:00'
tplot

;**************************
;Bundung radiosonde data:
;**************************

;Specify timespan:
;=================
timespan,'2013-03-13',13,/day

;Load preessure, temperature, relative humidity,
;zonal, and meridional winds at Bundung in timespan:
;We can select the parameters as 'press', 'temp', 'dewp','rh','uwnd', and 'vwnd':
;  press = pressure
;  temp = temperature
;  rh = relative humidity
;  uwnd = zonal wind:
;  vwnd = meridional wind
;===============================================================================
iug_load_radiosonde_rish,datatype ='misc', site = 'bdg'


;Plot time-height distribution of temperature, relative humidity, zonal and meridional winds:
;============================================================================================
tplot,['iug_radiosonde_bdg_press','iug_radiosonde_bdg_temp','iug_radiosonde_bdg_rh',$
  'iug_radiosonde_bdg_uwnd','iug_radiosonde_bdg_vwnd']

stop

;Substract the average data of zonal and meridional winds:
;=========================================================
tsub_average, 'iug_radiosonde_bdg_uwnd'
tsub_average, 'iug_radiosonde_bdg_vwnd'
tplot, ['iug_radiosonde_bdg_uwnd-d','iug_radiosonde_bdg_vwnd-d']

stop

; Set up the plot time range of zonal, meridional and vertical winds in the troposphere:
;=======================================================================================
tlimit, '2013-03-13 00:00:00', '2013-03-18 00:00:00'
tplot

;**************************
;Kototabang radiosonde data:
;**************************

;Specify timespan:
;=================
timespan,'2012-01-06',6,/day


;Load preessure, temperature, relative humidity,
;zonal, and meridional winds at Kototabang in timespan:
;We can select the parameters as 'press', 'temp', 'dewp','rh','uwnd', and 'vwnd':
;  press = pressure
;  temp = temperature
;  rh = relative humidity
;  uwnd = zonal wind:
;  vwnd = meridional wind
;===============================================================================
iug_load_radiosonde_rish,datatype ='misc', site = 'ktb'


;Plot time-height distribution of temperature, relative humidity, zonal and meridional winds:
;============================================================================================
tplot,['iug_radiosonde_ktb_press','iug_radiosonde_ktb_temp','iug_radiosonde_ktb_rh',$
  'iug_radiosonde_ktb_uwnd','iug_radiosonde_ktb_vwnd']

stop

;Substract the average data of zonal and meridional winds:
;=========================================================
tsub_average, 'iug_radiosonde_ktb_uwnd'
tsub_average, 'iug_radiosonde_ktb_vwnd'
tplot, ['iug_radiosonde_ktb_uwnd-d','iug_radiosonde_ktb_vwnd-d']

stop

; Set up the plot time range of zonal, meridional and vertical winds in the troposphere:
;=======================================================================================
tlimit, '2012-01-06 00:00:00', '2012-01-08 00:00:00'
tplot

;**************************
;Pontianak radiosonde data:
;**************************

;Specify timespan:
;=================
timespan,'2009-01-20',90,/day


;Load preessure, temperature, relative humidity,
;zonal, and meridional winds at Pontianak in timespan:
;We can select the parameters as 'press', 'temp', 'dewp','rh','uwnd', and 'vwnd':
;  press = pressure
;  temp = temperature
;  rh = relative humidity
;  uwnd = zonal wind:
;  vwnd = meridional wind
;===============================================================================
iug_load_radiosonde_rish,datatype ='misc', site = 'pon'


;Plot time-height distribution of temperature, relative humidity, zonal and meridional winds:
;============================================================================================
tplot,['iug_radiosonde_pon_press','iug_radiosonde_pon_temp','iug_radiosonde_pon_rh',$
  'iug_radiosonde_pon_uwnd','iug_radiosonde_pon_vwnd']

stop

;Substract the average data of zonal and meridional winds:
;=========================================================
tsub_average, 'iug_radiosonde_pon_uwnd'
tsub_average, 'iug_radiosonde_pon_vwnd'
tplot, ['iug_radiosonde_pon_uwnd-d','iug_radiosonde_pon_vwnd-d']

stop

; Set up the plot time range of zonal, meridional and vertical winds in the troposphere:
;=======================================================================================
tlimit, '2009-01-20 00:00:00', '2009-02-20 00:00:00'
tplot

;**************************
;Serpong radiosonde data:
;**************************

;Specify timespan:
;=================
timespan,'1993-10-08',7,/day


;Load preessure, temperature, relative humidity,
;zonal, and meridional winds at Serpong in timespan:
;We can select the parameters as 'press', 'temp', 'dewp','rh','uwnd', and 'vwnd':
;  press = pressure
;  temp = temperature
;  rh = relative humidity
;  uwnd = zonal wind:
;  vwnd = meridional wind
;===============================================================================
iug_load_radiosonde_rish,datatype ='misc', site = 'srp'


;Plot time-height distribution of temperature, relative humidity, zonal and meridional winds:
;============================================================================================
tplot,['iug_radiosonde_srp_press','iug_radiosonde_srp_temp','iug_radiosonde_srp_rh',$
  'iug_radiosonde_srp_uwnd','iug_radiosonde_srp_vwnd']

stop

;Substract the average data of zonal and meridional winds:
;=========================================================
tsub_average, 'iug_radiosonde_srp_uwnd'
tsub_average, 'iug_radiosonde_srp_vwnd'
tplot, ['iug_radiosonde_srp_uwnd-d','iug_radiosonde_srp_vwnd-d']

stop

; Set up the plot time range of zonal, meridional and vertical winds in the troposphere:
;=======================================================================================
tlimit, '1993-10-09 00:00:00', '1993-10-12 00:00:00'
tplot


end