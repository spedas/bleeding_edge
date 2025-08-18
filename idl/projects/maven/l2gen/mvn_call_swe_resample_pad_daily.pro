;+
;NAME:
; mvn_call_swe_resample_pad_daily
;PURPOSE:
; Wrapper for mvn_swe_resample_pad_daily.pro, checks time for most
; recent mag L1 data, and processes the new days.
;CALLING SEQUENCE:
; mvn_call_swe_resample_pad_daily
;INPUT:
; None -- the default is to process all files after a given time, from
;         a file
;         /disks/data/maven/data/sci/swe/l2/most_recent_l1mag_processed.txt
;         and process all files after that time.
;KEYWORDS:
; time_in = the time for which old files created *after* this date
;           will be processed. E.g., if you pass in '2017-11-07'
;           then all files created after 7-nov-2017/00:00:00 will
;           be reprocessed.
; before_time = if set, process all of the files created *before* the
;              input time
; days_in = An array of dates, e.g., ['2009-01-30','2009-02-01'] to
;           process. This ignores the input time. This option
;           replicates the proceesing done by
;           thm_reprocess_l2gen_days.
; use_file4time = if set, use filenames for time test instead of file
;                 modified time, useful for reprocessing
; search_time_range = if set, then use this time range to find files
;                     to be processed, instead of just before or after
;                     time. 
; out_rootdir = if set, reset the root_data_dir variable to this
;               value, for testing, 
; l2only = if set, then insist on using L2 MAG data for generating 
;          L2 PAD data
; no_reset_time = if set, then don't reset the time in 
;                 most_recent_l1mag_processed.txt (useful for repocessing
;                 data without affecting the cron job)
;HISTORY:
; Hacked from mvn_call_swe_l2gen, 14-Oct-2015, jmm
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-10-13 16:02:56 -0700 (Tue, 13 Oct 2015) $
; $LastChangedRevision: 19066 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/l2gen/mvn_call_swe_resample_pad_daily.pro $
;-
Pro mvn_call_swe_resample_pad_daily, time_in = time_in, $
                                     before_time = before_time, $
                                     use_file4time = use_file4time, $
                                     search_time_range = search_time_range, $
                                     days_in = days_in, $
                                     out_rootdir = out_rootdir, $
                                     l2only = l2only, $
                                     no_reset_time = no_reset_time, $
                                     _extra = _extra
  
  common temp_call_swe_resample_pad_daily, load_position
  set_plot, 'z'
  load_position = 'init'
  catch, error_status
  If(error_status Ne 0) Then Begin
     catch, /cancel
     print, '%MVN_CALL_SWE_RESAMPLE_PAD_DAILY: Got Error Message'
     help, /last_message, output = err_msg
     For ll = 0, n_elements(err_msg)-1 Do print, err_msg[ll]
     case load_position of
        'init':begin
           print, 'Problem with initialization'
           goto, SKIP_ALL
        end
        'timing':begin
           print, '***************TIME CHECKING SKIPPED****************'
           goto, SKIP_ALL
        End
        'resample':Begin
           print, '***************FILE SKIPPED****************'
           goto, SKIP_FILE
        end
        else: goto, SKIP_ALL
     endcase
  endif
;--------------------------------
;Do any setting of the root_data directory here, note that the search
;directory is hard-wired so this will have no effect on file searching
  If(is_string(out_rootdir)) Then Begin
     temp_string = out_rootdir
     ll = strmid(temp_string, strlen(temp_string)-1, 1)
     If(ll Ne '/' And ll Ne '\') Then temp_string = temp_string+'/'
     setenv, 'ROOT_DATA_DIR='+temp_string
     message, /info, 'Reset ROOT_DATA_DIR='+temp_string
  Endif
  odir = root_data_dir()+'maven/data/sci/'

 ;if you have the days that you want you are done
  If(keyword_set(days_in)) Then Begin
     days = time_string(days_in, /date_only)
     mvn_swe_resample_pad_daily, days, l2only = l2only
     Return
  Endif

;--------------------------------
;Get btime, which may be used if days_in, or search times are not set
  btime = 0.0
  btime_set_from_file = 0b
  load_position = 'timing'
  If(keyword_set(time_in)) Then Begin
     btime = time_double(time_in)
  Endif Else If(~keyword_set(search_time_range)) Then Begin
     timefile = file_search(odir+'swe/l2/most_recent_l1mag_processed.txt')
     If(is_string(timefile[0])) Then Begin
        btime_set_from_file = 1b ;only reset the time if you input it
        openr, unit, timefile[0], /get_lun
        btime = strarr(1)
        readf, unit, btime
        free_lun, unit
        btime = time_double(btime[0])
                                ;sanity check
        If(btime lt time_double('2013-10-13') Or $
           btime Gt systime(/sec)+24.0*3600.0d0) Then Begin
           dprint, 'Bad input time? Using the most recent day'
           btime = time_double(systime(/sec)) - 86400.0d0
        Endif
     Endif Else Begin
        dprint, 'Missing Input time file? Using the most recent day'
        btime = time_double(systime(/sec)) - 86400.0d0
     Endelse
  Endif

;Get the file days to process
;Set up check directory, mag L1 
  sdir = '/disks/data/maven/data/sci/mag/l1/sav/1sec/????/??/mvn_mag_l1_pl_1sec*.sav'
  pfile = file_search(sdir)
  If(keyword_set(use_file4time)) Then Begin
 ;Get the file date
     timep = file_basename(pfile, '.sav')
     For i = 0L, n_elements(pfile)-1L Do Begin
        ppp = strsplit(timep[i], '_', /extract)
        the_date = where((strlen(ppp) Eq 8) And (strmid(ppp, 0, 1)) Eq '2', nthe_date)
        If(nthe_date Eq 0) Then timep[i] = '' $
        Else timep[i] = ppp[the_date]
     Endfor
     test_time = time_double(time_string(temporary(timep), /date_only))
  Endif Else Begin
     finfo = file_info(pfile)
     test_time = finfo.mtime
  Endelse
  If(keyword_set(search_time_range)) Then Begin
     atime_test = test_time GT time_double(search_time_range[0])
     btime_test = test_time Lt time_double(search_time_range[1])
     proc_file = where(atime_test Eq 1 And $
                       btime_test Eq 1, nproc)
  Endif Else If(keyword_set(before_time)) Then Begin
     proc_file = where(test_time Lt btime, nproc)
  Endif Else Begin
     proc_file = where(test_time GT btime, nproc)
  Endelse
  If(nproc Gt 0) Then Begin
;Keep track of file times, if you are resetting the most_recent file
     If(btime_set_from_file) Then times_of_procfiles = test_time[proc_file]
;Get the file date, take care because these are sav files
     timep = file_basename(pfile[proc_file], '.sav')
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
;If there are any dates to process, do them
  If(is_string(timep_do) Eq 0) Then Begin
     dprint, 'No New MAG L1 Files to process'
     Return
  Endif
     
  nproc = n_elements(timep_do)
;extract the date from the filename
  For i = 0, nproc-1 Do Begin
     load_position = 'resample'
     timei0 = timep_do[i]
     timei = strmid(timei0, 0, 4)+$
             '-'+strmid(timei0, 4, 2)+'-'+strmid(timei0, 6, 2)
;Don't process any files with dates prior to 2013-12-04
     If(time_double(timei) Lt time_double('2013-12-04')) Then Begin
        dprint, 'Not processing: '+timei
        Continue
     Endif
;mvn_swe_resample_pad_daily will take care of the output
     dprint, 'Processing: '+timei
     mvn_swe_resample_pad_daily, timei, l2only = l2only
     del_data, '*'
     heap_gc                    ;added this here to avoid memory issues
     SKIP_FILE: 
  Endfor

;reset file time, or not
  If(keyword_set(no_reset_time)) Then btime_set_from_file = 0b

  If(btime_set_from_file && times_of_procfiles[0] Gt 0) Then Begin
     message, /info, 'Resetting last file time:'
     timefile = odir+'swe/l2/most_recent_l1mag_processed.txt'
     openw, unit, timefile, /get_lun
     time_out = time_string(max(times_of_procfiles))
     printf, unit, time_out
     free_lun, unit
  Endif

  SKIP_ALL:
  Return
End


   


