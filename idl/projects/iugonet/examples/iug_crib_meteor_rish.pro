;+
;PROCEDURE: IUG_CRIB_METEOR_RISH.PRO
;    A sample crib sheet that explains how to use the "iug_crib_meteor_rish.pro" 
;    procedure. You can run this crib sheet by copying & pasting each 
;    command below (except for stop and end) into the IDL command line. 
;    Or alternatively compile and run using the command:
;        .run iug_crib_meteor_rish
;
;Written by: A. Shinbori,  Jul 25, 2012
;Last Updated: A. Shinbori,  May 30, 2013 
;-

;Initializes system variables for themis:
;=========================================
thm_init

;*************************
;Biak meteor radar:
;*************************

;Specify timespan:
;=================
timespan,'2011-10-01',31,/day


;Load all the data of zonal and meridional wind velocities 
;and their standard deviations and the number of meteor traces
;at Kototabang for the selected parameter in timespan:
;Tplot parameters are 'iug_meteor_bik_uwnd_h2t60min00', 'iug_meteor_bik_vwnd_h2t60min00',
; 'iug_meteor_bik_uwndsig_h2t60min00', 'iug_meteor_bik_vwndsig_h2t60min00',
;  'iug_meteor_bik_mwnum_h2t60min00':
;  
;  uwnd = zonal wind:
;  vwnd = meridional wind
;  
;===============================================================================
iug_load_meteor_rish, site='bik', parameter = 'h2t60min00', length = '1_month'


;Plot time-height distribution of zonal and merdional wind:
;==========================================================
tplot,['iug_meteor_bik_uwnd_h2t60min00','iug_meteor_bik_vwnd_h2t60min00']

;Change in the y-range (altitude):
;=================================
ylim, 'iug_meteor_bik_uwnd_h2t60min00', 70, 110
ylim, 'iug_meteor_bik_vwnd_h2t60min00', 70, 110

;Change in the z-range (color bar scale):
;========================================
zlim, 'iug_meteor_bik_uwnd_h2t60min00', -100, 100
zlim, 'iug_meteor_bik_vwnd_h2t60min00', -100, 100

tplot

stop


; Set up the plot time range of zonal and meridional winds in the thermosphere:
;===============================================================================
tlimit, '2011-10-01 00:00:00', '2011-10-05 00:00:00'
tplot

stop

;*************************
;Kototabang meteor radar:
;*************************

;Specify timespan:
;=================
timespan,'2008-01-01',365,/day


;Load all the data of zonal and meridional wind velocities 
;and their standard deviations and the number of meteor traces
;at Kototabang for the selected parameter in timespan:
;Tplot parameters are 'iug_meteor_ktb_uwnd_h2t60min00', 'iug_meteor_ktb_vwnd_h2t60min00',
; 'iug_meteor_ktb_uwndsig_h2t60min00', 'iug_meteor_ktb_vwndsig_h2t60min00',
;  'iug_meteor_ktb_mwnum_h2t60min00':
;  
;  uwnd = zonal wind:
;  vwnd = meridional wind
;  
;===============================================================================
iug_load_meteor_rish, site='ktb', parameter = 'h2t60min00', length = '1_month'


;Plot time-height distribution of zonal and merdional wind:
;==========================================================
tplot,['iug_meteor_ktb_uwnd_h2t60min00','iug_meteor_ktb_vwnd_h2t60min00']

;Change in the y-range (altitude):
;=================================
ylim, 'iug_meteor_ktb_uwnd_h2t60min00', 70, 110
ylim, 'iug_meteor_ktb_vwnd_h2t60min00', 70, 110

;Change in the z-range (color bar scale):
;========================================
zlim, 'iug_meteor_ktb_uwnd_h2t60min00', -100, 100
zlim, 'iug_meteor_ktb_vwnd_h2t60min00', -100, 100

tplot

stop


; Set up the plot time range of zonal and meridional winds in the thermosphere:
;===============================================================================
tlimit, '2008-03-01 00:00:00', '2008-03-05 00:00:00'
tplot

stop

;**********************
;Serpong meteor radar:
;**********************

;Specify timespan:
;=================
timespan,'1993-01-01',365,/day


;Load all the data of zonal and meridional wind velocities 
;and their standard deviations and the number of meteor traces
;at Serpong for the selected parameter in timespan:
;Tplot parameters are 'iug_meteor_srp_uwnd_h2t60min00', 'iug_meteor_srp_vwnd_h2t60min00',
; 'iug_meteor_srp_uwndsig_h2t60min00', 'iug_meteor_srp_vwndsig_h2t60min00',
;  'iug_meteor_srp_mwnum_h2t60min00':
;  
;  uwnd = zonal wind:
;  vwnd = meridional wind
;  
;===============================================================================
iug_load_meteor_rish, site='srp', parameter = 'h2t60min00', length = '1_month'


;Plot time-height distribution of zonal and merdional wind:
;==========================================================
tplot,['iug_meteor_srp_uwnd_h2t60min00','iug_meteor_srp_vwnd_h2t60min00']

;Change in the y-range (altitude):
;=================================
ylim, 'iug_meteor_srp_uwnd_h2t60min00', 70, 110
ylim, 'iug_meteor_srp_vwnd_h2t60min00', 70, 110

;Change in the z-range (color bar scale):
;========================================
zlim, 'iug_meteor_srp_uwnd_h2t60min00', -100, 100
zlim, 'iug_meteor_srp_vwnd_h2t60min00', -100, 100

tplot

stop


; Set up the plot time range of zonal and meridional winds in the thermosphere:
;===============================================================================
tlimit, '1993-03-01 00:00:00', '1993-03-05 00:00:00'
tplot

;*************************
;Shigaraki meteor radar:
;*************************

;Specify timespan:
;=================
timespan,'1983-09-01',365,/day


;Load all the data of zonal and meridional wind velocities 
;and their standard deviations and the number of meteor traces
;at Kototabang for the selected parameter in timespan:
;Tplot parameters are 'iug_meteor_sgk_uwnd_h2t60min00', 'iug_meteor_sgk_vwnd_h2t60min00',
; 'iug_meteor_sgk_uwndsig_h2t60min00', 'iug_meteor_sgk_vwndsig_h2t60min00',
;  'iug_meteor_sgk_mwnum_h2t60min00':
;  
;  uwnd = zonal wind:
;  vwnd = meridional wind
;  
;===============================================================================
iug_load_meteor_rish, site='sgk', parameter = 'h2t60min00', length = '1_month'


;Plot time-height distribution of zonal and merdional wind:
;==========================================================
tplot,['iug_meteor_sgk_uwnd_h2t60min00','iug_meteor_sgk_vwnd_h2t60min00']

;Change in the y-range (altitude):
;=================================
ylim, 'iug_meteor_sgk_uwnd_h2t60min00', 70, 110
ylim, 'iug_meteor_sgk_vwnd_h2t60min00', 70, 110

;Change in the z-range (color bar scale):
;========================================
zlim, 'iug_meteor_sgk_uwnd_h2t60min00', -100, 100
zlim, 'iug_meteor_sgk_vwnd_h2t60min00', -100, 100

tplot

stop


; Set up the plot time range of zonal and meridional winds in the thermosphere:
;===============================================================================
tlimit, '1983-09-01 00:00:00', '1983-10-01 00:00:00'
tplot

stop

end


