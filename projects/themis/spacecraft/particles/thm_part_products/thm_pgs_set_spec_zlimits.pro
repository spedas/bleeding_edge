;+
;PROCEDURE: thm_pgs_set_spec_zlimits
;PURPOSE:
;  Helper routine for thm_part_products
;  Sets zlimits to good default minimums for spectrograms
;
;Inputs(required):
; in_name: name or names of the tplot variable to be modified
; units: of in_name(s) lower-case string
;
;Outputs:
;  None, just mutates in_name
;
;Notes:
;  Uses a fixed formula for limits.  They vary a little bit for different possible unit selections
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2013-09-16 10:56:21 -0700 (Mon, 16 Sep 2013) $
;$LastChangedRevision: 13039 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_products/thm_pgs_set_spec_zlimits.pro $
;-
pro thm_pgs_set_spec_zlimits, in_name, units

  compile_opt idl2,hidden

  ;datatype currently unused.
  ;Since min_value bounds loosely, It shouldn't need to change for different data types
  ;If we find a problem, can reassess
    
  if units eq 'counts' || units eq 'compressed' then begin
    min_value = 1e-5
  endif else if units eq 'rate' || units eq 'crate' then begin
    min_value = 1e-3
  endif else if units eq 'flux' then begin
    min_value = 1e-4
  endif else if units eq 'dflux' then begin
    min_value = 1e-18
  endif else if units eq 'eflux' then begin
    min_value = 1e0
  endif else begin
    ;no need to throw error for range limits
;    message,'ERROR: Unexpected unit type'
  endelse
      
  options,in_name,min_value=min_value,/default

end
