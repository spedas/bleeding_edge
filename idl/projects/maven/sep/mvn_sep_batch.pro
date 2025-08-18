; $LastChangedBy: ali $
; $LastChangedDate: 2023-10-21 18:50:42 -0700 (Sat, 21 Oct 2023) $
; $LastChangedRevision: 32205 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sep/mvn_sep_batch.pro $
; mvn_sep_batch: to be run from a cron job typically

!quiet=1
dprint,print_trace=4,print_dtime=1,setdebug=2,dlevel=3
set_plot,'z'
@idl_startup
!quiet=1
dummy=mvn_file_source(/set,verbose=1,dir_mode='775'o)
tplot_options,verbose=0

t0=systime(1)
dprint,'Starting mvn_common_l0_file_transfer at: '+time_string(t0,/local)+' host:'+getenv('HOST')+' user:'+getenv('USER')+' group:'+getenv('GROUP')
mvn_common_l0_file_transfer
t1=systime(1)
dprint,'Finished mvn_common_l0_file_transfer at: '+time_string(t1,/local)+' in '+strtrim((t1-t0))+' seconds.'

t0=systime(1)
dprint,'Starting mvn_sep_batch at: '+time_string(t0,/local)+' host:'+getenv('HOST')+' user:'+getenv('USER')+' group:'+getenv('GROUP')
timespan,c=120

mvn_mag_sts_to_sav,/init,coord='pl',level='l1'
mvn_mag_sts_to_sav,/init,coord='pl',level='l2'
mvn_mag_sts_to_sav,/init,coord='pc',level='l2'

mvn_save_reduce_timeres,/init,resstr='1sec', 'maven/data/sci/mag/l1/sav/$RES/YYYY/MM/mvn_mag_l1_pl_$RES_YYYYMMDD.sav'
mvn_save_reduce_timeres,/init,resstr='30sec','maven/data/sci/mag/l1/sav/$RES/YYYY/MM/mvn_mag_l1_pl_$RES_YYYYMMDD.sav'

mvn_save_reduce_timeres,/init,resstr='1sec', 'maven/data/sci/mag/l2/sav/$RES/YYYY/MM/mvn_mag_l2_pl_$RES_YYYYMMDD.sav'
mvn_save_reduce_timeres,/init,resstr='1sec', 'maven/data/sci/mag/l2/sav/$RES/YYYY/MM/mvn_mag_l2_pc_$RES_YYYYMMDD.sav'
mvn_save_reduce_timeres,/init,resstr='30sec','maven/data/sci/mag/l2/sav/$RES/YYYY/MM/mvn_mag_l2_pl_$RES_YYYYMMDD.sav'
;mvn_save_reduce_timeres,/init,resstr='30sec','maven/data/sci/mag/l2/sav/$RES/YYYY/MM/mvn_mag_l2_pc_$RES_YYYYMMDD.sav'

;mvn_sep_gen_plots,init=-10
mvn_sep_makefile;,/init
mvn_sep_save_reduce_timeres,resstr='32sec'
mvn_sep_save_reduce_timeres,resstr='5min'
mvn_sep_save_reduce_timeres,resstr='01hr'
generate_checksums,root_data_dir()+'maven/data/sci/sep/',dir_pattern='*.{sav,cdf}',file_pattern='*.???',/include_dir
;mvn_sta_tplot_restore,trange=[time_double('2014-9-30'),systime(1)],/create    ;  Since MOI
;mvn_sta_tplot_restore,trange=systime(1) + [-130,0] * 86400L ,/create            ; Last 30 days only
mvn_euv_l0_load,/gen;,/init
t1=systime(1)
dprint,'Finished mvn_sep_batch at: '+time_string(t1,/local)+' in '+strtrim((t1-t0))+' seconds.'

exit
