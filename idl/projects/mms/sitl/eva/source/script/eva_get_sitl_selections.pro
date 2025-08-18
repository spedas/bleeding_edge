;+
; NAME:  eva_get_sitl_selections
;
; PURPOSE:
;   To download SITL-selection files (max 10000 files) for a defined time period 
;   and return those filenames. If the time period is not defined, 
;   the latest file will be downloaded. The file timestamps can 
;   also be returned (i.e., the time the SITL submitted the selections)
;
; CALLING SEQUENCE: filenames = eva_get_sitl_selections(trange=trange [, num] )
;
; INPUT:
;    trange: (optional, either string or double)
;       - The time range from which SITL selection files are searched.
;       - The file stamps (i.e., the time the SITL submitted the
;         selections) are used for the search. 
;       - If omitted, the latest file will be searched.                     
;
; OUTPUT:
;    filenames: a string array indicating the filenames of matched SITL-selections.
;
; OTHER OUTPUT:
;    n         : the number of matched files.
;    filetimes: the time stamps (i.e., the time the SITL submitted the
;                selections) of matched files.
;
;
; CREATED BY: moka in May 2020
;
; $LastChangedBy: moka $
; $LastChangedDate: 2016-01-11 11:40:15 -0800 (Mon, 11 Jan 2016) $
; $LastChangedRevision: 19706 $
; $URL: svn+ssh://ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/bss/mms_get_roi.pro $
;-
FUNCTION eva_get_sitl_selections, trange=trange, n=n, filetimes=filetimes
  compile_opt idl2

  ;---------------------------------
  ; Timerange
  ;---------------------------------
  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
    return, -1
  endif
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr = timerange(trange) $
  else tr = [systime(/utc,/seconds)-3.d0*86400.d0, systime(/utc,/seconds)+1.d0*86400.d0]
  
  ;---------------------------------
  ; Login
  ;---------------------------------
  mms_init
  status = mms_login_lasp(login_info = login_info)
  if status ne 1 then begin
    print, 'Log-in failed'
    return, -1
  endif


  str_tr = time_string(tr)
  str_tr_date = strmid(str_tr,0,10)
  str_tr_hh   = strmid(str_tr,11,2)
  str_time  = str_tr_date+'-'+str_tr_hh
  start_time = str_time[0]
  end_time   = str_time[1]
  str_year = strmid(str_tr,0,4)
  kmin = min(long(str_year))
  kmax  = max(long(str_year))
  
  filenames = ''
  filetimes = ''
  for k = kmin, kmax do begin
    local_dir = filepath('', root_dir=!MMS.LOCAL_DATA_DIR, $
      subdirectory=['sitl','sitl_selections',strtrim(string(k),2)])
    file_mkdir, local_dir
    
    status = get_mms_selections_file("sitl_selections", $
      start_time=start_time, end_time=end_time, local_dir=local_dir)
      
    this_filenames = file_search(local_dir+'*',count=imax)
    lp = strlen(local_dir)
    date = strmid(this_filenames,lp+16,10)
    hh = strmid(this_filenames,lp+27,2)
    mm = strmid(this_filenames,lp+30,2)
    ss = strmid(this_filenames,lp+33,2)
    this_filetimes = date+'/'+hh+':'+mm+':'+ss
    
    filenames = [filenames, this_filenames]
    filetimes = [filetimes, this_filetimes]
  endfor
  nmax = n_elements(filenames)
  filenames = filenames[1:nmax-1]
  filetimes = filetimes[1:nmax-1]
  n = nmax-1
  
  return, filenames
END