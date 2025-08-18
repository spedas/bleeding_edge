;+
;Procedure:
;  thm_pgs_dist_array_start
;
;Purpose:
;  Identifies the start indexes for the dist_array data structure
;
;Input:
;  dist_array: A dist-array data structure
;  time_idx: A 1-d array of indexes into a time array
;Output:
;  dist_ptr_idx: The index to the starting mode for the requested time range
;  dist_seg_idx: The index to the first sample of the mode for the requested time range 
;
;Notes:
;
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2013-07-12 11:09:50 -0700 (Fri, 12 Jul 2013) $
;$LastChangedRevision: 12671 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_products/thm_pgs_dist_array_start.pro $
;-
pro thm_pgs_dist_array_start,dist_array,time_idx,dist_ptr_idx=dist_ptr_idx,dist_seg_idx=dist_seg_idx

  compile_opt idl2, hidden
  
  dist_seg_idx = time_idx[0]
  
  ;find segment and subsegment index for the beginning of the requested time interval
  for dist_ptr_idx = 0,n_elements(dist_array)-1 do begin
    if dist_seg_idx lt n_elements(*dist_array[dist_ptr_idx]) then begin
      return
    endif
    dist_seg_idx-=n_elements(*dist_array[dist_ptr_idx])
  endfor
  
end