;  mvn_l0_transfer_batch: to be run from a cron job typically
!quiet = 1
dprint,print_trace=4,print_dtime=1,setdebug=2,dlevel=3
set_plot,'z'
@idl_startup
!quiet = 1

dummy = mvn_file_source(/set,verbose=1,dir_mode='775'o)

t0 = systime(1)
tplot_options,verbose=0

dprint,'Starting file transfer job at: '+time_string(systime(1),/local)+' host:'+getenv('HOST')+' user:'+getenv('USER')+' group:'+getenv('GROUP')
mvn_common_l0_file_transfer

t1=systime(1)
dprint,'Finished file transfer job at: '+time_string(systime(1),/local), ' in ',(t1-t0), ' seconds.'

exit

