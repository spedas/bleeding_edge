;+
; NAME:
;    THM_SPINMODEL::PRINT_SEGMENTS.PRO
;
; PURPOSE:
;    Print the segments contained in a spin model.
;
; CATEGORY:
;   TDAS
;
; CALLING SEQUENCE:
;   spinmodel->print_segments
;
;  INPUTS:
;    None
;
;  OUTPUTS:
;    None
;
;  
;  EXAMPLE:
;     timespan,'2007-03-23',1,/days
;     thm_load_state,probe='a',/get_support_data
;
;     smp=spinmodel_get_ptr('a',use_eclipse_corrections=2)
;     smp->print_segments
;-

pro thm_spinmodel::print_segments

  sp = self.segs_ptr

  seg_array = *sp
  seg_count=n_elements(seg_array)
  
  for i=0L,seg_count-1 do begin
    segment_print,seg_array[i]
  endfor

end
