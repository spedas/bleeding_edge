;+
; NAME:
;
;   INTERP_MAG
;
; PURPOSE:
;
;   Interpolate the magnetometer data before backing out the recursive
;   filter - this procedure should be applied to either raw or pseudo-
;   sensor data
;
; CALLING SEQUENCE
;
;   mag_int = interp_mag(mag_in)
;
; INPUTS:
;
;   mag_in = vector of raw or pseudo sensor data
;
; OPTIONAL INPUTS:
;
;   none
;
; KEYWORD PARAMETERS:
;
;   none
;
; OUTPUTS:
;
;   mag_int = interpolated magnetometer data
;
; EXAMPLE:
;
;   magx_int = interp_mag(magx)
;
;   The routine is usually called as part of the magnetometer analysis
;     e.g. (NOTE this requires FAST_CALIBRATE = 0 in SDT), 
;       mag1dc = get_fa_fields('Mag1dc_S',/all)
;       mag2dc = get_fa_fields('Mag2dc_S',/all)
;       mag3dc = get_fa_fields('Mag3dc_S',/all)
;       raw2pseudo,mag1dc,mag2dc,mag3dc,mag_ps
;       magx_int = interp_mag(mag_ps.x.nt)
;       magy_int = interp_mag(mag_ps.y.nt)
;       magz_int = interp_mag(mag_ps.z.nt)
;       mag_ps.x.nt = magx_int
;       mag_ps.y.nt = magy_int
;       mag_ps.z.nt = magz_int
;       fix_magx,mag_ps.x,magx_fix,timex_fix
;       fix_magy,mag_ps.y,magy_fix,timey_fix
;       fix_magz,mag_ps.z,magz_fix,timez_fix
;       Apply/determine coupling matrix: 
;       Matrix from orbit 601 determined 11/15/96
;       0.984672    0.000000   -0.008604
;       0.008272    0.928669   -0.014153 
;       0.006700    0.006234    0.957579
;       -65.60      20.52      -71.75           Offset
;   mag_x = 0.984672d0*magx_fix+0.000000d0*magy_fix-0.008604d0*magz_fix + 65.60d0
;   mag_y = 0.008272d0*magx_fix+0.928669d0*magy_fix-0.014153d0*magz_fix - 20.52d0
;   mag_z = 0.006700d0*magx_fix+0.006234d0*magy_fix+0.957579d0*magz_fix + 71.75d0
;
;       ?smooth?
;
;   (eventually this sequence should be rationalized)
;
; MODIFICATION HISTORY:
;
;   written by R. J. Strangeway 1/31/97
;   Modified by R. J. Strangeway 1/22/99 to ensure end points kept
;
;   Modified by R. J. Strangeway 5/18/99 to correct "-1" in index arrays
;
;-

function interp_mag,mag_in

; find the delta's

dba=mag_in(1:*)-mag_in(0:*)
dbb=[0.,dba]

nb1 = where (dba lt 0 and mag_in gt 0)
nb2 = where (dba gt 0 and mag_in lt 0)
nb3 = where (dbb gt 0 and mag_in gt 0)
nb4 = where (dbb lt 0 and mag_in lt 0)
nbb = [nb1,nb2,nb3,nb4]
nkeep = where (nbb ge 0) ; added by RJS 5/18/99
nbb = nbb(nkeep)         ; added by RJS 5/18/99
nbb = nbb(sort (nbb))

; keep first and last point

if (nbb(0) ne 0) then nbb=[0,nbb]
if (nbb(n_elements(nbb)-1l) ne n_elements(mag_in)-1L) then nbb = [nbb,n_elements(mag_in)-1L]

mag_tmp = fltarr(n_elements(mag_in))+1.e30
mag_tmp(nbb) = mag_in(nbb)
mag_new = mag_in(nbb)

do_int = where(mag_tmp gt 1.e29,ndo)
xn=float(nbb)
ndiff = where (xn(1:*) ne xn(0:*))
if (ndiff(n_elements(ndiff)-1l) ne n_elements(xn)-1L) then ndiff = [ndiff,n_elements(xn)-1L]
y2=spl_init(xn(ndiff),mag_new(ndiff))

if (ndo gt 0) then begin
  mag_tmpp=spl_interp(xn(ndiff),mag_new(ndiff),y2,do_int)
  mag_tmp(do_int)=mag_tmpp
endif

return, mag_tmp

end

;+
; NAME: 
;
;   FIX_MAGX
;
; PURPOSE:
;
;   Fix the mag dc data by backing out the recursive filter
;
;   This procedure returns the "fixed" data at the same time steps
;   as input. i.e., this procedure should be used on the reference
;   component - bx or mag3
;
; CALLING SEQUENCE:
;
;   fix_magx,magx,mag_fix,time_fix
;
; INPUTS:
;
;   magx = structure of pseudo spacecraft x-component magnetometer data
;          Usually returned as sub-structure from raw2pseudo
;
; OPTIONAL INPUTS:
;
;   none
;
; KEYWORD PARAMETERS:
;
;   none
;
; OUTPUTS:
;
;   mag_fix = fixed magnetometer data
;   time_fix = time tag array for the fixed data
;
; EXAMPLE:
;
;   fix_magx,mag_ps.x,fix_mag_x,fix_time_x
;
; MODIFICATION HISTORY
;
;   written by R. J. Strangeway 11/12/96
;   modified by RJS 2/27/97 to take into account 1/64 delta-t time shift
;   between components
;   modified by R. J. Strangeway 4/30/97 to include a time shift
;   of -1/16 delta-t (earlier) to correct for absolute timing errors
;
;-

pro fix_magx,magx,mag_fix,time_fix

; return usage if incorrect number of parameters

if n_params() ne 3 then begin
  print, " "
  print, $
  "Calling sequence:"
  print, $
  "      fix_magx,mag_ps.x,fix_mag_x,fix_time_x"
  print, $
  "   where mag_ps.x is an input structure returned from raw2pseudo"
  print, $
  "   On return fix_mag_x and fix_time_x are arrays of fixed sensor data"
  print, $
  "   and associated time tags"
  print, " "
  return
endif

; skip last value to synchronize with other components

; coefficients calculated using smooth_freq_recurse.pro 3/21/97

mag_fix = -0.0733232*magx.nt(0:*) +0.6369286*magx.nt(1:*) $
          -3.6444135*magx.nt(2:*) +2.6277847*magx.nt(3:*) $
          +1.8312142*magx.nt(4:*) -0.4315937*magx.nt(5:*) $
          +0.0534028*magx.nt(6:*)

          
n=n_elements(mag_fix)

; subtract an extra 1/16 delta (i.e., data acquired earlier than tagged)

delta = 1.d0/16.d0
time_fix = delta*magx.time(0:*) + (1.d0 - delta)*magx.time(1:*)
time_fix = time_fix(2:n+1)

return
end

;+
; NAME: 
;
;   FIX_MAGY
;
; PURPOSE:
;
;   Fix the mag dc data by backing out the recursive filter and
;   interpolate the data to 1/4 of a time_step later
;
;   This procedure returns the "fixed" data with a quarter time step shift.
;   This procedure should be used on the component acquired just
;   before the reference component - i.e. by or mag2
;
; CALLING SEQUENCE:
;
;   fix_magy,magy,mag_fix,time_fix
;
; INPUTS:
;
;   magy = structure of pseudo spacecraft y-component magnetometer data
;          Usually returned as sub-structure from raw2pseudo
;
; OPTIONAL INPUTS:
;
;   none
;
; KEYWORD PARAMETERS:
;
;   none
;
; OUTPUTS:
;
;   mag_fix = fixed magnetometer data
;   time_fix = time tag array for the fixed data
;
; EXAMPLE:
;
;   fix_magy,mag_ps.y,fix_mag_y,fix_time_y
;
; MODIFICATION HISTORY
;
;   written by R. J. Strangeway 11/12/96
;   modified by RJS 2/27/97 to take into account 1/64 delta-t time shift
;   between components
;   modified by R. J. Strangeway 4/30/97 to include a time shift
;   of -1/16 delta-t (earlier) to correct for absolute timing errors
;
;-


pro fix_magy,magy,mag_fix,time_fix

; return usage if incorrect number of parameters

if n_params() ne 3 then begin
  print, " "
  print, $
  "Calling sequence:"
  print, $
  "      fix_magy,mag_ps.y,fix_mag_y,fix_time_y"
  print, $
  "   where mag_ps.y is an input structure returned from raw2pseudo"
  print, $
  "   On return fix_mag_y and fix_time_y are arrays of fixed sensor data"
  print, $
  "   and associated time tags"
  print, " "
  return
endif

; coefficients calculated using smooth_freq_recurse.pro 3/21/97

mag_fix = -0.0595650*magy.nt(0:*) +0.4972463*magy.nt(1:*) $
          -2.2375989*magy.nt(2:*) -0.2965664*magy.nt(3:*) $
          +3.7133968*magy.nt(4:*) -0.6999019*magy.nt(5:*) $
          +0.0829891*magy.nt(6:*)


n=n_elements(mag_fix)

; subtract an extra 1/16 delta (i.e., data acquired earlier than tagged)

delta = .25d0 - 1.d0/16.d0
time_fix = (1.d0 - delta)*magy.time(0:*) + delta*magy.time(1:*)
time_fix=time_fix(3:n+2)


return
end

;+
; NAME: 
;
;   FIX_MAGZ
;
; PURPOSE:
;
;   Fix the mag dc data by backing out the recursive filter and
;   interpolate the data to 1/2 of a time_step later
;
;   This procedure returns the "fixed" data with a half time step shift.
;   This procedure should be used on the component acquired first
;   before the reference component - i.e. bz or mag1
;
; CALLING SEQUENCE:
;
;   fix_magz,magz,mag_fix,time_fix
;
; INPUTS:
;
;   magz = structure of pseudo spacecraft z-component magnetometer data
;          Usually returned as sub-structure from raw2pseudo
;
; OPTIONAL INPUTS:
;
;   none
;
; KEYWORD PARAMETERS:
;
;   none
;
; OUTPUTS:
;
;   mag_fix = fixed magnetometer data
;   time_fix = time tag array for the fixed data
;
; EXAMPLE:
;
;   fix_magz,mag_ps.z,fix_mag_z,fix_time_z
;
; MODIFICATION HISTORY
;
;   written by R. J. Strangeway 11/12/96
;   modified by RJS 2/27/97 to take into account 1/64 delta-t time shift
;   between components
;   modified by R. J. Strangeway 4/30/97 to include a time shift
;   of -1/16 delta-t (earlier) to correct for absolute timing errors
;
;-


pro fix_magz,magz,mag_fix,time_fix

if n_params() ne 3 then begin
  print, " "
  print, $
  "Calling sequence:"
  print, $
  "      fix_magz,mag_ps.z,fix_mag_z,fix_time_z"
  print, $
  "   where mag_ps.z is an input structure returned from raw2pseudo"
  print, $
  "   On return fix_mag_z and fix_time_z are arrays of fixed sensor data"
  print, $
  "   and associated time tags"
  print, " "
  return
endif

; coefficients calculated using smooth_freq_recurse.pro 3/21/97

mag_fix = -0.0304702*magz.nt(0:*) +0.2184536*magz.nt(1:*) $
          -0.6990808*magz.nt(2:*) -2.8039706*magz.nt(3:*) $
          +4.7849212*magz.nt(4:*) -0.5211275*magz.nt(5:*) $
          +0.0512742*magz.nt(6:*)


n=n_elements(mag_fix)

; subtract an extra 1/16 delta (i.e., data acquired earlier than tagged)

delta = .5d0 - 1.d0/16.d0
time_fix = (1.d0 - delta)*magz.time(0:*) + delta*magz.time(1:*)
time_fix=time_fix(3:n+2)

return
end

; $Id: svdfit.pro,v 1.2 1995/04/07 23:50:26 dave Exp $

FUNCTION SVDFIT4,X,Y,M, YFIT = yfit, WEIGHT = weight, CHISQ = chisq, $
	SINGULAR = sing, VARIANCE = var, COVAR = covar, Funct = funct
;+
; NAME:
;	SVDFIT4
;
; PURPOSE:
;	Perform a general least squares fit with optional error estimates.
;
;	This version uses SVD.  A user-supplied function or a built-in
;	polynomial is fit to the data.
;       THIS VERSION IS THE IDL VERSION 4 PROCEDURE
;
; CATEGORY:
;	Curve fitting.
;
; CALLING SEQUENCE:
;	Result = SVDFIT4(X, Y, M)
;
; INPUTS:
;	X:	A vector representing the independent variable.
;
;	Y:	Dependent variable vector.  This vector should be same length 
;		as X.
;
;	M:	The number of coefficients in the fitting function.  For 
;		polynomials, M is equal to the degree of the polynomial + 1.
;
; OPTIONAL INPUTS:
;	Weight:	A vector of weights for Y(i).  This vector should be the same
;		length as X and Y.
;
;		If this parameter is ommitted, 1 is assumed.  The error for 
;		each term is weighted by Weight(i) when computing the fit.  
;		Frequently, Weight(i) = 1./Sigma(i) where Sigma is the 
;		measurement error or standard deviation of Y(i).
;
;	Funct:	A string that contains the name of an optional user-supplied 
;		basis function with M coefficients. If omitted, polynomials
;		are used.
;
;		The function is called:
;			R = FUNCT(X,M)
;		where X is an N element vector, and the function value is an 
;		(N, M) array of the N inputs, evaluated with the M basis 
;		functions.  M is analogous to the degree of the polynomial +1 
;		if the basis function is polynomials.  For example, see the 
;		function COSINES, in the IDL User Library, which returns a 
;		basis function of:
;			R(i,j) = cos(j*x(i)).
;		For more examples, see Numerical Recipes, page 519.
;
;		The basis function for polynomials, is R(i,j) = x(i)^j.
;		
; OUTPUTS:
;	SVDFIT4 returns a vector of M coefficients.
;
; OPTIONAL OUTPUT PARAMETERS:
;	NOTE:  In order for an optional keyword output parameter
;	to be returned, it must be defined before calling SVDFIT.
;	The value or structure doesn't matter.  For example:
;
;		YF = 1				;Define output variable yf.
;		C = SVDFIT4(X, Y, M, YFIT = YF) 	;Do SVD, fitted Y vector is now
;						;returned in variable YF.
;
;	YFIT:	Vector of calculated Y's.
;
;	CHISQ:	Sum of squared errors multiplied by weights if weights
;		are specified.
;
;	COVAR:	Covariance matrix of the coefficients.
;
;    VARIANCE:	Sigma squared in estimate of each coeff(M).
;
;    SINGULAR:	The number of singular values returned.  This value should
;		be 0.  If not, the basis functions do not accurately
;		characterize the data.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	None.
;
; MODIFICATION HISTORY:
;	Adapted from SVDFIT, from the book Numerical Recipes, Press,
;	et. al., Page 518.
;	minor error corrected April, 1992 (J.Murthy)
;-
;	ON_ERROR,2		;RETURN TO CALLER IF ERROR
;	set variables
	THRESH = 1.0E-9		;Threshold used in editing singular values


	XX = X*1.		;BE SURE X IS FLOATING OR DOUBLE
	N = N_ELEMENTS(X) 	;SIZE
	IF N NE N_ELEMENTS(Y) THEN BEGIN ;SAME # OF DATA POINTS.
	  message, 'X and Y must have same # of elements.'
	  ENDIF

	if n_elements(weight) ne 0 then begin
		if n_elements(weight) ne n then begin
		  message, 'Weights have wrong number of elements.'
		  endif
	  b = y * weight	;Apply weights
	  endif else b = y	;No weights
;

	if n_elements(funct) eq 0 then begin ;Use polynomial?
	  A = FLTARR(N,M)			;COEFF MATRIX
	  if n_elements(weight) ne 0 then xx = float(weight) $
	  else xx = replicate(1.,n)	;Weights are 1.
	  for i=0,m-1 do begin		;Make design matrix
		a(0,i) = xx
		xx = xx * x
		endfor
	endif else begin		;Call user's function
		z = execute('a='+funct+'(x,m)')
		if z ne 1 then begin
			message, 'Error calling user fcn: ' + funct
			endif
		if n_elements(weight) ne 0 then $
		  a = a * (weight # replicate(1.,m)) ;apply wts to A
	endelse

	svd,a,w,u,v			;Do the svd

	good = where(w gt (max(w) * thresh), ng) ;Cutoff for sing values
	sing = m - ng		;# of singular values
	if sing ne 0 then begin
		message, 'Warning:' + strcompress(sing, /REMOVE) + $
			' singular values found.',/continue
; continue added by R. J. Strangeway 7/16/97
;modified J.M.
small=where(w le max(w)*thresh)
w(Small)=0
;
		if ng eq 0 then return,undefined
		endif
;modified J.M

svbksb,u,w,v,b,coeff
;
	wt = fltarr(m)
	wt(good)=1./w(good)

	if (n_elements(weight) eq 0) then xx=replicate(1.,n) else $
		xx=weight
	if (n_elements(yfit) ne 0) or (n_elements(chisq) ne 0) then begin
	  if n_elements(funct) eq 0 then yfit = poly(x,coeff) $
		else begin 
		yfit = fltarr(n)
		for i=0,m-1 do yfit = yfit + coeff(i) * a(*,i) $
			/ xx	;corrected J.M.
		endelse
	  endif

	if n_elements(chisq) ne 0 then begin	;Compute chisq?
		chisq = (y - yfit)
		if n_elements(weight) ne 0 then chisq = chisq * weight
		chisq = total(chisq ^ 2)
		endif

	wt = wt*wt		;Use squared w

	if n_elements(covar) ne 0 then begin	;Get covariance?
		covar = fltarr(m,m)
		for i=0,m-1 do for j=0,i do begin
		  s = 0.
		  for k=0,m-1 do s = s + wt(k) * v(i,k) * v(j,k)
		  covar(i,j) = s
		  covar(j,i) = s
		endfor
	  endif

	if n_elements(var) ne 0 then begin
		var = fltarr(m)
		for j=0,m-1 do for i=0,m-1 do $
		   var(j) = var(j) + v(j,i)^2 * wt(i)
		endif

	return,coeff
end



pro spin_tone_fit,BB,dtime,coef,tspin,ttag,bfit=bfit

; edited version of rce_loop2_rjs.pro - error quantities deleted

; modified by RJS 9/6/97 to print % complete

; modified by RJS 6/16/98 to center the intervals

; modified by RJS 10/7/98 to return fit for possible residual calculation

ista=0L
sizt=size(dtime)
limit=sizt(3)
interval=fix((dtime(limit-1)-dtime(ista))/10.0)
print,'Estimate ',interval,' Coefficients'
bsig=1.0
var=1.0
yft=1.0
frac=10

bfit = BB

tttm = systime(1)

; modify to build up the coefficients etc., piece wise

coef=make_array(9,1,value=0.0d0)
nsamp=make_array(1,1,value=0.)
jk=-1

; find zero crossings (+ve to -ve on By)

nzero=where(BB(1:*,1) le 0.d0 and BB(0:*,1) gt 0.d0)
tzero=(dtime(nzero+1)*BB(nzero,1)-dtime(nzero)*BB(nzero+1,1))/(BB(nzero,1)-BB(nzero+1,1))
nspin=n_elements(tzero)
n1=0
print,0,format='(/i4,"%",$)'
while n1 lt nspin-2 do begin
        ista=nzero(n1)+1
        isto=nzero(n1+2)
	if isto gt limit-1 then isto=limit-1
;
;       Minimum number of points added by RJS 1/15/97
;
        if isto ge ista + 10 then begin
                tref=tzero(n1)
                trange=10.d0/(tzero(n1+2)-tref)

		for kk=0,2 do begin

;  modified by RJS to count number of singular solutions
;  Additional modification by RJS 6/9/97 to use the IDL version 4 svdfit procedure

			sing=0
			soln=svdfit4((dtime(ista:isto)-tref)*trange-5.d0,BB(ista:isto,kk), $
			6,funct='spinbase_mag',yfit=yft,chisq=bsig,variance=var, $
			singular=sing)
			if sing ne 0 then begin

;  diagnostic
				print,isto,ista
				print,dtime(isto),dtime(ista),dtime(isto)-dtime(ista)
				print,kk,sing
			endif else begin
                                bfit(ista:isto,kk)=yft
				if kk eq 0 then jk=jk+1
				if kk eq 0 and jk gt 0 then begin
				    coef=[[coef],[0.d0,0.d0,0.d0,0.d0,0.d0,0.d0,0.d0,0.d0,0.d0]]
				    nsamp=[[nsamp],[0.]]
				endif 
				if kk eq 0 then nsamp(0,jk) = isto-ista+1		
				coef(kk*3:kk*3+2,jk)=soln([0,1,4])
                                if kk eq 0 and frac lt 100 and jk gt .01*frac*(interval-1) then begin 
                                     print,frac,format='(i4,"%",$)'
                                     frac=frac+10
;                                    print,'Coefficient ',jk,'/',interval-1
                                endif
                                if kk eq 0 then begin
                                     if (jk eq 0) then begin
                                         ttag=dtime(ista)
                                         tspin=(tzero(n1+2)-tref)/2.d0
                                     endif else begin
                                         ttag=[ttag,dtime(ista)]
                                         tspin=[tspin,(tzero(n1+2)-tref)/2.d0]
                                     endelse
                                endif
			endelse
		endfor
	endif
	n1=n1+2
endwhile
print,100,format='(i4,"%"/)'
b1xy=sqrt(coef(0,*)^2+coef(1,*)^2)
b2xy=sqrt(coef(3,*)^2+coef(4,*)^2)
b3xy=sqrt(coef(6,*)^2+coef(7,*)^2)
r21=b2xy/b1xy
cphi21=(coef(3,*)*coef(0,*)+coef(4,*)*coef(1,*))/b1xy/b2xy
sphi21=(coef(4,*)*coef(0,*)-coef(3,*)*coef(1,*))/b1xy/b2xy
phi21=atan(sphi21,cphi21)
r31=b3xy/b1xy
cphi31=(coef(6,*)*coef(0,*)+coef(7,*)*coef(1,*))/b1xy/b3xy
sphi31=(coef(7,*)*coef(0,*)-coef(6,*)*coef(1,*))/b1xy/b3xy
phi31=atan(sphi31,cphi31)
bz=coef(8,*)
off1=coef(2,*)
off2=coef(5,*)

coef=[b1xy,bz,r21,phi21,r31,phi31,off1,off2,nsamp]

print,'SPIN_TONE_FIT took ',systime(1)-tttm,' Seconds'

return
end	

function spinbase_mag,t,nparams

twopi=2.d*!dpi
nparams=6				; two amplitudes, two linear growths, 
					; an offset, and linear change in offset

; Basis set of functions for fitting spinning data using time and assumed 5 sec spin
; Average Cosine, sine amplitude, linearly changing amplitude of cosine, sine, 
; DC term plus linear trend in "DC" term
; reference time now set in calling routine (6/16/98)

;t0=double(median(t))
t0 = 0.d0
tt=t-t0
ntt=n_elements(tt)

basis = dblarr(ntt,nparams)
basis(*,0)=cos(tt*twopi/5.d0)
basis(*,1)=sin(tt*twopi/5.d0)
basis(*,2)=tt*basis(*,0)
basis(*,3)=tt*basis(*,1)
basis(*,4)=1.0d
basis(*,5)=tt

return,float(basis)
end

function get_cal_history,fname,debug=debug,fdf_predict=fdf_predict

; read the magDC.cal file, and return coupling matrices, offsets

; modified by RJS 3/27/99 to also return fdf predict data if available

; modified by RJS 2/7/00 to preassign storage and return reference orbit

; modified by RJS 1/22/01 to allow for up to a 10th order polynomial in 
; fdf_predict

num_poly=10

error = 0
if n_params() eq 0 then begin
    fname='$FAST_CALIBRATION/MagDC.cal'
    openr,lu,fname,error=error,/get_lun
    if (error eq 0) then begin
        print,'Opened ',fname
    endif else begin
        fname='$FASTLIB/fast_fields_cals/MagDC.cal'
        openr,lu,fname,error=error,/get_lun
        if (error eq 0) then begin
            print,'Opened ',fname
        endif else begin
            print,'Could not open MagDC.cal'
            return,0
        endelse
    endelse
endif else begin
    openr,lu,fname,error=error,/get_lun
    if (error ne 0) then begin 
        print,'File ',fname,' not found'
        return,0
    endif else begin
        print,'Opened ',fname
    endelse
endelse

com = 'egrep -v "^#" '+fname+'|grep -i -c "epoch time"
spawn,com,result
reads,result(0),n_epochs


s=''
reftime=0.d0
read_fdf=0
n_epoch=0L
orb=0

tw = {t:dblarr(n_epochs), $
      xx:fltarr(n_epochs),xy:fltarr(n_epochs),xz:fltarr(n_epochs), $ 
      yx:fltarr(n_epochs),yy:fltarr(n_epochs),yz:fltarr(n_epochs), $
      zx:fltarr(n_epochs),zy:fltarr(n_epochs),zz:fltarr(n_epochs), $
      ox:fltarr(n_epochs),oy:fltarr(n_epochs),oz:fltarr(n_epochs), $
      ra:fltarr(n_epochs),dec:fltarr(n_epochs),phs:fltarr(n_epochs)}

sg = {xx_sig:fltarr(n_epochs),xy_sig:fltarr(n_epochs),xz_sig:fltarr(n_epochs), $ 
      yx_sig:fltarr(n_epochs),yy_sig:fltarr(n_epochs),yz_sig:fltarr(n_epochs), $
      zx_sig:fltarr(n_epochs),zy_sig:fltarr(n_epochs),zz_sig:fltarr(n_epochs), $
      ox_sig:fltarr(n_epochs),oy_sig:fltarr(n_epochs),oz_sig:fltarr(n_epochs), $
      ra_sig:fltarr(n_epochs),dec_sig:fltarr(n_epochs),phs_sig:fltarr(n_epochs)}

orb_ref = intarr(n_epochs)

while not EOF(lu) and n_epoch lt n_epochs do begin
  readf,lu,s
  m = strpos(s,'@(#)MagDC.cal')
  if (m ge 0) then print,'  Calibration version: ',strmid(s,1,m-1),'    ',strmid(s,m+4,40)
  m = strpos(strlowcase(s),'# fdf prediction')
  if (m ge 0) then begin
    read_fdf=1
    fdf_predict={ref_time:!values.d_nan,last_time:!values.d_nan,$
    ref_ra:!values.d_nan,trend_ra:!values.d_nan,second_ra:0.d0,$
    poly:dblarr(num_poly),$
    ref_dec:!values.d_nan}
  endif 
  if (read_fdf) then begin
    m = strpos(strlowcase(s),'# time_ref')
    if (m ge 0) then begin
      mm = strpos(strlowcase(s),':')
      if (mm gt 0) then fdf_predict.ref_time=str_to_time(strmid(s,mm+1,80))
    endif
    m = strpos(strlowcase(s),'# last time')
    if (m ge 0) then begin
      mm = strpos(strlowcase(s),':')
      if (mm gt 0) then fdf_predict.last_time=str_to_time(strmid(s,mm+1,80))
    endif
    m = strpos(strlowcase(s),'# reference ra')
    if (m ge 0) then begin
      mm = strpos(strlowcase(s),':')
      tmp=0.d0
      if (mm gt 0) then reads,strmid(s,mm+1,80),tmp
      fdf_predict.ref_ra=tmp
    endif
    m = strpos(strlowcase(s),'# trend')
    if (m ge 0) then begin
      mm = strpos(strlowcase(s),':')
      tmp=0.d0
      if (mm gt 0) then reads,strmid(s,mm+1,80),tmp
      fdf_predict.trend_ra=tmp
    endif
    m = strpos(strlowcase(s),'# second')
    if (m ge 0) then begin
      mm = strpos(strlowcase(s),':')
      tmp=0.d0
      if (mm gt 0) then reads,strmid(s,mm+1,80),tmp
      fdf_predict.second_ra=tmp
    endif
    m = strpos(strlowcase(s),'# poly_')
    if (m ge 0) then begin
      mm = strpos(strlowcase(s),':')
      tmp=0.d0
      npol=0
      if (mm ge m+8) then begin 
         reads,strmid(s,m+7,mm-1),npol
         reads,strmid(s,mm+1,80),tmp
         if (npol lt num_poly) then fdf_predict.poly[npol]=tmp
      endif
    endif
    m = strpos(strlowcase(s),'# declination')
    if (m ge 0) then begin
      mm = strpos(strlowcase(s),':')
      tmp=0.d0
      if (mm gt 0) then reads,strmid(s,mm+1,80),tmp
      fdf_predict.ref_dec=tmp
    endif
  endif
  m = strpos(strlowcase(s),'# end of fdf prediction')
  if (m ge 0) then begin
    read_fdf=0
    del_fdf=0
    for n = 0,n_tags(fdf_predict)-1L do begin
      bfin = where (finite(fdf_predict.(n)) eq 0, nfin)
      if (nfin gt 0) then del_fdf=1
    endfor
    if (del_fdf) then fdf_predict=0
  endif
  m = strpos(strlowcase(s),'correction')
  if m gt 0 then begin
    mm = strpos(strlowcase(s),':')
    if (mm gt 0) then begin 
       reads,strmid(s,mm+1,80),val
       mmm = strpos(strlowcase(s),'+/-')
       sig = 0.
       if (mmm gt 0) then reads,strmid(s,mmm+3,80),sig
    endif
    if (strpos(strlowcase(s),'spin-axis ra correction') gt 0) then tw.ra(n_epoch)=val
    if (strpos(strlowcase(s),'spin-axis ra correction') gt 0) then sg.ra_sig(n_epoch)=sig
    if (strpos(strlowcase(s),'spin-axis dec correction') gt 0) then tw.dec(n_epoch)=val
    if (strpos(strlowcase(s),'spin-axis dec correction') gt 0) then sg.dec_sig(n_epoch)=sig
    if (strpos(strlowcase(s),'spin-phase correction') gt 0) then tw.phs(n_epoch)=val
    if (strpos(strlowcase(s),'spin-phase correction') gt 0) then sg.phs_sig(n_epoch)=sig
  endif
  m = strpos(strlowcase(s),'gain matrix sigmas')
  if m gt 0 then begin
     reads,strmid(s,2,80),sx,sy,sz
     sg.xx_sig(n_epoch)=sx
     sg.xy_sig(n_epoch)=sy
     sg.xz_sig(n_epoch)=sz
     readf,lu,s
     reads,strmid(s,2,80),sx,sy,sz
     sg.yx_sig(n_epoch)=sx
     sg.yy_sig(n_epoch)=sy
     sg.yz_sig(n_epoch)=sz
     readf,lu,s
     reads,strmid(s,2,80),sx,sy,sz
     sg.zx_sig(n_epoch)=sx
     sg.zy_sig(n_epoch)=sy
     sg.zz_sig(n_epoch)=sz
     readf,lu,s
     reads,strmid(s,2,80),sx,sy,sz
     sg.ox_sig(n_epoch)=sx
     sg.oy_sig(n_epoch)=sy
     sg.oz_sig(n_epoch)=sz
  endif
  m = strpos(strlowcase(s),'# coupling matrix for orbit')
  if m ge 0 then begin
    m1 = strpos(strlowcase(s),'orbit') + 6
    reads,strmid(s,m1,5),orb
;
;   hard-wired fixes for orbit numbers around axial boom deploy
;
    if (orb eq 1787) then orb = 1795
    if (orb eq 1798) then orb = 1796
    orb_ref(n_epoch)=orb
  endif
  l = strpos(strlowcase(s),'epoch time')
  if l gt 0 and strmid(s,0,1) ne '#' then begin
    reads,s,reftime
    tw.t(n_epoch)=reftime
    if (keyword_set(debug)) then print,reftime
    readf,lu,xx,xy,xz
    tw.xx(n_epoch)=xx
    tw.xy(n_epoch)=xy
    tw.xz(n_epoch)=xz
    readf,lu,yx,yy,yz
    tw.yx(n_epoch)=yx
    tw.yy(n_epoch)=yy
    tw.yz(n_epoch)=yz
    readf,lu,zx,zy,zz
    tw.zx(n_epoch)=zx
    tw.zy(n_epoch)=zy
    tw.zz(n_epoch)=zz
    readf,lu,ox,oy,oz
    tw.ox(n_epoch)=ox
    tw.oy(n_epoch)=oy
    tw.oz(n_epoch)=oz
    n_epoch=n_epoch+1L
  endif
endwhile

free_lun,lu
   
bsig = where (sg.xx_sig ne 0.,nsig)
if (nsig eq 0) then bsig = where (sg.xy_sig ne 0.,nsig)
if (nsig eq 0) then bsig = where (sg.xz_sig ne 0.,nsig)
if (nsig eq 0) then bsig = where (sg.yx_sig ne 0.,nsig)
if (nsig eq 0) then bsig = where (sg.yy_sig ne 0.,nsig)
if (nsig eq 0) then bsig = where (sg.yz_sig ne 0.,nsig)
if (nsig eq 0) then bsig = where (sg.zx_sig ne 0.,nsig)
if (nsig eq 0) then bsig = where (sg.zy_sig ne 0.,nsig)
if (nsig eq 0) then bsig = where (sg.zz_sig ne 0.,nsig)
if (nsig eq 0) then bsig = where (sg.ox_sig ne 0.,nsig)
if (nsig eq 0) then bsig = where (sg.oy_sig ne 0.,nsig)
if (nsig eq 0) then bsig = where (sg.oz_sig ne 0.,nsig)

retval= tw
if (nsig gt 0) then retval= create_struct(retval,sg)
borb = where (orb_ref ne 0.,norb)
if (norb gt 0) then retval= create_struct(retval,'orb_ref',orb_ref)

return, retval

end

function get_mag_dqis

; find which mag_dqis are present

prog = getenv('FASTBIN') + '/showDQIs'
spawn, prog, result, /noshell

has_mag={magdc:0,magxyz:0,mag1dc:0,mag2dc:0,mag3dc:0}
b = where (strpos(result,'MagDC') ge 0,nb)
if (nb gt 0) then has_mag.magdc=1
b = where (strpos(result,'MagXYZ') ge 0,nb)
if (nb gt 0) then has_mag.magxyz=1
b = where (strpos(result,'Mag1dc_S') ge 0,nb)
if (nb gt 0) then has_mag.mag1dc=1
b = where (strpos(result,'Mag1dc_S') ge 0,nb)
if (nb gt 0) then has_mag.mag1dc=1
b = where (strpos(result,'Mag2dc_S') ge 0,nb)
if (nb gt 0) then has_mag.mag2dc=1
b = where (strpos(result,'Mag3dc_S') ge 0,nb)
if (nb gt 0) then has_mag.mag3dc=1

return,has_mag
end

pro get_mag_tweak,pseudo,mag,spin_fit,tw,ofst,useraw=useraw,norepair=norepair,fdf_predict=fdf_predict

; get the data for use in tweaker coefficient calculations

; Modified to resample 512 sps at 128 sps

; Also modified to get the tweaker matrix for the current time

; Modified by RJS 9/6/97 to look for the dqis before trying to read them

; Modified by RJS 9/6/97 to use any available MAG quantities, but useraw
; forces to raw quantities

; Modified by RJS 9/29/97 to check for correct version

; Modified by RJS 12/5/97 to repair data unless turned off with /norepair

; Modified by RJS 4/17/98 to reject bad spin period estimates (10% window) 

; Modified by RJS 6/11/98 to correct zero crossing glitch

; Modified by RJS 3/27/99 to return the fdf_predict information from a cal file

; Modified by RJS 4/14/99 to warn if data past end of calibration file
;     and use interim calibration for orbits > 9936 if calibration not available

; Modified by RJS 02/08/00 to interpolate calibration data

common ucla_mag_code,code_version,lib_version
if (n_elements(code_version) eq 0) then code_version=''
lib_version='3.8a'

code_version_chk=code_version
ll=strpos(code_version,'_d')
if (ll ge 0) then code_version_chk=strmid(code_version,0,ll)
if (code_version_chk ne lib_version) then begin
    print,''
    print,'WARNING - Calling program and library version mismatch'
    print,'          You may want to install the correct versions'
    print,'          Calling version: ',code_version
    print,'          Library version: ',lib_version
    print,''
endif

; get the data from SDT

delta_cross = 0.25d0 ; found empirically for orbit 1843

time_min_rec = 20.d0

norb_max_gap = 200  ; maximum gap to interpolate calibration data

if keyword_set(norepair) then repair = 0 else repair = 1

print,''
print,'Getting MAG data from SDT'
print,''

has_mag=get_mag_dqis()

; first try to get MagDC quantities

magdc={valid:has_mag.magdc}
if keyword_set(useraw) then magdc.valid = 0
if (magdc.valid) then magdc=get_fa_fields('MagDC',/all,repair=repair)

if magdc.valid eq 0 then begin

; Didn't get MagDC - try to get MagXYZ instead

  magxyz={valid:has_mag.magxyz}
  if (magxyz.valid) then magxyz=get_fa_fields('MagXYZ',/all,repair=repair)

  if magxyz.valid eq 0 then begin

;   Didn't get magxyz - try to get mag1dc_s etc. instead

    mag1dc_s={valid:has_mag.mag1dc}
    mag2dc_s={valid:has_mag.mag2dc}
    mag3dc_s={valid:has_mag.mag3dc}
    if (mag1dc_s.valid) then mag1dc_s=get_fa_fields('Mag1dc_S',/all,repair=repair)
    if (mag2dc_s.valid) then mag2dc_s=get_fa_fields('Mag2dc_S',/all,repair=repair)
    if (mag3dc_s.valid) then mag3dc_s=get_fa_fields('Mag3dc_S',/all,repair=repair)

    if mag1dc_s.valid eq 0 or mag2dc_s.valid eq 0 or mag3dc_s.valid eq 0 then begin
      print,''
      print,'This procedure needs magnetometer data quantities'
      print,'Please make sure the following Fields-Survey'
      print,'quantities are displayed in SDT: '
      print,'   either:  MagXDC, MagYDC, MagZDC
      print,'   or:      Mag1dc_S, Mag2dc_s, Mag3dc_S'
      print,'   or:      MagX, MagY, MagZ'
      print,''
      return
    endif

;   got the mag1dc_s etc. data - check for 1 bit steps

    chk=mag1dc_s.comp1(1:*)-mag1dc_s.comp1(0:*)
    b = where ((chk mod 1.) ne 0.,nb)
    if (nb ne 0) then begin

;     data have been calibrated somehow

      print,''
      print,'Raw magnetometer not quantized at 1-bit level'
      print,'Possibly using old version of SDT. To fix this problem '
      print,'please make sure the following Fields-Survey'
      print,'quantities are displayed in SDT: '
      print,'       MagX, MagY, MagZ'
      print,'and restart the procedure'
      print,''
      return
    endif

;   data ok - convert to pseudo sensor
  
    print,''
    print,'Using MAG1DC_S, MAG2DC_S, MAG3DC_S, '
    print,''
    n=n_elements(mag1dc_s.comp1)
    magxyz = {comp1:fltarr(n),comp2:fltarr(n),comp3:fltarr(n),time:dblarr(n)}
    magxyz.comp1 = -2.*mag3dc_s.comp1
    magxyz.comp2 = -2.*mag2dc_s.comp1
    magxyz.comp3 =  2.*mag1dc_s.comp1
    magxyz.time = mag1dc_s.time
    mag1dc_s=0.
    mag2dc_s=0.
    mag3dc_s=0.

  endif else begin

;   got the magxyz data - check for calibrated (pseudo-sensor)

    print,''
    print,'Using MAGXYZ'
    print,''
    chk=magxyz.comp1(1:*)-magxyz.comp1(0:*)
    b = where ((chk mod 2.) ne 0.,nb)
    if (nb ne 0) then begin

;     data uncalibrated - check for 1 bit quantization

      b = where ((chk mod 1.) ne 0.,nb)
      if (nb ne 0) then begin

;       data incorrectly quantized

        print,''
        print,'Raw magnetometer not quantized at 1-bit level'
        print,'Possibly using old version of SDT. To fix this problem '
        print,'please make sure the following Fields-Survey'
        print,'quantities are displayed in SDT: '
        print,'       MagX, MagY, MagZ'
        print,'and restart the procedure'
        print,''
        return
      endif

;     1 bit level - convert to pseudo-sensor

      print,''
      print,'MAGXYZ - 1 bit level quantization'
      print,''
      tmp=magxyz.comp1
      magxyz.comp1 = -2.*magxyz.comp3
      magxyz.comp2 = -2.*magxyz.comp2
      magxyz.comp3 =  2.*tmp
      tmp=0.

    endif

  endelse

endif else begin

; got the magdc data - check for uncalibrated

  print,''
  print,'Using MAGDC'
  print,''

  n=n_elements(magdc.comp1)
  magxyz = {comp1:fltarr(n),comp2:fltarr(n),comp3:fltarr(n),time:dblarr(n)}

  chk=magdc.comp1(1:*)-magdc.comp1(0:*)
  b = where ((chk mod 1.) ne 0.,nb)
  if (nb eq 0) then begin

;   MAGDC data are uncalibrated

    print,''
    print,'MAGDC - 1 bit level quantization'
    print,''
    magxyz.comp1 = -2.*magdc.comp3
    magxyz.comp2 = -2.*magdc.comp2
    magxyz.comp3 =  2.*magdc.comp1
    magxyz.time = magdc.time

;   use magdc.valid to flag uncalibrated data
    magdc={valid:0}

  endif else begin

    magxyz.comp1 = magdc.comp1
    magxyz.comp2 = magdc.comp2
    magxyz.comp3 = magdc.comp3
    magxyz.time = magdc.time
    magdc={valid:magdc.valid}

  endelse

endelse

print,''
print,'Store and interpolate MAG data'
print,''

; magxyz data ok - store
; note that magxyz.time is the same as mag1dc_s.time (i.e., z-sensor time)
; only magz.time is correct

n=n_elements(magxyz.comp1)
magx = {nt:dblarr(n),time:dblarr(n)}
magy = {nt:dblarr(n),time:dblarr(n)}
magz = {nt:dblarr(n),time:dblarr(n)}
magx.nt = magxyz.comp1
magy.nt = magxyz.comp2
magz.nt = magxyz.comp3
magx.time = magxyz.time
magy.time = magxyz.time
magz.time = magxyz.time
magxyz=0.

; warn about short intervals

if magz.time(n-1)-magz.time(0) lt time_min_rec*60.d0 then begin
  print,''
  print,'WARNING: Recommend time spans > ',time_min_rec,' minutes for this procedure'
  print,''
endif

; correct for zero-crossing if uncalibrated data

if (magdc.valid eq 0 and delta_cross ne 0.d0) then begin
  bf = where (magx.nt gt 0.d0,nf)
  if (nf gt 0) then magx.nt(bf) = magx.nt(bf)-delta_cross
  bf = where (magx.nt lt 0.d0,nf)
  if (nf gt 0) then magx.nt(bf) = magx.nt(bf)+delta_cross
  bf = where (magy.nt gt 0.d0,nf)
  if (nf gt 0) then magy.nt(bf) = magy.nt(bf)-delta_cross
  bf = where (magy.nt lt 0.d0,nf)
  if (nf gt 0) then magy.nt(bf) = magy.nt(bf)+delta_cross
  bf = where (magz.nt gt 0.d0,nf)
  if (nf gt 0) then magz.nt(bf) = magz.nt(bf)-delta_cross
  bf = where (magz.nt lt 0.d0,nf)
  if (nf gt 0) then magz.nt(bf) = magz.nt(bf)+delta_cross
endif

; Interpolate high rate data

if (magdc.valid eq 0) then begin
  mag_int = interp_mag(magx.nt)
  magx.nt=mag_int
  mag_int = interp_mag(magy.nt)
  magy.nt=mag_int
  mag_int = interp_mag(magz.nt)
  magz.nt=mag_int
  mag_int=0.

; Fix the recursive filter 

  print,''
  print,'Fixing Recursive Filter'
  print,''
  fix_magx,magx,magx_fix,magx_time
  fix_magy,magy,magy_fix,magy_time
  fix_magz,magz,magz_fix,magz_time

endif else begin

  magx_fix = magx.nt
  magx_time = magx.time
  magy_fix = magy.nt
  magy_time = magy.time
  magz_fix = magz.nt
  magz_time = magz.time

endelse

; resample 512 sps data at 128 sps

dt = magz_time(1:*)-magz_time(0:*)
nt = where (dt lt 1.d0/511.d0,nnt)
no = where (dt gt 1.d0/511.d0,nno)
if (nno gt 0) then no = [no,n_elements(dt)] else no = [n_elements(dt)]
nno=nno+1

if (nnt gt 0 ) then begin

    print,''
    print,'Smoothing and resampling 512 sps data at 128 sps'
    print,''

    nv = 2L+lindgen((nnt+2L)/4L)*4L

    tmp_t=[magz_time(no),magz_time(nt(nv))]
    t_sort=sort(tmp_t)
    magz_time=tmp_t(t_sort)

    tmp=smooth(magx_fix,7)
    tmp=[magx_fix(no),tmp(nt(nv))]
    magx_fix=tmp(t_sort)

    tmp=smooth(magy_fix,7)
    tmp=[magy_fix(no),tmp(nt(nv))]
    magy_fix=tmp(t_sort)

    tmp=smooth(magz_fix,7)
    tmp=[magz_fix(no),tmp(nt(nv))]
    magz_fix=tmp(t_sort)

endif

; get the appropriate coupling matrix - include fdf_predict if available

ref_9937 = str_to_time('1999-02-24/22:29:47')

cal_hist = get_cal_history(fdf_predict=fdf_predict)

tw = dblarr(3,3)
ofst = dblarr(3)

if (n_tags(cal_hist) ne 0) then begin
  borb = where (tag_names(cal_hist) eq 'ORB_REF',norb)
  b=where (cal_hist.t lt magz_time(0),nb)
  if (nb gt 0) then begin
    tw(0,0) =  cal_hist.xx(nb-1)
    tw(0,1) =  cal_hist.yx(nb-1)
    tw(0,2) =  cal_hist.zx(nb-1)
    tw(1,0) =  cal_hist.xy(nb-1)
    tw(1,1) =  cal_hist.yy(nb-1)
    tw(1,2) =  cal_hist.zy(nb-1)
    tw(2,0) =  cal_hist.xz(nb-1)
    tw(2,1) =  cal_hist.yz(nb-1)
    tw(2,2) =  cal_hist.zz(nb-1)
    ofst(0) =  cal_hist.ox(nb-1)
    ofst(1) =  cal_hist.oy(nb-1)
    ofst(2) =  cal_hist.oz(nb-1)
    if (nb ge n_elements(cal_hist.xx) or nb eq 1) then begin
        print,string("07b)
        print,'WARNING - Data out of range of Calibration file'
        print,'' 
    endif else if (norb gt 0) then begin
;
;       Interpolation scheme tries to keep the same coupling matrix for an entire
;       orbit, there will be differences between orbits if the data are 
;       calibrated for individual orbits versus several orbits at once.
;       In the latter case, the median orbit determines the calibration for
;       the entire span of data
;
;       Also note that the interpolation will not occur for intervals greater than
;       norb_max_gap orbits
;
        if (cal_hist.orb_ref(nb)-cal_hist.orb_ref(nb-1) gt norb_max_gap ) then begin
            print,''
            print,'FAILED TO INTERPOLATE CALIBRATION DATA'
            print,'  orbit gap greater than',norb_max_gap
            print,''
        endif else begin
            torb = median(magz_time,/even)
            tperorb = (cal_hist.t(nb)-cal_hist.t(nb-1))/(cal_hist.orb_ref(nb)-cal_hist.orb_ref(nb-1))
            norb_ref = floor(cal_hist.orb_ref(nb-1)+(torb-cal_hist.t(nb-1))/tperorb)
            print,''
            print,'Interpolating Calibration Data to Orbit',norb_ref
            if (magz_time(n_elements(magz_time)-1L)-magz_time(0) gt 1.1 * tperorb) then begin
                print,string("07b)
                print,'WARNING - data spans more than one orbit'
                print,'  Calibration determined for median orbit'
            endif
            print,''
            frct = float(norb_ref-cal_hist.orb_ref(nb-1))/float(cal_hist.orb_ref(nb)-cal_hist.orb_ref(nb-1))
            tw(0,0) =  cal_hist.xx(nb-1) + frct*(cal_hist.xx(nb)-cal_hist.xx(nb-1))
            tw(0,1) =  cal_hist.yx(nb-1) + frct*(cal_hist.yx(nb)-cal_hist.yx(nb-1))
            tw(0,2) =  cal_hist.zx(nb-1) + frct*(cal_hist.zx(nb)-cal_hist.zx(nb-1))
            tw(1,0) =  cal_hist.xy(nb-1) + frct*(cal_hist.xy(nb)-cal_hist.xy(nb-1))
            tw(1,1) =  cal_hist.yy(nb-1) + frct*(cal_hist.yy(nb)-cal_hist.yy(nb-1))
            tw(1,2) =  cal_hist.zy(nb-1) + frct*(cal_hist.zy(nb)-cal_hist.zy(nb-1))
            tw(2,0) =  cal_hist.xz(nb-1) + frct*(cal_hist.xz(nb)-cal_hist.xz(nb-1))
            tw(2,1) =  cal_hist.yz(nb-1) + frct*(cal_hist.yz(nb)-cal_hist.yz(nb-1))
            tw(2,2) =  cal_hist.zz(nb-1) + frct*(cal_hist.zz(nb)-cal_hist.zz(nb-1))
            ofst(0) =  cal_hist.ox(nb-1) + frct*(cal_hist.ox(nb)-cal_hist.ox(nb-1))
            ofst(1) =  cal_hist.oy(nb-1) + frct*(cal_hist.oy(nb)-cal_hist.oy(nb-1))
            ofst(2) =  cal_hist.oz(nb-1) + frct*(cal_hist.oz(nb)-cal_hist.oz(nb-1))
        endelse
    endif
    if (magz_time(0) gt ref_9937 and cal_hist.t(nb-1) lt ref_9937) then begin
        print,string("07b)
        print,'WARNING - Orbit > 9936, Using Interim Calibration'
        print,'' 
        tw(0,0) =  0.994810d0 ; = tw_xx
        tw(0,1) =  0.021717d0 ; = tw_yx
        tw(0,2) =  0.008806d0 ; = tw_zx
        tw(1,0) = -0.010418d0 ; = tw_xy
        tw(1,1) =  0.936967d0 ; = tw_yy
        tw(1,2) =  0.005444d0 ; = tw_zy
        tw(2,0) = -0.011389d0 ; = tw_xz
        tw(2,1) = -0.012910d0 ; = tw_yz
        tw(2,2) =  0.970318d0 ; = tw_zz
        ofst(0)=-16.254d0
        ofst(1)=8.899d0
        ofst(2)=114.373d0
    endif
  endif else cal_hist = 0 
endif

if (n_tags(cal_hist) eq 0) then begin

    if (magz_time(0) gt ref_9937) then begin

        print,string("07b)
        print,'WARNING - Orbit > 9936, Using Interim Calibration'
        print,'' 
        tw(0,0) =  0.994810d0 ; = tw_xx
        tw(0,1) =  0.021717d0 ; = tw_yx
        tw(0,2) =  0.008806d0 ; = tw_zx
        tw(1,0) = -0.010418d0 ; = tw_xy
        tw(1,1) =  0.936967d0 ; = tw_yy
        tw(1,2) =  0.005444d0 ; = tw_zy
        tw(2,0) = -0.011389d0 ; = tw_xz
        tw(2,1) = -0.012910d0 ; = tw_yz
        tw(2,2) =  0.970318d0 ; = tw_zz
        ofst(0)=-16.254d0
        ofst(1)=8.899d0
        ofst(2)=114.373d0

    endif else begin

;   Calibration for orbits < 9937

       tw(0,0) =  0.984672d0 ; = tw_xx
       tw(0,1) =  0.008272d0 ; = tw_yx
       tw(0,2) =  0.006700d0 ; = tw_zx
       tw(1,0) =  0.000000d0 ; = tw_xy
       tw(1,1) =  0.928669d0 ; = tw_yy
       tw(1,2) =  0.006234d0 ; = tw_zy
       tw(2,0) = -0.008604d0 ; = tw_xz
       tw(2,1) = -0.014153d0 ; = tw_yz
       tw(2,2) =  0.957579d0 ; = tw_zz
       ofst(0)=-65.60d0
       ofst(1)=20.52d0
       ofst(2)=-71.75d0

    endelse
endif

; also output warnings for data acquired during P12S7V anomaly

ref_9200 = str_to_time('1998-12-19/02:37:50')
ref_8431 = str_to_time('1998-10-09/06:21:17')

if (magz_time(0) gt ref_9200 and magz_time(0) lt ref_9937) then begin
    print,string("07b)
    print,'DANGER - Orbit >= 9200, < 9937: P12S7V Under voltage - BAD ADC GAIN'
    print,'' 
endif else if (magz_time(0) gt ref_8431 and magz_time(0) le ref_9200) then begin
    print,string("07b)
    print,'WARNING - Orbit >= 8431: P12S7V Under voltage'
    print,'' 
endif


; Apply the old coupling matrix

if (magdc.valid eq 0) then begin
  mag_x = tw(0,0)*magx_fix+tw(1,0)*magy_fix+tw(2,0)*magz_fix - ofst(0)
  mag_y = tw(0,1)*magx_fix+tw(1,1)*magy_fix+tw(2,1)*magz_fix - ofst(1)
  mag_z = tw(0,2)*magx_fix+tw(1,2)*magy_fix+tw(2,2)*magz_fix - ofst(2)
endif else begin
  mag_x = magx_fix
  mag_y = magy_fix
  mag_z = magz_fix
  tww=invert(tw)
  magx = mag_x+ofst(0)
  magy = mag_y+ofst(1)
  magz = mag_z+ofst(2)
  magx_fix = tww(0,0)*magx+tww(1,0)*magy+tww(2,0)*magz
  magy_fix = tww(0,1)*magx+tww(1,1)*magy+tww(2,1)*magz
  magz_fix = tww(0,2)*magx+tww(1,2)*magy+tww(2,2)*magz
endelse

; Compute a new tweaker matrix

print,''
print,'Computing New Tweaker Coefficients - Be Patient'
print,''
time=magz_time-magz_time(0)
BB = {x:time,y:[[mag_x],[mag_y],[mag_z]]}

; enable following statements to see if reducing samples increases speed

;BB = mag_vec_smooth_resample(BB,256L,4L)
;BB = mag_vec_smooth_resample(BB,128L,4L)
;BB = mag_vec_smooth_resample(BB,64L,2L)

spin_tone_fit,BB.y,BB.x,coef,tspin,ttag

; apply a spin period filter (allow 10% range in spin period)
; added by RJ Strangeway 4/17/98

bgood= where (tspin gt .9*median(tspin) and tspin lt 1.1*median(tspin),ngood)
n_est=n_elements (tspin)
if ( ngood lt .5*n_est) then begin
   print,''
   print,'DANGER - more than 50% of the data have bad spin period estimates'
   print,'         These data have been deleted from the spin fit estimators'
   print,'         Proceed at your own risk'
   print,''
endif
if ( ngood lt .9*n_est) then begin
   print,''
   print,'WARNING - more than 10% of the data have bad spin period estimates'
   print,'          These data have been deleted from the spin fit estimators'
   print,'          Check data carefully'
   print,''
endif


pseudo = {x:magx_fix,y:magy_fix,z:magz_fix,t:magz_time}
mag = {x:mag_x,y:mag_y,z:mag_z,t:magz_time}
spin_fit = {bspin:reform(coef(0,bgood)),bz_dc:reform(coef(1,bgood)), $
            by_bx:reform(coef(2,bgood)),phase_by:reform(coef(3,bgood)), $
            bz_bx:reform(coef(4,bgood)),phase_bz:reform(coef(5,bgood)), $
            bx_dc:reform(coef(6,bgood)),by_dc:reform(coef(7,bgood)), $
            nsamp:reform(coef(8,bgood)),time:ttag(bgood)+magz_time(0), $
            spin:tspin(bgood)}
            
end

function get_quartiles,vals

; get the upper and lower quartiles and median

md=median(vals)
b=where (vals lt md)
lo=median(vals(b))
b=where (vals gt md)
hi = median(vals(b))
return,[lo,md,hi]

end

; fit the residual tweaker coefficients

; call in the folllowing sequence, for example
;
;tw_zx = tweaker_coeff_fit(-checkfit.bz_bx*cos(checkfit.phase_bz),checkfit.time,mag.t)
;
; where checkfit is returned from the last SVDFIT call
; and time tags for the last tweaked data
;
; on return tw_zx contains the fit tweaker coeffecients,
; final fix is performed with magz = magz+tw_zx*magx
;
; for each component:
;tw_zx = tweaker_coeff_fit(-checkfit.bz_bx*cos(checkfit.phase_bz),checkfit.time,mag.t)
;tw_zy = tweaker_coeff_fit( checkfit.bz_bx*sin(checkfit.phase_bz),checkfit.time,mag.t)


; outlier rejection

function tweaker_coeff_fit,tw,tw_time,fit_time,width=width

if not keyword_set(width) then width = 7

nb1 = 0
nb2 = -1
nloop = 0
tw_t=tw_time
tw_v=tw

while nb1 ne nb2 and nloop lt 5 do begin

; pass-1

  avg = moment(tw_v,sdev=sdev)
  b = where (abs(tw_v-avg(0)) lt 5.*sdev,nb1)

; pass-2

  avg = moment(tw_v(b),sdev=sdev)
  b = where (abs(tw_v-avg(0)) lt 5.*sdev,nb2)

  tw_t = tw_t(b)
  tw_v = tw_v(b)

  nloop = nloop + 1

endwhile

; width point smoother, and residual rejection

if (nb2 gt 0) then tw_sm=smooth(tw_v,width < nb2-1L,/edge_truncate)
avg_sm = moment(tw_v-tw_sm,sdev=sdev_sm)
b_sm = where (abs(tw_v-tw_sm) lt 5.*sdev_sm,nb_sm)
tw_sm=smooth(tw_v(b_sm),7 < nb_sm-1L,/edge_truncate)
tw_sm=smooth(tw_sm,width < nb_sm-1L,/edge_truncate)
tw_v=tw_v(b_sm)
tw_t=tw_t(b_sm)

; spline interpolation for tweaker
 
y2=spl_init(tw_t-tw_t(0),tw_sm,/double)
tw_zx=spl_interp(tw_t-tw_t(0),tw_sm,y2,fit_time-tw_t(0),/double)


return,tw_zx
end





; function running_total(vv)

; simple running total

function running_total,vv

out = [vv,0.]

n = n_elements(vv)

nn = 0L
out(nn) = 0.

while nn lt n do begin
  out(nn+1) = out(nn) + vv(nn)
  nn = nn + 1L
endwhile

return,out

end

; return an index, with outliers rejected

; corrected for short integers

; also allow for weights to be passed

function outlier_rejection,d_in,wt=wt

nb1 = 0L
nb2 = -1L
nloop = 0

if not keyword_set(wt) then begin
    s=size(d_in)
    st=s(s(0)+1)
    if (st eq 5) then wt=dblarr(n_elements(d_in))+1.d0 $
    else wt=fltarr(n_elements(d_in))+1.0
endif

d_v=d_in

;b = lindgen(n_elements(d_in))
b = where (finite(d_in)) ; changed 8/27/98 - RJS

while nb1 ne nb2 and nloop lt 5 do begin

; pass-1

  avg=total(d_v(b)*wt(b))/total(wt(b))
  nb=double(n_elements(b))
  sdev=sqrt((nb-1.d0)*total((d_v(b)-avg)*(d_v(b)-avg)*wt(b))/total(wt(b))/nb)
  b = where (abs(d_v-avg) lt 5.*sdev,nb1)

; pass-2

  avg=total(d_v(b)*wt(b))/total(wt(b))
  nb=double(n_elements(b))
  sdev=sqrt((nb-1.d0)*total((d_v(b)-avg)*(d_v(b)-avg)*wt(b))/total(wt(b))/nb)
  b = where (abs(d_v-avg) lt 5.*sdev,nb2)

  nloop = nloop + 1

endwhile

; 7 point smoother, and residual rejection

d_sm=smooth(d_v(b),7 < nb2-1L,/edge_truncate)
avg_sm = moment(d_v(b)-d_sm,sdev=sdev_sm)
b_sm = where (abs(d_v(b)-d_sm) lt 5.*sdev_sm,nb_sm)

return,b(b_sm)

end





function get_torquer_mag,spinfit,mag,tw,torquer,debug=debug

; get an estimate of the torquer coil offsets

; Written by R. J. Strangeway 4/17/98
; Modified by RJS 5/11/98 to take into account change in tweaker matrix
; modified by RJS 8/21/98 to use 0.04 as the average x/y correlation (bymm)

; Now uses piece wise interpolation (RJS 6/19/98)

; Modified by RJS 9/28/01 to disable torquer offset over a large data gap

if keyword_set(debug) then debug = 1 else debug = 0

yfact=1.d0
zfact=1.d0
ny=0
nz=0

; select "good" data on calculated spin period (+/- 5% of median)
; plus constant data rate

spin_med=median(spinfit.spin)
spin_test = abs(spinfit.spin - spin_med)
rate_test = alog(round(spinfit.nsamp*.5/spinfit.spin))/alog(2.) 
rate_test = abs(rate_test - round(rate_test))
bgood=where (spin_test lt .05*spin_med and rate_test lt 1.e-3)
bx_dc=spinfit.bx_dc(bgood)
by_dc=spinfit.by_dc(bgood)
bz_dc=spinfit.bz_dc(bgood)
dbx_dc=bx_dc(1:*)-bx_dc(0:*)
dby_dc=by_dc(1:*)-by_dc(0:*)
dbz_dc=bz_dc(1:*)-bz_dc(0:*)

tm = spinfit.time(bgood)
dtm = tm[1:*]-tm[0:*]

; use ladfit to fit the two spin plane sensors
; restrict the data to where the dby_dc lies between bylo and byhi * dbx_dc

bymm = .04d0+tw(0,1) ; found from fits to torquer data

; changed from 0.06 to 0.04 by RJS 8/21/98
; upper limit changed to factor 3 by RJS 10/13/98 - missing some torquer data

bylo=.5d0*bymm
byhi=3.d0*bymm

ll = bylo*dbx_dc
hh = byhi*dbx_dc
bn = where (ll gt hh, nb)
if (nb gt 0) then begin
  gg = ll
  ll(bn) = hh(bn)
  hh(bn) = gg(bn)
endif

; add in time step check - use 60 s

bt = where (dtm lt 60. and ((dby_dc gt ll and dby_dc lt hh) or abs(dbx_dc) lt 10), nb)
if (nb gt 0) then begin
  xx=dbx_dc(bt(sort(dbx_dc(bt))))
  yy=dby_dc(bt(sort(dbx_dc(bt))))
  ft = ladfit(xx,yy,/double)

  if (debug) then print,'ft(1) - Y = ',ft(1) ; debug

  by = where (abs(dbx_dc(bt)) gt 10 and abs(dbx_dc(bt)) lt 200 , ny) 
  if (ny gt 0) then by=bt(by)

; safety check - expect ft(1) to be between bylo and byhi

  if (ft(1) lt bylo or ft(1) gt byhi) then ny=0

  yfact=ft(1)

endif

;  detrend dbz_dc, and use to further constrain the torquer intervals

bzlo=-10.d0
bzhi=-2.5d0

if (ny gt 0) then begin

   msk=intarr(n_elements(dbz_dc))
   msk(by)=1
   bm = where (msk eq 0)
   smth = smooth(dbz_dc(bm),21)
   dbz_dc=dbz_dc-interpol(smth,bm,lindgen(n_elements(dbz_dc)))

   ll = bzlo*dbx_dc
   hh = bzhi*dbx_dc
   bn = where (ll gt hh, nb)
   if (nb gt 0) then begin
     gg = ll
     ll(bn) = hh(bn)
     hh(bn) = gg(bn)
   endif

   bt = where (dbz_dc gt ll and dbz_dc lt hh and abs(dbx_dc) lt 200, nb)
   if (nb gt 0) then begin
     xx=dbx_dc(bt(sort(dbx_dc(bt))))
     zz=dbz_dc(bt(sort(dbx_dc(bt))))
     if (nb le 2) then begin 
       ff = total(zz/xx)/nb
       ft = [0,ff]
     endif else begin
       ft = ladfit(xx,zz,/double)
     endelse

     if (debug) then print,'ft(1) - Z = ',ft(1) ; debug

     bz = where (abs(dbx_dc(by)) gt 10 and abs(dbx_dc(by)) lt 200 , nz) 
     if (nz gt 0) then bz = by(bz)

;    safety check - expect ft(1) to be between bzlo and bzhi

     if (ft(1) lt bzlo or ft(1) gt bzhi) then nz=0

     zfact=ft(1)

;    additional check - delete all steps less than 100 nT in dbz_dc

     if (n_elements(bz) gt 1) then dn = [0,(bz(1:*)-bz(0:*))] else dn = [0]
     bgap = [(where (dn ne 1, ngap)),n_elements(dn)]
     for n = 0,ngap -1L do begin
         check_bz = total(dbz_dc(bz(bgap(n)):bz(bgap(n+1)-1)))
         if (abs (check_bz) lt 100.d0) then dbz_dc(bz(bgap(n)):bz(bgap(n+1)-1)) = 0.d0
     endfor
     by=bz
     bz = where (abs(dbz_dc(by)) gt 10, nz)
     if (nz gt 0) then bz=by(bz)

   endif
endif

if (nz gt 0) then begin


   xtorq=spinfit.bx_dc-spinfit.bx_dc
   ytorq=spinfit.bx_dc-spinfit.bx_dc
   ztorq=spinfit.bx_dc-spinfit.bx_dc

;   for nn = 0,nz-1L do xtorq(bgood(bz(nn)+1):*) = xtorq(bgood(bz(nn)+1):*)+dbx_dc(bz(nn))
;   xtorq=xtorq-median(xtorq)
;   ytorq=yfact*xtorq
;   ztorq=zfact*xtorq

;   use ztorq to specify the others (4/27/98)

   for nn = 0,nz-1L do ztorq(bgood(bz(nn)+1):*) = ztorq(bgood(bz(nn)+1):*)+dbz_dc(bz(nn))
   ztorq=ztorq-median(ztorq)
   xtorq=ztorq/zfact
   ytorq=yfact*xtorq

;  at this stage query the user

   has_torq = 1

   if (debug) then begin
      !p.multi=[0,1,3]
      !p.charsize=2.
      bb = where (abs(spinfit.bz_dc) lt 15000.)
      temp=spinfit.bz_dc(bb)
      temp=temp(1:*)-temp(0:*)
      plot,temp,ytitle='Delta_BZ_DC',yrange=[min(temp > (-1000.)),max(temp < 1000.)]
      plot,ztorq(bb),ytitle='Z_TORQ'
      temp=spinfit.bz_dc(bb)-ztorq(bb)
      temp=temp(1:*)-temp(0:*)
      plot,temp,ytitle='Delta_BZ_DC-ZTORQ',yrange=[min(temp > (-1000.)),max(temp < 1000.)]

      !p.multi=0
      !p.charsize=0.

      ans=''
      print,string("07b)
      read,ans,prompt='Is it ok to subtract torquer offsets? '
      ans=strmid(ans,0,1)

      if (ans eq 'N' or ans eq 'n') then has_torq = 0

    endif 

    if (has_torq) then  begin

        print,''
        print,'Subtracting torquer coil offsets'
        print,''

        spinfit.bx_dc=spinfit.bx_dc-xtorq
        spinfit.by_dc=spinfit.by_dc-ytorq
        spinfit.bz_dc=spinfit.bz_dc-ztorq

; interpolate the torquers - this could be done more quickly piece wise

        xyz=mag.t-mag.t
        torquer={t:mag.t,x:xyz,y:xyz,z:xyz}

;       torquer.x=interpol(xtorq,spinfit.time-mag.t(0),mag.t-mag.t(0))
;       torquer.y=interpol(ytorq,spinfit.time-mag.t(0),mag.t-mag.t(0))
;       torquer.z=interpol(ztorq,spinfit.time-mag.t(0),mag.t-mag.t(0))

;       Now using piece wise interpolation

        dd = [0.d0,xtorq(1:*)-xtorq(0:*)]
        bd = where (dd ne 0.d0, nd)
        if (nd gt 0) then begin
           tl=mag.t(0)-1.d0
           for nn = 0, nd-1L do begin
              bprev = where (mag.t gt tl and mag.t lt spinfit.time(bd(nn)-1L),nprev)
              if (nprev gt 0) then begin 
                 xyz(bprev)=xyz(bprev)+xtorq(bd(nn)-1L)
                 tl = mag.t(bprev(nprev-1L))
              endif
              bfix = where (mag.t ge spinfit.time(bd(nn)-1L) and  $
              mag.t lt spinfit.time(bd(nn)), nfix)
              if (nfix gt 0) then begin
                 dtorqdt=(xtorq(bd(nn))-xtorq(bd(nn)-1L))/(spinfit.time(bd(nn))-spinfit.time(bd(nn)-1L))
                 xyz(bfix)=xtorq(bd(nn)-1L)+dtorqdt*(mag.t(bfix)-spinfit.time(bd(nn)-1L))
                 tl = mag.t(bfix(nfix-1L))
              endif
           endfor
           blast = where (mag.t gt tl, nlast)
           if (nlast ne 0) then xyz(blast)=xyz(blast)+xtorq(n_elements(xtorq)-1L)
        endif

        torquer.x = xyz
        torquer.y = yfact*torquer.x
        torquer.z = zfact*torquer.x
        
    endif

endif else begin

   has_torq = 0

endelse

return,has_torq

end

; fix up the spin phase - still under test

pro fix_up_spin,frq,phs,time_error=time_error,flags=flags,nsm1=nsm1,nsm2=nsm2,nsm3=nsm3,nsm4=nsm4,debug=debug,no_query=no_query,is_sun=is_sun

if keyword_set(debug) then debug = 1 else debug = 0
if keyword_set(no_query) then no_query = 1 else no_query = 0

flags=intarr(n_elements(frq.y))
time_error=0

; flags is quality flag array:    0   good
;                                 1   object set to zero
;                                 2   in eclipse
;                                 4   data not smoothed
;                                16   Missing spin phase data

OBJ_ZERO = 1
IN_ECLIPSE = 2
NOT_SMOOTHED = 4
MISSING = 16

bell = string("07b)

bfin = where (finite(frq.x) and finite(frq.y), nfin)
if (nfin eq 0) then begin
   flags=flags + MISSING
   print,bell
   print,'FIX_UP_SPIN - NO GOOD DATA - returning'
   print,''
   return
endif
t_tmp=frq.x(bfin)
dt = t_tmp[1:*]-t_tmp[0:*]
frq_tmp=frq.y(bfin)
phs_tmp=phs.y(bfin)

bbad = where ((dt mod 256.d0) eq 0.d0,nbad)
if (nbad ne 0) then begin
   print,bell
   print,'FIX_UP_SPIN - BAD SPIN DATA - setting to NAN and returning'
   print,''
   frq.y(bfin(bbad+1))=!values.d_nan
   phs.y(bfin(bbad+1))=!values.d_nan
   flags=flags + NOT_SMOOTHED
   flags(bfin(bbad+1))=flags(bfin(bbad+1)) + MISSING
   return
endif


; if delta_t < 10 seconds pre-smooth
; want to smooth ~ 15 x 16 seconds

; these constants are have been determined arbitrarilly,
; can be over-ridden by keywords, but it is NOT recommended

; nsm1 and nsm2 specify the smoothing filter for dejittering
; nsm3 sets the smoother for folding back over-smoothed changes 
; in "good" (i.e. sunlit) data
;
; nsm4 is final delta-phase smoother - to put back in long term term trends
;
; nsm1,nsm2 shorter than set value - leaves in shorter scale wiggles
; nsm1,nsm2 shorter than set value - leaves too much long term variation

if ( not keyword_set(nsm1)) then nsm1=15
if ( not keyword_set(nsm2)) then nsm2=15
if ( not keyword_set(nsm3)) then nsm3=7
if ( not keyword_set(nsm4)) then nsm4=31
b=where (dt lt 10.,nb)
if (nb gt .1*n_elements(dt)) then begin
  nsm1=15*nsm1
  nsm2=15*nsm2
  nsm3=15*nsm3
  nsm4=15*nsm4
endif

; smooth the frequency 

frq_sm=smooth(smooth(frq_tmp,nsm1,/edge_truncate),nsm2,/edge_truncate)

; look for UT-offsets

time_error = 0
bkeep=lindgen(n_elements(frq_tmp))
toffset = dblarr(n_elements(t_tmp))
df=frq_tmp-frq_sm
avg_df = moment(df,sdev=sdev_df)
bf = where (abs(df-avg_df(0)) gt 5.*sdev_df, nf)
if (nf gt 0) then begin
   bg = where (abs(df-avg_df(0)) le 5.*sdev_df, ng)
   y2=spl_init(t_tmp(bg)-t_tmp(0),frq_tmp(bg),/double)
   frq_frq=spl_interp(t_tmp(bg)-t_tmp(0),frq_tmp(bg),y2,t_tmp-t_tmp(0),/double)
endif else begin
   frq_frq=frq_tmp
endelse
n_spins = round((frq_frq(1:*)*dt + phs_tmp(0:*) - phs_tmp(1:*))/360.d0)
t_err = 360.d0*n_spins/frq_frq(1:*) - dt

;  use 0.1 s as error for time steps - correct later in the code

bt = where (abs(t_err) gt 0.1d0, nbt)
if (nbt gt 0) then frq_tmp=frq_frq

; re-smooth here, after deleting jumps (includes pre-smooth)

; generate weights

if (nsm1 gt 20) then frq_tmp=smooth(frq_tmp,15,/edge_truncate)        
frq_sm=smooth(smooth(frq_tmp,nsm1,/edge_truncate),nsm2,/edge_truncate)
dff = frq_tmp-frq_sm
dff = dff - smooth(smooth(dff,nsm3,/edge_truncate),nsm3,/edge_truncate)
res = sqrt(nsm3*smooth(dff*dff,nsm3,/edge_truncate))
wt = 1.d0 - res*100.d0
wt_raw=wt

; if AttitudeCtrl data available - use these - or use is_sun if passed in

has_sun=0
if (keyword_set(is_sun)) then begin
   data_28 = is_sun
   has_sun=1
endif else begin
   prog = getenv('FASTBIN') + '/showDQIs'
   spawn, prog, result, /noshell
   b = where (strpos(result,'AttitudeCtrl') ge 0,nb)
   if (nb gt 0) then begin
      print,'GETTING IS_SUN'
      data=get_ts_from_sdt('AttitudeCtrl',2001,/all)

;     force data monotonic

      spin_zero=data.comp24 + data.time(0) - (data.time(0) mod 86400.d0)
      data_28 = data.comp28
      bn = where (spin_zero(1:*) - spin_zero(0:*) gt 0.d0, nb)
      while (nb ne (n_elements(spin_zero)-1L)) do begin
         spin_zero=spin_zero([0,bn+1])
         data_28=data_28([0,bn+1])
         bn = where (spin_zero(1:*) - spin_zero(0:*) gt 0.d0, nb)
      endwhile
      has_sun=1
      if (n_elements(data_28) ne n_elements(frq.x)) then has_sun=0
   endif
endelse

if (has_sun) then begin
  is_sun = data_28(bfin)

; use wt for not 176, wt_raw for not 0 or 176

  gg=where (is_sun eq 176, ng)
  bb=where (is_sun ne 176, nb)
  if (ng gt 0) then is_sun(gg)=1
  if (nb gt 0) then is_sun(bb)=0
  if (n_elements(wt) eq n_elements(bkeep)) then wt = double(is_sun(bkeep))

  is_sun = data_28(bfin)
  gg=where ((is_sun mod 176) eq 0, ng)
  bb=where ((is_sun mod 176) ne 0, nb)
  if (ng gt 0) then is_sun(gg)=1
  if (nb gt 0) then is_sun(bb)=0
  if (n_elements(wt) eq n_elements(bkeep)) then wt_raw = double(is_sun(bkeep))

  bb = where (data_28(bfin) eq 0, nb)
  if (nb ne 0 and n_elements(wt) eq n_elements(bkeep)) then $
    flags(bfin(bb))=flags(bfin(bb)) + OBJ_ZERO
endif

bb=where (wt lt 0., nb)
if (nb gt 0) then wt(bb)=0.d0

wt = 2.d0*smooth(wt,nsm2,/edge_truncate)
bb=where (wt gt 1., nb)
if (nb gt 0) then wt(bb)=1.d0
bb=where (wt gt 0., nb)
if (nb gt 0) then wt(bb)=sqrt(wt(bb))

; find where wt_raw lt .5 - set up an array of indices

becl=where (wt_raw lt .5,necl)
if (necl gt 0) then begin
   flags(becl)=flags(becl) + IN_ECLIPSE
   if (necl eq 1) then begin
     ecl_start=[becl(0)]
     ecl_end = [becl(0)]
   endif else begin
     db = becl(1:*)-becl(0:*)
     bgap = where (db ne 1,ngap)
     if (ngap ne 0) then begin
       ecl_start=[becl(0),becl(bgap+1L)]
       ecl_end = [becl(bgap),becl(n_elements(becl)-1L)]
     endif else begin
       ecl_start=[becl(0)]
       ecl_end = [becl(n_elements(becl)-1L)]
     endelse
   endelse
endif

;  correct UT offsets

bt = where (abs(t_err) gt 0.1d0, nbt)
if (nbt gt 0) then begin
   for n = 0L,nbt-1L do begin
      if (necl eq 0) then begin
         nchk = 0
      endif else begin
         bchk = where (ecl_start eq bt(n)+1,nchk)
         if (nchk eq 0) then bchk = where (ecl_end eq bt(n),nchk)
      endelse
      if (nchk eq 0) then begin
         toffset(bt(n)+1:*) = toffset(bt(n)+1:*)+t_err(bt(n))
         time_error = 1
      endif
   endfor
   t_tmp=t_tmp+toffset
   dt = t_tmp[1:*]-t_tmp[0:*]
endif

if (time_error) then begin
   print,''
   print,'FIX_UP_SPIN - Correcting UT offset errors'
   print,''
endif

; resmooth data, filtering out frequency jumps at eclipse entry and exit

phs_new=phs_tmp 
phs_str=phs_new
frq_str=frq_tmp

if (necl gt 0) then begin
   btmp=intarr(n_elements(frq_tmp))+1
   btmp(ecl_start)=0
   btmp(ecl_end)=0
   btmp(0)=1
   btmp(n_elements(btmp)-1L)=1
   bgood=where(btmp eq 1)
   frq_huh=frq_tmp(bgood)
   if (nsm1 gt 20) then frq_huh=smooth(frq_tmp(bgood),15,/edge_truncate)        
   frq_huh=smooth(smooth(frq_huh,nsm1,/edge_truncate),nsm2,/edge_truncate)
   y2=spl_init(t_tmp(bgood)-t_tmp(0),frq_huh,/double)
   tmp_tmp=spl_interp(t_tmp(bgood)-t_tmp(0),frq_huh,y2,t_tmp-t_tmp(0),/double)
   tmp_tmp(bgood)=frq_tmp(bgood)
   frq_tmp=tmp_tmp
   if (nsm1 gt 20) then frq_tmp=smooth(frq_tmp,15,/edge_truncate)        
   frq_sm=smooth(smooth(frq_tmp,nsm1,/edge_truncate),nsm2,/edge_truncate)
endif

frq_sm = frq_sm + wt*smooth(frq_tmp-frq_sm,nsm3,/edge_truncate)

; compute difference between reported phase and integrated spin fequency

n_p=n_elements(phs_tmp)
for nn = 1L,n_p-1L do phs_tmp(nn)=phs_tmp(nn-1)+ $
.5d0*(frq_sm(nn)+frq_sm(nn-1))*(t_tmp(nn)-t_tmp(nn-1))
phs_tmp=phs_tmp mod 360.
del_p = phs_tmp-phs_new
bb=where (del_p gt 180.,nb)
if (nb gt 0) then del_p(bb)=del_p(bb)-360.
bb=where (del_p lt -180.,nb)
if (nb gt 0) then del_p(bb)=del_p(bb)+360.
phs_tmp = del_p + phs_new

del_phase=0

; remove large delta's from the differences - trying to take care of 
; eclipse jumps - under test 5/12/98

; calculate phase jump at eclipse entry and exit

if (necl gt 0) then begin
   dd=del_p(1:*)-del_p(0:*)
   avg_dd = moment(dd,sdev=sdev_dd)
   bg = where (abs(dd-avg_dd(0)) le 5.*sdev_dd, ng)
   if (ng gt 0) then avg_dd = moment(dd(bg),sdev=sdev_dd)
   bd = where (abs(dd-avg_dd(0)) gt 5.*sdev_dd, nd)
   if (nd gt 0) then begin
      diff_dd=fltarr(n_elements(dd))
      for nn = 0,nd-1L do begin
         bexit = where (ecl_end eq bd(nn),nexit)
         if (nexit eq 1) then begin
            n1=ecl_start(bexit(0))+1L
            n2=ecl_end(bexit(0))
            med_del=0.d0
            if (n2-n1 ge 2) then med_del=median(dd(n1:n2),/even) 
            diff_dd(bd(nn))=dd(bd(nn))-med_del
            del_phase=1
         endif
         benter = where (ecl_start eq bd(nn)+1L,nenter)
         if (nenter eq 1) then begin
            n1=ecl_start(benter(0))
            n2=ecl_end(benter(0))-1L
            med_del=0.d0
            if (n2-n1 ge 2) then med_del=median(dd(n1:n2),/even) 
            diff_dd(bd(nn))=dd(bd(nn))-med_del
            del_phase=1
         endif
      endfor
   endif
endif

if (del_phase) then begin
   if (debug) then begin
      plot,diff_dd
      print,bell
      ans=''
      print,'Removing phase offsets'
      read,ans,prompt='ok? '
      print,''
   endif else ans='Y'
   if (ans eq 'y' or ans eq 'Y') then begin
      dff=running_total(diff_dd)
      del_p(0:*)=del_p(0:*)-dff
      dd=del_p(1:*)-del_p(0:*)
   endif
endif


; store the diff's (new - old) for reinsertion?

diff = del_p - phs_tmp + phs_new

; also make sure median diff is zero

med_diff = median(diff,/even)
diff = diff - med_diff
del_p = del_p - med_diff

; smooth the delta phase (double pass)

if (nsm1 gt 20) then del_p=smooth(del_p,15,/edge_truncate)
del_p_sm=smooth(smooth(del_p,nsm1,/edge_truncate),nsm2,/edge_truncate)

; calculate a new phase from the integrated spin frequency minus the
; smoothed delta, i.e., the smoothed delta gives a drift plus offset
; Note that phs_tmp_tmp is mod 360.

phs_tmp_tmp=phs_tmp-del_p_sm

; add n_spins*2pi to the phase to give monotonic phase
 
n_spins=floor(.5d0+(frq_sm*dt+phs_tmp_tmp(0:*)-phs_tmp_tmp(1:*))/360.)

for nn=1L,n_p-1L do phs_new(nn)=phs_new(nn-1L)+n_spins(nn-1L)*360. + $
phs_tmp_tmp(nn)-phs_tmp_tmp(nn-1L)


; calculate residual between new phase and input phase

phs_tmp=phs_new
phs_new=phs_new mod 360.
del_p = phs_new-phs.y(bfin)
bb=where (del_p gt 180.,nb)
if (nb gt 0) then del_p(bb)=del_p(bb)-360.
bb=where (del_p lt -180.,nb)
if (nb gt 0) then del_p(bb)=del_p(bb)+360.

; regress residual against monotonic phase - to get trend plus offset

a=0.d0
b=0.d0
abdev=0.d0
; add difference if there is a difference offset
if (del_phase) then del_p=del_p + diff
ft = ladfit(phs_tmp,del_p,/double)

; subtract trend and offset

phs_new  = (1.d0-ft(1))*phs_tmp - ft(0)

; put back in long term trends

add_back = smooth(smooth(del_p,nsm4,/edge_truncate),nsm4,/edge_truncate)- $
           smooth(smooth(del_p,nsm1,/edge_truncate),nsm2,/edge_truncate)

phs_new=phs_new + add_back

; difference for new frequency

frq_new=deriv(t_tmp-t_tmp(0),phs_new)
frq_new(0)=(phs_new(1)-phs_new(0))/dt(0)
frq_new(n_p-1)=(phs_new(n_p-1)-phs_new(n_p-2))/dt(n_p-2)

; get phs mod 360

phs_new=phs_new mod 360.
bb = where (phs_new lt 0., nb)
if (nb gt 0) then phs_new(bb)=phs_new(bb)+360.
del_p = phs_new-phs_str
if (del_phase) then del_p = (del_p + diff) mod 360.
bb=where (del_p gt 180.,nb)
if (nb gt 0) then del_p(bb)=del_p(bb)-360.
bb=where (del_p lt -180.,nb)
if (nb gt 0) then del_p(bb)=del_p(bb)+360.

; calculate phase drift

freq_med = median(frq_new)
n_spins = floor(.5d0+(freq_med*(t_tmp(1:*)-t_tmp(0:*))+phs_new(0:*)-phs_new(1:*))/360.d0)
n_p = n_elements(frq_new)
phs_nnn = phs_new
for nn=1L,n_p-1L do phs_nnn(nn)=phs_nnn(nn-1L)+n_spins(nn-1L)*360.d0+phs_new(nn)-phs_new(nn-1L)
del_ppp=.5d0*(frq_new(1:*)+frq_new(0:*))*(t_tmp(1:*)-t_tmp(0:*))
frq_ppp=phs_new
for nn=1L,n_p-1L do frq_ppp(nn)=frq_ppp(nn-1L)+del_ppp(nn-1L)

; check if new frequency and phase are ok, if so return them
; assume ok if no_questions set 

if (no_query eq 0) then begin
   !p.multi=[0,1,4]
   !p.charsize=2.
   plot,frq_new,/ynozero,ytitle='New Freq'
   plot,frq_str-frq_new,ytitle='Delta Freq'
   plot,del_p,ytitle='Delta Phase'
   plot,phs_nnn-frq_ppp,ytitle='Phase Drift'
   !p.multi=0
   !p.charsize=1.

   print,bell

   if (time_error) then print,'Warning - possible UT offset change'
   if (del_phase) then print,'Note - corrected phase offsets - not shown in plot'
   ans = ''
   read, ans, prompt='Are new values reasonable? '
endif else begin
   if (time_error or del_phase) then print,''
   if (time_error) then print,'FIX_UP_SPIN Warning - possible UT offset change'
   if (del_phase) then print,'FIX_UP_SPIN Note - corrected phase offsets'
   if (time_error or del_phase) then print,''
   ans='Y'
endelse

if ans ne 'N' and ans ne 'n' then begin
   frq.y(bfin)=frq_new
   phs.y(bfin)=phs_new
endif else flags=flags + NOT_SMOOTHED

return
end

function get_sun_ra_dec,t_arr

; get the sun position in GEI - based on the algorithm in Russell's
; coordinate transformation paper

; written by R. J. Strangeway, 4/20/98

; make sure time array is a double precision

s=size(t_arr)

if (s(s(0)+1) eq 7) then begin
   times=dblarr(n_elements(t_arr))
   times=str_to_time(t_arr)
endif else times=t_arr

; check times in range - forced by UCB date conversion routines

tlo=str_to_time('1970-01-01/00:00:00')
thi=str_to_time('2059-09-01/00:00:00')

bout=where(times lt tlo or times gt thi,nout)

if (nout ne 0) then begin
    print,''
    print,'Times out of range in GET_SUN_RA_DEC'
    print,''
    return,0
endif

dtor = !dpi/180.d0

fday = (times mod 86400.d0)/86400.d0
dj = times/86400.d0 + julday(1,1,1970) - julday(1,1,1900) + .5d0
t=dj/36525.d0
vl = (279.696678d0 + 0.9856473354d0*dj) mod 360.d0
gst = (279.690983d0 + 0.9856473354d0*dj + 360.d0*fday + 180.d0) mod 360.d0
g = ((358.475845d0 + 0.985600267d0*dj) mod 360.d0)*dtor
slong = vl + (1.91946d0 - 0.004789d0*t)*sin(g) + 0.020094d0*sin(2.d0*g)
obliq = (23.45229d0 - 0.0130125d0*t)*dtor
slp = (slong - 0.005686)*dtor
sind = sin(obliq)*sin(slp)
cosd = sqrt(1.d0-sind*sind)
sdec = atan(sind/cosd)/dtor
srasn = 180.d0 - atan((1.d0/tan(obliq))*sind/cosd, -cos(slp)/cosd)/dtor

return,{time:times,gst:gst,long:slong,ra:srasn,dec:sdec}

end

function interpolate_matrix,mat,mag

; interpolate the coefficients of a rotation matrix

mat_new = dblarr(n_elements(mag.x),3,3)

for j = 0, 2  do begin
  for i = 0, 2 do begin
    y2 = spl_init(mat.x-mat.x(0),reform(mat.y(*,i,j)),/double)
    mat_new(*,i,j) = spl_interp(mat.x-mat.x(0),reform(mat.y(*,i,j)),y2,mag.x-mat.x(0),/double)
   endfor
endfor

return,{x:mag.x,y:mat_new}
end

function interpolate_phase,phs,frq,mag

; put back in two-pi steps, interpolate phase and remove two-pi

; remember phase is actually in degrees

; add two-pi back in

; forces time series monotonic (assumes that both phs and frq have the 
; same time tags

bfin=where (finite(frq.y) and finite(phs.y),nfin)
bsort = sort(phs.x(bfin)-phs.x(bfin(0)))
phs_x=phs.x(bfin(bsort))
phs_y=phs.y(bfin(bsort))
frq_x=frq.x(bfin(bsort))
frq_y=frq.y(bfin(bsort))
n_l = n_elements(phs_y)
phs_l=dblarr(n_l)

phs_l(0) = phs_y(0)

for n = 1L, n_l-1L do begin
  n_spins = round((frq_x(n)-frq_x(n-1L))*(frq_y(n)+frq_y(n-1L))/720.d0)
  dphi = phs_y(n) - phs_y(n-1L)
  if (dphi lt -180.) then dphi = dphi + 360.d0
  if (dphi gt  180.) then dphi = dphi - 360.d0
  phs_l(n) = phs_l(n-1L) + n_spins*360.d0 + dphi
endfor

; interpolate and mod two-pi

bsort = sort(mag.x-phs_x(0))
y2 = spl_init(phs_x-phs_x(0),phs_l,/double)
phs_new = spl_interp(phs_x-phs_x(0),phs_l,y2,mag.x(bsort)-phs_x(0),/double)
phs_new = phs_new mod 360.d0
bc = where (phs_new lt 0., nb)
if (nb gt 0) then phs_new(bc) = phs_new(bc)+360.d0

return,{x:mag.x(bsort),y:phs_new}
end

function vector_cross_product,v1,v2

; get the cross product, assume vectors are stored (*,3)

n=n_elements(reform(v1(*,0)))
vv = dblarr(n,3)

vv(*,0) = v1(*,1)*v2(*,2) - v1(*,2)*v2(*,1)
vv(*,1) = v1(*,2)*v2(*,0) - v1(*,0)*v2(*,2)
vv(*,2) = v1(*,0)*v2(*,1) - v1(*,1)*v2(*,0)

return, vv

end

function vector_dot_product,v1,v2

; get the dot product, assume vectors are stored (*,3)

return, v1(*,0)*v2(*,0) + v1(*,1)*v2(*,1) + v1(*,2)*v2(*,2)

end

function set_dipole_orient,req_epoch

; set up the dipole orientation using IGRF at requested epoch

; currently only for single time, and further time is a double
; referenced to 1/1/1970 (IDL reference time)

igrf_dip={ $
epoch:[    1945.d0,    1950.d0,    1955.d0,    1960.d0,    1965.d0, $
           1970.d0,    1975.d0,    1980.d0,    1985.d0,    1990.d0, $
           1995.d0,    2000.d0], $
g10:  [  -30594.d0,  -30554.d0,  -30500.d0,  -30421.d0,  -30334.d0, $
         -30220.d0,  -30100.d0,  -29992.d0,  -29873.d0,  -29775.d0, $
         -29682.d0,     17.6d0], $
g11:  [   -2285.d0,   -2250.d0,   -2215.d0,   -2169.d0,   -2119.d0, $
          -2068.d0,   -2013.d0,   -1956.d0,   -1905.d0,   -1848.d0, $
          -1789.d0,     13.0d0], $
h11:  [    5810.d0,    5815.d0,    5820.d0,    5791.d0,    5776.d0, $
           5737.d0,    5675.d0,    5604.d0,    5500.d0,    5406.d0, $
           5318.d0,    -18.3d0] } 


times=round(igrf_dip.epoch)
ntimes=n_elements(times)-1
for n = 0,ntimes do igrf_dip.epoch(n) = (julday(1,1,times(n))-julday(1,1,1970))*86400.d0

; assume that last entry is secular variation - make sure this is always the case

if (req_epoch gt igrf_dip.epoch(ntimes-1)) then begin

;  extrapolate

   rate = 5.d0*(req_epoch-igrf_dip.epoch(ntimes-1))/ $
          (igrf_dip.epoch(ntimes)-igrf_dip.epoch(ntimes-1))

   g10 = igrf_dip.g10(ntimes-1)+rate*igrf_dip.g10(ntimes)
   g11 = igrf_dip.g11(ntimes-1)+rate*igrf_dip.g11(ntimes)
   h11 = igrf_dip.h11(ntimes-1)+rate*igrf_dip.h11(ntimes)

endif else begin

;  interpolate

   g10 = interpol(igrf_dip.g10,igrf_dip.epoch-req_epoch,0.d0)
   g11 = interpol(igrf_dip.g11,igrf_dip.epoch-req_epoch,0.d0)
   h11 = interpol(igrf_dip.h11,igrf_dip.epoch-req_epoch,0.d0)

endelse

lat   = asin(-g10/sqrt(g10^2+g11^2+h11^2))
lng  = atan(-h11, -g11)
 
x = cos(lat)*cos(lng)
y = cos(lat)*sin(lng)
z = sin(lat)

return,{lat:lat*180.d0/!dpi,lng:lng*180.d0/!dpi,x:x,y:y,z:z}

end

function transform_vector,trans,in_vec,inverse=inverse

; perform a coordinate transformation of a vector
; input should conform to the following conventions - there is only 
; minimal error checking
;
; trans - input transformation dimensions [n,3,3]
; in_vec - input vector, dimensions [n,3]
;
; it is assumed that trans is a from_to transformation, set flag inverse
; for inverse

n_arr = n_elements(trans(*,0,0))
n_vec = n_elements(in_vec(*,0))
if (n_vec ne n_arr) then begin
   print,string("07b)
   print,'TRANSFORM_VECTOR - dimension mismatch'
   print,''
   return,0
endif

if (keyword_set(inverse)) then begin

   out_vec=in_vec
   out_vec(*,0)=trans(*,0,0)*in_vec(*,0)+trans(*,1,0)*in_vec(*,1)+trans(*,2,0)*in_vec(*,2)
   out_vec(*,1)=trans(*,0,1)*in_vec(*,0)+trans(*,1,1)*in_vec(*,1)+trans(*,2,1)*in_vec(*,2)
   out_vec(*,2)=trans(*,0,2)*in_vec(*,0)+trans(*,1,2)*in_vec(*,1)+trans(*,2,2)*in_vec(*,2)

endif else begin

   out_vec=in_vec
   out_vec(*,0)=trans(*,0,0)*in_vec(*,0)+trans(*,0,1)*in_vec(*,1)+trans(*,0,2)*in_vec(*,2)
   out_vec(*,1)=trans(*,1,0)*in_vec(*,0)+trans(*,1,1)*in_vec(*,1)+trans(*,1,2)*in_vec(*,2)
   out_vec(*,2)=trans(*,2,0)*in_vec(*,0)+trans(*,2,1)*in_vec(*,1)+trans(*,2,2)*in_vec(*,2)

endelse

return,out_vec

end

function set_igrf_coefficients

; set up a structure containing the IGRF coefficients

; dgrf45

n_coeffs=10
n_arr = ((n_coeffs+3)*n_coeffs)/2
g_arr=dblarr(n_arr)
h_arr=dblarr(n_arr)
g_arr=[     -30594.d0, -2285.d0, -1244.d0,  2990.d0,  1578.d0, $
              1282.d0, -1834.d0,  1255.d0,   913.d0,   944.d0, $
               776.d0,   544.d0,  -421.d0,   304.d0,  -253.d0, $
               346.d0,   194.d0,   -20.d0,  -142.d0,   -82.d0, $
                59.d0,    57.d0,     6.d0,  -246.d0,   -25.d0, $
                21.d0,  -104.d0,    70.d0,   -40.d0,     0.d0, $
                 0.d0,   -29.d0,   -10.d0,    15.d0,    29.d0, $
                13.d0,     7.d0,    -8.d0,    -5.d0,     9.d0, $
                 7.d0,   -10.d0,     7.d0,     2.d0,     5.d0, $
               -21.d0,     1.d0,   -11.d0,     3.d0,    16.d0, $
                -3.d0,    -4.d0,    -3.d0,    -4.d0,    -3.d0, $
                11.d0,     1.d0,     2.d0,    -5.d0,    -1.d0, $
                 8.d0,    -1.d0,    -3.d0,     5.d0,    -2.d0  ]

h_arr=[          0.d0,  5810.d0,     0.d0, -1702.d0,   477.d0, $
                 0.d0,  -499.d0,   186.d0,   -11.d0,     0.d0, $
               144.d0,  -276.d0,   -55.d0,  -178.d0,     0.d0, $
               -12.d0,    95.d0,   -67.d0,  -119.d0,    82.d0, $
                 0.d0,     6.d0,   100.d0,    16.d0,    -9.d0, $
               -16.d0,   -39.d0,     0.d0,   -45.d0,   -18.d0, $
                 2.d0,     6.d0,    28.d0,   -17.d0,   -22.d0, $
                 0.d0,    12.d0,   -21.d0,   -12.d0,    -7.d0, $
                 2.d0,    18.d0,     3.d0,   -11.d0,     0.d0, $
               -27.d0,    17.d0,    29.d0,    -9.d0,     4.d0, $
                 9.d0,     6.d0,     1.d0,     8.d0,     0.d0, $
                 5.d0,     1.d0,   -20.d0,    -1.d0,    -6.d0, $
                 6.d0,    -4.d0,    -2.d0,     0.d0,    -2.d0  ]

dgrf45={epoch:1945.d0,earth_rad:6371.2d0,n_coeffs:10,gs:g_arr,hs:h_arr}

; dgrf50

g_arr= [    -30554.d0, -2250.d0, -1341.d0,  2998.d0,  1576.d0, $
              1297.d0, -1889.d0,  1274.d0,   896.d0,   954.d0, $
               792.d0,   528.d0,  -408.d0,   303.d0,  -240.d0, $
               349.d0,   211.d0,   -20.d0,  -147.d0,   -76.d0, $
                54.d0,    57.d0,     4.d0,  -247.d0,   -16.d0, $
                12.d0,  -105.d0,    65.d0,   -55.d0,     2.d0, $
                 1.d0,   -40.d0,    -7.d0,     5.d0,    19.d0, $
                22.d0,    15.d0,    -4.d0,    -1.d0,    11.d0, $
                15.d0,   -13.d0,     5.d0,    -1.d0,     3.d0, $
                -7.d0,    -1.d0,   -25.d0,    10.d0,     5.d0, $
                -5.d0,    -2.d0,     3.d0,     8.d0,    -8.d0, $
                 4.d0,    -1.d0,    13.d0,    -4.d0,     4.d0, $
                12.d0,     3.d0,     2.d0,    10.d0,     3.d0  ]

h_arr=[          0.d0,  5815.d0,     0.d0, -1810.d0,   381.d0, $
                 0.d0,  -476.d0,   206.d0,   -46.d0,     0.d0, $
               136.d0,  -278.d0,   -37.d0,  -210.d0,     0.d0, $
                 3.d0,   103.d0,   -87.d0,  -122.d0,    80.d0, $
                 0.d0,    -1.d0,    99.d0,    33.d0,   -12.d0, $
               -12.d0,   -30.d0,     0.d0,   -35.d0,   -17.d0, $
                 0.d0,    10.d0,    36.d0,   -18.d0,   -16.d0, $
                 0.d0,     5.d0,   -22.d0,     0.d0,   -21.d0, $
                -8.d0,    17.d0,    -4.d0,   -17.d0,     0.d0, $
               -24.d0,    19.d0,    12.d0,     2.d0,     2.d0, $
                 8.d0,     8.d0,   -11.d0,    -7.d0,     0.d0, $
                13.d0,    -2.d0,   -10.d0,     2.d0,    -3.d0, $
                 6.d0,    -3.d0,     6.d0,    11.d0,     8.d0  ]

dgrf50={epoch:1950.d0,earth_rad:6371.2d0,n_coeffs:10,gs:g_arr,hs:h_arr}

; dgrf55

g_arr=[     -30500.d0, -2215.d0, -1440.d0,  3003.d0,  1581.d0, $
              1302.d0, -1944.d0,  1288.d0,   882.d0,   958.d0, $
               796.d0,   510.d0,  -397.d0,   290.d0,  -229.d0, $
               360.d0,   230.d0,   -23.d0,  -152.d0,   -69.d0, $
                47.d0,    57.d0,     3.d0,  -247.d0,    -8.d0, $
                 7.d0,  -107.d0,    65.d0,   -56.d0,     2.d0, $
                10.d0,   -32.d0,   -11.d0,     9.d0,    18.d0, $
                11.d0,     9.d0,    -6.d0,   -14.d0,     6.d0, $
                10.d0,    -7.d0,     6.d0,     9.d0,     4.d0, $
                 9.d0,    -4.d0,    -5.d0,     2.d0,     4.d0, $
                 1.d0,     2.d0,     2.d0,     5.d0,    -3.d0, $
                -5.d0,    -1.d0,     2.d0,    -3.d0,     7.d0, $
                 4.d0,    -2.d0,     6.d0,    -2.d0,     0.d0  ]

h_arr=[          0.d0,  5820.d0,     0.d0, -1898.d0,   291.d0, $
                 0.d0,  -462.d0,   216.d0,   -83.d0,     0.d0, $
               133.d0,  -274.d0,   -23.d0,  -230.d0,     0.d0, $
                15.d0,   110.d0,   -98.d0,  -121.d0,    78.d0, $
                 0.d0,    -9.d0,    96.d0,    48.d0,   -16.d0, $
               -12.d0,   -24.d0,     0.d0,   -50.d0,   -24.d0, $
                -4.d0,     8.d0,    28.d0,   -20.d0,   -18.d0, $
                 0.d0,    10.d0,   -15.d0,     5.d0,   -23.d0, $
                 3.d0,    23.d0,    -4.d0,   -13.d0,     0.d0, $
               -11.d0,    12.d0,     7.d0,     6.d0,    -2.d0, $
                10.d0,     7.d0,    -6.d0,     5.d0,     0.d0, $
                -4.d0,     0.d0,    -8.d0,    -2.d0,    -4.d0, $
                 1.d0,    -3.d0,     7.d0,    -1.d0,    -3.d0  ]

dgrf55={epoch:1955.d0,earth_rad:6371.2d0,n_coeffs:10,gs:g_arr,hs:h_arr}

; dgrf60

g_arr=[     -30421.d0, -2169.d0, -1555.d0,  3002.d0,  1590.d0, $
              1302.d0, -1992.d0,  1289.d0,   878.d0,   957.d0, $
               800.d0,   504.d0,  -394.d0,   269.d0,  -222.d0, $
               362.d0,   242.d0,   -26.d0,  -156.d0,   -63.d0, $
                46.d0,    58.d0,     1.d0,  -237.d0,    -1.d0, $
                -2.d0,  -113.d0,    67.d0,   -56.d0,     5.d0, $
                15.d0,   -32.d0,    -7.d0,    17.d0,     8.d0, $
                15.d0,     6.d0,    -4.d0,   -11.d0,     2.d0, $
                10.d0,    -5.d0,    10.d0,     8.d0,     4.d0, $
                 6.d0,     0.d0,    -9.d0,     1.d0,     4.d0, $
                -1.d0,    -2.d0,     3.d0,    -1.d0,     1.d0, $
                -3.d0,     4.d0,     0.d0,    -1.d0,     4.d0, $
                 6.d0,     1.d0,    -1.d0,     2.d0,     0.d0  ]

h_arr=[          0.d0,  5791.d0,     0.d0, -1967.d0,   206.d0, $
                 0.d0,  -414.d0,   224.d0,  -130.d0,     0.d0, $
               135.d0,  -278.d0,     3.d0,  -255.d0,     0.d0, $
                16.d0,   125.d0,  -117.d0,  -114.d0,    81.d0, $
                 0.d0,   -10.d0,    99.d0,    60.d0,   -20.d0, $
               -11.d0,   -17.d0,     0.d0,   -55.d0,   -28.d0, $
                -6.d0,     7.d0,    23.d0,   -18.d0,   -17.d0, $
                 0.d0,    11.d0,   -14.d0,     7.d0,   -18.d0, $
                 4.d0,    23.d0,     1.d0,   -20.d0,     0.d0, $
               -18.d0,    12.d0,     2.d0,     0.d0,    -3.d0, $
                 9.d0,     8.d0,     0.d0,     5.d0,     0.d0, $
                 4.d0,     1.d0,     0.d0,     2.d0,    -5.d0, $
                 1.d0,    -1.d0,     6.d0,     0.d0,    -7.d0  ]

dgrf60={epoch:1960.d0,earth_rad:6371.2d0,n_coeffs:10,gs:g_arr,hs:h_arr}

; dgrf65

g_arr=[     -30334.d0, -2119.d0, -1662.d0,  2997.d0,  1594.d0, $
              1297.d0, -2038.d0,  1292.d0,   856.d0,   957.d0, $
               804.d0,   479.d0,  -390.d0,   252.d0,  -219.d0, $
               358.d0,   254.d0,   -31.d0,  -157.d0,   -62.d0, $
                45.d0,    61.d0,     8.d0,  -228.d0,     4.d0, $
                 1.d0,  -111.d0,    75.d0,   -57.d0,     4.d0, $
                13.d0,   -26.d0,    -6.d0,    13.d0,     1.d0, $
                13.d0,     5.d0,    -4.d0,   -14.d0,     0.d0, $
                 8.d0,    -1.d0,    11.d0,     4.d0,     8.d0, $
                10.d0,     2.d0,   -13.d0,    10.d0,    -1.d0, $
                -1.d0,     5.d0,     1.d0,    -2.d0,    -2.d0, $
                -3.d0,     2.d0,    -5.d0,    -2.d0,     4.d0, $
                 4.d0,     0.d0,     2.d0,     2.d0,     0.d0  ]

h_arr=[          0.d0,  5776.d0,     0.d0, -2016.d0,   114.d0, $
                 0.d0,  -404.d0,   240.d0,  -165.d0,     0.d0, $
               148.d0,  -269.d0,    13.d0,  -269.d0,     0.d0, $
                19.d0,   128.d0,  -126.d0,   -97.d0,    81.d0, $
                 0.d0,   -11.d0,   100.d0,    68.d0,   -32.d0, $
                -8.d0,    -7.d0,     0.d0,   -61.d0,   -27.d0, $
                -2.d0,     6.d0,    26.d0,   -23.d0,   -12.d0, $
                 0.d0,     7.d0,   -12.d0,     9.d0,   -16.d0, $
                 4.d0,    24.d0,    -3.d0,   -17.d0,     0.d0, $
               -22.d0,    15.d0,     7.d0,    -4.d0,    -5.d0, $
                10.d0,    10.d0,    -4.d0,     1.d0,     0.d0, $
                 2.d0,     1.d0,     2.d0,     6.d0,    -4.d0, $
                 0.d0,    -2.d0,     3.d0,     0.d0,    -6.d0  ]

dgrf65={epoch:1965.d0,earth_rad:6371.2d0,n_coeffs:10,gs:g_arr,hs:h_arr}

; dgrf70

g_arr=[     -30220.d0, -2068.d0, -1781.d0,  3000.d0,  1611.d0, $
              1287.d0, -2091.d0,  1278.d0,   838.d0,   952.d0, $
               800.d0,   461.d0,  -395.d0,   234.d0,  -216.d0, $
               359.d0,   262.d0,   -42.d0,  -160.d0,   -56.d0, $
                43.d0,    64.d0,    15.d0,  -212.d0,     2.d0, $
                 3.d0,  -112.d0,    72.d0,   -57.d0,     1.d0, $
                14.d0,   -22.d0,    -2.d0,    13.d0,    -2.d0, $
                14.d0,     6.d0,    -2.d0,   -13.d0,    -3.d0, $
                 5.d0,     0.d0,    11.d0,     3.d0,     8.d0, $
                10.d0,     2.d0,   -12.d0,    10.d0,    -1.d0, $
                 0.d0,     3.d0,     1.d0,    -1.d0,    -3.d0, $
                -3.d0,     2.d0,    -5.d0,    -1.d0,     6.d0, $
                 4.d0,     1.d0,     0.d0,     3.d0,    -1.d0  ]

h_arr=[          0.d0,  5737.d0,     0.d0, -2047.d0,    25.d0, $
                 0.d0,  -366.d0,   251.d0,  -196.d0,     0.d0, $
               167.d0,  -266.d0,    26.d0,  -279.d0,     0.d0, $
                26.d0,   139.d0,  -139.d0,   -91.d0,    83.d0, $
                 0.d0,   -12.d0,   100.d0,    72.d0,   -37.d0, $
                -6.d0,     1.d0,     0.d0,   -70.d0,   -27.d0, $
                -4.d0,     8.d0,    23.d0,   -23.d0,   -11.d0, $
                 0.d0,     7.d0,   -15.d0,     6.d0,   -17.d0, $
                 6.d0,    21.d0,    -6.d0,   -16.d0,     0.d0, $
               -21.d0,    16.d0,     6.d0,    -4.d0,    -5.d0, $
                10.d0,    11.d0,    -2.d0,     1.d0,     0.d0, $
                 1.d0,     1.d0,     3.d0,     4.d0,    -4.d0, $
                 0.d0,    -1.d0,     3.d0,     1.d0,    -4.d0  ]

dgrf70={epoch:1970.d0,earth_rad:6371.2d0,n_coeffs:10,gs:g_arr,hs:h_arr}

; dgrf75

g_arr=[     -30100.d0, -2013.d0, -1902.d0,  3010.d0,  1632.d0, $
              1276.d0, -2144.d0,  1260.d0,   830.d0,   946.d0, $
               791.d0,   438.d0,  -405.d0,   216.d0,  -218.d0, $
               356.d0,   264.d0,   -59.d0,  -159.d0,   -49.d0, $
                45.d0,    66.d0,    28.d0,  -198.d0,     1.d0, $
                 6.d0,  -111.d0,    71.d0,   -56.d0,     1.d0, $
                16.d0,   -14.d0,     0.d0,    12.d0,    -5.d0, $
                14.d0,     6.d0,    -1.d0,   -12.d0,    -8.d0, $
                 4.d0,     0.d0,    10.d0,     1.d0,     7.d0, $
                10.d0,     2.d0,   -12.d0,    10.d0,    -1.d0, $
                -1.d0,     4.d0,     1.d0,    -2.d0,    -3.d0, $
                -3.d0,     2.d0,    -5.d0,    -2.d0,     5.d0, $
                 4.d0,     1.d0,     0.d0,     3.d0,    -1.d0  ]

h_arr=[          0.d0,  5675.d0,     0.d0, -2067.d0,   -68.d0, $
                 0.d0,  -333.d0,   262.d0,  -223.d0,     0.d0, $
               191.d0,  -265.d0,    39.d0,  -288.d0,     0.d0, $
                31.d0,   148.d0,  -152.d0,   -83.d0,    88.d0, $
                 0.d0,   -13.d0,    99.d0,    75.d0,   -41.d0, $
                -4.d0,    11.d0,     0.d0,   -77.d0,   -26.d0, $
                -5.d0,    10.d0,    22.d0,   -23.d0,   -12.d0, $
                 0.d0,     6.d0,   -16.d0,     4.d0,   -19.d0, $
                 6.d0,    18.d0,   -10.d0,   -17.d0,     0.d0, $
               -21.d0,    16.d0,     7.d0,    -4.d0,    -5.d0, $
                10.d0,    11.d0,    -3.d0,     1.d0,     0.d0, $
                 1.d0,     1.d0,     3.d0,     4.d0,    -4.d0, $
                -1.d0,    -1.d0,     3.d0,     1.d0,    -5.d0  ]

dgrf75={epoch:1975.d0,earth_rad:6371.2d0,n_coeffs:10,gs:g_arr,hs:h_arr}

; dgrf80

g_arr=[     -29992.d0, -1956.d0, -1997.d0,  3027.d0,  1663.d0, $
              1281.d0, -2180.d0,  1251.d0,   833.d0,   938.d0, $
               782.d0,   398.d0,  -419.d0,   199.d0,  -218.d0, $
               357.d0,   261.d0,   -74.d0,  -162.d0,   -48.d0, $
                48.d0,    66.d0,    42.d0,  -192.d0,     4.d0, $
                14.d0,  -108.d0,    72.d0,   -59.d0,     2.d0, $
                21.d0,   -12.d0,     1.d0,    11.d0,    -2.d0, $
                18.d0,     6.d0,     0.d0,   -11.d0,    -7.d0, $
                 4.d0,     3.d0,     6.d0,    -1.d0,     5.d0, $
                10.d0,     1.d0,   -12.d0,     9.d0,    -3.d0, $
                -1.d0,     7.d0,     2.d0,    -5.d0,    -4.d0, $
                -4.d0,     2.d0,    -5.d0,    -2.d0,     5.d0, $
                 3.d0,     1.d0,     2.d0,     3.d0,     0.d0  ]

h_arr=[          0.d0,  5604.d0,     0.d0, -2129.d0,  -200.d0, $
                 0.d0,  -336.d0,   271.d0,  -252.d0,     0.d0, $
               212.d0,  -257.d0,    53.d0,  -297.d0,     0.d0, $
                46.d0,   150.d0,  -151.d0,   -78.d0,    92.d0, $
                 0.d0,   -15.d0,    93.d0,    71.d0,   -43.d0, $
                -2.d0,    17.d0,     0.d0,   -82.d0,   -27.d0, $
                -5.d0,    16.d0,    18.d0,   -23.d0,   -10.d0, $
                 0.d0,     7.d0,   -18.d0,     4.d0,   -22.d0, $
                 9.d0,    16.d0,   -13.d0,   -15.d0,     0.d0, $
               -21.d0,    16.d0,     9.d0,    -5.d0,    -6.d0, $
                 9.d0,    10.d0,    -6.d0,     2.d0,     0.d0, $
                 1.d0,     0.d0,     3.d0,     6.d0,    -4.d0, $
                 0.d0,    -1.d0,     4.d0,     0.d0,    -6.d0  ]

dgrf80={epoch:1980.d0,earth_rad:6371.2d0,n_coeffs:10,gs:g_arr,hs:h_arr}

; dgrf85

g_arr=[     -29873.d0, -1905.d0, -2072.d0,  3044.d0,  1687.d0, $
              1296.d0, -2208.d0,  1247.d0,   829.d0,   936.d0, $
               780.d0,   361.d0,  -424.d0,   170.d0,  -214.d0, $
               355.d0,   253.d0,   -93.d0,  -164.d0,   -46.d0, $
                53.d0,    65.d0,    51.d0,  -185.d0,     4.d0, $
                16.d0,  -102.d0,    74.d0,   -62.d0,     3.d0, $
                24.d0,    -6.d0,     4.d0,    10.d0,     0.d0, $
                21.d0,     6.d0,     0.d0,   -11.d0,    -9.d0, $
                 4.d0,     4.d0,     4.d0,    -4.d0,     5.d0, $
                10.d0,     1.d0,   -12.d0,     9.d0,    -3.d0, $
                -1.d0,     7.d0,     1.d0,    -5.d0,    -4.d0, $
                -4.d0,     3.d0,    -5.d0,    -2.d0,     5.d0, $
                 3.d0,     1.d0,     2.d0,     3.d0,     0.d0  ]

h_arr=[          0.d0,  5500.d0,     0.d0, -2197.d0,  -306.d0, $
                 0.d0,  -310.d0,   284.d0,  -297.d0,     0.d0, $
               232.d0,  -249.d0,    69.d0,  -297.d0,     0.d0, $
                47.d0,   150.d0,  -154.d0,   -75.d0,    95.d0, $
                 0.d0,   -16.d0,    88.d0,    69.d0,   -48.d0, $
                -1.d0,    21.d0,     0.d0,   -83.d0,   -27.d0, $
                -2.d0,    20.d0,    17.d0,   -23.d0,    -7.d0, $
                 0.d0,     8.d0,   -19.d0,     5.d0,   -23.d0, $
                11.d0,    14.d0,   -15.d0,   -11.d0,     0.d0, $
               -21.d0,    15.d0,     9.d0,    -6.d0,    -6.d0, $
                 9.d0,     9.d0,    -7.d0,     2.d0,     0.d0, $
                 1.d0,     0.d0,     3.d0,     6.d0,    -4.d0, $
                 0.d0,    -1.d0,     4.d0,     0.d0,    -6.d0  ]

dgrf85={epoch:1985.d0,earth_rad:6371.2d0,n_coeffs:10,gs:g_arr,hs:h_arr}

; dgrf90

g_arr=[     -29775.d0, -1848.d0, -2131.d0,  3059.d0,  1686.d0, $
              1314.d0, -2239.d0,  1248.d0,   802.d0,   939.d0, $
               780.d0,   325.d0,  -423.d0,   141.d0,  -214.d0, $
               353.d0,   245.d0,  -109.d0,  -165.d0,   -36.d0, $
                61.d0,    65.d0,    59.d0,  -178.d0,     3.d0, $
                18.d0,   -96.d0,    77.d0,   -64.d0,     2.d0, $
                26.d0,    -1.d0,     5.d0,     9.d0,     0.d0, $
                23.d0,     5.d0,    -1.d0,   -10.d0,   -12.d0, $
                 3.d0,     4.d0,     2.d0,    -6.d0,     4.d0, $
                 9.d0,     1.d0,   -12.d0,     9.d0,    -4.d0, $
                -2.d0,     7.d0,     1.d0,    -6.d0,    -3.d0, $
                -4.d0,     2.d0,    -5.d0,    -2.d0,     4.d0, $
                 3.d0,     1.d0,     3.d0,     3.d0,     0.d0  ]

h_arr=[          0.d0,  5406.d0,     0.d0, -2279.d0,  -373.d0, $
                 0.d0,  -284.d0,   293.d0,  -352.d0,     0.d0, $
               247.d0,  -240.d0,    84.d0,  -299.d0,     0.d0, $
                46.d0,   154.d0,  -153.d0,   -69.d0,    97.d0, $
                 0.d0,   -16.d0,    82.d0,    69.d0,   -52.d0, $
                 1.d0,    24.d0,     0.d0,   -80.d0,   -26.d0, $
                 0.d0,    21.d0,    17.d0,   -23.d0,    -4.d0, $
                 0.d0,    10.d0,   -19.d0,     6.d0,   -22.d0, $
                12.d0,    12.d0,   -16.d0,   -10.d0,     0.d0, $
               -20.d0,    15.d0,    11.d0,    -7.d0,    -7.d0, $
                 9.d0,     8.d0,    -7.d0,     2.d0,     0.d0, $
                 2.d0,     1.d0,     3.d0,     6.d0,    -4.d0, $
                 0.d0,    -2.d0,     3.d0,    -1.d0,    -6.d0  ]

dgrf90={epoch:1990.d0,earth_rad:6371.2d0,n_coeffs:10,gs:g_arr,hs:h_arr}

; igrf95

g_arr=[     -29682.d0, -1789.d0, -2197.d0,  3074.d0,  1685.d0, $
              1329.d0, -2268.d0,  1249.d0,   769.d0,   941.d0, $
               782.d0,   291.d0,  -421.d0,   116.d0,  -210.d0, $
               352.d0,   237.d0,  -122.d0,  -167.d0,   -26.d0, $
                66.d0,    64.d0,    65.d0,  -172.d0,     2.d0, $
                17.d0,   -94.d0,    78.d0,   -67.d0,     1.d0, $
                29.d0,     4.d0,     8.d0,    10.d0,    -2.d0, $
                24.d0,     4.d0,    -1.d0,    -9.d0,   -14.d0, $
                 4.d0,     5.d0,     0.d0,    -7.d0,     4.d0, $
                 9.d0,     1.d0,   -12.d0,     9.d0,    -4.d0, $
                -2.d0,     7.d0,     0.d0,    -6.d0,    -3.d0, $
                -4.d0,     2.d0,    -5.d0,    -2.d0,     4.d0, $
                 3.d0,     1.d0,     3.d0,     3.d0,     0.d0  ]

h_arr=[          0.d0,  5318.d0,     0.d0, -2356.d0,  -425.d0, $
                 0.d0,  -263.d0,   302.d0,  -406.d0,     0.d0, $
               262.d0,  -232.d0,    98.d0,  -301.d0,     0.d0, $
                44.d0,   157.d0,  -152.d0,   -64.d0,    99.d0, $
                 0.d0,   -16.d0,    77.d0,    67.d0,   -57.d0, $
                 4.d0,    28.d0,    -0.d0,   -77.d0,   -25.d0, $
                 3.d0,    22.d0,    16.d0,   -23.d0,    -3.d0, $
                 0.d0,    12.d0,   -20.d0,     7.d0,   -21.d0, $
                12.d0,    10.d0,   -17.d0,   -10.d0,     0.d0, $
               -19.d0,    15.d0,    11.d0,    -7.d0,    -7.d0, $
                 9.d0,     7.d0,    -8.d0,     1.d0,     0.d0, $
                 2.d0,     1.d0,     3.d0,     6.d0,    -4.d0, $
                 0.d0,    -2.d0,     3.d0,    -1.d0,    -6.d0  ]

igrf95={epoch:1995.d0,earth_rad:6371.2d0,n_coeffs:10,gs:g_arr,hs:h_arr}

; igrf95s

g_arr=[        17.6d0,   13.0d0,  -13.2d0,    3.7d0,   -0.8d0, $
                1.5d0,   -6.4d0,   -0.2d0,   -8.1d0,    0.8d0, $
                0.9d0,   -6.9d0,    0.5d0,   -4.6d0,    0.8d0, $
                0.1d0,   -1.5d0,   -2.0d0,   -0.1d0,    2.3d0, $
                0.5d0,   -0.4d0,    0.6d0,    1.9d0,   -0.2d0, $
               -0.2d0,    0.0d0,   -0.2d0,   -0.8d0,   -0.6d0, $
                0.6d0,    1.2d0,    0.1d0,    0.2d0,   -0.6d0, $
                0.3d0,   -0.2d0,    0.1d0,    0.4d0,   -1.1d0, $
                0.3d0,    0.2d0,   -0.9d0,   -0.3d0,    0.0d0, $
                0.0d0,    0.0d0,    0.0d0,    0.0d0,    0.0d0, $
                0.0d0,    0.0d0,    0.0d0,    0.0d0,    0.0d0, $
                0.0d0,    0.0d0,    0.0d0,    0.0d0,    0.0d0, $
                0.0d0,    0.0d0,    0.0d0,    0.0d0,    0.0d0  ]

h_arr=[         0.0d0,  -18.3d0,    0.0d0,  -15.0d0,   -8.8d0, $
                0.0d0,    4.1d0,    2.2d0,  -12.1d0,    0.0d0, $
                1.8d0,    1.2d0,    2.7d0,   -1.0d0,    0.0d0, $
                0.2d0,    1.2d0,    0.3d0,    1.8d0,    0.9d0, $
                0.0d0,    0.3d0,   -1.6d0,   -0.2d0,   -0.9d0, $
                1.0d0,    2.2d0,    0.0d0,    0.8d0,    0.2d0, $
                0.6d0,   -0.4d0,    0.0d0,   -0.3d0,    0.0d0, $
                0.0d0,    0.4d0,   -0.2d0,    0.2d0,    0.7d0, $
                0.0d0,   -1.2d0,   -0.7d0,   -0.6d0,    0.0d0, $
                0.0d0,    0.0d0,    0.0d0,    0.0d0,    0.0d0, $
                0.0d0,    0.0d0,    0.0d0,    0.0d0,    0.0d0, $
                0.0d0,    0.0d0,    0.0d0,    0.0d0,    0.0d0, $
                0.0d0,    0.0d0,    0.0d0,    0.0d0,    0.0d0  ]

igrf95s={epoch:2000.d0,earth_rad:6371.2d0,n_coeffs:8,gs:g_arr,hs:h_arr}

epoch=[dgrf45.epoch,dgrf50.epoch,dgrf55.epoch,dgrf60.epoch, $
       dgrf65.epoch,dgrf70.epoch,dgrf75.epoch,dgrf80.epoch, $
       dgrf85.epoch,dgrf90.epoch,igrf95.epoch,igrf95s.epoch]

earth=[dgrf45.earth_rad,dgrf50.earth_rad,dgrf55.earth_rad,dgrf60.earth_rad, $
       dgrf65.earth_rad,dgrf70.earth_rad,dgrf75.earth_rad,dgrf80.earth_rad, $
       dgrf85.earth_rad,dgrf90.earth_rad,igrf95.earth_rad,igrf95s.earth_rad]

n_coef=[dgrf45.n_coeffs,dgrf50.n_coeffs,dgrf55.n_coeffs,dgrf60.n_coeffs, $
        dgrf65.n_coeffs,dgrf70.n_coeffs,dgrf75.n_coeffs,dgrf80.n_coeffs, $
        dgrf85.n_coeffs,dgrf90.n_coeffs,igrf95.n_coeffs,igrf95s.n_coeffs]

gs=transpose([[dgrf45.gs],[dgrf50.gs],[dgrf55.gs],[dgrf60.gs], $
              [dgrf65.gs],[dgrf70.gs],[dgrf75.gs],[dgrf80.gs], $
              [dgrf85.gs],[dgrf90.gs],[igrf95.gs],[igrf95s.gs]])

hs=transpose([[dgrf45.hs],[dgrf50.hs],[dgrf55.hs],[dgrf60.hs], $
              [dgrf65.hs],[dgrf70.hs],[dgrf75.hs],[dgrf80.hs], $
              [dgrf85.hs],[dgrf90.hs],[igrf95.hs],[igrf95s.hs]])

igrf={epoch:epoch,earth_rad:earth,n_coeffs:n_coef,gs:gs,hs:hs}
return,igrf

end

function calculate_igrf,posn,gs,hs
;
; return the igrf model field
;     Input: posn[n,3]    position array in geocentric geographic coodinates (in km)
;            gs[n,n_coeffs]  g coefficients
;            hs[n,n_coeffs]  h coefficients
;
;     Output:  bfield[n,3]    model field in geocentric geographic coodinates (in nT)
;
;   Written by R. J. Strangeway 4/30/98
;

; set up

n_coeffs=n_elements(gs(0,*))
n_terms=round((sqrt(8.*n_coeffs+9.)-3.)/2.)
n_times=n_elements(posn(*,0))
rr=sqrt(posn(*,0)^2+posn(*,1)^2+posn(*,2)^2)
lat=acos(posn(*,2)/rr)
lng=atan(posn(*,1),posn(*,0))
ct=cos(lat)
st=sin(lat)
cl=dblarr(n_times,n_terms)
sl=dblarr(n_times,n_terms)
cl(*,0) = cos(lng)
sl(*,0) = sin(lng)
ratio=6371.2d0/rr
rr=ratio*ratio
bfield=dblarr(n_times,3)

; Schmidt Quasi-normal coefficients

p = dblarr(n_times,n_coeffs+1)
q = dblarr(n_times,n_coeffs+1)
p(*,0) = 1.d0
p(*,2) = st
q(*,0) = 0.d0
q(*,2) = ct

indx = {n:intarr(n_coeffs+1),m:intarr(n_coeffs+1)}
l=0
m=1
n=0
for k = 1,n_coeffs do begin
   if (n lt m) then begin
      m=0
      n=n+1
      rr=rr*ratio
   endif
   indx.n(k) = n
   indx.m(k) = m
   if (m ne n) then begin
      one = sqrt(double(n*n-m*m))
      two = sqrt((n-1.d0)^2 - double(m*m))/one
      three = (2.d0*n-1.d0)/one
      i = k - n
      j = i - n + 1
;      print,k,indx.n(k),indx.m(k),one, two,three
      p(*,k) = three*ct*p(*,i) - two*p(*,j)
      q(*,k) = three*(ct*q(*,i) - st*p(*,i)) - two*q(*,j)
   endif else begin
      if (k ne 2) then begin
         one = sqrt(1.d0-0.5d0/m)
         j = k-n-1
;         print,k,indx.n(k),indx.m(k),one
         p(*,k) = one*st*p(*,j)
         q(*,k) = one*(st*q(*,j)+ct*p(*,j))
         cl(*,m-1) = cl(*,m-2)*cl(*,0) - sl(*,m-2)*sl(*,0)
         sl(*,m-1) = sl(*,m-2)*cl(*,0) + cl(*,m-2)*sl(*,0)
      endif
   endelse
   one = gs(*,k-1)*rr
   if (m eq 0) then begin
      bfield(*,0) = bfield(*,0) + one*q(*,k)
      bfield(*,2) = bfield(*,2) - (n+1.d0)*one*p(*,k)
   endif else begin
      two = hs(*,k-1)*rr
      three = one*cl(*,m-1) +two*sl(*,m-1)
      bfield(*,0) = bfield(*,0) + three*q(*,k)
      bfield(*,2) = bfield(*,2) - (n+1.d0)*three*p(*,k)
      bz = where (st eq 0.d0, nbz)
      if (nbz ne 0) then bfield(bz,1) = bfield(bz,1) + $
         (one(bz)*sl(bz,m-1) - two(bz)*cl(bz,m-1))*q(bz,k)*ct(bz)
      bz = where (st ne 0.d0, nbz)
      if (nbz ne 0) then bfield(bz,1) = bfield(bz,1) + $
         (one(bz)*sl(bz,m-1) - two(bz)*cl(bz,m-1))*m*p(bz,k)/st(bz)
   endelse
   m = m + 1
endfor

; rotate from north,east,down to x,y,z

bz =    bfield(*,0)*st - bfield(*,2)*ct
brho =  bfield(*,0)*ct + bfield(*,2)*st
bx = -brho*cl(*,0) - bfield(*,1)*sl(*,0)
by = -brho*sl(*,0) + bfield(*,1)*cl(*,0)

bfield(*,0) = bx
bfield(*,1) = by
bfield(*,2) = bz


return,bfield
end

pro get_new_igrf,no_store_old=no_store_old

; replace the get_fa_orbit returned B_model with IGRF model computed
; on basis of Malin and Barraclough, 1981 (slightly different than MAGSAT)

@tplot_com

nm = where (data_quants(*).name eq 'B_model', nmm)
if (nmm eq 0) then begin
  print,''
  print,'GET_NEW_IGRF: B_model not stored as tplot data, returning'
  print,''
  return
endif

nm = where (data_quants(*).name eq 'fa_pos', nmm)
if (nmm eq 0) then begin
  print,''
  print,'GET_NEW_IGRF: fa_pos not stored as tplot data, returning'
  print,''
  return
endif

get_data,'fa_pos',data=fa_pos_gei
the_sun=get_sun_ra_dec(fa_pos_gei.x)
n_arr = n_elements(the_sun.time)
tmp = dblarr(n_arr)
cs = cos(the_sun.gst*!dpi/180.d0)
sn = sin(the_sun.gst*!dpi/180.d0)

gei_to_geo = {x:fa_pos_gei.x, $
              y:[[[ cs],[-sn],[tmp]], $
                 [[ sn],[ cs],[tmp]], $
                 [[tmp],[tmp],[tmp+1.d0]]]}

fa_pos_geo=fa_pos_gei
fa_pos_geo.y=transform_vector(gei_to_geo.y,fa_pos_gei.y)

igrf=set_igrf_coefficients()

; verify that last term is secular variation

if (abs (igrf.gs(n_elements(igrf.epoch)-1,0)) gt 100.d0) then print,'NO SECULAR VARIATION'

times=round(igrf.epoch)
for n = 0,n_elements(times)-1 do igrf.epoch(n) = (julday(1,1,times(n))-julday(1,1,1970))*86400.d0

; set last term to end of time range

tmx = max(fa_pos_geo.x,min=tmn)
n_igrf=n_elements(igrf.epoch)
if (tmx le igrf.epoch(n_igrf-2)) then tmx = igrf.epoch(n_igrf-2) + 86400.d0

igrf.gs(n_igrf-1,*)=igrf.gs(n_igrf-2,*) + igrf.gs(n_igrf-1,*)*5.d0*(tmx-igrf.epoch(n_igrf-2))/(igrf.epoch(n_igrf-1)-igrf.epoch(n_igrf-2))
igrf.hs(n_igrf-1,*)=igrf.hs(n_igrf-2,*) + igrf.hs(n_igrf-1,*)*5.d0*(tmx-igrf.epoch(n_igrf-2))/(igrf.epoch(n_igrf-1)-igrf.epoch(n_igrf-2))
igrf.epoch(n_igrf-1)=tmx

; interpolate the data to the time arrays

tmx = max(fa_pos_geo.x,min=tmn)
n1= max(where (igrf.epoch le tmn))
n2= min(where (igrf.epoch ge tmx))
n_terms=n_elements(igrf.gs(0,*))

dgdt = reform((igrf.gs(n2,*)-igrf.gs(n1,*))/(igrf.epoch(n2)-igrf.epoch(n1)))
gs = dblarr(n_arr,n_terms)
for n = 0,n_terms-1L do gs(*,n)=igrf.gs(n1,n)+dgdt(n)*(fa_pos_geo.x-igrf.epoch(n1))

dhdt = reform((igrf.hs(n2,*)-igrf.hs(n1,*))/(igrf.epoch(n2)-igrf.epoch(n1)))
hs = dblarr(n_arr,n_terms)
for n = 0,n_terms-1L do hs(*,n)=igrf.hs(n1,n)+dhdt(n)*(fa_pos_geo.x-igrf.epoch(n1))

b_model=calculate_igrf(fa_pos_geo.y,gs,hs)
b_m_gei= b_model
for i=0l,n_arr-1l do b_m_gei(i,*) = reform(gei_to_geo.y(i,*,*))##reform(b_model(i,*))

get_data,'B_model',data=bm
bm.ytitle='B_model_old'
store_data,'B_model',data={x:bm.x,y:b_m_gei,ytitle:'B_model'}
if (not keyword_set(no_store_old)) then begin
  store_data,'B_model_old',data=bm
  store_data,'Delta_B_model',data={x:bm.x,y:b_m_gei-bm.y,ytitle:'Delta_B_model'}
endif

return
end


function get_phase_from_attctrl,debug=debug

; patch the Sun phase information from attitude control quantities


; check that housekeeping is displayed in sdt - if not notify user and return

prog = getenv('FASTBIN') + '/showDQIs'
spawn, prog, result, /noshell
b = where (strpos(result,'AttitudeCtrl') ge 0,nb)

if (nb eq 0) then begin

    print,''
    print,'UCLA_MAG_DESPIN needs AttitudeCtrl data from SDT'
    print,'  Add any of the AttitudeCtrl data quantities (e.g. SUN)'
    print,''
    return,0

endif else begin

    print,''
    print,'Getting phase data from AttitudeCtrl'
    print,''

   data=get_ts_from_sdt('AttitudeCtrl',2001,/all)

;  force sun into data.comp24/25 - under test - now using MUE reported times etc.
;  only force in if object not 176

   patch = intarr(n_elements(data.comp24))

      safety=data

;     subtract MUE - OBJ OFFSET time from MUE reported times

      data.comp16 = data.comp16 - 0.000183105d0
      data.comp22 = data.comp22 - 0.000183105d0

      dc = data.comp17(1:*)-data.comp17(0:*)
      bcs = where (dc ne 0 and data.comp28(1:*) ne 176, ncs)

      if (debug) then begin
         print,'NCS',ncs
         print,'MEDIAN MUE-OBJ',median(data.comp16-data.comp24,/even)
      endif
      if (ncs ne 0) then begin
         data.comp24(bcs+1)=data.comp16(bcs+1)
         data.comp25(bcs+1)=data.comp17(bcs+1)
         data.comp28(bcs+1)=176
         patch(bcs+1)=1
         if (bcs(0) eq 0) then begin
            data.comp24(0)=data.comp16(0)
            data.comp25(0)=data.comp17(0)
            data.comp28(0)=176
            patch(0)=1
         endif
         dt = data.comp24(1:*)-data.comp24(0:*)
         nsp = round(dt/data.comp26)
         b_notz = where (nsp ne 0, n_notz)
         if (n_notz gt 0) then dt(b_notz) = dt(b_notz)/nsp(b_notz)
         b_isz = where (nsp eq 0, n_isz)
         if (n_isz gt 0) then dt(b_isz) = !values.d_nan
         data.comp26(bcs+1)=dt(bcs)
         if (bcs(0) eq 0) then data.comp26(0)=data.comp26(1)
         if (debug) then begin
            plot,data.comp24-safety.comp24,psym=3,yrange=[-.01,.01]
            ans = ''
            read, ans, prompt='Are new times reasonable? '
            if (ans eq 'N' or ans eq 'n') then begin
               data=safety
               patch(*)=0
            endif
         endif
      endif
   spin_per=data.comp26
   spin_zero=data.comp24 + data.time(0) - (data.time(0) mod 86400.d0)
   is_sun = data.comp28

   nadir_zero=data.comp22 + data.time(0) - (data.time(0) mod 86400.d0)

   phase_data={spin_zero:spin_zero,spin_per:spin_per,is_sun:is_sun,patch:patch,nadir_zero:nadir_zero}
   return,phase_data

endelse

end



function patch_spin_phase,phase_data,exp_ra,exp_dec, $
no_patch=no_patch,force_patch=force_patch,no_model=no_model,no_query=no_query

; patch the spin phase using recalculated nadir phase data

spin_zero=phase_data.spin_zero
spin_per=phase_data.spin_per
is_sun=phase_data.is_sun
patch=phase_data.patch
nadir_zero=phase_data.nadir_zero

; Assume that if more than 30 points have been patched already that the
; nadir phase needs to be recalculated - unless explicitly disabled

bptch = where (patch, nptch)
if (nptch gt 30 and no_patch eq 0) then force_patch=1

spin_phase = dblarr(n_elements(spin_zero))-98.4d0
do_patch = intarr(n_elements(spin_zero))
if (force_patch) then do_patch(*) = 1

bfin = where (finite(spin_zero), nfin)
if (nfin gt 0) then begin
  t_tmp =spin_zero(bfin)
  bbad = where ((t_tmp(1:*) - t_tmp(0:*)) mod 256.d0 eq 0.d0, nbad)
  if (nbad ne 0) then begin 
     do_patch(bfin(bbad+1)) = 1
     if (bbad(0) eq 0) then begin
        do_patch(bfin(0)) = 1
        nbad=nbad+1
     endif
  endif
endif
if (force_patch) then nbad=n_elements(do_patch)

if (no_model eq 0 and no_patch eq 0 and nbad gt 0) then begin

   print,''
   print,'Patching spin phase data with nadir phase'
   print,''

   get_data,'fa_pos',data=fa_pos_gei
   the_sun=get_sun_ra_dec(fa_pos_gei.x)
   the_sc = dblarr(n_elements(fa_pos_gei.x))+(90.d0 - exp_dec)*!dpi/180.d0
   phi_sc = dblarr(n_elements(fa_pos_gei.x))+(exp_ra)*!dpi/180.d0

;  spin axis (despun z-axis) in GEI

   sc_z = [[sin(the_sc)*cos(phi_sc)],[sin(the_sc)*sin(phi_sc)],[cos(the_sc)]]
 
   the_sc = (90.d0 - the_sun.dec)*!dpi/180.d0
   phi_sc = the_sun.ra*!dpi/180.d0
   sun_gei = [[sin(the_sc)*cos(phi_sc)],[sin(the_sc)*sin(phi_sc)],[cos(the_sc)]]

;  despun y-axis in GEI
 
   sc_y = vector_cross_product(sc_z,sun_gei)
   sc_y_abs = sqrt(vector_dot_product(sc_y,sc_y))
   sc_y = sc_y/[[sc_y_abs],[sc_y_abs],[sc_y_abs]]

;  despun x-axis in GEI

   sc_x = vector_cross_product(sc_y,sc_z)

   sc_to_gei = {x:fa_pos_gei.x, $
                y:[[[sc_x(*,0)],[sc_x(*,1)],[sc_x(*,2)]], $
                  [[sc_y(*,0)],[sc_y(*,1)],[sc_y(*,2)]], $
                  [[sc_z(*,0)],[sc_z(*,1)],[sc_z(*,2)]]]}

;  Earth position in despun coordinates, at the time of the nadir zero

   earth_sc = -transform_vector(sc_to_gei.y,fa_pos_gei.y,/inverse)

   y2=spl_init(fa_pos_gei.x-fa_pos_gei.x(0),earth_sc(*,0),/double)
   earth_x=spl_interp(fa_pos_gei.x-fa_pos_gei.x(0),earth_sc(*,0),y2, $
   nadir_zero-fa_pos_gei.x(0),/double)
   y2=spl_init(fa_pos_gei.x-fa_pos_gei.x(0),earth_sc(*,1),/double)
   earth_y=spl_interp(fa_pos_gei.x-fa_pos_gei.x(0),earth_sc(*,1),y2, $
   nadir_zero-fa_pos_gei.x(0),/double)

   earth_phs = atan(earth_y,earth_x) mod (2.d0*!dpi)
   bz = where (earth_phs lt 0, nz)
   if (nz gt 0) then earth_phs(bz)=earth_phs(bz) + 2.d0*!dpi

   patch_phs = 22.5d0 + earth_phs*180./!dpi ; angle is empirical
   bz = where (patch_phs gt 180., nz)
   if (nz gt 0) then patch_phs(bz)=patch_phs(bz) - 360.d0

   brep = where ((is_sun ne 176) and do_patch, nrep)
   bsun = where (is_sun eq 176, nsun)

   bfin = where (finite(spin_per) ne 0, nfin)
   if (nfin gt 1) then per_est = median(spin_per(bfin),/even) else per_est = 5.d0

   if (no_query eq 0) then begin
      plot,patch_phs,/ynozero
      ans = ''
      read, ans, prompt='Is new phase reasonable? '
      if (ans eq 'N' or ans eq 'n') then nrep=0
   endif

   if (nrep gt 0) then begin

       print,nrep,n_elements(nadir_zero)

       ts = nadir_zero - patch_phs*per_est/360.d0
       dts = ts(1:*)-ts(0:*)
       r_spins=dts/per_est
       n_spins=round(r_spins)
       frq_est=n_spins*360.d0/dts
       bbb = where (abs(r_spins-n_spins) gt .25, nbb)
       if (nbb gt 0) then frq_est(bbb)=!values.d_nan
       help,frq_est
       frq_est=[frq_est(0),frq_est]
       help,frq_est

       spn_tmp={x:spin_zero,y:frq_est}
       frq_tmp={x:nadir_zero,y:frq_est}
       phs_tmp={x:nadir_zero,y:patch_phs}

       phs_new=interpolate_phase(phs_tmp,frq_tmp,spn_tmp)
       bz = where (phs_new.y gt 180., nz)
       if (nz gt 0) then phs_new.y(bz)=phs_new.y(bz) - 360.d0

       if (nsun le 1) then begin
          print,''
          print,'PATCH_SPIN_PHASE - WARNING - Eclipse only spin phase'
          print,''
       endif else begin
          phs_off = median(phs_new.y(bsun),/even)
          if (no_query eq 0) then begin
             plot,phs_new.y,/ynozero
             print,'PHS_OFF',phs_off
             ans = ''
             read, ans, prompt='Ready to continue? '
          endif
          patch_phs = patch_phs - phs_off
       endelse

       phase_data.spin_zero(brep) = nadir_zero(brep)
       spin_phase(brep) = patch_phs(brep) - 98.4d0
       phase_data.spin_per(brep) = 360.d0/frq_est(brep)
       phase_data.is_sun(brep) = -1
       phase_data.patch(brep) = 1

   endif
  
endif

return,spin_phase
end
