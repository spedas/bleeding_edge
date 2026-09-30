;+
;PROCEDURE:  polar_to_xyz, rtp
;            polar_to_xyz, r, theta, phi
;PURPOSE: Calculates x, y and z given magnitude, theta and phi. This is the
;         inverse of xyz_to_polar, and a tplot wrapper around sphere_to_cart.
;INPUT:   Either one argument holding all three components (RTP), or three
;         arguments holding them separately (R, THETA, PHI).
;   One argument, RTP. Several options exist:
;    string:    name(s) of tplot variable(s) whose data.y is an array(n,3).
;               Wildcards are allowed.
;    structure: data.y is assumed to contain the array(n,3)
;    array(n,3)   n by (r,theta,phi components), in the order set by ORDER
;    array(3)     vector:  [r,theta,phi]
;   Three arguments, R, THETA, PHI. Each one may be:
;    string:    the name of one tplot variable holding one value per time
;    structure: {x:times, y:values}
;    array(n)   or a scalar, which is used for every sample (R=1 gives unit
;               vectors). Arrays given with tplot variables must already be
;               on the output time grid.
;RETURN VALUES: through the XYZ keyword, and as a new tplot variable when an
;    input is a tplot variable.
;KEYWORDS:
;   XYZ:        Named variable in which the result is returned: the name of
;               the new tplot variable if an input is a tplot variable, a
;               structure {x:times, y:array(n,3)} if an input is a structure,
;               otherwise an array(n,3) (array(3) for a single vector).
;   ORDER:      One argument only: the order of the components along the
;               second dimension of RTP. A 3-element string array or one string
;               separated by commas or spaces. Default: 'r,theta,phi'.
;               Accepted names are r, mag, magnitude; theta, th, t, con;
;               phi, ph, p, clk. The one-letter form may be written without
;               separators, e.g. order='ptr' is the same as order='phi,theta,r'.
;   NEWNAME:    Name of the output tplot variable. Only one tplot variable may
;               be converted when NEWNAME is set.
;   SUFFIX:     Suffix of the output tplot variable name. Default: '_xyz'.
;   TPLOTNAMES: Named variable in which the names of the new tplot variables
;               are returned.
;   ERROR:      Named variable set to 1 on success and 0 on failure. With
;               several tplot variables it is 1 only if all were converted.
;OPTION KEYWORDS:  These describe the input angles and match the xyz_to_polar
;   keywords of the same name, so the same keywords undo xyz_to_polar.
;   CO_LATITUDE:   If set, theta is co-latitude (0<=theta<=180). Otherwise
;                  theta is latitude (-90<=theta<=90), the xyz_to_polar default.
;   RADIANS:       If set, theta and phi are in radians. Otherwise they are in
;                  degrees, as xyz_to_polar returns them.
;   CLOCK:         If set, theta and phi are the cone and clock angles made by
;                  xyz_to_polar,/clock.
;   NEGATE:        If set, the result is negated, undoing xyz_to_polar,/negate.
;   Phi may be in any range (-180 to 180, 0 to 360, or beyond), so the
;   xyz_to_polar keywords PH_0_360 and PH_HIST are not needed here.
;
;SEE ALSO:
;  xyz_to_polar.pro, sphere_to_cart.pro, cart_to_sphere.pro
;
;EXAMPLES:
;
;     Undoing xyz_to_polar:
;xyz_to_polar,'Vp',magnitude=m,theta=th,phi=ph  ; makes 'Vp_mag','Vp_th','Vp_phi'
;polar_to_xyz,m,th,ph        ; makes 'Vp_xyz', equal to 'Vp' to rounding error
;xyz_to_polar,'Vp',/co_latitude,/clock
;polar_to_xyz,'Vp_mag','Vp_con','Vp_clk',/co_latitude,/clock,newname='Vp2'
;
;     Angles in radians, theta as co-latitude:
;polar_to_xyz,'pos_r','pos_colat','pos_lon',/radians,/co_latitude
;    This makes 'pos_r_xyz'.
;
;     One variable holding (phi, theta, r):
;polar_to_xyz,'B_sph',order='phi,theta,r'      ; makes 'B_sph_xyz'
;
;     Unit vectors from direction angles:
;polar_to_xyz,1.,'B_th','B_phi',newname='B_dir'
;
;     Passing arrays:
;polar_to_xyz,[2.,30.,45.],xyz=v        ; v = [1.2247449, 1.2247449, 1.0000000]
;polar_to_xyz,mag,th,ph,xyz=vecs        ; vecs will be an array(n,3)
;polar_to_xyz,[[mag],[th],[ph]],xyz=vecs ; same result
;
;NOTES:
;   Output name: the input name plus SUFFIX. With separate variables it is
;   built from R, with a trailing '_mag' removed, so 'Vp_mag','Vp_th','Vp_phi'
;   give 'Vp_xyz'. If R is not a tplot variable, THETA (without '_th' or
;   '_con') is used, then PHI (without '_phi' or '_clk').
;   Separate tplot variables on different time grids are interpolated with
;   tinterpol_mxn onto the times of the first one given (R, then THETA, then
;   PHI). Phi is unwrapped first so it interpolates across the +-180 degree
;   cut. Times outside an input's time range get NaN.
;   dlimits are copied from the R (or RTP) tplot variable, so units and
;   coordinate system carry over. Labels become x,y,z and colors [2,4,6];
;   ylog, yrange, min_value and max_value are removed because they apply to
;   the magnitude, not to signed components. Limits are not copied.
;   The result is double if any input is double, float otherwise, as for
;   xyz_to_polar. A magnitude of 0 gives [0,0,0] whatever the angles
;   (xyz_to_polar returns a NaN theta for a zero vector).
;   Unlike xyz_to_polar, numbers are always data, never tplot variable
;   indices.
;   What cannot be undone: xyz_to_polar,/quick_mag makes no angles, samples
;   that MAX_VALUE/MIN_VALUE replaced by MISSING are lost, and xyz_to_polar
;   does not copy dlimits (labels, units, coordinate system) to its outputs.
;
;CREATED BY:  Zesen Huang  2026-09-29  (spedas/bleeding_edge issue #22)
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-


;helper: 1 if v is a real number or an array of real numbers
function polar_to_xyz_is_real, v

  compile_opt idl2, hidden

  t = size(v, /type)
  return, (t ge 1 && t le 5) || (t ge 12 && t le 15)

end


;helper: returns the column of r, theta and phi given by ORDER, or -1
function polar_to_xyz_order, order

  compile_opt idl2, hidden

  if n_elements(order) eq 0 then return, [0l, 1l, 2l]

  if size(order, /type) ne 7 then begin
    dprint, 'ORDER must be a string, e.g. order=''r,theta,phi'''
    return, -1l
  endif

  o = strlowcase(strtrim(order, 2))
  if n_elements(o) eq 1 then begin
    o = strsplit(o[0], ' ,', /extract)
    ;one-letter form without separators, e.g. 'rtp'
    if n_elements(o) eq 1 && strlen(o[0]) eq 3 then $
      o = [strmid(o[0], 0, 1), strmid(o[0], 1, 1), strmid(o[0], 2, 1)]
  endif

  if n_elements(o) ne 3 then begin
    dprint, 'ORDER must name three components, e.g. order=''r,theta,phi'''
    return, -1l
  endif

  idx = lonarr(3)
  for k = 0, 2 do begin
    case k of
      0: names = ['r', 'mag', 'magnitude']
      1: names = ['theta', 'th', 't', 'con']
      2: names = ['phi', 'ph', 'p', 'clk']
    endcase
    hit = bytarr(3)
    for j = 0, n_elements(names)-1 do hit = hit or (o eq names[j])
    w = where(hit, nw)
    if nw ne 1 then begin
      dprint, 'ORDER must name r, theta and phi once each, not: ' + strjoin(o, ',')
      return, -1l
    endif
    idx[k] = w[0]
  endfor

  return, idx

end


;helper: the conversion itself, on arrays with one element per sample
function polar_to_xyz_calc, r, theta, phi, co_latitude=co_latitude, $
  radians=radians, clock=clock, negate=negate

  compile_opt idl2, hidden

  ;sphere_to_cart takes latitude and longitude in degrees
  if keyword_set(radians) then begin
    lat = theta * (180d / !dpi)
    lon = phi * (180d / !dpi)
  endif else begin
    lat = theta
    lon = phi
  endelse
  if keyword_set(co_latitude) then lat = 90d - lat

  sphere_to_cart, r, lat, lon, x, y, z

  ;xyz_to_polar,/clock converts (z,-y,x) instead of (x,y,z)
  if keyword_set(clock) then begin
    tmp = x
    x = z
    y = -y
    z = tmp
  endif

  if keyword_set(negate) then begin
    x = -x
    y = -y
    z = -z
  endif

  ;a zero vector has no direction; xyz_to_polar gives it a NaN theta
  w = where(r eq 0, nw)
  if nw gt 0 then begin
    x[w] = 0
    y[w] = 0
    z[w] = 0
  endif

  xyz = [[x], [y], [z]]

  ;sphere_to_cart works in double; keep float input float
  if size(r, /type) ne 5 && size(theta, /type) ne 5 && size(phi, /type) ne 5 then $
    xyz = float(xyz)

  return, xyz

end


;helper: converts an array(n,3) or array(3) holding r, theta and phi
function polar_to_xyz_rtp, data, idx, label, error=error, _extra=opts

  compile_opt idl2, hidden

  error = 0

  if ~polar_to_xyz_is_real(data) then begin
    dprint, label + ' must be a numeric array(n,3) or array(3)'
    return, -1
  endif

  dim = size(data, /dimensions)
  ndim = size(data, /n_dimensions)
  if ndim eq 2 && dim[1] eq 3 then begin
    rr = data[*, idx[0]]
    tt = data[*, idx[1]]
    pp = data[*, idx[2]]
  endif else if ndim eq 1 && dim[0] eq 3 then begin
    rr = [data[idx[0]]]
    tt = [data[idx[1]]]
    pp = [data[idx[2]]]
  endif else begin
    dprint, label + ' must be an array(n,3) or array(3), not [' + $
      strjoin(strtrim(dim, 2), ',') + ']'
    return, -1
  endelse

  xyz = polar_to_xyz_calc(rr, tt, pp, _extra=opts)
  if ndim eq 1 then xyz = reform(xyz)

  error = 1
  return, xyz

end


;helper: reads one of R, THETA, PHI (tplot name, structure or numbers)
function polar_to_xyz_component, v, label, time=time, has_time=has_time, $
  name=name, dlimits=dl, error=error

  compile_opt idl2, hidden

  error = 0
  has_time = 0
  name = ''
  dl = 0

  vtype = size(v, /type)
  if vtype eq 0 then begin
    dprint, label + ' is undefined'
    return, -1
  endif

  if vtype eq 7 || vtype eq 8 then begin
    if vtype eq 7 then begin
      if n_elements(v) ne 1 then begin
        dprint, label + ' must be a single tplot variable name'
        return, -1
      endif
      tn = tnames(v[0], n)
      if n ne 1 then begin
        if n eq 0 then dprint, 'No tplot variable matches ' + v[0] + ' (' + label + ')' $
        else dprint, v[0] + ' matches ' + strtrim(n, 2) + ' tplot variables; ' + $
          label + ' must match exactly one'
        return, -1
      endif
      name = tn[0]
      get_data, name, data=d, dlimits=dl
      if ~is_struct(d) then begin
        dprint, name + ' has no data'
        return, -1
      endif
      what = name
    endif else begin
      d = v
      what = label
    endelse

    str_element, d, 'x', t, success=sx
    str_element, d, 'y', y, success=sy
    if ~sx || ~sy then begin
      dprint, what + ' must have x and y tags'
      return, -1
    endif
    if ~polar_to_xyz_is_real(y) then begin
      dprint, what + ' must hold numbers'
      return, -1
    endif
    if n_elements(y) ne n_elements(t) then begin
      dprint, what + ' must hold one value per time, not [' + $
        strjoin(strtrim(size(y, /dimensions), 2), ',') + ']'
      return, -1
    endif
    has_time = 1
    error = 1
    if n_elements(y) eq 1 then begin
      time = [t[0]]
      return, [y[0]]
    endif
    time = t
    return, reform(y, n_elements(y))
  endif

  if ~polar_to_xyz_is_real(v) then begin
    dprint, label + ' must be a tplot variable name, a structure or numbers'
    return, -1
  endif

  error = 1
  if n_elements(v) eq 1 then return, v[0]
  return, reform(v, n_elements(v))

end


;helper: removes jumps of more than half a period from an angle series
function polar_to_xyz_unwrap, a, period

  compile_opt idl2, hidden

  out = double(a)
  w = where(finite(out), nw)
  if nw lt 2 then return, out

  aw = out[w]
  jumps = round((aw[1:*] - aw[0:nw-2]) / period)
  out[w] = aw - period * [0d, total(double(jumps), /cumulative)]

  return, out

end


;helper: interpolates one component onto the output time grid
function polar_to_xyz_regrid, val, t, tref, label, period=period, error=error

  compile_opt idl2, hidden

  error = 1
  if n_elements(t) eq n_elements(tref) && array_equal(t, tref) then return, val

  error = 0
  dprint, dlevel=2, 'Interpolating ' + label + ' onto the time grid of the first input'

  if keyword_set(period) then y = polar_to_xyz_unwrap(val, period) else y = val
  tinterpol_mxn, {x:t, y:y}, tref, out=out_d, /nan_extrapolate, error=err
  if ~keyword_set(err) || ~is_struct(out_d) then begin
    dprint, 'Could not interpolate ' + label + ' onto the time grid of the first input'
    return, -1
  endif

  error = 1
  if size(val, /type) eq 4 then return, float(out_d.y)
  return, out_d.y

end


;helper: dlimits of the output, based on those of the input
function polar_to_xyz_dlimits, dl

  compile_opt idl2, hidden

  if is_struct(dl) then new_dl = dl else new_dl = 0

  str_element, new_dl, 'labels', ['x', 'y', 'z'], /add_replace
  str_element, new_dl, 'colors', [2, 4, 6], /add_replace
  str_element, new_dl, 'labflag', -1, /add_replace

  ;these apply to the magnitude, not to signed components
  str_element, new_dl, 'ylog', /delete
  str_element, new_dl, 'yrange', /delete
  str_element, new_dl, 'min_value', /delete
  str_element, new_dl, 'max_value', /delete

  return, new_dl

end


;helper: removes one of the xyz_to_polar suffixes from a tplot name
function polar_to_xyz_base, name, suffixes

  compile_opt idl2, hidden

  ln = strlen(name)
  for i = 0, n_elements(suffixes)-1 do begin
    ls = strlen(suffixes[i])
    if ln gt ls && strmid(name, ln-ls) eq suffixes[i] then return, strmid(name, 0, ln-ls)
  endfor

  return, name

end


pro polar_to_xyz, r, theta, phi, $
    xyz = xyz, $
    order = order, $
    newname = newname, $
    suffix = suffix, $
    tplotnames = tplotnames, $
    co_latitude = co_latitude, $
    radians = radians, $
    clock = clock, $
    negate = negate, $
    error = error

  compile_opt idl2

  error = 0
  tplotnames = ''
  if n_elements(suffix) gt 0 then sfx = suffix[0] else sfx = '_xyz'
  opts = {co_latitude:keyword_set(co_latitude), radians:keyword_set(radians), $
    clock:keyword_set(clock), negate:keyword_set(negate)}

  nparams = n_params()
  if nparams ne 1 && nparams ne 3 then begin
    dprint, 'Usage: polar_to_xyz, rtp  or  polar_to_xyz, r, theta, phi'
    return
  endif

  ;------------------------------------------------------------------------
  ; one argument holding r, theta and phi
  ;------------------------------------------------------------------------
  if nparams eq 1 then begin

    idx = polar_to_xyz_order(order)
    if idx[0] lt 0 then return

    ;tplot variables
    if size(r, /type) eq 7 then begin
      names = tnames(r, n)
      if n eq 0 then begin
        dprint, 'No tplot variables match: ' + strjoin(r, ' ')
        return
      endif
      if keyword_set(newname) && n gt 1 then begin
        dprint, 'NEWNAME cannot be used when several tplot variables match: ' + $
          strjoin(names, ' ')
        return
      endif
      nok = 0
      for i = 0, n-1 do begin
        dprint, dlevel=3, 'Computing x,y,z for ', names[i]
        get_data, names[i], data=d, dlimits=dl
        if ~is_struct(d) then begin
          dprint, names[i] + ' has no data'
          continue
        endif
        str_element, d, 'x', t, success=sx
        str_element, d, 'y', y, success=sy
        if ~sx || ~sy then begin
          dprint, names[i] + ' must have x and y tags'
          continue
        endif
        v = polar_to_xyz_rtp(y, idx, names[i], error=err, _extra=opts)
        if ~err then continue
        if keyword_set(newname) then outname = newname else outname = names[i] + sfx
        store_data, outname, data={x:t, y:v}, dlimits=polar_to_xyz_dlimits(dl)
        xyz = outname
        tplotnames = keyword_set(tplotnames) ? [tplotnames, outname] : outname
        nok = nok + 1
      endfor
      error = (nok eq n) ? 1 : 0
      return
    endif

    ;structure
    if size(r, /type) eq 8 then begin
      str_element, r, 'y', y, success=sy
      if ~sy then begin
        dprint, 'RTP structure must have a y tag'
        return
      endif
      v = polar_to_xyz_rtp(y, idx, 'RTP', error=err, _extra=opts)
      if ~err then return
      str_element, r, 'x', t, success=sx
      if sx then xyz = {x:t, y:v} else xyz = {y:v}
      error = 1
      return
    endif

    ;array
    v = polar_to_xyz_rtp(r, idx, 'RTP', error=err, _extra=opts)
    if ~err then return
    xyz = v
    error = 1
    return

  endif

  ;------------------------------------------------------------------------
  ; three arguments: r, theta and phi
  ;------------------------------------------------------------------------
  if n_elements(order) gt 0 then $
    dprint, dlevel=2, 'ORDER is ignored when R, THETA and PHI are given separately'

  rv = polar_to_xyz_component(r, 'R', time=tr, has_time=hr, name=nr, dlimits=dlr, error=err)
  if ~err then return
  tv = polar_to_xyz_component(theta, 'THETA', time=tt, has_time=ht, name=nt, error=err)
  if ~err then return
  pv = polar_to_xyz_component(phi, 'PHI', time=tp, has_time=hp, name=nph, error=err)
  if ~err then return

  has_ref = hr || ht || hp
  if has_ref then begin
    ;output times: those of the first input that has times
    if hr then tref = tr else if ht then tref = tt else tref = tp
    if keyword_set(radians) then period = 2d * !dpi else period = 360d
    if hr then begin
      rv = polar_to_xyz_regrid(rv, tr, tref, 'R', error=err)
      if ~err then return
    endif
    if ht then begin
      tv = polar_to_xyz_regrid(tv, tt, tref, 'THETA', error=err)
      if ~err then return
    endif
    if hp then begin
      pv = polar_to_xyz_regrid(pv, tp, tref, 'PHI', period=period, error=err)
      if ~err then return
    endif
    n = n_elements(tref)
  endif else n = max([n_elements(rv), n_elements(tv), n_elements(pv)])

  ;arrays must match the number of samples; scalars are used for every sample
  sizes = [n_elements(rv), n_elements(tv), n_elements(pv)]
  if total(sizes eq 1 or sizes eq n) ne 3 then begin
    dprint, 'R, THETA and PHI must have ' + strtrim(n, 2) + $
      ' elements or be scalars; they have ' + strjoin(strtrim(sizes, 2), ', ')
    return
  endif
  single = ~has_ref && n eq 1
  if sizes[0] eq 1 then rv = replicate(rv[0], n)
  if sizes[1] eq 1 then tv = replicate(tv[0], n)
  if sizes[2] eq 1 then pv = replicate(pv[0], n)

  v = polar_to_xyz_calc(rv, tv, pv, _extra=opts)
  if single then v = reform(v)

  ;arrays in, array out
  if ~has_ref then begin
    xyz = v
    error = 1
    return
  endif

  ;structures in, structure out
  d = {x:tref, y:v}
  if nr eq '' && nt eq '' && nph eq '' then begin
    xyz = d
    error = 1
    return
  endif

  ;tplot variables in, tplot variable out
  if keyword_set(newname) then outname = newname $
  else if nr ne '' then outname = polar_to_xyz_base(nr, ['_mag']) + sfx $
  else if nt ne '' then outname = polar_to_xyz_base(nt, ['_th', '_con']) + sfx $
  else outname = polar_to_xyz_base(nph, ['_phi', '_clk']) + sfx

  store_data, outname, data=d, dlimits=polar_to_xyz_dlimits(dlr)
  xyz = outname
  tplotnames = outname
  error = 1

end
