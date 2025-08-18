;+
;PROCEDURE: thm_part_time_iterator
;PURPOSE:  An accessor method to make it easier to iterate
;  particle distributions that are regularly gridded in time
;  but not in mode.(e.g. after thm_part_time_interpolate has been used to match time grids)
;
;INPUTS:
; dist_array: The array of particle distribution mode pointers to be interated
;
;OUTPUTS: 
;  dist_struct(optional): an individiual distribution structure being returned
;
;KEYWORDS:
; nelements=nelements:  Query the total number of elements and return
; index=index:  The index for the distribution that should be returned(default=0)
; set=set: If this keyword is set, then dist_struct will be stored at index instead of returned from index
;
; SEE ALSO:
;  thm_part_time_interpolate, thm_part_dist_array, thm_part_smooth, thm_part_subtract,thm_part_omni_convert
;
; EXAMPLE:
; 
; thm_part_time_iterator,dist_psif,nelements=n
; for i = 0,n-1 do begin
;   thm_part_time_iterator,dist_psif,s,index=i
;   s.data*=2
;   thm_part_time_iterator,dist_psif,s,index=i,/set
; endfor
;
; TODO:
;   This is routine is primarily for simplifying user interaction with particle distribution structures,
;     but I think it could be used to simplify/clarify other routines in the SEE ALSO section.
;
;  $LastChangedBy: pcruce $
;  $LastChangedDate: 2015-03-11 13:34:12 -0700 (Wed, 11 Mar 2015) $
;  $LastChangedRevision: 17117 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_time_iterator.pro $
;-
pro thm_part_time_iterator,dist_array,dist_struct,nelements=nelements,index=index,set=set

  compile_opt idl2,hidden

  if arg_present(nelements) then begin
    
    nelements = 0
    for i =0,n_elements(dist_array)-1 do begin
      nelements+=n_elements(*dist_array[i])
    endfor
    return
    
  endif
  
  if ~keyword_set(index) then begin
    index=0
  endif

  t = 0
  for i = 0,n_elements(dist_array)-1 do begin
    if t+n_elements(*dist_array[i]) gt index then begin
      if keyword_set(set) then begin
        (*dist_array[i])[index-t]=dist_struct
      endif else begin
        dist_struct=(*dist_array[i])[index-t]
      endelse
      return
    endif else begin
      t+=n_elements(*dist_array[i])
    endelse
  endfor

end