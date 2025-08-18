
;+
;PURPOSE:
;  Apply eclipse corrections (when present) to 3D data structures 
;  within thm_part_moments.pro
;
;
;ARGUMENTS:
;  dat: Valid 3D data structure
;  
;
;KEYWORDS:
;  domega: Array of weights used inside the Wind routines to calculate
;          vector and tensore components.  This array should be set to
;          0 if a correction is being applied or if a correction was
;          applied on the last loop.  
;  eclipse: Flag used by this routine to determine when an ecplise 
;           starts or ends (assists output messages). Should be set 
;           to 1 at the start of an eclipse and 0 at the end.
;  previous: Stores the delta phi value from the last time through the 
;            loop.  Helps determine when domega should be zeroed. 
;            
;
;
;NOTES:
;
;
;-

pro thm_part_moments_apply_eclipse, dat, domega=domega, $
                                    eclipse=eclipse, previous=previous 


    compile_opt idl2, hidden

  
  ; Check data structure validity
  if size(dat,/type) ne 8 then begin
    dprint, dlevel=0, 'Invalid particle data structure. No eclipse corrections applied.'
    return
  endif
  
  
  ; Check that corrections tag exists
  if ~in_set( strlowcase( tag_names(dat) ), 'eclipse_dphi') then begin
    return
  endif
  
  
  ; If /use_eclipse_corrections was used when loading data this field
  ; should always contain a valid number. 
  if ~finite(dat.eclipse_dphi) then begin
    if size(previous,/type) ne 0 && finite(previous) then begin
      dprint, dlevel=1, 'Error: Expected valid eclipse correction. '+ $
                        'Spin data may not have been loaded properly or may be incomplete.'
      previous = dat.eclipse_dphi
      domega = 0 ;reset weight for moment calc
      return
    endif else begin
      return
    endelse
  endif
      
  
  ; Attempt to notify user of the correction duration
  if dat.eclipse_dphi ne 0 && ~keyword_set(eclipse) then begin
    eclipse = 1b
    dprint, dlevel=2, verbose=verbose, 'Applying eclipse corrections beginning at: '+time_string(dat.time)
  endif
  if dat.eclipse_dphi eq 0 && keyword_set(eclipse) then begin
    eclipse = 0b
    dprint, dlevel=2, verbose=verbose, 'End eclipse corrections at: '+time_string(dat.time)
  endif
  
  
  ; Check this correction against the previous distributions.
  ; If different the weight for moments calculation must be zeroed.
  if keyword_set(previous) then begin
    if previous ne dat.eclipse_dphi then domega=0
  endif


  ; Add correction to current phi values
  dat.phi += dat.eclipse_dphi

  ; Store last value
  previous = dat.eclipse_dphi
  

end
