;+
;Procedure:
;  thm_pgs_dist_array_times
;
;Purpose:
;  Concatenates a 1-d array of times from a thm_part_dist_array structure
;
;Input:
;  dist_array: A dist-array data structure
;
;Output:
;  times: An array of times
;
;Notes:
;  
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2013-07-12 11:09:50 -0700 (Fri, 12 Jul 2013) $
;$LastChangedRevision: 12671 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_products/thm_pgs_dist_array_times.pro $
;-
pro thm_pgs_dist_array_times,dist_array,times=times

    compile_opt idl2, hidden

    ;concatenate times into a single sequence
    for i = 0,n_elements(dist_array)-1 do begin
      times = array_concat((*dist_array[i]).time,times)
    endfor

   
end