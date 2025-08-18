;+
;NAME:
; mvn_sta_l2_load
;PURPOSE:
; Loads MVN L2 data for a given file(s), or time_range
;CALLING SEQUENCE:
; mvn_sta_l2_load, files = files, trange=trange, sta_apid=sta_apid, $
;                  tplot_vars_create = tplot_vars_create
;INPUT:
; All via keyword, if none are set, then the output of timerange() is
; used, which may prompt for a time interval
;KEYWORDS:
; files = if set, then read from these files, otherwise, files are
;         figured out from the time range. 
; trange = read in the data from this time range, note that if both
;          files and time range are set, files takes precedence in
;          finding files.
; sta_apid = an apid for the data, e.g. ['c0', 'c6'], if not set all
;            are included.
; user_pass = a user, password combination to be passed through to
;             file_retrieve.pro, a string with format:
;             'user:password' for sites that require Basic
;             authentication. Digest authentication is not supported.
; no_time_clip = if set do not clip the data to the time range. The
;                trange is only used for file selection.
; tplot_vars_create = if set, call mvn_sta_l2_tplot to get tplot
;                     variables
; tvar_names = list of the STA tplot variable names loaded
; l2_version_in = if set, input this version, the default is to use
;                 the current version, but that may not exist yet if 
;                 you are reprocessing
; iv_level = Loads data from intermediate (iv?) files with background
;            estimates, fills the bkg tag in the data structure, and
;            recalculates the eflux value, subtracting background.
; bkg_only = if set, only load background data, iv_level, (or
;            iv*_load) must be set
; no_download = if set, do not download data, passed through to
;               mvn_pfp_spd_download.pro
; no_update = if set, do not check for files if a file exists
; parent_files = an array of the files input, only file basenames,
;                only files that exist
;OUTPUT:
; No variables, data are loaded into common blocks
;HISTORY:
; 16-may-2014, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2024-06-27 12:54:12 -0700 (Thu, 27 Jun 2024) $
; $LastChangedRevision: 32711 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/mvn_sta_l2_load.pro $
;-
Pro mvn_sta_l2_load, files = files, trange = trange, sta_apid = sta_apid, $
                     user_pass = user_pass, no_time_clip = no_time_clip, $
                     tplot_vars_create = tplot_vars_create, $
                     tvar_names = tvar_names, l2_version_in = l2_version_in, $
                     iv_level = iv_level, bkg_only = bkg_only, $
                     no_download = no_download, no_update = no_update, $
                     parent_files = parent_files
;Keep track of software versioning here
  If(keyword_set(l2_version_in)) Then sw_vsn = l2_version_in $
  Else sw_vsn = mvn_sta_current_sw_version()
  sw_vsn_str = 'v'+string(sw_vsn, format='(i2.2)')
;Deal with possibility of background files
  If(keyword_set(iv_level)) Then Begin
     iv_str = strcompress(string(iv_level), /remove_all)
     iv_lvl = 'iv'+iv_str
  Endif
  If(keyword_set(bkg_only) && ~keyword_set(iv_level)) Then Begin
     dprint, 'IV_LEVEL keyword is not set, defaulting to iv_level = 1'
     iv_level = 1
  Endif
;The first step is to set up filenames, if there are any
  If(keyword_set(files)) Then Begin
     filex = files 
  Endif Else Begin
; If trange is set, do not time clip
     If(keyword_set(trange)) Then no_time_clip = 1
     tr0 = timerange(trange)
;Need number of days and app_ids
     start_day_dbl = time_double(time_string(tr0[0], precision = -3)) ;start day in seconds
     ndays = ceil((tr0[1]-start_day_dbl)/86400.0d0)                                        
     days = start_day_dbl+86400.0d0*dindgen(ndays)
     daystr = time_string(days, precision = -3, format = 6)
;App_ids
     If(is_string(sta_apid)) Then Begin
        If(n_elements(sta_apid) Eq 1) Then Begin
           ;we'll handle space-separated lists
           app_id = strsplit(sta_apid, ' ', /extract)
        Endif Else app_id = sta_apid
        app_id = strlowcase(strcompress(app_id, /remove_all))
     Endif Else Begin
        If(keyword_set(iv_level)) Then Begin
           app_id = ['c0', 'c6', 'c8', 'ca', 'd0', 'd1']
        Endif Else app_id = ['2a', 'c?', 'd?']
     Endelse
;Globbing is not clear in mvn_pfp_file_retrieve
     app_id1 = ''
     For j = 0, n_elements(app_id)-1 Do Begin
        a1 = strmid(app_id[j], 0, 1)
        a2 = strmid(app_id[j], 1, 1)
        If(a2 Eq '?' Or a2 Eq'*') Then Begin
           If(a1 Eq 'c') Then Begin
              aj = a1+['0','2','4','6','8','a','c','d','e','f']
           Endif Else If(a1 Eq 'd') Then Begin
              aj = a1+['0', '1', '4', '6', '7', '8', '9', 'a', 'b']
           Endif Else aj = '2a'
        Endif Else aj = app_id[j]
        app_id1 = [app_id1, aj]
     Endfor
     If(n_elements(app_id1) Gt 1) Then app_id = app_id1[1:*] Else Begin
        app_id = ['2a', 'c'+['0','2','4','6','8','a','c','d','e','f'], 'd'+['0', '1', '4', '6', '7', '8', '9', 'a', 'b']]
     Endelse
     napp_id = n_elements(app_id)
;FIles for all days and app_ids
     filex = ''
     If(keyword_set(iv_level)) Then ivfilex = ''
     For j = 0, napp_id-1 Do For k = 0, ndays-1 Do Begin
;fixed daystr to daystr[k], 2015-01-13
        yyyy = strmid(daystr[k], 0, 4) & mmmm = strmid(daystr[k], 4, 2)
        filepath = 'maven/data/sci/sta/l2/'+yyyy+'/'+mmmm+'/'        
        filejk0 = filepath+'mvn_sta_l2_'+app_id[j]+'*_'+daystr[k]+'_'+sw_vsn_str+'.cdf'
;        filejk = mvn_pfp_file_retrieve(filejk0, user_pass =
;user_pass)
;handle no_update here, so that spd_download does not connect, jmm, 2021-04-20
        If(keyword_set(no_update)) Then Begin
           ps = file_retrieve(/default_structure)
           filejk = file_search(ps.local_data_dir+filejk0)
           If(is_string(filejk)) Then Begin
              filejk = filejk[n_elements(filejk)-1]
              dprint, dlevel=2, 'File found Locally: '+filejk
           Endif Else Goto, look_remote
        Endif Else Begin
           look_remote:
           filejk = mvn_pfp_spd_download(filejk0, user_pass = user_pass, no_download = no_download)
        Endelse
;Files with ? or * left were not found
        question_mark = strpos(filejk, '?')
        If(is_string(filejk) && question_mark[0] Eq -1) Then filex = [filex, filejk]
        If(keyword_set(iv_level)) Then Begin
           ivfilepath = 'maven/data/sci/sta/'+iv_lvl+'/'+yyyy+'/'+mmmm+'/'
           ivfilejk0 = ivfilepath+'mvn_sta_l2_'+app_id[j]+'*_'+daystr[k]+'_'+iv_lvl+'.cdf'
           ;stick with no_update in spd_download here, jmm, 2021-04-20
           ivfilejk = mvn_pfp_spd_download(ivfilejk0, user_pass = user_pass, no_download = no_download, no_update = no_update)
;Files with ? or * left were not found
           iquestion_mark = strpos(ivfilejk, '?')
           If(is_string(ivfilejk) && iquestion_mark[0] Eq -1) Then ivfilex = [ivfilex, ivfilejk]
        Endif
     Endfor
     If(n_elements(filex) Gt 1) Then filex = filex[1:*] Else Begin
        dprint, 'No files found fitting input criteria'
        Return
     Endelse
     If(keyword_set(iv_level)) Then Begin
        If(n_elements(ivfilex) Gt 1) Then ivfilex = ivfilex[1:*] Else Begin
           dprint, 'No BKG files found fitting input criteria'
           Return
        Endelse
     Endif
  Endelse
;If bkg_only is set, then swap out filex for ivfilex
  If(keyword_set(bkg_only)) Then Begin
     filex = ivfilex
     bkg_sub = 0 ;Do not subtract background if you are only loading background
  Endif Else Begin
     bkg_sub = keyword_set(iv_level) ;will only load/subtract background if iv_Level is set
  Endelse

;Only unique files here
  filex_u = filex[bsort(filex)]
  filex = filex_u[uniq(filex_u)]
  nfiles = n_elements(filex)
;Output the files to be loaded
  parent_files = file_basename(filex)
;But we apparently also want the revision number
  For j = 0, nfiles-1 Do Begin
     fj0 = strsplit(filex[j],'.',/extract)
     fj1 = file_search(strjoin(fj0,'*.'))
     parent_files[j] = file_basename(fj1[n_elements(fj1)-1])
  Endfor
;Add bck files if not bkg_only,
  If(keyword_set(iv_level) And ~keyword_set(bkg_only)) Then Begin
     parent_files = [parent_files, file_basename(ivfilex)]
  Endif

;Ok, load the files, extract app_ids from filenames-because you may
;have to concatenate data app_id by app_id
  app_ids_all = ''
  For j = 0, nfiles-1 Do Begin
     xxxx = strsplit(file_basename(filex[j]), '_', /extract)
     app_ids_all = [app_ids_all, strmid(xxxx[3], 0, 2)]
  Endfor
  app_ids_all0 = app_ids_all[1:*]                  ;app_ids are in the same order as filex
  app_ids_all1 = app_ids_all0[bsort(app_ids_all0)] ;but sorted for uniq call
  app_ids_all = app_ids_all1[uniq(app_ids_all1)]   ;otherwise files are loaded twice over month boundaries
  napp_ids_all = n_elements(app_ids_all)           ;jmm, 2015-01-13
;Now for each app_id, read the files
  For j = 0, napp_ids_all-1 Do Begin
     datj = -1
     ssj = where(app_ids_all0 Eq app_ids_all[j], nssj)
     If(nssj Eq 0) Then Begin
        dprint, 'No files for apid: '+app_ids_all[j]
        Continue                ;to next app_id
     Endif Else Begin
        ck = 0
        If(keyword_set(trange) && n_elements(trange[0, *]) Gt 1) Then Begin
           ntr = n_elements(trange[0, *])
           For i = 0, ntr-1 Do For k = 0, nssj-1 Do Begin
;extract file time range from the filename, to check time ranges so
;that we don't need to load files if not necessary
              f1 = strsplit(file_basename(filex[ssj[k]]), '_', /extract)
              ti0 = time_double(f1[n_elements(f1)-2])+[0.0, 86400.0d0]
              If(time_double(trange[0, i]) Le ti0[1] and time_double(trange[1, i]) Ge ti0[0]) Then Begin
                 datk = mvn_sta_cmn_l2read(filex[ssj[k]], iv_level = iv_level, bkg_sub = bkg_sub, trange = trange[*, i])
                 If(is_struct(datk)) Then Begin
                    If(~is_struct(datj)) Then datj = temporary(datk) $
                    Else datj = mvn_sta_cmn_concat(temporary(datj), temporary(datk))
                 Endif
              Endif
           Endfor
        Endif Else Begin
           For k = 0, nssj-1 Do Begin
              datk = mvn_sta_cmn_l2read(filex[ssj[k]], trange = trange, iv_level = iv_level, bkg_sub = bkg_sub)
              If(is_struct(datk)) Then Begin
                 If(~is_struct(datj)) Then datj = temporary(datk) $
                 Else datj = mvn_sta_cmn_concat(temporary(datj), temporary(datk))
              Endif
           Endfor
        Endelse
;Check time range
        If(~keyword_set(files) and ~keyword_set(no_time_clip)) Then Begin
           If(is_struct(datj)) Then datj = mvn_sta_cmn_tclip(datj, tr0) $
           Else Begin
              dprint, 'No data for apid: '+app_ids_all[j]
              Continue          ;to next app_id
           Endelse
        Endif
     Endelse
;Contract nbins = 1 case, 
;     If(datj.nbins Eq 1) Then Begin
;        num_dists = n_elements(datj.time)
;        temp = reform(datj.bkg, num_dists, datj.nenergy, datj.nmass)
;        str_element, datj, 'bkg', temp, /add_replace  
;        temp = reform(datj.data, num_dists, datj.nenergy, datj.nmass)
;        str_element, datj, 'data', temp, /add_replace  
;        temp = reform(datj.eflux, num_dists, datj.nenergy, datj.nmass)
;        str_element, datj, 'eflux', temp, /add_replace  
;        temp = reform(datj.dead, num_dists, datj.nenergy, datj.nmass)
;        str_element, datj, 'dead', temp, /add_replace  
;     Endif
;Which App id?
     Case app_ids_all[j] of
        '2a': Begin
           common mvn_2a, mvn_2a_ind, mvn_2a_dat
           mvn_2a_dat = temporary(datj) & mvn_2a_ind = 0
        End
        'c0': Begin
           common mvn_c0, mvn_c0_ind, mvn_c0_dat
           mvn_c0_dat = temporary(datj) & mvn_c0_ind = 0
        End
        'c2': Begin
           common mvn_c2, mvn_c2_ind, mvn_c2_dat
           mvn_c2_dat = temporary(datj) & mvn_c2_ind = 0
        End
        'c4': Begin
           common mvn_c4, mvn_c4_ind, mvn_c4_dat
           mvn_c4_dat = temporary(datj) & mvn_c4_ind = 0
        End
        'c6': Begin
           common mvn_c6, mvn_c6_ind, mvn_c6_dat
           mvn_c6_dat = temporary(datj) & mvn_c6_ind = 0
        End
        'c8': Begin
           common mvn_c8, mvn_c8_ind, mvn_c8_dat
           mvn_c8_dat = temporary(datj) & mvn_c8_ind = 0
        End
        'ca': Begin
           common mvn_ca, mvn_ca_ind, mvn_ca_dat
           mvn_ca_dat = temporary(datj) & mvn_ca_ind = 0
        End
        'cc': Begin
           common mvn_cc, mvn_cc_ind, mvn_cc_dat
           mvn_cc_dat = temporary(datj) & mvn_cc_ind = 0
        End
        'cd': Begin
           common mvn_cd, mvn_cd_ind, mvn_cd_dat
           mvn_cd_dat = temporary(datj) & mvn_cd_ind = 0
        End
        'ce': Begin
           common mvn_ce, mvn_ce_ind, mvn_ce_dat
           mvn_ce_dat = temporary(datj) & mvn_ce_ind = 0
        End
        'cf': Begin
           common mvn_cf, mvn_cf_ind, mvn_cf_dat
           mvn_cf_dat = temporary(datj) & mvn_cf_ind = 0
        End
        'd0': Begin
           common mvn_d0, mvn_d0_ind, mvn_d0_dat
           mvn_d0_dat = temporary(datj) & mvn_d0_ind = 0
        End
        'd1': Begin
           common mvn_d1, mvn_d1_ind, mvn_d1_dat
           mvn_d1_dat = temporary(datj) & mvn_d1_ind = 0
        End
        'd2': Begin
           common mvn_d2, mvn_d2_ind, mvn_d2_dat
           mvn_d2_dat = temporary(datj) & mvn_d2_ind = 0
        End
        'd3': Begin
           common mvn_d3, mvn_d3_ind, mvn_d3_dat
           mvn_d3_dat = temporary(datj) & mvn_d3_ind = 0
        End
        'd4': Begin
           common mvn_d4, mvn_d4_ind, mvn_d4_dat
           mvn_d4_dat = temporary(datj) & mvn_d4_ind = 0
        End
        'd6': Begin
           common mvn_d6, mvn_d6_ind, mvn_d6_dat
           mvn_d6_dat = temporary(datj) & mvn_d6_ind = 0
        End
        'd7': Begin
           common mvn_d7, mvn_d7_ind, mvn_d7_dat
           mvn_d7_dat = temporary(datj) & mvn_d7_ind = 0
        End
        'd8': Begin
           common mvn_d8, mvn_d8_ind, mvn_d8_dat
           mvn_d8_dat = temporary(datj) & mvn_d8_ind = 0
        End
        'd9': Begin
           common mvn_d9, mvn_d9_ind, mvn_d9_dat
           mvn_d9_dat = temporary(datj) & mvn_d9_ind = 0
        End
        'da': Begin
           common mvn_da, mvn_da_ind, mvn_da_dat
           mvn_da_dat = temporary(datj) & mvn_da_ind = 0
        End
        'db': Begin
           common mvn_db, mvn_db_ind, mvn_db_dat
           mvn_db_dat = temporary(datj) & mvn_db_ind = 0
        End
     Endcase
  Endfor
  If(keyword_set(tplot_vars_create)) Then Begin
     mvn_sta_l2_tplot, /replace
     tvar_names = tnames('mvn_sta_'+app_id+'*')
  Endif Else tvar_names = ''

  Return
End
