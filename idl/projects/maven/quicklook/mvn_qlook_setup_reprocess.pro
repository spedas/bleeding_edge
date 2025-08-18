; setup to reprocess pfpl2_long plots, from mission start to 2019-12-01
nproc = 1
time_range = dblarr(2, nproc)
;time_range[*, 0] = time_double(['2014-10-27', '2019-12-01'])
;file_copy, '/home/muser/export_socware/idl_socware/projects/maven/quicklook/mvn_qlook_1day.pro', '/mydisks/home/maven/mvn_qlook_1day.pro', /overwrite
;mvn_l2gen_multiprocess_a, 'mvn_qlook_1day', nproc, 0, time_range, '/mydisks/home/maven/'
;file_copy, '/home/muser/export_socware/idl_socware/projects/maven/quicklook/mvn_pfpl2_long_1day.pro', '/mydisks/home/maven/mvn_pfpl2_long_1day.pro', /overwrite
;mvn_l2gen_multiprocess_a, 'mvn_pfpl2_long_1day', nproc, 0,
;time_range, '/mydisks/home/maven/'

file_copy, '/home/muser/export_socware/idl_socware/projects/maven/quicklook/mvn_spaceweather_1day.pro', '/mydisks/home/maven/mvn_spaceweather_1day.pro', /overwrite
mvn_l2gen_multiprocess_a, 'mvn_spaceweather_1day', nproc, 0, time_range, '/mydisks/home/maven/'

End

