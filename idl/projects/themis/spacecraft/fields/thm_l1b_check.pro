;+
;NAME:
;thm_l1b_check
;PURPOSE:
;Tests for L1B (Estimated spin-axis Bz from spin-plane components),
;FGM data. Currently (as of 2025-01-28) used only for THEMIS E, post
;2024-05-25
;CALLING SEQUENCE:
;file = thm_l1b_check(date, probe)
;INPUT:
;date = date for data check
;probe = probe (currently only 'e' will give a non-blank answer)
;OUTPUT:
;file = L1B file with data for the given day, full path
;HISTORY:
;hacked from THM_L2GEN_FGM, 2025-01-25, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
Function thm_l1b_check, date, probe

  thm_init
  thx = 'th'+probe[0]
  If((thx Eq 'the') && (time_double(date) Ge time_double('2024-05-25'))) Then Begin
;check for L1B data, if there is a file, then we move on, otherwise return
     date0 = time_string(date, tformat = 'YYYYMMDD')
     year0 = strmid(date0, 0, 4)
     fullfile = file_dailynames(thx+'/l1b/fgm/', thx+'_l1b_fgm_', '_v01.cdf', $
                                /yeardir, trange = time_double(date)+[0.0,86400.0d0])
     l1b_file = spd_download(remote_file = fullfile, _extra = !themis)
     If(is_string(file_search(l1b_file))) Then Begin
        Return, l1b_file
     Endif Else Return, ''
  Endif Else Return, ''
End

  
