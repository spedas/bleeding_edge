PRO eva_sitl_submit_bakstr, tlb, TESTING

  ; initialize
  title = 'Back Structure Submission'

  ; Check for BAK structures
  tn = tnames()
  idx = where(strmatch(tn,'mms_stlm_bakstr'),ct)
  if ct eq 0 then begin
    msg = 'Back-Structure not found. If you wish to'
    msg = [msg, 'submit a FOM structure, please disable the back-']
    msg = [msg, 'structure mode.']
    rst = dialog_message(msg,/error,/center,title=title)
    return
  endif
  
  ; BAK structures
  get_data,'mms_stlm_bakstr',data=Dmod, lim=lmod,dl=dmod
  get_data,'mms_soca_bakstr',data=Dorg, lim=lorg,dl=dorg
  tai_BAKStr_org = lorg.unix_BAKStr_org
  str_element,/add,tai_BAKStr_org,'START', mms_unix2tai(lorg.unix_BAKStr_org.START); LONG
  str_element,/add,tai_BAKStr_org,'STOP',  mms_unix2tai(lorg.unix_BAKStr_org.STOP) ; LONG
  tai_BAKStr_mod = lmod.unix_BAKStr_mod
  str_element,/add,tai_BAKStr_mod,'START', mms_unix2tai(lmod.unix_BAKStr_mod.START); LONG
  str_element,/add,tai_BAKStr_mod,'STOP',  mms_unix2tai(lmod.unix_BAKStr_mod.STOP) ; LONG
  
  ;------------------
  ; Modification Check
  ;------------------
  ;diff = eva_sitl_strct_comp(tai_BAKStr_mod, tai_BAKstr_org); (0) Not equal (1) Equal
  same = mms_compare_struct(tai_BAKstr_mod, tai_BAKstr_org)
  if same then begin
    msg = "The back-structure has not been modified at all."
    msg = [msg,'EVA cannot submit unmodified back-structure.']
    answer = dialog_message(msg,/info,/center,title=title)
    return
  endif
  
  ;------------------
  ; Validation
  ;------------------
  vsp = '////////////////////////////'
  header = [vsp+' NEW SEGMENTS '+vsp]
  r = eva_sitl_validate(tai_BAKStr_mod, -1, vcase=1, header=header, /quiet); Validate New Segs
  header = [r.msg,' ', vsp+' MODIFIED SEGMENTS '+vsp]
  r2 = eva_sitl_validate(tai_BAKStr_mod, tai_BAKStr_org, vcase=2, header=header,/quiet); Validate Modified Seg

  ct_err = r.error.COUNT+r2.error.COUNT
  if ct_err ne 0 then begin
    if ct_err eq 1 then mmm=' error exists.' else mmm=' errors exist.'
    msg = strtrim(string(ct_err),2)+mmm+' Submission aborted.'
    answer = dialog_message(msg,/center,title=title)
    return
  endif
  if r.yellow.COUNT ne 0 then begin
    msg = 'An yellow warning exists. Still submit?'
    if r.yellow.COUNT gt 1 then msg = 'Yellow warnings exist. Still submit?'
    answer = dialog_message(msg,/center,/question)
    if strmatch(strlowcase(answer),'no') then return
  endif

  ;------------------
  ; Submit
  ;------------------

  if TESTING then begin
    problem_status = 0
    msg='TEST MODE: The modified BAKStr was not sent to SDC.'
    rst = dialog_message(msg,/information,/center,title=title)
  endif else begin  
    mms_put_back_structure, tai_BAKStr_mod, tai_BAKStr_org, $
      mod_error_flags,   mod_yellow_warning_flags, mod_orange_warning_flags, $
      mod_error_msg,     mod_yellow_warning_msg,   mod_orange_warning_msg, $
      mod_error_times,   mod_yellow_warning_times, mod_orange_warning_times, $
      mod_error_indices, mod_yellow_warning_indices, mod_orange_warning_indices, $
      new_segs, $
      new_error_flags,   orange_warning_flags,   yellow_warning_flags, $
      new_error_msg,     orange_warning_msg,     yellow_warning_msg, $
      new_error_times,   orange_warning_times,   yellow_warning_times, $
      new_error_indices, orange_warning_indices, yellow_warning_indices, $
      problem_status, /warning_override
    case problem_status of
      0: msg = 'The back-structure was sent successfully to SDC.'
      1: msg = 'Something is wrong with the selection. Please validate and try again.'
      2: msg = 'There was nothing to submit. Please check the selection again.'
      3: msg = 'The structure passed the tests, but an error at the SDC prevented final submission.'
      else: message,'Something is wrong.'
    endcase
    answer = dialog_message(msg,/center,/info,title=title)
    ptr_free, mod_error_times, mod_orange_warning_times, mod_yellow_warning_times
    ptr_free, mod_error_indices, mod_orange_warning_indices, mod_yellow_warning_indices
    ptr_free, new_error_times, orange_warning_times, yellow_warning_times
    ptr_free, new_error_indices, orange_warning_indices, yellow_warning_indices
  endelse

  
END
