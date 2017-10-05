
;+
;NAME:
;  thm_part_remove.pro
;
;
;PURPOSE:
;  Remove bins that fall below a specified # of counts from any 3D particle data structure.
;
;
;CALLING SEQUENCE:
;  thm_part_remove, dist, threshold=threshold, [/zero], [/remove]
;
;
;INPUT ARGUMENTS:
;  dist:  Particle distribution(s).
;         Can be single or array of structure(s) or pointer(s) to structure(s).
;  threshold:  The value below wich data points will be removed or zeroed.
;              Must be in the same units as the input data.
;
;
;KEYWORDS:
;  zero:  (default) Data below the threshold will be set to zero.
;  remove:  Data below the threshold will be removed.  Specifically,
;           the data will be set to NaN and the bin flag set to off.
;           
;
;NOTES:
;   
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-08-24 18:29:05 -0700 (Wed, 24 Aug 2016) $
;$LastChangedRevision: 21724 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_remove.pro $
;-

pro thm_part_remove, dist, threshold=threshold, remove=remove, zero=zero

    compile_opt idl2, hidden


  ;check distribution type
  if is_struct(dist) then begin
    ;create pointer to structure to allow for uniform handling below
    ;avoid creating copy
    ptrs = ptr_new(dist,/no_copy)
  endif else if total(~ptr_valid(dist)) eq 0 then begin
    ptrs = dist
  endif else begin
    dprint, dlevel=1, 'ERROR: Invalid distribution, input must be valid structure or pointer array.'
    return
  endelse
  
  if undefined(threshold) then threshold = 1
  
  ;check input threshold
  if ~is_numeric(threshold) then begin
    dprint, dlevel=1, 'ERROR: Invalid threshold, input must be a numeric value.'
    return
  endif else begin
    thresh = threshold
  endelse
  
  
  ;zero bins by default
  if ~keyword_set(remove) then zero = 1b
  
  
  ;loop over all present distribution arrays and apply requested behavior
  for i=0, n_elements(ptrs)-1 do begin
    
    ptr = ptrs[i]
    above = (*ptrs[i]).data gt thresh
     
   ;zero the flag
    if keyword_set(remove) then begin
      (*ptrs[i]).bins = (*ptrs[i]).bins and above 
    endif else if keyword_set(zero) then begin
      ;zero the bins
      (*ptrs[i]).data = (*ptrs[i]).data * above 
    endif
      
  endfor

  ;unfortunately IDL can't create a pointer without either
  ;copying the target or leaving it undefined...
  if undefined(dist) then begin
    dist = temporary(*ptrs)
  endif

  return


end
