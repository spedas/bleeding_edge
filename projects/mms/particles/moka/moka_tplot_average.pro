; Get an average between trange from a tplot-variable
; THis is used when we need a magnetic field direction for a FPI sample.
FUNCTION moka_tplot_average, mag_name, trange, norm=norm
  compile_opt idl2
  tn=tnames(mag_name,ct)
  if ct eq 0 then message, mag_name+' does not exist'
  if n_elements(trange) ne 2 then message, 'trange must be a 2-element array.'
  tr = time_double(trange)
  get_data,mag_name,data=B
  idx = where( (tr[0] le B.x) and (B.x lt tr[1]), nmax)
  if nmax eq 0 then message, 'No data point found in the specified time range.'
;  nstart = idx[0]
;  nstop = idx[nmax-1]
  sz = size(B.y)
  dim = sz[0]
  
  if dim eq 1 then begin
    bavg = total(B.y[idx])/double(nmax)
    return, bavg
  endif
  
  if dim eq 2 then begin
    if sz[2] eq 3 then begin
      bx_avg = total(B.y[idx,0])/double(nmax)
      by_avg = total(B.y[idx,1])/double(nmax)
      bz_avg = total(B.y[idx,2])/double(nmax)
      
      ; ensure bmag is a unit vector
      if keyword_set(norm) then begin
        btot = sqrt(bx_avg^2+by_avg^2+bz_avg^2)
        bx_avg /= btot
        by_avg /= btot
        bz_avg /= btot
      endif

      return, [bx_avg, by_avg, bz_avg]
    endif else stop
  endif else stop
END