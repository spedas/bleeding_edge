; Regression tests for the SPEDAS heliocentric coordinate transforms.

pro test_spd_epv00
  compile_opt idl2

  ; Reference vector from ERFA t_erfa_c.c for JD(TT)=2453412.02501161.
  spd_epv00, 2400000.5d + 53411.52501161d, p, v, /JD_TT, status=status
  p_ref = [-0.7757238809297706813d, 0.5598052241363340596d, $
    0.2426998466481686993d]
  v_ref = [-0.1091891824147313846d-1, -0.1247187268440845008d-1, $
    -0.5407569418065039061d-2]
  if max(abs(p[0,*]-p_ref)) gt 5d-12 then message, 'EPV00 position test failed.'
  if max(abs(v[0,*]-v_ref)) gt 1d-12 then message, 'EPV00 velocity test failed.'
  if status[0] ne 0 then message, 'EPV00 status test failed.'

  ; Exercise the normal SPEDAS Unix-time path, including TT-UTC.
  utc = (2400000.5d + 53411.52501161d - 2440587.5d)*86400d - 64.184d
  spd_epv00, utc, p_utc, v_utc
  if max(abs(p_utc-p)) gt 1d-11 then message, 'EPV00 Unix time conversion failed.'

  print, 'test_spd_epv00: all tests passed.'
end
