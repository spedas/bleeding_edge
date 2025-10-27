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
;        wavelet98_paul_dog_test.tplot
;
;   These files should be uploaded into:
;     https://github.com/spedas/test_data/analysis_tools
;
;   The savefiles are used by pyspedas tests to confirm that IDL and python results are the same.
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2025-10-22 20:15:05 -0700 (Wed, 22 Oct 2025) $
; $LastChangedRevision: 33789 $
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

pro wavelet98_paul_dog_validate
  ; to be used for python wavelet98.py validation, using wavelet.pro with paul and dog wavelets

  thm_init
  del_data, '*'

  ; Create a tplot variable that contains a wave.
  t =  FINDGEN(4000)
  time = time_double('2010-01-01') + 10*t
  data = sin(2*!pi*t/32.)
  data2 = sin(2*!pi*t/64.)
  data[1000:3000] = data2[1000:3000]
  var = 'sin_wav'
  store_data, var, data={x:time, y:data}

  dt = average(time[1:*] - time[0:n_elements(time)-1])

  ; Paul wavelet
  wave_out_paul = wavelet(data, dt, period=period_paul, mother='paul')
  help, wave_out_paul

  wvar1 = 'wav_paul'
  store_data, wvar1, data={x:time, y:wave_out_paul, v:period_paul}

  pvar1 = 'pow_paul'
  pow_paul = abs(wave_out_paul)^2
  dl = {spec:1,ylog:1,ystyle:1}
  store_data, pvar1, data={x:time, y:pow_paul, v:period_paul}, dl=dl

  ; Dog wavelet
  wave_out_dog = wavelet(data, dt, period=period_dog, mother='dog')
  help, wave_out_dog

  wvar2 = 'wav_dog
  store_data, wvar2, data={x:time, y:wave_out_dog, v:period_dog}

  pvar2 = 'pow_dog'
  pow_dog = abs(wave_out_dog)^2
  dl = {spec:1,ylog:1,ystyle:1}
  store_data, pvar2, data={x:time, y:pow_dog, v:period_dog}, dl=dl

  varnames = [var, wvar1, pvar1, wvar2, pvar2]
  tplot_save, varnames, filename = 'idltestfiles/wavelet98_paul_dog_test'
  tplot, varnames

end

pro wav_data_validate

  wav_data_resample_validate
  wav_data_2d_validate
  wav_data_crosscorr_validate
  wav_data_keywords2_validate
  wavelet98_paul_dog_validate

end