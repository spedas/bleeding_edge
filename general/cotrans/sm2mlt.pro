;+
; FUNCTION:
;    sm2mlt
;
; PURPOSE:
;     Converts a Cartesian vector in SM coordinates to Magnetic Local Time (MLT)
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-01-21 13:42:42 -0800 (Thu, 21 Jan 2016) $
; $LastChangedRevision: 19770 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/sm2mlt.pro $
;-

function sm2mlt, x_sm, y_sm, z_sm
  compile_opt idl2
  ; convert to spherical coordinates
  cart2spc, x_sm, y_sm, z_sm, r, theta, phi
  mlt_0 = 12.0+phi*24.0/(2.0*!PI)
  where_gt_24 = where(mlt_0 gt 24.0, wherecount)
  ; fix MLTs > 24
  if wherecount ne 0 then mlt_0[where_gt_24] = mlt_0[where_gt_24]-24.0
  return, mlt_0
end