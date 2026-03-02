;+
;NAME:
; mvn_call_sta_l2l2
;CALLING SEQUENCE:
; mvn_call_sta_l2l2
;INPUT:
; None -- the default is to read in a file
;         /disks/data/maven/data/sci/sta/l2/most_recent_l2_processed.txt
;         and process the files 3, 10, 30, 60 days before
;KEYWORDS:
; days_in = An array of dates, e.g., ['2009-01-30','2009-02-01'] to
;           process. 
; out_dir = the directory in which you write the data, default is
;           '/disks/data/maven/data/sci/sta/l2/'
; add_background = if set, then do all background calculations for
;                  this date.
; alt_data_path = New (2025-10) keyword for an alternate data path for
;                 output, replaces 'maven' in
;                 '/disks/data/maven/stuff/'
;                 UPDATED 2026-02 no longer prepends /disks/data/ 
;HISTORY:
;Hacked from mvn_call_sta_l2gen, 2016-10-18, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: ghanley $
; $LastChangedDate: 2026-02-23 15:18:22 -0800 (Mon, 23 Feb 2026) $
; $LastChangedRevision: 34181 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/l2util/mvn_call_sta_l2l2.pro $
;-
Pro mvn_call_sta_l2l2, out_dir = out_dir, $
                       days_in = days_in, $
                       alt_data_path = alt_data_path, $
                       _extra = _extra
  
  common temp_call_sta_l2gen, load_position
  set_plot, 'z'
  load_position = 'init'
  ecount = 0
  catch, error_status
  
  if error_status ne 0 then begin
     print, '%MVN_CALL_STA_L2L2: Got Error Message'
     help, /last_message, output = err_msg
     For ll = 0, n_elements(err_msg)-1 Do print, err_msg[ll]
;Open a file print out the error message, only once
     If(ecount Lt 1 && getenv('USER') Eq 'muser') Then Begin
        ecount = ecount+1
        ec = strcompress(string(ecount), /remove_all)
        openw, eunit, '/mydisks/home/maven/muser/sta_l2l2_err_msg'+ec+'.txt', /get_lun
        For ll = 0, n_elements(err_msg)-1 Do printf, eunit, err_msg[ll]
        If(keyword_set(timei)) Then Begin
           printf, eunit, timei
        Endif
        free_lun, eunit
;mail it to jimm@ssl.berkeley.edu
        cmd_rq = 'mailx -s "Problem with STA L2L2 process" jimm@ssl.berkeley.edu < /mydisks/home/maven/muser/sta_l2l2_err_msg'+ec+'.txt'
        spawn, cmd_rq
     Endif

     case load_position of
        'init':begin
           print, 'Problem with initialization'
           goto, SKIP_ALL
        end
        'l2gen':Begin
           print, '***************FILE SKIPPED****************'
           goto, SKIP_FILE
        end
        'Add IV4':Begin
           print, '***************FILE SKIPPED****************'
           goto, SKIP_FILE
        end
        else: goto, SKIP_ALL
     endcase
  endif
  If(keyword_set(out_dir)) Then odir = out_dir $
  Else Begin
     If(keyword_set(alt_data_path)) Then Begin
        ;odir = '/disks/data/'+alt_data_path+'data/sci/'
        odir = alt_data_path+'data/sci/'
     Endif Else odir = '/disks/data/maven/data/sci/'
  Endelse
  
;--------------------------------
  btime_set_from_file = 0b      ;need this to handle defaults correctly
  times_of_procfiles = 0.0d0
  one_day = 24.0*3600.0d0
  If(keyword_set(days_in)) Then Begin
     days = time_double(time_string(days_in, precision = -3))
  Endif Else Begin
     timefile = file_search(odir+'sta/l2/most_recent_l2_processed.txt')
     If(is_string(timefile[0])) Then Begin
        openr, unit, timefile[0], /get_lun
        btime = strarr(1)
        readf, unit, btime
        free_lun, unit
        btime = time_double(btime[0])
        btime_set_from_file = 1b ;only reset the time if you input it
;sanity check
        If(btime lt time_double('2013-10-13') Or $
           btime Gt systime(/sec)+one_day) Then Begin
           dprint, 'bad input time?'
           Return
        Endif
     Endif Else Begin
        dprint, 'Missing Input time file?'
        Return
     Endelse
;Only process if the date is less than today
     today = time_string(systime(/sec), precision = -3)
     btime = time_string(btime, precision = -3)
     If(time_double(btime) Ge time_double(today)) Then Begin
;        dprint, 'No Times to process'
        Return
     Endif
;Process 3, 10, 30, days before
     days = time_double(btime)-one_day*[3.0, 10.0, 30.0]
  Endelse
     
;For each day
  timep_do = time_string(days, precision = -3)
  nproc = n_elements(days)
;Send a message that processing is starting
  If(~keyword_set(days_in) && getenv('USER') Eq 'muser') Then Begin
     openw, tunit, '/mydisks/home/maven/muser/sta_l2l2_msg0.txt', /get_lun
     printf, tunit, 'Processing: sta'
     For i = 0, nproc-1 Do printf, tunit, timep_do[i]
     free_lun, tunit
     cmd0 = 'mailx -s "STA L2L2 process start" jimm@ssl.berkeley.edu < /mydisks/home/maven/muser/sta_l2l2_msg0.txt'
     spawn, cmd0
  Endif
  message, /info, 'Processing: sta'
  For i = 0, nproc-1 Do print, timep_do[i]
  For i = 0, nproc-1 Do Begin
;extract the date from the filename
     timei = timep_do[i]
;Don't process any files with dates prior to 2013-12-04
     If(time_double(timei) Lt time_double('2013-12-04')) Then Begin
        dprint, 'Not processing: '+timei
        Continue
     Endif
     yr = strmid(timei, 0, 4)
     mo = strmid(timei, 5, 2)
;filei_dir is the output directory, not necessarily the search
;directory
     filei_dir = odir+'sta/l2/'+yr+'/'+mo+'/'
     If(is_string(file_search(filei_dir)) Eq 0) Then Begin
        message, /info, 'Creating: '+filei_dir
        file_mkdir, filei_dir
     Endif
     load_position = 'l2gen'
     message, /info, 'PROCESSING: sta FOR: '+timei
     mvn_sta_l2gen, date = timei, directory = filei_dir, /use_l2_files, $
                    _extra=_extra

     If(keyword_set(add_background)) Then Begin
        load_position = 'Add IV4'
        fileivi_dir = odir
        mvn_sta_l2gen_addbck, date = timei, alt_data_path = odir+'sta/', _extra = _extra
     Endif

SKIP_FILE: 
     del_data, '*'
     heap_gc                    ;added this here to avoid memory issues
  Endfor
  load_position = 'Done'

;Send a message that processing is done
  If(~keyword_set(days_in) && getenv('USER') Eq 'muser') Then Begin
     openw, tunit, '/mydisks/home/maven/muser/sta_l2l2_msg1.txt', /get_lun
     printf, tunit, 'Finished Processing: sta'
     free_lun, tunit
     cmd1 = 'mailx -s "STA L2L2 process end" jimm@ssl.berkeley.edu < /mydisks/home/maven/muser/sta_l2l2_msg1.txt'
     spawn, cmd1
  Endif
;reset file time
  If(btime_set_from_file) Then Begin
     message, /info, 'Resetting last file time:'
     timefile = file_search(odir+'sta/l2/most_recent_l2_processed.txt')
     openw, unit, timefile, /get_lun
     time_out = time_string(time_double(btime)+one_day)
     printf, unit, time_out
     free_lun, unit
  Endif

  SKIP_ALL:
  Return
End


   

