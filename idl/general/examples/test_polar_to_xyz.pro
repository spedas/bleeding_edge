;+
;PROCEDURE:  test_polar_to_xyz
;PURPOSE:  Round-trip tests for polar_to_xyz (spedas/bleeding_edge issue #22).
;   Builds synthetic x,y,z data, runs xyz_to_polar -> polar_to_xyz in each mode
;   (separate or single variables, latitude or co-latitude, degrees or radians,
;   /clock, /negate, component orders, different time grids, arrays and
;   structures) and prints PASS or FAIL with the largest absolute difference.
;   It also checks hand-computed points and the error handling.
;
;   The expected values of the hand-computed points, and every round trip
;   below, were checked in numpy with check_polar_to_xyz.py (same folder),
;   which mirrors cart_to_sphere, xyz_to_polar, sphere_to_cart and
;   polar_to_xyz step by step.
;
;USAGE:  (SPEDAS, including the new idl/general/science/polar_to_xyz.pro, on !path)
;   .compile test_polar_to_xyz
;   test_polar_to_xyz
;
;   Messages printed by polar_to_xyz during the error-handling tests are
;   expected. xyz_to_polar also prints floating-point warnings for the zero
;   and z-axis vectors.
;-


;helper: compares two numeric arrays (NaN must match NaN) and prints PASS/FAIL
pro test_polar_to_xyz_check, label, got, expected, tol, npass, nfail

  compile_opt idl2

  maxdiff = !values.d_nan
  ok = n_elements(got) gt 0 && n_elements(got) eq n_elements(expected)
  if ok then ok = size(got, /type) ne 7 && size(got, /type) ne 8
  if ok then begin
    g = double(reform(got, n_elements(got)))
    e = double(reform(expected, n_elements(expected)))
    ok = array_equal(finite(g), finite(e))
    w = where(finite(e), nw)
    if nw gt 0 then maxdiff = max(abs(g[w] - e[w])) else maxdiff = 0d
    ok = ok && (maxdiff le tol)
  endif

  if ok then npass = npass + 1 else nfail = nfail + 1
  print, (ok ? 'PASS  ' : 'FAIL  ') + string(label, format='(A-52)') + $
    ' max|diff| = ' + string(maxdiff, format='(E10.3)') + $
    '  (tol ' + strtrim(string(tol, format='(G10.2)'), 2) + ')'

end


;helper: prints PASS/FAIL for a condition
pro test_polar_to_xyz_assert, label, condition, npass, nfail

  compile_opt idl2

  ok = n_elements(condition) eq 1 && keyword_set(condition)
  if ok then npass = npass + 1 else nfail = nfail + 1
  print, (ok ? 'PASS  ' : 'FAIL  ') + label

end


;helper: data.y of a tplot variable, or NaN if it does not exist
function test_polar_to_xyz_y, name

  compile_opt idl2

  if size(name, /type) ne 7 || name eq '' then return, !values.d_nan
  get_data, name, data=d
  if ~is_struct(d) then return, !values.d_nan
  return, d.y

end


pro test_polar_to_xyz

  compile_opt idl2

  npass = 0
  nfail = 0
  tol = 1d-10       ; double precision round trips
  tolf = 1d-5       ; float round trips (numpy mirror: up to 1.4e-6)
  d2r = !dpi / 180d

  del_data, 'p2x_*'

  ;--------------------------------------------------------------------------
  ; synthetic data: same formulas as check_polar_to_xyz.py. |v| is 0.69 to 12.1,
  ; x changes sign and phi crosses +-180 degrees 4 times.
  ;--------------------------------------------------------------------------
  n = 500
  i = dindgen(n)
  t0 = time_double('2020-01-01')
  t = t0 + 60d * i
  x = 3d + 7d * cos(0.11d * i)
  y = 5d * sin(0.07d * i + 0.3d)
  z = 4d * cos(0.05d * i + 1d) - 1d
  v = [[x], [y], [z]]
  store_data, 'p2x_v', data={x:t, y:v}, dlimits={labels:['vx', 'vy', 'vz'], $
    colors:[2, 4, 6], ysubtitle:'[km/s]', data_att:{units:'km/s', coord_sys:'gse'}}

  print
  print, '--- separate r, theta, phi tplot variables ---'

  xyz_to_polar, 'p2x_v', magnitude=m, theta=th, phi=ph
  out = ''
  polar_to_xyz, m, th, ph, xyz=out, error=err
  test_polar_to_xyz_assert, 'ERROR=1 and default name p2x_v_xyz', $
    err eq 1 && out eq 'p2x_v_xyz', npass, nfail
  test_polar_to_xyz_check, 'latitude, degrees (defaults)', test_polar_to_xyz_y(out), v, tol, npass, nfail
  get_data, out, data=d
  if is_struct(d) then begin
    tx = d.x
    ytype = size(d.y, /type)
  endif else begin
    tx = 0
    ytype = 0
  endelse
  test_polar_to_xyz_assert, 'output times equal input times', array_equal(tx, t), npass, nfail
  test_polar_to_xyz_assert, 'double in, double out', ytype eq 5, npass, nfail

  xyz_to_polar, 'p2x_v', magnitude=m, theta=th, phi=ph, /co_latitude
  get_data, th, data=dth
  test_polar_to_xyz_assert, '(xyz_to_polar /co_latitude gives 0<=theta<=180)', $
    min(dth.y) ge 0 && max(dth.y) le 180, npass, nfail
  out = ''
  polar_to_xyz, m, th, ph, /co_latitude, newname='p2x_colat', xyz=out
  test_polar_to_xyz_check, '/co_latitude', test_polar_to_xyz_y(out), v, tol, npass, nfail

  xyz_to_polar, 'p2x_v', magnitude=m, theta=th, phi=ph, /ph_0_360
  get_data, ph, data=dph
  test_polar_to_xyz_assert, '(xyz_to_polar /ph_0_360 gives 0<=phi<=360)', $
    min(dph.y) ge 0 && max(dph.y) gt 180, npass, nfail
  out = ''
  polar_to_xyz, m, th, ph, newname='p2x_0_360', xyz=out
  test_polar_to_xyz_check, 'phi from /ph_0_360, no keyword needed', test_polar_to_xyz_y(out), v, tol, npass, nfail

  xyz_to_polar, 'p2x_v', magnitude=m, theta=th, phi=ph, /clock
  test_polar_to_xyz_assert, '(xyz_to_polar /clock names _con and _clk)', $
    th eq 'p2x_v_con' && ph eq 'p2x_v_clk', npass, nfail
  out = ''
  polar_to_xyz, m, th, ph, /clock, newname='p2x_clock', xyz=out
  test_polar_to_xyz_check, '/clock', test_polar_to_xyz_y(out), v, tol, npass, nfail

  xyz_to_polar, 'p2x_v', magnitude=m, theta=th, phi=ph, /clock, /co_latitude
  out = ''
  polar_to_xyz, m, th, ph, /clock, /co_latitude, newname='p2x_clock_colat', xyz=out
  test_polar_to_xyz_check, '/clock /co_latitude', test_polar_to_xyz_y(out), v, tol, npass, nfail

  xyz_to_polar, 'p2x_v', magnitude=m, theta=th, phi=ph, /negate
  out = ''
  polar_to_xyz, m, th, ph, /negate, newname='p2x_negate', xyz=out
  test_polar_to_xyz_check, '/negate', test_polar_to_xyz_y(out), v, tol, npass, nfail

  ;radians: convert the xyz_to_polar angles
  xyz_to_polar, 'p2x_v', magnitude=m, theta=th, phi=ph
  get_data, m, data=dm
  get_data, th, data=dth
  get_data, ph, data=dph
  store_data, 'p2x_th_rad', data={x:t, y:dth.y * d2r}
  store_data, 'p2x_phi_rad', data={x:t, y:dph.y * d2r}
  out = ''
  polar_to_xyz, m, 'p2x_th_rad', 'p2x_phi_rad', /radians, newname='p2x_rad', xyz=out
  test_polar_to_xyz_check, '/radians', test_polar_to_xyz_y(out), v, tol, npass, nfail

  xyz_to_polar, 'p2x_v', magnitude=m, theta=th, phi=ph, /co_latitude
  get_data, th, data=dthc
  store_data, 'p2x_colat_rad', data={x:t, y:dthc.y * d2r}
  out = ''
  polar_to_xyz, m, 'p2x_colat_rad', 'p2x_phi_rad', /co_latitude, /radians, newname='p2x_colat_rad_xyz', xyz=out
  test_polar_to_xyz_check, '/co_latitude /radians', test_polar_to_xyz_y(out), v, tol, npass, nfail

  ;scalar magnitude: unit vectors, and the name comes from theta
  xyz_to_polar, 'p2x_v', magnitude=m, theta=th, phi=ph
  out = ''
  polar_to_xyz, 1, th, ph, xyz=out
  vmag = sqrt(total(v^2, 2))
  test_polar_to_xyz_assert, 'R=1: name from theta is p2x_v_xyz', out eq 'p2x_v_xyz', npass, nfail
  test_polar_to_xyz_check, 'R=1 gives unit vectors', test_polar_to_xyz_y(out), $
    v / rebin(vmag, n, 3), tol, npass, nfail

  ;structures in, structure out
  s = 0
  polar_to_xyz, {x:t, y:dm.y}, {x:t, y:dth.y}, {x:t, y:dph.y}, xyz=s
  test_polar_to_xyz_assert, 'three structures give a structure', $
    is_struct(s) && array_equal(s.x, t), npass, nfail
  if is_struct(s) then sy = s.y else sy = !values.d_nan
  test_polar_to_xyz_check, 'three structures', sy, v, tol, npass, nfail

  print
  print, '--- one tplot variable holding all three components ---'

  store_data, 'p2x_rtp', data={x:t, y:[[dm.y], [dth.y], [dph.y]]}, $
    dlimits={labels:['r', 'th', 'phi'], ysubtitle:'[km/s]', data_att:{units:'km/s', coord_sys:'gse'}}
  out = ''
  polar_to_xyz, 'p2x_rtp', xyz=out, error=err, tplotnames=tn
  test_polar_to_xyz_assert, 'ERROR=1, name p2x_rtp_xyz, TPLOTNAMES', $
    err eq 1 && out eq 'p2x_rtp_xyz' && n_elements(tn) eq 1 && tn[0] eq out, npass, nfail
  test_polar_to_xyz_check, 'default order r,theta,phi', test_polar_to_xyz_y(out), v, tol, npass, nfail
  get_data, out, dlimits=dl
  labs = ''
  cols = 0
  units = ''
  csys = ''
  str_element, dl, 'labels', labs
  str_element, dl, 'colors', cols
  str_element, dl, 'data_att.units', units
  str_element, dl, 'data_att.coord_sys', csys
  test_polar_to_xyz_assert, 'dlimits: labels x,y,z, colors 2,4,6, units kept', $
    array_equal(labs, ['x', 'y', 'z']) && array_equal(cols, [2, 4, 6]) && $
    units eq 'km/s' && csys eq 'gse', npass, nfail

  store_data, 'p2x_prt', data={x:t, y:[[dph.y], [dm.y], [dth.y]]}
  out = ''
  polar_to_xyz, 'p2x_prt', order='phi,r,theta', xyz=out
  test_polar_to_xyz_check, 'order=''phi,r,theta''', test_polar_to_xyz_y(out), v, tol, npass, nfail
  out = ''
  polar_to_xyz, 'p2x_prt', order=['ph', 'mag', 'th'], newname='p2x_prt2', xyz=out
  test_polar_to_xyz_check, 'order=[''ph'',''mag'',''th'']', test_polar_to_xyz_y(out), v, tol, npass, nfail

  store_data, 'p2x_ptr', data={x:t, y:[[dph.y], [dth.y], [dm.y]]}
  out = ''
  polar_to_xyz, 'p2x_ptr', order='PTR', xyz=out
  test_polar_to_xyz_check, 'order=''PTR'' (compact, upper case)', test_polar_to_xyz_y(out), v, tol, npass, nfail

  store_data, 'p2x_tpr_rad', data={x:t, y:[[dthc.y * d2r], [dph.y * d2r], [dm.y]]}
  out = ''
  polar_to_xyz, 'p2x_tpr_rad', order='theta phi r', /co_latitude, /radians, xyz=out
  test_polar_to_xyz_check, 'order=''theta phi r'' /co_latitude /radians', $
    test_polar_to_xyz_y(out), v, tol, npass, nfail

  ;wildcards
  store_data, 'p2x_g1_rtp', data={x:t, y:[[dm.y], [dth.y], [dph.y]]}
  store_data, 'p2x_g2_rtp', data={x:t, y:[[2 * dm.y], [dth.y], [dph.y]]}
  tn = ''
  polar_to_xyz, 'p2x_g?_rtp', tplotnames=tn, error=err
  test_polar_to_xyz_assert, 'wildcard: two variables made', err eq 1 && n_elements(tn) eq 2 && $
    array_equal(tn, ['p2x_g1_rtp_xyz', 'p2x_g2_rtp_xyz']), npass, nfail
  test_polar_to_xyz_check, 'wildcard: second variable', test_polar_to_xyz_y('p2x_g2_rtp_xyz'), 2 * v, tol, npass, nfail

  s = 0
  polar_to_xyz, {x:t, y:[[dm.y], [dth.y], [dph.y]]}, xyz=s
  if is_struct(s) then sy = s.y else sy = !values.d_nan
  test_polar_to_xyz_check, 'structure {x,y} in, structure out', sy, v, tol, npass, nfail

  print
  print, '--- arrays ---'

  xyz_to_polar, v, magnitude=ma, theta=tha, phi=pha
  va = 0
  polar_to_xyz, [[ma], [tha], [pha]], xyz=va
  test_polar_to_xyz_check, 'array(n,3)', va, v, tol, npass, nfail
  va = 0
  polar_to_xyz, ma, tha, pha, xyz=va
  test_polar_to_xyz_check, 'three array(n)', va, v, tol, npass, nfail
  va = 0
  polar_to_xyz, 1d, tha, pha, xyz=va
  test_polar_to_xyz_check, 'scalar R=1 with array(n) angles', va, v / rebin(vmag, n, 3), tol, npass, nfail

  print
  print, '--- float input ---'

  store_data, 'p2x_vf', data={x:t, y:float(v)}
  xyz_to_polar, 'p2x_vf', magnitude=m, theta=th, phi=ph
  out = ''
  polar_to_xyz, m, th, ph, xyz=out
  yf = test_polar_to_xyz_y(out)
  test_polar_to_xyz_assert, 'float in, float out', size(yf, /type) eq 4, npass, nfail
  test_polar_to_xyz_check, 'float round trip', yf, float(v), tolf, npass, nfail
  xyz_to_polar, 'p2x_vf', magnitude=m, theta=th, phi=ph, /clock, /co_latitude
  out = ''
  polar_to_xyz, m, th, ph, /clock, /co_latitude, newname='p2x_vf_clock', xyz=out
  test_polar_to_xyz_check, 'float round trip /clock /co_latitude', test_polar_to_xyz_y(out), $
    float(v), tolf, npass, nfail

  print
  print, '--- separate variables on different time grids ---'

  ;theta and phi every 20 s from 30 s before the first r time, r every 60 s.
  ;Both angles are linear in time, so linear interpolation is exact once phi
  ;is unwrapped. phi grows 3 deg/min and is exactly 180 at r samples 117, 237,
  ;357 and 477, where interpolating the wrapped phi would be wrong (numpy: by 4.97).
  nb = 3 * n + 3
  tb = t0 - 30d + 20d * dindgen(nb)
  phib = ((-171d + 0.05d * (tb - t0) + 180d) mod 360d) - 180d
  latb = -60d + 120d * (tb - t0) / (60d * n)
  r_true = 2d + sin(0.02d * i)
  store_data, 'p2x_tg_mag', data={x:t, y:r_true}, dlimits={ysubtitle:'[nT]', ylog:1, $
    data_att:{units:'nT', coord_sys:'gsm'}}
  store_data, 'p2x_tg_th', data={x:tb, y:latb}
  store_data, 'p2x_tg_phi', data={x:tb, y:phib}
  sphere_to_cart, r_true, -60d + 120d * (t - t0) / (60d * n), -171d + 0.05d * (t - t0), xe, ye, ze
  vexp = [[xe], [ye], [ze]]

  out = ''
  polar_to_xyz, 'p2x_tg_mag', 'p2x_tg_th', 'p2x_tg_phi', xyz=out
  test_polar_to_xyz_assert, 'name p2x_tg_xyz (from R, _mag removed)', out eq 'p2x_tg_xyz', npass, nfail
  get_data, out, data=d, dlimits=dl
  if is_struct(d) then tx = d.x else tx = 0
  test_polar_to_xyz_assert, 'output times are those of R', array_equal(tx, t), npass, nfail
  test_polar_to_xyz_check, 'theta, phi interpolated (phi unwrapped)', test_polar_to_xyz_y(out), $
    vexp, 1d-9, npass, nfail
  labs = ''
  units = ''
  csys = ''
  ysub = ''
  str_element, dl, 'labels', labs
  str_element, dl, 'data_att.units', units
  str_element, dl, 'data_att.coord_sys', csys
  str_element, dl, 'ysubtitle', ysub
  str_element, dl, 'ylog', success=has_ylog
  test_polar_to_xyz_assert, 'dlimits from R: units, coord_sys, ysubtitle kept, ylog removed', $
    units eq 'nT' && csys eq 'gsm' && ~has_ylog && ysub eq '[nT]' && $
    array_equal(labs, ['x', 'y', 'z']), npass, nfail

  ;angles known only for the first half of the r times: second half is NaN
  whalf = where(tb le t0 + 60d * (n / 2 - 1) + 10d)
  store_data, 'p2x_th_half', data={x:tb[whalf], y:latb[whalf]}
  store_data, 'p2x_phi_half', data={x:tb[whalf], y:phib[whalf]}
  out = ''
  polar_to_xyz, 'p2x_tg_mag', 'p2x_th_half', 'p2x_phi_half', newname='p2x_half', xyz=out
  yh = test_polar_to_xyz_y(out)
  if n_elements(yh) eq 3 * n then begin
    nnan = long(total(~finite(yh[*, 0])))
    yfirst = yh[0:n/2-1, *]
  endif else begin
    nnan = -1
    yfirst = !values.d_nan
  endelse
  test_polar_to_xyz_assert, 'outside the angle times: NaN (250 rows)', nnan eq n / 2, npass, nfail
  test_polar_to_xyz_check, 'inside the angle times', yfirst, vexp[0:n/2-1, *], 1d-9, npass, nfail

  print
  print, '--- special vectors: zero, +z, -z, NaN, -x, just below the -x axis ---'

  sp = [[0d, 0d, 0d, !values.d_nan, -4d, -1d], $
    [0d, 0d, 0d, 1d, 0d, -1d-12], $
    [0d, 2d, -3d, 1d, 0d, 0.5d]]
  xyz_to_polar, sp, magnitude=ms, theta=ths, phi=phs
  sp_exp = sp
  sp_exp[3, *] = !values.d_nan
  vs = 0
  polar_to_xyz, ms, ths, phs, xyz=vs
  test_polar_to_xyz_check, 'zero vector -> 0, NaN row -> NaN', vs, sp_exp, 1d-12, npass, nfail

  print
  print, '--- hand-computed points (expected values from numpy) ---'

  ;columns: (r, latitude in degrees, phi in degrees) -> (x, y, z)
  pts = [[1d, 0d, 0d], [2d, 90d, 0d], [3d, 30d, 45d], [5d, -45d, -120d], $
    [2d, 60d, 200d], [4d, -90d, 77d]]
  expv = [[1d, 0d, 0d], $
    [1.2246467991473532d-16, 0d, 2d], $
    [1.8371173070873839d, 1.8371173070873834d, 1.4999999999999998d], $
    [-1.7677669529663682d, -3.061862178478973d, -3.5355339059327373d], $
    [-0.9396926207859086d, -0.3420201433256687d, 1.7320508075688772d], $
    [5.5097117733407295d-17, 2.386518362048475d-16, -4d]]
  for k = 0, 5 do begin
    p = pts[*, k]
    e = expv[*, k]
    lab = '[' + strjoin(strtrim(string(p, format='(F7.1)'), 2), ',') + ']'
    pk = 0
    polar_to_xyz, p, xyz=pk
    test_polar_to_xyz_check, 'point ' + lab, pk, e, 1d-14, npass, nfail
    pk = 0
    polar_to_xyz, [p[0], 90d - p[1], p[2]], /co_latitude, xyz=pk
    test_polar_to_xyz_check, 'point ' + lab + ' as co-latitude', pk, e, 1d-14, npass, nfail
    pk = 0
    polar_to_xyz, [p[0], p[1] * d2r, p[2] * d2r], /radians, xyz=pk
    test_polar_to_xyz_check, 'point ' + lab + ' in radians', pk, e, 1d-14, npass, nfail
    pk = 0
    polar_to_xyz, [p[2], p[0], p[1]], order='phi,r,theta', xyz=pk
    test_polar_to_xyz_check, 'point ' + lab + ' order phi,r,theta', pk, e, 1d-14, npass, nfail
    pk = 0
    polar_to_xyz, p[0], p[1], p[2], xyz=pk
    test_polar_to_xyz_check, 'point ' + lab + ' as three scalars', pk, e, 1d-14, npass, nfail
  endfor

  ;the float example in the header
  pk = 0
  polar_to_xyz, [2., 30., 45.], xyz=pk
  test_polar_to_xyz_assert, 'header example [2.,30.,45.] is float [3]', $
    size(pk, /type) eq 4 && n_elements(pk) eq 3, npass, nfail
  test_polar_to_xyz_check, 'header example [2.,30.,45.]', pk, $
    [1.2247448713915892d, 1.224744871391589d, 0.9999999999999999d], 1d-6, npass, nfail

  ;/clock: xyz (1,2,3) has magnitude sqrt(14), cone asin(1/sqrt(14)) (co-latitude
  ;acos(1/sqrt(14))) and clock atan(-2,3)
  mag123 = 3.7416573867739413d
  con123 = 15.501359566936996d
  conc123 = 74.498640433063d
  clk123 = -33.690067525979785d
  xyz_to_polar, [1d, 2d, 3d], magnitude=mc, theta=thc, phi=phc, /clock
  test_polar_to_xyz_check, 'xyz_to_polar,[1,2,3],/clock', [mc, thc, phc], [mag123, con123, clk123], $
    1d-12, npass, nfail
  pk = 0
  polar_to_xyz, [mag123, con123, clk123], /clock, xyz=pk
  test_polar_to_xyz_check, 'cone/clock point back to [1,2,3]', pk, [1d, 2d, 3d], 1d-13, npass, nfail
  pk = 0
  polar_to_xyz, [mag123, conc123, clk123], /clock, /co_latitude, xyz=pk
  test_polar_to_xyz_check, 'cone (co-latitude)/clock point back to [1,2,3]', pk, [1d, 2d, 3d], $
    1d-13, npass, nfail
  xyz_to_polar, [1d, 1d, 1d], magnitude=m1, theta=th1, phi=ph1
  test_polar_to_xyz_check, 'xyz_to_polar,[1,1,1]', [m1, th1, ph1], $
    [1.7320508075688772d, 35.264389682754654d, 45d], 1d-12, npass, nfail

  print
  print, '--- error handling (polar_to_xyz prints a message each time) ---'

  store_data, 'p2x_2col', data={x:t, y:[[x], [y]]}
  err = -1
  polar_to_xyz, 'p2x_does_not_exist', error=err
  test_polar_to_xyz_assert, 'missing tplot variable: ERROR=0', err eq 0, npass, nfail
  err = -1
  polar_to_xyz, 'p2x_v_mag', 'p2x_does_not_exist', 'p2x_v_phi', error=err
  test_polar_to_xyz_assert, 'missing theta variable: ERROR=0', err eq 0, npass, nfail
  err = -1
  polar_to_xyz, 'p2x_2col', error=err
  test_polar_to_xyz_assert, 'two-column variable: ERROR=0', err eq 0, npass, nfail
  err = -1
  polar_to_xyz, transpose(v), error=err
  test_polar_to_xyz_assert, 'array(3,n) instead of array(n,3): ERROR=0', err eq 0, npass, nfail
  err = -1
  polar_to_xyz, 'p2x_rtp', 'p2x_v_th', 'p2x_v_phi', error=err
  test_polar_to_xyz_assert, 'R with three columns: ERROR=0', err eq 0, npass, nfail
  err = -1
  polar_to_xyz, 'p2x_rtp', order=['r', 'r', 'phi'], error=err
  test_polar_to_xyz_assert, 'ORDER naming r twice: ERROR=0', err eq 0, npass, nfail
  err = -1
  polar_to_xyz, 'p2x_rtp', order='r,theta', error=err
  test_polar_to_xyz_assert, 'ORDER with two names: ERROR=0', err eq 0, npass, nfail
  err = -1
  polar_to_xyz, [1d, 2d], [3d, 4d, 5d], [6d, 7d], error=err
  test_polar_to_xyz_assert, 'arrays of different lengths: ERROR=0', err eq 0, npass, nfail
  err = -1
  polar_to_xyz, 'p2x_v_mag', 'p2x_v_th', error=err
  test_polar_to_xyz_assert, 'two arguments: ERROR=0', err eq 0, npass, nfail
  err = -1
  polar_to_xyz, 'p2x_g?_rtp', newname='p2x_one', error=err
  test_polar_to_xyz_assert, 'NEWNAME with a wildcard matching two: ERROR=0', err eq 0, npass, nfail
  err = -1
  polar_to_xyz, 'p2x_v_*', 'p2x_v_th', 'p2x_v_phi', error=err
  test_polar_to_xyz_assert, 'R matching several variables: ERROR=0', err eq 0, npass, nfail
  err = -1
  polar_to_xyz, 'p2x_v_mag', 'p2x_v_th', 'abc', error=err
  test_polar_to_xyz_assert, 'PHI not a tplot variable: ERROR=0', err eq 0, npass, nfail

  print
  print, strtrim(npass, 2) + ' passed, ' + strtrim(nfail, 2) + ' failed'
  if nfail eq 0 then print, 'ALL TESTS PASSED' else print, 'SOME TESTS FAILED'

end