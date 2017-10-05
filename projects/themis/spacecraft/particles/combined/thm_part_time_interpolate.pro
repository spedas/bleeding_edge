;+
;PROCEDURE: thm_part_time_interpolate
;PURPOSE:  Interpolate particle data to match the time grid of another distribution, or to an arbitary time grid
;
;INPUTS:
;  source: A particle dist_data structure to be modified by interpolation to match target
;  target: A particle dist_data structure whose times will be matched, or an array of target times for interpolatuion.
;  
;OUTPUTS:
;   Replaces source with a time interpolated dist_data structure
;
;KEYWORDS: 
;  error: Set to 1 on error, zero otherwise
;  
; NOTES:
;   Any target times that occur between modes will contain samples filled with NANs.  Effective interpolation is very very tricky between modes.(Read: It will probably never happen)
;   Accepts any keywords normally accepted by IDL interpol
;   
;   This has a done of TBDs, we need to come back and fix them when time is available.
; SEE ALSO:
;   thm_part_dist_array, thm_part_smooth, thm_part_subtract,thm_part_omni_convert
;
;  $LastChangedBy: jimm $
;  $LastChangedDate: 2017-10-02 11:19:09 -0700 (Mon, 02 Oct 2017) $
;  $LastChangedRevision: 24078 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/combined/thm_part_time_interpolate.pro $
;-


pro thm_part_time_interpolate,source,target,error=error,_extra=ex

  compile_opt idl2

  error = 1
  
  ;input validation TBD
  
  ;handling of time array inputs TBD 
  
  ;TBD interpolate all fields
  
  ;concatenate time list from all target modes
  for i = 0,n_elements(target)-1 do begin
    target_mid_times = array_concat(((*target[i]).time+(*target[i]).end_time)/2d,target_mid_times)        
    target_delta_times = array_concat(((*target[i]).end_time-(*target[i]).time),target_delta_times)    
  endfor
  
  
  for i = 0,n_elements(source)-1 do begin
  
    ;handle target times that occur between modes.  Since we can't interpolate these reliably in the general case, we're treating them as missing data
    if i eq 0 then begin ;This handles the case where we're checking for all targets before the first source mode
      idx = where(target_mid_times lt min((*source[0]).time),c)
      if c gt 0 then begin
        out_dist = ptr_new(replicate((*source[0])[0],c))
        (*out_dist[0]).time = target_mid_times[idx]-target_delta_times[idx]/2d ;using the target time width to resize the time bin after interpolation only works because the spacecraft runs in snapshot mode 
        (*out_dist[0]).end_time = target_mid_times[idx]+target_delta_times[idx]/2d 
        (*out_dist[0]).data = !VALUES.D_NAN
      endif
    endif else begin ;this handles the case where we're checking for all targets between modes(we can't interpolate between modes because the data may not match)
      idx = where(target_mid_times lt min((*source[i]).time) and target_mid_times gt max((*source[i-1]).end_time),c)
      if c gt 0 then begin
        out_dist = array_concat(ptr_new(replicate((*source[i])[0],c)),temporary(out_dist))
        (*out_dist[n_elements(out_dist)-1]).time = target_mid_times[idx]-target_delta_times[idx]/2d ;using the target time width to resize the time bin after interpolation only works because the spacecraft runs in snapshot mode 
        (*out_dist[n_elements(out_dist)-1]).end_time = target_mid_times[idx]+target_delta_times[idx]/2d
        (*out_dist[n_elements(out_dist)-1]).data = !VALUES.D_NAN
      endif
    endelse
    
    ;This handles the case where we're checking for targets within modes
    idx = where (target_mid_times ge min((*source[i]).time) and target_mid_times le max((*source[i]).end_time),c)
    if c gt 0 then begin  
      out_data = replicate((*source[i])[0],c)
      
      tag_names=tag_names(out_data[0])
    
      if n_elements(*source[i]) gt 1 then begin ;need more than one source struct to interpolate, otherwise, we default to the copy from the replicate above
        for j=0,n_elements(tag_names)-1 do begin
          if is_num(out_data[0].(j)) then begin
            for k = 0,n_elements(out_data[0].(j))-1 do begin
              out_data.(j)[k] = interpol((*source[i]).(j)[k],((*source[i]).time+(*source[i]).end_time)/2d,target_mid_times[idx],_extra=ex) ;The assumption with this interpolation is that it will be valid for any data that are changing over time within a mode.  For others, it should not change the data.(because it is constant)
            endfor
          endif else if n_elements(out_data[0].(j)) ne 1 then begin ;single element non-numeric are copied
            message,'Panic!' ;arrays of non-numeric types, no way to handle...eeeekkk!!
          endif 
        endfor
      endif
      ;guarantees that final times match target exactly
      out_data.time = target_mid_times[idx]-target_delta_times[idx]/2d 
      out_data.end_time = target_mid_times[idx]+target_delta_times[idx]/2d 
      
      
      ;temporary routine bombs on some machines if out_dist is undefined, but not others
      if ~undefined(out_dist) then begin 
        out_dist = array_concat(ptr_new(out_data,/no_copy),temporary(out_dist))
      endif else begin
        out_dist = array_concat(ptr_new(out_data,/no_copy),out_dist)
      endelse
    endif
  endfor
  
  ;This handles the case where we're checking for all targets after the last mode
  idx = where(target_mid_times gt max((*source[n_elements(source)-1]).end_time),c)
  if c gt 0 then begin
    out_dist = array_concat(ptr_new(replicate((*source[n_elements(source)-1])[0],c)),out_dist)
    (*out_dist[n_elements(out_dist)-1]).time = target_mid_times[idx]-target_delta_times[idx]/2d ;using the target time width to resize the time bin after interpolation only works because the spacecraft runs in snapshot mode 
    (*out_dist[n_elements(out_dist)-1]).end_time = target_mid_times[idx]+target_delta_times[idx]/2d
    (*out_dist[n_elements(out_dist)-1]).data = !VALUES.D_NAN
  endif
  
  source=temporary(out_dist) 
  heap_gc ; remove pointers whose references were just deleted
  
  error = 0

end
