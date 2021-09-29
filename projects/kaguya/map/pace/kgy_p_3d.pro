;+
;FUNCTION:	kgy_p_3d
;INPUT:	
;	dat:	structure,	2d data structure filled by get_eesa_surv, get_eesa_burst, etc.
;PURPOSE:
;	Returns the pressure tensor, [Pxx,Pyy,Pzz,Pxy,Pxz,Pyz], eV/cm^3 
;CREATED BY:
;	Yuki Harada on 2018-05-09
;       modified from p_3d and p_3d_new
;       sc_pot correction is NOT included!
;-
function kgy_p_3d,dat2,_extra=_extra

p3dxx = 0.
p3dyy = 0.
p3dzz = 0.
p3dxy = 0.
p3dxz = 0.
p3dyz = 0.

if dat2.valid eq 0 then begin
  dprint, 'Invalid Data'
  return, [p3dxx,p3dyy,p3dzz,p3dxy,p3dxz,p3dyz]
endif

dat = conv_units(dat2,"eflux")		; Use Energy Flux

data = dat.data*dat.bins
energy = dat.energy
denergy = dat.denergy
theta = dat.theta/!radeg
phi = dat.phi/!radeg
dtheta = dat.dtheta/!radeg
dphi = dat.dphi/!radeg
mass = dat.mass * 1.6e-22
Const = (mass/(2.*1.6e-12))^(-.5)
domega = 2.*cos(theta)*sin(dtheta/2.)*dphi

cth = cos(theta)
sth = sin(theta)
cph = cos(phi)
sph = sin(phi)
cth2 = cth^2
cthsth = cth*sth

dnrg = Const*denergy*(energy^(-.5))
p3dxx = total(dnrg*data*cph*cph*domega*cth2,/nan)
p3dyy = total(dnrg*data*sph*sph*domega*cth2,/nan)
p3dzz = total(dnrg*data*domega*sth*sth,/nan)
p3dxy = total(dnrg*data*cph*sph*domega*cth2,/nan)
p3dxz = total(dnrg*data*cph*domega*cthsth,/nan)
p3dyz = total(dnrg*data*sph*domega*cthsth,/nan)

flux=[0.,0.,0.]
dnrg=denergy*(energy^(-1))
flux(0) = total(dnrg*data*cph*domega*cth,/nan)
flux(1) = total(dnrg*data*sph*domega*cth,/nan)
flux(2) = total(dnrg*data*domega*sth,/nan)

density = ((mass/(2.*1.6e-12))^(.5))*total(denergy*(energy^(-1.5))*data*domega,/nan)

if density eq 0. then begin
	vel=[0.,0.,0.]
endif else begin
	vel = flux/density
endelse
p3dxx = mass*(p3dxx-vel(0)*flux(0))/1.6e-12
p3dyy = mass*(p3dyy-vel(1)*flux(1))/1.6e-12
p3dzz = mass*(p3dzz-vel(2)*flux(2))/1.6e-12
p3dxy = mass*(p3dxy-vel(0)*flux(1))/1.6e-12
p3dxz = mass*(p3dxz-vel(0)*flux(2))/1.6e-12
p3dyz = mass*(p3dyz-vel(1)*flux(2))/1.6e-12

;	Pressure is in units of eV/cm**3

return, [p3dxx,p3dyy,p3dzz,p3dxy,p3dxz,p3dyz]

end

