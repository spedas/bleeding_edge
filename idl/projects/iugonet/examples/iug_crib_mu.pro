;+
;PROCEDURE: IUG_CRIB_MU.PRO
;    A sample crib sheet that explains how to use the "iug_load_mu.pro" 
;    procedure. You can run this crib sheet by copying & pasting each 
;    command below (except for stop and end) into the IDL command line. 
;    Or alternatively compile and run using the command:
;        .run iug_crib_mu
;
;Written by: A. Shinbori,  Feb 18, 2011
;Last Updated:  A. Shinbori,  Jan 07, 2014
;-

;Initializes system variables for themis:
;=========================================
thm_init

;=======================Troposphere=======================================
;Specify timespan:
;=================
timespan,'1994-09-29',1,/day

;Load all the standard observation data of the troposphere and stratosphere 
;taken by the MU radar in timespan:
;Tplot variables are 'iug_mu_uwnd', 'iug_mu_vwnd', 'iug_mu_wwnd', 'iug_mu_pwr1', 
;'iug_mu_pwr2', 'iug_mu_pwr3', 'iug_mu_pwr4', 'iug_mu_pwr5', 'iug_mu_wdt1',
;'iug_mu_wdt2', 'iug_mu_wdt3', 'iug_mu_wdt4', 'iug_mu_wdt5', 'iug_mu_dpl1',
;'iug_mu_dpl2', 'iug_mu_dpl3', 'iug_mu_dpl4', 'iug_mu_dpl5', 'iug_mu_pn1',
;'iug_mu_pn2, 'iug_mu_pn3,'iug_mu_pn4, 'iug_mu_pn5:
;  uwnd = zonal wind:
;  vwnd = meridional wind
;  wwnd = vertical wind
;  pwr = echo intensity, wdt = spectral width, dpl = radial Doppler velocity,
;  pn = noise level
;===============================================================================
iug_load_mu, datatype = 'troposphere'

;Plot time-height distribution of zonal wind, and echo intensity, spectral width,
;radial Doppler velocity, and noise level for beam number 1 in the troposphere:
;===============================================================================
tplot,['iug_mu_trop_uwnd','iug_mu_trop_pwr1','iug_mu_trop_wdt1','iug_mu_trop_dpl1', 'iug_mu_trop_pn1']

stop

; Set up the plot time range of zonal wind, and echo intensity, spectral width,
;radial Doppler velocity, and noise level for beam number 1 in the troposphere:
;===============================================================================
tlimit, '1994-09-29 10:00:00', '1994-09-29 15:00:00'
tplot

stop

;=======================Ionosphere=======================================
;Specify timespan:
;=================
timespan,'1989-03-06',3,/day

;Load all the incoherent scatter observation data of the ionosphere 
;taken by the MU radar in timespan:
;Tplot variables are 'iug_mu_iono_Vperp_e', 'iug_mu_iono_Vperp_n', 'iug_mu_iono_Vpara_u', 'iug_mu_iono_Vpara_u', 
;'iug_mu_iono_Vz_ns', 'iug_mu_iono_Vz_ew', 'iug_mu_iono_Vd_b', 'iug_mu_iono_pwr1', 'iug_mu_iono_pwr2',
;'iug_mu_iono_pwr3', 'iug_mu_iono_pwr4':
;  Vperp_e = eastward ion drift perpendicular to the magnetic field
;  Vperp_n = northward ion drift perpendicular to the magnetic field
;  Vpara_u = Upward ion drift parallel to the magnetic field
;  Vz_ns = north-south ion drift
;  Vz_ew = east-west ion drift
;  Vd_b = ion drift parallel to each beam direction
;  pwr = echo intensity
;===============================================================================
iug_load_mu, datatype = 'ionosphere'

;Plot time-height distribution of eartward and northward drift velocity perpendicular  
;to the magnetic field and echo power for beam 1 and 2 in the ionosphere:
;=====================================================================================
tplot,['iug_mu_iono_Vperp_e','iug_mu_iono_Vperp_n','iug_mu_iono_Vpara_u','iug_mu_iono_pwr1', 'iug_mu_iono_pwr2']

stop

;=======================Meteor=======================================
;Specify timespan:
;=================
timespan,'1990-05-18',5,/day

;Load all the special observation data of meteor wind
;taken by the MU radar in timespan:
;Tplot variables are 'iug_mu_meteor_uwnd_h1t60min00', 'iug_mu_meteor_vwnd_h1t60min00',
;'iug_mu_meteor_uwndsig_h1t60min00', 'iug_mu_meteor_vwndsig_h1t60min00', 
;'iug_mu_meteor_mwnum_h1t60min00':
;  uwnd = zonal wind:
;  vwnd = meridional wind
;  uwndsig = standard deviation of zonal wind
;  vwndsig = standard deviation of meridional wind
;  mwnum = number of meteors used to derive the horizontal wind
;===============================================================================
iug_load_mu, datatype = 'meteor',parameter = 'h1t60min00'

;Plot time-height distribution of zonal and meridional winds, standard deviation of
;zonal and meridional winds and number of meteors used to derive the horizontal wind:
;=====================================================================================
tplot,['iug_mu_meteor_uwnd_h1t60min00','iug_mu_meteor_vwnd_h1t60min00','iug_mu_meteor_uwndsig_h1t60min00',$
       'iug_mu_meteor_vwndsig_h1t60min00', 'iug_mu_meteor_mwnum_h1t60min00']

stop

;==========================RASS=======================================
;Specify timespan:
;=================
timespan,'1996-10-27',10,/day

;Load all the special observation data of RASS
;taken by the MU radar in timespan:
;Tplot variables are 'iug_mu_rass_uwnd', 'iug_mu_rass_vwnd',
;'iug_mu_rass_wwnd', 'iug_mu_rass_temp':
;  uwnd = zonal wind:
;  vwnd = meridional wind
;  wwnd = vertical wind
;  temp = air temperature
;===============================================================================
iug_load_mu, datatype = 'rass'

;Plot time-height distribution of zonal and meridional winds, standard deviation of
;zonal and meridional winds and number of meteors used to derive the horizontal wind:
;=====================================================================================
tplot,['iug_mu_rass_uwnd','iug_mu_rass_vwnd','iug_mu_rass_wwnd',$
       'iug_mu_rass_temp']

stop

;==========================FAI=======================================
;Specify timespan:
;=================
timespan,'1986-08-05',10,/day

;Load all the special observation data of FAI
;taken by the MU radar in timespan:
;Tplot variables are 'iug_mu_fai_ifdp1t_dpl1', 'iug_mu_fai_ifdp1t_pwr1',
;'iug_mu_fai_ifdp1t_wdt1', 'iug_mu_fai_ifdp1t_snr1', 'iug_mu_fai_ifdp1t_pn1', and so on:

;===============================================================================
iug_load_mu, datatype = 'fai', parameter = 'ifdp1t'

;Plot time-height distribution of zonal and meridional winds, standard deviation of
;zonal and meridional winds and number of meteors used to derive the horizontal wind:
;=====================================================================================
tplot,['iug_mu_fai_ifdp1t_dpl1','iug_mu_fai_ifdp1t_pwr1','iug_mu_fai_ifdp1t_wdt1',$
       'iug_mu_fai_ifdp1t_snr1','iug_mu_fai_ifdp1t_pn1']

end


