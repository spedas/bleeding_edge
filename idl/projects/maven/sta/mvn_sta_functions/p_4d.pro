;+
;FUNCTION:	p_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q)
;INPUT:	
;	dat:	structure,	3d data structure filled by themis routines get_th?_p???
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
;	Returns the pressure tensor, [Pxx,Pyy,Pzz,Pxy,Pxz,Pyz], eV/cm^3 
;NOTES:	
;	Function normally called by "get_4dt" to
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	00-2-24	
;LAST MODIFICATION:
;	J.McFadden	05-2-8		Fixed diagonalization
;	J.McFadden	06-2-23		changed the s/c pot calculation to the same as n_2d_new.pro
;	J.McFadden	09-4-29		added a diagonalization to Pxx and Pyy to maximize difference
;-
function p_4d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt

p4d=[0.,0.,0.,0.,0.,0.] 

if dat2.valid eq 0 then begin
  print,'Invalid Data'
  return, p4d
endif

if (dat2.quality_flag and 195) gt 0 then return,p4d

if dat2.nbins eq 1 then return,p4d

dat = dat2
nmass = dat.nmass
nenergy = dat.nenergy
nbins = dat.nbins

momen = m_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
flux=j_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
density=n_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)

if keyword_set(ms) then begin
	if keyword_set(mi) then mass2=mi else mass2=(ms[0]+ms[1])/2.
endif else begin
	if ndimen(dat.mass_arr) eq 3 then mass2=reform(total(dat.mass_arr(*,0,*),1))/nenergy
	if ndimen(dat.mass_arr) eq 2 then mass2=total(dat.mass_arr,1)/nenergy
	if keyword_set(mi) then mass2[*]=mi
endelse

mass2 = mass2*dat.mass

if keyword_set(ms) then begin
	p4dxx = (momen[0]-mass2*flux[0]*flux[0]/(density+1.e-10)/1.e10)
	p4dyy = (momen[1]-mass2*flux[1]*flux[1]/(density+1.e-10)/1.e10)
	p4dzz = (momen[2]-mass2*flux[2]*flux[2]/(density+1.e-10)/1.e10)
	p4dxy = (momen[3]-mass2*flux[0]*flux[1]/(density+1.e-10)/1.e10)
	p4dxz = (momen[4]-mass2*flux[0]*flux[2]/(density+1.e-10)/1.e10)
	p4dyz = (momen[5]-mass2*flux[1]*flux[2]/(density+1.e-10)/1.e10)
	nmass=1

endif else begin
	p4dxx = reform((momen[0,*]-mass2*flux[0,*]*flux[0,*]/(density+1.e-10)/1.e10))
	p4dyy = reform((momen[1,*]-mass2*flux[1,*]*flux[1,*]/(density+1.e-10)/1.e10))
	p4dzz = reform((momen[2,*]-mass2*flux[2,*]*flux[2,*]/(density+1.e-10)/1.e10))
	p4dxy = reform((momen[3,*]-mass2*flux[0,*]*flux[1,*]/(density+1.e-10)/1.e10))
	p4dxz = reform((momen[4,*]-mass2*flux[0,*]*flux[2,*]/(density+1.e-10)/1.e10))
	p4dyz = reform((momen[5,*]-mass2*flux[1,*]*flux[2,*]/(density+1.e-10)/1.e10))
endelse

; Rotate the tensor about the magnetic field to diagonalize
; This should give a result that diagonalizes the pressure tensor about dat.magf
; where magf is in s/c coordinates -- ie same as the dat.theta and dat.phi coordinates.

pp = reform(fltarr(6,nmass))

if finite(total(dat.magf)) && (total(dat.magf*dat.magf) gt 0.) then begin

	bx=dat.magf(0)
	by=dat.magf(1)
	bz=dat.magf(2)
	ph=atan(by,bx)
	rot_ph=([[cos(ph),-sin(ph),0],[sin(ph),cos(ph),0],[0,0,1]])
	th=!pi/2.-atan(bz,(bx^2+by^2)^.5)
	rot_th=[[cos(th),0,sin(th)],[0,1,0],[-sin(th),0,cos(th)]]

; 	Determine the final rotation based on diagonalization of Pxx and Pyy of the mass bin with the most pressure

	max_pp = max(p4dxx+p4dyy+p4dzz,ind)
	p = [[p4dxx[ind],p4dxy[ind],p4dxz[ind]],[p4dxy[ind],p4dyy[ind],p4dyz[ind]],[p4dxz[ind],p4dyz[ind],p4dzz[ind]]]
	p = rot_ph#p#transpose(rot_ph)
	p = rot_th#p#transpose(rot_th)
	l1 = (p[0,0]+p[1,1] + (p[0,0]^2+p[1,1]^2-2.*p[0,0]*p[1,1]+4.*p[0,1]^2)^.5)/2.
	l2 = (p[0,0]+p[1,1] - (p[0,0]^2+p[1,1]^2-2.*p[0,0]*p[1,1]+4.*p[0,1]^2)^.5)/2.
	if l1 ne l2 then ph=acos(((p[0,0]*l1-p[1,1]*l2)/(l1^2-l2^2))^.5) else ph=0.	; ph is the rotation angle to diagonalize
	rot_ph2=([[cos(ph),-sin(ph),0.],[sin(ph),cos(ph),0.],[0.,0.,1.]])

	for i=0,nmass-1 do begin

; 	   First form the pressure tensor
		p = [[p4dxx[i],p4dxy[i],p4dxz[i]],[p4dxy[i],p4dyy[i],p4dyz[i]],[p4dxz[i],p4dyz[i],p4dzz[i]]]
; 	   Rotate p about Z-axis by the angle between X and the projection of B on the XY plane
		p = rot_ph#p#transpose(rot_ph)
; 	   Then rotate p about Y-axis by the angle between Bz and B 
		p = rot_th#p#transpose(rot_th)
; 	   Finally diagonalize Pxx and Pyy
		p = rot_ph2#p#transpose(rot_ph2)

		pp[*,i]=[p[0,0],p[1,1],p[2,2],p[0,1],p[0,2],p[1,2]]
	endfor
	
	if keyword_set(ms) then pp=reform(pp)

	return, pp

endif else begin

	return, transpose([[p4dxx],[p4dyy],[p4dzz],[p4dxy],[p4dxz],[p4dyz]])

endelse

;	Pressure is in units of eV/cm**3,  [p4dxx,p4dyy,p4dzz,p4dxy,p4dxz,p4dyz]

end

