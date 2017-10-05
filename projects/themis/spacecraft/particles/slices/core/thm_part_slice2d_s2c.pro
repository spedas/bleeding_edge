;+
;Procedure:
;  thm_part_slice2d_s2c
;
;Purpose:
;  Helper function for thm_part_slice2d_getxyz
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
;$LastChangedDate: 2016-03-04 18:05:22 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20331 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/core/thm_part_slice2d_s2c.pro $
;
;-
pro thm_part_slice2d_s2c, r,theta,phi, vec

    compile_opt idl2, hidden

  rd = !dpi/180.
  n = n_elements(r)
  a = cos(rd*theta)
  vec = [ [reform(a * cos(rd*phi) * r, n)], $
          [reform(a * sin(rd*phi) * r, n)], $
          [reform(sin(rd*theta) * r, n)  ]   ]
end
