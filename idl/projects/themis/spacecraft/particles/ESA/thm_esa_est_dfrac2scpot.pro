;+
;NAME:
; thm_esa_est_dfrac2scpot
;PURPOSE:
; For a given probe and date, estimates the SC potential from PEER and PEIR
; data, and plots it.
;CALLING SEQUENCE:
; thm_esa_est_dfrac2scpot, date, probe, no_init = no_init, $
;                          random_dp = random_dp, plot = plot
;INPUT:
; date = a date, e.g., '2008-01-05'
; probe = a probe, e.g., 'c'
;OUTPUT:
; a tplot variable 'th'+probe+'_est_scpot' is created
; If /random_dp is set, then date and probe are output 
;KEYWORDS:
; trange = a time range
; no_init = if set, do not read in a new set of data
; random_dp = if set, the input date and probe are randomized, note
;             that this keyword is unused if no_init is set.
; plot = if set, plot a comparison of the estimated sc_pot wht the
;        value obtained from the esa L2 cdf (originally from
;        thm_load_esa_pot)
; use_n3dnew = if set, use n_3d_new.pro to get densities
;HISTORY:
; 1-feb-2023, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2023-02-06 15:08:13 -0800 (Mon, 06 Feb 2023) $
; $LastChangedRevision: 31478 $
; $URL: $
;-

Pro thm_esa_est_dfrac2scpot, date, probe, trange=trange, $
                             no_init = no_init, random_dp = random_dp, $
                             plot = plot, load_all_esa = load_all_esa, $
                             time_smooth_dt = time_smooth_dt, $
                             use_n3dnew = use_n3dnew, $
                             _extra=_extra
  
;Use peer and peir data
;Only load one type of data, unless you want it all for plotting or
;random_dp options
  If(keyword_set(load_all_esa) Or keyword_set(random_dp) Or keyword_set(plot)) Then Begin
     only_dtyp = 0b
  Endif Else only_dtyp = 1b
  dtyp = ['peer', 'peir']
  If(~keyword_set(no_init)) Then Begin
     If(keyword_set(random_dp)) Then Begin
        probes = ['a', 'b', 'c', 'd', 'e']
        index = fix(5*randomu(seed))
        probe = probes[index]
;start in 2008
        t0 = time_double('2008-01-01')
        t1 = time_double(time_string(systime(/sec), /date))
        dt = t1-t0
        date = time_string(t0+dt*randomu(seed), /date)
     Endif
     sc = probe
     dprint, 'Probe: ', strupcase(sc)
     If(keyword_set(trange)) Then Begin
        dprint, 'Time_range:', time_string(trange) 
        If(only_dtyp) Then thm_load_esa_pkt, probe = sc, trange = trange, datatype = dtyp Else Begin
           thm_load_esa_pkt, probe = sc, trange = trange
           thm_load_esa_pot, efi_datatype = 'mom', probe = sc, trange = trange
        Endelse
        date = time_string(trange[0], /date_only)
     Endif Else If(keyword_set(date)) Then Begin
        timespan, date
        dprint, 'date: ', date
        If(only_dtyp) Then thm_load_esa_pkt, probe = sc, datatype = dtyp Else Begin
           thm_load_esa_pkt, probe = sc
           thm_load_esa_pot, efi_datatype = 'mom', probe = sc
        Endelse
     Endif Else Begin           ;no date is set explicitly, but there may have been a timespan earlier so call timerange
        ppp2 = time_string(timerange(),/date_only)
        date = ppp2[0]
        dprint, 'date: ', date
        If(only_dtyp) Then thm_load_esa_pkt, probe = sc, datatype = dtyp Else Begin
           thm_load_esa_pkt, probe = sc
           thm_load_esa_pot, efi_datatype = 'mom', probe = sc
        Endelse
     Endelse
  Endif Else sc = probe

  thx = 'th'+sc
  For j =0, 1 Do Begin
     get_data, thx+'_'+dtyp[j]+'_en_counts', data = dr
     If(~is_struct(dr)) Then Begin
        message, /info, 'No '+dtyp[j]+' data'
        Return
     Endif
  Endfor

  ntimes = n_elements(dr.x)
  scpot = fltarr(ntimes)
  For j = 0, ntimes-1 Do Begin
     t = dr.x[j]
     efuncj = 'get_'+thx+'_'+dtyp[0]
     edj = call_function(efuncj, t)
     ifuncj = 'get_'+thx+'_'+dtyp[1]
     idj = call_function(ifuncj, t)
     scpot[j] = thm_esa_dfrac2scpot(edj, idj, use_n3dnew = use_n3dnew, _extra = _extra)
  Endfor

  dlim = {ysubtitle:'[Volts]', units:'volts'}
  store_data, thx+'_est_scpot', data = {x:dr.x, y:scpot}, dlimits = dlim
  options, thx+'_est_scpot', 'yrange', [0.0, 100.0]
  If(keyword_set(time_smooth_dt)) Then Begin
     tsmooth_in_time, thx+'_est_scpot', time_smooth_dt, newname = thx+'_est_scpot'
  Endif

  If(keyword_set(plot) Or keyword_set(random_dp)) Then Begin
     thm_spec_lim4overplot, thx+'_'+dtyp[0]+'_en_counts', zlog = 1, ylog = 1, /overwrite, ymin = 2.0
     thm_spec_lim4overplot, thx+'_'+dtyp[1]+'_en_counts', zlog = 1, ylog = 1, /overwrite, ymin = 2.0
     scpot_overlay1 = scpot_overlay(thx+'_'+dtyp[0]+'_sc_pot', thx+'_'+dtyp[0]+'_en_counts', sc_line_thick = 2.0, /use_yrange)
     scpot_overlay2 = scpot_overlay(thx+'_est_scpot', thx+'_'+dtyp[0]+'_en_counts', sc_line_thick = 2.0, suffix = '_EST', /use_yrange)
     If(~xregistered('tplot_window')) Then tplot_window, [scpot_overlay1, scpot_overlay2, thx+'_'+dtyp[1]+'_en_counts'] $
     Else tplot, [scpot_overlay1, scpot_overlay2, thx+'_'+dtyp[1]+'_en_counts']
  Endif
End
