FUNCTION eva_sitl_validate_msg, title, flags, msg, times, indices
  vsep = '------------------'
  loc_error = where(flags ne 0, ct_error)
  disp = ''
  if ct_error ne 0 then begin; if error found
    disp = [vsep,title,vsep,' ']; header
    for c=0,ct_error-1 do begin; for each error type
      disp = [disp, msg[loc_error[c]],' ']; record the message
      tstr = *(times[loc_error[c]]); a list of erroneous segment time
      tidx = *(indices[loc_error[c]]); a list of erroneous segment number
      nmax = n_elements(tstr)
      for n=0,nmax-1 do begin; for each erroneous segment
        disp = [disp, '   segment '+strtrim(string(tidx[n]),2)+', '+strmid(tstr[n],0,19)]; record the seg info
      endfor
    endfor; for each error type
  endif
  result = {message:disp, count:ct_error}
  return, result
END

FUNCTION eva_sitl_validate, tai_FOMstr_mod, tai_FOMstr_org, header=header, $
  quiet=quiet, vcase=vcase;, valstruct=valstruct
  compile_opt idl2
  COMMON SESSION_DATA, gFomValidation
  
  if n_elements(vcase) eq 0 then vcase = 0
  
  ;---------------------
  ; Validation by Rick
  ;---------------------
  problem_status = 0; 0 means 'no error'
  case vcase of
    0: begin
      mms_check_fom_structure, tai_FOMstr_mod, tai_FOMstr_org, $
        error_flags,  orange_warning_flags,  yellow_warning_flags,$; Error Flags
        error_msg,    orange_warning_msg,    yellow_warning_msg,  $; Error Messages
        error_times,  orange_warning_times,  yellow_warning_times,$; Erroneous Segments (ptr_arr)
        error_indices,orange_warning_indices,yellow_warning_indices, $; Error Indices (ptr_arr)
        valstruct=gFomValidation
      end
    1: begin
      mms_back_structure_check_new_segments, tai_FOMStr_mod, new_seg, $
        error_flags, orange_warning_flags, yellow_warning_flags, $
        error_msg,   orange_warning_msg,   yellow_warning_msg, $
        error_times, orange_warning_times, yellow_warning_times, $
        error_indices, orange_warning_indices, yellow_warning_indices, $
        valstruct=gFomValidation
      end
    2: begin
      mms_back_structure_check_modifications, tai_FOMStr_mod, tai_FOMStr_org, $
        error_flags,  yellow_warning_flags, orange_warning_flags, $
        error_msg,    yellow_warning_msg,   orange_warning_msg, $
        error_times,  yellow_warning_times, orange_warning_times, $
        error_indices,yellow_warning_indices,orange_warning_indices, $
        valstruct=gFomValidation
      end
    3: begin
      result=dialog_message('Something is wrong. Please contact Super-SITL',/center)
      end
    else: message,'Something is wrong!!'
  endcase
  
  ;---------------------
  ; REFORMAT MESSAGES
  ;---------------------
  if n_elements(error_flags) eq 0 then stop
  error  = eva_sitl_validate_msg('ERROR', error_flags, error_msg, error_times, error_indices)
  orange = eva_sitl_validate_msg('ORANGE_WARNING',orange_warning_flags, orange_warning_msg,$
     orange_warning_times,orange_warning_indices)
  yellow = eva_sitl_validate_msg('YELLOW_WARNING',yellow_warning_flags, yellow_warning_msg,$
     yellow_warning_times,yellow_warning_indices)
  
  ptr_free, error_times, error_indices
  ptr_free, orange_warning_times, orange_warning_indices
  ptr_free, yellow_warning_times, yellow_warning_indices
  
  ;---------------------
  ; DISPLAY MESSAGES
  ;---------------------
  if vcase eq 3 then begin
     msg = ['****************************',$
            '******* FPI CAL MODE *******',$
            '****************************']
  endif else msg = ''
  
  if n_elements(header) eq 0 then begin
    msg = [msg, error.MESSAGE, orange.MESSAGE, yellow.MESSAGE]
  endif else begin
    msg = [msg, header, error.MESSAGE, orange.MESSAGE, yellow.MESSAGE]
  endelse
  

  ct_total = error.COUNT+orange.COUNT+yellow.COUNT
  
;  if vcase lt 2 then begin
;    msg = [msg, yellow.MESSAGE]
;    ct_total += yellow.COUNT
;  endif
;  
  if(ct_total eq 0)then begin
    ex = '####################'
    msg = [msg, ex,' No error/warning',ex]
  endif 
  
  ;---------------------
  ; WRAP TEXTS
  ;---------------------
  if ~keyword_set(quiet) then begin 
    nmax = n_elements(msg)
    LL=120;76
    newmsg = ''
    for n=0,nmax-1 do begin
      if (strlen(msg[n]) ge LL) then begin
        s0 = msg[n]
        ct = 0
        strlenmsg = strlen(s0)
        while (strlenmsg ge LL) do begin
          newmsg = [newmsg,strmid(s0,ct*LL,LL)]
          strlenmsg -= LL
          ct+=1
        endwhile
        newmsg = [newmsg,strmid(s0,ct*LL,LL)]
      endif else begin
        newmsg = [newmsg,msg[n]]
      endelse
    endfor
    msg = newmsg[1:n_elements(newmsg)-1]
    ;----------------
    xdisplayfile,'dummy',done='Close',group=tlb,text=msg, title='VALIDATION',height=50, width=120;/grow_to_screen
    ;----------------
    mmax = n_elements(msg)
    openw,nf,'eva_validate.txt',/get_lun ; open as a new file
    for m=0,mmax-1 do begin
      printf, nf, msg[m]
    endfor
    free_lun, nf
    ;----------------
  endif
  result = {error:error, orange:orange, yellow:yellow, msg:msg}
;  if vcase lt 2 then begin
;    result = {error:error, orange:orange, yellow:yellow, msg:msg}
;  endif else begin
;    result = {error:error, orange:orange, msg:msg}
;  endelse
  return, result
END
