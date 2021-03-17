;+
; MMS State crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2020-08-25 14:54:30 -0700 (Tue, 25 Aug 2020) $
; $LastChangedRevision: 29084 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_load_state_crib.pro $
;-

;;    ============================
;; 1) Select date and time interval
;;    ============================
; download data for Oct 16 2015
date = '2015-10-16/00:00:00'
timespan,date,1,/day

;;    ===================================
;; 2) Select probe, level, and datatype
;;    ===================================
probe = '2'
level = 'def'     ; 'pred'
datatypes = 'pos'    ; 'vel', 'spinras', 'spindec'

mms_load_state, probes=probe, level=level, datatypes=datatypes
tplot, 'mms2_defeph_pos'
stop

; load attitude data only
mms_load_state, probes=['1', '2'], level='def', /attitude_only
tplot, ['mms*_defatt_*']
stop

; same with position 
; no probe specified so will get all 4 probes
; no level specified so will default to definitive data if available
mms_load_state, /ephemeris_only
tplot, ['mms*_defeph_*']
stop

; variables loaded so far
tplot_names
stop

; remove tplot variables created so far
del_data, 'mms*_def*'

; set to future date
date = '2040-11-31/00:00:00'
timespan,date,1,/day

; request definitive data (because date is in the future definitive
; data will not be found. by default the routine will look for predicted
; when definitive is not found).
mms_load_state, probes= ['1'], level='def', datatypes='pos'
tplot, ['mms*_defeph_*']
stop

; requesting predicted this time (result should be the same
; as above)
mms_load_state, probes= ['1','2'], level='pred', datatypes='pos'
tplot, ['mms*_predeph_*']
stop

; you can turn off automatic definitive or predicted data behavior
; (note that no data will be found since user requested definitive data
; and turned off default behavior 
; pick some date unlikely to occur
date = '2040-11-31/00:00:00'
timespan,date,1,/day
mms_load_state, probes= ['3'], level='def', datatypes='pos', pred_or_def=0

stop
end