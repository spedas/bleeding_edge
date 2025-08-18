;+
;NAME:
; mvn_over_shell
;PURPOSE:
; Top shell for production of MAVEN PFP overview plots
;CALLING SEQUENCE:
; mvn_over_shell, date = date, $
;                 num_days = num_days, $
;                 reprocess = reprocess, $
;                 instr_to_process = instr_to_process, $
;                 start_date=start_date, end_date=end_date
;INPUT:
; All via keyword
;OUTPUT:
; No explicit outputs, just plots
;KEYWORDS:
; date = start date for process, default is today
; num_days = number of days to process, default is 1
; instr_to_process = which instruments, or plopt types, currently one
;                    of: ['over', 'lpw', 'mag', 'sep', 'sta', 'swe', 'swia']
; plot_dir = the output directory. The deafult is to write files to:
;            '/disks/data/maven/pfp/whatever_instrument/YYYY/MM' given
;            the date
; directory = same as plot_dir, kept for backwards compatibility. If
;             both plot_dir and directoy are set, plot_dir should 
;             take precedence.
; start_date, end_date = Start and end dates to facilitate
;                        reprocessing.
;HISTORY:
; Hacked from thm_over_shell, 2013-05-12, jmm, jimm@ssl.berkeley.edu
; Added pfpl2 overplots, 2015-04-22, jmm
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-06-03 10:53:07 -0700 (Wed, 03 Jun 2015) $
; $LastChangedRevision: 17796 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_over_shell.pro $
;-
Pro mvn_over_shell, date = date, $
                    num_days = num_days, $
                    instr_to_process = instr_to_process, $
                    plot_dir = plot_dir, $
                    start_date=start_date, end_date=end_date, $
                    l0_input_file=l0_input_file, xxx = xxx, $
                    directory = directory, _extra=_extra

;Hold load position for error handling
common mvn_over_shell_private, load_position

If(~keyword_set(datein)) Then $
  datein = time_string(systime(/seconds), precision = -3)

;oops, redundant keywords, this will insure that plot_dir takes precedence
If(keyword_set(directory) And ~keyword_set(plot_dir)) Then Begin
   plot_dir = directory
Endif

catch, error_status
If(error_status Ne 0) Then Begin
  dprint, dlevel = 0, 'Got Error Message'
  help, /last_message, output = err_msg
  For ll = 0, n_elements(err_msg)-1 Do print, err_msg[ll]
  Case load_position Of
    'over':Begin
      print, 'Skipped Overview: '+time_string(datein)
      Goto, skip_over
    End
    'lpw':Begin
      print, 'Skipped LPW Overview: '+time_string(datein)
      Goto, skip_lpw
    End
    'mag':Begin
      print, 'Skipped MAG Overview: '+time_string(datein)
      Goto, skip_mag
    End
    'sep':Begin
      print, 'Skipped SEP Overview: '+time_string(datein)
      Goto, skip_sep
    End
    'sta':Begin
      print, 'Skipped STA Overview: '+time_string(datein)
      Goto, skip_sta
    End
    'swe':Begin
      print, 'Skipped SWE Overview: '+time_string(datein)
      Goto, skip_swe
    End
    'swia':Begin
      print, 'Skipped SWIA Overview: '+time_string(datein)
      Goto, skip_swia
    End
    'pfpl2':Begin
      print, 'Skipped PFPL2 Overview: '+time_string(datein)
      Goto, skip_pfpl2
    End
    Else: Begin
      print, 'MVN_OVER_SHELL exiting with no clue'
    End
  Endcase
Endif

load_position = 'init'

mvn_qlook_init, device ='z', _extra=_extra                  ;not sure what this will do yet

If(keyword_set(instr_to_process)) Then Begin
  instx = strcompress(/remove_all, strlowcase(instr_to_process))
Endif Else instx = ['over', 'lpw', 'mag', 'sep', 'sta', 'swe', 'swia'];, 'pfpl2']

over_all = where(instx Eq 'over')
If(over_all[0] Eq -1) Then noload = 0b Else noload = 1b

If(keyword_set(l0_input_file)) Then Begin
  p1 = strsplit(file_basename(l0_input_file), '_',/extract)
  p1 = strlowcase(p1)
  If((p1[2] NE 'all' And p1[2] NE 'svy') Or p1[3] NE 'l0') Then Begin
     dprint, 'Incorrect filename: '+file_basename(l0_input_file)
     Return
  Endif
  date = p1[4]
  start_date = time_double(date)
  end_date= start_date
Endif Else Begin
    If(Not keyword_set(date)) Then $
      date = time_string(systime(/seconds), precision = -3)
    If(keyword_set(start_date)) Then start_date = time_double(start_date) Else Begin
        If(keyword_set(num_days)) Then ndays = num_days Else ndays = 1
        start_date = time_double(date)-86400.*(ndays-1)
    Endelse
    If(keyword_set(end_date)) Then end_date = time_double(end_date) $
    Else end_date = time_double(date)
Endelse

i = 0.

;Remove gap between plot panels
tplot_options, 'ygap', 0.0d0
tplot_options, 'lazy_ytitle', 1

;mess with margins
tplot_options, 'xmargin', [ 18, 10]
tplot_options, 'ymargin', [ 5, 5]

While start_date+86400.*i Le end_date Do Begin
    If(~keyword_set(xxx)) Then del_data,'*'
    datein = time_string(start_date+86400.*i)
    dprint, 'Processing: '+time_string(datein)
    datein = time_string(datein)
    datein_d = time_double(datein)
    yyyy = strmid(datein, 0, 4)
    mmmm = strmid(datein, 5, 2)
;plot_dir check down here, to allow direct output
    If(keyword_set(plot_dir)) Then Begin
       pdir = plot_dir 
       direct_to_dbase = 0b
    Endif Else Begin
       pdir = '/disks/data/maven/data/sci/'
       direct_to_dbase = 1b
    Endelse

    do_over = where(instx Eq 'over')
    If(do_over[0] Ne -1) Then Begin
        load_position = 'over'
        If(keyword_set(xxx)) Then noload_data = 1 Else noload_data = 0
        If(direct_to_dbase) Then pdir1 = pdir+'pfp/ql/'+yyyy+'/' $
        Else pdir1 = pdir
        If(~is_string(file_search(pdir1))) Then file_mkdir, pdir1
        mvn_gen_overplot, date = datein, /makepng, device = 'z', $
          directory = pdir1, l0_input_file=l0_input_file, noload_data = noload_data, _extra=_extra
        skip_over:
    Endif
    do_lpw = where(instx Eq 'lpw')
    If(do_lpw[0] Ne -1) Then Begin
        load_position = 'lpw'
        If(direct_to_dbase) Then pdir1 = pdir+'lpw/ql/'+yyyy+'/' $
        Else pdir1 = pdir
        If(~is_string(file_search(pdir1))) Then file_mkdir, pdir1
        mvn_lpw_overplot, date = datein, /makepng, device = 'z', $
          directory = pdir1, noload_data = noload, _extra=_extra
        skip_lpw:
    Endif
    do_mag = where(instx Eq 'mag')
    If(do_mag[0] Ne -1) Then Begin
        load_position = 'mag'
        If(direct_to_dbase) Then pdir1 = pdir+'mag/ql/'+yyyy+'/' $
        Else pdir1 = pdir
        If(~is_string(file_search(pdir1))) Then file_mkdir, pdir1
        mvn_mag_overplot, date = datein, /makepng, device = 'z', $
          directory = pdir1, noload_data = noload, _extra=_extra
        skip_mag: 
    Endif
    do_sep = where(instx Eq 'sep')
    If(do_sep[0] Ne -1) Then Begin
        load_position = 'sep'
        If(direct_to_dbase) Then pdir1 = pdir+'sep/ql/'+yyyy+'/' $
        Else pdir1 = pdir
        If(~is_string(file_search(pdir1))) Then file_mkdir, pdir1
        mvn_sep_overplot, date = datein, /makepng, device = 'z', $
          directory = pdir1, noload_data = noload, _extra=_extra
        skip_sep: 
    Endif
    do_sta = where(instx Eq 'sta')
    If(do_sta[0] Ne -1) Then Begin
        load_position = 'sta'
        If(direct_to_dbase) Then pdir1 = pdir+'sta/ql/'+yyyy+'/' $
        Else pdir1 = pdir
        If(~is_string(file_search(pdir1))) Then file_mkdir, pdir1
        mvn_sta_overplot, date = datein, /makepng, device = 'z', $
          directory = pdir1, noload_data = noload, _extra=_extra
        skip_sta: 
    Endif
    do_swe = where(instx Eq 'swe')
    If(do_swe[0] Ne -1) Then Begin
        load_position = 'swe'
        If(direct_to_dbase) Then pdir1 = pdir+'swe/ql/'+yyyy+'/' $
        Else pdir1 = pdir
        If(~is_string(file_search(pdir1))) Then file_mkdir, pdir1
        mvn_swe_overplot, date = datein, /makepng, device = 'z', $
          directory = pdir1, noload_data = noload, _extra=_extra
        skip_swe: 
    Endif
    do_swia = where(instx Eq 'swia')
    If(do_swia[0] Ne -1) Then Begin
        load_position = 'swia'
        If(direct_to_dbase) Then pdir1 = pdir+'swi/ql/'+yyyy+'/' $
        Else pdir1 = pdir
        If(~is_string(file_search(pdir1))) Then file_mkdir, pdir1
        mvn_swia_overplot, date = datein, /makepng, device = 'z', $
          directory = pdir1, noload_data = noload, _extra=_extra
        skip_swia: 
    Endif
    do_pfpl2 = where(instx Eq 'pfpl2')
    If(do_pfpl2[0] Ne -1) Then Begin
        load_position = 'pfpl2'
        If(direct_to_dbase) Then pdir1 = pdir+'pfp/l2/plots/'+yyyy+'/'+mmmm+'/' $
        Else pdir1 = pdir
        If(~is_string(file_search(pdir1))) Then file_mkdir, pdir1
        mvn_pfpl2_overplot, date = datein, /makepng, device = 'z', $
          directory = pdir1, noload_data = noload, _extra=_extra
        skip_pfpl2: 
    Endif
    i=i+1
End

Return
End
