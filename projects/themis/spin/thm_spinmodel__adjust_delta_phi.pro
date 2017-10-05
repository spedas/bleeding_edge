; Helper routine to apply spin phase corrections
pro thm_spinmodel::adjust_delta_phi,trange=trange,delta_phi_offset=delta_phi_offset

; Find each segment whose time range overlaps trange, and add
; delta_phi_offset to the delta_phi correction.

sp = self.segs_ptr
seg_t1 = (*sp)[*].t1
seg_t2 = (*sp)[*].t2
n = n_elements(seg_t1)
correction_count=0L

for i=0L, n-1 do begin
   if ( ((*sp)[i].t1 GE trange[0]) and ((*sp)[i].t2 LE trange[1])) then begin
      (*sp)[i].initial_delta_phi += delta_phi_offset
      ;  Turn on the bit that indicates delta_phi offsets have been
      ;  applied to this segment
      sf = (*sp)[i].segflags OR 4
      (*sp)[i].segflags = sf
      correction_count += 1
   end
endfor

dprint,dlevel=3,string(correction_count) + ' segments adjusted.'
end
