;Read in the burst 1 list and create an IDL save file with the
;results.

;Burst 1 list for each sc comes from create_rbsp_burst_times_rates_list.pro
;To get data from this list use rbsp_get_burst_times_rates_list.pro


pro create_burst1_times_rates_idl_save_file,sc

  path = '/Users/aaronbreneman/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/calibration_files/'
  fn = 'burst1_times_rates_RBSP'+sc+'.txt'

  openr,lun,path+fn,/get_lun
  jnk = ''
  readf,lun,jnk

  d0 = ''
  d1 = ''
  duration = 0.
  sr = 0.

  dat = ''
  while not eof(lun) do begin
    readf,lun,dat
    vals = strsplit(dat,' ',/extract)
    d0 = [d0,vals[0]]
    d1 = [d1,vals[2]]
    duration = [duration,float(vals[3])]
    sr = [sr,float(vals[4])]

  endwhile

  close,lun & free_lun,lun

  n = n_elements(d0)
  d0 = d0[1:n-1]
  d1 = d1[1:n-1]
  duration = duration[1:n-1]
  sr = sr[1:n-1]

;  vals = {t0:d0,t1:d1,duration:duration,samplerate:sr}
;  for i=0,50 do print,vals.t0[i],vals.t1[i],vals.duration[i],vals.samplerate[i]

  save,d0,d1,duration,sr,filename=path+'burst1_times_rates_RBSP'+sc+'.sav'

end
