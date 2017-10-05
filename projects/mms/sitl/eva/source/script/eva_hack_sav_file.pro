;+
; NAME:
;   EVA_HACK_SAV_FILE
;
; PURPOSE:
;   This is an emergency script to be used when SITL selection is rejected
;   due to "metadata evaluation timestamp mismatch" or when the EVA's validation
;   returns the following error:
;   
;   ERROR: The evaluation times for the automated system and SITL selections do not match!
;            segment -1, Orbit-wide error -
;
; USAGE:
;   1. Launch EVA
;   2. Restore a SITL selection
;   3. Use the IDL console and execute the following command:
;   
;     MMS> eva_hack_sav_file
;   
;   4. Click the validate button to make sure the error is gone.
;   5. Submit
;   
;
; CREATED BY: Mitsuo Oka   Sep 2015
;
; $LastChangedBy: moka $
; $LastChangedDate: 2016-01-11 11:49:01 -0800 (Mon, 11 Jan 2016) $
; $LastChangedRevision: 19707 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/script/eva_hack_sav_file.pro $
PRO eva_hack_sav_file
  mms_init
  
  ;----------------
  ; LATEST ABS
  ;----------------
  get_latest_fom_from_soc, fom_file, error_flag, error_msg
  if error_flag then begin
    msg = 'Failed to retrieve the latest FOMstructure from SDC. This is unlikely to happen.' 
    result=dialog_message(msg,/center)
    return
  endif
  restore, fom_file
  strCorrect = FOMstr.METADATAEVALTIME
  print,'The current eval-time at SDC         :',strCorrect

  ;-------------------------
  ; CURRENT SITL SELECTION
  ;-------------------------
  tn=tnames('mms_stlm_fomstr',ct)
  if ct ne 1 then begin
    msg = 'Something is wrong. Current SITL selection is not found.'
    result = dialog_message(msg,/center)
    return
  endif
  get_data,'mms_stlm_fomstr',data=OD,lim=Olim,dl=Odl
  strEvalTime = Olim.unix_FOMstr_mod.METADATAEVALTIME
  print, "The eval-time in the current sav file:",strEvalTime
  
  ;----------------------------------
  ; COMPARE AND REPLACE IF NECESSARY
  ;----------------------------------
  if strmatch(strCorrect,strEvalTime) then begin
    msg = 'The METADATAEVALTIME is correct. No need to hack.'
  endif else begin
    str_element,/add,Olim,'unix_FOMstr_mod.METADATAEVALTIME',strCorrect
    store_data,'mms_stlm_fomstr',data=OD,lim=Olim,dl=Odl
    msg = 'The discrepancy of METADATAEVALTIME is fixed. '
    msg = [msg, '', 'Please click the Validate button to clear the error.']
  endelse
  result=dialog_message(msg,/center)
END
