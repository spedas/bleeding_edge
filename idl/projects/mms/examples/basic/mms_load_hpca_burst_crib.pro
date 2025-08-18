;+
; MMS HPCA burst data crib sheet
;
; This crib sheet shows basic usage of the HPCA routines for burst data in SPEDAS; 
;   it shows how to load the data and creates the following figures:
;       1) H+, O+, He+ number density
;       2) H+, O+ and He+ scalar temperature
;       3) H+, O+ and He+, He++ bulk velocity
;       4) H+, O+, He+, He++ flux averaged over anodes=[0, 15]
;       5) H+ flux averaged over fov= 0-360deg, 0-180deg, 180-360deg
;       6) H+, O+, He+, He++ flux averaged over full FoV
;       
;       
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;     
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-08-14 12:44:51 -0700 (Mon, 14 Aug 2023) $
; $LastChangedRevision: 31998 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_load_hpca_burst_crib.pro $
;-

; zoom into the burst interval
timespan, '2015-10-16/13:00', 10, /min

mms_load_hpca, probes='1', datatype='moments', data_rate='brst', level='l2', /latest_version

; show H+, O+ and He+ density
tplot, ['mms1_hpca_hplus_number_density', $
  'mms1_hpca_oplus_number_density', $
  'mms1_hpca_heplus_number_density']
stop

; show H+, O+ and He+ temperature
tplot, ['mms1_hpca_hplus_scalar_temperature', $
  'mms1_hpca_oplus_scalar_temperature', $
  'mms1_hpca_heplus_scalar_temperature']
stop

; show H+, O+ and He+ flow velocity
tplot, 'mms1_hpca_*_ion_bulk_velocity'
stop

; load the burst mode ion data
mms_load_hpca, probes='1', datatype='ion', data_rate='brst', level='l2', /latest_version

; average over nodes
mms_hpca_calc_anodes, anode=[5, 6], probe=1 ; average anodes=5, 6
mms_hpca_calc_anodes, anode=[13, 14], probe=1 ; average anodes=13, 14
mms_hpca_calc_anodes, anode=[0, 15], probe=1 ; average anodes=0, 15

flux_burst = ['mms1_hpca_hplus_flux_anodes_0_15', $
  'mms1_hpca_oplus_flux_anodes_0_15', $
  'mms1_hpca_heplus_flux_anodes_0_15', $
  'mms1_hpca_heplusplus_flux_anodes_0_15']

; don't interpolate through the gaps
tdegap, flux_burst, /overwrite

; show spectra for H+, O+ and He+, He++
tplot, flux_burst
stop

; average over various FOV's (0-360, 0-180, 180-360)
mms_hpca_calc_anodes, fov=[0, 360], probe='1'
mms_hpca_calc_anodes, fov=[0, 180], probe='1'
mms_hpca_calc_anodes, fov=[180, 360], probe='1'

; don't interpolate through the gaps
tdegap, 'mms1_hpca_*plus_flux_elev_*', /overwrite

; plot each view
tplot, ['mms1_hpca_hplus_flux_elev_*']  
stop

; plot each species
tplot, ['mms1_hpca_*plus_flux_elev_0-360']
stop
end