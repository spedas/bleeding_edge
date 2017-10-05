pro thm_spinmodel::addseg,newseg
sp = self.segs_ptr

if (self.lastseg EQ -1) then begin
  (*sp)[0] = newseg
  self.lastseg = 0L
endif else begin
   lseg=(*sp)[self.lastseg]
   if (newseg.t1 EQ lseg.t2) then begin
      ;
      ; Normal case: segments are contiguous
      ;
      self.lastseg = self.lastseg + 1
      newseg.c1 = lseg.c2
      newseg.c2 = lseg.c2 + newseg.c2
      (*sp)[self.lastseg] = newseg
   endif else begin
      ; Segments are not contiguous -- this should indicate
      ; a UTC date boundary, and the spin models on either side will
      ; need to be merged.
      ;
      ; There are several cases, depending on the delta-t between the
      ; end of the previous segment, and the start of the current segment:
      ;
      ; 1) Large gap, greater than 1/2 spin : create a new segment to
      ;    bridge the gap.
      ; 2) Small gap, <= 1/2 spin, previous segment covers 2 or more spins:
      ;    remove last spin from previous segment, converting the situation
      ;    to the "large gap" case, then create a new segment to bridge
      ;    the gap.
      ; 3) Small gap, previous segment only contains 1 spin : if current
      ;    segment contains 2 or more spins, remove first spin from 
      ;    current segment, converting the situation to the "large gap"
      ;    case, then create a new segment to bridge the gap.
      ; 4) Small gap, previous and current segments each contain only
      ;    a single spin.  This should never happen -- if no averaging
      ;    was applied, the segments should be exactly contiguous.
      ; 5) Negative gap -- current segment starts more than 1/2 spin
      ;    before end of previous segment.  This should never happen,
      ;    since it would imply that the apid 305 packets are incorrectly
      ;    time ordered.
      ;dprint,'seam detected'
      ;print,'Before:
      ;print,lseg
      ;print,newseg
      ;print,'==================================='
      spinper = 360.0D/lseg.b
      gap_spin_count = (newseg.t1 - lseg.t2)/spinper
      gap_time = newseg.t1 - lseg.t2
      if (gap_spin_count GT 0.5) then begin
         ; Case 1: Gap of 1 or more spins between segments, add fill
         ;dprint,'case 1: 1+ spin gap, adding fill segment'
         gap_nspins = floor(gap_spin_count + 0.5)
         gap_spinper = (newseg.t1 - lseg.t2)/(1.0D * gap_nspins)
         ; Fill in eclipse delta_phi parameters
         gap_idpu_spinper = (newseg.idpu_spinper + lseg.idpu_spinper)/2.0
         gap_segflags = newseg.segflags AND lseg.segflags
         ; We need to calculate gap_initial_delta_phi by extrapolating
         ; from lseg to lseg.t2 = gapseg.t1
         segment_interp_t,lseg,lseg.t2,dummy_spincount,dummy_tlast,dummy_spinphase,$
            dummy_spinper,gap_initial_delta_phi
         fillseg = {spinmodel_segment,t1:lseg.t2, t2:newseg.t1, c1:lseg.c2,$
              c2:lseg.c2+gap_nspins,b:360.0D/gap_spinper,c:0.0D,npts:0L,$
               maxgap:gap_time, phaserr:0.0D, $
               initial_delta_phi: 0.0D, $
               idpu_spinper:gap_idpu_spinper, segflags:gap_segflags}
         fillseg.initial_delta_phi = gap_initial_delta_phi
         self.lastseg = self.lastseg+1
         (*sp)[self.lastseg] = fillseg
         ;print,fillseg
         newseg.c1 = fillseg.c2
         newseg.c2 = newseg.c1 + newseg.c2
         self.lastseg = self.lastseg + 1
         (*sp)[self.lastseg] = newseg
         ;print,newseg
      endif else if (gap_spin_count GT -0.5) then begin
         ; Case 2, 3, 4, or 5
         if ((lseg.c2 - lseg.c1) GE 2) then begin
            ; Case 2: small gap, previous segment has at least 2 spins
            ;dprint,'<1 spin gap, stealing spin from last segment'
            c2_new = lseg.c2 - 1

            segment_interp_n,lseg,c2_new,t_last,dummy

            ; Fill in eclipse delta_phi parameters
            gap_idpu_spinper = (newseg.idpu_spinper + lseg.idpu_spinper)/2.0
            gap_segflags = newseg.segflags AND lseg.segflags
            ; We need to calculate gap_initial_delta_phi by extrapolating
            ; from lseg to t_last = fillseg.t1
            segment_interp_t,lseg,t_last,dummy_spincount,dummy_tlast,dummy_spinphase,$
               dummy_spinper,gap_initial_delta_phi

            lseg.c2 = c2_new
            lseg.t2 = t_last
            (*sp)[self.lastseg].c2 = c2_new
            (*sp)[self.lastseg].t2 = t_last
            ;print,lseg
            dt = newseg.t1-t_last
            spinper = dt
            fillseg = {spinmodel_segment,t1:t_last,t2:newseg.t1,c1:c2_new,$
                 c2:c2_new+1,b:360.0D/spinper,c:0.0D,npts:0L,maxgap:dt,$
                 phaserr:0.0D, initial_delta_phi: 0.0D, $
                 idpu_spinper: gap_idpu_spinper, segflags: gap_segflags}
            fillseg.initial_delta_phi = gap_initial_delta_phi
            self.lastseg = self.lastseg + 1
            ;print,fillseg
            (*sp)[self.lastseg] = fillseg
            newseg.c1 = fillseg.c2
            newseg.c2 = newseg.c2 + newseg.c1 
            self.lastseg = self.lastseg + 1
            (*sp)[self.lastseg] = newseg
         endif else if (newseg.c2 GE 2) then begin
            ; Case 3: small gap, previous segment has only 1 spin,
            ; current segment has at least 2 spins
            ;print,'<1 spin gap, stealing spin from next segment'

            ; It is assumed that newseg is the first segment of a
            ; new UTC day, therefore the spin numbers start over
            ; at 0.  So we want to change newseg to start
            ; at spin 1 instead of spin 0.
            segment_interp_n,newseg,1,t_last,dummy

            ; Fill in eclipse delta_phi parameters
            gap_idpu_spinper = (newseg.idpu_spinper + lseg.idpu_spinper)/2.0
            gap_segflags = newseg.segflags AND lseg.segflags
            ; We need to calculate gap_initial_delta_phi by extrapolating
            ; from lseg to lseg.t2 = fillseg.t1
            segment_interp_t,lseg,lseg.t2,dummy_spincount,dummy_tlast,dummy_spinphase,$
               dummy_spinper,gap_initial_delta_phi
            ; We also need to calculate new_initial_delta_phi for newseg,
            ; since we've removed its first spin. New start time is t_last.
            segment_interp_t,newseg,t_last,dummy_spincount,dummy_tlast,dummy_spinphase,$
               dummy_spinper,newseg_initial_delta_phi

            dt = t_last - newseg.t1
            bp = newseg.b + 2.0D*newseg.c*dt
            newseg.b = bp
            newseg.t1 = newseg.t1 + dt
            newseg.c1 = lseg.c2 + 1
            newseg.c2 = newseg.c2 + newseg.c1
            newseg.initial_delta_phi = newseg_initial_delta_phi
            fill_spinper = newseg.t1 - lseg.t2
            gap_time = fill_spinper
            fillseg = {spinmodel_segment,t1:lseg.t2,t2:newseg.t1,c1:lseg.c2,$
                c2:lseg.c2 + 1,b:360.0D/fill_spinper,c:0.0D, npts: 0L,$
                 maxgap: gap_time,phaserr:0.0D, initial_delta_phi: 0.0D,$
                 idpu_spinper: gap_idpu_spinper, segflags: gap_segflags}
            fillseg.initial_delta_phi = gap_initial_delta_phi
            self.lastseg = self.lastseg + 1
            (*sp)[self.lastseg] = fillseg
            self.lastseg = self.lastseg + 1
            (*sp)[self.lastseg] = newseg
         endif else begin
            ; Case 4: small gap, but segments on either side only contain
            ; one spin each.  This should never happen.
            message,'<1 spin gap, but neither segment has enough spins to steal.  This should not happen!'
         endelse
      endif else begin
         ; Case 5: out of order sun pulse times.  This should never happen.
         dprint,'ERROR: Modified segments:'
         dprint,"lseg:"
         help,lseg,/str
         dprint,"fillseg:"
         help,fillseg,/str
         dprint,"newseg:"
         help,newseg,/str
         dprint,"Version:"
         help,!VERSION,/str
         message,'Unexpected (out of order) sun pulse time sequence...this should not happen!'
             
      endelse
      ;print,'Modified segments:'
      ;print,lseg
      ;print,fillseg
      ;print,newseg
   endelse
endelse
end
