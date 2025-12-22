;       @(#)svdout.pro	1.21     10/09/02
;+
; NAME: SVDOUT
;
; PURPOSE: Fit to a model function with outlier throw-away. Essentially the
;          same as SVDFIT, which is supplied with IDL.
;
; CALLING SEQUENCE: c = svdout(x,y,nsvd)
; 
; INPUTS: X - array of independent variables corresponding to Y
;         Y - dependent variables
;         NSVD - order of desired polynomial fit, or number of
;         coefficients in arbitrary linear model function. 
;
; KEYWORDS: All the same as for SVDFIT, plus...
;          USED - a named variable in which the indices of the data
;          used for the final fit are returned. 
;
;          TOSSED - a named variable in which the indices of the data
;          removed from the final fit are returned.
;
;          SHOW - if set, causes successive fits to be plotted
;          interactively, so you can see what's going on, set weights
;          properly, etc. 
;
; OPTIONAL INPUTS: see documentation for IDL routine SVDFIT.
;
; OUTPUTS: an array of coefficients for polynomial fit. If NSVD is
;          2, then Y is approximated best by:
;                 y ~ c(0) + c(1)*x + c(2)*x^2
;
; OPTIONAL OUTPUTS: see documentation for IDL routine SVDFIT.
;
; MODIFICATION HISTORY: written October 1996 by Bill Peria, UCB/SSL
;                       11-March-97 began using Mozer's 1.2 + 0.4*i scheme
;                       14-April-97 inserted SVDFIT2, which is just
;                       SVDFIT with /CONTINUE added to the warning
;                       message, so that it won't just quit!
;                       23-June-97 Moved SVDFIT2 into separate module,
;                       to avoid horrible IDL 5 implementation of
;                       SVDFIT! 
;-
;
; This code would ideally use the incomplete gamma function to
; determine if the fit were improving or not. Like this:
; 
; goodness = igamma(0.5*(nx-nsvd), 0.5*chisq)
;
; However, doing so requires that the user provide accurate error
; estimates for each individual data point, via the WEIGHT
; keyword. Since this isn't always done (sometimes you just want a
; decent functional approximation to your data, and don't know or
; don't want to be bothered with weights) I decided to just look at
; chisq divided by number of degrees of freedom. May add the IGF route
; as a keyword sometime, for more serious model evaluation
; purposes. On the other hand, the whole point of this thing is to
; reject outliers, so how do I know what an outlier is unless I know
; the single-point measurement errors? I guess it's implicit here that
; whatever the measurement errors are, they are the same at each
; point. This could be a problem if this code is used in a dewobbler
; for UVI. 9-Oct-02 WJP
;




function svdout,xc,yc,nsvd,WEIGHT=weightc,FUNCT=funct, YFIT = yfit, $
                COVAR = covar, VARIANCE = variance,  $
                SINGULAR = singular, CHISQ = chisq,  $
                USED = orig_indices, SHOW = show, TOSSED = tossed

green = !d.n_colors*0.6
red = !d.n_colors*0.9


nan = !values.f_nan
if idl_type(yc) eq 'double' then nan = !values.d_nan

;
; must define these to something, so they get returned!
covar = nan
variance = nan


if ((not defined(nsvd)) and defined(funct)) then begin
    basis = call_function(funct,xc,nsvd)
endif
crap = make_array(type=data_type(yc),nsvd)

catch,err_stat
if (err_stat ne 0) then begin
    print,err_stat
    message,!err_string,/continue
    return,crap
endif

eps = 0.01                      ; min allowable mean fractional change
                                ; in c with 3 sigma toss 
x = xc
y = yc
if defined(weightc) then weight = weightc
nx = n_elements(x)
n_orig = nx
orig_indices = lindgen(nx)
tossed = -1L

not_nan = where(finite(x) and finite(y),nnn)
if nnn eq 0 then begin
    message,'No finite data points...',/continue
    tossed = orig_indices
    return,crap
endif
orig_indices = orig_indices(not_nan)
x = x(not_nan)
y = y(not_nan)
if defined(weight) then weight = weight(not_nan)

if not defined(chisq) then chisq = 0.0 

yfit = 0.                       ; must be defined to be returned
c = svdfit2(x, y, nsvd, WEIGHT = weight,  $
            FUNCT = funct, YFIT = yfit, CHISQ = chisq, $
            COVAR = covar, VARIANCE = variance, $
            SINGULAR =   singular)
if not defined(c) then return,c

sigma = sqrt(chisq/(n_elements(y)-2l))

if keyword_set(show) then begin
    title = 'data-fit'
    if defined(funct) then title = title + ' ('+funct+')'
    plot,x-x(0),y-yfit,/ynozero,title=title
    oplot,var_range(x-x(0)),[1,1]*(!y.crange(0) > (-sigma)),color=red
    oplot,var_range(x-x(0)),[1,1]*(!y.crange(1) <  sigma),color=red
    print,'Hit space bar to continue...'
    dummy = get_kbrd(1)
endif


goodness = chisq/(nx-nsvd)      ; the smaller, the gooder...

c0 = c
iteration = 0l
repeat begin
    c_was = c
    chisq_was = chisq
    goodness_was = goodness
    max_this_time = 1.2+float(iteration)*.4
    
    sigma = sqrt(chisq/(n_elements(y)-2l))
    dev = abs(y-yfit)
    worst = reverse(sort(dev))
    nworst = n_elements(worst)
    out_of_bounds = min(where(dev(worst) lt max_this_time*sigma))
    if out_of_bounds le 0 then begin
        if n_elements(x) ne n_orig then begin
            if defined(funct) then begin
                basis = call_function(funct,xc,nsvd)
            endif else begin
                exponents = findgen(nsvd)##(fltarr(n_orig)+1.)
                basis = (replicate(1.d,nsvd)##xc)^exponents
            endelse
            
            yfit = xc - xc
            for i=0,nsvd-1l do begin
                yfit = yfit + c(i)*reform(basis(*,i))
            endfor
        endif
        
        if keyword_set(show) then message,'converged after' + $
          ''+strcompress(string(iteration))+' iterations!',/continue
        
        tossed = lindgen(n_orig)
        tossed(orig_indices) = -1L
        tss = where(tossed ge 0,ntss)
        if ntss gt 0 then tossed = tossed(tss)
        return,c                ; fit is good, no outliers!
    endif
    
    use = worst(out_of_bounds:nworst-1l)
    all_gone = n_elements(use) le n_orig/2.
    
    if not all_gone then begin
        use = use(sort(use))
        x = x(use)
        y = y(use)
        if defined(weight) then weight = weight(use)
        c = svdfit2(x, y, nsvd, WEIGHT = weight,  $
                    FUNCT = funct, YFIT = yfit, CHISQ = chisq, $
                    COVAR = covar, VARIANCE = variance, $
                    SINGULAR =   singular) 
        if keyword_set(show) then begin
            color = !d.n_colors*(((iteration+1) mod 4)*.1 + .3)
            if ((iteration+1) mod 4) eq 0 then begin
                plot,x-x(0),y-yfit,/ynozero,title=title
            endif
            oplot,x-x(0),y-yfit,color=color
            oplot,var_range(x-x(0)), $
              [1,1]*(!y.crange(0) > (-sigma)),color=red
            oplot,var_range(x-x(0)), $
              [1,1]*(!y.crange(1) <  sigma),color=red
            print,'Hit space bar to continue...'
            dummy = get_kbrd(1)
        endif
        goodness = chisq/(n_elements(use)-nsvd)
    endif
    frac_change = 2.0*abs(goodness-goodness_was)/$
      (goodness+goodness_was)
    goodness_grew = goodness gt goodness_was
    converged = (frac_change lt eps) or goodness_grew
    
    if goodness_grew or all_gone then begin
        c = c_was
    endif else begin
        orig_indices = orig_indices(use)
    endelse
    
    iteration = iteration + 1l
endrep until (converged or  $
              all_gone  or  $
              goodness_grew)

if not converged then begin
    message,'did not converge...',/continue
endif

if n_elements(x) ne n_orig then begin
    if defined(funct) then begin
        basis = call_function(funct,xc,nsvd)
    endif else begin
        exponents = findgen(nsvd)##(fltarr(n_orig)+1.)
        basis = (replicate(1.d,nsvd)##xc)^exponents
    endelse
    
    tossed = lindgen(n_orig)
    tossed(orig_indices) = -1L
    tss = where(tossed ge 0,ntss)
    if ntss gt 0 then tossed = tossed(tss)
    
    yfit = xc - xc
    for i=0,nsvd-1l do begin
        yfit = yfit + c(i)*reform(basis(*,i))
    endfor
endif

if keyword_set(show) then message,'converged after ' + $
  ''+strcompress(string(iteration))+' iterations!',/continue
return,c
end
