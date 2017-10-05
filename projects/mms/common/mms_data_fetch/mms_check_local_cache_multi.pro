; This program will check the local cache to see if files have been downloaded.
; If they have - it will generate a "file list" of files consistent with the search.
; If not - it will produce an error flag which signifies no data is available.
;
; Lets keep this simple: assume one s/c, one instrument_id, one mode, one level, 
; and one, if any, optional descriptor
;

; PROCEDURE: MMS_CHECK_LOCAL_CACHE_MULTI
;
; PURPOSE: Checks local cache for files within a date range for a specific
;          instrument, spacecraft, descriptor, level and mode. Requires timespan
;          be set before calling.
;
; INPUT:
;   local_flist      - OPTIONAL. Name for an array of strings. This will have
;                    - names of all of the files consistent with the query.
;
;   file_flag        - OPTIONAL. (Integer) Flag which determines if data is
;                      available locally. Returns 1 if no files found.
;                      
;   sc_id            - OPTIONAL. (String) String containing spacecraft id.
;                      
;
;   instrument_id    - REQUIRED. (String) String containing instrument id.
;                      
;
;   mode             - OPTIONAL. (String) String containing MODE id.
;               
;
;   level            - OPTIONAL. (String) String containing LEVEL id.
;                      
;
;
;
; KEYWORDS:
;
;   optional_descriptor
;                    - OPTIONAL. (String) Descriptor for data product (e.g. 'bpsd' for
;                      the instrument 'dsp' provides search coil data). If not set,
;                      and the data product you are interested has a descriptor, it
;                      will not be found.
;                      
; HISTORY:
;
; 2015-03-17, FDW, to go along with mms_data_fetch.
; 2015-07-20, KAG made the code more generalized and act more like mms_data_fetch
; LASP, University of Colorado

; MODIFICATION HISTORY:
;
;-

;  $LastChangedBy: rickwilder $
;  $LastChangedDate: 2015-07-20 15:58:30 -0700 (Mon, 20 Jul 2015) $
;  $LastChangedRevision: 18185 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/mms_data_fetch/mms_check_local_cache_multi.pro $

;



pro mms_check_local_cache_multi, local_flist, file_flag, $
                               sc_id = sc_id, level=level, $
                               mode=mode, instrument_id=instrument_id, $
                               optional_descriptor=optional_descriptor

  file_flag = 0

  sc_flag = keyword_set(sc_id)
  lv_flag = keyword_set(level)
  md_flag = keyword_set(mode)
  ii_flag = keyword_set(instrument_id)
  od_flag = keyword_set(optional_descriptor)

  big_flag = total([sc_flag, lv_flag, md_flag, ii_flag, od_flag])

; How Katy does it:
; 1) use File_search to get all names inside your specified local data directory
; 2) parse out the files that match your criteria
; 3) profit

  fnames_all = file_search(!mms.local_data_dir, '*.cdf')
  
  times = time_string(timerange())
  start_string = times[0]
  end_string = times[1]
  
  strs = strsplit(start_string, '/', /extract)
  start_date = strs[0]
  start_date = strjoin(strsplit(start_date, '-',/extract))
  start_date_num = float(start_date);long(start_date)
  
  
  start_time = strs[1]
  start_time = strjoin(strsplit(start_time, ':',/extract))
  start_time_num = long(start_time)
  
  strs = strsplit(end_string, '/', /extract)
  end_date = strs[0]
  end_date = strjoin(strsplit(end_date, '-',/extract))
  end_date_num = float(end_date);long(end_date)

  end_time = strs[1]
  end_time = strjoin(strsplit(end_time, ':',/extract))  
  end_time_num = long(end_time)
  start_string = start_date+start_time
  end_string = end_date+end_time
  
;  start_num = float(start_string)
;  end_num = float(end_string)
  
;  date_strings = mms_convert_timespan_to_date()
;  start_date = date_strings.start_date
;  end_date = date_strings.end_date
  mms_parse_file_name, fnames_all, fsc_ids, finst_ids, fmodes, flevels, $
    fd_types, fversion_strings, fstart_strings, fyears, /contains_dir
  
  fdates = strmid(fstart_strings, 0, 8)
  ftimes = strmid(fstart_strings, 8, 6)
  fdaten = float(fdates)
  ftimen = long(ftimes)
  
  if end_date_num eq start_date_num then end_date_num = end_date_num +1D
  
  dind = where(fdaten ge start_date_num and fdaten lt end_date_num)

  if total(dind) eq -1 then begin
    dprint, 'NO FILES MATCH INPUT DATES'
    file_flag = 1
    return
  endif
  
  fnames = fnames_all[dind]
  ftimen = ftimen[dind]
  if start_time_num ne 0 or end_time_num ne 0 then begin   
    tind = where(ftimen ge start_time_num and ftimen lt end_time_num)
    if total(tind) eq -1 then begin
      dprint, 'NO FILES MATCH INPUT DATES AND TIMES'
      PRINT, 'Consider widening timeframe'
      file_flag = 1
      return
    endif
    fnames = fnames[tind]
  endif

  if sc_flag eq 1 then begin
    mms_parse_file_name, fnames, fsc_ids, finst_ids, fmodes, flevels, $
      fd_types, fversion_strings, fstart_strings, fyears, /contains_dir

    nsc = n_elements(sc_id)
    sc_ind = []
    for s=0, nsc-1 do begin
      sc = sc_id[s]
      ind = where(fsc_ids eq sc)
      sc_ind = [sc_ind, ind]
    endfor
    if total(sc_ind) eq -1 then begin
      dprint, 'NO FILES FOUND MATCHING CRITERIA'
      RETURN
    endif

    fnames = fnames[sc_ind]
  endif
    
  if md_flag eq 1 then begin
    mms_parse_file_name, fnames, fsc_ids, finst_ids, fmodes, flevels, $
      fd_types, fversion_strings, fstart_strings, fyears, /contains_dir

    nmd = n_elements(mode)
    md_ind = []
    for m=0, nmd-1 do begin
      md = mode[m]
      ind = where(fmodes eq md)
      md_ind = [md_ind, ind]
    endfor
    if total(md_ind) eq -1 then begin
      dprint, 'NO FILES FOUND MATCHING CRITERIA'
      file_flag = 1
      RETURN
    endif
    fnames = fnames[md_ind]
  endif

  if lv_flag eq 1 then begin
    mms_parse_file_name, fnames, fsc_ids, finst_ids, fmodes, flevels, $
      fd_types, fversion_strings, fstart_strings, fyears, /contains_dir

    nlv = n_elements(level)
    lv_ind = []
    for l=0, nlv-1 do begin
      lv = level[l]
      ind = where(flevels eq lv)
      lv_ind = [lv_ind, ind]
    endfor
    if total(lv_ind) eq -1 then begin
      dprint, 'NO FILES FOUND MATCHING CRITERIA'
      file_flag = 1
      RETURN
    endif    
    fnames = fnames[lv_ind]
  endif

  if ii_flag eq 1 then begin
    mms_parse_file_name, fnames, fsc_ids, finst_ids, fmodes, flevels, $
      fd_types, fversion_strings, fstart_strings, fyears, /contains_dir

    nii = n_elements(instrument_id)
    ii_ind = []
    for i=0, nii-1 do begin
      ii = instrument_id[i]
      ind = where(finst_ids eq ii)
      ii_ind = [ii_ind, ind]
    endfor
    if total(ii_ind) eq -1 then begin
      dprint, 'NO FILES FOUND MATCHING CRITERIA'
      file_flag=1
      RETURN
    endif
    fnames = fnames[ii_ind]
  endif
  
  if od_flag eq 1 then begin
    mms_parse_file_name, fnames, fsc_ids, finst_ids, fmodes, flevels, $
      fd_types, fversion_strings, fstart_strings, fyears, /contains_dir

    nod = n_elements(optional_descriptor)
    od_ind = []
    for o=0, nod-1 do begin
      od = optional_descriptor[o]
      ind = where(fd_types eq od)
      od_ind = [od_ind, ind]
    endfor
    if total(od_ind) eq -1 then begin
      dprint, 'NO FILES FOUND MATCHING CRITERIA'
      file_flag = 1
      RETURN
    endif
    fnames = fnames[od_ind]
  endif
    
    
  local_flist = fnames
;stop
;; Convert start date
;  start_year_str = strmid(start_date, 0, 4)
;  start_year = fix(start_year_str)
;  start_month = fix(strmid(start_date, 5, 2))
;  start_day = fix(strmid(start_date, 8, 2))
;  start_jul = julday(start_month, start_day, start_year, 0, 0, 0)
;
;; Convert end date
;  end_year = fix(strmid(end_date, 0, 4))
;  end_month = fix(strmid(end_date, 5, 2))
;  end_day = fix(strmid(end_date, 8, 2))
;  end_jul = julday(end_month, end_day, end_year, 0, 0, 0)
;
;  if start_year ne end_year then file_flag = 1
;
;
;stop
;
;;if big_flag eq 0 then begin
;;  dprint, 'No criteria input, returning every single file name in your specified local data directory'
;;  local_flist = fnames
;;  return
;;endif
;
;
;;mms_init
;
;
;;
;;file_flag = 0  
;;
;;num_optional = n_elements(optional_descriptor)
;;
;;if num_optional eq 0 then optional_descriptor = ''
;;
;;if num_optional gt 1 then file_flag = 1
;;
;;;num_instruments = n_elements(instrument_id)
;;;if num_instruments eq 0 then file_flag = 1
;;;
;;;num_modes = n_elements(mode)
;;;if num_modes eq 0 then file_flag = 1
;;;
;;;if num_levels eq 0 then file_flag = 1
;;;num_levels = n_elements(level)
;;
;
;; Check only over a day boundary
;;if end_jul-start_jul gt 86400 then file_flag = 1
;
;;lastpos = strlen(local_dir)
;;if strmid(local_dir, lastpos-1, lastpos) eq path_sep() then begin
;;  data_dir = local_dir + 'data' + path_sep() + 'mms' + path_sep()
;;endif else begin
;;  data_dir = local_dir + path_sep() + 'data' + path_sep() + 'mms' + path_sep()
;;endelse
;
;;data_dir = !MMS.LOCAL_DATA_DIR
;;
;;if file_flag eq 0 then begin
;;      ; First, get the directory to search
;;  if strlen(optional_descriptor) eq 0 then begin
;;      
;;    file_dir = filepath('', root_dir=data_dir, $
;;      subdirectory = [sc_id, level, mode, instrument_id, start_year_str])
;;      
;;  endif else begin
;;    
;;    file_dir = filepath('', root_dir=data_dir, $
;;      subdirectory = [sc_id, level, mode, instrument_id, optional_descriptor, start_year_str])
;;      
;;    endelse
;;    
;;  search_string = file_dir + '*.cdf'
;;  search_results = file_search(search_string)
;;    
;;  if n_elements(search_results) eq 1 and search_results(0) eq '' then begin
;;    local_flist = ''
;;    file_base = ''
;;    file_flag = 1
;;  endif else begin
;;    ; Parse search results to extract times
;;    
;;    cut_filenames = strarr(n_elements(search_results))
;;    file_bases = cut_filenames
;;    for i = 0, n_elements(search_results)-1 do begin
;;      slash = strpos(search_results(i), path_sep(), /reverse_search)
;;      cut_filenames(i) = strmid(search_results(i), slash+1, strlen(search_results(i))-slash-1)
;;      first_space = strpos(cut_filenames(i), '_', /reverse_search)
;;      file_bases(i) = strmid(cut_filenames(i), 0, first_space)
;;    endfor
;;    
;;    mms_parse_file_name, cut_filenames, fsc_ids, finst_ids, fmodes, flevels, $
;;                         foptional_descriptors, fversion_strings, fstart_strings, fyears   
;;                                            
;;    ; Now parse the start string
;;    mms_parse_start_string, fstart_strings, fmonths, fdays, fyears, fhours, fminutes, fseconds
;;    
;;    ; Convert to julian days
;;    fstart_juls = julday(fmonths, fdays, fyears, fhours, fminutes, fseconds)
;;    
;;    ; Identify files within start and end time
;;    loc_match = where(fstart_juls ge start_jul and fstart_juls le end_jul, count_match)
;;        
;;    if count_match gt 0 then begin
;;      local_flist = search_results(loc_match)
;;      match_cuts = cut_filenames(loc_match)
;;      file_base = file_bases(loc_match)      
;;      
;;    endif else begin
;;      local_flist = ''
;;      file_base = ''
;;      file_flag = 1
;;    endelse
;;    
;;  endelse
;;    
;;  
;;endif else begin
;;  local_flist = ''
;;  file_base = ''
;;  file_flag = 1
;;endelse






end