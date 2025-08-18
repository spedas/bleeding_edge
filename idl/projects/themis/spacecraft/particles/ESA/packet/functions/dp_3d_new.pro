;+
;FUNCTION:	p_3d_new(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
;INPUT:	
;	dat:	structure,	2d data structure filled by get_eesa_surv, get_eesa_burst, etc.
;KEYWORDS
;	ENERGY:	fltarr(2),	optional, min,max energy range for integration
;	ERANGE:	fltarr(2),	optional, min,max energy bin numbers for integration
;	EBINS:	bytarr(na),	optional, energy bins array for integration
;					0,1=exclude,include,  
;					na = dat.nenergy
;	ANGLE:	fltarr(2,2),	optional, angle range for integration
;				theta min,max (0,0),(1,0) -90<theta<90 
;				phi   min,max (0,1),(1,1)   0<phi<360 
;	ARANGE:	fltarr(2),	optional, min,max angle bin numbers for integration
;	BINS:	bytarr(nb),	optional, angle bins array for integration
;					0,1=exclude,include,  
;					nb = dat.ntheta
;	BINS:	bytarr(na,nb),	optional, energy/angle bins array for integration
;					0,1=exclude,include
;PURPOSE:
;	Returns the pressure error due to statistics, dp, eV/cm^3, corrects for spacecraft potential if dat.sc_pot exists, diagonalizes 
;NOTES:	
;	Function normally called by "get_3dt" or "get_2dt" to
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	00-2-24	
;LAST MODIFICATION:
;	J.McFadden	05-2-8		Fixed diagonalization
;	J.McFadden	06-2-23		changed the s/c pot calculation to the same as n_2d_new.pro
;	J.McFadden	09-4-29		added a diagonalization to Pxx and Pyy to maximize difference
;-
function dp_3d_new,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,_extra=_extra

p3dxx = 0. & p3dyy = 0. & p3dzz = 0. & p3dxy = 0. & p3dxz = 0. & p3dyz = 0.

if dat2.valid eq 0 then begin
  dprint, 'Invalid Data'
  return, [p3dxx,p3dyy,p3dzz,p3dxy,p3dxz,p3dyz]
endif

mass  = dat2.mass

momen = m_3d_new(dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,_extra=_extra)
flux=j_3d_new(dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,_extra=_extra)
density=n_3d_new(dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,_extra=_extra)
dmomen = dm_3d_new(dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,_extra=_extra)
dflux=dj_3d_new(dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,_extra=_extra)
ddensity=dn_3d_new(dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,_extra=_extra)

p3dxx = (momen(0)-mass*flux(0)*flux(0)/density/1.e10)
p3dyy = (momen(1)-mass*flux(1)*flux(1)/density/1.e10)
p3dzz = (momen(2)-mass*flux(2)*flux(2)/density/1.e10)
p3dxy = (momen(3)-mass*flux(0)*flux(1)/density/1.e10)
p3dxz = (momen(4)-mass*flux(0)*flux(2)/density/1.e10)
p3dyz = (momen(5)-mass*flux(1)*flux(2)/density/1.e10)

dp3dxx = ((dmomen[0])^2 + (2.*mass/1.e10*flux(0)*dflux(0)/density)^2. + (mass/1.e10*flux(0)*flux(0)*ddensity/density^2)^2)^.5
dp3dyy = ((dmomen[1])^2 + (2.*mass/1.e10*flux(1)*dflux(1)/density)^2. + (mass/1.e10*flux(1)*flux(1)*ddensity/density^2)^2)^.5
dp3dzz = ((dmomen[2])^2 + (2.*mass/1.e10*flux(2)*dflux(2)/density)^2. + (mass/1.e10*flux(2)*flux(2)*ddensity/density^2)^2)^.5
dp3dxy = ((dmomen[3])^2 + (2.*mass/1.e10*flux(0)*dflux(1)/density)^2. + (mass/1.e10*flux(0)*flux(1)*ddensity/density^2)^2)^.5
dp3dxz = ((dmomen[4])^2 + (2.*mass/1.e10*flux(0)*dflux(2)/density)^2. + (mass/1.e10*flux(0)*flux(2)*ddensity/density^2)^2)^.5
dp3dyz = ((dmomen[5])^2 + (2.*mass/1.e10*flux(1)*dflux(2)/density)^2. + (mass/1.e10*flux(1)*flux(2)*ddensity/density^2)^2)^.5

; Rotate the tensor about the magnetic field to diagonalize
; This should give a result that diagonalizes the pressure tensor about dat2.magf
; where magf is in s/c coordinates -- ie same as the dat2.theta and dat2.phi coordinates.

; First form the pressure tensor
	p = [[p3dxx,p3dxy,p3dxz],[p3dxy,p3dyy,p3dyz],[p3dxz,p3dyz,p3dzz]]
	dp = [[dp3dxx,dp3dxy,dp3dxz],[dp3dxy,dp3dyy,dp3dyz],[dp3dxz,dp3dyz,dp3dzz]]

if finite(total(dat2.magf)) && (total(dat2.magf*dat2.magf) gt 0.) then begin
	bx=dat2.magf(0)
	by=dat2.magf(1)
	bz=dat2.magf(2)
  ; Rotate p and dp about Z-axis by the angle between X and the projection of B on the XY plane
	ph=atan(by,bx)
	rot_ph=([[cos(ph),-sin(ph),0],[sin(ph),cos(ph),0],[0,0,1]])
	p = rot_ph#p#transpose(rot_ph)
	dp = rot_ph#dp#transpose(rot_ph)
  ; Then rotate p about Y-axis by the angle between Bz and B 
	th=!pi/2.-atan(bz,(bx^2+by^2)^.5)
	rot_th=[[cos(th),0,sin(th)],[0,1,0],[-sin(th),0,cos(th)]]
	p = rot_th#p#transpose(rot_th)
	dp = rot_th#dp#transpose(rot_th)
  ; Finally diagonalize Pxx and Pyy
	l1 = (p[0,0]+p[1,1] + (p[0,0]^2+p[1,1]^2-2.*p[0,0]*p[1,1]+4.*p[0,1]^2)^.5)/2.
	l2 = (p[0,0]+p[1,1] - (p[0,0]^2+p[1,1]^2-2.*p[0,0]*p[1,1]+4.*p[0,1]^2)^.5)/2.
	if l1 ne l2 then ph=acos(((p[0,0]*l1-p[1,1]*l2)/(l1^2-l2^2))^.5) else ph=0.	; ph is the rotation angle to diagonalize
	rot_ph=([[cos(ph),-sin(ph),0.],[sin(ph),cos(ph),0.],[0.,0.,1.]])
	dp = rot_ph#dp#transpose(rot_ph)
endif
	return, [dp(0,0),dp(1,1),dp(2,2),dp(0,1),dp(0,2),dp(1,2)]

;	Pressure is in units of eV/cm**3,  [p3dxx,p3dyy,p3dzz,p3dxy,p3dxz,p3dyz]

end

