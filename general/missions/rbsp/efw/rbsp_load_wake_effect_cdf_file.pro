;Load Sheng's wake effect flag files at
;http://rbsp.space.umn.edu/rbsp_efw/data/rbsp/wake_effect_flag
;e.g. rbspa/2014/rbspa_efw_wake_effect_flag_and_euv_2014_0101_v01.cdf

;These have the tplot variables:
;1 rbspa_eu_wake_flag
;2 rbspa_eu_fixed
;3 rbspa_ev_wake_flag
;4 rbspa_ev_fixed
;5 rbspa_ew
;where "fixed" are the waveforms (@16 Samples/sec) with the wake signal removed.

;These files are created with
;rbsp_load_efw_waveform, probe=probe, datatype='esvy', type='cal', coord='uvw', /noclean, trange=the_time_range


pro rbsp_load_wake_effect_cdf_file,sc

  rbsp_efw_init

;  sc = 'a'
;  datetime = '2014-01-01'
;  timespan,datetime

  tr = timerange()
  datetime = strmid(time_string(tr[0]),0,10)


  year = strmid(datetime,0,4)
  mn = strmid(datetime,5,2)
  dy = strmid(datetime,8,2)


  fn = 'rbsp'+sc+'_efw_wake_effect_flag_and_euv_'+year+'_'+mn+dy+'_v01.cdf'


  if ~keyword_set(folder) then folder = !rbsp_efw.local_data_dir + $
                                       'rbsp' + strlowcase(sc[0]) + path_sep() + $
                                       'wake_flags' + path_sep() + $
                                       year + path_sep()



  ;url = 'http://rbsp.space.umn.edu/kersten/data/rbsp/wake_effect_flag/'
  url = 'http://rbsp.space.umn.edu/rbsp_efw/wake_effect_flag/'
  path = 'rbsp'+sc+'/'+year+'/'+fn


  file_loaded = spd_download(remote_file=url+path,$
                local_path=folder,$
                /last_version)



  cdf2tplot,file_loaded


end
