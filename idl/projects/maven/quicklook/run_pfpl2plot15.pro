;+
;NAME:
; run_pfpl2plot15
;PURPOSE:
; Designed to run from a cronjob, sets up a lock file, and
; processes. It the lock file exists, no processing. This program
; process the most recent N depending on the num_days keyword, default
; value is 15.
;CALLING SEQUENCE:
; run_pfpl2plot15, num_days = num_days
;INPUT:
; none
;OUTPUT:
; none
;KEYWORDS:
; num_days =  process the last num_days days, default is 15
;HISTORY:
; 19-oct-2023, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

Pro run_pfpl2plot15, num_days = num_days

  test_file = file_search('/mydisks/home/maven/muser/PFPL2PLOT15lock.txt')
  If(is_string(test_file[0])) Then Begin
     message, /info, 'Lock file /mydisks/home/maven/muser/PFPL2PLOT15lock.txt Exists, Returning'
  Endif Else Begin
     test_file = '/mydisks/home/maven/muser/PFPL2PLOT15lock.txt'
     spawn, 'touch '+test_file[0]
     If(keyword_set(num_days)) Then n = num_days Else n = 15
     one_day = 86400.0
     date0 = time_double(time_string(systime(/sec),precision=-3))-(n-1.0)*one_day
     days_in = time_string(date0+one_day*indgen(n))
     mvn_call_pfpl2plot, days_in = days_in
     message, /info, 'Removing Lock file /mydisks/home/maven/muser/PFPL2PLOT15lock.txt'
     file_delete, test_file[0]
  Endelse

  Return

End

