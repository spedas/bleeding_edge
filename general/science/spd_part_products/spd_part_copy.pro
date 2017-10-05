;+
;Procedure: spd_part_copy
;
;Purpose: Performs deep copy on particle data that is returned by thm_part_dist_array
;
;Arguments:  Old: A particle data structure to be copied
;            New: A variable name to which the particle data should be copied
;
;Keywords: error=error:  Set to named variable. Returns 0 if no error, nonzero otherwise.
;
;Usage: spd_part_copy,old,new
;
;  $LastChangedBy: aaflores $
;  $LastChangedDate: 2016-02-09 16:31:11 -0800 (Tue, 09 Feb 2016) $
;  $LastChangedRevision: 19920 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_part_products/spd_part_copy.pro $
;-

pro spd_part_copy,old,new,error=error

  compile_opt idl2,hidden

  error = 1

  if size(old,/type) ne 10 then begin
    dprint,dlevel=1,"ERROR: old undefined or has wrong type"
    return
  endif
  
  new = ptrarr(n_elements(old))
  
  for i = 0,n_elements(old)-1l do begin
    new[i] = ptr_new(*old[i])
  endfor

  error=0


end