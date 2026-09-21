;+
; NAME: tinterpol_mxn_validate
; PURPOSE:
;   Generate synthetic inputs and IDL reference outputs for the Python
;   time_interpolate and interpolate_rotation validation suites.
;   No mission data or network access is needed.
;
; CALLING SEQUENCE:
;   tinterpol_mxn_validate
;   tinterpol_mxn_validate, filename='/path/to/tinterpol_mxn_validate.cdf'
;
; NOTES:
;   Companions: pyspedas/utilities/tests/test_tinterpol_mxn.py
;               pyspedas/utilities/tests/test_interpolate_rotation.py
;   All mxn_idl_*, mxn_methods_*, and rot_idl_* variables are reserved for this generator. Only those variables
;   are exported. Times include exact half-seconds and use TT2000 in the CDF.
;   Re-running replaces the single fixture, retaining the linear cases and adding
;   quadratic, spline, nearest-neighbor, repeat-previous, and rotation cases.
;   Python uses PYSPEDAS_TINTERPOL_MXN_CDF for a local override; otherwise it
;   downloads interpolation_tests/tinterpol_mxn_validate.cdf from spedas/test_data.
;   Publish the regenerated CDF there when the new cases are ready for CI.
;   Previous has no tinterpol_mxn keyword; its reference uses VALUE_LOCATE.
;
;   The preserve-NaNs case records IDL's actual output, including the NaN at an
;   exact valid input sample adjacent to a NaN. Python deliberately preserves
;   that valid sample; the corresponding test checks this difference explicitly.
;-
pro tinterpol_mxn_validate, filename=filename
  compile_opt idl2
  if ~keyword_set(filename) then $
    filename='/Users/jwl/spdsoft_trunk/general/tools/python_validate/tinterpol_mxn_validate.cdf'

  start_time = time_double('2020-01-01')
  source = {x:start_time+[0d,2d,5d], y:[0d,4d,10d]}
  target = start_time+[-1d,0d,1d,5d,6d]
  store_data, 'mxn_idl_source', data=source
  store_data, 'mxn_idl_target', data={x:target,y:dblarr(n_elements(target))}

  tinterpol_mxn, 'mxn_idl_source', 'mxn_idl_target', newname='mxn_idl_linear'
  tinterpol_mxn, 'mxn_idl_source', 'mxn_idl_target', newname='mxn_idl_nan', /nan_extrapolate
  tinterpol_mxn, 'mxn_idl_source', 'mxn_idl_target', newname='mxn_idl_repeat', /repeat_extrapolate
  tinterpol_mxn, 'mxn_idl_source', 'mxn_idl_target', newname='mxn_idl_trim', /no_extrapolate

  source_nan = {x:start_time+[0d,1d,2d,3d], $
    y:[[0d,!values.d_nan,2d,3d],[!values.d_nan,2d,4d,!values.d_nan]]}
  target_nan = start_time+[0d,0.5d,1d,2.5d,3d]
  store_data, 'mxn_idl_source_nan', data=source_nan
  store_data, 'mxn_idl_target_nan', data={x:target_nan,y:dblarr(n_elements(target_nan))}
  tinterpol_mxn, source_nan, target_nan, out=ignore_result, /ignore_nans
  store_data, 'mxn_idl_ignore', data=ignore_result
  tinterpol_mxn, source_nan, target_nan, out=preserve_result
  store_data, 'mxn_idl_preserve', data=preserve_result

  ; Non-symmetric 3x3 matrices expose swapped component axes in the CDF round trip.
  matrices = dblarr(3,3,3)
  for i=0,2 do for j=0,2 do matrices[*,i,j] = source.y + 10d*i + 100d*j
  store_data, 'mxn_idl_matrix_source', data={x:source.x,y:matrices}
  tinterpol_mxn, 'mxn_idl_matrix_source', 'mxn_idl_target', newname='mxn_idl_matrix_linear'
  tinterpol_mxn, 'mxn_idl_matrix_source', 'mxn_idl_target', newname='mxn_idl_matrix_nan', /nan_extrapolate

  ; Time-independent bins and time-dependent bins are both exported.
  spectral_values = [[0d,4d,10d],[10d,14d,20d]]
  static_bins = [10d,20d]
  moving_bins = [[10d,12d,15d],[20d,22d,25d]]
  store_data, 'mxn_idl_static_source', data={x:source.x,y:spectral_values,v:static_bins}
  store_data, 'mxn_idl_moving_source', data={x:source.x,y:spectral_values,v:moving_bins}
  tinterpol_mxn, 'mxn_idl_static_source', 'mxn_idl_target', newname='mxn_idl_static'
  tinterpol_mxn, 'mxn_idl_moving_source', 'mxn_idl_target', newname='mxn_idl_moving'
  tinterpol_mxn, 'mxn_idl_moving_source', 'mxn_idl_target', newname='mxn_idl_moving_nan', /nan_extrapolate

  store_data, 'mxn_idl_single_source', data={x:[start_time+1d],y:reform([3d,4d],1,2)}
  tinterpol_mxn, 'mxn_idl_single_source', 'mxn_idl_target', newname='mxn_idl_single'
  tinterpol_mxn, 'mxn_idl_single_source', 'mxn_idl_target', newname='mxn_idl_single_nan', /nan_extrapolate

  ; Additional interpolation methods.
  del_data,'mxn_methods_*'
  t0=time_double('2020-01-01')
  x=t0+[0d,1d,3d,6d,10d,15d]
  y=[0d,2d,-1d,4d,3d,9d]
  u=t0+[-2d,0d,.5d,1d,2d,3d,4.5d,6d,8d,10d,12.5d,15d,17d]
  store_data,'mxn_methods_source',data={x:x,y:y}
  store_data,'mxn_methods_target',data={x:u,y:dblarr(n_elements(u))}
  tinterpol_mxn,'mxn_methods_source','mxn_methods_target',/quadratic,newname='mxn_methods_quadratic'
  tinterpol_mxn,'mxn_methods_source','mxn_methods_target',/spline,newname='mxn_methods_spline'
  tinterpol_mxn,'mxn_methods_source','mxn_methods_target',/nearest_neighbor,newname='mxn_methods_nearest'
  indices=(value_locate(x,u)>0)<(n_elements(x)-1)
  store_data,'mxn_methods_previous',data={x:u,y:y[indices]}

  yn=y
  yn[2]=!values.d_nan
  store_data,'mxn_methods_nan_source',data={x:x,y:yn}
  tinterpol_mxn,'mxn_methods_nan_source','mxn_methods_target',/quadratic,/ignore_nans,newname='mxn_methods_quadratic_ignore'
  tinterpol_mxn,'mxn_methods_nan_source','mxn_methods_target',/spline,/ignore_nans,newname='mxn_methods_spline_ignore'
  ; Targets strictly between samples avoid the intentional exact-sample NaN difference.
  un=t0+[.5d,2d,4.5d,8d,12.5d]
  store_data,'mxn_methods_nan_target',data={x:un,y:dblarr(n_elements(un))}
  tinterpol_mxn,'mxn_methods_nan_source','mxn_methods_nan_target',/quadratic,newname='mxn_methods_quadratic_nan'
  tinterpol_mxn,'mxn_methods_nan_source','mxn_methods_nan_target',/spline,newname='mxn_methods_spline_nan'

  matrix=dblarr(6,3,3)
  for i=0,2 do for j=0,2 do matrix[*,i,j]=(1d+i)*y+10d*j
  store_data,'mxn_methods_matrix_source',data={x:x,y:matrix}
  tinterpol_mxn,'mxn_methods_matrix_source','mxn_methods_target',/quadratic,newname='mxn_methods_matrix_quadratic'
  tinterpol_mxn,'mxn_methods_matrix_source','mxn_methods_target',/spline,newname='mxn_methods_matrix_spline'

  tvars = ['mxn_idl_source', 'mxn_idl_target', 'mxn_idl_linear', 'mxn_idl_nan', $
    'mxn_idl_repeat', 'mxn_idl_trim', 'mxn_idl_source_nan', 'mxn_idl_target_nan', $
    'mxn_idl_ignore', 'mxn_idl_preserve', 'mxn_idl_matrix_source', $
    'mxn_idl_matrix_linear', 'mxn_idl_matrix_nan', 'mxn_idl_static_source', $
    'mxn_idl_moving_source', 'mxn_idl_static', 'mxn_idl_moving', 'mxn_idl_moving_nan', $
    'mxn_idl_single_source', 'mxn_idl_single', 'mxn_idl_single_nan']
  tvars = [tvars, tnames('mxn_methods_*')]
  ; Rotation interpolation is validated through tvector_rotate on each unit axis.
  ; This tests the entire matrix transformation, including left-handed bases.
  matrix_array_lib
  del_data, 'rot_idl_*'
  rt = start_time + [0d,2d,6d]
  ru = start_time + [-1d,0d,.5d,1d,2d,4d,6d,8d]
  rq = [[1d,.5d,0d],[0d,.5d,1d],[0d,.5d,0d],[0d,.5d,0d]]
  rm = qtom(rq)
  store_data, 'rot_idl_matrix', data={x:rt,y:rm}
  store_data, 'rot_idl_quaternion', data={x:rt,y:rq}
  store_data, 'rot_idl_left', data={x:rt,y:ctv_swap_hands(rm)}
  store_data, 'rot_idl_single', data={x:[rt[1]],y:rm[1:1,*,*]}
  ; IDL qslerp's singleton path fails at the exact source timestamp. Use the
  ; direct matched-grid tvector_rotate path for the constant-matrix reference,
  ; matching Python tvector_rotate's explicit singleton handling.
  constant_m = dblarr(n_elements(ru),3,3)
  for i=0,n_elements(ru)-1 do constant_m[i,*,*]=rm[1,*,*]
  store_data, 'rot_idl_constant', data={x:ru,y:constant_m}
  for axis=0,2 do begin
    basis = dblarr(n_elements(ru),3)
    basis[*,axis]=1d
    axis_name=strtrim(axis,2)
    store_data, 'rot_idl_basis'+axis_name, data={x:ru,y:basis}
    tvector_rotate, 'rot_idl_matrix', 'rot_idl_basis'+axis_name, newname='rot_idl_right'+axis_name
    tvector_rotate, 'rot_idl_left', 'rot_idl_basis'+axis_name, newname='rot_idl_left'+axis_name
    tvector_rotate, 'rot_idl_constant', 'rot_idl_basis'+axis_name, newname='rot_idl_single'+axis_name
  endfor
  tvars = [tvars, tnames('rot_idl_*')]

  tplot2cdf, filename=filename, tvars=tvars, /default_cdf_structure, /tt2000
  print, 'Generated ', filename, ' using IDL ', !version.release
end
