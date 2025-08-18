;+
;Procedure:
;  spd_slice2d_s2c
;
;Purpose:
;  Helper function for spd_slice2d_getxyz
;  Converts spherical coordinates to cartesian
;
;Input:
;  r: N element array of radial values (can be any dimensions)
;  theta: N element array of theta values ( " )
;  phi: N element array of phi values ( " )
;
;Output:
;  vec: Nx3 array of cartesian values in x,y,z order
;
;Notes:
;  could probably just use sphere_to_cart?
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-09-08 18:47:45 -0700 (Tue, 08 Sep 2015) $
;$LastChangedRevision: 18734 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_slice2d_s2c.pro $
;
;-
pro spd_slice2d_s2c, r,theta,phi, vec

    compile_opt idl2, hidden

  rd = !dpi/180.
  n = n_elements(r)
  a = cos(rd*theta)
  vec = [ [reform(a * cos(rd*phi) * r, n)], $
          [reform(a * sin(rd*phi) * r, n)], $
          [reform(sin(rd*theta) * r, n)  ]   ]
end
