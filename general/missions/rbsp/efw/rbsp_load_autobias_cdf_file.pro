;Load Sheng's autobias  flag files at
;http://rbsp.space.umn.edu/kersten/data/rbsp/autobias_flag
;e.g. rbspa/2014/rbspa_efw_autobias_flag_20140101_v01.cdf

;These have the tplot variables:
;rbsp?_ab_flag                 (flag values at 1/min cadence)
;rbsp?_efw_hsk_idpu_fast_TBD   (actual autobias values at high cadence)


pro rbsp_load_autobias_cdf_file,sc

  rbsp_efw_init

;  sc = 'a'
;  datetime = '2014-01-01'
;  timespan,datetime

  tr = timerange()
  datetime = strmid(time_string(tr[0]),0,10)


  year = strmid(datetime,0,4)
  mn = strmid(datetime,5,2)
  dy = strmid(datetime,8,2)


  fn = 'rbsp'+sc+'_efw_autobias_flag_'+year+mn+dy+'_v01.cdf'


  if ~keyword_set(folder) then folder = !rbsp_efw.local_data_dir + $
                                       'rbsp' + strlowcase(sc[0]) + path_sep() + $
                                       'autobias_flags' + path_sep() + $
                                       year + path_sep()


  ;url = 'http://rbsp.space.umn.edu/kersten/data/rbsp/autobias_flag/'
  url = 'http://rbsp.space.umn.edu/rbsp_efw/autobias_flag/'
  path = 'rbsp'+sc+'/'+year+'/'+fn


  file_loaded = spd_download(remote_file=url+path,$
                local_path=folder,$
                /last_version)

  cdf2tplot,file_loaded


end
