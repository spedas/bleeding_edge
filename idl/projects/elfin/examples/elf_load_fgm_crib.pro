;+
; ELF FGM crib sheet
; This crib sheet shows how to load FGM data.  
; The FGM CDF file contains the following variables:
;    ela_fgs   ; FGM survey mode data with pseudo calibration applied
;    ela_fgs_fsp_res_dmxl   : FGM survey data, spin resolution, residual, in DMXL coordinates
;    ela_fgs_fsp_res_gei    : FGM survey data, spin resolution, residual, in GEI coordinates
;    ela_fgs_fsp_igrf_dmxl  : spin resolution IGRF, in DMXL coordinates
;    ela_fgs_fsp_igrf_gei   : spin resolution IGRF, in GEI coordinates
;    ela_fgs_fsp_res_trend  : ela_fgs_fsp_res data detrended
; The elf_load_fgm routine loads the following tplot variables
;    ela_fgs   
;    ela_fgs_fsp_res_dmxl  
;    ela_fgs_fsp_res_gei    
;    ela_fgs_fsp_res_ndw  ; NDW coordinates: N=north (spherical -theta, positive North), D=radial down (spherical -r)
;         W=west (spherical -phi)
;    ela_fgs_fsp_res_obw  ; OWV coordinates: B=along model field, O=normal to b but outwards from Earth,
;         W=normal to b but westward: w = (rxb)/|rxb|, where r is satellite position
; The /get_support_data keyword also loads state and IGRF data
; 
; NOTE: **** Not all FGM CDFs contain the new spin resolved data. Testing and Reprocessing of all FGM CDFs is in progress
;
; $LastChangedBy: clrussell $
; $LastChangedDate: 2016-05-25 14:40:54 -0700 (Wed, 25 May 2016) $
; $LastChangedRevision: 21203 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elf/examples/basic/mms_load_state_crib.pro $
;-

;; Initialize elfin system variables
elf_init

;;    ============================
;; 1) Select date and time interval
;;    ============================
; download data for 8/2/2015
date = '2022-01-01/00:00:00'
timespan,date,1,/day
tr=timerange()

;;    ===================================
;; 2) Select probe, datatype
;;    ===================================
probe = 'a'          ; if no probe is specified the routine will default to probe a
elf_load_fgm, probes=probe, /no_download
tplot, 'ela_fgs'
stop

; commented out until ELB data is ready
;;    ===================================
;; 3) Select probe b
;;    ===================================
;probe = 'b'          
;elf_load_fgm, probes=probe, /no_download
;tplot, ['elb_fgs_fsp_res_dmxl','elb_fgs_fsp_res_gei','elb_fgs_fsp_res_ndw','elb_fgs_fsp_res_obw']
;stop

;;    ===================================
;; 4) Use get_support_data keyword 
;;    ===================================
probe = 'a'
elf_load_fgm, trange=tr, probes=probe, /get_support_data
tplot, ['ela_fgs_fsp_res_dmxl','ela_fgs_fsp_res_gei','ela_fgs_fsp_igrf_dmxl','ela_fgs_fsp_igrf_gei']
stop
tplot, ['ela_fgs_fsp_pos_gei','ela_fgs_fsp_vel_gei','ela_fgs_fsp_att_gei']
;  NOTE - Use tlimit to zoom into science zones
stop

;;    ===================================
;; 5) Set no download flag
;;    ===================================
probe = ['a']         
elf_load_fgm, trange=tr, probes=probe, /no_download
tplot, ['ela_fgs_fsp_res_dmxl','ela_fgs_fsp_res_gei','ela_fgs_fsp_res_ndw','ela_fgs_fsp_res_obw']
;  NOTE - Use tlimit to zoom into science zones
stop

;;    ===================================
;; 6) Add suffix to tplot name
;;    ===================================
probe = ['b']
elf_load_fgm, trange=tr, probes=probe, suffix='_test', /no_download
tplot_names
stop

; remove tplot variables created so far
del_data, 'el*'

end