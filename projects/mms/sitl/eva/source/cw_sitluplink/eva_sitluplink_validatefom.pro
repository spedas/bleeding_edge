FUNCTION eva_sitluplink_validateFOM, unix_fomstr
  compile_opt idl2
  
  tgn = tag_names(unix_fomstr)
  idxA=where(strlowcase(tgn) eq 'uplinkflag',ctA)
  idxB=where(strlowcase(tgn) eq 'evalstarttime',ctB)
  if(ctA eq 0)then begin; If no uplinkflag 
    return, 0           ; then return with no error
  endif else begin
    if (unix_fomstr.UPLINKFLAG) then begin; If UPLINK=1
      if (ctB eq 0) then begin           ; but no EVALSTARTIME, then error
        message,'Something is wrong.'
      endif
    endif else begin; If UPLINK=0
      return, 0; then return with no error (because no need to validate)
    endelse
  endelse
  
  ;---------------------
  ; Validation by Rick
  ;---------------------

  transtart = time_string(unix_fomstr.timestamps[0])
  transtop = time_string(unix_fomstr.timestamps[n_elements(unix_fomstr.timestamps)-1])
  sROIs = mms_get_srois(trange = [transtart, transtop])

  mms_convert_fom_unix2tai, unix_fomstr, tai_fomstr
  mms_check_fom_uplink, tai_fomstr, srois, error_flags, error_indices, error_msg, error_times

  print, '------------'

  loc_error = where(error_flags ne 0, count_error)
  print, 'Errors: '+strtrim(string(count_error),2)
  errmsg = ''
  for i = 0, count_error-1 do begin
    print, error_msg[loc_error[i]]
    errmsg = [errmsg,error_msg[loc_error[i]]]
    print, *error_times[loc_error[i]]
  endfor
  print, '------------'
  if count_error gt 0 then result = dialog_message(errmsg,/center)

  ;***** WARNING SHOULD NOT BE COUNTED AS AN ERROR ***********
  if error_flags[2] eq 1 then begin
    count_error -= 1
  endif
  
  ptr_free, error_indices
  ptr_free, error_times
  
  return, count_error
END
