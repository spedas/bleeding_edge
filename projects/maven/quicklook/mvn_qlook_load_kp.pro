;+
;NAME:
; mvn_qlook_load_kp
;CALLING SEQUENCE:
; mvn_qlook_load_kp, trange = trange, files = files
;PURPOSE:
; Inputs MAVEN KP insitu data from text files for the given time range
;INPUT:
;OUTPUT:
; a set of tplot variables for the KP data
;KEYWORDS:
; files = if set, then read from these files, otherwise, files are
;         figured out from the time range. 
; trange = read in the data from this time range, note that if both
;          files and time range are set, files takes precedence in
;          finding files. If not set, the default is to use the output
;          of timerange(), which may prompt the user
; user_pass = a user, password combination to be passed through to
;             file_retrieve.pro, a string with format:
;             'user:password' for sites that require Basic
;             authentication. Digest authentication is not supported.
; no_time_clip = if set do not clip the data to the time range. The
;                trange is only used for file selection.
; tvars = the array of tplot names for variables created
;HISTORY:
; 25-sep-2015, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-01-08 13:33:01 -0800 (Fri, 08 Jan 2016) $
; $LastChangedRevision: 19704 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_qlook_load_kp.pro $
;-
Pro mvn_qlook_load_kp, trange = trange, files = files, $
                       user_pass = user_pass, no_time_clip = no_time_clip, $
                       tvars = tvars, _extra=_extra

  common mvn_file_source_com, psource

  tvars = ''
;The first step is to set up filenames, if there are any
  If(keyword_set(files)) Then Begin
     filex = files
     tr0 = [0.0, 0.0]
  Endif Else Begin
     tr0 = timerange(trange)
;Need number of days and app_ids
     start_day_dbl = time_double(time_string(tr0[0], precision = -3)) ;start day in seconds
     ndays = ceil((tr0[1]-start_day_dbl)/86400.0d0)
     days = start_day_dbl+86400.0d0*dindgen(ndays)
     daystr = time_string(days, precision = -3, format = 6)
;Files for all days
     filex = ''
     For j = 0, ndays-1 Do Begin
        yyyy = strmid(daystr[j], 0, 4) & mmmm = strmid(daystr[j], 4, 2)
;filej0 is the local data directory relative path, and the SSL remote
;data relative path
        filej0 = 'maven/data/sci/kp/insitu/'+yyyy+'/'+mmmm+'/mvn_kp_insitu_'+$
                 daystr[j]+'_v??_r??.tab'
;filej1 is the SDC remote data directory relative path
        filej1 = 'sci/kp/insitu/'+yyyy+'/'+mmmm+'/mvn_kp_insitu_'+$
                 daystr[j]+'_v??_r??.tab'
;uses spd_download if sdc_input is set, file_retrieve chokes on
;'https'
        If(is_struct(psource)) Then Begin
           sdc_input = strpos(psource.remote_data_dir, 'lasp.colorado.edu')
        Endif Else sdc_input = -1
        If(sdc_input[0] Ne -1 && psource.no_server Eq 0) Then Begin
           local_path = psource.local_data_dir+filej0
           local_files = file_search(local_path)
           remote_path = psource.remote_data_dir+filej1
           remote_files = remote_path
           spd_download_expand, remote_files, /last_version
           If(is_string(local_files)) Then Begin
              filej = local_files[n_elements(local_files)-1]
;If the last version of remote_files is greater than the local
;version, then grab it, using gt and lt on file_basenames will work.
              If(is_string(remote_files)) Then Begin
                 If(file_basename(remote_files[0]) Gt file_basename(filej)) Then Begin
                    filej = spd_download(/last_version, $
                                         local_path = file_dirname(local_path, /mark_directory), $
                                         remote_file = remote_files)
                 Endif 
              Endif
              question_mark = strpos(filej, '?')
           Endif Else Begin
              filej = spd_download(/last_version, $
                                   local_path = file_dirname(local_path, /mark_directory), $
                                   remote_file = remote_files[0])
              question_mark = strpos(filej, '?')
           Endelse
        Endif Else Begin
           filej = mvn_pfp_file_retrieve(filej0, user_pass = user_pass)
;Files with ? or * left were not found
           question_mark = strpos(filej, '?')
        Endelse
        If(is_string(filej) && question_mark[0] Eq -1) Then $
           filex = [filex, filej]
     Endfor
     If(n_elements(filex) Gt 1) Then filex = filex[1:*] Else Begin
        dprint, 'No files found fitting input criteria'
        Return
     Endelse
  Endelse
;Only files that exist here
  filex = file_search(filex)
  If(~is_string(filex)) Then Begin
     dprint, 'No KP files found for time range: '+time_string(tr0)
     Return
  Endif
;Only unique files here
  filex_u = filex[bsort(filex)]
  filex = filex_u[uniq(filex_u)]
;Ok, load the files, it's easier to work with the pointer array
;to concatenate and clip, and then create the tplot variables.
  nfiles = n_elements(filex)
  fc = 0L
  For j = 0, nfiles-1 Do Begin
     otpj = mvn_qlook_kp_read(filex[j], tim_arrj, col_qj, $
                              col_sj, col_uj, col_fj)
     If(ptr_valid(otpj[0])) Then Begin
        If(fc Eq 0) Then Begin
           otp = otpj
           tim_arr = tim_arrj
;we're going to assume that all of these don't change
           col_quantity = col_qj
           col_source = col_sj
           col_units = col_uj
           col_fmt = col_fj
        Endif Else Begin
           If(Not array_equal(col_quantity, col_qj)) Then $
              dprint, 'Array mismatch for col_quantity, concat may be off'
           If(Not array_equal(col_source, col_sj)) Then $
              dprint, 'Array mismatch for col_source, concat may be off'
           If(Not array_equal(col_units, col_uj)) Then $
              dprint, 'Array mismatch for col_units, concat may be off'
           If(Not array_equal(col_fmt, col_fj)) Then $
              dprint, 'Array mismatch for col_quantity, concat may be off'
           tmp = *otp[j]
           tmpj = *otpj[j]
           ptr_free, otp[j]
           otp[j] = ptr_new([tmp, tmpj])
           tim_arr = [tim_arr, tim_arrj]
        Endelse
        fc = fc+1
     Endif Else Begin
        dprint, 'Unreadable file: '+filex[j]
     Endelse
  Endfor
  If(fc Eq 0) Then Begin
     dprint, 'No KP files found, no data input'
     If(keyword_set(files)) Then dprint, 'Files:'+files
     dprint, 'Time range: '+time_string(tr0)
     Return
  Endif
;clip data here
  ncol = n_elements(otp)
  If(~keyword_set(no_time_clip) && total(tr0) Gt 0) Then Begin
     keep = where(tim_arr Gt tr0[0] And tim_arr Le tr0[1], nkeep)
     If(nkeep Eq 0) Then Begin
        dprint, 'No data in time range: '+time_string(tr0)
        Return
     Endif
     tim_arr = tim_arr[keep]
     For j = 0, ncol-1 Do Begin
;Everything's a pointer here
        If(ptr_valid(otp[j])) Then Begin
           tmpj = *otp[j]
           ptr_free, otp[j]
           tmpj = tmpj[keep]
           otp[j] = ptr_new(tmpj)
        Endif
     Endfor
  Endif
;tplot variables
  tplot_name0 = col_source+strcompress(col_quantity, /remove_all)
;Swap 'XQuality' for 'QualityX', Y and Z, this will help, to combine
;variables, now if something ends in 'X', 'Y', 'Z' then this is a
;component that can be combined
  tplot_name0 = ssw_str_replace(tplot_name0, 'XQuality', 'QualityX')
  tplot_name0 = ssw_str_replace(tplot_name0, 'YQuality', 'QualityY')
  tplot_name0 = ssw_str_replace(tplot_name0, 'ZQuality', 'QualityZ')
;Ok, now is this an X, or start of a rotation matrix?
  xvar = bytarr(ncol)
  mtvar = bytarr(ncol)
  For j = 1, ncol-1 Do Begin    ;the first column is time
     tplot_namej = tplot_name0[j]
     lastchar = strmid(tplot_namej, strlen(tplot_namej)-1)
     If(lastchar Eq 'X') then xvar[j] = 1
     last9chars = strmid(tplot_namej, strlen(tplot_namej)-9)
     If(last9chars Eq 'Row1,Col1') Then mtvar[j] = 1
  Endfor
;Keep track of variables that have been used:
  used = bytarr(ncol)           ;will need this to make x,y,z, variables
  tvars = ''
  For j = 1, ncol-1 Do Begin
     tplot_namej = tplot_name0[j]
     dlimits = {data_att:{units:col_units[j]}}
     If(used[j] Eq 0) Then Begin
        If(~xvar[j] && ~mtvar[j]) Then Begin ;just a variable
           tvars = [tvars, tplot_namej]
           store_data, tplot_namej, data = {x:tim_arr, y:*otp[j]}, $
                       dlimits = dlimits
           used[j] = 1
        Endif Else If(xvar[j]) Then Begin
;Strip the last character from the name, find the Y and Z components
           tpl0 = strmid(tplot_namej, 0, strlen(tplot_namej)-1)
           ss_yvar = where(tplot_name0 Eq tpl0+'Y', yes_yvar)
           ss_zvar = where(tplot_name0 Eq tpl0+'Z', yes_zvar)
           If(yes_yvar Gt 0 And yes_zvar Gt 0) Then Begin
              y = replicate((*otp[j])[0], n_elements(tim_arr), 3)
              y[*, 0] = *otp[j]
              y[*, 1] = *otp[ss_yvar[0]]
              y[*, 2] = *otp[ss_zvar[0]]
              used[j] = 1
              used[ss_yvar[0]] = 1
              used[ss_zvar[0]] = 1
              tvars = [tvars, tpl0]
              store_data, tpl0, data = {x:tim_arr, y:y}, $
                       dlimits = dlimits
              options, tpl0, colors = [2, 4, 6], $
                       labels = ['X', 'Y', 'Z'], labflag = 1
           Endif Else Begin     ;shouldn't happen
              dprint, 'Missing Y or Z for:'+tplot_namej
              tvars = [tvars, tplot_namej]
              store_data, tplot_namej, data = {x:tim_arr, y:*otp[j]}, $
                       dlimits = dlimits
              used[j] = 1
           Endelse
        Endif Else If(mtvar[j]) Then Begin
;Strip the last 9 characters from the name, find the other 8 components
           tpl0 = strmid(tplot_namej, 0, strlen(tplot_namej)-9)
           ss_var = bytarr(3, 3)
           For k = 0, 2 Do For l = 0, 2 Do Begin
              kl_test = tpl0+'Row'+strcompress(k+1, /remove_all)+$
                        ',Col'+strcompress(l+1, /remove_all)
              ss_var[k, l] = where(tplot_name0 Eq kl_test)
           Endfor
           ok = where(ss_var Ne -1, nok)
           If(nok Eq 9) Then Begin
              y = replicate((*otp[j])[0], n_elements(tim_arr), 3, 3)
              For k = 0, 2 Do For l = 0, 2 Do Begin
                 y[*, l, k] = *otp[ss_var[k, l]] ;note transpose for columns
                 used[ss_var[k, l]] = 1
              Endfor
              used[j] = 1       ;redundant
              tvars = [tvars, tpl0]
              store_data, tpl0, data = {x:tim_arr, y:y}, $
                       dlimits = dlimits
           Endif Else Begin
              dprint, 'Missing Col or Row for:'+tplot_namej
              tvars = [tvars, tplot_namej]
              store_data, tplot_namej, data = {x:tim_arr, y:*otp[j]}, $
                       dlimits = dlimits
              used[j] = 1
           Endelse
        Endif
     Endif                    ; Else message, /info, tplot_namej+'already used'
  Endfor
  If(n_elements(tvars) Gt 1) Then tvars=tnames(tvars[1:*])

  Return
End

        
     
        
