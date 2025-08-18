;+
;Procedure: THM_LOAD_FBK
;
;Purpose:  Loads THEMIS FilterBank data
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
;  suffix= suffix to add to output data quantity 
;  relpathnames_all: named variable in which to return all files that are
;          required for specified timespan, probe, datatype, and level.
;          If present, no files will be downloaded, and no data will be loaded.
;          and/or level options in named variables supplied as 
;          arguments to the corresponding keywords.
;  files   named varible for output of pathnames of local files.
;  CDF_DATA: named variable in which to return cdf data structure: only works
;          for a single spacecraft and datafile name.
;  VARNAMES: names of variables to load from cdf: default is all.
;  /GET_SUPPORT_DATA: load support_data variables as well as data variables 
;                      into tplot variables.
;  /DOWNLOADONLY: download file but don't read it.
;  /VALID_NAMES, if set, then this routine will return the valid
;  probe, datatype
;  /NO_DOWNLOAD: use only files which are online locally.
;  /VERBOSE  set to output some useful info
;  /NO_TIME_CLIP: Disables time clipping, which is the default
;Example:
;   thg_load_fbk,/get_suppport_data,probe=['a', 'b']
;Notes:
; Added the new frequency center values, 24-oct-2008, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: nikos $
; $LastChangedDate: 2016-11-16 15:45:58 -0800 (Wed, 16 Nov 2016) $
; $LastChangedRevision: 22364 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/thm_load_fbk.pro $
;-

pro thm_load_fbk_post, sname = probe, datatype = dt, level = lvl, $
                       tplotnames = tplotnames, $
                       suffix = suffix, proc_type = proc_type, coord = coord, $
                       delete_support_data = delete_support_data, $
                       files = files, _extra = _extra


  ;; remove suffix from support data
  ;; and add DLIMIT tags to data quantities
  for l = 0, n_elements(tplotnames)-1 do begin    
    tplot_var = tplotnames[l]
    get_data, tplot_var, data = d_str, limit = l_str, dlimit = dl_str
    ;;if we're not dealing with support data
    if size(/type,dl_str) eq 8 && dl_str.cdf.vatt.var_type eq 'data' $
      then begin
      if strmatch(lvl, 'l1') then begin
        data_att = { data_type:'raw'}
      end else if strmatch(lvl, 'l2') then begin
        unit = dl_str.cdf.vatt.units
        coord_sys = 'none'
        data_att = { data_type:'calibrated', coord_sys:coord_sys, $
                     units:unit}
                                ;labels omitted , differ for fbk data from fgm example
      end
      str_element, dl_str, 'data_att', data_att, /add
      store_data, tplot_var, data = d_str, limit = l_str, dlimit = dl_str
    endif else begin
      
      ;; save name of support tplot variable for possible deletion
      if tplot_var && keyword_set(delete_support_data) then begin
        if size(support_var_list, /type) eq 0 then $
          support_var_list = [tplot_var] $
        else $
          support_var_list = [support_var_list, tplot_var] 
      endif
    endelse
  endfor
  
  ;; calibrate, if this is L1
  if strmatch(lvl, 'l1') then begin
    if ~keyword_set(proc_type) || strmatch(proc_type, 'calibrated') then begin
      thm_cal_fbk, probe = probe, datatype = dt, $
        in_suffix = suffix, out_suffix = suffix
      ;; delete support data 
      if size(support_var_list, /type) ne 0 then $
        del_data, support_var_list     
    endif
; Pick up correct frequency bands for variables
    cdfi = cdf_load_vars(files, var_type = 'support_data')
    If(is_struct(cdfi)) Then Begin ;if we can't read the files, then there's no data
      fvar = where(strmatch(cdfi.vars.name, 'th?_fbk_fcenter'))
      If(fvar[0] Ne -1) Then Begin
        If(ptr_valid(cdfi.vars[fvar].dataptr)) Then fcenter_values = *cdfi.vars[fvar].dataptr $
        Else fcenter_values = [2689.0, 572.0, 144.2, 36.2, 9.05, 2.26]
;Note that these default values are the actual values as of
;24-oct-2008 reprocessing, but as long as correct values are included
;in the files, these will never be used. jmm
      Endif
      fbk_vars = tnames('th'+probe[0]+'_fb_*') ;these are the calibrated L1 or L2 vars
      nfbk = n_elements(fbk_vars)
      For j = 0, nfbk-1 Do Begin ;for each variable, replace d.v if it exists and has 6 elements
        get_data, fbk_vars[j], data = d
        If(is_struct(d)) Then Begin
          If(tag_exist(d, 'v') && n_elements(d.v) Eq n_elements(fcenter_values)) Then Begin
            d.v = fcenter_values
            store_data, fbk_vars[j], data = temporary(d)
          Endif
        Endif
      Endfor
    Endif

  endif


end

pro thm_load_fbk,probe=probe, $
                 datatype = datatype, $
                 trange = trange, $
                 level=level, $
                 verbose = verbose, $
                 downloadonly = downloadonly, $
                 no_download = no_download, $
                 relpathnames_all = relpathnames_all, $
                 cdf_data=cdf_data, $
                 get_support_data = get_support_data, $
                 varnames=varnames, $
                 valid_names = valid_names, $
                 files = files, $
                 suffix = suffix, $
                 type = type, $
                 progobj = progobj, $
                 _extra = _extra

  if ~keyword_set(probe) then probe = ['a', 'b', 'c', 'd', 'e']

  if(keyword_set(type)) then $
    dprint, 'type keyword ignored for fb data'

  if not keyword_set(suffix) then suffix = ''
    
  vlevels = 'l1 l2'
  deflevel = 'l1'
  lvl = thm_valid_input(level, 'Level', vinputs = vlevels, definput = deflevel,format="('l', I1)", verbose=0)

  if lvl eq '' then return                            

  ;construct valid datatype list
  valid_raw = ['fb1', 'fb2', 'fbh']

  valid_calibrated =  'fb_' + ['v1', 'v2', 'v3', 'v4', 'v5', 'v6','edc12', 'edc34', 'edc56', $
                     'scm1', 'scm2', 'scm3', 'eac12', 'eac34', 'eac56', 'hff']

  valid_datatypes = ssl_set_union(valid_raw, valid_calibrated)

  vsnames =  'a b c d e'

  ;validate inputs
  if not keyword_set(datatype) then begin
    datatype = valid_datatypes
  endif else begin
    datatype = ssl_check_valid_name(strlowcase(datatype),valid_datatypes,/include_all, $
                                    invalid=msg_dt, type='data type')
  endelse
  
  if(size(datatype,/n_dim) eq 0 && datatype eq '') then return
  
  if(keyword_set(probe)) then myprobe = probe   
  if not keyword_set(myprobe) then begin
    myprobe = strsplit(vsnames,' ',/extract)
  endif else begin
    myprobe = ssl_check_valid_name(strlowcase(myprobe),strsplit(vsnames,' ',/extract), $
                                /include_all, invalid=msg_sname, type='probe')
  endelse
  probe=myprobe
  
  if(size(myprobe,/n_dim) eq 0 && myprobe eq '') then return

  if arg_present(relpathnames_all) then begin
     downloadonly=1
     no_download=1
   end

   if lvl eq 'l1' then begin
     ;; default action for loading level 1 is to calibrate, so get support data
     if not keyword_set(get_support_data) then begin
       get_support_data = 1
       delete_support_data = 1
     endif
   endif

  ;if a calibrated datatype is requested the raw data types must be loaded
  if(lvl eq 'l1') then begin

    isect = ssl_set_intersection(datatype, valid_calibrated)

    if(size(isect, /n_dim) ne 0) then dt = ssl_set_union(datatype, valid_raw) $
    else dt = datatype
     
  endif else dt = datatype

  l = lvl

  thm_load_xxx,sname=myprobe, $
               datatype = dt, $
               trange = trange, $
               level=l, $
               verbose = verbose, $
               downloadonly = downloadonly, $
               cdf_data=cdf_data, $
               get_cdf_data = arg_present(cdf_data), $
               get_support_data=get_support_data, $
               delete_support_data = delete_support_data, $
               varnames=varnames, $
               valid_names = valid_names, $
               files = files, $
               vsnames = vsnames, $
               type_sname = 'probe', $
               vdatatypes =  strjoin(valid_datatypes,' '), $
               file_vdatatypes = 'fbk', $
               vlevels = vlevels, $
               vL2datatypes =  strjoin(valid_calibrated,' '), $
               deflevel = deflevel, $
               version = 'v01', $
               progobj=progobj, $
               post_process_proc = 'thm_load_fbk_post', $
               proc_type = type, $
               vtypes='raw calibrated', deftype = 'calibrated', $
               suffix = suffix, $
               relpathnames_all = relpathnames_all, $
               no_download = no_download, $
               _extra = _extra


  ;delete unrequested data
  if(lvl eq 'l1' and not keyword_set(valid_names)) then begin

    list = ssl_set_complement(ssl_set_intersection(datatype, valid_raw),valid_raw)

    if(size(list, /n_dim) eq 0 && list eq -1L) then return

    var_list = array_cross(probe, list)

    var_strings = reform('th' + var_list[0, *] + '_' + var_list[1, *] + suffix)
    
    for i = 0, n_elements(var_strings) -1L do begin
      if(tnames(var_strings[i]) ne '') then del_data, var_strings[i]
    endfor

  endif

  ;needed to return valid names correctly
  level = l

  datatype = dt
  
  ;notify user of partially invalid input
  if keyword_set(msg_sname) then dprint, dlevel=1, msg_sname
  if keyword_set(msg_dt) then dprint, dlevel=1, msg_dt

end
