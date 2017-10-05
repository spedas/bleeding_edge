;+
;Procedure:
;  spd_slice2d_nearest
;
;
;Purpose:
;  Helper function for spd_slice2d.
;  Get a time range that encompasses a specified number of 
;  samples closest to a specified time range.
;
;
;Input:
;  ds: (pointer) Particle distribution pointer array.
;  time: (double) Time near which to search
;  samples: (int/long) Number of samples to use
;
;
;Output:
;  return value: (double) two element time range 
;
;
;Notes:
;  Uses the center of each sample's time window to determine distance.
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-12-02 19:04:33 -0800 (Wed, 02 Dec 2015) $
;$LastChangedRevision: 19516 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_slice2d_nearest.pro $
;
;-
function spd_slice2d_nearest, ds, time, samples

    compile_opt idl2, hidden

  ;number of samples to consider
  n = undefined(samples) ? 1:samples[0]

  ;get distance to each sample
  for i=0, n_elements(ds)-1 do begin
    start_times = array_concat( (*ds[i]).time, start_times)
    end_times = array_concat( (*ds[i]).end_time, end_times)
  endfor

  distance = abs( (start_times + end_times)/2 - time ) ;use center

  ;get indices for n closest samples
  idx = sort(distance)
  idx = idx[0:(n < n_elements(idx))-1]
    
  ;full time range
  trange = [ min(start_times[idx]), max(end_times[idx]) ]
  
  return, trange
  
end
