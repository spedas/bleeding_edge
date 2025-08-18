
;+
; NAME:
;    SEGMENT_INTERP_T
;
; PURPOSE:
;    Performs interpolation on individual elements. (Now a vectorized implementation, accepts multiple inputs)
;
; CATEGORY:
;   TDAS
;
; CALLING SEQUENCE:
;  segment_interp_t,segments,t,spincount,t_last,spinphase,spinper,segflag,eclipse_delta_phi
;
;  INPUTS:
;    segments: Segment struct from spinmodel
;    t: target time array for interpolation(number of elements must match segments)
;
;  OUTPUTS:
;    spincount,t_last,spinphase,segflag,eclipse_delta_phi
;
;  KEYWORDS:
;    mask=Set to mask value or array of mask value(with same number of elements as segments)
;
;  PROCEDURE:
;
;  
;  EXAMPLE:
;
;  
;
;$LastChangedBy: bsadeghi $
;$LastChangedDate: 2012-05-22 10:48:29 -0700 (Tue, 22 May 2012) $
;$LastChangedRevision: 10447 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spin/segment_interp_t.pro $
;-

pro segment_interp_t,segments,t,spincount,t_last,spinphase,spinper,segflag,eclipse_delta_phi,mask=mask
  ; eclipse_delta_phi is zero, unless the bits specified in mask are all set.
  ; For testing, assume mask=1
  
  
  n = n_elements(segments)
  
  ;output variables
  spincount = dblarr(n)
  t_last = dblarr(n)
  spinphase = dblarr(n)
  spinper = dblarr(n)
  segflag = segments[*].segflags
  eclipse_delta_phi = dblarr(n) ;It is important that this variable is initialized to 0
  
  ;Internal variables. 
  ;If memory becomes an issue, we can avoid allocating by using some creative index operations
  dt = dblarr(n)
  fracspins = dblarr(n)
  intspins = dblarr(n)
  bp = dblarr(n)
  phi_lastpulse = dblarr(n) 
  tlast_dt = dblarr(n)
  
  if ~keyword_set(mask) then mask=1
  
  if n_elements(mask) eq 1 then begin
    mask = replicate(mask,n)
  endif
  
  ;orignal version was a series of nested-ifs operating on single elements, 
  ;these where functions allow vectorized operations on each sub-block and flatten logic a bit
  ;this increases speed significantly at the cost of increased memory usage. 
  idx1 = where(t lt segments[*].t1,c1)
  idx2 = where(t gt segments[*].t2,c2) 
  
  ;each of the conditions below splits based on the truth of this sub-clause
  branch1_idx = where(abs(segments[*].c) lt 1D-12,branch1_c,complement=branch1_cidx,ncomplement=branch1_nc)
  branch2_idx = where(((segments[*].segflags AND mask) EQ mask) AND (segments[*].idpu_spinper GT 1.0D))
  
  idx3 = where(t ge segments[*].t1 and t le segments[*].t2,c3)
  ;idx4 = where(t ge segments[*].t1 and t le segments[*].t2 and abs(segments.c) ge 1.0D-12,c4) 
  
  if c1 gt 0 then begin
  
    dt [idx1]= segments[idx1].t1 - t[idx1]
    spinper[idx1] = 360.0D/segments[idx1].b
    fracspins[idx1] = dt[idx1]/spinper[idx1]
    intspins[idx1] = ceil(fracspins[idx1])
    spinphase[idx1] = (intspins[idx1]-fracspins[idx1])*360.0D
    spincount[idx1] = segments[idx1].c1 - intspins[idx1]
    t_last[idx1] = segments[idx1].t1 - intspins[idx1]*spinper[idx1]
  ;  eclipse_delta_phi[idx1] = 0.0D ;redundant, initialized to zero
  endif
  
  if c2 gt 0 then begin
    dt[idx2] = t[idx2]-segments[idx2].t2
    bp[idx2] = segments[idx2].b + 2.0D*segments[idx2].c*(segments[idx2].t2-segments[idx2].t1)
    spinper[idx2] = 360.0D/bp[idx2]
    fracspins[idx2]=dt[idx2]/spinper[idx2]
    
    idx2_branch = ssl_set_intersection(idx2,branch2_idx) 
    
    if idx2_branch[0] ne -1 then begin
      model_phi = fracspins[idx2_branch]*360.0D
      idpu_bp = 360.0D/segments[idx2_branch].idpu_spinper
      idpu_phi = dt[idx2_branch]*idpu_bp
      eclipse_delta_phi[idx2_branch] = segments[idx2_branch].initial_delta_phi + (model_phi - idpu_phi)
    endif
    
    intspins[idx2] = floor(fracspins[idx2])
    spinphase[idx2] = (fracspins[idx2]-intspins[idx2])*360.0D
    spincount[idx2] = segments[idx2].c2 + intspins[idx2]
    t_last[idx2] = segments[idx2].t2 + intspins[idx2]*spinper[idx2]
  endif
  
  if c3 gt 0 then begin
    dt[idx3] = t[idx3]-segments[idx3].t1
    phi = segments[idx3].b*dt[idx3] + segments[idx3].c*dt[idx3]*dt[idx3]
    bp[idx3] = segments[idx3].b+2.0D*segments[idx3].c*dt[idx3]
    spinper[idx3] = 360.0D/bp[idx3]
    spinphase[idx3] = phi mod 360.0D
    fracspins[idx3] = phi/360.0D
    spincount[idx3] = floor(fracspins[idx3])
    phi_lastpulse[idx3] = spincount[idx3]*360.0D
  
    if branch1_c gt 0 then begin
      tlast_dt[branch1_idx] = phi_lastpulse[branch1_idx]/segments[branch1_idx].b
    endif
    
    if branch1_nc gt 0 then begin
      tlast_dt[branch1_cidx] = (-segments[branch1_cidx].b + sqrt(segments[branch1_cidx].b^2 - $
                                4.0*segments[branch1_cidx].c*(-phi_lastpulse[branch1_cidx]))) / $
                               (2.0*segments[branch1_cidx].c)
    endif
    
    idx3_branch = ssl_set_intersection(idx3,branch2_idx) 
    
    if idx3_branch[0] ne -1 then begin
      model_phi = fracspins[idx3_branch]*360.0D
      idpu_bp = 360.0D/segments[idx3_branch].idpu_spinper
      idpu_phi = dt[idx3_branch]*idpu_bp
      eclipse_delta_phi[idx3_branch] = segments[idx3_branch].initial_delta_phi + (model_phi - idpu_phi)
    endif
  
    t_last[idx3] = segments[idx3].t1 + tlast_dt[idx3]
    spincount[idx3] = spincount[idx3]+segments[idx3].c1 
  
  endif
  
end
