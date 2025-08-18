;+
; NAME:
;   rbsp_interp_spin_phase (function)
;
; PURPOSE:
;   Calculate spin phases at arbitrary times using linear interpolation.
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   phase = rbsp_interp_spin_phase(sc, time_array, $
;     newname = newname $
;     , tper = tper $
;     , tphase = tphase $
;     , tumbra_sta = tumbra_sta $
;     , tumbra_end = tumbra_end $
;     , umbra_pad = umbra_pad)
;
; ARGUMENTS:
;   sc: (In, required) Spacecraft name. Should be 'a' or 'b'.
;   time_array: (In, required) A time array at which spin phases are returned.
;
; KEYWORDS:
;   newname: (In, optional) A tplot name for storing the returned spin phases.
;       If not provided, the spin phases are not stored into a tplot name.
;   tper: (In, optional) Spin-period tplot name. By default, 
;           tper = 'rbsp' + strlowcase(sc[0]) + '_spinper'
;   tphase: (In, optional) Spin-phase tplot name. By default, 
;           tphase = 'rbsp' + strlowcase(sc[0]) + '_spinphase'
;   tumbra_sta: (In, optional) Umbra starting time tplot name. By default, 
;           tumbra_sta = 'rbsp' + strlowcase(sc[0]) + '_umbta_sta'
;   tumbra_end: (In, optional) Umbra ending time tplot name. By default, 
;           tumbra_sta = 'rbsp' + strlowcase(sc[0]) + '_umbta_end'
;   umbra_pad: (In, optional) Time padding to the umbra times. By default, 
;           umbra_pad = [-20d, 20d] * 60d
;         This padding is to account for spin-period distrotion around umbra.
;         APL has learned this problem, so this default padding will likely
;         change in the future.
;
; COMMON BLOCKS:
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;   2012-10-24: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;   2012-11-05: Initial release to TDAS. JBT, SSL/UCB.
;
;
; VERSION:
; $LastChangedBy: nikos $
; $LastChangedDate: 2016-10-06 16:51:43 -0700 (Thu, 06 Oct 2016) $
; $LastChangedRevision: 22061 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_interp_spin_phase.pro $
;
;-

;-------------------------------------------------------------------------------
function rbsp_interp_spin_phase_integration, per, tarr, t0, phi0, time_array
  ; Calcuate phase at tarr that has spin period per.
  compile_opt idl2, hidden 

  omega = 2d * !dpi / per

  dt = tarr[1:*] - tarr
  dphi = omega * dt
  nt = n_elements(tarr)
  phase = dblarr(nt)
  for i = 1L, nt - 1 do phase[i] = phase[i-1] + dphi[i-1]
  phase = phase * !radeg
  phase_out = interpol(phase, tarr, time_array)

  if n_elements(time_array) gt 1 then begin
    phase0 = interpol(phase_out, time_array, t0)
  endif else begin
    phase0 = phase_out[0]
  endelse
  offset = phase0 - phi0
  phase_out -= offset

  nfold = abs(round(-min(phase_out) / 360d)) + 1L
  phase_out += nfold * 360d

  phase_out = phase_out mod 360

  return, phase_out
end



;-------------------------------------------------------------------------------
function rbsp_interp_spin_phase, sc, time_array, $
  newname = newname $
  , tper = tper $
  , tphase = tphase $
  , tumbra_sta = tumbra_sta $
  , tumbra_end = tumbra_end $
  , umbra_pad = umbra_pad

compile_opt idl2

if n_elements(sc) eq 0 or size(sc, /type) ne 7 then begin
  dprint, 'Invalid spacecraft name argument. Abort.'
  return, -1
endif

rbx = 'rbsp' + strlowcase(sc[0]) + '_'

; Umbra padding.
if n_elements(umbra_pad) eq 0 then umbra_pad = [-20d, 20d] * 60d ; 20 min

; Check existence of spin period.
if n_elements(tper) eq 0 then tper = rbx + 'spinper'
if ~spd_check_tvar(tper) then begin
  dprint, 'Spin period data not available. Abort.'
  return, -1
endif
get_data, tper, data = dat_per

; Check if time_array is covered by timespan
tspan = timerange()
tr = minmax(time_array)
if tr[0] lt tspan[0] or tr[1] gt tspan[1] then begin
  dprint, 'The input time array exceeds the coverage of time span. Abort.'
  return, -1
endif

; Check existence of spin phase.
if n_elements(tphase) eq 0 then tphase = rbx + 'spinphase'
if ~spd_check_tvar(tphase) then begin
  dprint, 'Spin phase data not available. Abort.'
  return, -1
endif
get_data, tphase, data = dat_ph

; tper and tphase should have the same time tag.
if max(dat_ph.x - dat_per.x) - min(dat_ph.x - dat_per.x) gt 1e-6 then begin
  dprint, 'Spin period and spin phase data do not have the same time tags.' + $
    ' Abort.'
  return, -1
endif

; Special case: time_array covers a very short time range, namely, it covers no 
; spin period data points.
nt = n_elements(dat_per.x)
ind = where(dat_per.x gt tr[0] and dat_per.x lt tr[1], nind)
if nind eq 0 then begin
  dprint, 'Time array very short. Be cautious about the interpolation results!'
  ; Head
  if tr[1] lt dat_per.x[0] then begin
    tarr = interpol([tr[0], dat_per.x[0]], 1e2)
    per = tarr * 0d + dat_per.y[0]
    t0 = dat_per.x[0]
    phi0 = dat_ph.y[0]
    phase_out = rbsp_interp_spin_phase_integration(per, tarr, t0, phi0, $
      time_array)
    if size(newname, /type) eq 7 then begin
      store_data, newname, data = {x:time_array, y:phase_out}
      options, newname, ysubtitle = '[degree]'
    endif
    return, phase_out
  endif
  ; Tail
  if tr[0] gt dat_per.x[nt-1] then begin
    tarr = interpol([dat_per.x[nt-1], tr[1]], 1e2)
    per = tarr * 0d + dat_per.y[nt-1]
    t0 = dat_per.x[nt-1]
    phi0 = dat_ph.y[nt-1]
    phase_out = rbsp_interp_spin_phase_integration(per, tarr, t0, phi0, $
      time_array)
    if size(newname, /type) eq 7 then begin
      store_data, newname, data = {x:time_array, y:phase_out}
      options, newname, ysubtitle = '[degree]'
    endif
    return, phase_out
  endif
  ; Middle
  i0 = value_locate(dat_per.x, tr[0])
  t0 = dat_per.x[i0]
  t1 = dat_per.x[i0+1]
  tarr = interpol([t0, t1], 1e2)
  per = interpol(dat_per.y, dat_per.x, tarr)
  phi0 = dat_ph.y[i0]
  phase_out = rbsp_interp_spin_phase_integration(per, tarr, t0, phi0, $
    time_array)
  if size(newname, /type) eq 7 then begin
    store_data, newname, data = {x:time_array, y:phase_out}
    options, newname, ysubtitle = '[degree]'
  endif
  return, phase_out
endif

; Check existence of eclipse times.
if n_elements(tumbra_sta) eq 0 then tumbra_sta = rbx + 'umbra_sta'
if n_elements(tumbra_end) eq 0 then tumbra_end = rbx + 'umbra_end'
if ~spd_check_tvar(tumbra_sta) or ~spd_check_tvar(tumbra_end) then begin
;   dprint, 'Eclipse times not available. Abort.'
;   return, -1
  seg_tr = dblarr(5, 2)
  dt_seg = (tspan[1] - tspan[0]) / 5d
  seg_tr[*, 0] = tspan[0] + dindgen(5) * dt_seg
  seg_tr[*, 1] = tspan[0] + (dindgen(5) + 1d) * dt_seg
endif else begin
  get_data, tumbra_sta, data = udat_sta
  get_data, tumbra_end, data = udat_end
  umbra_tr = [[udat_sta.x + umbra_pad[0]], [udat_end.x + umbra_pad[1]]]

  ; Break spin period data into segments.
  n_umbra = n_elements(udat_sta.x)
  seg_tr = dblarr(n_umbra*2+1, 2)
  for i = 0, n_umbra-1 do begin
    seg_tr[i*2+1, *] = umbra_tr[i, *]
    if i eq 0 then seg_tr[i*2,0] = dat_per.x[0] else $
      seg_tr[i*2,0] = umbra_tr[i-1,1]
    seg_tr[i*2,1] = umbra_tr[i,0]
  endfor
  seg_tr[2*n_umbra, 0] = umbra_tr[n_umbra-1,1]
  ; seg_tr[2*n_umbra, 1] = dat_per.x[nt-1]
  ; seg_tr[2*n_umbra, 1] = max(time_array) + 0.1
  seg_tr[2*n_umbra, 1] = tspan[1]
endelse

; Loop over seg_tr.
nseg = n_elements(seg_tr[*,0])
; umbra_seg = intarr(nseg)
; umbra_seg[1:*:2] = 1
phase_out = time_array
; dt_per = median(dat_per.x[1:*] - dat_per.x)
for i = 0, nseg-1 do begin
  tmptr = seg_tr[i,*]
  ind = where(time_array ge tmptr[0] and time_array lt tmptr[1], nind)
  if nind eq 0 then continue
  ista = ind[0]
  iend = ind[nind-1]
  tsta = tmptr[0]
  tend = tmptr[1]

;   print, ' # ', jbt_istr(i+1), ' out of ', jbt_istr(nseg), ':'
;   print, 'ista = ', ista
;   print, 'iend = ', iend 
;   help, time_array
;   print, 'time_array span: ', time_string(minmax(time_array), prec = 3)
;   print, 'tmptr: ', time_string(reform(tmptr), prec = 3)
;   print, ''
;   stop

  ; Determine phase reference point.
  dum = minmax(time_array[ista:iend])
  tmp_ind = where(dat_per.x ge dum[0] and dat_per.x le dum[1], tmp_nind)
  if tmp_nind eq 0 then begin
    dprint, 'No spin period data covered by time_array. Something is off.'
    stop
    return, -1
  endif
  i0 = tmp_ind[0]

  t0 = dat_per.x[i0]
  phi0 = dat_ph.y[i0]

  dt = 0.2d  ; This number is derived based on the smoothness of the spin-period
             ; sine curve.
  nt = (tend - tsta) / dt + 1L
  tarr = tsta + dindgen(nt) * dt
  per = interpol(dat_per.y, dat_per.x, tarr)
;   print, ista, iend
;   stop
  phase_out[ista:iend] = $
    rbsp_interp_spin_phase_integration(per, tarr, t0, phi0, $
    time_array[ista:iend])

  ; Check t0 and phi0
;   !p.multi = [0, 1, 2]
;   dum0 = t0 - 20.
;   xr = [0, 50]
;   yr = [0, 400]
;   ; spin phase
;   cgplot, dat_ph.x - dum0, dat_ph.y, psym = -2, color = 6, xr = xr, /xsty, $
;     title = time_string(dum0, prec = 3), yr = yr, /ysty
;   plots, t0 - dum0, phi0, color = 4, psym = 1, symsize = 3
;   tmp = phase_out[ista:iend]
;   x = time_array[ista:iend]
;   oplot, x - dum0, tmp, psym = 1
; ;   ; spin period
; ;   plot, dat_per.x - dum0, dat_per.y, xr = xr, /xsty, $
; ;     yr = minmax(dat_per.y) + [-0.01, 0.01], $
; ;     /ysty
; ;   oplot, tarr - dum0, per, color = 6
; ;   !p.multi = 0
;   stop


  ; Check.
;   tmp_time_array = time_array[ista:iend]
;   tmp_phase = phase_out[ista:iend]
;   store_data, 'tmp', data = {x:time_array[ista:iend], $
;     y:phase_out[ista:iend]}
;   options, tphase, psym = 2, colors = [6]
;   store_data, 'tmp2',  data = [tphase, 'tmp']
;   dum_tr = minmax(time_array[ista:iend])
;   tplot, 'tmp2', trange = dum_tr + [-5e2, 5e2]
;   timebar, dum_tr
;   ind = where(dat_ph.x ge dum_tr[0] and dat_ph.x le dum_tr[1])
;   print, 'phase data index range: ', minmax(ind)
;   print, 'initial index: ', i0
;   stop

endfor

if size(newname, /type) eq 7 then begin
  store_data, newname, data = {x:time_array, y:phase_out}
  options, newname, ysubtitle = '[degree]'
endif
return, phase_out


end
