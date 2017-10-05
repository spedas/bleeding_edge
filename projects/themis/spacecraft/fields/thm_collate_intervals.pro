;+
;Purpose: Takes a bunch of intervals from different data sources and
;collates all intervals of the same source into a single vector(may be multidimensional)
;
;keywords:
;         r: an array of data with dimensions [time,samples,sources]
;         s: an array of source s[i] indices should have the source index of [*,*,i]
;
;         returns: an array with dimensions [time,samples,sources] but
;         all sources will be unique(ie the size of the output sources
;         will be <= the input sources)
;
;Notes: --Used by thm_cal_fft,thm_cal_fbk
;       --The returned data will be sorted according to source index in
;       ascending order
;-

;used to stick individual intervals together
;i2 clobbers i1 on collisions
function thm_compose_intervals, i1, i2

  idx = where(finite(i2))

  r = i1

  r(idx) = i2(idx)

  return, r

end

;r = the array of results
;s = the sel list
function thm_collate_intervals, r, s1

  if(n_elements(s1) eq 0) then return, r

  ;sort by source
  idx = sort(s1)

  s = s1[idx]

  d_arr = r(*, *, idx)

  idx = where(s ne shift(s, 1L), cnt)

  ;output array

  if(cnt gt 0) then $
    o_arr = d_arr(*, *, idx) $
  else $
    o_arr = d_arr(*, *, 0)

  o_arr_cnt = 0

  ;collate the intervals
  for i = 1, n_elements(s)-1L do begin

    if(s[i] eq s[i-1]) then $
      o_arr[*,*,o_arr_cnt] = thm_compose_intervals(o_arr[*, *, o_arr_cnt], d_arr[*, *, i]) $
    else $
      o_arr_cnt += 1

  endfor

  return, o_arr

end
