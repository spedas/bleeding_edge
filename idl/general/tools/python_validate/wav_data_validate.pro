;+
;PROCEDURE: wav_data_validate
;
;PURPOSE:
;   Generate test data for Python vs IDL validation tests for the wav_data routine.
;
;
;   Creates the following savefiles:
;        wav_data_resample_test.tplot
;        sin_wav_wv_pol_perp.tplot
;        wav_data_cross_test.tplot
;        sin_wav_wv_pol_perp.tplot
;
;   These files should be uploaded into:
;     https://github.com/spedas/test_data/analysis_tools
;
;   The savefiles are used by pyspedas tests to confirm that IDL and python results are the same.
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2025-10-13 10:21:07 -0700 (Mon, 13 Oct 2025) $
; $LastChangedRevision: 33753 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/python_validate/wav_data_validate.pro $
;-


pro wav_data_resample_validate
  ; Create synthetic data with NaN values and time varying steps.
  ; This will trigger the resample portion of the wav_data procedure.
  ; Results will be saved in wav_data_resample_test.tplot

  compile_opt idl2

  thm_init
  del_data, '*'
  var = 'sin_wav'

  ; Create a tplot variable that contains a wave.
  t = findgen(4000)
  time = time_double('2010-01-01') + 10 * t
  data = sin(2 * !pi * t / 32.)
  data2 = sin(2 * !pi * t / 64.)
  data[1000 : 3000] = data2[1000 : 3000]
  varorig = var + '_orig'
  store_data, varorig, data = {x: time, y: data}


  ; Create gaps in the data
  data[1050 : 1060, *] = !values.f_nan

  for i=3050,3160, 5 do begin
    data[i] = !values.f_nan
  endfor

  ; Create a varying time step that will trigger the resampling
  for i = 0, 60 do begin
    if (i mod 2 eq 0) then begin
      time[2000 + i] = time[2000 + i] + 80
    endif
  endfor

  store_data, var, data = {x: time, y: data}

  wav_data, var
  wav_data, varorig

  varnames = tnames()
  print, varnames

  tplot_save, varnames, filename = 'idltestfiles/wav_data_resample_test'
  tplot, varnames
end

pro wav_data_2d_validate
  ; Create 2D synthetic data
  ; Results will be saved in wav_data_2d_test.tplot

  compile_opt idl2

  thm_init
  del_data, '*'
  var = 'sin_wav'

  t = findgen(4000)
  time = time_double('2010-01-01') + 10. * t

  base = sin(2. * !pi * t / 48.)
  quad = cos(2. * !pi * t / 64.)

  data = fltarr(n_elements(t), 2)
  data[*, 0] = base
  data[*, 1] = quad

  data[1200:2800, 0] = sin(2. * !pi * t[1200:2800] / 36.)
  data[1200:2800, 1] = cos(2. * !pi * t[1200:2800] / 80.)

  store_data, var, data = {x: time, y: data}

  wav_data, var, get_components=1

  varnames = tnames()
  print, varnames

  tplot_save, varnames, filename = 'idltestfiles/wav_data_2d_test'
  tplot, varnames


end

pro wav_data_crosscorr_validate
  ; Create 3D synthetic data and then apply the wav_data keywords cross1, cross2
  ; Results will be saved in wav_data_cross_test.tplot

  compile_opt idl2

  thm_init
  del_data, '*'
  var = 'sin_wav'

  t = findgen(4000)
  time = time_double('2010-01-01') + 10. * t

  base = sin(2. * !pi * t / 48.)
  quad = cos(2. * !pi * t / 48.)
  parallel = sin(2. * !pi * t / 64.)

  data = fltarr(n_elements(t), 3)
  data[*, 0] = base
  data[*, 1] = quad
  data[*, 2] = parallel

  data[1200:2800, 0] = sin(2. * !pi * t[1200:2800] / 36.)
  data[1200:2800, 1] = cos(2. * !pi * t[1200:2800] / 36.)
  data[1200:2800, 2] = sin(2. * !pi * t[1200:2800] / 80.)

  store_data, var, data = {x: time, y: data}

  wav_data, var, get_components=1, cross1=1, cross2=1

  varnames = tnames()
  print, varnames

  tplot_save, varnames, filename = 'idltestfiles/wav_data_cross_test'
  tplot, varnames[0:4]
  ;stop
  tplot, varnames[5:10]
  ;stop
  tplot, varnames[11:*]

end

pro wav_data_keywords2_validate
  ; Create 3D synthetic data and then apply various wav_data keywords
  ; Results will be saved in wav_data_key2_test.tplot

  compile_opt idl2

  thm_init
  del_data, '*'
  var = 'sin_wav'

  t = findgen(4000)
  time = time_double('2010-01-01') + 10. * t

  base = sin(2. * !pi * t / 48.)
  quad = cos(2. * !pi * t / 48.)
  parallel = sin(2. * !pi * t / 64.)

  data = fltarr(n_elements(t), 3)
  data[*, 0] = base
  data[*, 1] = quad
  data[*, 2] = parallel

  data[1200:2800, 0] = sin(2. * !pi * t[1200:2800] / 36.)
  data[1200:2800, 1] = cos(2. * !pi * t[1200:2800] / 36.)
  data[1200:2800, 2] = sin(2. * !pi * t[1200:2800] / 80.)

  store_data, var, data = {x: time, y: data}

  wav_data, var, magrat=1, normval=1, fraction=1, kolom=1, rotate_pow=1

  varnames = tnames()
  print, varnames

  tplot_save, varnames, filename = 'idltestfiles/wav_data_key2_test'
  tplot, varnames

end

pro wav_data_validate

  wav_data_resample_validate
  wav_data_2d_validate
  wav_data_crosscorr_validate
  wav_data_keywords2_validate

end