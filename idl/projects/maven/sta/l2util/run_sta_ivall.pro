;+
;NAME:
;run_sta_ivall
;PURPOSE:
;Reads in a start date, and process a day, if that day is more than 
;250 days ago
;This is a main program, designed to be called from a
;shell script. Processes 1 day at a time, for iv1, then the previous
;day for iv2, then the previous day for iv3, then the previous day for
;iv4. This is done so that for each process both days on either side
;of the given day are processed.
;CALLING SEQUENCE:
;run_sta_ivall
;INPUT:
;start_time, is input from file
;/disks/data/maven/data/sci/sta/iv1/mvn_sta_ivall_start_time.txt
;OUTPUT:
; Temporary Maven STA L2 files, round 1 of background creation
;HISTORY:
; 2022-09-20, jmm, jimm@ssl.berkeley.edu
;-
Pro run_sta_ivall
  lock_file = '/mydisks/home/maven/muser/STAIVlock.txt'
  test_file = file_search(lock_file)
  If(is_string(test_file[0])) Then Begin
     message, /info, 'Lock file /mydisks/home/maven/muser/STAIVlock.txt Exists, Returning'
  Endif Else Begin
     spawn, 'touch '+lock_file
     st_file = '/disks/data/maven/data/sci/sta/iv1/mvn_sta_ivall_start_time.txt'
     st_time = strarr(1)
     openr, unit, st_file, /get_lun
     readf, unit, st_time
     free_lun, unit
     tstart = time_double(st_time[0])
;Only process if this date is more than 250 days old
     one_day = 86400.0d0
     days250 = systime(/sec)-250.0d0*one_day
     If(tstart Lt days250) Then Begin
;do the process one day at a time, in the local working directory
;Starts with iv1 for the input date, then subtracts a day for each of
;the next threee processes
        mvn_sta_l2gen, date = time_string(tstart), temp_dir = './', iv_level = 1
        mvn_sta_l2gen, date = time_string(tstart-one_day), temp_dir = './', iv_level = 2
        mvn_sta_l2gen, date = time_string(tstart-2.0*one_day), temp_dir = './', iv_level = 3
        mvn_sta_l2gen, date = time_string(tstart-3.0*one_day), temp_dir = './', iv_level = 4
;Add a day and reset start time file
        tstart_new = tstart+one_day
        openw, unit, st_file, /get_lun
        printf, unit, time_string(tstart_new)
        free_lun, unit
;All done
        spawn, '/bin/rm '+lock_file
     Endif
  Endelse
End


