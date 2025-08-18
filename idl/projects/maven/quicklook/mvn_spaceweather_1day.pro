;+
;NAME:
;mvn_spaceweather_1day
;PURPOSE:
;reads in a start and end date, and reprocesses all of the days in
;the interval. This is a main program, designed to be called from a
;shell script. Processes 1 day at a time
;CALLING SEQUENCE:
; .run mvn_spaceweather_1day
;INPUT:
;start_time, end_time are input from files
;mvn_spaceweather_1day_start_time.txt and
;mvn_spaceweather_1day_end_time.txt.
;OUTPUT:
;PLots, spaceweather 1,3 and 7-day
;HISTORY:
; 2023-10-11, jmm, jimm@ssl.berkeley.edu
;-
this_file = 'mvn_spaceweather_1day'
spawn, 'touch '+this_file+'_lock'
;Apparently you cannot compile code in the way we're calling this, so
st_file = this_file+'_start_time.txt'
st_time = strarr(1)
openr, unit, st_file, /get_lun
readf, unit, st_time
free_lun, unit
tstart = time_double(st_time[0])
timespan, tstart, 1;Needed for cron job
en_file = this_file+'_end_time.txt'
en_time = strarr(1)
;process days
openr, unit, en_file, /get_lun
readf, unit, en_time
free_lun, unit
tend = time_double(en_time[0])
If(tstart Ge tend) Then exit
;do the process one day at a time, in the local working directory
mvn_call_spaceweatherplot, days_in = time_string(tstart, precision = -3), instr = 'spaceweather', /no_proc_mail
;Add a day and reset start time file
tstart_new = tstart+86400.0d0
openw, unit, this_file+'_start_time.txt', /get_lun
printf, unit, time_string(tstart_new)
free_lun, unit
;All done
spawn, '/bin/rm '+this_file+'_lock'
exit

