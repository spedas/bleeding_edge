;+
; NAME:
;    SPINMODEL_RESET.PRO
;
; PURPOSE:  
;    Free any data structures associated with the spin model for a 
;    given probe or set of probes, and null out the spin model
;    pointer to prevent stale, previously loaded data from being
;    used erroneously.
;
; CATEGORY: 
;   TDAS
;
; CALLING SEQUENCE:
;   spinmodel_reset,probe='a'
;   spinmodel_reset,probe='a b c'
;   spinmodel_reset,probe=['a','b','c']
;   spinmodel_reset,probe='*'
;   spinmodel_reset,probe='all'
;
;  INPUTS:
;    None.
;
;  OUTPUTS:
;    None.
;
;  KEYWORDS:
;    PROBE  Specifies which probe or probes to reset.
;    
;  PROCEDURE:
;    Parse value of PROBE keyword to see which models to reset;
;    for any specified model with existing data, free the data
;    and set the spinmodel pointer in the common block to null.
;
;  EXAMPLE:
;
;Written by: Jim Lewis (jwl@ssl.berkeley.edu)
;-

; Helper function: free spin model objects for a single probe

pro spinmodel_reset_single,probe=probe
common spinmodel_common,tha_std_obj, thb_std_obj, thc_std_obj,$
                        thd_std_obj, the_std_obj, thf_std_obj,$
                        tha_ecl_obj, thb_ecl_obj, thc_ecl_obj,$
                        thd_ecl_obj, the_ecl_obj, thf_ecl_obj


case probe of
 'a': BEGIN
      if obj_valid(tha_std_obj) then begin
         obj_destroy,tha_std_obj
         tha_std_obj = obj_new()
      endif
      if obj_valid(tha_ecl_obj) then begin
         obj_destroy,tha_ecl_obj
         tha_ecl_obj = obj_new()
      endif
      END
 'b': BEGIN
      if obj_valid(thb_std_obj) then begin
         obj_destroy,thb_std_obj
         thb_std_obj = obj_new()
      endif
      if obj_valid(thb_ecl_obj) then begin
         obj_destroy,thb_ecl_obj
         thb_ecl_obj = obj_new()
      endif
      END
 'c': BEGIN
      if obj_valid(thc_std_obj) then begin
         obj_destroy,thc_std_obj
         thc_std_obj = obj_new()
      endif
      if obj_valid(thc_ecl_obj) then begin
         obj_destroy,thc_ecl_obj
         thc_ecl_obj = obj_new()
      endif
      END
 'd': BEGIN
      if obj_valid(thd_std_obj) then begin
         obj_destroy,thd_std_obj
         thd_std_obj = obj_new()
      endif
      if obj_valid(thd_ecl_obj) then begin
         obj_destroy,thd_ecl_obj
         thd_ecl_obj = obj_new()
      endif
      END
 'e': BEGIN
      if obj_valid(the_std_obj) then begin
         obj_destroy,the_std_obj
         the_std_obj = obj_new()
      endif
      if obj_valid(the_ecl_obj) then begin
         obj_destroy,the_ecl_obj
         the_ecl_obj = obj_new()
      endif
      END
 'f': BEGIN
      if obj_valid(thf_std_obj) then begin
         obj_destroy,thf_std_obj
         thf_std_obj = obj_new()
      endif
      if obj_valid(thf_ecl_obj) then begin
         obj_destroy,thf_ecl_obj
         thf_ecl_obj = obj_new()
      endif
      END
else: message,'Unrecognized probe identifier: '+probe
endcase  
end

pro spinmodel_reset,probe=probe
if (n_elements(probe) EQ 0) then begin
   message,'Required PROBE keyword not passed.'
endif

if (size(probe,/n_dim) EQ 0) then begin
   probe_arr = strsplit(strlowcase(probe),' ',/extract)
endif else begin
   probe_arr = strlowcase(probe)
endelse

; probe_arr is now a lower-case array of probe IDs.

; Check for "all" or "*"

result=WHERE(strmatch(probe_arr,'all'),all_count)
result=WHERE(strmatch(probe_arr,'\*'),star_count)
if ((all_count GE 1) or (star_count GE 1)) then begin
   dprint,'Resetting spin models for all probes.'
   spinmodel_reset_single,probe='a'
   spinmodel_reset_single,probe='b'
   spinmodel_reset_single,probe='c'
   spinmodel_reset_single,probe='d'
   spinmodel_reset_single,probe='e'
   spinmodel_reset_single,probe='f'
endif else begin
   for i=0,n_elements(probe_arr)-1 do begin
      dprint,'Resetting spin model for probe '+probe_arr[i]
      spinmodel_reset_single,probe=probe_arr[i]
   endfor
endelse
end
