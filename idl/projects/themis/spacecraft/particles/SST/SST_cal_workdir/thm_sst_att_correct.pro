;helper function to check to see if the attenuators are in at the
;start and end of a day, if so, then extend the data in both
;directions to find a transition, for at least a week in each
;direction, uses psif data for test, since that sems to be most
;comprehensive
Pro thm_sst_att_auto_extend, probe, date, newdate, newdur
  ndays = 7                     ;max extension in either direction
;use thm_load_sst to get atten variable
  timespan, date, 1
  thm_load_sst, probe = probe, suffix = '_auto_extend_test'
  get_data, 'th'+probe[0]+'_psif_atten_auto_extend_test', data = di
  If(~is_struct(di)) Then Begin
     dprint, dlevel = 2, 'No PSIF data: '+time_string(date)+' No extension'
     Return
  Endif
  If(di.y[0] Eq 10 And di.y[n_elements(di.y)-1] Eq 10) Then Begin
     newdate = time_double(date)
     newdur = 1
     Return
  Endif
  att_daystart0 = di.y[0]
  att_dayend0 = di.y[n_elements(di.x)-1]
;Check each direction, if needed
  one_day = 86400.0d0
  If(att_daystart0 Eq 10) Then Begin
     new_date = time_double(date)
     new_dur = 1
  Endif Else Begin;check each day previously until att = 10
     iday = 0
     new_date = 0.0d0
     While iday Lt 7 And new_date EQ 0 Do Begin
        iday++
        test_date = time_double(date)-iday*one_day
        timespan, test_date
        thm_load_sst, probe = probe, suffix = '_auto_extend_test'
        get_data, 'th'+probe[0]+'_psif_atten_auto_extend_test', data = di
        If(is_struct(di)) Then Begin
           test_att = where(di.y Eq 10)
           If(test_att[0] Ne -1) Then Begin
              new_date = test_date
              new_dur = 1+iday
           Endif
        Endif Else Begin        ;data gap
           new_date = time_double(date)
           new_dur = 1
        Endelse
     Endwhile
     If(iday Eq 7) Then Begin
        dprint, dlevel = 2, 'No Attenuator change for 7 days prior to: '+$
                time_string(date)+' No extension' ;may never happen?
        new_date = date
        new_dur = 1
     Endif
  Endelse
;Ok now in the plus direction, here you have both new date and new_dur
;but start with date, and 1, to save input times...
  If(att_dayend0 Eq 10) Then Begin
     pdur = 0 ;extra duration to add to new_dur
  Endif Else Begin
     pday = 0
     pdur = 0
     While pday Lt 7 And pdur Eq 0 Do Begin
        pday++
        test_date = time_double(date)+pday*one_day
        timespan, test_date
        thm_load_sst, probe = probe, suffix = '_auto_extend_test'
        get_data, 'th'+probe[0]+'_psif_atten_auto_extend_test', data = di
        If(is_struct(di)) Then Begin
           test_att = where(di.y Eq 10)
           If(test_att[0] Ne -1) Then Begin
              pdur = pday
           Endif
        Endif Else Begin        ;data gap
           pdur = 0
        Endelse
     Endwhile
     If(pday Eq 7) Then Begin
        dprint, dlevel = 2, 'No Attenuator change for 7 days after to: '+$
                time_string(date)+' No extension' ;may never happen?
        pdur = 0
     Endif
  Endelse

  newdate = new_date
  newdur = new_dur+pdur          ;since the initial day is included in new_dur
  del_data, '*_auto_extend_test' ;get rid of this stuff

End
    
  
;Helper function for sun removal
Function temp_sun_remove, ptr_in
;Remove sun contamination, sets data to zero, not just bins. Otherwise
;there is no correction if units are counts.
  ;default bins
  b2m = [0,8,16,24,32,33,34,40,47,48,49,50,55,56,57]
  dist = *ptr_in
  dist.data[*, b2m] = 0
  dist.bins[*, b2m] = 0
  oops = where(~finite(dist.data), noops)
  If(noops Gt 0) Then dist.data[oops] = 0.0
  ptr_free, ptr_in
  return, ptr_new(dist)
End
;+
;NAME:
; thm_sst_att_correct
;PURPOSE:
; tests for attenuator transition, calculates background level and
; correction factor, and corrects the attenuation level in the saved
; data structures. Ideally the correction is interpolated between two
; attenuator transistions.
;CALLING SEQUENCE:
; thm_sst_att_correct, probe, date, dur = dur
;INPUT:
; probe = 'a', 'b', 'c', 'd', or 'e'
; date = start date
;KEYWORDS:
; dur = duration in days, note that some attenuator intervals are more
;       than a day, if there is no attenuator transition during the
;       date input, no correction will be calculated. If there is only
;       one transition in the data, then the correction will not be 
;       interpolated over the full interval.
; auto_extend = If duration is 1 day, the auto_extend option will
;               extend the calculation to previous and later days if
;               the attenuators are in at the start and end of the
;               day. This will extend at least 7 days in either
;               direction.
;NOTES:
;Uses thm_part_dist2, and not thx_sst_psi?f
;HISTORY:
; 2021-03-29, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2021-07-13 13:06:43 -0700 (Tue, 13 Jul 2021) $
; $LastChangedRevision: 30125 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/SST_cal_workdir/thm_sst_att_correct.pro $
;-
Pro thm_sst_att_correct, probe, date, dur = dur, $
                         auto_extend = auto_extend, $
                         no_transitions = no_transitions, $
                         _extra = _extra
;This will require all new data
  del_data, 'th'+probe[0]+'_ps??_*'
  i_att = 3/1000.0               ;this is a minimum value for PSIF data, based on calculations, approximately 99% of attenuator transitions are above this value
  e_att = 6/1000.0               ;same for PSEF data
  If(~keyword_set(dur)) Then dur = 1
  If(dur Eq 1 && keyword_set(auto_extend)) Then Begin
     thm_sst_att_auto_extend, probe, date, newdate, newdur
  Endif Else Begin
     newdate = date & newdur = dur
  Endelse
;In this case, timespan and loads are called
  no_transitions = 0
  thm_sst_att_times, probe, newdate, dur=newdur, $
                     psif_times, psef_times, $ ;times padded by 1
                     psif_st_en, psef_st_en, $
                     psif_times1, psef_times1, $ ;times with buffer
                     psif_st_en1, psef_st_en1, $
                     _extra = _extra
  If(n_elements(psif_st_en) Eq 1 And psif_st_en[0] Eq -1) Then Begin ;no transitions
     no_transitions = 1
  Endif Else no_transitions = 0
;Ok, for each transition then for both electrons and protons
  thx = 'th'+probe[0]
  ie = ['i', 'e']
;Remove sun contamination
  b2m = [0,8,16,24,32,33,34,40,47,48,49,50,55,56,57]
;ax1i and ax1e are a fit to log attenuator effective value versus
;attenuated counts, To get fit values for a given count rate of x, use
;the function f3pl.pro, e.g. fx = f3pl(ax, x).
  ax1i = [1.89863,-1.38343,-1.90731,-0.0192765,-3.13986,0.311749]
  Ax1e = [-1.76029,-0.0443143,-2.60651,0.192501,-5.85348,0.896954]
;Ions first
  For j = 0, 1 Do Begin
     If(j eq 0) Then att = i_att else att = e_att
     instr = 'ps'+ie[j]+'f'
     instr_r = 'ps'+ie[j]+'r'
     instr_b = 'ps'+ie[j]+'b'
     If(j eq 0) Then Begin
        st_en = psif_st_en
        st_en1 = psif_st_en1
        times = psif_times
        times1 = psif_times1
     Endif Else Begin
        st_en = psef_st_en
        st_en1 = psef_st_en1
        times = psef_times
        times1 = psef_times1
     Endelse
;data and atten variables should exist, since thm_load_sst2 and
;thm_load_sst2_atten2 are called in thm_sst_att_times.pro
     If(~is_struct(data)) Then get_data, thx+'_'+instr+'_data', data = data
     If(~is_struct(atten)) Then get_data, thx+'_'+instr+'_atten', data = atten
     If(~is_struct(rate)) Then get_data, thx+'_'+instr+'_count_rate_total', data = rate
     If(j Eq 0) Then ax = ax1i Else ax = ax1e
     rate.y = rate.y > 1.0
     t3pl = f3pl(ax, alog10(rate.y))
     t3pl = simple_despike_1d(t3pl, alt_spike_threshold = 0.05) ;log values are easy to smooth
     t3pl = smooth(t3pl, 3) ;small amount of smoothing
     store_data, thx+'_'+instr+'_ratio_minv', data = {x:rate.x, y:t3pl}
;get the count rate for att_level minimum
;ratio_all will be the attenuation ratio for the sample
     tim_arr = data.x
     ndset = n_elements(tim_arr)
     ratio_all = {x:tim_arr, y: fltarr(ndset, 16), v:fltarr(ndset, 16)}
     xx = where(atten.y Ne 10, nxx)
     If(nxx Eq 0) Then Begin    ;attenuators out for the full interval
        ratio_all.y = 1.0
        store_data, thx+'_'+instr+'_ratio_var', data = ratio_all
        Continue                ;next species
     Endif Else Begin
        ratio_all.y[xx, *] = att ;minimum value
        yy = where(atten.y Eq 10, nyy)
        If(yy[0] Ne -1) Then ratio_all.y[yy, *] = 1.0
        If(n_elements(st_en) Eq 1 And st_en[0] Eq -1) Then Begin ;no transitions
           ratio_all.y = ratio_all.y < 1.0
           For ll = 0, 15 Do ratio_all.y[*, ll] = ratio_all.y[*, ll] > 10.0^t3pl
           store_data, thx+'_'+instr+'_ratio_var', data = ratio_all
           Continue             ;next species
        Endif
;4 numbers for each attenuator in episode, n episodes
        n = n_elements(st_en[0, *])
        otp = ptrarr(4, n) & otp1 = ptrarr(4, n)
;A flag for a good transition
        ok_flag = bytarr(2, n)
;Attenuation ratios, in/out, interpolate between these values for each
;attenuator in time interval
        ratio = fltarr(16, 2, n)
;keep track of energy, this will be interpolated into the v tag of the
;ratio_all structure
        energy = ratio
        ratio_times = dblarr(2, n)
        initj = 0               ;nothing will happen if initj is 0
        For i = 0, n-1 Do Begin
           For k = 0, 3 Do Begin
              If((st_en[k, i] Ne -1) && (st_en1[k, i] Ne -1)) Then Begin
                 e1 = thm_part_dist2(thx+'_'+instr, index = st_en[k, i], badbins2mask = b2m)
                 e11 = thm_part_dist2(thx+'_'+instr, index = st_en1[k, i], badbins2mask = b2m)
                 If(is_struct(e1) && is_struct(e11)) Then Begin
                    otp[k, i] = ptr_new(e1)
                    otp1[k, i] = ptr_new(e11)
                    otp[k, i] = temp_sun_remove(otp[k, i])
                    otp1[k, i] = temp_sun_remove(otp1[k, i])
                 Endif
              Endif
           Endfor
           For g = 0, 1 Do Begin ;g now refers to each transition, g = 0 atts pop in, g = 1 atts pop out
              If(g Eq 0) Then Begin
                 k1 = 1 & k0 = 0 ;k0 = attenuator out, k1 = attenuator in
              Endif Else Begin
                 k1 = 2 & k0 = 3
              Endelse
              otp_in = otp[k1, i]
              otp_out = otp[k0, i]
;Attenuator out = 10, Attenuator in = 5
              If(ptr_valid(otp_in) && ptr_valid(otp_out)) Then Begin
                 If((*otp_in).atten Eq 5 && (*otp_out).atten Eq 10) Then Begin
                    ok_flag[g, i] = 1
;attenuation ratios as a function of energy
                    rate1 = (*otp_out).data/(*otp_out).integ_t
                    rate1a = (*otp_in).data/(*otp_in).integ_t
                    rate_t1 = total(rate1, 2)
                    rate_t1a = total(rate1a, 2)
                    ratio_tmp  = rate_t1a/rate_t1
                    not_ok_gk = where(~finite(ratio_tmp), nnot_ok_gk)
                    If(nnot_ok_gk Gt 0) Then ratio_tmp[not_ok_gk] = 0
                    ratio[*, g, i] = ratio_tmp
                    energy[*, g, i] = (*otp_in).energy[*, 0] ;energy doesn't vary with angle
                    ratio_times[g, i] = times[k1, i]
                 Endif
              Endif
           Endfor
;Interpolate ratio over all of the times in the interval between
;transitions, use ge and le because times are defined as att in times
           If(ratio_times[0, i] Gt 0 And ratio_times[1, i] Gt 0) Then Begin
              xx = where(tim_arr Ge ratio_times[0, i] And $
                         tim_arr Le ratio_times[1, i], nxx)
              If(nxx Gt 0) Then Begin
                 initj = 1      ;we have changed an interval
                 For ll = 0, 15 Do Begin
                    rtmp = ratio[ll, *, i] > att
                    rtmp = alog10(rtmp)
                    ratio_all.y[xx, ll] = 10.0^interpol(rtmp, $
                                                        ratio_times[*, i], $
                                                        tim_arr[xx])
;Left this interpolation here just in case in the future there are
;time-varying energy arrays
                    ratio_all.v[xx, ll] = interpol(energy[ll, *, i], $
                                                   ratio_times[*, i], $
                                                   tim_arr[xx])
                 Endfor
              Endif
           Endif
        Endfor                  ;i loop, n atten intervals
        If(initj Eq 1) Then Begin ;nothing happens if initj was not set
           ratio_all.y = ratio_all.y < 1.0
;use t3pl values outside of ratio_times
           full_tr = minmax(ratio_times[where(ratio_times Ne 0)])
           x_unused = where(tim_arr Lt full_tr[0] Or tim_arr Gt full_tr[1], nx_unused)
           If(nx_unused Gt 0) Then Begin
              For ll = 0, 15 Do Begin
                 ratio_all.y[x_unused, ll] = ratio_all.y[x_unused, ll] > 10.0^t3pl[x_unused]
              Endfor
           Endif
           store_data, thx+'_'+instr+'_ratio_var', data = ratio_all
        Endif
     Endelse
  Endfor                        ;j loop , ions or electrons
  options, '*ratio_var*', 'ylog', 1
  options, '*ratio_var*', 'yrange', [1.0e-3, 10.0]
  ;delete the input data, except for the ratio_var variables
  vkeep = tnames(thx+'*_ratio_*')
  vars = tnames(thx+'_ps??_*')
  delvars = ssl_set_complement(vkeep, vars)
  del_data, delvars
End
