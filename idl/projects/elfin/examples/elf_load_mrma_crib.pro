;+
; ELF MRMa crib sheet
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
date = '2018-11-01/00:00:00'
timespan,date,1,/day

;;    ===================================
;; 2) Select probe, datatype
;;    ===================================
probe = 'a'
datatype = 'mrma'    ; mrma is the only data type

elf_load_mrma, probes=probe, datatype='mrma'
stop
tplot, 'ela_mrma'
stop

; load mrma data only
elf_load_mrma, probes=['b']
tplot, 'elb_mrma'

; variables loaded so far
tplot_names
stop

; use no_download flag
date = '2018-11-01/03:06:00'
timespan,date,120.,/sec
elf_load_mrma, probes=probe, datatype='mrma'
tplot, 'ela_mrma'
stop


; remove tplot variables created so far
del_data, 'el*'

end