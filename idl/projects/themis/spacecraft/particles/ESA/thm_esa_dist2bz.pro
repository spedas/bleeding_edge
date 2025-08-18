;+
;NAME:
; thm_esa_dist2bz
;PURPOSE:
; For a given probe and date, estimates the SC potential from PEEF
; data, and plots it.
;CALLING SEQUENCE:
; thm_esa_dist2bz, date, probe, no_init = no_init, $
;                  random_dp = random_dp, plot = plot
;INPUT:
; date = a date, e.g., '2008-01-05'
; probe = a probe, e.g., 'c'
;OUTPUT:
; a tplot variable 'th'+probe+'_dist2bz' is created
; If /random_dp is set, then date and probe are output 
;KEYWORDS:
; trange = a time range
; no_init = if set, do not read in a new set of data
; random_dp = if set, the input date and probe are randomized, note
;             that this keyword is unused if no_init is set.
; use_ev = if set, use an average eignevector (from different energy
;          bands) to get the theta (latitude) angle between the
;          electron distribution direction, rather than the average
;          theta
; phi_threshold = Good eigenvector values need to have an azimuthal
;                (phi) angle closer to atan(bx,by) than this value, in
;                degrees. Default is 30.0
;HISTORY:
; 10-jun-2024, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

Pro thm_esa_dist2bz, date, probe, trange=trange, $
                     no_init = no_init, random_dp = random_dp, $
                     plot = plot, use_ev = use_ev, $
                     phi_threshold = phi_threshold, $
                     _extra=_extra
  
;Only bother with PEEF data, since you need full angular resolution
  dtyp = 'peef'
;Only load one type of data, unless you want it all for plotting or
;random_dp options
  If(keyword_set(random_dp) Or keyword_set(plot)) Then Begin
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
        If(only_dtyp) Then Begin
           thm_load_esa_pkt, probe = sc, trange = trange, datatype = dtyp
        Endif Else Begin
           thm_load_esa_pkt, probe = sc, trange = trange
        Endelse
        thm_load_fit, probe = sc, datatype = 'fgs'
        date = time_string(trange[0], /date_only)
     Endif Else If(keyword_set(date)) Then Begin
        timespan, date
        dprint, 'date: ', date
        If(only_dtyp) Then Begin
           thm_load_esa_pkt, probe = sc, datatype = dtyp
        Endif Else Begin
           thm_load_esa_pkt, probe = sc
        Endelse
        thm_load_fit, probe = sc, datatype = 'fgs'
     Endif Else Begin           ;no date is set explicitly
        ppp2 = time_string(timerange(),/date_only)
        date = ppp2[0]
        dprint, 'date: ', date
        If(only_dtyp) Then Begin
           thm_load_esa_pkt, probe = sc, datatype = dtyp
        Endif Else Begin
           thm_load_esa_pkt, probe = sc
        Endelse
        thm_load_fit, probe = sc, datatype = 'fgs'
     Endelse
  Endif Else sc = probe

  thx = 'th'+sc
  get_data, thx+'_'+dtyp+'_en_counts', data = dr
  If(~is_struct(dr)) Then Begin
     message, /info, 'No '+dtyp+' data'
     Return
  Endif
  get_data, thx+'_fgs', data = b
  If(~is_struct(b)) Then Begin
     message, /info, 'No FGS data'
     Return
  Endif

;For each ESA data interval, get the theta angle
  ntimes = n_elements(dr.x)
  theta = fltarr(ntimes)+!values.f_nan
  bxyz_tmp = data_cut(thx+'_fgs', dr.x, /extrapolate)
  trb = minmax(b.x) + 2*[-3.0d0, 3.0d0]
  funcj = 'get_'+thx+'_'+dtyp   ;the function needed to return the edist
  If(keyword_set(phi_threshold)) Then phth = phi_threshold Else phth = 30.0
  For j = 0, ntimes-1 Do Begin
;Only do this calculation if the time here is not too far before or
;after the Bfield time, to avoid extrapolation weirdness
     t = dr.x[j]
     If(t Ge trb[0] And t Le trb[1]) Then Begin
        dj = call_function(funcj, t)
        evj = thm_esa_dist2bz_angle(dj, av_theta = thetaj)
        If(is_struct(evj)) Then Begin
;Check to see if the angle is anything like atan(bx,by)
           atest = atan(bxyz_tmp[j, 0], bxyz_tmp[j, 1])*180.0/!dpi
           If(abs(evj.phi-atest) Le phth) Then Begin
              If(keyword_set(use_ev)) Then theta[j] = evj.theta $
              Else theta[j] = thetaj
           Endif
        Endif
     Endif
  Endfor
  dlim = {ysubtitle:'[degrees]', units:'degrees'}
  store_data, thx+'_dist2bz_theta', data = {x:dr.x, y:theta}, dlimits=dlim
  options, thx+'_dist2bz_theta', 'yrange', [-100.0, 100.0]
;interpolate to the FGS times, and create a new variable
  theta_tmp = data_cut(thx+'_dist2bz_theta',b.x)
  Bz_tmp = tan(theta_tmp*!dpi/180.0)*sqrt(b.y[*,0]^2+b.y[*,1]^2)
  dlim = {ysubtitle:'[nT]', units:'nT'}
  store_data, thx+'_dist2bz', data={x:b.x,y:bz_tmp}, dlim=dlim

;How well does this work?
  If(keyword_set(plot) Or keyword_set(random_dp)) Then Begin
     split_vec, thx+'_fgs'
     If(~xregistered('tplot_window')) Then tplot_window, [thx+'_fgs_z', thx+'_dist2bz'] $
     Else tplot, [thx+'_fgs_z', thx+'_dist2bz']
     get_data, thx+'_fgs_z', data = bz0
     get_data, thx+'_dist2bz', data = bz1
     ppp = where(finite(bz1.y) And finite(bz0.y), nppp)
     fraction0 = float(nppp)/n_elements(bz0.y)
     bztestval = abs(bz0.y) > 10.0 ;for comparisons, if bz is close to zero
     qqq = where(abs(bz1.y[ppp]-bz0.y[ppp])/bztestval Le 0.50, nqqq)
     fraction2 = float(nqqq)/n_elements(bz0.y)
     Print, nppp, ' of ', n_elements(bz0.y), ' are finite, fraction = ', fraction0
     Print, nqqq, ' of ', n_elements(bz0.y), ' are within 0.5 of Bz, fraction = ', fraction2
  Endif
     
End
