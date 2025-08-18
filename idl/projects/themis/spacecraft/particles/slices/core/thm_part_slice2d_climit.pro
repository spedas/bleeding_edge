;+
;Procedure:
;  thm_part_slice2d_climit
;
;
;Purpose:
;  Helper function for thm_part_slice2d_getxyz
;
;
;Input:
;  dist: 3D particle data structure (UNSANITIZED)
;  datatpoints: final averaged data array from thm_part_slice2d_getxyz
;  units: string specifying units (e.g. 'eflux', 'df')
;  subtract_counts: (float) subtract this many counts from all values 
;  count_threshold: (float) removed datapoints with less than this number of counts
;
;
;Output:
;  none, modifies datapoints
;
;
;Notes:
;
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-04 18:05:22 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20331 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/core/thm_part_slice2d_climit.pro $
;
;-
pro thm_part_slice2d_climit, dist, datapoints, $
                             units=units, $
                             regrid=regrid, $
                             subtract_counts=subtract_counts, $
                             count_threshold=count_threshold

    compile_opt idl2, hidden
    

  ;Apply count limits/subtraction
  if keyword_set(count_threshold) or keyword_set(subtract_counts) then begin
    
    threshold = keyword_set(subtract_counts) ? subtract_counts:count_threshold

    ;get array of values in the specified units for the given threshold 
    thresh = thm_part_slice2d_ncount(dist, units, threshold, regrid=regrid)
    
    if n_elements(thresh) eq n_elements(datapoints) then begin
      
      if keyword_set(subtract_counts) then begin
        datapoints = (datapoints - thresh) > 0
        dprint, dlevel=4, 'Subtracting '+strtrim(threshold,2)+ $
                          ' counts from all bins in "'+dist.data_name+'"'
      endif else begin
        ltidx = where(datapoints lt thresh, nlt)
        if nlt gt 0 then datapoints[ltidx] = 0.
        dprint, dlevel=4, 'Removing '+strtrim(nlt,2)+$
                          ' bins below one count from "'+dist.data_name+'"'
      endelse
    endif else begin
      dprint, dlevel=0, 'Error matching count threshold to distribution. ' + $
                        'Bins below threshold could not be subtracted!'
    endelse
  endif
  
end