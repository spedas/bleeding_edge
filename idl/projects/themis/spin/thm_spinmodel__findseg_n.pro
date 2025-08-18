function thm_spinmodel::findseg_n,n
sp = self.segs_ptr
currseg = (*sp)[self.index_n]
if ( (currseg.c1 LE n) AND (n LE currseg.c2) ) then begin
  return, self.index_n
endif else if (n LE (*sp)[0].c1) then begin
  self.index_n = 0
  return, self.index_n
endif else if (n GE (*sp)[self.lastseg].c2) then begin
 self.index_n = self.lastseg
  return, self.index_n
endif else if (n LE currseg.c1) then begin
  start_index = 0
endif else start_index = self.index_n + 1

idx = where((*sp).c1 le n and n lt (*sp).c2,c)
if c lt 1 then begin
  message,'Internal error: no spinmodel segments match input spin count.'
endif else if c gt 1 then begin
  message,'Internal error: multiple spinmodel segments match input spin count.'
endif else begin
  self.index_n = idx
  return,self.index_n
endelse

;for i=start_index,self.lastseg,1 do begin
;  currseg = (*sp)[i]
;  if ((currseg.c1 LE n) AND (n LE currseg.c2))then begin
;     self.index_n = i
;     return, self.index_n
;  endif 
;endfor
end
