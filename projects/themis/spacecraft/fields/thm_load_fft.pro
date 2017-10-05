;+
;Procedure: THM_LOAD_FFT
;
;Purpose:  Loads THEMIS FFT spectra (ParticleBurst and WaveBurst) data
;
;keywords:
;  probe = Probe name. The default is 'all', i.e., load all available probes.
;          This can be an array of strings, e.g., ['a', 'b'] or a
;          single string delimited by spaces, e.g., 'a b'
;  datatype = The type of data to be loaded, can be an array of strings 
;          or single string separate by spaces.  The default is 'all'
;  TRANGE= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded
;  level = the level of the data, the default is 'l1', or level-1
;          data. A string (e.g., 'l2') or an integer can be used. 'all'
;          can be passed in also, to get all levels.
;  type=   'raw' or 'calibrated'. default is calibrated.
;  suffix= suffix to add to output data quantity (not added to support
;  data)
;  relpathnames_all: named variable in which to return all files that are
;          required for specified timespan, probe, datatype, and level.
;          If present, no files will be downloaded, and no data will be loaded.
;  files   named varible for output of pathnames of local files.
;  CDF_DATA: named variable in which to return cdf data structure: only works
;          for a single spacecraft and datafile name.
;  VARNAMES: names of variables to load from cdf: default is all.
;  /GET_SUPPORT_DATA: load support_data variables as well as data variables 
;                      into tplot variables.
;  /DOWNLOADONLY: download file but don't read it.
;  /VALID_NAMES: if set, then this routine will return the valid
;  probe, datatype and/or level options in named variables supplied as 
;  arguments to the corresponding keywords.
;  /NO_DOWNLOAD: use only files which are online locally.
;  /VERBOSE  set to output some useful info
;  /NO_TIME_CLIP: Disables time clipping, which is the default
;Example:
;   thm_load_fft,/get_suppport_data,probe=['a', 'b']
;Notes:
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2016-11-16 15:45:58 -0800 (Wed, 16 Nov 2016) $
; $LastChangedRevision: 22364 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/thm_load_fft.pro $
;-

;this procedure is a callback(higher order) procedure which is passed
;as an argument to thm_load_xxx
;it removes any suffixes from support data,
;sets dlimit.data_att.data_type
;and calls calibration fx
pro thm_load_fft_post, sname=probe, datatype=dt, level=lvl, $
                       tplotnames=tplotnames, $
                       suffix=suffix, proc_type=proc_type, coord=coord, $
                       delete_support_data = delete_support_data, $
                       _extra=_extra


  if not keyword_set(suffix) then suffix = ''
  ;; remove suffix from support data
  ;; and add DLIMIT tags to data quantities
  for l=0, n_elements(tplotnames)-1 do begin    
     tplot_var = tplotnames[l]

     get_data, tplot_var, data=d_str, limit=l_str, dlimit=dl_str
     ;;if we're not dealing with support data
     ;;set the proper dlimit attributes to make pretty plots
     ;;(right now we don't do anything 'cept set the data type)
     if size(/type,dl_str) eq 8 && dl_str.cdf.vatt.var_type eq 'data' $
     then begin
       if strmatch(lvl, 'l1') then begin
         data_att = { data_type:'raw'}
         
       end else if strmatch(lvl, 'l2') then begin
         data_att = { data_type:'calibrated'}
       end

       str_element, dl_str, 'data_att', data_att, /add
       store_data, tplot_var, data = d_str, limit = l_str, dlimit = dl_str

     endif else begin
        ;; for support data,
        ;; rename original variable to exclude suffix
        if n_elements(tplot_var_list) gt 0 then begin
          tplot_var_list = [tplot_var_list,tplot_var]
        endif else begin
          tplot_var_list = [tplot_var]
        endelse       
        if keyword_set(suffix) then begin
           tplot_var_root = strmid(tplot_var, 0, $
                                   strpos(tplot_var, suffix, /reverse_search))
          ; store_data, delete=tplot_var
           if tplot_var_root then begin
             store_data, tplot_var_root, data = d_str, limit = l_str, dlimit = dl_str
             if n_elements(tplot_var_root_list) gt 0 then begin
               tplot_var_root_list = [tplot_var_root_list,tplot_var_root]
             endif else begin
               tplot_var_root_list = [tplot_var_root]
             endelse
           endif
           tplot_var = tplot_var_root
         endif

     endelse
  endfor

  ;; calibrate, if this is L1
  if strmatch(lvl, 'l1') then begin
     if ~keyword_set(proc_type) || strmatch(proc_type, 'calibrated') then begin
        thm_cal_fft, probe=probe, datatype=dt, $
          in_suffix = suffix, out_suffix = suffix

        ;delete original
        if keyword_set(delete_support_data) then begin
          if n_elements(tplot_var_list) gt 0 then del_data, tplot_var_list
          if n_elements(tplot_var_root_list) gt 0 then del_data, tplot_var_root_list
        endif else begin  
          if keyword_set(suffix) && n_elements(tplot_var_root_list) gt 0 then del_data, tplot_var_root_list  
        endelse
     endif
  endif
  
;; set units and coordinates from CDF attributes for L2, then set some
;; tplot options for plotting
  if strmatch(lvl, 'l2') then begin
    spd_new_units, tplotnames
    spd_new_coords, tplotnames
    options, tplotnames, 'zlog', 1
    options, tplotnames, 'ylog', 1
    options, tplotnames, 'ystyle', 1
;Also remove 0 values and fill with NaN values, and set yrange
    For j = 0, n_elements(tplotnames)-1 Do Begin
      get_data, tplotnames[j], data = ddd
      If(is_struct(ddd)) Then Begin
        zv = where(ddd.y Eq 0, nzv)
        If(nzv Gt 0) Then ddd.y[zv] = !values.f_nan
        store_data, tplotnames[j], data = temporary(ddd)
        tk = strpos(tplotnames[j], 'eac')
        If(tk[0] Ne -1) Then options, tplotnames[j], 'yrange', [ 10., 8192.] $
        Else options, tplotnames[j], 'yrange', [ 10., 4096.]
      Endif
    Endfor
  endif

  
end

;the main proc
pro thm_load_fft,probe=probe,$
                 datatype = datatype, $
                 trange = trange, $
                 level=level, $
                 verbose = verbose, $
                 downloadonly = downloadonly, $
                 relpathnames_all = relpathnames_all, $
                 no_download = no_download,  $
                 cdf_data=cdf_data, $
                 get_support_data = get_support_data, $
                 delete_support_data = delete_support_data, $
                 varnames=varnames, $
                 valid_names = valid_names, $
                 files = files, $
                 suffix = suffix, $
                 type = type, $
                 progobj=progobj, $
                 _extra = _extra

   
  if ~keyword_set(probe) then probe = ['a', 'b', 'c', 'd', 'e']

  if(keyword_set(type)) then begin
      keep_type = strlowcase(strcompress(type, /remove_all))
  endif else keep_type = 'calibrated'
  
  if not keyword_set(suffix) then suffix = ''
      
  vlevels = 'l1 l2'
  deflevel = 'l1'
  lvl = thm_valid_input(level, 'Level', vinputs = vlevels, definput = deflevel,format="('l', I1)", verbose=0)

  if lvl eq '' then return                            
      
  vsnames = 'a b c d e f'
  
  ;construct valid datatype list
  valid_raw = [ 'fff_16', 'fff_32', 'fff_64', 'ffp_16', 'ffp_32', 'ffp_64', 'ffw_16', 'ffw_32', 'ffw_64']
   
  valid_calibrated = [ 'v1', 'v2', 'v3', 'v4', 'v5', 'v6', $
                       'edc12', 'edc34', 'edc56', $
                       'scm1', 'scm2', 'scm3', $
                       'eac12', 'eac34', 'eac56', $
                       'undef', $
                       'eperp', 'epara', 'dbperp', 'dbpara']

  valid_support = ['adc','src','hed']

  valid_calibrated = array_cross(valid_raw, [valid_calibrated,valid_support])

  valid_calibrated = reform(valid_calibrated[0, *] + '_' + valid_calibrated[1, *])

  valid_datatypes = ssl_set_union(valid_calibrated, valid_raw)


  if(keyword_set(probe)) then $
    p_var = probe

  ;validate inputs
  if not keyword_set(datatype) then begin
    datatype = valid_datatypes
  endif else begin
    datatype = ssl_check_valid_name(strlowcase(datatype),valid_datatypes,/include_all, $
                                    invalid=msg_dt, type='data type')
  endelse
  
  if(size(datatype,/n_dim) eq 0 && datatype eq '') then return
     
  if not keyword_set(p_var) then begin
    p_var = strsplit(vsnames,' ',/extract)
  endif else begin 
    p_var = ssl_check_valid_name(strlowcase(p_var),strsplit(vsnames,' ',/extract), $
                                 /include_all, invalid=msg_sname, type='probe')
  endelse
  probe = p_var
  
  if(size(p_var,/n_dim) eq 0 && p_var eq '') then return

  if arg_present(relpathnames_all) then begin
    downloadonly = 1
    no_download = 1
  end

  if lvl eq 'l1' then begin
    ;; default action for loading level 1 is to calibrate, so get support data
    if not keyword_set(get_support_data) then begin 
      get_support_data = 1
      delete_support_data = 0   ;this is handled later in the routine, so do not pass this to thm_load_xxx, jmm, 24-mar-2011
      yes_we_want_support_data = 0b
    endif else yes_we_want_support_data = 1b
  endif

  ;if a calibrated datatype is requested the raw data types must be loaded
  if(lvl eq 'l1') then begin

    isect = ssl_set_intersection(datatype, valid_calibrated)

    if(size(isect, /n_dim) ne 0) then dt = ssl_set_union(datatype, valid_raw) $
    else dt = datatype
     
  endif else dt = datatype

  p = vsnames

  l = lvl

  vl = vlevels

  thm_load_xxx, sname = p_var, $
    datatype = dt, $
    trange = trange, $
    level = l, $
    verbose = verbose, $
    downloadonly = downloadonly, $
    cdf_data = cdf_data, $
    get_cdf_data = arg_present(cdf_data), $
    get_support_data = get_support_data, $
    delete_support_data = delete_support_data, $
    varnames = varnames, $
    valid_names = valid_names, $
    files = files, $
    vsnames = p, $
    type_sname = 'probe', $
    vdatatypes = strjoin(valid_datatypes, ' '), $
    file_vdatatypes = strjoin(congrid(valid_raw, n_elements(valid_datatypes), /center), ' '), $
    file_vL2datatypes = 'fft', $
    vlevels = vl, $
    deflevel = deflevel, $
    version = 'v01', $
    progobj = progobj, $
    post_process_proc = 'thm_load_fft_post', $
    proc_type = type, $
    vtypes = 'raw calibrated', deftype = 'calibrated', $
    suffix = suffix, $
    relpathnames_all = relpathnames_all, $
    no_download = no_download, $
    _extra = _extra

  ;retain datatype if single argument was passed in
  if n_elements(p_var) eq 1 then probe = p_var[0] else $
  probe=p_var
  ;delete unrequested data, if necessary
  if(lvl eq 'l1' and not keyword_set(valid_names)) then begin
      If(keep_type Ne 'raw') Then Begin
          valid_support = array_cross(valid_raw, valid_support)
          valid_support = reform(valid_support[0, *] + '_' + valid_support[1, *])
          valid_raw_support = [valid_raw, valid_support]
      Endif Else valid_raw_support = valid_support
      If(yes_we_want_support_data) Then Begin
;This line is here because when you do want support data, you only
;want it for the datatypes that you loaded, but it doesn't work
;          list = ssl_set_complement(ssl_set_intersection(datatype, valid_raw_support), valid_raw_support)
	base_datatype=strmid(datatype, 0, 6)
        support_data_to_keep = array_cross(base_datatype, ['_adc', '_src', '_hed'])
	support_data_to_keep = reform(support_data_to_keep[0,*]+support_data_to_keep[1,*])
	list = ssl_set_complement(support_data_to_keep, valid_raw_support)
      Endif Else list = valid_raw_support ;otherwise, ditch it all
      if(size(list, /n_dim) eq 0 && list eq -1L) then goto, exit_sequence
      var_list = array_cross(p_var, list)
      var_strings = reform('th' + var_list[0, *] + '_' + var_list[1, *])
      for i = 0, n_elements(var_strings) -1L do begin
;this is needed because support data does not have the suffix, but raw data does
          if(tnames(var_strings[i]) ne '') then del_data, var_strings[i] $
          else if(tnames(var_strings[i]+suffix) ne '') then del_data, var_strings[i]+suffix
      endfor
  endif
  ;needed to return valid names correctly
  exit_sequence: 
  level = l

  ;retain datatype if single argument was passed in
  ;and no raw quantities were added
  if n_elements(dt) eq 1 then datatype = dt[0] else $
  datatype = dt

  ;notify user of partially invalid input
  if keyword_set(msg_sname) then dprint, dlevel=1, msg_sname
  if keyword_set(msg_dt) then dprint, dlevel=1, msg_dt

end
