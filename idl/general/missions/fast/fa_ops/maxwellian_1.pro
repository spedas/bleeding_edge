;+
;PROCEDURE: maxwellian_1,x,a,f,pder,units=units,mass=mass,index=ind
;PURPOSE:
;	Procedure returns maxwellian function f(x,a) and df/da, where f=a0*exp(a1*x), x-vector of energies.
;INPUTS:
;	x	fltarr(n)	array of energy values
;	a	dblarr(2)	array of function parameters
;	f	dblarr(n)	array of function values to be returned 
;	pder	dblarr(n,2)	array of partial derivative, df/da returned 
;
;KEYWORDS:
;	UNITS	string		units for function (df,eflux,flux), def='df' 
;	INDEX	intarr(2)	indexes used for estimate of "a"
;				if set, returns initial estimate of "a." 
;				call before calling curvefit.pro
;
;NOTES:
;	see funct_fit2d.pro
;	see curvefit.pro
;	see maxwellian_2.pro, maxwellian_3.pro
;
;CREATED BY:	J. McFadden  96-11-14
;FILE:  maxwellian_1.pro
;VERSION 1.
;LAST MODIFICATION: mcfadden 97-10-16	
;MOD HISTORY:
;		97-5		delory	 
;		97-10-16	mcfadden	mass in common 
;-

pro maxwellian_1,x, $
                 a, $
                 f, $
                 pder, $
                 UNITS=units, $
                 INDEX=ind
common fit_mass,mass2

; Default units are energy flux. Avoids underflow and overflow
; errors. 
if not defined(f_units) then units = 'eflux'

; Get initial estimate of "a" before calling curvefit.pro
if keyword_set(ind) then begin
	f0=f(ind(0))
	f1=f(ind(1))
	x0=x(ind(0))
	x1=x(ind(1))
	if keyword_set(units) then begin
		if units eq 'eflux' then begin
			f0 = f0/(2.*x0^2)
			f0 = f0/((1.6e-12/mass2)^2*1.e-15)
			f1 = f1/(2.*x1^2)
			f1 = f1/((1.6e-12/mass2)^2*1.e-15)
			if f0 LE 0 then begin
				print,'MAXWELLIAN_1: f0 is too small. Try again'
				stop
			endif
		endif
		if units eq 'flux' then begin
			f0=f0/(x0 * 2. *(1.6e-12/mass2)^2 * 1.e-15)
			f1=f1/(x1 * 2. *(1.6e-12/mass2)^2 * 1.e-15)
		endif
	endif                       
; 	default units is 'df'
	a=dblarr(2)
	a(1)=(alog(f1)-alog(f0))/(x1-x0)
	a(0)=f0/exp(a(1)*x0)
	return
; Return f and df/da for input "x" and "a"
endif else begin
	bx = exp(a(1)*x)
	if keyword_set(units) then begin
		if units eq 'eflux' then begin
			bx = bx * x * x * 2. *(1.6e-12/mass2)^2 * 1.e-15
		endif
		if units eq 'flux' then begin
			bx = bx * x * .5 *(1.6e-12/mass2)^2 * 1.e-15
		endif
	endif                       
	; default units is 'df'
	f  = a(0) * bx
	if N_PARAMS() ge 4 then pder= [[bx], [a(0) * x * bx]]
endelse

return

end
