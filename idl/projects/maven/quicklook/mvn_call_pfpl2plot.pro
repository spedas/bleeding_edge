;+
;NAME:
; mvn_call_pfpl2plot
;CALLING SEQUENCE:
; mvn_call_pfpl2plot
;INPUT:
; All via keyword
;KEYWORDS:
; time_in = the time for which old files created *after* this date
;           will be processed. E.g., if you pass in '2017-11-07'
;           then all files created after 7-nov-2017/00:00:00 will
;           be reprocessed. The default is to use the system time
;           minus 24 hours.
; dtime = The number of seconds prior to system time used in the
;         deafult case, defined as 84610.0 seconds.
; before_time = if set, process all of the files created *before* the
;              input time
; days_in = An array of dates, e.g., ['2009-01-30','2009-02-01'] to
;           process. This ignores the input time. This option
;           replicates the proceesing done by
;           thm_reprocess_l2gen_days.
; out_dir = the directory for plots, default is to use the default
;           database, /disks/data/maven/data/sci/pfp/l2/plots.
; use_file4time = if set, use filenames for time test instead of file
;                 modified time, useful for reprocessing
; search_time_range = if set, then use this time range to find files
;                     to be processed, instead of just before or after
;                     time. 
; no_proc_mail = do not send email when starting a process, so that
;                there aren't a bunch of e,ails during reprocessing
;HISTORY:
;Hacked from mvn_call_sta_l2gen.pro 2015-06-02, jmm
;Added call to mvn_pfpl2_longplot, 2019-12-10, jmm
;Added call to mvn_spaceweather_overplot, 2023-09-05, jmm
; $LastChangedBy: jimm $
; $LastChangedDate: 2023-09-26 14:32:36 -0700 (Tue, 26 Sep 2023) $
; $LastChangedRevision: 32134 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_call_pfpl2plot.pro $
;-
Pro mvn_call_pfpl2plot, time_in = time_in, $
                        dtime = dtime, $
                        before_time = before_time, $
                        out_dir = out_dir, $
                        use_file4time = use_file4time, $
                        search_time_range = search_time_range, $
                        days_in = days_in, $
                        instrument = instrument, $
                        no_proc_mail = no_proc_mail, $
                        _extra = _extra
  
  common temp_call_sta_l2gen, load_position
  set_plot, 'z'

  load_position = 'init'
  einit = 0
  catch, error_status
;create a random number for emails
  Ff_ext = strcompress(/remove_all, string(long(100000.0*randomu(seed))))
  if error_status ne 0 then begin
     print, '%MVN_CALL_PFPL2PLOT: Got Error Message'
     help, /last_message, output = err_msg
     For ll = 0, n_elements(err_msg)-1 Do print, err_msg[ll]
;Open a file print out the error message, only once
     If(einit Eq 0) Then Begin
        einit = 1
        efile = '/mydisks/home/maven/muser/pfpl2_err_msg.txt'+ff_ext
        openw, eunit, efile, /get_lun
        For ll = 0, n_elements(err_msg)-1 Do printf, eunit, err_msg[ll]
        If(keyword_set(timei)) Then Begin
           printf, eunit, time_string(timei)
        Endif Else printf, eunit, 'Date unavailable' 
        free_lun, eunit
;mail it to jimm@ssl.berkeley.edu
        cmd_rq = 'mailx -s "Problem with PFPL2 process" jimm@ssl.berkeley.edu < '+efile
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
        'pfp12':Begin
           print, '***************FILE SKIPPED****************'
           goto, SKIP_FILE
        end
        'pfp12_long':Begin
           print, '***************FILE SKIPPED****************'
           goto, SKIP_FILE
        end
        'spaceweather':Begin
           print, '***************FILE SKIPPED****************'
           goto, SKIP_FILE
        end
        else: goto, SKIP_ALL
     endcase
  endif
  If(keyword_set(out_dir)) Then odir = out_dir Else odir = '/disks/data/maven/data/sci/'

;--------------------------------
  If(keyword_set(instrument)) Then instr = instrument $
  Else instr = ['pfpl2', 'pfpl2_long','spaceweather']
  ninstr = n_elements(instr)
  If(~keyword_set(days_in) && ~keyword_set(search_time_range)) Then Begin
     If(keyword_set(time_in)) Then Begin
        btime = time_double(time_in) 
     Endif Else Begin
        If(keyword_set(dtime)) Then dt = dtime Else dt = 86410.0d0
        btime = systime(/sec)-dt
     Endelse
     If(btime lt time_double('2013-10-13') Or $
        btime Gt systime(/sec)+24.0*3600.0d0) Then Begin
        dprint, 'bad input time?'
        Return
     Endif
  Endif Else Begin ;ANother fix for files touched, 2020-01-24, jmm
     btime = systime(/sec)-88410.0d0 ;shouldn't be needed
     btime = btime > time_double('2020-01-23/22:00:00')
  Endelse
  
;For each instrument
  For k = 0, ninstr-1 Do Begin
     load_position = 'instrument'
     instrk = instr[k]
     If(keyword_set(days_in)) Then Begin
        days = time_string(days_in)
        timep_do = strmid(days, 0, 4)+strmid(days, 5, 2)+strmid(days, 8, 2)
     Endif Else Begin
        Case instrk Of ;some instruments require multiple directories
           'pfpl2': Begin
              instr_dir = ['lpw','mag','sep','sta','swe','swi']
              suffix = ['cdf','sts','cdf','cdf','cdf','cdf']
              sdir = '/disks/data/maven/data/sci/'+instr_dir+'/l2/*/*/*.'+suffix
;Add bcrust save files:
              sdir = [sdir, '/disks/data/maven/data/mod/bcrust/*/*/*.tplot']
           End
           'pfpl2_long': Begin
              instr_dir = ['lpw','mag','sep','sta','swe','swi']
              suffix = ['cdf','sts','cdf','cdf','cdf','cdf']
              sdir = '/disks/data/maven/data/sci/'+instr_dir+'/l2/*/*/*.'+suffix
;Add bcrust save files:
              sdir = [sdir, '/disks/data/maven/data/mod/bcrust/*/*/*.tplot']
           End
           'spaceweather': Begin
              instr_dir = ['lpw','mag','sep','sta','swe','swi']
              suffix = ['cdf','sts','cdf','cdf','cdf','cdf']
              sdir = '/disks/data/maven/data/sci/'+instr_dir+'/l2/*/*/*.'+suffix
           End
           Else: sdir = '/disks/data/maven/data/sci/'+instrk+'/l2/*/*/*.cdf'
        Endcase
;Set up check directories
        pfile = file_search(sdir)
        If(keyword_set(use_file4time)) Then Begin
 ;Get the file date
           timep = file_basename(pfile)
           For i = 0L, n_elements(pfile)-1L Do Begin
              ppp = strsplit(timep[i], '_', /extract)
              the_date = where((strlen(ppp) Eq 8) And $
                               (strmid(ppp, 0, 1)) Eq '2', nthe_date)
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
           proc_file = where(test_time Lt  btime, nproc)
        Endif Else Begin
           proc_file = where(test_time GT btime, nproc)
        Endelse
        If(nproc Gt 0) Then Begin
;Get the file date
           timep = file_basename(pfile[proc_file])
           For i = 0, nproc-1 Do Begin
              ppp = strsplit(timep[i], '_', /extract)
              the_date = where((strlen(ppp) Eq 8) And $
                               (strmid(ppp, 0, 1)) Eq '2', nthe_date)
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
        dprint, 'No Files to process for Instrument: '+instrk
     Endif Else Begin
        nproc = n_elements(timep_do)
;Send a message that processing is starting
        If(~keyword_set(no_proc_mail)) Then Begin
           ofile0 = '/mydisks/home/maven/muser/pfpl2_msg0.txt'+ff_ext
           openw, tunit, ofile0, /get_lun
           printf, tunit, 'Processing: '+instrk
           For i = 0, nproc-1 Do printf, tunit, timep_do[i]
           free_lun, tunit
           cmd0 = 'mailx -s "PFPL2 process start" jimm@ssl.berkeley.edu < '+ofile0
           spawn, cmd0
           file_delete, ofile0
        Endif
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
           filei_dir = odir+'/pfp/l2/plots/'+yr+'/'+mo+'/'
           If(is_string(file_search(filei_dir)) Eq 0) Then Begin
              message, /info, 'Creating: '+filei_dir
              file_mkdir, filei_dir
           Endif
           message, /info, 'PROCESSING: '+instrk+' FOR: '+timei
           Case instrk Of
              'pfpl2': Begin
                 load_position = 'pfp12'
                 mvn_pfpl2_overplot, date = timei, directory = filei_dir, $
                                     device = 'z', /multipngplot, _extra =_extra
              End
              'pfpl2_long': Begin ;add longplot, jmm, 2019-12-10
                 load_position = 'pfp12_long'
                 mvn_pfpl2_longplot, date = timei, directory = filei_dir, $
                                     device = 'z', _extra = _extra
              End
              'spaceweather': Begin
                 load_position = 'spaceweather'
                 filei_dir = '/disks/data/maven/anc/ccmc/' ;the full output path is handled in the overplot program
                 If(is_string(file_search(filei_dir)) Eq 0) Then Begin
                    message, /info, 'Creating: '+filei_dir
                    file_mkdir, filei_dir
                 Endif
                 mvn_spaceweather_overplot, date = timei, directory = filei_dir, $
                                            device = 'z', /makepng, _extra =_extra
              End
              Else: Begin
                 dprint, 'No instrument defined: '+instrk
              End
           Endcase
           SKIP_FILE: 
           del_data, '*'
           heap_gc              ;added this here to avoid memory issues
        Endfor
        SKIP_INSTR: load_position = 'instrument'
;Send a message that processing is done
        If(~keyword_set(no_proc_mail)) Then Begin
           ofile1 = '/mydisks/home/maven/muser/pfpl2_msg1.txt'+ff_ext
           openw, tunit, ofile1, /get_lun
           printf, tunit, 'Finished Processing: '+instrk
           free_lun, tunit
           cmd1 = 'mailx -s "PFPL2 process end" jimm@ssl.berkeley.edu < '+ofile1
           spawn, cmd1
           file_delete, ofile1
        Endif
     Endelse
;reset all tplot options, by using options input for only title
     tplot_options, options = {title:''}
  Endfor

  SKIP_ALL:
  Return
End

