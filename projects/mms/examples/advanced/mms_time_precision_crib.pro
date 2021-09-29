;+
; 
; mms_time_precision_crib
; 
; 
; Due to usage of unix times in SPEDAS, times are limited to 
; microsecond level pricision; this crib sheet demonstrates 
; the issue and shows how to load in the full times with
; nanosecond level precision using LONG64s or Big Integers
; 
; 
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2019-04-29 15:12:32 -0700 (Mon, 29 Apr 2019) $
; $LastChangedRevision: 27140 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_time_precision_crib.pro $
;-

; Load the data in with unix times
mms_load_fgm, trange=['2015-10-16/13:06', '2015-10-16/13:07'], /time_clip, data_rate='brst'
get_data, 'mms1_fgm_b_gse_brst_l2', data=d

; the precision here should be +- 1 microsecond, since unix times are defined from Jan 1970 and stored as doubles
print, time_string(d.X[0], tformat='YYYY-MM-DD/hh:mm:ss.ffffff')
; 2015-10-16/13:06:00.005329

; to get nanosecond precision, load the data in with the original TT2000 timestamps using the /tt2000 keyword
mms_load_fgm, /tt2000, trange=['2015-10-16/13:06', '2015-10-16/13:07'], /time_clip, data_rate='brst'
get_data, 'mms1_fgm_b_gse_brst_l2', data=d

; note the type here is LONG64 - this is required to store such a large number with high precision
help, d.x[0]
; <Expression>    LONG64    =     498272793048243059
stop

; warning: most analysis routines in SPEDAS assume you're using unix times, so data loaded with the TT2000 
; keyword likely won't work in any SPEDAS/tplot routines. 

; if you decide to write analysis routines that use the full TT2000 timestamps, it's best to use
; the BigInteger datatype to avoid precision issues that can occur with calculations with LONG64 integers in IDL
help, BigInteger(d.x[0])

; the following example shows how to convert to a more recent time base without a loss of precision
new_base = BigInteger(d.x[0])

for time_idx=0, n_elements(d.x)-1 do append_array, big_times, BigInteger(d.X[time_idx])

for time_idx=0, n_elements(d.x)-1 do append_array, new_times, big_times[time_idx]-new_base

; new_times should have been converted while preserving the full precision
;MMS> new_times[0]
;0
;MMS> new_times[1]
;7812602
;MMS> new_times[2]
;15625205
;MMS> new_times[3]
;23437807

; now calculate the difference between timestamps, in nanoseconds
;MMS> 15625205-7812602
;     7812603
;MMS> 23437807-15625205
;     7812602
;
; note that both are +- 1 nanosecond of the first in the series, 7812602

; if you were to do the same calculations using unix times, you would get (updated to integers in nanoseconds for comparison):
;MMS> new_times[0]
;0
;MMS> new_times[1]
;7812738
;MMS> new_times[2]
;15625238
;MMS> new_times[3]
;23437976

; the precision issues can be seen by looking at the differences:
;MMS> 15625238-7812738
;7812500
;MMS> 23437976-15625238
;7812738
;

end