;+
;NAME:
; mvn_call_sta_l2gen
;CALLING SEQUENCE:
; mvn_call_sta_l2gen
;INPUT:
; None -- the default is to read in a file
;         /disks/data/maven/data/sci/sta/l2/most_recent_l0_processed.txt
;         and process all files after that time
;KEYWORDS:
; time_in = the time for which old files created *after* this date
;           will be processed. E.g., if you pass in '2017-11-07'
;           then all files created after 7-nov-2017/00:00:00 will
;           be reprocessed
; before_time = if set, process all of the files created *before* the
;              input time
; days_in = An array of dates, e.g., ['2009-01-30','2009-02-01'] to
;           process. This ignores the input time.
; out_dir = the directory in which you write the data, default is './'
; use_file4time = if set, use filenames for time test instead of file
;                 modified time, useful for reprocessing
; search_time_range = if set, then use this time range to find files
;                     to be processed, instead of just before or after
;                     time. 
; use_l2_files = if set, then use L2 files as input, and not
;                L0's. Note that L0 is still used for file
;                searching, so you might want to use this with the
;                days_in option. (passed through to mvn_sta_l2gen.pro)
; max_l0_files = This is the maximum number of L0 files that can be
;                processed, the deault is 30. This is a fail-safe to
;                avoid mass reprocessing of data, if a bunch of file
;                ctime values are inadvertently changed. If more files
;                than this limit are tried, an error email will be sent.
;HISTORY:
;Hacked from thm_all_l1l2_gen, 17-Apr-2014, jmm
; $LastChangedBy: jimm $
; $LastChangedDate: 2020-01-24 09:13:20 -0800 (Fri, 24 Jan 2020) $
; $LastChangedRevision: 28228 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/l2util/mvn_call_sta_l2gen.pro $
;-
Pro mvn_call_sta_l2gen, time_in = time_in, $
                        before_time = before_time, $
                        out_dir = out_dir, $
                        use_file4time = use_file4time, $
                        search_time_range = search_time_range, $
                        days_in = days_in, $
                        max_l0_files = max_l0_files, $
                        _extra = _extra
  
  common temp_call_sta_l2gen, load_position
  set_plot, 'z'
  load_position = 'init'
  einit = 0
;Do not process more than maxfiles L0 files
  If(keyword_set(max_l0_files)) Then maxfiles = max_l0_files $
  Else maxfiles = 30
  catch, error_status
;create a random number for emails, use the input time for seed, so
;that multiple processes do not generate the same files
  If(keyword_set(time_in)) Then seed = long(time_double(time_in[0])) $
  Else If(keyword_set(days_in)) Then seed = long(time_double(days_in[0])) $
  Else seed = long(systime(/sec))
     
  Ff_ext = strcompress(/remove_all, string(long(100000.0*randomu(seed))))
  if error_status ne 0 then begin
     print, '%MVN_CALL_STA_L2GEN: Got Error Message'
     help, /last_message, output = err_msg
     For ll = 0, n_elements(err_msg)-1 Do print, err_msg[ll]
;Open a file print out the error message, only once
     If(einit Eq 0) Then Begin
        einit = 1
        efile = '/mydisks/home/maven/muser/sta_l2_err_msg.txt'+ff_ext
        openw, eunit, efile, /get_lun
        For ll = 0, n_elements(err_msg)-1 Do printf, eunit, err_msg[ll]
        If(keyword_set(timei)) Then Begin
           printf, eunit, timei
        Endif
        free_lun, eunit
;mail it to jimm@ssl.berkeley.edu
        cmd_rq = 'mailx -s "Problem with STA L2 process" jimm@ssl.berkeley.edu < '+efile
        spawn, cmd_rq
        file_delete, efile
     Endif

     case load_position of
        'init':begin
           print, 'Problem with initialization'
           goto, SKIP_ALL
        end
        'instrument':begin
           print, '***************INSTRUMENT SKIPPED****************'
           goto, SKIP_INSTR
        End
        'l2gen':Begin
           print, '***************FILE SKIPPED****************'
           goto, SKIP_FILE
        end
        else: goto, SKIP_ALL
     endcase
  endif
  If(keyword_set(out_dir)) Then odir = out_dir Else odir = '/disks/data/maven/data/sci/'

;--------------------------------
  instr = 'sta'
  ninstr = n_elements(instr)
  btime_set_from_file = 0b      ;need this to handle defaults correctly
  times_of_procfiles = 0.0d0
  If(keyword_set(time_in)) Then btime = time_double(time_in) Else Begin
     If(~keyword_set(days_in)) Then Begin
        timefile = file_search(odir+'sta/l2/most_recent_l0_processed.txt')
        If(is_string(timefile[0])) Then Begin
           openr, unit, timefile[0], /get_lun
           btime = strarr(1)
           readf, unit, btime
           free_lun, unit
           btime = time_double(btime[0])
           btime_set_from_file = 1b ;only reset the time if you input it
;sanity check
           If(btime lt time_double('2013-10-13') Or btime Gt systime(/sec)+24.0*3600.0d0) Then Begin
              dprint, 'bad input time?'
              Return
           Endif
        Endif Else Begin
           dprint, 'Missing Input time file?'
           Return
        Endelse
     Endif
  Endelse
     
;For each instrument
  For k = 0, ninstr-1 Do Begin
     load_position = 'instrument'
     instrk = instr[k]
     If(keyword_set(days_in)) Then Begin
        days = time_string(days_in)
        timep_do = strmid(days, 0, 4)+strmid(days, 5, 2)+strmid(days, 8, 2)
     Endif Else Begin
        Case instrk Of          ;so instruments require multiple directories
;           'sta': instr_dir = [instrk, 'mag']
           'sta': instr_dir = instrk
           Else: instr_dir = instrk
        Endcase
;Set up check directories, l0 is first
        sdir = '/disks/data/maven/data/sci/pfp/l0_all/*/*/mvn_pfp_all_l0_*.dat'
;        sdir = '/disks/data/maven/data/sci/pfp/l0/mvn_pfp_all_l0_*.dat'
        pfile = file_search(sdir)
        If(keyword_set(use_file4time)) Then Begin
 ;Get the file date
           timep = file_basename(pfile)
           For i = 0L, n_elements(pfile)-1L Do Begin
              ppp = strsplit(timep[i], '_', /extract)
              the_date = where((strlen(ppp) Eq 8) And (strmid(ppp, 0, 1)) Eq '2', nthe_date)
              If(nthe_date Eq 0) Then timep[i] = '' $
              Else timep[i] = ppp[the_date]
           Endfor
           test_time = time_double(time_string(temporary(timep), /date_only))
        Endif Else Begin
           finfo = file_info(pfile)
;"fix" for full mission touch of Jan-23-2020, jmm
           test_time = finfo.ctime ;changed from mtime, jmm, 2016-07-20
           touched = where(finfo.ctime Lt time_double('2020-01-23/22:00:00'), ntouched)
           If(ntouched Gt 0) Then Begin
              test_time[touched] = finfo[touched].mtime
           Endif
        Endelse
        If(keyword_set(search_time_range)) Then Begin
           atime_test = test_time GT time_double(search_time_range[0])
           btime_test = test_time Lt time_double(search_time_range[1])
           proc_file = where(atime_test Eq 1 And $
                             btime_test Eq 1, nproc)
        Endif Else If(keyword_set(before_time)) Then Begin
           proc_file = where(test_time Lt  btime, nproc)
        Endif Else Begin
           proc_file = where(test_time GT btime, nproc)
        Endelse
        If(nproc Gt maxfiles) Then Begin
           dprint, 'Too many files > '+string(maxfiles)
           message, 'Too many files to process > '+string(maxfiles)
        Endif
        If(nproc Gt 0) Then Begin
;Get the file date
           timep = file_basename(pfile[proc_file])
;Keep track of file times, if you are resetting the most_recent file
           If(btime_set_from_file) Then times_of_procfiles = test_time[proc_file]
           For i = 0, nproc-1 Do Begin
              ppp = strsplit(timep[i], '_', /extract)
              the_date = where((strlen(ppp) Eq 8) And (strmid(ppp, 0, 1)) Eq '2', nthe_date)
              If(nthe_date Eq 0) Then timep[i] = '' $
              Else timep[i] = ppp[the_date]
           Endfor
;process the unique dates
           dummy = is_string(timep, timep_ok) ;timep_ok are nonblank strings
           If(dummy Gt 0) Then Begin
              ss_timep = bsort(timep_ok, timep_s)
              timep_do = timep_s[uniq(timep_s)]
           Endif Else timep_do = ''
        Endif Else timep_do = ''
     Endelse
;If there are any dates to process, do them
     If(is_string(timep_do) Eq 0) Then Begin
        message, /info, 'No Files to process for Instrument: '+instrk
     Endif Else Begin
        nproc = n_elements(timep_do)
;Send a message that processing is starting
        ofile0 = '/mydisks/home/maven/muser/sta_l2_msg0.txt'+ff_ext
        openw, tunit, ofile0, /get_lun
        printf, tunit, 'Processing: '+instrk
        For i = 0, nproc-1 Do printf, tunit, timep_do[i]
        free_lun, tunit
        cmd0 = 'mailx -s "STA L2 process start" jimm@ssl.berkeley.edu < '+ofile0
        spawn, cmd0
        file_delete, ofile0
        message, /info, 'Processing: '+instrk
        For i = 0, nproc-1 Do print, timep_do[i]
        For i = 0, nproc-1 Do Begin
;extract the date from the filename
           timei0 = timep_do[i]
           timei = strmid(timei0, 0, 4)+$
                   '-'+strmid(timei0, 4, 2)+'-'+strmid(timei0, 6, 2)
;Don't process any files with dates prior to 2013-12-04
           If(time_double(timei) Lt time_double('2013-12-04')) Then Begin
              dprint, 'Not processing: '+timei
              Continue
           Endif
           yr = strmid(timei0, 0, 4)
           mo = strmid(timei0, 4, 2)
;filei_dir is the output directory, not necessarily the search
;directory
           filei_dir = odir+instrk+'/l2/'+yr+'/'+mo+'/'
           If(is_string(file_search(filei_dir)) Eq 0) Then Begin
              message, /info, 'Creating: '+filei_dir
              file_mkdir, filei_dir
           Endif
           load_position = 'l2gen'
           message, /info, 'PROCESSING: '+instrk+' FOR: '+timei
           Case instrk Of
              'sta': mvn_sta_l2gen, date = timei, directory = filei_dir, _extra=_extra
              Else: mvn_sta_l2gen, date = timei, directory = filei_dir, _extra=_extra
           Endcase
           SKIP_FILE: 
           del_data, '*'
           heap_gc              ;added this here to avoid memory issues
        Endfor
        SKIP_INSTR: load_position = 'instrument'
;Send a message that processing is done
        ofile1 = '/mydisks/home/maven/muser/sta_l2_msg1.txt'+ff_ext
        openw, tunit, ofile1, /get_lun
        printf, tunit, 'Finished Processing: '+instrk
        free_lun, tunit
        cmd1 = 'mailx -s "STA L2 process end" jimm@ssl.berkeley.edu < '+ofile1
        spawn, cmd1
        file_delete, ofile1
     Endelse
  Endfor
;reset file time
  If(btime_set_from_file && times_of_procfiles[0] Gt 0) Then Begin
     message, /info, 'Resetting last file time:'
     timefile = file_search(odir+'sta/l2/most_recent_l0_processed.txt')
     openw, unit, timefile, /get_lun
     time_out = time_string(max(times_of_procfiles))
     printf, unit, time_out
     free_lun, unit
  Endif

  SKIP_ALL:
  Return
End


   

