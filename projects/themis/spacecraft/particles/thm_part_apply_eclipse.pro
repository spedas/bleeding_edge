
;+
;PURPOSE:
;  Apply eclipse corrections (when present) to 3D data structures.
;
;
;ARGUMENTS:
;  data: Valid 3D data structure
;  
;
;KEYWORDS:
;  eclipse: Flag used by this routine to determine when an ecplise 
;           starts or ends (assists output messages). Will be set 
;           to 1 at the start of an eclipse and 0 at the end.
;            
;NOTES:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2013-09-10 12:11:07 -0700 (Tue, 10 Sep 2013) $
;$LastChangedRevision: 13011 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_apply_eclipse.pro $
;
;-

pro thm_part_apply_eclipse, data, eclipse=eclipse

    compile_opt idl2, hidden

  
  ; Check data structure validity
  if ~is_struct(data) then begin
    dprint, dlevel=0, 'Invalid particle data structure. No eclipse corrections applied.'
    return
  endif
  
  
  ; Check that corrections tag exists
  if ~in_set( strlowcase( tag_names(data) ), 'eclipse_dphi') then begin
    return
  endif
  

  ; If /use_eclipse_corrections was used when loading data this field should always contain a valid number. 
  if ~finite(data.eclipse_dphi) then begin
    if keyword_set(eclipse) then begin
      dprint, dlevel=0, 'Error: Expected valid eclipse correction at'+time_string(data.time)+ $
                        '. Spin data may not have been loaded properly or may be incomplete.'
      eclipse = 0b
    endif
    return
  endif
      
  
  ; Attempt to notify user of the correction duration
  if data.eclipse_dphi ne 0 && ~keyword_set(eclipse) then begin
    eclipse = 1b
    dprint, dlevel=2, verbose=verbose, 'Applying eclipse corrections beginning at: '+time_string(data.time)
  endif
  if data.eclipse_dphi eq 0 && keyword_set(eclipse) then begin
    eclipse = 0b
    dprint, dlevel=2, verbose=verbose, 'End eclipse corrections at: '+time_string(data.time)
  endif


  ; Add correction to phi
  data.phi += data.eclipse_dphi
  

end
