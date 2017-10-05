;+
;Procedure:
;  thm_part_set_counts
;
;Purpose:
;  Perform the somewhat common task of setting all data
;  in the distribution to a particular number of counts.
;
;Calling Sequence:
;  thm_part_set_counts, dist_array, counts [,set_units]
;
;Input:
;  dist_array:  pointer array containing particle data (see thm_part_dist_array)
;  counts:  number of counts to set the distribution to
;  set_units:  flag to set the units_name field to 'counts'
;
;Example:
;  ;set all data in the distribution to 1 count
;  thm_part_set_counts, dist_array, 1.
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-24 11:08:03 -0700 (Thu, 24 Mar 2016) $
;$LastChangedRevision: 20582 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_set_counts.pro $
;
;-

pro thm_part_set_counts, data, counts, set_units=set_units

    compile_opt idl2, hidden


if in_set(ptr_valid(data),0) then begin
  dprint, dlevel=1, 'Invalid input data; must be pointer array from thm_part_dist_array'
  return
endif


if undefined(counts) || ~is_num(counts) then begin
  dprint, dlevel=1, 'Invalid counts; please enter a valid number'
  return
endif


;set all bins to requested value
for i=0, n_elements(data)-1 do begin
  (*data[i]).data = float(counts)
  if keyword_set(set_units) then begin
    (*data[i]).units_name = 'counts'
  endif
endfor


end