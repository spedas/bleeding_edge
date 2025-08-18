;+
; ELF State crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to clrussell@igpp.ucla.edu
;
;
; $LastChangedBy: clrussell $
; $LastChangedDate: 2016-05-25 14:40:54 -0700 (Wed, 25 May 2016) $
; $LastChangedRevision: 21203 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elf/examples/basic/mms_load_state_crib.pro $
;-

;;    ============================
;; 1) Select date and time interval
;;    ============================
; download data for 8/2/2015
date = '2021-10-16/00:00:00'
timespan,date,1,/day
elf_init

;;    ===================================
;; 2) Select probe, datatype 
;;    ===================================
probe = 'a'
datatype = 'pos'    ; 'vel', ; to be added 'spinras', 'spindec'

elf_load_state, probes=probe, datatype=datatype
tplot, 'ela_pos_gei'
stop

; load velocity data only
elf_load_state, probes=['a', 'b'], datatype='vel_gei'
tplot, ['el*_vel_gei']
stop

; same with position
; no probe specified so will get all probes
; no level specified so will default to definitive data if available
elf_load_state
tplot, ['el*gei']
stop

; variables loaded so far
tplot_names
stop

; remove tplot variables created so far
del_data, 'ela*'

; set to future date
date = '2019-11-31/00:00:00'
timespan,date,1,/day

; request predictive data (because date is in the future) 
elf_load_state, probes= ['a'], datatype='pos_gei', /pred
tplot, ['ela_pos_gei']
stop

; request definitive data (because date is in the future definitive
; data will not be found. by default the routine will look for predicted
; when definitive is not found).
; TO DO - the elf_load_state routine only has access to pred so the load
;         routine is temporarily hard coded to use predicted. This will
;         change as soon as definitive data is automated.
timespan, '2019-06-12',1d
elf_load_state, probes= ['b'], datatype='vel_gei'
tplot, ['elb_vel_gei']
stop

; request other coordinate systems
timespan, '2019-02-12',1d
elf_load_state, probes= ['a'], datatype=['pos_mag', 'pos_gei']
tplot, ['ela_pos_gei','ela_pos_mag']
stop


;;    ===================================
;; 2) Use no_download flag
;;    ===================================
probe = 'a'
datatype = 'pos'    ; 'vel', ; to be added 'spinras', 'spindec'
timespan, '2019-02-12',1d
elf_load_state, probes=probe, datatype=datatype, /no_download
tplot, 'ela_pos_gei'
stop

;
del_data, '*'
Print, 'Done'

end