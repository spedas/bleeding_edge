; $LastChangedBy: ali $
; $LastChangedDate: 2021-05-31 14:03:08 -0700 (Mon, 31 May 2021) $
; $LastChangedRevision: 30016 $
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
;mvn_mag_gen_l1_sav,init=1 ;looks like muser@mojo has a cronjob that does this too, so commenting it out ;20190814 Ali
mvn_save_reduce_timeres,/mag,resstr='1sec'
mvn_save_reduce_timeres,/mag,resstr='30sec'
;mvn_sep_gen_plots,init=-10
mvn_sep_makefile;,/init
mvn_sep_save_reduce_timeres;,/init
generate_checksums,root_data_dir()+'maven/data/sci/sep/',dir_pattern='*.{sav,cdf}',file_pattern='*.???',/include_dir
;mvn_sta_tplot_restore,trange=[time_double('2014-9-30'),systime(1)],/create    ;  Since MOI
;mvn_sta_tplot_restore,trange=systime(1) + [-130,0] * 86400L ,/create            ; Last 30 days only
mvn_euv_l0_load,/gen;,/init
t1=systime(1)
dprint,'Finished mvn_sep_batch at: '+time_string(t1,/local)+' in '+strtrim((t1-t0))+' seconds.'

exit
