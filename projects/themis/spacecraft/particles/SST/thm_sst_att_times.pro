; Uses similar calculation to thm_sst_quality_flags to get appropriate
; attenuator transition times. These are saved in times0 variables,
; times 30 second eariler are saved in the times1 variables, times 30
; second before that are saved in the times2 variables
; Swapped positions of psif, psef variables in the procedure
; definition, 2021-03-30
; hsi_ql_st_en returns the start and end indices of intervals where a
; condition applies.
;-
PRO hsi_ql_st_en, condition, st_ss, en_ss, ok=ok

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
Pro thm_sst_att_times, probe, date, dur = dur, $
                       psif_times, psef_times, $ ;times padded by 1
                       psif_st_en, psef_st_en, $
                       psif_times1, psef_times1, $ ;times with buffer
                       psif_st_en1, psef_st_en1, $
                       buffer = buffer
;ps?f_st_en1, are for the times one more step of buffer away, for
;derivative options
;outputs are 4xN, end time of att 10 (open), start of att 5(closed)
;end of 5, start of 10. time = 0, index = -1 for transitions that are
;not in the duration, added 30 second buffer, 2021-01-27
;Added second buffer, 2021-02-08
;Saves unbuffered times, 2021-02-24
;Instead of unbufffered ttimes, uses same calculation as
;thm_sst_qualiy_flags, which throws out 1 data point in each direction
;from transiston.
  psef_times = -1 & psif_times = -1
  psef_st_en = -1 & & psif_st_en = -1
  psef_times1 = -1 & psif_times1 = -1
  psef_st_en1 = -1 & & psif_st_en1 = -1

  If(n_elements(buffer) Gt 0) Then dtb = buffer Else dtb = 30.0

;Check to see if data are loaded, if not load
  thx = 'th'+probe[0]
  get_data, thx+'_psif_count_rate', data = c
  If(~is_struct(c)) Then Begin
     If(~keyword_set(dur)) Then dur = 1
     timespan, date, dur
     thm_load_sst2, probe = probe
     get_data, thx+'_psif_count_rate', data = c
     If(~is_struct(c)) Then Return ;no data
  Endif

  dtyp = ['i', 'e']
  For j = 0, 1 Do Begin
     dd = 'ps'+dtyp[j]+'f'
     get_data, thx+'_'+dd+'_count_rate', data = cj
     If(~is_Struct(cj)) Then Begin
        dprint, 'No rate data for: '+dd
        print, time_string(date)
        Return
     Endif    
     thm_load_sst2_atten2, thx+'_'+dd+'_data' ;this is sometimes
;     wrong, e.g., thd 2010-04-01, not shifted as in thm_psif_load, etc...
     get_data, thx+'_'+dd+'_atten', data = aj
     If(~is_struct(aj)) Then Begin
        dprint, 'No Atten data for: '+dd
        print, time_string(date)
        Return
     Endif
     If(n_elements(aj.x) Ne n_elements(cj.x)) Then Begin
        dprint, 'time array mismatch for: '+dd
        print, time_string(date)
        Return
     Endif
;find start and end times of attenuator in (both)
     c1 = aj.y Eq 5             ; And cj.y Gt 0
     hsi_ql_st_en, c1, st_ss, en_ss, ok=ok
     If(ok[0] Eq -1) Then Return
     nintv = n_elements(st_ss)
     ndset = n_elements(c1)
     nds1 = ndset-1
;Here, unpad the st_ss, en_ss indices by 1, -1
     If(j Eq 0) Then Begin ;ions
        psif_st_en = lonarr(4, nintv)-1
        psif_times = dblarr(4, nintv)
        psif_st_en1 = psif_st_en
        psif_times1 = psif_times
        st_ss1 = (st_ss+1) < nds1
        en_ss1 = (en_ss-1) > 0
        psif_st_en[1, *] = st_ss1
        psif_st_en[2, *] = en_ss1
        psif_times[1, *] = cj.x[st_ss1]
        psif_times[2, *] = cj.x[en_ss1]
        For k = 0, nintv-1 Do Begin
           If(dtb Gt 0) Then Begin ;reset intervals less than 10*dtb
              If(psif_times[2, k]-psif_times[1, k] Lt 10.0*dtb) Then Begin
                 psif_st_en[1, k] = -1 & psif_st_en[2, k] = -1
                 psif_times[1, k] = 0 & psif_times[2, k] = 0
                 Continue
              Endif
           Endif
           ipre = st_ss[k]
           If(ipre Gt 0) Then Begin
              Repeat Begin
                 ipre--
                 test_10 = aj.y[ipre]
              Endrep Until test_10 Eq 10 Or ipre Eq 1
;testing counts here is ok, since attenuators out should have non-zero
;count rates, subtract 1 as buffer
              ipre = (ipre-1) > 0
              If(cj.y[ipre] Gt 0 and aj.y[ipre] Eq 10) Then Begin
                 psif_st_en[0, k] = ipre
                 psif_times[0, k] = cj.x[ipre]
              Endif
           Endif
           ipst = en_ss[k]
           If(ipst Lt nds1) Then Begin
              Repeat Begin
                 ipst++
                 test_10 = aj.y[ipst]
              Endrep Until test_10 Eq 10 Or ipst Eq nds1
;pad by one here
              ipst = (ipst+1) < nds1
              If(cj.y[ipst] Gt 0 And aj.y[ipst] Eq 10) Then Begin
                 psif_st_en[3, k] = ipst
                 psif_times[3, k] = cj.x[ipst]
              Endif
           Endif
;Adjust for time buffer
           psif_times1[*, k] = psif_times[*, k]
           psif_st_en1[*, k] = psif_st_en[*, k]
           If(dtb Gt 0) Then Begin
              If(psif_times1[0, k] Gt 0) Then Begin ;check for zeros
                 ttime = psif_times1[0, k]-dtb
                 yyy = max(where(cj.x Le ttime))
                 If(yyy[0] Eq -1) Then Begin
;remove this one, shouldn't happen often
                    Psif_Drop_0: 
                    psif_st_en1[0, k] = -1
                    psif_times1[0, k] = 0.0
                 Endif Else Begin
;If state changes, drop this one
                    test_10or5 = where(aj.y[yyy:psif_st_en1[0, k]] Ne 10)
                    If(test_10or5[0] Ne -1) Then Goto, Psif_Drop_0
                    psif_times1[0, k] = cj.x[yyy]
                    psif_st_en1[0, k] = yyy
                 Endelse
              Endif
              If(psif_times1[1, k] Gt 0) Then Begin
                 ttime = psif_times1[1, k]+dtb
                 yyy = min(where(cj.x Ge ttime))
                 If(yyy[0] Eq -1) Then Begin
                    Psif_Drop_1: 
                    psif_st_en1[1, k] = -1
                    psif_times1[1, k] = 0.0
                 Endif Else Begin
                    test_10or5 = where(aj.y[psif_st_en1[1, k]:yyy] Ne 5)
                    If(test_10or5[0] Ne -1) Then Goto, Psif_Drop_1
                    psif_times1[1, k] = cj.x[yyy]
                    psif_st_en1[1, k] = yyy
                 Endelse
              Endif
              If(psif_times1[2, k] Gt 0) Then Begin
                 ttime = psif_times1[2, k]-dtb
                 yyy = max(where(cj.x Le ttime))
                 If(yyy[0] Eq -1) Then Begin
                    Psif_Drop_2: 
                    psif_st_en1[2, k] = -1
                    psif_times1[2, k] = 0.0
                 Endif Else Begin
                    test_10or5 = where(aj.y[yyy:psif_st_en1[2, k]] Ne 5)
                    If(test_10or5[0] Ne -1) Then Goto, Psif_Drop_2
                    psif_times1[2, k] = cj.x[yyy]
                    psif_st_en1[2, k] = yyy
                 Endelse
              Endif
              If(psif_times1[3, k] Gt 0) Then Begin
                 ttime = psif_times1[3, k]+dtb
                 yyy = min(where(cj.x Ge ttime))
                 If(yyy[0] Eq -1) Then Begin
                    Psif_Drop_3: 
                    psif_st_en1[3, k] = -1
                    psif_times1[3, k] = 0.0
                 Endif Else Begin
                    test_10or5 = where(aj.y[psif_st_en1[3, k]:yyy] Ne 10)
                    If(test_10or5[0] Ne -1) Then Goto, Psif_Drop_3
                    psif_times1[3, k] = cj.x[yyy]
                    psif_st_en1[3, k] = yyy
                 Endelse
              Endif
           Endif
        Endfor
        ok_flag = bytarr(nintv) ;in case an entire interval is thrown out
        For k = 0, nintv-1 Do Begin
           If(total(psif_times) Ne 0) Then ok_flag[k] = 1
        Endfor
        keep = where(ok_flag Ne 0, nok)
        If(nok Gt 0) Then Begin
           psif_times = psif_times[*, keep]
           psif_st_en = psif_st_en[*, keep]
           psif_times1 = psif_times1[*, keep]
           psif_st_en1 = psif_st_en1[*, keep]
        Endif Else Begin
           psif_times = -1
           psif_st_en = -1
           psif_times1 = -1
           psif_st_en1 = -1
        Endelse
     Endif Else Begin           ;electrons
        psef_st_en = lonarr(4, nintv)-1
        psef_times = dblarr(4, nintv)
        psef_st_en1 = psef_st_en
        psef_times1 = psef_times
        st_ss1 = (st_ss+1) < nds1
        en_ss1 = (en_ss-1) > 0
        psef_st_en[1, *] = st_ss1
        psef_st_en[2, *] = en_ss1
        psef_times[1, *] = cj.x[st_ss1]
        psef_times[2, *] = cj.x[en_ss1]
        For k = 0, nintv-1 Do Begin
           If(dtb Gt 0) Then Begin ;reset intervals less than 10*dtb
              If(psef_times[2, k]-psef_times[1, k] Lt 10.0*dtb) Then Begin
                 psef_st_en[1, k] = -1 & psef_st_en[2, k] = -1
                 psef_times[1, k] = 0 & psef_times[2, k] = 0
                 Continue
              Endif
           Endif
           ipre = st_ss[k]
           If(ipre Gt 0) Then Begin
              Repeat Begin
                 ipre--
                 test_10 = aj.y[ipre]
              Endrep Until test_10 Eq 10 Or ipre Eq 1
;testing counts here is ok, since attenuators out should have non-zero
;count rates, subtract 1 as buffer
              ipre = (ipre-1) > 0
              If(cj.y[ipre] Gt 0 and aj.y[ipre] Eq 10) Then Begin
                 psef_st_en[0, k] = ipre
                 psef_times[0, k] = cj.x[ipre]
              Endif
           Endif
           ipst = en_ss[k]
           If(ipst Lt nds1) Then Begin
              Repeat Begin
                 ipst++
                 test_10 = aj.y[ipst]
              Endrep Until test_10 Eq 10 Or ipst Eq nds1
;pad by one here
              ipst = (ipst+1) < nds1
              If(cj.y[ipst] Gt 0 And aj.y[ipst] Eq 10) Then Begin
                 psef_st_en[3, k] = ipst
                 psef_times[3, k] = cj.x[ipst]
              Endif
           Endif
;Adjust for time buffer
           psef_times1[*, k] = psef_times[*, k]
           psef_st_en1[*, k] = psef_st_en[*, k]
           If(dtb Gt 0) Then Begin
              If(psef_times1[0, k] Gt 0) Then Begin ;check for zeros
                 ttime = psef_times1[0, k]-dtb
                 yyy = max(where(cj.x Le ttime))
                 If(yyy[0] Eq -1) Then Begin
;remove this one, shouldn't happen often
                    Psef_Drop_0: 
                    psef_st_en1[0, k] = -1
                    psef_times1[0, k] = 0.0
                 Endif Else Begin
;If state changes, drop this one
                    test_10or5 = where(aj.y[yyy:psef_st_en1[0, k]] Ne 10)
                    If(test_10or5[0] Ne -1) Then Goto, Psef_Drop_0
                    psef_times1[0, k] = cj.x[yyy]
                    psef_st_en1[0, k] = yyy
                 Endelse
              Endif
              If(psef_times1[1, k] Gt 0) Then Begin
                 ttime = psef_times1[1, k]+dtb
                 yyy = min(where(cj.x Ge ttime))
                 If(yyy[0] Eq -1) Then Begin
                    Psef_Drop_1: 
                    psef_st_en1[1, k] = -1
                    psef_times1[1, k] = 0.0
                 Endif Else Begin
                    test_10or5 = where(aj.y[psef_st_en1[1, k]:yyy] Ne 5)
                    If(test_10or5[0] Ne -1) Then Goto, Psef_Drop_1
                    psef_times1[1, k] = cj.x[yyy]
                    psef_st_en1[1, k] = yyy
                 Endelse
              Endif
              If(psef_times1[2, k] Gt 0) Then Begin
                 ttime = psef_times1[2, k]-dtb
                 yyy = max(where(cj.x Le ttime))
                 If(yyy[0] Eq -1) Then Begin
                    Psef_Drop_2: 
                    psef_st_en1[2, k] = -1
                    psef_times1[2, k] = 0.0
                 Endif Else Begin
                    test_10or5 = where(aj.y[yyy:psef_st_en1[2, k]] Ne 5)
                    If(test_10or5[0] Ne -1) Then Goto, Psef_Drop_2
                    psef_times1[2, k] = cj.x[yyy]
                    psef_st_en1[2, k] = yyy
                 Endelse
              Endif
              If(psef_times1[3, k] Gt 0) Then Begin
                 ttime = psef_times1[3, k]+dtb
                 yyy = min(where(cj.x Ge ttime))
                 If(yyy[0] Eq -1) Then Begin
                    Psef_Drop_3: 
                    psef_st_en1[3, k] = -1
                    psef_times1[3, k] = 0.0
                 Endif Else Begin
                    test_10or5 = where(aj.y[psef_st_en1[3, k]:yyy] Ne 10)
                    If(test_10or5[0] Ne -1) Then Goto, Psef_Drop_3
                    psef_times1[3, k] = cj.x[yyy]
                    psef_st_en1[3, k] = yyy
                 Endelse
              Endif
           Endif
        Endfor
        ok_flag = bytarr(nintv) ;in case an entire interval is thrown out
        For k = 0, nintv-1 Do Begin
           If(total(psef_times) Ne 0) Then ok_flag[k] = 1
        Endfor
        keep = where(ok_flag Ne 0, nok)
        If(nok Gt 0) Then Begin
           psef_times = psef_times[*, keep]
           psef_st_en = psef_st_en[*, keep]
           psef_times1 = psef_times1[*, keep]
           psef_st_en1 = psef_st_en1[*, keep]
        Endif Else Begin
           psef_times = -1
           psef_st_en = -1
           psef_times1 = -1
           psef_st_en1 = -1
        Endelse
     Endelse
  Endfor
End


