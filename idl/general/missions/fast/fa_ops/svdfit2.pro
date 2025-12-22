;
; This is the IDL 4 version of SVDFIT, except that this version
; returns to the caller with singular values zeroed, instead of just
; giving up. 
;
;
FUNCTION SVDFIT2,X,Y,M, YFIT = yfit, WEIGHT = weight, CHISQ = chisq, $
	SINGULAR = sing, VARIANCE = var, COVAR = covar, Funct = funct

        THRESH = 1.0E-9         ;Threshold used in editing singular values
 

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
			' singular values found.',/CONTINUE
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


