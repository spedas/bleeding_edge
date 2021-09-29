;+ call this file to set up reprocess, this will split up the input
;time range equally. Run as muser
;sample crontab command
;# STA L2 Reprocess, 2015-08-31
;# 4,8,14,18,24,28,34,38,44,48,54,58 * * * * /bin/csh
;/home/muser/export_socware/idl_socware/projects/maven/l2gen/mvn_l2gen_multiprocess_b.csh
;mvn_sta_l2gen_1day 2 0 /mydisks/home/maven sta_l2_reprocess
;>/dev/null 2>&1
;# for l2l2
;# 4,8,14,18,24,28,34,38,44,48,54,58 * * * * /bin/csh /home/muser/export_socware/idl_socware/projects/maven/l2gen/mvn_l2gen_multiprocess_b.csh mvn_sta_l2l2_1day 2 0 /mydisks/home/maven sta_l2l2_reprocess >/dev/null 2>&1
;#

Pro mvn_sta_setup_iv1process, start_date = start_date, $ ;default is 2014-10-06
                              end_date = end_date, $     ;default is now
                              nproc = nproc             ;default is 3
;-
  if(~keyword_set(nproc)) Then nproc = 3
  If(keyword_set(start_date)) Then Begin
     st = time_string(start_date, precision = -3)
  Endif Else st = '2014-10-06'
  If(keyword_set(end_date)) Then Begin
     en = time_string(end_date, precision = -3)
  Endif Else en = time_string(systime(/sec), precision = -3)

  one_day = 86400.0d0
  t0 = time_double(st) & t1 = time_double(en)
  ndays = (t1-t0)/one_day
  ndnp = round(ndays/nproc)
  tall = t0+ndnp*one_day*indgen(nproc+1)
  tall[nproc] = tall[nproc] < t1
  time_range = dblarr(2, nproc)
  time_range[0, *] = tall[0:nproc-1]
  time_range[1, *] = tall[1:nproc]
  time_range = time_string(time_range, precision = -3)

;run as jimm?
  If(getenv('USER') Eq 'jimm') Then Begin
     file_copy, '/home/jimm/themis_sw/projects/maven/sta/l2util/mvn_sta_iv1_1day.pro', '/mydisks/home/maven/jimm/mvn_sta_iv1_1day.pro', /overwrite
     mvn_l2gen_multiprocess_a, 'mvn_sta_iv1_1day', nproc, 0, time_range, '/mydisks/home/maven/jimm/'
  Endif Else Begin
     file_copy, '/home/muser/export_socware/idl_socware/projects/maven/sta/l2util/mvn_sta_iv1_1day.pro', '/mydisks/home/maven/mvn_sta_iv1_1day.pro', /overwrite
     mvn_l2gen_multiprocess_a, 'mvn_sta_iv1_1day', nproc, 0, time_range, '/mydisks/home/maven/'
  Endelse
End

