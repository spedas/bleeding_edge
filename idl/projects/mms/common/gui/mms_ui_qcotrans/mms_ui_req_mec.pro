
; Helper function,
; Returns 1 if data is required but is not available 
; or does not cover the time range. 
;
function mms_ui_req_mec_check, name, trange, loadedData

  compile_opt idl2, hidden
  
  ovr = 120. ;overlap tolerance

  ;look for tplot variable
  tvar = tnames(name, trange=crange)
    
  ;check loaded data if not found
  if ~is_string(tvar) && obj_valid(loadedData) then begin
    dummy = loadedData->getTvarData(name)
    tvar = tnames(name, trange=crange)
  endif
    
  ;verify variable was found and time range is sufficient
  if is_string(tvar) && $
     min(crange)-ovr le min(trange) || $
     max(crange)+ovr ge max(trange)    $
  then begin
    return, 0 ;present and sufficient
  endif
                           
  return, 1 ;not present or insufficient

end


;+
;
;NAME: 
;  mms_ui_req_mec
;
;PURPOSE:
;  Determines availability of mec quaternion support data
;
;CALLING SEQUENCE:
;  General:
;    bool = mms_ui_req_spin(probe,inCoord,outCoord,trange [,loadedData])
;
;  Example:
;    if mms_ui_req_spin(probe,inCoord,outCoord,trange,loadedData) then begin
;      mms_load_mec,probe=probe,trange=trange,varformat='*_quat_*'
;    endif
;
;INPUT:
;  inCoord: string storing the destination coordinate system (e.g. 'gse')
;  outCoord: string storing the destination coordinate system (e.g. 'sse')
;  probe: mms probe for check
;  trange: two element arraw storing the time range
;  loadedData: gui loadedData object reference
; 
;OUTPUT:
;  Returns boolean: 1 if required data is not present or does not cover
;                   the time range, 0 otherwise.
;
;NOTES:
;  This code assumes that only explicit transformations into the
;  coordinates in question will require mec data.
;
;HISTORY:
;  2015-04-24 - loaded data object now optional
;
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2016-12-07 11:04:32 -0800 (Wed, 07 Dec 2016) $
;$LastChangedRevision: 22444 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/gui/mms_ui_qcotrans/mms_ui_req_mec.pro $
;
;-
function mms_ui_req_mec, inCoord,outCoord,probe, trange, loadedData

    compile_opt idl2, hidden

  if inCoord ne 'eci' && inCoord ne 'j2000' then begin
    if mms_ui_req_mec_check('mms'+probe+'_mec_quat_eci_to_'+inCoord,trange,loadedData) then begin
      return,1
    endif
  endif
  
  if outCoord ne 'eci' && outCoord ne 'j2000' then begin
    if mms_ui_req_mec_check('mms'+probe+'_mec_quat_eci_to_'+outCoord,trange,loadedData) then begin
      return,1
    endif
  endif
  
  return, 0

end

