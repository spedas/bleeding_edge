;+
;PROCEDURE:  cart_to_sphere2, x, y, z,  r, lamda, phi
;PURPOSE:  transform from cartesian to spherical coordinates
;INPUTS:   x, y, z          (array or scaler)
;OUTPUTS:  r, lamda, phi    (same as x,y,z)
;
;CREATED BY:	Tai Phan (modified from Davin's procedure)
;LAST MODIFICATION:	@(#)cart_to_sphere.pro	1.4 95/08/24
;
;NOTES:
;   Lamda and phi are different from Cart_to_sphere's theta and phi  
;-
pro cart_to_sphere2,x,y,z,r,lamda,phi
rho = sqrt(y*y + z*z)
r= sqrt(x*x+y*y+z*z)
phi = atan(y,z)/!dtor
lamda = atan(x,rho)/!dtor


return
end

