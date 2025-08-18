;+
;FUNCTION:	kgy_n_3d
;INPUT:	
;	dat:	structure,	2d data structure filled by get_eesa_surv, get_eesa_burst, etc.
;PURPOSE:
;	Returns the density, n, 1/cm^3
;NOTES:	
;	Function normally called by "get_3dt" or "get_2dt" to 
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	Yuki Harada on 2018-05-09
;       modified from n_3d and n_3d_new
;-
function kgy_n_3d,dat2,_extra=_extra

density = 0.

if dat2.valid eq 0 then begin
  dprint, 'Invalid Data'
  return, density
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
Const = (mass)^(-1.5)*(2.)^(.5)
charge = dat.charge
if finite(dat.sc_pot) then energy = energy+(charge*dat.sc_pot/abs(charge)) > 0.

density = Const*total(denergy*(energy^(.5))*data*2.*cos(theta)*sin(dtheta/2.)*dphi,/nan)

; units are 1/cm^3

return, density
end

