;+
;Procedure : tsy_valid_param
;
;Purpose: 
;    Helper function used by Tsyganenko wrapper routines. Validates model input 
;      parameters and interpolates parameters onto position data
;    
;    
;Input:
;    in_val: tplot variable containing parameter data to be interpolated onto 
;      the position data
;    pos_name: the name of the position tplot variable
;    
; Returns -1L on failure
;  
;        
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-03-17 12:53:14 -0700 (Tue, 17 Mar 2015) $
; $LastChangedRevision: 17145 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/tsy_valid_param.pro $
;-

function tsy_valid_param, in_val, pos_name
  COMPILE_OPT HIDDEN, IDL2
  if undefined(in_val) || undefined(pos_name) then begin
    dprint, dlevel = 0, 'Error in tsy_valid_param, undefined input parameter'
    return, -1l
  endif
  if n_elements(in_val) gt 0 then begin
    ;if in_val is a string, assume in_val is stored in a tplot variable
    if size(in_val, /type) eq 7 then begin
      ; check that in_val is in the list of tplot variables
      if tnames(in_val) eq '' then begin
        message, /continue, in_val + ' is of type string but no tplot variable of that name exists'
        return, -1L
      endif

      ; interpolate onto position data
      tinterpol_mxn, in_val, pos_name, out=d_verify, error=e

      if e ne 0 then begin
        return, d_verify.y
      endif else begin
        message, /continue, 'error interpolating ' + in_val + ' onto position data'
        return, -1L
      endelse
      
    endif else return, in_val ; not a tplot variable, return the structure
  endif

  message, /continue, 'Warning: Unable to read ' + in_val + ' defaulting to 0.'

  get_data, pos_name, data = d

  return, dblarr(n_elements(d.x))
end
