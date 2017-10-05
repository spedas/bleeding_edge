;+
; Returns the start and end indices of intervals where a condition
; applies
;-
PRO Temp_st_en, condition, st_ss, en_ss, ok=ok

   n = N_ELEMENTS(condition)
   ok = where(condition, nok)
   IF(nok EQ 0) THEN BEGIN
      st_ss = 0
      en_ss = n-1
   ENDIF ELSE BEGIN
      IF(nok EQ 1) THEN BEGIN
         st_ss = ok[0]
         en_ss = ok[0]
      ENDIF ELSE BEGIN
         qq = [5000, ok[1:*]-ok]
         st_ss = ok[where(qq NE 1)]
         qq = [ok[1:*]-ok, 5000]
         en_ss = ok[where(qq NE 1)]
      ENDELSE
   ENDELSE

   RETURN
END
;+
;NAME:
;thm_efi_sdt_test
;PURPOSE:
;Checks houesekeeping data to flag the presence of EFI SDT (Sensor
;Diagnostic Tests).
;CALLING SEQUENCE:
;thm_efi_sdt_test, probe=probe, trange=trange
;INPUT:
;All via keyword
;OUTPUT:
;None explicit, instead the program creates a tplot variable with an
;sdt_flag for each HSK data point, 'th?_efi_sdt_flag' is set to 1, if
;there is an SDT.
;KEYWORDS:
;probe = The default is: ['a', 'b', 'c', 'd', 'e']
;trange  = (Optional) Time range of interest  (2 element array), if
;this is not set, the default is to use any timespan that has been
;previously set, and then to prompt the user. Note that if the input
;time range is not a full day, a full day's data is loaded
;textend = the extension time for the data, in seconds. Sdt's typically last
;for 2.5 hours, so the input time range is by default extended by 3
;hours. the keyword textend can be used to change this.
;min_dt = the minimum duration for an SDT, default is 20 minutes (1200
;seconds). 
;HISTORY:
; 2014-10-13, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-10-28 15:13:18 -0700 (Wed, 28 Oct 2015) $
; $LastChangedRevision: 19178 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/thm_efi_sdt_test.pro $
;-
Pro thm_efi_sdt_test, probe = probe, trange = trange, $
                      ibias_ddt = ibias_ddt, $
                      textend = textend, $
                      test_dt = test_dt, $
                      min_dt = min_dt, $
                      _extra=_extra
  
  If(keyword_set(textend)) Then text = textend $
  Else text = 3.0*3600.0d0

  If Keyword_set(test_dt) Then dt0 = test_dt Else dt0 = 125.0

  If(keyword_set(min_dt)) Then dtmin = min_dt Else dtmin = 1200.0 

  If(keyword_set(ibias_ddt)) Then ibdt = ibias_ddt $
  Else ibdt = 12.5

  If (keyword_set(trange) && n_elements(trange) Eq 2) Then Begin
     tr0 = timerange(trange)
  Endif Else tr0 = timerange()
  tr = tr0+[-text, text]

;Given the tr value, load the hsk data
  If(keyword_set(probe)) Then Begin
     sc = thm_valid_input(probe, 'probe', vinput='a b c d e', $
                          definput = ['a', 'b', 'c', 'd', 'e'], $
                          /include_all)
  Endif Else sc = ['a', 'b', 'c', 'd', 'e']

  thm_load_hsk, probe = sc, trange = tr

  thx = 'th'+sc
  nsc = n_elements(sc)
  For isc = 0, nsc-1 Do Begin
     d = 0 & x = 0 & y = 0 & ynew = 0 ;probably not needed
     vhvars = tnames(thx[isc]+['*ibias_raw', '*guard_raw', '*usher_raw'])
     If(n_elements(vhvars) Ne 3) Then Begin
        dprint, 'Insufficient HSK data'
        Return
     Endif
     deriv_data, vhvars
;Use the ibias data to create a flag
     bvar = tnames(thx[isc]+'*ibias_raw_ddt')
     If(is_string(bvar) Eq 0) Then Begin
        dprint, 'Missing variable: '+thx[isc]+'*ibias_raw_ddt'
        Continue
     Endif
     bvar = bvar[0]
     get_data, bvar, data = dbvar
     ny = n_elements(dbvar.y[0,*])
     For k = 0, ny-1 Do Begin
        If(k Eq 0) Then ck = abs(dbvar.y[*, k]) Gt ibdt $
        Else ck = ck + (abs(dbvar.y[*, k]) Gt ibdt)
     Endfor
     fvar0 =  thx[isc]+'_efi_sdt_hsk'
     d = {x:dbvar.x, y:((ck/2.0)<1)}
     store_data, fvar0, data = d
     options, fvar0, 'yrange', [0.0, 1.20]
;Get sdt start and end times, if they exist
     flag = d.y eq 1
     temp_st_en, flag, st_ss, en_ss, ok = ok
     If(ok[0] Eq -1) Then Begin
        fvar = thx[isc]+'_efi_sdt_flag'
        store_data, fvar, data = d
        options, fvar, 'yrange', [0.0, 1.20]
     Endif Else Begin
        st_time = d.x[st_ss]
        en_time = d.x[en_ss]
;Now concatenate the intervals if there is a LT 125 second difference
;between the end time of an interval and the start time of the next
        n = n_elements(st_ss)
        keep = bytarr(n)+1
        For k = 0, n-2 Do Begin
           If(keep[k]) Then Begin
              k1 = k
              Repeat Begin
                 k1 = k1+1
                 If((st_time[k1]-en_time[k]) Lt dt0) Then Begin
                    keep[k1] = 0b
                    en_time[k] = en_time[k1]
                 Endif
              Endrep Until k1 Eq n-1 Or keep[k1] Eq 1
           Endif
        Endfor
        ok = where(keep Gt 0, nok) ;nok can't be zero here...
        st_time = st_time[ok]
        st_ss = st_ss[ok]
        en_time = en_time[ok]
        en_ss = en_ss[ok]
;SDT's take a while, so do not flag any interval that is
;shorter than 20 minutes
        n = n_elements(st_ss)
        keep = bytarr(n)+1
        For k = 0, n-1 Do Begin
           If((en_time[k]-st_time[k]) Lt dtmin) Then keep[k] = 0b
        Endfor
        ok = where(keep Gt 0, nok) ;nok can be zero here...
        If(nok Eq 0) Then Begin
           ynew = d.y & ynew[*] = 0
           st_ss = -1 & en_ss = -1
        Endif Else Begin
           st_time = st_time[ok]
           st_ss = st_ss[ok]
           en_time = en_time[ok]
           en_ss = en_ss[ok]
;reset flag array
           n = n_elements(st_ss)
           ynew = d.y & ynew[*] = 0
           For k = 0, n-1 Do Begin
              ynew[st_ss[k]:en_ss[k]] = 1
           Endfor
        Endelse
        fvar = thx[isc]+'_efi_sdt_flag'
        store_data, fvar, data = {x:d.x, y:ynew}
        options, fvar, 'yrange', [0.0, 1.20]
     Endelse
;Clip the data
     time_clip, fvar, tr0[0], tr0[1], /replace
;Set up a sparse start and end time variable
     get_data, fvar, data = d
     nd = n_elements(d.x)
     flag = d.y eq 1
     temp_st_en, flag, st_ss, en_ss, ok = ok
     n = n_elements(st_ss)
     fsparse = thx[isc]+'_efi_sdt_flag_sparse'
     If(ok[0] Eq -1) Then Begin
        store_data, fsparse, {x:minmax(d.x), y:[0, 0]}
     Endif Else Begin
        en_ss1 = (en_ss+1) < (nd-1) ;we want the subscripts of the end of time intervals here
;Do this interval by interval
        x = [d.x[st_ss[0]], d.x[en_ss1[0]]]
        If(en_ss[0] Eq nd-1) Then y = [1, 1] $ ;If the last interval is flagged, keep it
        Else y = [1, 0]
        If(n Gt 1) Then Begin
           For j = 1, n-1 Do Begin
              x = [x, d.x[st_ss[j]], d.x[en_ss1[j]]]
              If(en_ss[j] Eq nd-1) Then y = [y, 1, 1] $
              Else y = [y, 1, 0]
           Endfor
        Endif
;Add zero points on the ends if needed
        If(st_ss[0] Gt 0) Then Begin
           x = [d.x[0], x]
           y = [0, y]
        Endif
        If(en_ss[n-1] Lt nd-1) Then Begin
           x = [x, d.x[nd-1]]
           y = [y, 0]
        Endif
        store_data, fsparse, data = {x:x, y:y}
     Endelse
     options, fsparse, 'yrange', [0.0, 1.20]
  Endfor
  Return
End
