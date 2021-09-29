
;Load Efield model cdf files at

;http://rbsp.space.umn.edu/rbsp_efw/e_model/rbspa/2014/
;e.g. rbspa_e_model_2014_0101_v01.cdf


;These have the tplot variables:
;   1 rbspa_vcoro_mgse     --> corotational velocity
;   2 rbspa_evxb_mgse   --> motional E-field (v x B)
;   3 rbspa_ecoro_mgse  --> corotation E-field  (-vcoro x B)
;   4 rbspa_emod_mgse    --> ecoro + evxb


;These CDF files were created by Sheng Tian, 2020.


pro rbsp_load_emodel_cdf_file,sc;,testing=testing


;    sc = 'a'
 ;   testing = 1
  ;  date = '2013-07-15'
   ; timespan,date
  rbsp_efw_init

  tr = timerange()
  datetime = strmid(time_string(tr[0]),0,10)


  year = strmid(datetime,0,4)
  mn = strmid(datetime,5,2)
  dy = strmid(datetime,8,2)


  fn = 'rbsp'+sc+'_e_model_'+year+'_'+mn+dy+'_v01.cdf'

  if ~keyword_set(folder) then folder = !rbsp_efw.local_data_dir + $
                                       'rbsp' + strlowcase(sc[0]) + path_sep() + $
                                       'e_model' + path_sep() + $
                                       year + path_sep()


    
  url = 'http://rbsp.space.umn.edu/rbsp_efw/e_model/'
  ;url = 'http://rbsp.space.umn.edu/rbsp_efw/test_perigee_correction/'
  path = 'rbsp'+sc+'/'+year+'/'+fn


  file_loaded = spd_download(remote_file=url+path,$
                local_path=folder,$
                /last_version)

  cdf2tplot,file_loaded

;  if ~KEYWORD_SET(testing) then $
 ;   cdf2tplot,file_loaded else $
  ;  tplot_restore,filename='~/Desktop/rbspa_test_perigee_correction_2013_0715_v01.tplot'



end
