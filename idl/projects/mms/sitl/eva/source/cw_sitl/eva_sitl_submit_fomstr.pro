; $LastChangedBy: moka $
; $LastChangedDate: 2023-12-30 22:32:28 -0800 (Sat, 30 Dec 2023) $
; $LastChangedRevision: 32329 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/cw_sitl/eva_sitl_submit_fomstr.pro $
PRO eva_sitl_submit_FOMStr, tlb, TESTING, vcase, user_flag=user_flag

  if n_elements(user_flag) eq 0 then user_flag = 1
  ; initialize 
  title = 'FOM Submission'
    
  ; FOM structures
  get_data,'mms_stlm_fomstr',data=Dmod, lim=lmod,dl=dlmod
  get_data,'mms_soca_fomstr',data=Dorg, lim=lorg,dl=dlorg
  mms_convert_fom_unix2tai, lmod.unix_FOMStr_mod, tai_FOMstr_mod; Modified FOM to be checked
  mms_convert_fom_unix2tai, lorg.unix_FOMStr_org, tai_FOMstr_org; Original FOM for reference
  header = eva_sitl_text_selection(lmod.unix_FOMstr_mod)
  
  
  
  ;------------------
  ; UPLINK Check
  ;------------------
;  result = eva_sitluplink_log(tai_FOMstr_mod, title=title, /check)
;  if strmatch(result,'*abort*',/fold_case) then begin
;    print, result
;    return
;  endif
  
  ;------------------
  ; Modification Check
  ;------------------
  ;diff = eva_sitl_strct_comp(tai_FOMstr_mod, tai_FOMstr_org);
  same = mms_compare_struct(tai_FOMstr_mod, tai_FOMstr_org)
  ;if strmatch(diff,'unchanged') then begin
  if same then begin
    msg = "The FOM structure has not been modified at all."
    msg = [msg,'Would you still like to submit?']
    msg = [msg,' ']
    msg = [msg,'If you want to submit a back-structure,']
    msg = [msg,'please log-in as a Super-SITL and enable']
    msg = [msg,'the back-structure mode.']
    answer = dialog_message(msg,/question,/center,title=title)
    if strcmp(answer,'No') then return
  endif
    
  ;------------------
  ; Validation
  ;------------------
  r = eva_sitl_validate(tai_FOMstr_mod, tai_FOMstr_org, header=header, vcase=vcase)
  
  if r.error.COUNT ne 0 then begin
    rst = dialog_message('Please fix the error before submission.',/center,/error)
    return
  endif
  
  if (r.orange.COUNT ne 0) and (user_flag ne 2) then begin
    rst = dialog_message('Only Super SITL can override orange warnings.',/center,/error)
    return
  endif
  
  if r.yellow.COUNT ne 0 then begin
    msg = 'An yellow warning exists. Still submit?'
    if r.yellow.COUNT gt 1 then msg = 'Yellow warnings exist. Still submit?'
    answer = dialog_message(msg,/center,/question)
    if strmatch(strlowcase(answer),'no') then return
  endif
  
  r = eva_sitluplink_validateFOM(lmod.UNIX_FOMSTR_MOD)
  if (r gt 0) then return
 
  ;------------------
  ; Submit
  ;------------------
  local_dir = !MMS.LOCAL_DATA_DIR
  found = file_test(local_dir); check if the directory exists
  if not found then file_mkdir, local_dir

  if TESTING then begin
    problem_status = 0
    msg='File submission disabled. The modified structure was not sent to SDC.'
    rst = dialog_message(msg,/information,/center,title=title)
  endif else begin
    case vcase of
      0:begin
        mms_put_fom_structure, tai_FOMstr_mod, tai_FOMStr_org, $
          error_flags,  orange_warning_flags,  yellow_warning_flags,$; Error Flags
          error_msg,    orange_warning_msg,    yellow_warning_msg,  $; Error Messages
          error_times,  orange_warning_times,  yellow_warning_times,$; Erroneous Segments (ptr_arr)
          error_indices,orange_warning_indices,yellow_warning_indices,$; Error Indices (ptr_arr)
          problem_status, /warning_override
        ptr_free, error_times, orange_warning_times, yellow_warning_times
        ptr_free, error_indices, orange_warning_indices, yellow_warning_indices
        end
      3:begin
        s = tai_FOMstr_mod
        idx = where(strmatch(tag_names(s),'FPICAL'),ct)
        if(ct eq 1)then begin; Make sure the FPICAL tag exists
          nmax = n_elements(s.FOM)
          sourceid = eva_sourceid()
          tai_start = s.TIMESTAMPS[s.START[0]]
          tai_stop = s.TIMESTAMPS[s.STOP[0]]
          mms_submit_fpi_calibration_segment, tai_start, tai_stop, s.FOM[0], sourceid,  $
            error_flags, error_msg, $
            yellow_warning_flags, yellow_warning_msg, $
            orange_warning_flags, orange_warning_msg, $
            problem_status
          endif else stop
        end    
      else: message, "Something is wrong"
    endcase
      
    case problem_status of
      0: begin
        msgsfx = 'for DRAFT.'
        tn = tag_names(tai_FOMstr_mod)
        idx = where(tn eq strupcase('UPLINKFLAG'), nmatch)
        if nmatch gt 0 then begin
          if tai_FOMstr_mod.UPLINKFLAG eq 1 then msgsfx='for UPLINK.'
        endif else begin
          print, '...no UPLINK flag in FOMstr.'
        endelse
        msg=['The FOM structure was sent to SDC '+msgsfx]
        msg=[msg, 'A validation email will be sent to you (within 60 min)']
        msg=[msg, 'if successfully received at SDC.']
        rst = dialog_message(msg,/information,/center,title=title)
        end
      2: begin
        msg='Attempt to submit FOM structure interrupted, check your internet connection and try again.'
        rst = dialog_message(msg,/error,/center,title=title)
        end
      else: begin
        msg='Submission Failed.'
        rst = dialog_message(msg,/error,/center,title=title)
        end
    endcase
    
  endelse
END
