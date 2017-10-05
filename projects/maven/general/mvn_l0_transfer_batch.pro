;   mvn_sep_batch  - to be run from a cron job typically
!quiet = 1
dprint,print_trace=4,print_dtime=1,setdebug=2,dlevel=3
set_plot,'z'
@idl_startup
!quiet = 1

dummy = mvn_file_source(/set,verbose=1,dir_mode='775'o)

t0 = systime(1)
tplot_options,verbose=0

dprint,'Starting file transfer job at: '+time_string(systime(1),/local)
mvn_common_l0_file_transfer

exit

