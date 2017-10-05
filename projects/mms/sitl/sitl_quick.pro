;+
; NAME: 
;   SITL_QUICK
; 
; PURPOSE:
;   This is an emergency script to be used when EVA is not working but 
;   a SITL still needs to modify the ABS selection within a limited time.
;   There won't be any display (because it won't generate any tplot-variable).
;
; INPUT:
;   Prepare an input ASCII file which contains a list of
;   startime, endtime, FOM value, and discussion (required for overriding
;   warning) of desired segments (There should be 3 or 4 columns,
;   each delimited by space). You will be prompted for this input file 
;   immediately after execution of this script.
; 
; INPUT (example)
;   2015-05-06/23:30:04 , 2015-05-06/23:35:44,  4.7,
;   2015-05-06 /23:36:34, 2015-05 -06/23:44:54, 50.0, 'This is a nice dipolarization front'
;   2015-05-06/23:45:04, 2015-05-06/23:53:24,  1.8
;
; NOTE:
;   - This program is completely independent from EVA but still requires
;     SPEDAS because SPEDAS contains programs provided by LASP.  
;   - Each segment will be attached a label 'SITL(Quick):<username>' where
;     <username> is the user's login ID.
;
; CREATED BY: Mitsuo Oka   Feb 2015
; 
; $LastChangedBy: moka $
; $LastChangedDate: 2015-09-23 17:14:25 -0700 (Wed, 23 Sep 2015) $
; $LastChangedRevision: 18898 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/sitl_quick.pro $
Function sitl_quick_template
  anan = fltarr(1) & anan[0] = 'NaN'
  ppp = {VERSION:1.00000, $
    DATASTART:0L, $
    DELIMITER:44b, $
    MISSINGVALUE:anan[0], $
    COMMENTSYMBOL:';', $
    FIELDCOUNT:4L, $
    FIELDTYPES:[7L, 7L, 4L, 7L], $
    FIELDNAMES:['str_stime','str_etime','fom','discussion'], $
    FIELDLOCATIONS:[0L,17L,35L,39L],$
    FIELDGROUPS:[0L,1L,2L,3L]}
  return, ppp
End

PRO sitl_quick, filename=filename
  common mms_sitl_connection, netUrl, connection_time, login_source
  compile_opt idl2
  
  mms_init
  
  ;------------------
  ; Fetch ABS
  ;------------------
  get_latest_fom_from_soc, fom_file, error_flag, error_msg
  if error_flag then message,'FOMStr not found in SDC. Ask Super SITL.'
  restore,fom_file
  mms_convert_fom_tai2unix, FOMstr, unix_FOMstr, start_string
  
  ;------------------
  ; Get Username
  ;------------------
  type = size(netUrl, /type) ;will be 11 if object has been created
  if (type eq 11) then begin
    netUrl->GetProperty, URL_USERNAME = username
  endif else begin
    message,'Something is wrong'
  endelse
  
  ;------------------
  ; Input File
  ;------------------
  if n_elements(filename) eq 0 then begin
    filename = dialog_pickfile(/READ)
  endif
  found = file_test(filename)
  if not found then begin
    print, 'ERROR: '+filename+' was not found'
    return
  endif
  r = read_ascii(filename, template=sitl_quick_template())

  ;------------------
  ; FOM Structure
  ;------------------
  print, '--------------'
  print, 'INPUTS'
  print, '--------------'
  NSEGS = n_elements(r.FOM)
  SEGLENGTHS = lonarr(NSEGS)
  SOURCEID = strarr(NSEGS)
  START = lonarr(NSEGS)
  STOP = lonarr(NSEGS)
  for n=0,NSEGS-1 do begin
    strFOM = string(r.FOM[n],format='(F5.1)')
    print, r.STR_STIME[n], ' - ', r.STR_ETIME[n], ', FOM=',strFOM,', ',strtrim(r.DISCUSSION[n],2)
    stime = str2time(r.STR_STIME[n])
    etime = str2time(r.STR_ETIME[n])
    rs = min(abs(unix_FOMstr.TIMESTAMPS-stime), ids)
    re = min(abs(unix_FOMstr.TIMESTAMPS-etime), ide)
    SOURCEID[n] = username+'(Quick)'
    START[n] = long(ids)
    STOP[n]  = long(ide)-1L; because STOP should be the start of the stop-segment
    SEGLENGTHS[n] = STOP[n]-START[n]+1L
  endfor
  str_element,/add,unix_FOMstr,'DISCUSSION', r.DISCUSSION
  str_element,/add,unix_FOMstr,'FOM', r.FOM
  str_element,/add,unix_FOMstr,'NBUFFS',total(SEGLENGTHS)
  str_element,/add,unix_FOMstr,'NSEGS',NSEGS
  str_element,/add,unix_FOMstr,'SEGLENGTHS',SEGLENGTHS
  str_element,/add,unix_FOMstr,'SOURCEID', SOURCEID
  str_element,/add,unix_FOMstr,'START',START
  str_element,/add,unix_FOMstr,'STOP',STOP
  mms_convert_fom_unix2tai, unix_FOMStr, tai_FOMstr

  ;------------------
  ; Validation
  ;------------------
  valstruct = mms_load_fom_validation(); validation structure
  problem_status = 0; 0 means 'no error'

  mms_check_fom_structure, tai_FOMstr, FOMstr, $
    error_flags,  orange_warning_flags,  yellow_warning_flags,$; Error Flags
    error_msg,    orange_warning_msg,    yellow_warning_msg,  $; Error Messages
    error_times,  orange_warning_times,  yellow_warning_times,$; Erroneous Segments (ptr_arr)
    error_indices,orange_warning_indices,yellow_warning_indices,$; Error Indices (ptr_arr)
    valstruct=valstruct
      
  print, ''
  print, '--------------'
  print, 'ERROR'
  print, '--------------'
  cmax = n_elements(error_flags)
  ct_error = 0
  for c=0,cmax-1 do begin; for each error type
    if error_flags[c] eq 1 then begin; if error
      ct_error += 1
      print, ' '
      print, error_msg[c]
      tstr = *(error_times[c])
      tidx = *(error_indices[c])
      nmax = n_elements(tstr)
      for n=0,nmax-1 do begin
        print, '   segment: ',strtrim(string(tidx[n]),2), ', ', tstr[n]
      endfor
    endif
  endfor
  if ct_error eq 0 then print, 'none'
  
  print, ' '
  print, '--------------'
  print, 'ORANGE WARNING'
  print, '--------------'
  cmax = n_elements(orange_warning_flags)
  ct_orange = 0
  ct_override = 0
  for c=0,cmax-1 do begin; for each error type
    if orange_warning_flags[c] eq 1 then begin; if error
      ct_orange += 1
      print, ' '
      print, orange_warning_msg[c]
      tstr = *(orange_warning_times[c])
      tidx = *(orange_warning_indices[c])
      nmax = n_elements(tstr)
      for n=0,nmax-1 do begin
        cmt = r.DISCUSSION[tidx[n]]
        if strmatch(cmt,'*NaN*') then begin 
          ow = '' 
        endif else begin 
          ow = '!!!!! OVERRIDDEN !!!!!'
          ct_override += 1
        endelse
        print, '   segment: ',strtrim(string(tidx[n]),2), ', ', tstr[n], ',',ow
      endfor
    endif
  endfor
  if ct_orange eq 0 then print, 'none'
  
  print, ' '
  print, '--------------'
  print, 'YELLOW WARNING'
  print, '--------------'
  cmax = n_elements(yellow_warning_flags)
  ct_yellow = 0
  for c=0,cmax-1 do begin; for each error type
    if yellow_warning_flags[c] eq 1 then begin; if error
      ct_yellow += 1
      print, ' '
      print, yellow_warning_msg[c]
      tstr = *(yellow_warning_times[c])
      tidx = *(yellow_warning_indices[c])
      nmax = n_elements(tstr)
      for n=0,nmax-1 do begin
        print, '   segment: ',strtrim(string(tidx[n]),2), ', ', tstr[n]
      endfor
    endif
  endfor
  if ct_yellow eq 0 then print, 'none'
  
  ;------------------
  ; Submit
  ;------------------
  print, ''
  if (ct_error eq 0) and (ct_orange eq ct_override) then begin
    mms_put_fom_structure, tai_FOMstr, FOMStr,$
      error_flags,  orange_warning_flags,  yellow_warning_flags,$; Error Flags
      error_msg,    orange_warning_msg,    yellow_warning_msg,  $; Error Messages
      error_times,  orange_warning_times,  yellow_warning_times,$; Erroneous Segments (ptr_arr)
      error_indices,orange_warning_indices,yellow_warning_indices,$; Error Indices (ptr_arr)
      problem_status, /warning_override
      
    case problem_status of
      0: print, '>>> The FOM structure was sent successfully to SDC.'
      2: print, '>>> Attempt to submit FOM structure interrupted, check your internet connection and try again.'
      else: print, '>>> Submission Failed.'
    endcase

  endif else begin
    print, '>>> The FOM structure was not sent to SDC because of an error/warning.'
  endelse
  print, ''
  ptr_free, error_times, orange_warning_times, yellow_warning_times
  ptr_free, error_indices, orange_warning_indices, yellow_warning_indices
  
END
