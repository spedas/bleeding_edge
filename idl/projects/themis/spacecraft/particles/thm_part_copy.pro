;+
;Procedure: thm_part_copy
;
;Purpose: Performs deep copy on particle data that is returned by thm_part_dist_array
;
;Arguments:  Old: A particle data structure to be copied
;            New: A variable name to which the particle data should be copied
;
;Keywords: error=error:  Set to named variable. Returns 0 if no error, nonzero otherwise.
;
;Usage: thm_part_copy,old,new
;
;History:  2016-02-09 - Moved to spd_part_copy, kept as wrapper
;
;  $LastChangedBy: aaflores $
;  $LastChangedDate: 2016-02-09 16:31:11 -0800 (Tue, 09 Feb 2016) $
;  $LastChangedRevision: 19920 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_copy.pro $
;-

pro thm_part_copy,old,new,error=error

  compile_opt idl2,hidden

  spd_part_copy,old,new,error=error

end