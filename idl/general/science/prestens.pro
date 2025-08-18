;+
;PROCEDURE:	prestens
;PURPOSE:	This function computes the relative components of the pressure
;		tensor
;INPUT:	
;	dat:	A 3d structure such as those gotten by using get_el,get_pl,etc.
;		e.g. "get_el"
;KEYWORDS:	
;	esteprange:	energy range to use
;
;CREATED BY:	Davin Larson
;LAST MODIFICATION:	@(#)prestens.pro	1.5 95/10/06
;
;NOTE:	 It is NOT yet corrected to give physical results
;-

function prestens, dat, $
   ESTEPRANGE = esteprange

if n_elements(esteprange) eq 0 then esteprange = [0 ,dat.nenergy-1]

e1 = esteprange(0)
e2 = esteprange(1)
;e1 = 9
;e2 = dat.nenergy-1
b1 = 0
b2 = dat.nbins-1


data = dat.data(e1:e2,b1:b2)
theta= dat.theta(e1:e2,b1:b2)
phi  = dat.phi(e1:e2,b1:b2)
energy = dat.energy(e1:e2,b1:b2)

mult = replicate(1.,e2-e1+1)
domega = mult # dat.domega(b1:b2)
geom =  mult # dat.geom

sphere_to_cart, 1., theta, phi, sx,sy,sz

pp = data * domega * energy * energy / geom  ;  must be fixed
pxx = total(sx*sx*pp,/double)
pyy = total(sy*sy*pp,/double)
pzz = total(sz*sz*pp,/double)
pxy = total(sx*sy*pp,/double)
pxz = total(sx*sz*pp,/double)
pyz = total(sy*sz*pp,/double)

prtens = [ [pxx,pxy,pxz],[pxy,pyy,pyz],[pxz,pyz,pzz] ]

return ,prtens
end
