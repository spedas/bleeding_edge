
; Helper function,
; Returns 1 if data is required but is not available 
; or does not cover the time range. 
;
function thm_ui_req_slp_check, name, in, out, trange, loadedData

    compile_opt idl2, hidden

  ; commenting out 'att', 'other' coordinate system lists because they aren't used. -egrimes, 2/21/2014
 ; pos = ['sel','sse'] ;transforms to/from these require position data
 ; att = ['sel'] ;transforms to/from these requre attitude data
 ; other = ['gse','gsm','sm','gei','geo','spg','ssl','dsl']
  coordSysObj = obj_new('thm_ui_coordinate_systems')
  pos = coordSysObj->makeCoordSysListForTHEMISReqPos()
  obj_destroy, coordSysObj
  
  ovr = 120. ;overlap buffer

  
  ;Use POS list since all data is loaded at once
  ;For now no transformations between coordinates listed in 
  ;other require POS or ATT transforms.

  if in_set(in,pos) || in_set(out,pos) then begin

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
  endif

  return, 0 ;data not required
end


;+
;
;NAME: 
;  thm_ui_req_slp
;
;PURPOSE:
;  Determines availablity of solar/lunar ephemeris data.
;
;CALLING SEQUENCE:
;  General:
;    bool = thm_ui_req_spin(inCoord,outCoord,trange [,loadedData])
;
;  Example:
;    if thm_ui_req_spin(inCoord,outCoord,trange,loadedData) then begin
;      thm_load_slp,datatype='all',trange=trange
;    endif
;
;INPUT:
;  inCoord: string storing the destination coordinate system (e.g. 'gse')
;  outCoord: string storing the destination coordinate system (e.g. 'sse')
;  trange: two element arraw storing the time range
;  loadedData: gui loadedData object reference
; 
;OUTPUT:
;  Returns boolean: 1 if required data is not present or does not cover
;                   the time range, 0 otherwise.
;
;NOTES:
;  This code assumes that only explicit transformations into the
;  coordinates in question will require slp data.
;
;HISTORY:
;  2015-04-24 - loaded data object now optional
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-04-24 18:45:02 -0700 (Fri, 24 Apr 2015) $
;$LastChangedRevision: 17429 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spedas_plugin/thm_ui_cotrans/thm_ui_req_slp.pro $
;
;-
function thm_ui_req_slp, inCoord, outCoord, trange, loadedData

    compile_opt idl2, hidden


  name_sun_pos = 'slp_sun_pos'
  name_lun_pos = 'slp_lun_pos'
  name_lun_att_x = 'slp_lun_att_x'
  name_lun_att_z = 'slp_lun_att_z'
  
  in = strlowcase(inCoord[0])
  out = strlowcase(outCoord[0])

  if thm_ui_req_slp_check(name_sun_pos, in, out, trange, loadedData) || $
     thm_ui_req_slp_check(name_lun_pos, in, out, trange, loadedData) || $
     thm_ui_req_slp_check(name_lun_att_x, in, out, trange, loadedData) || $
     thm_ui_req_slp_check(name_lun_att_z, in, out, trange, loadedData) $
  then begin
    return, 1
  endif

  return, 0

end

