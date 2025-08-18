;+
;NAME:
; thm_esa_est_dist2scpot
;PURPOSE:
; For a given probe and date, estimates the SC potential from PEER
; data, and plots it.
;CALLING SEQUENCE:
; thm_esa_est_dist2scpot, date, probe, no_init = no_init, $
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
; esa_datatype = 'peef', 'peer', or 'peeb'; the default is 'peer'
;
;HISTORY:
; 31-may-2015, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2017-10-02 11:19:09 -0700 (Mon, 02 Oct 2017) $
; $LastChangedRevision: 24078 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/ESA/thm_esa_est_dist2scpot.pro $
;-

Pro thm_esa_est_dist2scpot, date, probe, trange=trange, $
                            no_init = no_init, random_dp = random_dp, $
                            plot = plot, esa_datatype = esa_datatype, $
                            load_all_esa = load_all_esa, _extra=_extra
  
;The default is to Use peer data for this
  If(is_string(esa_datatype)) Then Begin
     dtyp = strlowcase(strcompress(/remove_all, esa_datatype[0])) 
  Endif Else dtyp = 'peer'

;Only load one type of data, unless you want it all for plotting or
;random_dp options
  If(keyword_set(load_all_esa) Or keyword_set(random_dp) Or keyword_set(plot)) Then Begin
     only_dtyp = 0b
  Endif Else only_dtyp = 1b

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
  get_data, thx+'_'+dtyp+'_en_counts', data = dr
  If(~is_struct(dr)) Then Begin
     message, /info, 'No '+dtyp+' data'
     Return
  Endif

  ntimes = n_elements(dr.x)
  scpot = fltarr(ntimes)
  For j = 0, ntimes-1 Do Begin
     t = dr.x[j]
     funcj = 'get_'+thx+'_'+dtyp
     dj = call_function(funcj, t)
     scpot[j] = thm_esa_dist2scpot(dj, _extra = _extra)
  Endfor

  dlim = {ysubtitle:'[Volts]', units:'volts'}
  store_data, thx+'_est_scpot', data = {x:dr.x, y:scpot}, dlimits = dlim
  options, thx+'_est_scpot', 'yrange', [0.0, 100.0]

  If(keyword_set(plot) Or keyword_set(random_dp)) Then Begin
     thm_spec_lim4overplot, thx+'_'+dtyp+'_en_counts', zlog = 1, ylog = 1, /overwrite, ymin = 2.0
     scpot_overlay1 = scpot_overlay(thx+'_'+dtyp+'_sc_pot', thx+'_'+dtyp+'_en_counts', sc_line_thick = 2.0, /use_yrange)
     scpot_overlay2 = scpot_overlay(thx+'_est_scpot', thx+'_'+dtyp+'_en_counts', sc_line_thick = 2.0, suffix = '_EST', /use_yrange)
     window, xs = 1024, ys = 1024
     tplot, [scpot_overlay1, scpot_overlay2]
  Endif
End
