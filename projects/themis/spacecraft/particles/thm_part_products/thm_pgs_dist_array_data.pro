;+
;Procedure:
;  thm_pgs_dist_array_data
;
;Purpose:
;  Returns the selected data structure, increments the dist_array indexes
;
;Input:
;  dist_array: A dist-array data structure
;  dist_ptr_index=dist_ptr_index: dist_ptr_index for the dist_array(modifed by this routine)
;  dist_seg_index=dist_seg_index: dist_seg_index for the dist_array(modified by this routine)
;Output:
;  data=data:  The data structure idenfitied by the indexes
;
;Notes:
;
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2013-07-12 13:17:02 -0700 (Fri, 12 Jul 2013) $
;$LastChangedRevision: 12674 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_products/thm_pgs_dist_array_data.pro $
;-
pro thm_pgs_dist_array_data,dist_array,dist_ptr_idx=dist_ptr_idx,dist_seg_idx=dist_seg_idx,data=data

  compile_opt idl2, hidden
  
  ;get data
  data = (*dist_array[dist_ptr_idx])[dist_seg_idx]
  ;increment
  dist_seg_idx++
  ;rollover to next mode segment
  if dist_seg_idx eq n_elements(*dist_array[dist_ptr_idx]) then begin
    dist_seg_idx=0
    dist_ptr_idx++
  endif
   
end
