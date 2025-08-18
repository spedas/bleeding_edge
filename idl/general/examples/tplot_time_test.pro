Pro tplot_time_test

  dt100 = tplot_noise_vars(nvar = 100)
  dt = fltarr(10)
  for j = 0, 9 do begin 
     del_data, '*' & dt[j] = tplot_noise_vars(nvar = 100)
  endfor
  dt1 = fltarr(10)
  del_data, '*'
  for j = 0, 9 do dt1[j] = tplot_noise_vars(nvar = 100)

  help, /memory

  del_data, '*'
  dt100 = tplot_noise_vars(nvar = 100)
  get_data, 'test_var_000002', data = d, dlimit = dl
  t0 = systime(/sec) & for j = 0, 100 do store_data, 'test_var_000002', data = d, dlimit = dl, limits = {units:'Not really counts'} & dt_store_100 = systime(/sec)-t0
  get_data, 'test_var_000002', data = d, dlimit = dl, limits = al
  help, al, /str                ;will show units Not really counts
;But not options:
  t0 = systime(/sec) & for j = 0, 100 do options, 'test_var_000092', 'units', 'Really counts, no kidding' & dt_options_100 = systime(/sec)-t0
  get_data, 'test_var_000092', data = d, dlimit = dl, limits = al
  help, al, /str                ;will show units Really counts, no kididng
  t0 = systime(/sec) & for j = 0, 100 do tplot, 'test_var_00009*' & dt_tplot_100 = systime(/sec)-t0

;store data takes forever with so many variables
  del_data,'*'
  dt1000 = tplot_noise_vars(nvar = 1000)
  get_data, 'test_var_000002', data = d, dlimit = dl
  t0 = systime(/sec) & for j = 0, 100 do store_data, 'test_var_000002', data = d, dlimit = dl, limits = {units:'Not really counts'} & dt_store_1000 = systime(/sec)-t0
  get_data, 'test_var_000002', data = d, dlimit = dl, limits = al
  help, al, /str                ;will show units Not really counts
;But not options:
  t0 = systime(/sec) & for j = 0, 100 do options, 'test_var_000092', 'units', 'Really counts, no kidding' & dt_options_1000 = systime(/sec)-t0
  get_data, 'test_var_000092', data = d, dlimit = dl, limits = al
  help, al, /str                ;will show units Really counts, no kididng
  t0 = systime(/sec) & for j = 0, 100 do tplot, 'test_var_00009*' & dt_tplot_1000 = systime(/sec)-t0


  notes = ['dt100 = time to create 100 tplot vars, starting from 0: '+string(format='(f9.3)', dt100)+' seconds', $
           'dt1000 = time to create 1000 tplot vars, starting from 0: '+string(format='(f9.3)', dt1000)+' seconds', $
           'dt = array(10), time in seconds to create 10 sets of 100 tplot vars, starting from 0 for each set'+strjoin(string(format='(f9.3)', dt),','), $
           'dt1 = array(10), time in seconds to create 10 sets of 100 tplot vars, not resetting to 0 for each set'+strjoin(string(format='(f9.3)', dt1),','), $
           'dt_store_100 = time to add limits using store_data 100 times, after 100 variables: '+string(format='(f9.3)', dt_store_100), $
           'dt_options_100 = time to add limits using options 100 times, after 100 variables: '+string(format='(f9.3)', dt_options_100), $
           'dt_tplot_100 = time to tplot 10 vars 100 times, after 100 variables: '+string(format='(f9.3)', dt_tplot_100), $
           'dt_store_1000 = time to add limits using store_data 100 times, after 1000 variables: '+string(format='(f9.3)', dt_store_1000), $
           'dt_options_1000 = time to add limits using options 100 times, after 1000 variables: '+string(format='(f9.3)', dt_options_1000), $
           'dt_tplot_1000 = time to tplot 10 vars 100 times, after 1000 variables: '+string(format='(f9.3)', dt_tplot_1000)]
         
  save, notes, dt100, dt1000, dt, dt1, dt_store_1000, dt_options_1000, dt_store_100, dt_options_100, $
        dt_tplot_1000, dt_tplot_100, file = 'tplot_time_test.sav'

  for j = 0, n_elements(notes)-1 Do print, notes[j]


  help, /memory
  del_data, '*'

End
