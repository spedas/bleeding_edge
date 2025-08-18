;+
;Procedure:
;  thm_part_slice2d_intrange
;
;
;Purpose:
;  Helper function for thm_part_slice2d.
;  Retrieves the indices of all samples in the specified
;  time range from a particle distribution pointer.
;
;
;Input:
;  ds: (pointer) Single particle distribution pointer.
;  trange: (double) Two element array specifying the slice's time range.
;
;
;Output:
;  return value: indices of all sample within trange.
;  n: number of samples
;
;
;Notes:
;  Uses the center of each sample's time window.
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-04 18:05:22 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20331 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/core/thm_part_slice2d_intrange.pro $
;
;-
function thm_part_slice2d_intrange, ds, trange, n=n

    compile_opt idl2, hidden

  times = (*ds).time + ((*ds).end_time - (*ds).time)/2  ;use center
  times_ind = where(times ge trange[0] AND times le trange[1], n)

  return, times_ind
  
end
