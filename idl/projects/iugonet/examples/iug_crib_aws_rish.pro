;+
;PROCEDURE: IUG_CRIB_AWS_RISH.PRO
;    A sample crib sheet that explains how to use the "iug_load_aws_rish.pro" 
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
timespan,'1994-05-01',7,/day


;Load zonal, meridional and vertical winds at Shigaraki in timespan:
;===================================================================
iug_load_aws_rish, site = 'sgk'


;Plot time-height distribution of zonal and meridional winds:
;============================================================
tplot,['iug_aws_sgk_uwnd','iug_aws_sgk_vwnd']

stop

;Substract the average data of zonal, meridional and vertical winds:
;===================================================================
tsub_average, 'iug_aws_sgk_uwnd'
tsub_average, 'iug_aws_sgk_vwnd'
tplot, ['iug_aws_sgk_uwnd-d','iug_aws_sgk_vwnd-d']

stop

;1-hour running average of zonal and meridional winds:
;=====================================================
tsmooth_in_time, 'iug_aws_sgk_uwnd', 3600
tsmooth_in_time, 'iug_aws_sgk_vwnd', 3600

tplot, ['iug_aws_sgk_uwnd_smoothed','iug_aws_sgk_vwnd_smoothed']

stop

; Set up the plot time range of zonal and meridional winds in the troposphere:
;=============================================================================
tlimit, '1994-05-05 00:00:00', '1994-05-06 00:00:00'
tplot

end