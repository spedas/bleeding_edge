; New wrapper which combines mms_data_fetch and mms_check_local_cache routines.
; Done to avoid confusion between online routine (mms_data_fetch) and offline routine (mms_check_local_cache).
; 
; PROCEDURE: MMS_FIND_SCIENCE_FILES
;
; PURPOSE: Checks SDC and local cache for files within a date range for a specific
;          instrument, spacecraft, descriptor, level and mode. Requires timespan
;          be set before calling. If mms_init not called ahead of this routine,
;          we will default to ~/data/mms for the local data directory.
;
; INPUT:
;   local_flist      - REQUIRED. Name for an array of strings. This will have
;                    - names of all of the files consistent with the query.
;
;   fail_flag        - REQUIRED. (Integer) Flag which determines if data is
;                      available. Returns 1 if no files found.
;
;   sc_id            - REQUIRED. (String) String containing spacecraft id.
;                      Only one is allowed at a time.
;
;   instrument_id    - REQUIRED. (String) String containing instrument id.
;                      Only one is allowed at a time.
;
;   mode             - REQUIRED. (String) String containing instrument id.
;                      Only one is allowed at a time.
;
;   level            - REQUIRED. (String) String containing instrument id.
;                      Only one is allowed at a time.
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
;   no_update        - OPTIONAL. Set if you don't wish to replace earlier file versions
;                      with the latest version. If not set, earlier versions are deleted
;                      and replaced.
;
;   reload           - OPTIONAL. Set if you wish to download all files in query, regardless
;                      of whether file exists locally. Useful if obtaining recent data files
;                      that may not have been full when you last cached them.
;
;                      NOTE: no_update and reload should NEVER be simultaneously set. Will
;                      give an error if it happens.

;
; HISTORY:
;
; 2015-03-17, FDW, to go along with mms_data_fetch.
; LASP, University of Colorado

; MODIFICATION HISTORY:
;
;-

;  $LastChangedBy: rickwilder $
;  $LastChangedDate: 2015-07-22 12:53:11 -0700 (Wed, 22 Jul 2015) $
;  $LastChangedRevision: 18206 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/mms_data_fetch/mms_find_science_files.pro $

;



pro mms_find_science_files, local_flist, fail_flag, $
  sc_id, instrument_id, mode, level, descriptor=descriptor, no_update=no_update, reload=reload
  
  
fail_flag = 0
; first, check if valid sc_id

sc_id=strlowcase(sc_id) ; this turns any data type to a string
if sc_id ne 'mms1' and sc_id ne 'mms2' and sc_id ne 'mms3' and sc_id ne 'mms4' then begin
  message,"Invalid spacecraft id. Using default spacecraft mms1.",/continue
  sc_id='mms1'
endif

; check if valid level

t = timerange(/current)
st = time_string(t)
start_date = strmid(st[0],0,10)
end_date = strmatch(strmid(st[1],11,8),'00:00:00')?strmid(time_string(t[1]-10.d0),0,10):strmid(st[1],0,10)

;on_error, 2
if keyword_set(no_update) and keyword_set(reload) then message, 'ERROR: Keywords /no_update and /reload are ' + $
  'conflicting and should never be used simultaneously.'

; First - use the online routine, mms_data_fetch, which will obtain a list of files within the timespan from the
; and download the files if the file size or version number doesn't match

if keyword_set(descriptor) then begin
  if keyword_set(no_update) then begin
    mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc_id, $
      instrument_id=instrument_id, mode=mode, $
      level=level, optional_descriptor=descriptor, /no_update
  endif else begin
    if keyword_set(reload) then begin
      mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc_id, $
      instrument_id=instrument_id, mode=mode, $
      level=level, optional_descriptor=descriptor, /reload
    endif else begin
      mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc_id, $
      instrument_id=instrument_id, mode=mode, $
      level=level, optional_descriptor=descriptor
    endelse
  endelse
endif else begin
  if keyword_set(no_update) then begin
    mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc_id, $
      instrument_id=instrument_id, mode=mode, $
      level=level, /no_update
  endif else begin
    if keyword_set(reload) then begin
      mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc_id, $
      instrument_id=instrument_id, mode=mode, $
      level=level, /reload
    endif else begin
      mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc_id, $
      instrument_id=instrument_id, mode=mode, $
      level=level
    endelse
  endelse
endelse

; First, warn user if some of the downloads timed out.
loc_fail = where(download_fail eq 1, count_fail)

if count_fail gt 0 then begin
  loc_success = where(download_fail eq 0, count_success)
  warning_string, 'Some of the ' + instrument_id + ' downloads from the SDC timed out. Try again later if plot is missing data.'
  print, warning_string
  if count_success gt 0 then begin
    local_flist = local_flist(loc_success)
  endif else if count_success eq 0 then begin
    login_flag = 1
  endif
endif

; Now, if for some reason the connection to the SDC failed (incorrect password, no internet connection),
; we will use the offline routine mms_check_local_cache as a backup.

file_flag = 0
if login_flag eq 1 then begin
  warning_string = 'Unable to locate ' + instrument_id + ' files on the SDC server, checking local cache...'
  print, warning_string
  
  if keyword_set(descriptor) then begin
    
    mms_check_local_cache, local_flist, file_flag, $
      mode, instrument_id, level, sc_id, optional_descriptor=descriptor

;    mms_check_local_cache_multi, local_flist, file_flag, $
;      sc_id = sc_id, level=level, $
;      mode=mode, instrument_id=instrument_id, $
;      optional_descriptor=descriptor
      
  endif else begin
    
;    mms_check_local_cache_multi, local_flist, file_flag, $
;      sc_id = sc_id, level=level, $
;      mode=mode, instrument_id=instrument_id
      
    mms_check_local_cache, local_flist, file_flag, $
      mode, instrument_id, level, sc_id
  endelse
endif

; Now, if we found the files, lets re-sort them in chronological order

if login_flag eq 0 or file_flag eq 0 then begin
  ; We can safely verify that there is some data file to open, so lets do it

  if n_elements(local_flist) gt 1 then begin
    local_flist = mms_sort_filenames_by_date(local_flist)
  endif 
  
endif else begin
  warning_string = 'No ' + instrument_id + ' data available for timerange specified or invalid query!'
  print, warning_string
  fail_flag = 1
endelse

end
