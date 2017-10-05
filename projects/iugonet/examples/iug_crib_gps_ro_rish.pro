;+
;PROCEDURE: IUG_CRIB_GPS_RO_RISH.PRO
;    A sample crib sheet that explains how to use the "iug_crib_gps_ro_rish.pro" 
;    procedure. You can run this crib sheet by copying & pasting each 
;    command below (except for stop and end) into the IDL command line. 
;    Or alternatively compile and run using the command:
;        .run iug_crib_gps_ro_rish
;
;Written by: A. Shinbori,  May 18, 2016
;Last Updated: A. Shinbori,  May 18, 2016 
;-

;Initializes system variables for themis:
;=========================================
thm_init

;****************
;Champ satellite:
;****************

;Specify timespan:
;=================
timespan,'2006-06-01',1,/day


;Load all the GPS-CHAMP radio occultation data for the selected parameter in timespan:
;Tplot parameters are 'gps_ro_champ_fsi_event', 'gps_ro_champ_fsi_gpsid','gps_ro_champ_fsi_leoid',
;'gps_ro_champ_fsi_lat', 'gps_ro_champ_fsi_lon','gps_ro_champ_fsi_ref','gps_ro_champ_fsi_pres',
;'gps_ro_champ_fsi_temp', 'gps_ro_champ_fsi_tan_lat', 'gps_ro_champ_fsi_tan_lon':
;  
;  ref = refractivity [N]
;  pres = Air pressure [hPa]
;  temp = Dry air temperature [degree C]
;  
;===============================================================================
iug_load_gps_ro_rish, site='champ'


;Plot time-height distribution of refractivity, air pressure, and dru air temperature:
;=====================================================================================
tplot,['gps_ro_champ_fsi_ref','gps_ro_champ_fsi_pres','gps_ro_champ_fsi_temp']

;Change in the z-range (color bar scale) of temperature:
;=======================================================
zlim, 'gps_ro_champ_fsi_temp', -100, 20

tplot

stop


; Set up the plot time range of refractivity, air pressure, and dru air temperature:
;===================================================================================
tlimit, '2006-06-01 10:00:00', '2006-06-01 20:00:00'
tplot

stop

;*****************
;COSMIC satellite:
;*****************

;Specify timespan:
;=================
timespan,'2009-06-01',1,/day


;Load all the GPS-COSMIC radio occultation data for the selected parameter in timespan:
;Tplot parameters are 'gps_ro_cosmic_fsi_event', 'gps_ro_cosmic_fsi_gpsid','gps_ro_cosmic_fsi_leoid',
;'gps_ro_cosmic_fsi_lat', 'gps_ro_cosmic_fsi_lon','gps_ro_cosmic_fsi_ref','gps_ro_cosmic_fsi_pres',
;'gps_ro_cosmic_fsi_temp', 'gps_ro_cosmic_fsi_tan_lat', 'gps_ro_cosmic_fsi_tan_lon':
;  
;  ref = refractivity [N]
;  pres = Air pressure [hPa]
;  temp = Dry air temperature [degree C]
;  
;===============================================================================
iug_load_gps_ro_rish, site='cosmic'


;Plot time-height distribution of refractivity, air pressure, and dru air temperature:
;=====================================================================================
tplot,['gps_ro_cosmic_fsi_ref','gps_ro_cosmic_fsi_pres','gps_ro_cosmic_fsi_temp']

;Change in the z-range (color bar scale) of temperature:
;=======================================================
zlim, 'gps_ro_cosmic_fsi_temp', -100, 20

tplot

stop


; Set up the plot time range of refractivity, air pressure, and dru air temperature:
;===================================================================================
tlimit, '2009-06-01 10:00:00', '2009-06-01 20:00:00'
tplot

stop
end


