;
;
; PROCEDURE: mms_timing_method.pro
;
; PURPOSE: To determine the propagation direction and speed of a structure (discontinuity, wave, bow shock, etc.)
;          using four-point MMS spacecraft measurements
; INPUT:
;         BDATA = (signal)this is the timeseries that carries the structure signature,
;                 could be |B|, n, a component of the field, etc.
;         PDATA = Four spacecraft position vectors. By default it uses 'mms*_mec_r_gse'.
;         TRANGE = Time range covering the structure. If this keyword is not provided
;                  a tplot window should be available to click-select a time range. The time range
;                  should cover the structure in all four s/c. Also select it long enough so the
;                  routine has some wiggle room to determine the highest correlations.
;
;
; OUTPUT:
;         KVECTOR = Propagation unit vector in whatever coordinate system the position vectors are (default=gse).
;         SPEED = Propagation speed in km/s.
;         TIMEDELAYS = Time delay in observation between different spacecraft pairs.
;         CORRCOEFF = Correlation coefficients of shifted and unshifted signals between different spacecraft
;                     pair. This is a number between 0 and 1.
;
; KEYWORDS:
;         TPLT: Plot the results (shifted and unshifted signals) on a tplot window.
;         SAVEPLOT: Save the tplot window as an .ps file.
;         DRATE: Data rate for the bdata.
;         CHECKQF: Check MMS tetrahedron quality factor. The routine is not usable for string-of-pearl.
;         BOWSHOCK: If the timing is on the main bow shock crossing, setting this keyword ensures that
;                   the bow shock normal is pointed outward towards the sun, regardless of inward/outward motion. In this
;                   case, a negative speed means an inward (Earthward) bow shock motion.
;         TFINAL: If the structure is selected from a tplot window, this keyword returns the selected time range.
;
; EXAMPLES:
;         > mms_timing_method, trange = time_double('2018-01-08/'+['06:41:10.619','06:41:10.901']), kvector = kvector
;           ;;;;; get the propagation direction of an IP shock in GSE
;         > mms_timing_method, trange = time_double('2023-04-24/'+['03:50:10.78','03:50:13.41']), drate='srvy', /tplt, kvector=kvector, speed = speed, /bowshock
;           ;;;;; Get the propagation direction and speed of a bow shock crossing using survey mode magnetic field data.
;
; Written by: Hadi Madanian (2025-04-04)
; todos: optimize correlation finder; add rotation matrix output
;
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-04-10 15:55:15 -0700 (Thu, 10 Apr 2025) $
; $LastChangedRevision: 33253 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/mms_timing_method.pro $


pro mms_timing_method, bdata = bdata, pdata = pdata, trange = trange, kvector = kvector, speed = speed, $
  window=window, drate = drate,  bowshock = bowshock, corrcoeff = corrcoeff, timedelays = timedelays, $
  saveplot = saveplot, tplt = tplt, matrix = matrix, tfinal = tfinal, checkqf = checkqf

  @tplot_com

  current_window= !d.window
  if current_window ge 0 then begin
    currtpnm = tplot_vars.options.varnames
    currtptr  = tplot_vars.options.trange
  endif

  probes = ['1','2','3','4']
  if undefined(drate) then drate = 'brst'
  if undefined(bdata) then bdata = ['mms'+probes+'_fgm_b_gse_'+drate+'_l2_btot']
  if undefined(pdata) then pdata = ['mms'+probes+'_mec_r_gse']
  if ~keyword_set(trange) then begin
    dprint,'Selecting the time range from the current tplot window for correlation: '
    if (current_window lt 0) then begin
      printd, 'No active window found.... a time range must be provided'
      stop
    endif
    ctime, trange, npoints=2, /silent, /EXACT
    wait, 1
  endif
  tfinal = trange
  trt = [trange[0]-60, trange[0]+60]


  if keyword_set(checkqf) then begin
    mms_load_tqf, trange=trt
    get_data,'mms_tetrahedron_qf',data=dqf
    if ~finite(mean(dqf.y)) then begin
      printd, 'There may not be a tetrahedron. Check formation or unset checkqf flag.'
      return
    endif
    qf = spd_tplot_average('mms_tetrahedron_qf', trange)
    qf = spd_tplot_average('mms_tetrahedron_qf', trange)
    if qf < 0.7 then begin
      print, 'MMS tetrahedron quality flag is less than 0.7; unset checkqf flag to proceed'
      return
    endif else print, 'MMS tetrahedron quality flag is above 0.7'
  endif

  mustlodb = 0b
  mustlodpos = 0b
  if ~tdexists(bdata[0], trange[0], trange[1]) then mustlodb=1b
  if ~tdexists(bdata[1], trange[0], trange[1]) then mustlodb=1b
  if ~tdexists(bdata[2], trange[0], trange[1]) then mustlodb=1b
  if ~tdexists(bdata[3], trange[0], trange[1]) then mustlodb=1b
  if ~tdexists(pdata[0], trt[0], trt[1]) then mustlodpos=1b
  if ~tdexists(pdata[1], trt[0], trt[1]) then mustlodpos=1b
  if ~tdexists(pdata[2], trt[0], trt[1]) then mustlodpos=1b
  if ~tdexists(pdata[3], trt[0], trt[1]) then mustlodpos=1b
  if mustlodb then begin
    if ~keyword_set(drate) then begin
      print, 'For loading data, drate keyword must be set.'
      return
    endif
  endif
  if (mustlodb) then mms_load_fgm, trange=trt, probes = probes, data_rate= drate
  if (mustlodpos) then mms_load_state, trange = trt, probe = probes, datatypes = 'pos', /ephemeris_only
  bdata=bdata[sort(bdata)]
  pdata=pdata[sort(pdata)]
  for ii=0,3 do tinterpol, pdata[ii], bdata[ii], /SPLINE, /NAN_EXTRAPOLATE
  posdata = pdata+'_interp'
  store_data,'*intpd_shifted',/del


  suffix = '_shifted'
  dt_arr = dblarr(6) * 0.0
  possc = dblarr(3,4) * 0.0
  tcros1 = dblarr(6) * 0.0
  maxcorr = dt_arr

  bn_mms1 = tsample(bdata[0], trange, times = tarray1, index = indss)
  dt = (tarray1[1]-tarray1[0])
  bnt =n_elements(tarray1)
  bnt1=bnt
  lags = lindgen(bnt) - ceil(bnt/2.0)
  for ii = 1 , 3 do begin        ;;; Loop over S/C pairs
    curr_sc = bdata[ii]
    tinterpol, curr_sc , bdata[0], newname = curr_sc + '_intpd', /NEAREST_NEIGHBOR
    get_data, curr_sc + '_intpd', temp, dataarr
    result = dblarr(size(lags,/dim))
    for kk = 0 , n_elements(lags)-1 do begin
      shift_arr = shift(dataarr, lags[kk])
      bn_mms = shift_arr[indss]
      result[kk] = CORRELATE(bn_mms1, bn_mms, /double)
    endfor
    maxcorr[ii-1] = max(result, maxind)
    dt_arr[ii-1] = lags[maxind] * dt      ;;  Finding the time lag
    get_data, curr_sc + '_intpd', data = dd
    store_data, curr_sc + '_intpd' + suffix, data = {x: (dd.x + dt_arr[ii-1]), y: dd.y}
    options, curr_sc + '_intpd' + suffix, 'labels', 'mms' + probes[ii]
  endfor



  t1 = tarray1[ceil(bnt/2)]
  tcros1[0:2] = t1 - dt_arr[0:2]



  ;;;; Doing the same for MMS2-MMS3 and MMS2-MMS4 ;;;;;
  bn_mms2 = tsample(bdata[1], trange, times = tarray2, index = indss)
  dt = (tarray2[1]-tarray2[0])
  bnt =n_elements(tarray2)
  lags = lindgen(bnt) - ceil(bnt/2.0)
  for ii=2,3 do begin
    curr_sc = bdata[ii]
    tinterpol, curr_sc , bdata[1], newname = curr_sc + '_intpd', /NEAREST_NEIGHBOR
    get_data, curr_sc + '_intpd', temp, dataarr
    result = dblarr(size(lags,/dim))
    for kk = 0 , n_elements(lags)-1 do begin
      shift_arr = shift(dataarr, lags[kk])
      bn_mms = shift_arr[indss]
      result[kk] = CORRELATE(bn_mms2, bn_mms, /double)
    endfor
    maxcorr[ii+1] = max(result, maxind)
    dt_arr[ii+1] = lags[maxind] * dt      ;;  f Finding the time lag
  endfor

  ;tmid = tarray2[ceil(bnt/2)]
  ;tcros1[3:4] = tmid - dt_arr[3:4]


  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;; Doing the same for MMS2-MMS3 and MMS2-MMS4 ;;;;;
  bn_mms3 = tsample(bdata[2], trange, times = tarray3, index = indss)
  dt = (tarray3[1]-tarray3[0])
  bnt =n_elements(tarray3)
  lags = lindgen(bnt) - ceil(bnt/2.0)
  curr_sc = bdata[3]
  tinterpol, curr_sc , bdata[2], newname = curr_sc + '_intpd', /NEAREST_NEIGHBOR
  get_data, curr_sc + '_intpd', temp, dataarr
  result = dblarr(size(lags,/dim))
  for kk = 0 , n_elements(lags)-1 do begin
    shift_arr = shift(dataarr, lags[kk])
    bn_mms = shift_arr[indss]
    result[kk] = CORRELATE(bn_mms3, bn_mms, /double)
  endfor
  maxcorr[5] = max(result, maxind)
  dt_arr[5] = lags[maxind] * dt      ;;  Finding the time lag


  ;;;; recreat MMS1 variable for consistency and grouping later.
  copy_data, bdata[0], bdata[0] + '_intpd' + suffix
  copy_data, bdata[0], bdata[0] + '_intpd'
  options, bdata[0] + '_intpd' + suffix, 'labels', 'mms' + probes[0]
  options, bdata[0] + '_intpd', 'labels', 'mms' + probes[0]


  possc[*,0] = data_cut(posdata[0],t1)
  possc[*,1] = data_cut(posdata[1],tcros1[0])
  possc[*,2] = data_cut(posdata[2],tcros1[1])
  possc[*,3] = data_cut(posdata[3],tcros1[2])
  inds = where(possc eq 0.0, cnt)
  if cnt gt 0 then begin
    print, 'Position vector is empty: Somethin not right'
    stop
  endif

  Tmat = dt_arr
  Dmat = [[possc[*,0]-possc[*,1]], [possc[*,0]-possc[*,2]], [possc[*,0]-possc[*,3]], $
    [possc[*,1]-possc[*,2]], [possc[*,1]-possc[*,3]], [possc[*,2]-possc[*,3]]]

  ;m = LA_LINEAR_EQUATION(Dmat, Tmat)

  SVDC, Dmat, Ww, Uu, vV
  sv = FLTARR(3, 3)
  FOR kk = 0, 2 DO sv[kk,kk] = Ww[kk]
  m = vV ## INVERT(SV) ## TRANSPOSE(Uu) ## Tmat
  speed = 1/norm(m, /double,LNORM=2)
  kvector = transpose(m * speed)
  corrcoeff = maxcorr
  timedelays = dt_arr
  inds = where(maxcorr lt 0.85,cnt)
  if cnt gt 0 then begin
    print, '!!!!=======---- Correlation coefficient too low < 0.85, bad correlation, maybe choose a differnet period'
    print, 'between MMS1 and', probes[inds+1]
  endif

  dsize = get_screen_size()
  if keyword_set(tplt) then begin
    if keyword_set(window) then Dwin = window else begin
      window, /free, xsize=dsize[0]/2., ysize=dsize[1]*2.5/3.,xpos=dsize[0]/4., ypos=dsize[1]/3.
      Dwin = !d.window
    endelse
    wset,Dwin
    stornm = 'unshifted_original'
    ;  store_data, stornm, /del
    store_data, stornm, data = bdata, dlim={constant:0}
    options, stornm ,'colors', [0, 210, 1, 135]
    options, stornm, 'labels', ['mms'+probes]
    options, stornm, 'labflag', -1
    options, stornm, 'ystyle',1
    options, stornm, 'yrange',[0,0]
    options, bdata, 'ystyle',1
    options, bdata, 'yrange',[0,0]

    stornm = 'shifted_signals'
    ;  store_data, stornm, /del
    store_data, stornm, data = [ bdata + '_intpd' + '_shifted' ], dlim={constant:0}
    options, 'shifted_signals' ,'colors', [0, 210, 1, 135]
    options, 'shifted_signals', 'labels', ['mms'+probes]
    options, 'shifted_signals', 'labflag', -1
    options, 'shifted_signals', 'ystyle',1
    options, 'shifted_signals', 'yrange',[0,0]
    options, bdata + '_intpd' + '_shifted', 'yrange',[0,0]
    options, bdata + '_intpd' + '_shifted', 'ystyle',1
    ;    options,'*_intpd_shifted','ystyle',1


    tplot,['unshifted_original', 'shifted_signals'], window=Dwin
    timebar, trange, linestyle=2
  endif
  ;wait, 0.2
  store_data,posdata,/del

  if keyword_set(bowshock) then begin
    if kvector[0] lt 0 then begin
      kvector = -kvector
      speed = -speed
    endif
  endif

  print, 'Correlation Coefs: ', corrcoeff
  print, 'Time delays (s): ', timedelays
  print, 'k_vec in gse: ', kvector
  print, 'speed: ', speed
  print, 'final time range:', time_string(tfinal)

  if keyword_set(matrix) then begin
    kvector = matrix ## kvector
    print, 'k_vec in NCB: ', kvector
  endif


  if keyword_set(saveplot) then begin
    popen, 'timing_analysis_figure', xsize=8, ysize=4, unit='inches'
    tplot,['unshifted_original', 'shifted_signals']
    timebar, trange, linestyle=2
    xyouts, 0.3 , 0.4, 'Correlation Coefs: ' + strtrim(corrcoeff, 2), /NORMAL, color=0
    xyouts, 0.3 , 0.5, 'Time delays (s): ' + strtrim(timedelays, 2), /NORMAL, color=0
    xyouts, 0.3 , 0.6, 'k_vec in gse: ' + strtrim(kvector, 2), /NORMAL, color=0
    xyouts, 0.3 , 0.7, 'speed: ' + strtrim(speed, 2) + ' km/s', /NORMAL, color=0
    pclose
  endif


  ;store_data, '*_intpd*',/del

  if (current_window ge 0) then tplot, currtpnm, window=current_window, trange = currtptr
end