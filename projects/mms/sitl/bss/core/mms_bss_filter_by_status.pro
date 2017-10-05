; This function filters burst-segment-status structure 's' by a 'status'
; If the keyword 'idx' is set, then the structure of those idx segments will be
; searched and filtered. If 'idx' is omitted, then all segments of the structure
; 's' will be examined. 
FUNCTION mms_bss_filter_by_status, s, status,idx=idx,ex=ex
  compile_opt idl2
  if n_elements(idx) eq 1 && idx[0] lt 0 then begin
    return, -1
  endif
  statuslow = '*'+strlowcase(status)+'*'
  if n_elements(idx) eq 0 then begin
    idx_old = lindgen(n_elements(s.STATUS))
  endif else begin
    idx_old = idx
  endelse  
  midx = where(strmatch(strlowcase(s.STATUS[idx_old]),statuslow), ct,$
    complement=exidx, ncomplement=nct)
  if keyword_set(ex) then begin
    idx_new = (nct gt 0) ? idx_old[exidx] : -1
  endif else begin
    idx_new = (ct gt 0) ? idx_old[midx] : -1
  endelse
  return, idx_new
END
