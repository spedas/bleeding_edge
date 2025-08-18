;+
;NAME:
; run_mvn_over_shell30
;PURPOSE:
; Designed to run from a cronjob, sets up a lock file, and
; processes the single-instrument plots from thirty days ago. If the
; lock file exists, no processing. Added 7, 14 day reprocess, jmm,
; 2020-12-30.
;CALLING SEQUENCE:
; run_mvn_over_shell30, ndays_offset = ndays_offset
;INPUT:
; none
;OUTPUT:
; none
;KEYWORDS:
; ndays_offset = days from now that is being processed, the default is
;                [3,7,14,30].
;HISTORY:
; 8-dec-2020, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2024-05-28 13:41:50 -0700 (Tue, 28 May 2024) $
; $LastChangedRevision: 32654 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/run_mvn_over_shell30.pro $
;-

Pro run_mvn_over_shell30, ndays_offset = ndays_offset

  test_file = file_search('/mydisks/home/maven/muser/MVN_OVER_SHELL30lock.txt')
  If(is_string(test_file[0])) Then Begin
     message, /info, 'Lock file /mydisks/home/maven/muser/MVN_OVER_SHELL30lock.txt Exists, Returning'
  Endif Else Begin
     test_file = '/mydisks/home/maven/muser/MVN_OVER_SHELL30lock.txt'
     spawn, 'touch '+test_file[0]
     If(keyword_set(ndays_offset)) Then ndays = ndays_offset $
     Else ndays = [3, 7, 14, 30]
     ndays_str = string(ndays, format='(i2.2)')
     date = systime(/sec)
;Subtract the number of days, do for 7, 14 and 30 days
     For j = 0, n_elements(ndays)-1 Do Begin
        datej = date - ndays[j]*86400.0d0
        datej = time_string(datej, precision = -3)
        message, /info, 'PROCESSING: '+datej
        mvn_over_shell, date = datej
     Endfor
     message, /info, 'Removing Lock file /mydisks/home/maven/muser/MVN_OVER_SHELL30lock.txt'
     file_delete, test_file[0]
  Endelse

  Return

End

