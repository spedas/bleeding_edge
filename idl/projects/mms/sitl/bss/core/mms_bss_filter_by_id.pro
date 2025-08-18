FUNCTION mms_bss_filter_by_id, s, IDs, idx=idx
  compile_opt idl2
  if n_elements(idx) eq 1 && idx[0] lt 0 then begin
    return, -1
  endif
  if n_elements(idx) eq 0 then begin
    idx = lindgen(n_elements(s.DATASEGMENTID))
  endif
  idx_old = idx
  match, s.DATASEGMENTID[idx_old], IDs, idx, subuser, count=ct
  idx_new = (ct gt 0) ? idx_old[idx] : -1
  return, idx_new
END
