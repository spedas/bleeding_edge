;Multiscale smoothing, used on particle distributions
Function temp_multiscale_smooth, x, sm
  nsm = n_elements(sm)
  xout = x
  For j = 0, nsm-1 Do xout = smooth(xout, sm[j])
  Return, xout
End

;Interpolate onto a high resolution energy grid
Function temp_interp_hires, y, x, xout, xfactor = xfactor, _extra=_extra
  xout = -1
  If(keyword_set(xfactor)) Then xf = xfactor Else xf = 10.0
  ok = where(finite(x), nok)
  If(nok Eq 0) Then Return, -1
  xr = minmax(x[ok])
  nxout = long(xf*nok)
  xout = xr[0]+((xr[1]-xr[0])/(nxout-1))*indgen(nxout)
  yout = interpol(y[ok], x[ok], xout)
  Return, yout
End
  
;byte scale the input array x, vrange is the desired range to set to
;0 to 255. Log scaled, unless the linear keyword is set. The default
;value for vrange is [1.04e4, 1.0e8]
Function temp_tscale, x0, vrange = vrange, linear = linear, _extra=_extra


  If(keyword_set(vrange)) Then vr = vrange Else vr = [1.0e4, 1.0e8]
  vr = minmax(vr)

  If(~keyword_set(linear) And min(vr) Le 0) Then Begin
     dprint, 'Bad vrange, vr Le 0 is not allowed, vrange = ', vrange
     Return, -1
  Endif
  
  x = x0
  lo = where(~finite(x) or x Le vr[0], nlo)
  If(nlo Gt 0) Then x[lo] = vr[0]
  x = x < vr[1]

  If(~keyword_set(linear)) Then Begin
     x = bytescale(alog(x), range = alog(vr))
  Endif Else Begin
     x = bytescale(x, range = vr)
  Endelse

  Return, X
End
;+
;NAME:
; thm_esa_est_dist2scpot2
;PURPOSE:
; For a given probe and date, estimates the SC potential from PEER
; data, and plots it. This differs from the original
; thm_esa_est_dist2scpot.pro in that it uses the "eyeball test"; it
; only checks byte-scaled eflux variables.
;CALLING SEQUENCE:
; thm_esa_est_dist2scpot2, date, probe, no_init = no_init, $
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
; plot = if set, plot a comparison of the estimated sc_pot with the
;        value obtained from the esa L2 cdf (originally from
;        thm_load_esa_pot)
; esa_datatype = 'peef', 'peer', or 'peeb'; the default is 'peer'
; dyellow = the value subtracted from the peak of the distribution to
;        obtain the value below which we decide the photoelectron part
;        ends. The default value is 40.
; yellow = the limit (0-255) where above this value, we assume that
;          there are photo electrons in the scaled eflux
;          spectrogram. This will give the potential; the default is
;          205. 
; lo_scpot = lower limit for the potential, default is to use the low
;            energy limit of the data
; hi_scpot = upper limit for the potential, default is 100 V
; time_smooth_dt = if set, smooth the data in time, using this value
;                  as smoothing time, default is no smoothing
; hsk_test = if the HSK data for hsk_ifgm_xy_raw and hsk_ifgm_zr_raw
;            is below this value, set potential to low limit
; densmatch = if the potential is set to the low limit, because the
;             distribution is unsuitable (maybe not two maxima below
;             100 eV) then use thm_esa_dfrac2scpot for the potential.
; use_counts = if set, use the'en_counts' variable, and not
;              the 'en_flux' variable.
; slope_test = if set then the potential is set to the point at which
;              there is a maximum negative slope, if this value is
;              less than 30 V.
; sst_test = If set, if the SST electron total flux (thx_psef_tot) is
;            greater than this value, then th SC potential is set to
;            scplo. The default is to not use this test, but a good
;            value, based on data for THE from 2017, looks like 5.0e4.
;NOTES:
; Here is a summary of the process:
; 1) PEER data is the default. If the keyword /no_init is not set,
; Level 2 data is loaded for the input probe and date. 
; 2) Limits are set; by default, SCPLO is set to the lowest energy
; value in the data, but can be reset using the keyword
; lo_scpot. SCPHI has a default of 100 V, but can can be set using the
; keyword hi_scpot.
; 3) If the hsk_test keyword is set, then FGM housekeeping data is
; used to determine where the sc_pot should be set to SCPLO. The
; calculation is expected to be unreliable when the variables
; 'th(probe)_hsk_ifgm_xy_raw' and 'th(probe)_hsk_ifgm_zr_raw' have very
; low values. hsk_test = 75 is the value used for THEMIS ESA L2
; production. If the sst_test keyword is set, then the calculation is
; not good when the sst total electron variable is greater than this
; number. sst_test = 3e4 is the value used for THEMIS_ESA_L2.
; 4) Next, the spectrum is bytescaled in log space, so that values are
; between 0 and 255.
; 5) For each time interval, in order for photoelectrons to be
; expected, there has to be a local maximum in the spectrum at low
; energy, in one of the two lowest energy channels of the peer
; data. If there is no low energy maximum, or if this value is less
; than the 'yellow' value discussed in the next step, then there are no
; photoelectrons expected, and the potential is set to SCPLO.
; 6) For each time interval, the spectrum is interpolated to a
; higher resolution energy grid (also in log space).
; 7) For each time interval, a value of 'yellow' is chosen; this is
; the limit where above this value, we assume that there are low
; energy photo electrons in the scaled eflux spectrogram. There are
; two keywords, 'yellow' (default 205) and 'dyellow' (default 40). The
; value for each time interval is determined by the value of the low
; energy peak minus the dyellow value. For example, if the low energy
; bytescaled peak is a value of 240, then the photoelectron part of
; the distribution is set to 240-dyellow (approximately yellow on the
; typical plot color scale). The default is 40, so for this example,
; the cutoff for photoelectrons is then 200. But since the default
; value of the 'yellow' keyword is 205, then the cutoff is set to 205,
; and the potential is set to the energy value where the spectrum
; drops below the value of 205. The spectrum has to persist below this
; value for at least 10 points in the high resolution energy
; spectrum. If the value of the spectrum does not drop below 205, or
; is not below 205 for enough points, then it is assumed that there is
; no substantial photoelectron component, and the potential is set to
; SCPLO. (Note that the values of 205 and 40 were chosen using
; examples created by testing the estimates versus real SCPOT data for
; THEMIS A, D, and E for the first two weeks of January 2017.)
; 8) If the keyword /slope_test is set and there is an estimate of
; scpot > SCPLO, then the potential is set to the point where the
; negative slope of the spectrum has a maximum value, if this value is
; less than 30 V. This is done to avoid very large estimates where
; the slope of the spectrum starts off very negative at low energy,
; but then there is a nearly flat but slightly decreasing slope at
; higher energy, which delays the descent of the spectrum to the 'yellow'
; value. This is the default for THEMIS L2 ESA file production.
; 9) If the /densmatch keyword is set, and the estimated value of the
; potential is greater than the SCPHI limit, then the potential is
; adjusted to a value which gives an estimate electron density a
; factor of two times the estimated ion density. This is no longer
; used in L2 production.
; 10) the estimated potential is saved in a tplot variable called
; 'th(probe)_est_scpot' which can be interpolated to the time arrays
; for the different ESA modes.
; 11) If the keyword time_smooth_dt is set, then the potential is
; smoothed using that time range. The default for ESA L2 production is
; 120.0 seconds.
;HISTORY:
; 3-mar-2016, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2025-08-04 15:41:41 -0700 (Mon, 04 Aug 2025) $
; $LastChangedRevision: 33532 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/ESA/thm_esa_est_dist2scpot2.pro $
;-

Pro thm_esa_est_dist2scpot2, date, probe, trange=trange, $
                             yellow=yellow, dyellow = dyellow, $
                             no_init = no_init, random_dp = random_dp, $
                             plot = plot, esa_datatype = esa_datatype, $
                             lo_scpot = lo_scpot, hi_scpot = hi_scpot, $
                             time_smooth_dt = time_smooth_dt, $
                             hsk_test = hsk_test, densmatch = densmatch, $
                             use_counts = use_counts, despike = despike, $
                             slope_test = slope_test, sst_test = sst_test, $
                             _extra=_extra

;The default is to use peer data for this, and a good idea in general
  If(is_string(esa_datatype)) Then Begin
     dtyp = strlowcase(strcompress(/remove_all, esa_datatype[0])) 
  Endif Else dtyp = 'peer'

  dtyp1 = '*'+'_en_eflux'

;Only load one type of data, unless you want it all for plotting or
;random_dp options
  If(~keyword_set(no_init)) Then Begin
     If(keyword_set(random_dp)) Then Begin
        del_data, '*' ;no need for old data
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
        thm_load_esa, level='l2', probe = sc, trange = trange, datatype = dtyp1
        thm_load_esa_pot, efi_datatype = 'mom', probe = sc, trange = trange
        date = time_string(trange[0], /date_only)
     Endif Else If(keyword_set(date)) Then Begin
        timespan, date
        dprint, 'date: ', date
        thm_load_esa, level='l2', probe = sc, datatype = dtyp1
        thm_load_esa_pot, efi_datatype = 'mom', probe = sc
     Endif Else Begin
;no date is set explicitly, use timerange
        ppp2 = time_string(timerange(),/date_only)
        date = ppp2[0]
        dprint, 'date: ', date
        thm_load_esa, level='l2', probe = sc, datatype = dtyp1
        thm_load_esa_pot, efi_datatype = 'mom', probe = sc
     Endelse
     If(keyword_set(densmatch)) Then Begin
        thm_load_esa_pkt, probe = sc, datatype = ['peer', 'peir'] ;Load packet data
     Endif
  Endif Else sc = probe

  thx = 'th'+sc
  If(keyword_set(use_counts)) Then Begin
     get_data, thx+'_'+dtyp+'_en_counts', data = dr
  Endif Else Begin
     get_data, thx+'_'+dtyp+'_en_eflux', data = dr
  Endelse
  
  If(~is_struct(dr)) Then Begin
     message, /info, 'No '+dtyp+' data'
     Return
  Endif

;Low and high limits
  If(keyword_set(lo_scpot)) Then scplo = lo_scpot Else Begin
     drv = dr.v
     scplo = min(drv[where(finite(drv) And drv gt 0)])
  Endelse
  If(keyword_set(hi_scpot)) Then scphi = hi_scpot Else scphi = 100.0
;If requested, use HSK data for FGM to determine where the sc_pot should be
;set to scplo automatically
  ntimes = n_elements(dr.x)
  If(keyword_set(hsk_test)) Then Begin
     If(~keyword_set(no_init)) Then thm_load_hsk, probe = sc
     get_data, thx+'_hsk_ifgm_xy_raw', data = xy
     If(~is_struct(xy)) Then Goto, no_hsk
     xy_test = interpol(xy.y, xy.x, dr.x)
     get_data, thx+'_hsk_ifgm_zr_raw', data = zr
     If(~is_struct(zr)) Then Goto, no_hsk
     zr_test = interpol(zr.y, zr.x, dr.x)
     ss_hsk_test = (xy_test Lt hsk_test) And (zr_test Lt hsk_test)
  Endif Else Begin
     no_hsk:
     ss_hsk_test = bytarr(ntimes)
  Endelse
;If requested, use SST data to determine where the sc_pot should be
;set to scplo automatically
  If(keyword_set(sst_test)) Then Begin
     If(~keyword_set(no_init)) Then thm_load_sst, probe = sc
     get_data, thx+'_psef_tot', data = psef
     If(~is_struct(psef)) Then Goto, no_sst
     sst_psef = interpol(psef.y, psef.x, dr.x)
     ss_psef_test = (sst_psef Gt sst_test)
  Endif Else Begin
     no_sst:
     ss_psef_test = bytarr(ntimes)
  Endelse
;bytescale in log space
  ok = where(finite(dr.y) And dr.y Gt 0, nok)
  If(nok Gt 0) Then vrange = minmax(dr.y[ok]) Else vrange = 0b
  yy = rotate(temp_tscale(dr.y, vrange = vrange, _extra=_extra), 7)
  vv = rotate(dr.v, 7)
  nchan = n_elements(vv[0,*])
  scpot = fltarr(ntimes)+scplo  ;low limit
  If(keyword_set(yellow)) Then ylw = yellow Else ylw = 205
  If(keyword_set(dyellow)) Then dylw = dyellow Else dylw = 40
  For j = 0, ntimes-1 Do Begin
     i = 0
     maxv = max(yy[j,0:5], maxpt)
;     if(dr.x[j] Gt time_double('2025-02-25/07:20:00')) then stop
     If(ss_hsk_test[j] Gt 0 Or ss_psef_test[j] Gt 0) Then continue ;Do not process this time
     do_this_j = 0b
     ylwj = (maxv-dylw) > ylw
     If(vv[j, 0] Lt 1.0) Then Begin ;fix for zero energy modes
        If(yy[j, 1] Ge ylwj) Then do_this_j = 1b
     Endif Else Begin
        If(yy[j, 0] Ge ylwj) Then do_this_j = 1b
     Endelse
     If(do_this_j) Then Begin
;interpolate to a higher resolution energy grid
        yyy0 = temp_interp_hires(reform(yy[j,*]), alog(reform(vv[j,*])), $
                                 vvv, _extra=_extra)
        yyy = temp_multiscale_smooth(yyy0, [31, 21, 11])
        If(yyy[0] Ne -1) Then Begin
           Repeat Begin ;drop to yellow, or lower, and persist for 10 points
              i=i+1
              i1 = i+1
              cc = (yyy[i] lt ylwj) Or (exp(vvv[i1]) Ge scphi) Or $
                   (i1 Eq n_elements(yyy)-1)
           Endrep Until cc
        Endif
;We have an I value, this has to persist for at least 10 points, jmm, 2025-02-25
        imxx = (i+10)<(n_elements(yyy)-1)
        itmp = yyy[i:imxx]
        Iok = where(itmp Le ylwj, niok)
        If(niok Lt 10) Then i = n_elements(yyy)-1 ;No deal
;Check slope, and adjust value back to where slope is maximum, but
;only if it's less than 30 V
        If(keyword_set(slope_test)) Then Begin
           dydv = deriv(vvv,yyy)
           max_slope = min(dydv[0:imxx], maxpt)
           If(max_slope Lt 0.0 And exp(vvv[maxpt]) Lt 30.0) Then i = maxpt+1
        Endif
;check density ratio
        If(keyword_set(densmatch)) Then Begin
           efuncj = 'get_'+thx+'_peer'
           edj = call_function(efuncj, dr.x[j])
           ifuncj = 'get_'+thx+'_peir'
           idj = call_function(ifuncj, dr.x[j])
           scpot_dens = thm_esa_dfrac2scpot(edj, idj, _extra = _extra)
        Endif
        If(exp(vvv[i]) Lt scphi) Then scpot[j] = exp(vvv[i]) Else Begin
           If(keyword_set(densmatch)) Then scpot[j] = scpot_dens $
           Else scpot[j] = scplo
        Endelse
     Endif
;     If(dr.x[j] Gt time_double('2025-02-25 11:02:50')) Then stop
  Endfor
  scpot = scpot < scphi
  dlim = {ysubtitle:'[Volts]', units:'volts'}
  If(keyword_set(despike)) Then Begin
     scpot = simple_despike_1d(scpot, spike_threshold = 20.0, width = 11)
  Endif
  store_data, thx+'_est_scpot', data = {x:dr.x, y:scpot}, dlimits = dlim
  options, thx+'_est_scpot', 'yrange', [0.0, scphi]
  If(keyword_set(time_smooth_dt)) Then Begin
     tsmooth_in_time, thx+'_est_scpot', time_smooth_dt, newname = thx+'_est_scpot'
  Endif

  If(keyword_set(plot) Or keyword_set(random_dp)) Then Begin
     thm_spec_lim4overplot, thx+'_'+dtyp+'_en_eflux', zlog = 1, ylog = 1, /overwrite , ymin = 2.0
     zlim, thx+'_'+dtyp+'_en_eflux', 1d4, 7.5d8, 1 ;to make it look like the overplots     
     scpot_overlay1 = scpot_overlay(thx+'_esa_pot', thx+'_'+dtyp+'_en_eflux', sc_line_thick = 2.0, /use_yrange)
     scpot_overlay2 = scpot_overlay(thx+'_est_scpot', thx+'_'+dtyp+'_en_eflux', sc_line_thick = 2.0, suffix = '_EST', /use_yrange)
     If(~xregistered('tplot_window')) Then tplot_window, [scpot_overlay1, scpot_overlay2] $
     Else tplot, [scpot_overlay1, scpot_overlay2]
  Endif
End
