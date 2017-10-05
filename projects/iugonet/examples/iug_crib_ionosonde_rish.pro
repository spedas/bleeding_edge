;+
;PROCEDURE: IUG_CRIB_IONOSONDE_RISH.PRO
;    A sample crib sheet that explains how to use the "iug_load_ionosonde_rish.pro" 
;    procedure. You can run this crib sheet by copying & pasting each 
;    command below (except for stop and end) into the IDL command line. 
;    Or alternatively compile and run using the command:
;        .run iug_crib_aws_rish
;
;Written by: A. Shinbori,  Nov 12, 2012
;Last Updated: A. Shinbori,  Feb 25, 2013 
;-

;Initializes system variables for themis:
;=========================================
thm_init

;Specify timespan:
;=================
timespan,'2002-07-01',1,/day


;Load zonal, meridional and vertical winds at Shigaraki in timespan:
;===================================================================
iug_load_ionosonde_rish, site = 'sgk',/fixed_freq


;Plot time-height distribution of echo power at every 2 MHz frequency (2.0-8.0 MHz):
;===================================================================================
tplot,['iug_ionosonde_sgk_freq_2MHz','iug_ionosonde_sgk_freq_4MHz',$
       'iug_ionosonde_sgk_freq_6MHz','iug_ionosonde_sgk_freq_8MHz']

stop

;Substract the average data of echo power at every 2 MHz frequency (2.0-8.0 MHz):
;================================================================================
tsub_average, 'iug_ionosonde_sgk_freq_2MHz'
tsub_average, 'iug_ionosonde_sgk_freq_4MHz'
tsub_average, 'iug_ionosonde_sgk_freq_6MHz'
tsub_average, 'iug_ionosonde_sgk_freq_8MHz'
tplot, ['iug_ionosonde_sgk_freq_2MHz-d','iug_ionosonde_sgk_freq_4MHz-d',$
        'iug_ionosonde_sgk_freq_6MHz-d','iug_ionosonde_sgk_freq_8MHz-d']

stop

;1-hour running average of echo power at every 2 MHz frequency (2.0-8.0 MHz):
;============================================================================
tsmooth_in_time, 'iug_ionosonde_sgk_freq_2MHz', 3600
tsmooth_in_time, 'iug_ionosonde_sgk_freq_4MHz', 3600
tsmooth_in_time, 'iug_ionosonde_sgk_freq_6MHz', 3600
tsmooth_in_time, 'iug_ionosonde_sgk_freq_8MHz', 3600

tplot, ['iug_ionosonde_sgk_freq_2MHz_smoothed','iug_ionosonde_sgk_freq_4MHz_smoothed',$
        'iug_ionosonde_sgk_freq_6MHz_smoothed','iug_ionosonde_sgk_freq_8MHz_smoothed']

stop

; Set up the plot time range of echo power at every 2 MHz frequency (2.0-8.0 MHz):
;=================================================================================
tlimit, '2002-07-01 00:00:00', '2002-07-01 12:00:00'
tplot

end