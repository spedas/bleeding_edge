;+
;Procedure:
;  thm_part_slice2d_getsun
;
;
;Purpose:
;  Helper function for thm_part_slice2d.
;  Retrieves sun vectors for all distributions within
;  the specified time range and averages them.
;
;
;Input:
;  ds: (pointer) Pointer array to particle distribution structures.
;  trange: (double) Two element time range for the slice.
;
;
;Output:
;  Returns averaged sun vector (3-vector float) on success or 0 on failure.
;
;
;Notes:
;  This assumes that the spacecraft-sun vector is roughly constant over
;  the time range of the slice.
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-04 18:05:22 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20331 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/core/thm_part_slice2d_getsun.pro $
;
;-

;Returns sun vector or 0 on error
;
; If multiple distributions are being used the sun vector 
; will be determined by averaging.  
; 
function thm_part_slice2d_getsun, ds, trange=trange, fail=fail

    compile_opt idl2, hidden


  ; get sun vector data added in thm_part_dist_array
  for i=0, n_elements(ds)-1 do begin
    
    if ~in_set( 'sun_vector', strlowcase(tag_names(*ds[i])) ) then continue 
    
    ; only use data in requested time range
    times_ind = thm_part_slice2d_intrange(ds[i], trange, n=ndat)
    if ndat gt 0 then begin
      svs = ~keyword_set(svs) ? [ (*ds[i])[times_ind].sun_vector ]  :  $
                                [ [svs], [(*ds[i])[times_ind].sun_vector] ]
    endif
  endfor 
  
  ; assume sun vector was not requested if no data is present
  if ~keyword_set(svs) then begin
    return, 0
  endif

  ; average
  sun_vector = average(svs, 2) 
  
  
;  ;TESTING ******************  
;  ;Check that angle between vectors is not too large
;  rsvs = reform(sun_vector) # replicate(1.,dimen2(svs))
;  ca = total(  svs * rsvs ,1)     /      $
;       ( sqrt(total(svs^2,1)) * sqrt(total(rsvs^2,1)) ) 
;  a = acos(ca < 1) * 180/!pi * 60
;  print, string(10b) + 'sun vec diffs from ave (minutes)' 
;  print, a
;  ;**************************
  
  
  ; Check for NaNs that could signify an error
  if in_set(finite(sun_vector), 0) then begin
    dprint, dlevel=0, 'Error: Invalid sun vector retrieved for '+ $
                      time_string(trange[0])+' to '+time_string(trange[1]) 
    return, 0
  endif


  return, sun_vector

end
