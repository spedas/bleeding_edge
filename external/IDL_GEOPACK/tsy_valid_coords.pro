;+
;Procedure : tsy_valid_coords
;
;Purpose: 
;    Helper function used by Tsyganenko wrapper routines - checks coordinate system in dlimits structure
;    
;Input:
;    dlimits: dlimits structure from the tplot position variable
;    
;Keywords:
;    geopack_2008: specify to use the 2008 version of Geopack library. Must have v9.2 or later of the IDL Geopack DLM
;    
;Output:    
; Returns -1 on failure, +1 on success
;  
;        
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-03-17 12:53:14 -0700 (Tue, 17 Mar 2015) $
; $LastChangedRevision: 17145 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/tsy_valid_coords.pro $
;-
function tsy_valid_coords, dlimits, geopack_2008 = geopack_2008
  if ~is_struct(dlimits) then begin
    message, /continue, 'dlimits structure not set, make sure input variables are in gsm coordinates or results will be invalid'
    return, -1
  endif else begin
    str_element, dlimits, 'data_att', success = s
    if s eq 0 then begin
      message, /continue, 'dlimits.data_att structure not set, make sure input variables are in gsm coordinates or results will be invalid'
      return, -1
    endif else begin
      str_element, dlimits.data_att, 'coord_sys', success = s
      if s eq 0 then begin
        message, /continue, 'dlimits.data_att.coord_sys value not set, make sure input variables are in gsm coordinates or results will be invalid'
        return, -1
      endif else if strlowcase(dlimits.data_att.coord_sys) ne 'gsm' then begin
        message, /continue, 'input variable is in the wrong coordinate system, returning'
        return, -1 ;definitely wrong coordinate system=error
      endif
    endelse
  endelse
  return, 1
end