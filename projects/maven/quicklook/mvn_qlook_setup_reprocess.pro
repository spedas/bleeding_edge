nproc = 1
time_range = dblarr(2, nproc)
time_range[*, 0] = time_double(['2014-09-22', '2015-03-21'])
file_copy, '/home/muser/export_socware/idl_socware/projects/maven/quicklook/mvn_qlook_1day.pro', '/mydisks/home/maven/mvn_qlook_1day.pro', /overwrite
mvn_l2gen_multiprocess_a, 'mvn_qlook_1day', nproc, 0, time_range, '/mydisks/home/maven/'

End

