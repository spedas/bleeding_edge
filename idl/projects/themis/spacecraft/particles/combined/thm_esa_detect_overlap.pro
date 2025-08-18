;+
;NAME:
;thm_esa_detect_overlap
;PURPOSE:
;Detects mode overlap that occasionally occurs in ESA data, this
;function compares the times for different ESA modes, if there is
;overlap, as indicated by a mode end time greater than or equal to the
;start time of the following mode, then an overlap is flagged. This
;should be used for reprocessing gmom data files that had entire modes
;removed due to overlaps.
;CALLING SEQUENCE:
;overlap_flag = thm_esa_detect_overlap(date = date, probe = probe)
;INPUT:
; via keyword
;OUTPUT:
;overlap_flag = 1, if overlap is detected, = 0 otherwise
;KEYWORDS:
;date = the date, the default is to let thm_load_esa_pkt prompt for
;one
;probe = the probe, the default is 'a'
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2020-08-18 10:11:19 -0700 (Tue, 18 Aug 2020) $
;$LastChangedRevision: 29044 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/combined/thm_esa_detect_overlap.pro $
;-
Function thm_esa_detect_overlap, date = date, probe = probe, plot = plot

  otp = 0
  If(~keyword_set(probe)) Then probe = 'a'

  If(keyword_set(date)) Then timespan, date, 1

  thm_load_esa_pkt, probe=probe

;check all datatypes
  dtyp = ['peef', 'peif', 'peer', 'peir', 'peeb', 'peib']
  ndtyp = n_elements(dtyp)
  tr = timerange()
  For j = 0, ndtyp-1 Do Begin
     data = thm_part_dist_array(probe = probe, type = dtyp[j], trange = tr)
     If(n_elements(data) Eq 1) Then continue ;can't be an overlap
     max_times = dblarr(n_elements(data))
     min_times = max_times
     For i = 0, n_elements(data)-1 Do Begin
        max_times[i] = max((*data[i]).end_time, /nan)
        min_times[i] = min((*data[i]).time, /nan)
     Endfor
     idx = where(max_times[0:n_elements(data)-2] Ge min_times[1:n_elements(data)-1], c)
     If(c Gt 0) Then Begin
        If(keyword_set(plot)) Then Begin
           Case dtyp[j] Of
              'peif':oops_dtyp = 'ptiff'
              'peef':oops_dtyp = 'pteff'
              'peir':oops_dtyp = 'ptirf'
              'peer':oops_dtyp = 'pterf'
              'peib':oops_dtyp = 'ptibb'
              'peeb':oops_dtyp = 'ptebb'
           End
           thm_load_gmom, probe=probe[0], datatype = '*'+oops_dtyp+'*'
           oops_var = 'th'+probe[0]+'_'+oops_dtyp+'_en_eflux'
           tplot, oops_var
        Endif
        message, /info, 'Overlap Detected: '
        print, 'Probe: '+probe[0]
        print, 'Datatype: '+dtyp[j]
        print, 'DATE: '+time_string(tr[0], prec = -3)
        otp = 1
        Return, otp
     Endif
  Endfor
  message, /info, 'No overlaps for: '
  print, 'Probe: '+probe[0]
  print, 'DATE: '+time_string(tr[0], prec = -3)
  Return, otp
End
