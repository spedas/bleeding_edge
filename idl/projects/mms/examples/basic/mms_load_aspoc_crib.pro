;+
; MMS ASPOC crib sheet
; 
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;     
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-08-14 12:44:51 -0700 (Mon, 14 Aug 2023) $
; $LastChangedRevision: 31998 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_load_aspoc_crib.pro $
;-

;;  example  for mms1
scid='1'

;; load l2  data for MMS 1    (merged data for aspoc1 and aspoc2)
mms_load_aspoc, trange=['2015-10-16', '2015-10-17'], probe=scid, level='l2'

;; Make tplot parameter for combined aspoc ion current using l2 data
;;
join_vec, 'mms'+scid+['_aspoc_ionc_l2', '_asp1_ionc_l2', '_asp2_ionc_l2'], 'mms'+scid+'_asp_ionc_all'

; plot ion current from aspoc1, aspoc2, and total current,  all current in one panel,  onboard processed spacecraft potential
;
tplot, 'mms'+scid+['_asp1_ionc_l2','_asp2_ionc_l2','_aspoc_ionc_l2','_asp_ionc_all']
stop

;; example for L1b data (note: SDC password required)

;; load l1b  data for MMS 1    (datatype can be set either asp1 or  asp2)
mms_load_aspoc, trange=['2015-10-16', '2015-10-17'], probe=scid, datatype='asp1', level='l1b'

tplot, 'mms'+scid+['_asp1_ionc_l1b', '_asp1_spot_l1b']

end