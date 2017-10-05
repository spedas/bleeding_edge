;+
;Purpose:returns a unique list of source names from constructed from a non-unique list
;of source indices
;
;Keywords:
;        src_idx: an array of source indices
;        sel_str: an array of source strings
;
;Returns: an array of unique source strings, the length of which will
;be less than or equal to the length of s
;
;Notes: --the sel_string will be returned in ascending sorted order
;              according to their index.
;       --used in thm_cal_fft,thm_cal_fbk
;       --a similiar function is used to get the proper cp element
;           any changes here should probably be mirrored there
;

function thm_get_unique_sel, src_idx, sel_str

  s = src_idx

;get unique indices
  s = s[sort(s)]

  idx = where(s ne shift(s, 1L), cnt)

  out = strarr(cnt>1)

  out[*] = 'undef'

  if(cnt gt 0) then $
    s = s[idx] $
  else $
    s = s[0]

  ;filter out of range values

  idx = where((s ge 0) or (s lt n_elements(sel_str)), cnt)

  if(cnt eq 0) then return, out

  out[idx] = sel_str[fix(s[idx])]

  return, out

end
