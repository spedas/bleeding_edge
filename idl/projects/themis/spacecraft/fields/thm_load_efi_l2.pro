;+
;Procedure: THM_LOAD_EFI_l2
;
;Purpose:  Loads THEMIS EFI level 2 data
;
;Syntax:  THM_LOAD_EFI [, <optional keywords below> ]
;
;keywords:
;  PROBE:		Input, string.  Specify space-separated probe
;  letters, or string array (e.g., 'a c', ['a', 'c']).  Defaults to
;  all probes.
;  DATATYPE:		Input, string.  Default setting is to load
;  quantities.  Use DATATYPE kw to narrow the data products.
;  Wildcards and glob-style patterns accepted (e.g., ef?, *_dot0).
;  SUFFIX:		Input, scalar or array string.  Set (scalar)
;  to append SUFFIX to all output TPLOT variable names.  Set (array
;  with same # elements	as COORD) to put suffixes for corresponding
;  COORD elements (one TPLOT variable with suffix for each element of
;  COORD).  When COORD has > 1 element, SUFFIX must have the same # of
;  elements (or be unset).
;  TRANGE:		Input, double (2 element array).  Time range
;  of interest.  If this is not set, the default is to prompt the
;  user.  Note that if the input time range is not a full day, a full
;  day's data is loaded.
;  /DOWNLOADONLY:	Input, numeric, 0 or 1.  Set to download file
;  but not read it.
;  /VALID_NAMES:	Input, numeric, 0 or 1.  If set, then this
;  routine will return the valid probe, datatype and/or level options
;  in named variables supplied as arguments to the corresponding
;  keywords.
;  FILES:		Output, string.  Named varible for output of
;  pathnames of local files.
;  /VERBOSE:		Input, numeric, 0 or 1.  Set to output some
;  useful info.
;  /NO_DOWNLOAD:	Input, numeric, 0 or 1.  Set to use only files
;  which are online locally.
;  RELPATHNAMES_ALL:	Output, string.  Named variable in which to
;  return all files that are required for specified timespan, probe,
;  datatype, and level.  If present, no files will be downloaded, and
;  no data will be loaded.
;  COORD:		Input, string.  What coordinate system you
;  would like your data in.  For choices, see THEMIS Sci. Data
;  Anal. Software Users Guide.
;  TEST:		Input, numeric, 0 or 1.  Disables selected
;  /CONTINUE to MESSAGE.  For QA testing only.
;  /NO_TIME_CLIP:       Disables time clipping, which is the default
;Example:
;   thg_load_efi,/get_suppport_data,probe=['a', 'b']
;Notes:
;
;Modifications:
;  Added TEST kw to disable certain /CONTINUE to MESSAGE, and passed TEST
;    through to THM_CAL_EFI.PRO, W.M.Feuerstein, 4/7/2008 (M).
;  Fixed crash on passing an argument for RELPATHNAMES_ALL, WMF, 4/9/2008 (Tu).
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-07-22 16:45:29 -0700 (Tue, 22 Jul 2025) $
; $LastChangedRevision: 33486 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/thm_load_efi_l2.pro $
;-

pro thm_load_efi_l2, probe = probe, datatype = datatype, trange = trange, $
                     level = level, verbose = verbose, downloadonly = downloadonly, $
                     no_download = no_download, coord = coord, varformat = varformat, $
                     cdf_data = cdf_data, varnames = varnames, valid_names = valid_names, $
                     files = files, relpathnames_all = relpathnames_all, $
                     suffix = suffix, progobj = progobj, test = test, $
                     no_time_clip = no_time_clip, msg_out=msg_out, _extra = _extra

  thm_init
  
  if ~keyword_set(probe) then probe = ['a', 'b', 'c', 'd', 'e']

; If verbose keyword is defined, override !themis.verbose
  vb = size(verbose, /type) ne 0 ? verbose : !themis.verbose
  if not keyword_set(suffix) then suffix=''
  if arg_present(relpathnames_all) then begin
     downloadonly=1
     no_download=1
  end

  thm_load_proc_arg, sname = probe, datatype = datatype, $
    level = 'l2', verbose = verbose, no_download = no_download, $
    valid_names = valid_names, $
    vsnames = 'a b c d e', $
    type_sname = 'probe', $
    vdatatypes = 'eff_dot0 efs_dot0 eff_q_mag eff_q_pha efs_q_mag efs_q_pha eff_e12_efs eff_e34_efs efp efw', $
    vtypes = 'calibrated', $
    vlevels = 'l2', $
    vL2datatypes = 'eff_dot0 efs_dot0 eff_q_mag eff_q_pha efs_q_mag efs_q_pha eff_e12_efs eff_e34_efs efp efw', $
    file_vL2datatypes = 'efi efi efi efi efi efi efi efi efp efw', $
    deflevel = 'l2', $
    osname = probes, odt = dts, olvl = lvls, $
    oft = fts, ofdt = fdts, otyp = typ, $
    load_params = !themis, $
    my_themis = my_themis

  lvls = 'l2'                   ;only one level at a time please
  ndts = n_elements(dts)
  nfts = n_elements(fts)
  nprobes = n_elements(probes)

  if keyword_set(valid_names) then return

  if ndts*nfts*nprobes le 0 then return

  if arg_present(cdf_data) && ndts*nprobes gt 1 then begin
    dprint,  'can only get cdf_data for a single datatype'
    return
  endif

;
; If trange is not already set, take whatever was used for the
; last timespan command, similar to what happens inside
; thm_load_xxx.  This ensures that time range clipping is
; performed, even if a trange keyword argument is not explicitly passed.

  if ~keyword_set(trange) then begin
    trange = timerange()        ;
  endif

;get file names, loop over all snames, levels and datatypes
  for j = 0, nfts-1 do $
    for i = 0, nprobes-1 do begin
    probei = probes[i]
    ftj = fts[j]
    lvlk = 'l2'
    relpath = 'th'+probei+'/'+lvlk+'/'+ ftj+'/'
    prefix = 'th'+probei+'_'+lvlk+'_'+ftj+'_'
    dir = 'YYYY/'
    ending = '_v01.cdf'

    relpathnames = file_dailynames(relpath, prefix, ending, dir = dir, trange = trange, addmaster = addmaster)

    if vb ge 7 then dprint,  'relpathnames : ', relpathnames

    if arg_present(relpathnames_all) then begin
      if i+j eq 0 then relpathnames_all = relpathnames else relpathnames_all = [relpathnames_all, relpathnames]
    endif

;;download files for this probe, level, and datatype
;; my_themis is a copy of !themis, which may have no_download set
    files = spd_download(remote_file=relpathnames, _extra = my_themis, progobj = progobj)

    if keyword_set(downloadonly) then continue

    if arg_present(cdf_data) then begin
      cdf_data = cdf_load_vars(files, varnames = varnames, verbose = vb, /all)
      return
    endif
    if ~keyword_set(varformat) then begin
      varformat = 'th?_'+dts
      If(keyword_set(coord)) Then Begin
        crd = ssl_check_valid_name(strlowcase(coord), ['dsl', 'gse', 'gsm'], /include_all, $
                                   invalid=msg_coord, type='coordinates')
      Endif Else begin
        crd = 'dsl'
        dprint,  'Defaulting to loading data in DSL coordinates.  Use coord="gse", "gsm", "all", or "*" to load other coordinate systems.'
      Endelse
      For vv = 0, n_elements(crd)-1 Do Begin
        varformat = [varformat, ' th?_'+dts+'_'+crd[vv]]
      Endfor
      If(n_elements(varformat) Gt 1) Then varformat = strjoin(varformat, ' ')
    endif

    if keyword_set(vb) then dprint,  transpose(['Loading...', files])
    If(is_string(file_search(files)) Eq 0) Then Begin
      dprint, 'Files: '+files+' not found'
      Return
    Endif
    spd_cdf2tplot, file = files, all = all, verbose = vb, varformat = varformat, tplotnames = tplotnames

    if ~keyword_set(no_time_clip) && keyword_set(trange) then begin
      for l = 0, n_elements(tplotnames)-1 do begin
        if tplotnames[l] eq '' then continue
        dprint,  'Clipping '+tplotnames[l]
        time_clip, tplotnames[l], trange[0], trange[1], /replace, error = clip_err
        if clip_err then begin
          dprint,  'Unable to clip '+tplotnames[l]+' to requested time range. Data may be out of range.'
          store_data, tplotnames[l], /del
          filtered_tplotnames = tplotnames[l]
        endif
      endfor
      if keyword_set(filtered_tplotnames) then tplotnames = filtered_tplotnames
    endif

;; add DLIMIT tags to data quantities, and suffix if necessary
    for l = 0, n_elements(tplotnames)-1 do begin
      tplot_var = tplotnames[l]
      etype = strmid(tplot_var, 0, 5)
      qflag = strpos(tplot_var, '_q_')
      get_data, tplot_var, data = d_str, limit = l_str, dlimit = dl_str
      if is_struct(dl_str) then begin
        if qflag[0] eq -1 then begin ;a field or voltage
          spd_new_units, tplot_var
          spd_new_coords, tplot_var
          get_data, tplot_var, dlimits = dl_str
          unit = dl_str.data_att.units
;the units tag has the coordinate system included; for ysubtitle and
;for SPDF plots. Strip it from the units tag here, but not from the
;'unit' variable, since that goes to ysubtitle
          u1 = strsplit(unit, ' ', /extract)
          dl_str.data_att.units = u1[0]
          if etype Eq 'th'+probei+'_v' then begin
            colors = [1, 2, 3, 4, 5, 6]
            labels = ['V1', 'V2', 'V3', 'V4', 'V5', 'V6']
          endif
          if etype eq 'th'+probei+'_e' then begin
            colors = [2, 4, 6]
            labels = [ 'Ex', 'Ey', 'Ez']
          endif
          str_element, dl_str, 'colors', colors, /add
          str_element, dl_str, 'labels', labels, /add
          str_element, dl_str, 'labflag', 1, /add
          store_data, tplot_var, data = d_str, limit = l_str, dlimit = dl_str
        endif else begin        ;a quality flag
;No units or coordinate sysetm, just the title
          str_element, dl_str, 'ytitle', tplot_var, /add
          store_data, tplot_var, data = d_str, limit = l_str, dlimit = dl_str
          ylim, tplot_var, 0, 0, 1
        endelse
      endif
      if n_elements(suffix) eq 1 && strlen(suffix) gt 0 then begin
        tplot_var_suf = tplot_var+suffix[0]
;        tplot_names
        copy_data, tplot_var, tplot_var_suf
        store_data,tplot_var,/delete
;        tplot_names
      endif
    endfor                      ;end of loop for loaded variables

  endfor                    ;end of loop over all probes, levels and datatypes.

  msg_out = keyword_set(msg_coord) ? msg_coord:''

end



