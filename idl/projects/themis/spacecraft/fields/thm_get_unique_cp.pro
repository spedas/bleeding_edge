;+
;Purpose:returns a unique list of cp names that corresponds to the
;sel_strings returned by thm_get_unique_sel.pro
;
;Keywords: 
;        src_idx: an array of source indices
;        sel_str: the sel strings used in sel source selection
;        cp_list: an array of cp's corresponding to those indices
;
;Returns: an array of unique cp's structs the correspond to the
;selected sel_string
;
;Notes: --used in thm_cal_fft,thm_cal_fbk
;       --any changes here should probably be mirrored in thm_get_unique_sel.pro
;
function thm_get_unique_cp,src_idx,sel_str,cp_list

  s = src_idx
  cpl=cp_list

  ;get unique indices
  idx = sort(s)

  s = s[idx]

  cpl = cpl[idx]


  idx = where(s ne shift(s, 1L), cnt)

  if(cnt gt 0) then begin
      s = s[idx]
      cpl = cpl[idx]
  endif else begin
      s = s[0]
      cpl = cpl[0]
  endelse

  ;filter out of range values
  idx = where((s ge 0) or (s lt n_elements(sel_str)), cnt)

  if(cnt eq 0) then return, cpl

  return, cpl[idx]

end
