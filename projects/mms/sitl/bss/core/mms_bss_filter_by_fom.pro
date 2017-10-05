; This function extracts segments that have 
;
; FOM larger than or equal to frange[0]
; and
; FOM smaller than frange[1]
;
FUNCTION mms_bss_filter_by_fom, s, frange, idx=idx
  compile_opt idl2
  if n_elements(idx) eq 1 && idx[0] lt 0 then begin
    return, -1
  endif
  if n_elements(idx) eq 0 then begin
    idx = lindgen(n_elements(s.FOM))
  endif
  idx_old = idx
  idx = where(frange[0] le s.FOM[idx_old] and s.FOM[idx_old] lt frange[1], ct)
  idx_new = (ct gt 0) ? idx_old[idx] : -1
  return, idx_new
END