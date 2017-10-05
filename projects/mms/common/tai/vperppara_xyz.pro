;+
;Procedure:	vperppara_xyz, vel, magf, vperp_mag=vperp_mag, vpara=vpara, vperp_xyz=vperp_xyz
;INPUT:	
;	vel:	a string containing a structure (e.g. a.x(1000), a.y(1000,3))
;	magf:	the other string. a.x and b.x are not the same. The resulting
;		array size is the size of a.
;OUTPUT:
;	vperp_mag: a string which contains the component of a perpendicular
;			to b.
;	vpara: a string which contains the component of a parallel
;			to b.  	
;	
;
;CREATED BY:
;	Tai Phan	98-01-06
;LAST MODIFICATION:
;	2001-10-26		Tai Phan
;-

pro vperppara_xyz, vel, magf, vperp_mag=vperp_mag, vpara=vpara, vperp_xyz=vperp_xyz

interpolate, vel, magf, 'b_interp'

get_data, vel, data=vec1
get_data, 'b_interp', data=vec2

vpara_t= total(vec1.y*vec2.y,2)/sqrt(total(vec2.y^2,2))

vperp_t= sqrt(total(vec1.y^2,2) - vpara_t^2)

if keyword_set(vperp_mag) then store_data,vperp_mag,data={xtitle:'Time',x:vec1.x,y:vperp_t}

if keyword_set(vpara) then store_data,vpara,data={xtitle:'Time',x:vec1.x,y:vpara_t}

get_data,vel,data = v

get_data,'b_interp',data = b

vperpx = v.y(*,0) - dotp(v.y,b.y) * b.y(*,0) / (b.y(*,0)^2 + b.y(*,1)^2 + b.y(*,2)^2)
vperpy = v.y(*,1) - dotp(v.y,b.y) * b.y(*,1) / (b.y(*,0)^2 + b.y(*,1)^2 + b.y(*,2)^2)
vperpz = v.y(*,2) - dotp(v.y,b.y) * b.y(*,2) / (b.y(*,0)^2 + b.y(*,1)^2 + b.y(*,2)^2)


vperp = fltarr(n_elements(vperpx), 3)

vperp(*,0) = vperpx
vperp(*,1) = vperpy
vperp(*,2) = vperpz

if keyword_set(vperp_xyz) then store_data,vperp_xyz,data = {x:v.x, y:vperp}

end




