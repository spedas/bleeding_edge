;+
; ELF MRMi crib sheet
;
; NOTE:  *** THIS Crib is obsolete. MRMI data is not collected. ***
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
date = '2018-11-14/00:00:00'
timespan,date,1,/day
del_data, 'el*'

;;    ===================================
;; 2) Select probe, datatype
;;    ===================================
probe = 'a'
datatype = 'mrmi'    ; mrma is the only data type

elf_load_mrmi, probes=probe, datatype=datatype
tplot, 'ela_mrmi'
stop

; variables loaded so far
tplot_names
stop

date = '2018-11-14/02:00:00'
timespan,date,21600.,/sec
elf_load_mrmi, probes=probe, datatype=datatype, /no_download
tplot, 'ela_mrmi'
stop

; remove tplot variables created so far
del_data, 'el*'

end