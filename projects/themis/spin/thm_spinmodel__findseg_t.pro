
;+
; NAME:
;    SPINMODEL_FINDSEG_T
;
; PURPOSE:
;    Finds indexes of spin model segments matching each time.
;
; CATEGORY:
;   TDAS
;
; CALLING SEQUENCE:
;  model->spinmodel_findseg_t,t
;
;  INPUTS:
;    model: spin model, reference to object of type 'thm_spinmodel'
;    t: array of times to which model segments will be matched
;
;  RETURNS:
;    an array of matching indexes.  Throws error using 'message' routine on failure.
;
;  PROCEDURE:
;
;  
;  EXAMPLE:
;
;  
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2011-05-09 11:16:41 -0700 (Mon, 09 May 2011) $
;$LastChangedRevision: 8651 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spin/thm_spinmodel__findseg_t.pro $
;-


;vectorized implementation
function thm_spinmodel::findseg_t,t


  sp = self.segs_ptr
  seg_t1 = (*sp)[*].t1
  seg_t2 = (*sp)[*].t2
  n = n_elements(seg_t1)
  
  if n eq 1 then return,lon64arr(n_elements(t))
  
  idx_t1 = 0 > value_locate(seg_t1,t,/l64) < (n-1) ;these look like gt/lt operators, but they're actually min/max; used to clip data into range
  idx_t2 = -1 > value_locate(seg_t2,t,/l64) < (n-2)
  
  idx_tmp1 = where(idx_t1 ne idx_t2+1,c)
  
  if c ne 0 then begin
    message,'Internal error: Time does not match spinmodel segments.'
  endif
  
  return,idx_t1
  
end


;Old iterative implementation
;currseg = (*sp)[self.index_t]
;if ( (currseg.t1 LE t) AND (t LE currseg.t2) ) then begin
;  return, self.index_t
;endif else if (t LE (*sp)[0].t1) then begin
;  self.index_t = 0
;  return, self.index_t
;endif else if (t GE (*sp)[self.lastseg].t2) then begin
;  self.index_t = self.lastseg
;  return, self.index_t
;endif else if (t LE currseg.t1) then begin
;  start_index = 0
;endif else start_index = self.index_t + 1
;
;idx = where((*sp).t1 le t and t lt (*sp).t2,c)
;if c lt 1 then begin
;  message,'Internal error: no spinmodel segments match input time.'
;endif else if c gt 1 then begin
;  message,'Internal error: multiple spinmodel segments match input time.'
;endif else begin
;  self.index_t = idx
;  return,self.index_t
;endelse

;for i=start_index,self.lastseg,1 do begin
;  currseg = (*sp)[i]
;  if ((currseg.t1 LE t) AND (t LE currseg.t2)) then begin
;     self.index_t = i
;     return, self.index_t
;  endif 
;endfor
;end
