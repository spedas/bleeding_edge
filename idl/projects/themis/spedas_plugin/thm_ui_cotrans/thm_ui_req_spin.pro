

;helper function for spin tvar requirement checking to simplify code organization
function thm_ui_cotrans_new_req_spin_tvars_helper,in_coord,out_coord,trange,varname,loadedData

  compile_opt idl2,hidden
  
  
 ; left_coords = ['gse','gsm','sm','gei','geo','sse','sel','mag']
 ; right_coords = ['spg','ssl','dsl']
  coordSysObj = obj_new('thm_ui_coordinate_systems')
  left_coords = coordSysObj->makeCoordSysListForSpinModel()
  right_coords = coordSysObj->makeCoordSysListforTHEMIS(/include_dsl)
  obj_destroy, coordSysObj
  
  in_coord_tmp = strlowcase(in_coord[0])
  out_coord_tmp = strlowcase(out_coord[0])
  
  overlap_margin = 120. ;how many seconds can the spin variables not overlap on an end before fail
    
  ;if transforming from one set to the other, spinras & spindec vars are required
  if (in_set(in_coord_tmp,left_coords) && in_set(out_coord_tmp,right_coords)) || $
     (in_set(out_coord_tmp,left_coords) && in_set(in_coord_tmp,right_coords)) then begin
       
    ;first check availability on the command line
    tvarname = tnames(varname,trange=var_trange)   
    ;if command line tplot variable is unavailable
    ;uses 60 second margin on each end, 60 seconds in the state data cadence 
    if ~is_string(tvarname) || $
       var_trange[0] - overlap_margin gt trange[0] || $
       var_trange[1] + overlap_margin lt trange[1] then begin
       
       ;check gui loadedData if available
       if ~obj_valid(loadedData) || ~in_set(varname,loadedData->getAll(/parent)) then begin
         return,1
       endif else begin
       
         ;var with correct name found, export and verify times.
         tmp = loadedData->getTvarData(varname)       
         tvarname = tnames(varname,trange=var_trange)
         
         ;export unsuccessful or times out of range
         ;uses 60 second margin on each end, 60 seconds in the state data cadence
         if ~is_string(tvarname) || $
            var_trange[0] - overlap_margin gt trange[0] || $
            var_trange[1] + overlap_margin lt trange[1] then begin
              return,1
         endif
       endelse
    endif ;if block is passed without returning, var found
    
  endif
  
  return,0

end

;determine if spin tplot variables are required for transformation
;Needed for any transformations that require 'gse2dsl' or 'dsl2gse'
;If variables are found in gui loadedData, will also be exported to command line for use with tplot
function thm_ui_cotrans_new_req_spin_tvars,in_coord,out_coord,probe,trange,loadedData

  compile_opt idl2,hidden

  ;name of the variables required
  spinras_cor = 'th'+probe+'_state_spinras_corrected'
  spindec_cor = 'th'+probe+'_state_spindec_corrected'
  spinras = 'th'+probe+'_state_spinras'
  spindec = 'th'+probe+'_state_spindec'
  
  
  if (~thm_ui_cotrans_new_req_spin_tvars_helper(in_coord,out_coord,trange,spinras_cor,loadedData) && $
      ~thm_ui_cotrans_new_req_spin_tvars_helper(in_coord,out_coord,trange,spindec_cor,loadedData)) || $
      (~thm_ui_cotrans_new_req_spin_tvars_helper(in_coord,out_coord,trange,spinras,loadedData) && $
       ~thm_ui_cotrans_new_req_spin_tvars_helper(in_coord,out_coord,trange,spindec,loadedData)) then begin
    return,0
  endif else begin
    return,1
  endelse

end

;determine if spin model is required for transformation
;Needed for any transformations that require 'ssl2dsl' or 'dsl2ssl'
function thm_ui_cotrans_new_req_spin_model,in_coord,out_coord,probe,trange

  compile_opt idl2,hidden

  ;left_coords = ['dsl','gse','gsm','sm','gei','geo','sse']
  ;right_coords = ['spg','ssl']
  coordsysobj = obj_new('thm_ui_coordinate_systems')
  left_coords = coordsysobj->makeCoordSysListForSpinModel(/include_dsl)
  right_coords = coordsysobj->makeCoordSysListForTHEMIS()
  obj_destroy, coordsysobj
  
  in_coord_tmp = strlowcase(in_coord[0])
  out_coord_tmp = strlowcase(out_coord[0])
  
  overlap_margin = 120. ;how many seconds can the spin variables not overlap on an end before fail
  
  ;if transforming from one set to the other, spinras & spindec vars are required
  if (in_set(in_coord_tmp,left_coords) && in_set(out_coord_tmp,right_coords)) || $
     (in_set(out_coord_tmp,left_coords) && in_set(in_coord_tmp,right_coords)) then begin
  
    spinmodel_ptr = spinmodel_get_ptr(probe)
    
    if ~obj_valid(spinmodel_ptr) then begin
      return,1
    endif
    
    spinmodel_get_info,model=spinmodel_ptr,start_time=model_start,end_time=model_end
    
    ;uses 60 second margin on each end, 60 seconds in the state data cadence
    if model_start - overlap_margin gt trange[0] || model_end + overlap_margin lt trange[1] then begin
      return,1
    endif
  
  endif
  return,0
end


;+ 
;NAME:
;  thm_ui_req_spin
;
;PURPOSE:
;  Determines availability of parameters for spin model.
;
;CALLING SEQUENCE:
;  bool = thm_ui_req_spin(in_coord, out_coord, probe, trange [,loadedData])
;
;  Example:
;    if thm_ui_req_spin(in_coord, out_coord, probe, trange) then begin
;      thm_load_state, probe=probe, trange=trange, /get_support_data
;    endif
;
;INPUT:
;  in_coord:  string storing the original coordinate system
;  out_coord:  a string storing the destination coordinate system
;  probe:  string probe designation
;  trange:  two element double storing requested time range
;  loadedData:  (optional) SPEDAS loadedData object
; 
;OUTPUT:
;  return value: 0 if required data is present for entire time range plus margin
;                1 otherwise
;
;NOTES:
;
;HISTORY:
;  2015-04-24 - loaded data object now optional
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-04-24 18:45:02 -0700 (Fri, 24 Apr 2015) $
;$LastChangedRevision: 17429 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spedas_plugin/thm_ui_cotrans/thm_ui_req_spin.pro $
;
;-
function thm_ui_req_spin,in_coord,out_coord,probe,trange,loadedData

  compile_opt idl2,hidden
  
  return,thm_ui_cotrans_new_req_spin_tvars(in_coord,out_coord,probe,trange,loadedData) || thm_ui_cotrans_new_req_spin_model(in_coord,out_coord,probe,trange)
  
end
