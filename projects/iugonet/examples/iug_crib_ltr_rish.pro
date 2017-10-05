;+
;PROCEDURE: IUG_CRIB_LTR_RISH.PRO
;    A sample crib sheet that explains how to use the "iug_load_ltr_rish.pro" 
;    procedure. You can run this crib sheet by copying & pasting each 
;    command below (except for stop and end) into the IDL command line. 
;    Or alternatively compile and run using the command:
;        .run iug_crib_ltr_rish
;
;Written by: A. Shinbori,  Feb 18, 2011
;Last Updated:  A. Shinbori,  Dec 26, 2011
;-

;Initializes system variables for themis:
;=========================================
thm_init

;Specify timespan:
;=================
timespan,'2005-12-01',7,/day


;Load zonal, meridional and vertical winds at Shigaraki in timespan:
;We can select the parameters as 'uwnd', 'vwnd', 'wwnd', 'pwr1', 'pwr2', 'pwr3',
;  'pwr4', 'pwr5', 'wdt1', 'wdt2', 'wdt3', 'wdt4', 'wdt5':
;  uwnd = zonal wind:
;  vwnd = meridional wind
;  wwnd = vertical wind
;===============================================================================
iug_load_ltr_rish, site = 'sgk', parameter = ['uwnd','vwnd','wwnd']


;Plot time-height distribution of zonal wind:
;============================================
tplot,['iug_ltr_sgk_uwnd','iug_ltr_sgk_vwnd','iug_ltr_sgk_wwnd']

stop

;Substract the average data of zonal, meridional and vertical winds:
;===================================================================
tsub_average, 'iug_ltr_sgk_uwnd'
tsub_average, 'iug_ltr_sgk_vwnd'
tsub_average, 'iug_ltr_sgk_wwnd'
tplot, ['iug_ltr_sgk_uwnd-d','iug_ltr_sgk_vwnd-d','iug_ltr_sgk_wwnd-d']

stop

;1-hour running average of zonal, meridional and vertical winds:
;==============================================================
tsmooth_in_time, 'iug_ltr_sgk_uwnd', 3600
tsmooth_in_time, 'iug_ltr_sgk_vwnd', 3600
tsmooth_in_time, 'iug_ltr_sgk_wwnd', 3600

tplot, ['iug_ltr_sgk_uwnd_smoothed','iug_ltr_sgk_vwnd_smoothed','iug_ltr_sgk_wwnd_smoothed']

stop

; Set up the plot time range of zonal, meridional and vertical winds in the troposphere:
;=======================================================================================
tlimit, '2005-12-05 00:00:00', '2005-12-06 00:00:00'
tplot

end