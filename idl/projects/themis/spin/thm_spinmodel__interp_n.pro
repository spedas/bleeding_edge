;+
; NAME:
;    SPINMODEL_INTERP_N.PRO
;
; PURPOSE:
;    Given a spin model and spin count  (or array of counts), calculate
;    the sun pulse time and spin period at each input count.
;
; CATEGORY:
;   TDAS
;
; CALLING SEQUENCE:
;   spinmodel->interp_n,count=input_counts,$
;      time=output_times, spinper=output_spinper
;
;  INPUTS:
;    Count: A long integer (or long integer array) specifying the spin
;      count to use.  If the input is a scalar, all outputs
;      will be scalars; otherwise, all outputs are arrays having
;      the same size as the input counts.
;
;  OUTPUTS:
;    spinper: Optional keyword parameter to receive spin period values.
;    time: Optional keyword parameter to receive sun pulse time
;       of each input count.
;
;  KEYWORDS:
;
;  /COUNT: Required input keyword argument specifying a time or array of times.
;  /SPINPER: Optional keyword argument to receive spin period values.
;  /TIME:  Optional keyword argument to receive sun pulse times.
;
;  PROCEDURE:
;     Find the spinmodel segment containing the input spin count.
;     Invert phi(t) function to find time corresponding to this count.
;     Use b and c segment parameters to determine the spin period
;       at the sunpulse time.
;  
;  EXAMPLE:
;  ; Retrieve first 100 sun pulse times included in model for THA:
;  modelptr=spinmodel_get_ptr('a')
;  spinmodel_interp_n,model=modelptr,count=lindgen(100),time=output_times
;  
;-

pro thm_spinmodel::interp_n,count=count,time=time,spinper=spinper

if (keyword_set(count) NE 1) then begin
message,'Required input keyword parameter COUNT not present.'
end

n=count

sp = self.segs_ptr
if (ptr_valid(sp) NE 1) then begin
  message,'Spinmodel segment pointer is invalid'
end

inp_count=n_elements(count)
if (inp_count EQ 1) then begin
   seg_index = self->findseg_n(count)
   seg = (*sp)[seg_index]

   segment_interp_n,seg,count,my_time,my_spinper

   if (arg_present(time) EQ 1) then time=my_time
   if (arg_present(spinper) EQ 1) then spinper=my_spinper

endif else begin
   my_time=dblarr(inp_count)
   my_spinper=dblarr(inp_count)

   for i=0L,inp_count-1L do begin
      seg_index = self->findseg_n(count[i])
      seg = (*sp)[seg_index]

      segment_interp_n,seg,count[i],tl,spper

      my_time[i]=tl
      my_spinper[i]=spper
   endfor

   if (arg_present(time) EQ 1)  then time=my_time
   if (arg_present(spinper) EQ 1) then spinper=my_spinper
endelse
end
