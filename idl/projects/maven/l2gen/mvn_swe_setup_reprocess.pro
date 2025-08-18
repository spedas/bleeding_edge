nproc = 1
time_range = dblarr(2, nproc)
time_range[*, 0] = time_double(['2014-10-11', '2015-02-01'])
file_copy, '/home/jimm/themis_sw/projects/maven/l2gen/mvn_swe_l2gen_1day.pro', '/mydisks/home/maven/mvn_swe_l2gen_1day.pro', /overwrite
mvn_l2gen_multiprocess_a, 'mvn_swe_l2gen_1day', nproc, 0, time_range, '/mydisks/home/maven/'

End

