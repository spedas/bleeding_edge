Function tmp_outlier_reject, x0, alpha, beta, min_points, sigma, nkeep, x_out = x

  keep0 = where(finite(x0))
  If(keep0[0] Ne -1) Then x = x0[keep0] Else Begin
    sigma = 0.0
    Return, !values.d_nan
  Endelse

  y = 0
  xbar = mean(x)
  sigma = stddev(x)

  keep = where(abs(x-xbar) le sigma*(alpha+beta*y), nkeep)

  If(nkeep Le min_points) Then Begin
    sigma = 0.0
    Return, !values.d_nan
  Endif Else If(nkeep Eq n_elements(x)) Then Return, xbar
    
  x = x[keep]
;do this again, until you converge  
  Repeat Begin
    y = y+1
    xbar = mean(x)
    sigma = stddev(x)
    keep = where(abs(x-xbar) le sigma*(alpha+beta*y), nkeep)
    nx = n_elements(x)
    If(nkeep Le min_points) Then Begin
      sigma = 0.0
      Return, !values.d_nan
    Endif Else If(nkeep Eq nx) Then Return, xbar
  Endrep Until (nkeep Eq nx or nkeep le min_points)

;If you're here, check
  If(nkeep Le min_points) Then Begin
    sigma = 0.0
    Return, !values.d_nan
  Endif Else If(nkeep Eq nx) Then Return, xbar

  End
;+
;Name:
; spinavg
;Purpose:
; performs a spinavg on B or E field data, results are average values
; over the spin periods -- nothing else
;Calling Sqeuence:
; spinavg,arr_in_t,arr_in_data,arr_in_sunpulse_t,arr_in_sunpulse_data, $
;         arr_out_data,arr_out_sigma,npoints,sun_data,$
;         min_points=min_points,alpha=alpha,beta=beta
;Input:
;  arr_in_t = time array for the data
;  arr_in_data = the data to be spin fit
;  arr_in_sunpulse_t = time array for sunpulse data
;  arr_in_sunpulse_data = sunpulse data
;Output:
;  arr_out_data = the array averaged over the spin periods
;  sigma = sigma for each spin period
;  npoints = number of points in fit for each spin period
;  sun_data = midpoint times of spitfit data
;keywords:
;  min_points = Minimum number of points to fit.  Default = 5.
;  alpha = A parameter for finding fits.  Points outside of sigma*(alpha + beta*i)
;          will be thrown out.  Default 1.4.
;  beta = A parameter for finding fits.  See above.  Default = 0.4
;-
pro spinavg, arr_in_t, arr_in_data, arr_in_spin_t, $
             arr_out_data, arr_out_sigma, npoints, sun_data, $
             min_points = min_points, alpha = alpha, beta = beta, _extra = _extra

  if not keyword_set(alpha) then alpha = 1.4
  if not keyword_set(beta) then beta = 0.4
  if not keyword_set(min_points) then min_points = 5

; Make sure ARR_IN_T is monotonic (if necessary, sort it....).  Update ARR_IN_DATA correspondingly:
;
  size_xxx = size(arr_in_t)
  monoton = 1b
  non_monoton_detected = 0b
  k0 = 0L
  k1 = k0+1L
  while monoton && ( k1 le size_xxx[1]-1 ) do begin
    if (arr_in_t[ k1++ ] - arr_in_t[ k0++ ] lt 0) then begin
      non_monoton_detected = 1b
      monoton = 0b
    endif
  endwhile
  if non_monoton_detected  then begin
    dprint, '*** WARNING: Non-monotonic time tags detected.  Sorting data'
    ss_sort = bsort(arr_in_t)
    arr_in_t = arr_in_t[ss_sort]
    arr_in_data = arr_in_data[ss_sort, *]
  endif

; find portion of data where the input overlaps the spin times
;
  size_xxx = size(arr_in_t)
  overlap1 = where(arr_in_spin_t ge arr_in_t[0] and arr_in_spin_t le arr_in_t[size_xxx[1]-1])
  sizeoverlap = size(overlap1)

; define dummy arrays to be filled later
;
  ncomp = n_elements(arr_in_data[0, *])
  arr_out_data = dblarr(sizeoverlap[1]-1, ncomp)+!values.d_nan
  arr_out_sigma = arr_out_data
  sun_data = 0.5*(arr_in_spin_t[overlap1[1:*]]+arr_in_spin_t[overlap1])
  Npoints = lonarr(sizeoverlap[1]-1, ncomp)
  i = 0L
  j = (where(arr_in_t ge arr_in_spin_t[overlap1[i]] and arr_in_t le arr_in_spin_t[overlap1[i+1]]))[0]
  for i = 0L, sizeoverlap[1]-2 do begin
; select a one period chunk of data:
    overlap = j
    while ( j lt size_xxx[1] ) && ( arr_in_t[j] le arr_in_spin_t[overlap1[i+1]] ) do begin
      overlap = [ overlap, j ]
      ++j
    endwhile
    if n_elements( overlap ) gt 1 then overlap = temporary( overlap[1:*] )
    if n_elements(overlap) ge min_points then begin
      thx_xxx_keepx = arr_in_t[overlap]
    ; throw out points 1.4 stddev (alpha) away from mean
      for k = 0, ncomp-1 do begin ;have to do this separately for each component
        arr_out_data[i, k] = tmp_outlier_reject(arr_in_data[overlap, k], alpha, beta, min_points, sigma, npts)
        arr_out_sigma[i, k] = sigma
        npoints[i, k] = npts
      endfor
    endif
  endfor                        ; i

end

;+
;NAME:
; thm_spinavg
;PURPOSE: 
; average data over spin periods, and return a tplot variable
;CALLING SEQUENCE:
; thm_spinavg,var_name_in, $
;          sigma=sigma, npoints=npoints, spinaxis=spinaxis, median=median, $
;          plane_dim=plane_dim, axis_dim=axis_dim,  $
;          min_points=min_points,alpha=alpha,beta=beta, $
;          phase_mask_starts=phase_mask_starts,phase_mask_ends=phase_mask_ends, $
;          sun2sensor=sun2sensor
;INPUT:
;  var_name_in = tplot variable name containing data to fit
;keywords:
;  sigma = If set, will cause program to output tplot variable with
;          sigma for each period.
;  npoints = If set, will cause program to output tplot variable with
;            of points in fit.
;  spin_frac_offset = If set, the time array of the variable will be
;                     offset by this fraction of an average spin
;                     period before averaging.
;  absv = if set, fit the absolute value.
;  min_points = Minimum number of points to fit.  Default = 5.
;  alpha = A parameter for finding fits.  Points outside of
;          sigma*(alpha + beta*i) will be thrown out for the ith
;          iteration.  Default 1.4.
;  beta = A parameter for finding fits.  See above.  Default = 0.4
; $LastChangedBy: aaflores $
; $LastChangedDate: 2012-01-26 16:43:03 -0800 (Thu, 26 Jan 2012) $
; $LastChangedRevision: 9624 $
; $URL:
;-

pro thm_spinavg, var_name_in, sigma = sigma, npoints = npoints, $
                 spin_frac_offset = spin_frac_offset, absv = absv, $
                 _extra = _extra


  vn = tnames(var_name_in)
  If(is_string(vn) Eq 0) Then Begin
    dprint, 'No variable: '+var_name_in
    Return
  Endif
  
  If(keyword_set(spin_frac_offset)) Then Begin
    sp0 = spin_frac_offset
  Endif Else sp0 = 0.0

  nvn = n_elements(vn)
  For i = 0, nvn-1 Do Begin
    probe = strmid(vn[i], 2, 1)
    thx = 'th'+probe[0]
    get_data, vn[i], data = thx_xxx_in, dl = dl
    tri = minmax(thx_xxx_in.x)
    get_data, 'th'+probe[0]+'_state_spinper', data = thx_spinper
    If(is_struct(thx_spinper) Eq 0) Then Begin
      thm_load_state, probe = probe[0], /get_support_data, trange = tri
      get_data, 'th'+probe[0]+'_state_spinper', data = thx_spinper
    Endif
    If(is_struct(thx_spinper) Eq 0) Then Begin
      dprint, 'No Spin Period Available: '+vn[i]
      Continue
    Endif
    ok_spin = where(finite(thx_spinper.y))
    If(ok_spin[0] Eq -1) Then begin ;not real likely
      dprint, 'No Spin Period Available: '+vn[i]
      Continue
    Endif
;Get the average spin period
    av_spinper = mean(thx_spinper.y[ok_spin])
;create spin times in bins starting at the first time in the variable
;data array
    nspins = ceil((tri[1]-tri[0])/av_spinper)
    spin_times = tri[0]+av_spinper*dindgen(nspins+1)
;Apply shift to data here:
    If(keyword_set(absv)) Then Begin
      spinavg, thx_xxx_in.x+sp0*av_spinper, abs(thx_xxx_in.y), spin_times, $
        d, s, n, spin_midpoint, _extra = _extra
    Endif Else Begin
      spinavg, thx_xxx_in.x+sp0*av_spinper, thx_xxx_in.y, spin_times, $
        d, s, n, spin_midpoint, _extra = _extra
    Endelse
    store_data, vn[i]+'_spinavg', data = {x:spin_midpoint, y:d}, dl = dl
    If keyword_set(sigma) Then store_data, vn[i]+'_spinavg_sig', data = {x:spin_midpoint, y:s}, dl = dl
    If keyword_set(Npoints) Then store_data, vn[i]+'_spinavg_npoints', data = {x:spin_midpoint, y:n}, dl = dl
  Endfor                        ;i
End

