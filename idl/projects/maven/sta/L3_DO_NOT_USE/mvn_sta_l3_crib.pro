;+
;Crib for running STATIC L3 density code, to generate tplot save files
;
;
;
;-
;

;Compile any new routines that are not yet on SVN:
;.r /Users/cmfowler/IDL/STATIC_routines/Processing_software/mvn_sta_functions_l3/mvn_sta_get_c6_co2.pro  ;This will be committed at some point

date = '2017-10-18'  ;pick a date

;trange=time_double(['2017-03-28/05:10:00', '2017-03-28/05:45:00'])

;tmpdir = '/Users/cmfowler/TEMP/density/'
tmpdir='/Users/Gwen/Desktop/maven/data/l3_cdf_test/'

mvn_sta_l3_top, date, trange=trange, /den, /temp, tmpdir=tmpdir, /indspice, version='03'

;Code is currently running with the old version of CO2 (V03). When finished, replace with new code, and then run with V04

;Create science file:
fileout = '/Users/Gwen/Desktop/maven/data/l3_cdf_test/density/2017/10/mvn_sta_l3_den_20171018_full_v03.tplot'
mvn_sta_l3_generate_science_files, dfile_version='03', testfile=fileout

fileout =  '/Users/Gwen/Desktop/maven/data/l3_cdf_test/temperature/2017/10/mvn_sta_l3_temp_20171018_full_v03.tplot'
mvn_sta_l3_generate_science_files, tfile_version='03', testfile=fileout
