;+
;Procedure:
;  spd_pgs_map_azimuth
;
;Purpose:
;  Map any range of azimuth values in [-inf,inf] to [0,360]
;
;Calling Sequence:
;  new_angles = thm_pgs_map_azimuth(angles)
;
;Input:
;  phi: Array of azimuth values in degrees
;
;Output:
;  return value: Input values mapped to [0,360]
;
;Notes:
;
;  -values of 360 will not be wrapped to zero
;   (otherwise a [0,360] range is mapped to [0,0])
;
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2016-01-04 15:09:48 -0800 (Mon, 04 Jan 2016) $
;$LastChangedRevision: 19671 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_part_products/spd_pgs_map_azimuth.pro $
;
;-
function spd_pgs_map_azimuth, phi

    compile_opt idl2, hidden


  p = float(phi)
      
  ;map limits to +-[0,360]
  ;do not wrap multiples of 360
  pmod = p mod 360
  gtz = where(pmod ne 0, ngtz)
  if ngtz gt 0 then p[gtz] = pmod[gtz]
  
  ;wrap negative values
  ltz = where(p lt 0, nltz)
  if nltz gt 0 then p[ltz] += 360.

  return, p

end
