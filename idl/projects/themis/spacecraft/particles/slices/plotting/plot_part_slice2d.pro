
;+
;Purpose: Notify user that old routine was renamed to follow naming conventions.
;
;Notes: May be removed in the future
;
;-

pro plot_part_slice2d, a, b, c, d, _extra=_extra

    compile_opt idl2, hidden
    
  ;************************************************************************
  ; "plot_part_slice2d" renamed to "thm_part_slice2d_plot" as of 2008-08-06
  ; Usage will remain the same; see thm_crib_part_slice2d for details.
  ;************************************************************************
  message, 'ERROR: "plot_part_slice2d.pro" has been renamed to "thm_part_slice2d_plot", ' + $
           'please update any scripts accordingly.  ' + $
           'Usage remains the same; see "/examples/thm_crib_part_slice2d" for details.'
  
  
end