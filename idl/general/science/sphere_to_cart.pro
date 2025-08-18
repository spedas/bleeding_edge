;+
;PROCEDURE sphere_to_cart,r,theta,phi, x,y,z
;PURPOSE:  transform from spherical to cartesian coordinates
;INPUTS:  r, theta, phi    (array or scalar) (Units are degrees)
;OUTPUTS: x, y, z          (will have the same dimensions as r,theta,phi)
;KEYWORD OUTPUT:
;   VEC:  a named variable in which the vector [x,y,z] is returned
;
;CREATED BY:	Davin Larson
;LAST MODIFICATION:	@(#)sphere_to_cart.pro	1.6 02/11/01
;
;NOTES:
;   -90 < theta < 90   (latitude not co-lat)  
;   
;SEE ALSO:
;  xyz_to_polar.pro
;-
pro sphere_to_cart,r,theta,phi, x, y, z,vec = vec
c = cos(!dpi/180.*theta)
x = c * cos(!dpi/180.*phi) * r
y = c * sin(!dpi/180.*phi) * r
z = sin(!dpi/180.*theta) * r
vec = [[x],[y],[z]]
return
end

