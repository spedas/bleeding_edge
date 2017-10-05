pro eclipse_spinfit_demo,probe=probe
thm_load_state,probe=probe,/get_supp
smp=spinmodel_get_ptr(probe)
smp->get_info,shadow_start=shadow_start,shadow_end=shadow_end,shadow_count=shadow_count
if shadow_count EQ 0 then begin
   dprint,'No eclipses found.'
endif else begin
   for i=0,shadow_count-1 do begin
   eclipse_trange=[shadow_start[i],shadow_end[i]]
   dprint,'Eclipse times:' 
   dprint,time_string(shadow_start[i]),time_string(shadow_end[i])
   eclipse_fgm_fit,probe=probe,eclipse_trange=eclipse_trange
   stop
   endfor
endelse
end
