;+
;PROCEDURE: thm_part_subtract
;PURPOSE:  Subtracts from a particle distribution down to a minimum.
;(If units are in counts, you can use this to do 1 or N count subtraction)
;
;INPUTS:
;  dist_data:
;   A particle distribution array from thm_part_dist_array
;OUTPUTS:
;   Replaces dat with a data structure with the requested counts subtract
;
;Keywords: 
;  error: Set to 1 on error, zero otherwise
;  subtract_value: The amount to subtract(default: 1)
;  minimum_value: The minimum after subtraction.(default 5e-3) Prevents asymptotes in moment calculations, negative values 
;  
;Example:
; dist_data = thm_part_dist_array(probe='a',type='peif',trange=['2012-02-08/09','2012-02-08/12']) ;load data(loaded in counts, by default)
; thm_part_subtract,dist_data ;subtract one count level 
; thm_part_moments,inst='peif',probe='a',dist_array=dist_data ;calculate moments
;  
; NOTES:
;   Works with thm_part_dist_array.pro, see crib thm_crib_sst_extrapolation.pro, thm_crib_esa_extrapolation.pro for examples on new particle processing routines
;
;  $LastChangedBy: pcruce $
;  $LastChangedDate: 2013-01-18 08:57:01 -0800 (Fri, 18 Jan 2013) $
;  $LastChangedRevision: 11462 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_subtract.pro $
;-


pro thm_part_subtract,dist_data,error=error,subtract_value=subtract_value,minimum_value=minimum_value

compile_opt idl2

error=1

if undefined(dist_data) then begin
  dprint,dlevel=1,'Error: dist_data undefined'
  return
endif

if undefined(subtract_value) then begin
  subtract_value = 1
endif 

if undefined(minimum_value) then begin
  minimum_value = 5e-3
endif 

;loops over modes, not times, so this loop is quite efficient, The time-series calculations are fully vectorized
for i = 0,n_elements(dist_data)-1 do begin
  (*dist_data[i]).data= ((*dist_data[i]).data - subtract_value) > minimum_value
endfor

error=0

end