function poly_out,xc,yc,ndegree,yfit,yband,sigma,a
;+
; NAME: POLY_OUT
;
; PURPOSE: Polynomial fit with 3-sigma throw-away. Essentially the
;          same as POLY_FIT, which is supplied with IDL.
;
;
; CALLING SEQUENCE: c = poly_out(x,y,ndegree)
; 
; INPUTS: X - array of independent variables corresponding to Y
;         Y - dependent variables
;         NDEGREE - order of desired polynomial fit
;
; OPTIONAL INPUTS: see documentation for IDL routine POLY_FIT.
;
; OUTPUTS: an array of coefficients for polynomial fit. If NDEGREE is
;          2, then Y is approximated best by:
;                 y ~ c(0) + c(1)*x + c(2)*x^2
;
; OPTIONAL OUTPUTS: see documentation for IDL routine POLY_FIT.
;
; MODIFICATION HISTORY: written October 1996 by Bill Peria, UCB/SSL
;
;-
;	@(#)poly_out.pro	1.7	


eps = 0.01  ; minimum allowable mean fractional change in c with 3 sigma toss
x = xc
y = yc
nx = n_elements(x)
n_orig = nx

c = poly_fit(x,y,ndegree,yfit,yband,sigma,a)
if not defined(c) then return,c
c0 = c

repeat begin
    c_was = c
    sigma_was = sigma
    dev = abs(y-yfit)
    worst = reverse(sort(dev))
    nworst = n_elements(worst)
    three_sigma = min(where(dev(worst) lt 2.0*median(dev)))
    if three_sigma le 0 then begin
        return,c                ; fit is good, no outliers!
    endif
    
    use = worst(three_sigma:nworst-1l)
    use = use(sort(use))
    x = x(use)
    y = y(use)
    c = poly_fit(x,y,ndegree,yfit,yband,sigma,a)
    
    frac_change = $
      abs(total(2.0*abs(c-c_was)/(c+c_was))/double(ndegree))

    sigma_grew = sigma gt sigma_was
    converged = (frac_change lt eps) or sigma_grew
    all_gone = n_elements(use) le n_orig/2.
    
    if sigma_grew or all_gone then c = c_was

endrep until (converged or  $
              all_gone  or  $
              sigma_grew)

if not converged then begin
    message,'did not converge...',/continue
    return,c
endif
    
return,c
end
