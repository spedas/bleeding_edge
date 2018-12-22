;+
;Procedure: THM_LOAD_XXX
;
;Purpose:  Generic THEMIS Data File Loading routine, meant to be called by
;   type specific thm_load procedures.
;
;keywords:
;  post_process_proc: name of procedure to call after cdf2tplot is called
;                     will be called w/ keywords sname, dt (datatype), lvl,
;                     and _extra.
;  relpath_funct: name of routine to call in place of file_dailynames
;                 may simply be a wrapper.
;                 will be called w/ keywords sname, dt (datatype), lvl,
;                 and _extra.
;  cdf_to_tplot: user-supplied procedure to override cdf2tplot
;  sname  = site or probe name. The default is 'all',
;  type_sname = string, set to 'probe' or 'site'
;  /all_sites_in_one: set this if all sites are contained in a single file.
;  vsnames = space-separated list of valid probes/sites
;  datatype = Can be any datatype from the list of valid datatypes
;             or 'all'
;  vdatatypes = space-separated list of valid data types
;  file_vdatatypes = space-separated list of file types corresponding to each
;          valid data type.  If there is a one-to-one correpspondence
;          between filetype and datatype, vfiletypes may be left undefined.
;          If all datatypes are in a single file, then file_vdatatypes may
;          contain a single name, rather than a list.
;  TRANGE= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded
;  level = the level of the data, the default is 'l1', or Level 1
;          data. A string (e.g., 'l2') or an integer can be used.
;  vlevels=A space-separated list of valid levels, e.g. 'l1 l2'
;  proc_type =  the type of data, i.e. 'raw' or 'calibrated'. This is
;          for validating the 'type' keyword to thm_load procs.
;  vtypes =A space-separated list of valid types, e.g. 'raw calibrated'
;  vL2datatypes= space-separated list of datatypes valid for L2 data
;  vL2coord= space-separated list of coordinates valid for L2 data
;  file_vL2datatypes=same as file_vdatatypes, but for L2 data.  Defaults to
;          value of file_vdatatypes.
;  coord = coordinate system of data to  be loaded.  For L2, may be an array or
;          space-separated list, which will checked against vL2coord.
;          For L1, no checking: passed on to post_process_proc.
;  CDF_DATA: named variable in which to return cdf data structure: only works
;          for a single spacecraft and datafile name.
;  VARNAMES: names of variables to load from cdf: default is all.
;  /GET_SUPPORT_DATA: load support_data variables as well as data variables
;                      into tplot variables.
;  /DOWNLOADONLY: download file but don't read it.
;  /NO_UPDATE: prevent contact to server if local file already exists.
;  /valid_names, if set, then this routine will return the valid probe, datatype
;          and/or level options in named variables supplied as
;          arguments to the corresponding keywords.
;  files   named varible for output of pathnames of local files.
;  /VERBOSE  set to output some useful info
;  suffix  suffix to add to names of tplot variables loaded from CDF
;          Note that the suffix is *not* applied to support_data.
;  SCM_CAL: structure that contains calibration paramters
;  msg_out: A named variable to output any useful error messages, 
;           messages can be printed to the console later when they
;           will be more visible to the user.
;
;Notes:
;  This routine is (should be) platform independent.
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-12-21 11:50:27 -0800 (Fri, 21 Dec 2018) $
; $LastChangedRevision: 26397 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_load_xxx.pro $
;-

pro thm_load_xxx, sname = sname, datatype = datatype, trange = trange, $
                  level = level, coord = coord, proc_type = type, version = version, $
                  verbose = verbose, downloadonly = downloadonly, $
                  cdf_data = cdf_data, get_cdf_data = get_cdf_data, $
                  get_support_data = get_support_data, varformat = varformat, $
                  tplotnames = tplotnames, valid_names = valid_names, $
                  files = files, $
                  type_sname = type_sname, $
                  vsnames = vsnames, vdatatypes = vdatatypes, $
                  file_vdatatypes = file_vdatatypes, $
                  vtypes = vtypes, $
                  vlevels = vlevels, deflevel = deflevel, $
                  vL2datatypes = vL2datatypes, vL2coord = vL2coord, $
                  file_vL2datatypes = file_vL2datatypes, $
                  relpath_funct = relpath_funct, $
                  cdf_to_tplot = cdf_to_tplot, $
                  post_process_proc = post_process_proc, $
                  addmaster = addmaster, midfix = midfix, $
                  no_download = no_download, relpathnames_all = relpathnames_all, $
                  all_sites_in_one = all_sites_in_one, suffix = suffix, $
                  progobj = progobj, $ ;jmm, 15-may-2007
                  scm_cal = scm_cal, $
                  no_update = no_update, $
                  alternate_load_params=alternate_load_params, $
                  no_time_clip = no_time_clip, $
                  no_implicit_wildcard=no_implicit_wildcard, $
                  use_eclipse_corrections=use_eclipse_corrections, $
                  msg_out=msg_out, $
                  _ref_extra = _extra


  compile_opt idl2

  if keyword_set(alternate_load_params) then begin
   dprint, 'Using alternate load parameters'
   load_params=alternate_load_params
  endif else begin
   thm_init
   load_params=!themis
  endelse

  thm_load_proc_arg, sname = sname, datatype = datatype, $
    level = level, coord = coord, proc_type = type, $
    verbose = verbose, $
    varformat = varformat, valid_names = valid_names, $
    type_sname = type_sname, $
    vsnames = vsnames, vdatatypes = vdatatypes, $
    file_vdatatypes = file_vdatatypes, $
    vtypes = vtypes, $
    vlevels = vlevels, deflevel = deflevel, $
    vL2datatypes = vL2datatypes, vL2coord = vL2coord, $
    file_vL2datatypes = file_vL2datatypes, $
    no_download = no_download, $
    progobj = progobj, $
    osname = snames, odt = dts, olvl = lvls, my_themis = my_themis, $
    oft = fts, ofdt = fdts, $ 
    load_params=load_params, $
    use_eclipse_corrections=use_eclipse_corrections, $
    no_update = no_update, $
    msg_out = msg_out

  vb = size(verbose, /type) ne 0 ? verbose : load_params.verbose

  nlvls = n_elements(lvls)
  ndts = n_elements(dts)
  nfts = n_elements(fts)
  nsnames = n_elements(snames)

  if nlvls*ndts*nfts*nsnames le 0 then return

  if keyword_set(valid_names) then return

  if get_cdf_data && nlvls*nfts*nsnames gt 1 then begin
    dprint,  'can only get cdf_data for a single file type'
    return
  endif

  if keyword_set(all_sites_in_one) then begin
    ;; site name is not included in pathname of data file
    nsnames = 1                 ;for ASK
  endif
  
;get file names, loop over all snames, levels and datatypes
  files_ptrarr = ptrarr(nsnames, nfts, nlvls)

  for k = 0, nlvls-1 do $
    for j = 0, nfts-1 do $
    for i = 0, nsnames-1 do begin
    snamei = snames[i]
    ftj = fts[j]
    lvlk = lvls[k]
    if keyword_set(relpath_funct) then begin
      ;; call a datatype specific pathname function, because
      ;; we don't want to write one-box-fits-all heuristics
      relpathnames = call_function(relpath_funct, sname = snamei, $
                                   filetype = ftj, level = lvlk, $
                                   version = version, trange = trange, $
                                   addmaster = addmaster, _extra = _extra)
    endif else begin
      ;; use standard heuristics to determine pathname
      ;; if these don't work, please consider using your own relpath_funct
      ;; before adding code which may affect the other instrument load routines
      if strcmp(strlowcase(type_sname), 'probe') then begin
        relpath = 'th'+snamei+'/'+lvlk+'/'+ ftj+'/'
        prefix = 'th'+snamei+'_'+lvlk+'_'+ftj+'_'
        dir = 'YYYY/'
      endif else if strcmp(strlowcase(type_sname), 'site') then begin
        relpath = 'thg/'+lvlk+'/'+ftj+'/'+snamei + '/'
        prefix = 'thg_'+lvlk+'_'+ftj+'_'+snamei + '_'
        dir = 'YYYY/'
      endif
      If(version Eq '') Then Begin
        ending = '.cdf'
      Endif Else ending = '_'+version+'.cdf'
  
      relpathnames = file_dailynames(relpath, prefix, ending, dir = dir, $
                                     trange = trange, addmaster = addmaster)
    endelse
       ;get the full path name, save it for later for reading the cdf.
    my_themis.no_download = 1
    files_ptrarr[i, j, k] = $
      ptr_new(spd_download(remote_file=relpathnames, _extra = my_themis))

                                ;build an array with all relpathnames, so all files can be downloaded
                                ;with one call to file_retrieve.
    if i+j+k eq 0 then relpathnames_all = relpathnames else $
      relpathnames_all = [relpathnames_all, relpathnames]
    if vb ge 7 then dprint,  'files', *files_ptrarr[i, j, k]

  endfor           ;end of loop over all snames, levels and datatypes.

    ;download files for all snames, levels, and datatypes
  if ~load_params.no_download && ~keyword_set(no_download) then begin
    if vb ge 7 then dprint,  'relpathnames', relpathnames_all
    my_themis.no_download = 0
    files = spd_download(remote_file=relpathnames_all, _extra = my_themis)
  endif

  ;there appear to be mulitple copies of this and other settings 
  ;in my_themis, load_params, & specific keywords - these should
  ;be sorted out more explicitly, but for now I'm copying
  ;the logic of the no_download implementation above
  if load_params.downloadonly || keyword_set(downloadonly) then begin
    ptr_free, files_ptrarr
    return
  endif

;load data into tplot variables  loop over all snames, levels and datatypes

  for k = 0, nlvls-1 do $
    for j = 0, nfts-1 do $
    for i = 0, nsnames-1 do begin
    if keyword_set(all_sites_in_one) then begin
      snamei = snames           ; this is for ASK
    endif else snamei = snames[i]
    ftj = fts[j]
    fdtj = fdts[j]
    lvlk = lvls[k]
    files = file_search(*files_ptrarr[i, j, k], count = filecount)
    If(filecount Eq 0) Then Begin
      dprint, 'Files Not Found:'
      If(ptr_valid(files_ptrarr[i, j, k])) Then Begin
        dprint,  *files_ptrarr[i, j, k]
      Endif Else dprint,  'Invalid files pointer'
      Continue                  ;no file found, go to the next
    Endif
    ; note the trailing '*' is necessary to get, for example,
    ; both tha_fgh and tha_fgh_hed, given datatype of fgh

    star = keyword_set(get_support_data) ? '*' : ''

    ;  2010-01-26 JWL: For thm_load_state, we need to disable the implied
    ;  trailing wildcard that enables support variables like tha_fgh_hed
    ;  to be autoloaded, even if only "fgh" was supplied as an input
    ;  datatype to thm_load_fgm.
    ;
    ;  But if thm_load_state requests datatype "pos", we don't necessarily
    ;  want to load "pos_gse" and "pos_gsm" even if /get_support_data
    ;  is specified.  So in thm_load_state, we'll call thm_load_xxx
    ;  with /no_implicit_wildcard, and the other load routines will
    ;  not be affected.

    if keyword_set(no_implicit_wildcard) then begin
       star = ''
    endif

    fdtj_arr = strsplit(fdtj, ' ', /extract)
    if n_elements(fdtj_arr) eq 1 then fdtj_arr = fdtj_arr[0] ; for ASK
    if keyword_set(varformat) then begin
      varformatj = varformat
    endif else if strcmp(strlowcase(type_sname), 'probe') then begin
      varformatj = strjoin('*'+fdtj_arr+star, ' ')
    endif else begin
      varformatj = strjoin('*'+fdtj_arr+'_'+snamei+star, ' ')
    endelse
    if vb ge 6 then printdat, varformatj ;;;;
    if get_cdf_data then begin
      if not keyword_set(varformat) then varformat = varformatj
      cdf_data = cdf_load_vars(*files_ptrarr[0, 0, 0], varnames = varnames, $
                               verbose = vb, /all, varformat = varformat)
      ptr_free, files_ptrarr
      return
    endif

    if keyword_set(cdf_to_tplot) then begin
      call_procedure, cdf_to_tplot, file = files, $
        all = all, verbose = vb, tplotnames = tplotnames, $
        varformat = varformatj, midfix = midfix, midpos = 4,  $
        suffix = suffix, varnames = varnames, _extra = _extra
    endif else begin
      if keyword_set(verbose) then dprint,  transpose(['Loading...', files])
      spd_cdf2tplot, file = files, all = all, verbose = vb, $
        tplotnames = tplotnames, suffix = suffix, $
        midfix = midfix, midpos = 4, varformat = varformatj
    endelse
    tn_pre_proc = tnames()

    ; clip data to requested trange, if trange exists, jmm, 2009-08-11
    If (keyword_set(trange) && n_elements(trange) Eq 2) $
      Then tr = timerange(trange) $
      else tr = timerange()

    ;explicit check for existence of tplotnames to avoid later crash, jmm, 27-aug-2009
    If(is_string(tplotnames)) Then Begin
      for ivar = 0, n_elements(tplotnames)-1 do begin ;change index variable to ivar, jmm, 28-jul-2009
        if tnames(tplotnames[ivar]) eq '' then continue
      
      ; check special case from efi loading
        if strmid(tplotnames[ivar], 16, 17, /reverse_offset) eq '_thm_cal_efi_priv' then continue
      
      ; check special case from state loading
        if strmid(tplotnames[ivar], 10, 11, /reverse_offset) eq '_state_temp' then continue
      
      ; check for scm data, skip cut until after calibration
        if strmid(tplotnames[ivar], 3, 3) eq '_sc' then continue
      
        if ~keyword_set(no_time_clip) then begin
           time_clip, tplotnames[ivar], min(tr), max(tr), /replace, error = tr_err
           if tr_err then del_data, tplotnames[ivar]
        endif
      endfor
    
      tn_post_clip = tnames()
    ; make ssl_set_intersection doesn't get scalar inputs
      if n_elements(tn_pre_proc) eq 1 then tn_pre_proc = [tn_pre_proc]
      if n_elements(tn_post_clip) eq 1 then tn_post_clip = [tn_post_clip]
      if n_elements(tplotnames) eq 1 then tplotnames = [tplotnames]

      tn_for_cal = ssl_set_intersection(tplotnames, tn_post_clip)
      if keyword_set(post_process_proc) then begin
        if keyword_set(scm_cal) then Begin
          call_procedure, post_process_proc, sname = snamei, filetype = ftj, $
            datatype = fdtj, suffix = suffix, coord = coord, $
            level = lvlk, verbose = vb, tplotnames = tplotnames, $
            progobj = progobj, proc_type = type, trange = trange, $
            scm_cal = scm_cal, get_support_data = get_support_data, $
            use_eclipse_corrections = use_eclipse_corrections, _extra = _extra
        endif else Begin
          if ~array_equal(tn_for_cal, -1L,/no_type) then $
          call_procedure, post_process_proc, sname = snamei, filetype = ftj, $
            datatype = fdtj, suffix = suffix, coord = coord, $
            level = lvlk, verbose = vb, tplotnames = tn_for_cal, $
            progobj = progobj, files = files, proc_type = type, $
            get_support_data = get_support_data, trange = trange, $
            use_eclipse_corrections = use_eclipse_corrections, no_time_clip=no_time_clip, _extra = _extra
        endelse
      endif
    
    ; make sure tplot_vars created in post_procs get added to list
      tn_post_proc = tnames()
      if n_elements(tn_post_proc) eq 1 then tn_post_proc = [tn_post_proc]
      post_proc_names = ssl_set_complement(tn_pre_proc, tn_post_proc)
      if size(post_proc_names, /type) eq 7 then tplotnames = [tplotnames, post_proc_names]

    ; clip data to requested trange, if trange exists, jmm, 2009-08-11
      for ivar = 0, n_elements(tplotnames)-1 do begin
        if tnames(tplotnames[ivar]) eq '' then continue
    
    ; check special case from efi loading
        if strmid(tplotnames[ivar], 16, 17, /reverse_offset) eq '_thm_cal_efi_priv' then continue
    
    ; check special case from state loading
        if strmid(tplotnames[ivar], 10, 11, /reverse_offset) eq '_state_temp' then continue
        if ~keyword_set(no_time_clip) then begin 
           time_clip, tplotnames[ivar], min(tr), max(tr), /replace, error = tr_err
           if tr_err then del_data, tplotnames[ivar]
        endif 
      endfor
    Endif                       ;end for If block checking for tplotnames
  endfor           ;end of loop over all snames, levels and datatypes.

  ptr_free, files_ptrarr
    
end
