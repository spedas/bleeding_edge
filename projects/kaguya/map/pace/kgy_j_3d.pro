;+
;FUNCTION:	kgy_j_3d
;INPUT:	
;	dat:	structure,	2d data structure filled by get_eesa_surv, get_eesa_burst, etc.
;PURPOSE:
;	Returns the flux, [Jx,Jy,Jz], 1/(cm^2-s) 
;CREATED BY:
;	Yuki Harada on 2018-05-09
;       modified from j_3d and j_3d_new
;-
function kgy_j_3d,dat2,_extra=_extra

flux3dx = 0.
flux3dy = 0.
flux3dz = 0.

if dat2.valid eq 0 then begin
  dprint, 'Invalid Data'
  return, [flux3dx,flux3dy,flux3dz]
endif

dat = conv_units(dat2,'df')     ; Use distribution function

data = dat.data*dat.bins
energy = dat.energy
denergy = dat.denergy
theta = dat.theta/!radeg
phi = dat.phi/!radeg
dtheta = dat.dtheta/!radeg
dphi = dat.dphi/!radeg
mass = dat.mass
Const = 2./mass/mass*1e5
if finite(dat.sc_pot) then energy = energy+(charge*dat.sc_pot/abs(charge)) > 0.


;; flux3dx = Const*total(denergy*(energy)*data*(dtheta/2.+cos(2*theta)*sin(dtheta)/2.)*(2.*sin(dphi/2.)*cos(phi)),/nan)
;; flux3dy = Const*total(denergy*(energy)*data*(dtheta/2.+cos(2*theta)*sin(dtheta)/2.)*(2.*sin(dphi/2.)*sin(phi)),/nan)
;; flux3dz = Const*total(denergy*(energy)*data*(2.*sin(theta)*cos(theta)*sin(dtheta/2.)*cos(dtheta/2.))*dphi,/nan)

flux3dx = Const*total(denergy*(energy)*data*2.*cos(theta)*sin(dtheta/2.)*dphi $
                      *cos(phi)*cos(theta),/nan)
flux3dy = Const*total(denergy*(energy)*data*2.*cos(theta)*sin(dtheta/2.)*dphi $
                      *sin(phi)*cos(theta),/nan)
flux3dz = Const*total(denergy*(energy)*data*2.*cos(theta)*sin(dtheta/2.)*dphi $
                      *sin(theta),/nan)


return, [flux3dx,flux3dy,flux3dz]
end

