; $LastChangedBy: ali $
; $LastChangedDate: 2021-05-31 14:03:08 -0700 (Mon, 31 May 2021) $
; $LastChangedRevision: 30016 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_l0_transfer_batch.pro $
; mvn_l0_transfer_batch: to be run from a cron job typically
message,'obsolete!! merged with mvn_sep_batch'
stop
!quiet = 1
dprint,print_trace=4,print_dtime=1,setdebug=2,dlevel=3
set_plot,'z'
@idl_startup
!quiet = 1

dummy = mvn_file_source(/set,verbose=1,dir_mode='775'o)

t0 = systime(1)
tplot_options,verbose=0

dprint,'Starting mvn_l0_transfer_batch at: '+time_string(systime(1),/local)+' host:'+getenv('HOST')+' user:'+getenv('USER')+' group:'+getenv('GROUP')
mvn_common_l0_file_transfer

t1=systime(1)
dprint,'Finished mvn_l0_transfer_batch at: '+time_string(systime(1),/local)+' in '+strtrim((t1-t0))+' seconds.'

exit
