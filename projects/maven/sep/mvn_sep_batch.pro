;   mvn_sep_batch  - to be run from a cron job typically
!quiet = 1
dprint,print_trace=4,print_dtime=1,setdebug=2,dlevel=3
set_plot,'z'
@idl_startup
!quiet = 1

dummy = mvn_file_source(/set,verbose=1,dir_mode='775'o)

t0 = systime(1)
tplot_options,verbose=0

;dprint,'Starting file transfer job at: '+time_string(systime(1),/local)
;mvn_common_l0_file_transfer

dprint,'Starting SEP batch job at: '+time_string(systime(1),/local)+' host:'+getenv('HOST')+' user:'+getenv('USER')+' group:'+getenv('GROUP')

;mvn_mag_gen_l1_sav,init=1 ;looks like muser@mojo has a cronjob that does this too, so commenting it out ;20190814 Ali
mvn_save_reduce_timeres,init=1,/mag,resstr='1sec',verbose=1
mvn_save_reduce_timeres,init=1,/mag,resstr='30sec',verbose=1

;mvn_sep_gen_plots,init=-10
timespan,[time_double('2014-3-18'),systime(1)]
mvn_sep_makefile,/init
mvn_sep_save_reduce_timeres,init=-1

generate_checksums,root_data_dir()+'maven/data/sci/sep/',dir_pattern='*.{sav,cdf}',file_pattern='*.???',/include_dir

;mvn_sta_tplot_restore,trange=[time_double('2014-9-30'),systime(1)],/create    ;  Since MOI
;mvn_sta_tplot_restore,trange=systime(1) + [-130,0] * 86400L ,/create            ; Last 30 days only
mvn_euv_l0_load,/gen

t1=systime(1)
dprint,'Finished SEP batch job at: '+time_string(systime(1),/local), ' in ',(t1-t0), ' seconds.'

exit

