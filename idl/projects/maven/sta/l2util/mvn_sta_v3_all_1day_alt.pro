;+
;NAME:
;mvn_sta_v3_all_1day_alt
;PURPOSE:
;reads in a start and end date, and reprocesses all of the days in
;the interval. This is a main program, designed to be called from a
;shell script. Processes 1 day at a time. Creates version 3 of files,
;with start times at the start of the day, and overlap at the end of
;the day. This script is designed to be used if the end_date has
;already been processed. It won't reprocess data for the end date and
;beyond.
;CALLING SEQUENCE:
; .run mvn_sta_v3_all_1day_alt
;INPUT:
;start_time, end_time are input from files
;mvn_sta_v3_all_1day_alt_start_time.txt and
;mvn_sta_v3_all_1day_alt_end_time.txt.
;OUTPUT:
; Maven STA L2 files
;HISTORY:
; 2025-09-10, jimm@ssl.berkeley.edu
;-
this_file = 'mvn_sta_v3_all_1day_alt'
spawn, 'touch '+this_file+'_lock'
;Apparently you cannot compile code in the way we're calling this, so
st_file = this_file+'_start_time.txt'
st_time = strarr(1)
openr, unit, st_file, /get_lun
readf, unit, st_time
free_lun, unit
tstart = time_double(st_time[0])
en_file = this_file+'_end_time.txt'
en_time = strarr(1)
;process days
openr, unit, en_file, /get_lun
readf, unit, en_time
free_lun, unit
tend = time_double(en_time[0])
If(tstart Ge tend) Then exit
;do the process one day at a time, in the local working directory, but
;the process starts by filling the new v3 L2 file 4 days in advance,
;or to the day before the end_date
one_day = 86400.0d0
days_in = time_string(tstart+4.0*one_day)
If(days_in Lt tend) Then Begin
   mvn_call_sta_l2l2, days_in = days_in, temp_dir = './', /use_l2_files, $
                      alt_data_path = 'fast/maven/', /new_l2_version, /l2_only_dead
Endif
;Now call the addbck process, No init keyword set, this will
;reset the sw version and the default data path to find the new v3
;files. Since this only runs for this date, the filepaths should be consistent.
mvn_sta_l2gen_addbck, date = time_string(tstart), $
                      end_date = time_string(tend), $
                      alt_data_path = 'fast/maven/'
;Add a day and reset start time file
tstart_new = tstart+one_day
openw, unit, this_file+'_start_time.txt', /get_lun
printf, unit, time_string(tstart_new)
free_lun, unit
;All done
spawn, '/bin/rm '+this_file+'_lock'
exit

