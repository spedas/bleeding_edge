;+
; NAME:
;    SPINMODEL_GET_PTR.PRO
;
; PURPOSE:  
;   Returns a pointer to the spin model, specified by a single
;   letter probe designation ('a' through 'f').  This is to avoid
;   having to define the spinmodel common block all over the place.
;
; CATEGORY: 
;   TDAS
;
; CALLING SEQUENCE:
;   model_ptr=spinmodel_get_ptr('a')
;
;  INPUTS:
;    probe: A scalar character, one of 'a' through 'f', specifying which model
;       pointer to return.
;
;  OUTPUTS:
;    model_ptr: The return value is a pointer to the specified spin model,
;       suitable for passing to the other spinmodel manipulation routines.
;
;  KEYWORDS:
;    None.
;    
;  PROCEDURE:
;    Test probe argument for validity; return appropriate value from
;    the spinmodel_common block.
;
;  EXAMPLE:
;     model_ptr=spinmodel_get_ptr('a')
;     spinmodel_test,model_ptr
;
;Written by: Jim Lewis (jwl@ssl.berkeley.edu)
;Change Date: 2007-10-08
;-

function spinmodel_get_ptr,probe,use_eclipse_corrections=use_eclipse_corrections
common spinmodel_common, tha_std_obj, thb_std_obj, thc_std_obj,$
                        thd_std_obj, the_std_obj, thf_std_obj,$
                        tha_ecl_obj, thb_ecl_obj, thc_ecl_obj,$
                        thd_ecl_obj, the_ecl_obj, thf_ecl_obj,$
                        tha_full_obj, thb_full_obj, thc_full_obj,$
                        thd_full_obj, the_full_obj, thf_full_obj, init_flag

if n_elements(use_eclipse_corrections) EQ 0 then begin
  use_eclipse_corrections=0  ; Default to no corrections for now
end

ptr = obj_new()

if n_elements(init_flag) EQ 0 then begin
    ; No spin model data has been loaded for any probe, so return
    ; a null object.  It is the caller's responsibility to check
    ; this condition before attempting to use it.

    dprint,'No spinmodel data is available for probe '+probe+'. Use thm_load_state,/get_support to load a spinmodel.'
    return,obj_new()
endif

if (use_eclipse_corrections EQ 0) then begin
dprint,'No eclipse corrections.'
   case probe of
   'a': ptr=tha_std_obj
   'b': ptr=thb_std_obj
   'c': ptr=thc_std_obj
   'd': ptr=thd_std_obj
   'e': ptr=the_std_obj
   'f': ptr=thf_std_obj
   else: message,'Unrecognized probe identifier: expecting scalar character a,b,c,d,e, or f.'
   endcase
endif else if (use_eclipse_corrections EQ 1) then begin
dprint,'Using partial eclipse corrections.'
   case probe of
   'a': ptr=tha_ecl_obj
   'b': ptr=thb_ecl_obj
   'c': ptr=thc_ecl_obj
   'd': ptr=thd_ecl_obj
   'e': ptr=the_ecl_obj
   'f': ptr=thf_ecl_obj
   else: message,'Unrecognized probe identifier: expecting scalar character a,b,c,d,e, or f.'
   endcase
endif else begin
dprint,'Using full eclipse corrections.'
   case probe of
   'a': ptr=tha_full_obj
   'b': ptr=thb_full_obj
   'c': ptr=thc_full_obj
   'd': ptr=thd_full_obj
   'e': ptr=the_full_obj
   'f': ptr=thf_full_obj
   else: message,'Unrecognized probe identifier: expecting scalar character a,b,c,d,e, or f.'
   endcase
endelse

if ~obj_valid(ptr) then begin
  dprint,'No spinmodel data is available for probe '+probe+'. Use thm_load_state,/get_support to load a spinmodel.'
endif

return, ptr
end
