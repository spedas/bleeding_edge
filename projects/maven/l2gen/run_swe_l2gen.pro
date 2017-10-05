;+
;NAME:
; run_swe_L2gen
;PURPOSE:
; Designed to run from a cronjob, sets up a lock file, and
; processes. It the lock file exists, no processing
;CALLING SEQUENCE:
; run_swe_l2gen, noffset_sec = noffset_sec
;INPUT:
; none
;OUTPUT:
; none
;KEYWORDS:
; none
;HISTORY:
; 25-jun-2014, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

Pro run_swe_l2gen

  test_file = file_search('/mydisks/home/maven/muser/SWEL2lock.txt')
  If(is_string(test_file[0])) Then Begin
     message, /info, 'Lock file /mydisks/home/maven/muser/SWEL2lock.txt Exists, Returning'
  Endif Else Begin
     test_file = '/mydisks/home/maven/muser/SWEL2lock.txt'
     spawn, 'touch '+test_file[0]
     mvn_call_swe_l2gen
     message, /info, 'Removing Lock file /mydisks/home/maven/muser/SWEL2lock.txt'
     file_delete, test_file[0]
  Endelse

  Return

End

