FUNCTION mms_bss_filter_by_flag, s, isPending=isPending,$
  inPlayList=inPlayList, idx=idx
  compile_opt idl2
  if n_elements(idx) eq 1 && idx[0] lt 0 then begin
    return, -1
  endif
  if n_elements(idx) eq 0 then begin
    idx_old = lindgen(n_elements(s.FOM))
  endif else begin
    idx_old = idx
  endelse
  if n_elements(isPending) eq 1 then begin
    midx = where(s.isPENDING[idx_old] eq isPending,ct)
    if ct gt 0 then idx_new = idx_old[midx] else idx_new = idx_old
  endif
  if n_elements(inPlaylist) eq 1 then begin
    midx = where(s.inPLAYLIST[idx_old] eq inPlayList, ct)
    if ct gt 0 then idx_new = idx_old[midx] else idx_new = idx_old
  endif
  return, idx_new
END