;       @(#)curvout.pro	1.7     03/12/98
;+
; NAME: CURVOUT
;
; PURPOSE:
; Calls IDL's CURVEFIT iteratively, rejecting outliers at each
; iteration, until the fit converges or too many points are thrown
; away.
;
; INPUTS: X - the independent variable
;         Y - the dependent variable
;         WEIGHTS - the relative importance of each point in
;                   determining goodness of fit
;         APAR - a vector of parameters for evaluating the model
;             function. This should be a good guess on input.
;       
; KEYWORD PARAMETERS:
;    FUNCTION_NAME - a string naming a user supplied procedure which
;                    will be called by CURVEFIT.
;
;    ITMAX: maximum number of CURVEFIT iterations. CURVOUT will
;           iterate until it's done.
;    
;    ITER: the number of iterations actually performed. This will
;          apply only to the last cycle of CURVOUT. 
;
;    TOL: convergence tolerance. The routine returns when the relative
;         decrease in chi-squared is less than TOL in an
;         interation. Default = 1.e-3.
;
;    CHI2: The value of chi-squared on exit (obsolete)
;
;    CHISQ: The value of reduced chi-squared on exit
;
;    NODERIVATIVE: If this keyword is set then the user procedure will
;                  not be requested to provide partial
;                  derivatives. The partial derivatives will be
;                  estimated in CURVEFIT using forward differences. If
;                  analytical derivatives are available they should
;                  always be used.
;    
;    USED - a named variable in which the indices of the data
;    used for the final fit are returned. 
;
;    TOSSED - a named variable in which the indices of the data
;    removed from the final fit are returned.
;
;    MAX_TOSS - the maximum allowable fraction of the data represented
;               by outliers. Up to MAX_TOSS*(number of points) may be
;               thrown away to acheive a good fit. Default is 0.5. 
;
;    SHOW - if set, causes successive fits to be plotted
;           interactively.
;
;
; OUTPUTS: A - the vector of parameters at which the model function
;          most closely matches the data Y.
;
;          SIGMA - standard deviations of APAR
;
; EXAMPLE: phase_diff = curveout(tdiff,pdiff,weights,ang,sigma,
;                                funct='sun_mag_diff',/noderiv)
;
; MODIFICATION HISTORY: 
;
;-
function curvout, xc, yc, weightsc, apar, sigma,  $
                  FUNCTION_NAME = function_name, $
                  ITMAX=itmax, ITER=iter, TOL=tol, CHI2=chi2, $
                  NODERIVATIVE=noderivative, CHISQ=chisq,  $
                  USED = orig_indices, SHOW = show,  $
                  TOSSED = tossed, MAX_TOSS = max_toss


green = !d.n_colors*0.6
red = !d.n_colors*0.9

nan = !values.f_nan
if idl_type(yc) eq 'double' then nan = !values.d_nan
crap = replicate(nan, n_elements(xc))

catch,err_stat
if (err_stat ne 0) then begin
    print,err_stat
    message,!err_string,/continue
    return,crap
endif

if not defined(max_toss) then max_toss = 0.5

eps = 0.01                      ; min allowable mean fractional change
                                ; in c with 3 sigma toss 
x = xc
y = yc
nx = n_elements(x)
nsvd = n_elements(apar)
n_orig = nx
orig_indices = lindgen(nx)
tossed = -1L
if defined(weightsc) then weights = weightsc else weights = fltarr(nx)

not_nan = where(finite(x) and finite(y),nnn)
if nnn eq 0 then begin
    message,'No finite data points...',/continue
    tossed = orig_indices
    return,crap
endif
orig_indices = orig_indices(not_nan)
x = x(not_nan)
y = y(not_nan)
if defined(weights) then weights = weights(not_nan)

if not defined(chisq) then chisq = 0.0 

yfit = curvefit(x, y, weights, apar, sigma,  $
                FUNCTION_NAME = function_name, $
                ITMAX=itmax, ITER=iter, TOL=tol,  $
                CHI2=chi2, NODERIVATIVE=noderivative,  $
                CHISQ = chisq)
if not defined(yfit) then return,yfit

my_chi = total((y-yfit)^2,/nan)
goodness = my_chi/(nx-nsvd)     ; the smaller, the gooder...
my_sigma = sqrt(my_chi/(n_elements(y)-2l))

if keyword_set(show) and defined(apar) then begin
    title = 'data-fit'
    if defined(function_name) then title = title + ' ('+function_name+')'
    plot,x-x(0),y-yfit,/ynozero,title=title
    oplot,var_range(x-x(0)),[1,1]*(!y.crange(0) > (-my_sigma)),color=red
    oplot,var_range(x-x(0)),[1,1]*(!y.crange(1) <  my_sigma),color=red
    print,'Hit space bar to continue...'
    dummy = get_kbrd(1)
endif

apar0 = apar
iteration = 0l
repeat begin
    apar_was = apar
    my_chi_was = my_chi
    goodness_was = goodness
    max_this_time = 1.2+float(iteration)*.4
    
    my_sigma = sqrt(my_chi/(n_elements(y)-2l))
    dev = abs(y-yfit)
    worst = reverse(sort(dev))
    nworst = n_elements(worst)
    
    out_of_bounds = min(where(dev(worst) lt max_this_time*my_sigma))
    if out_of_bounds le 0 then begin
        if n_elements(x) ne n_orig then begin
            if defined(function_name) then begin
                call_procedure, function_name, xc, apar, yfit
            endif else begin
                call_procedure, 'funct', xc, apar, yfit
            endelse
            
            tossed = lindgen(n_orig)
            tossed(orig_indices) = -1L
            tss = where(tossed ge 0,ntss)
            if ntss gt 0 then tossed = tossed(tss)
        endif
        
        if keyword_set(show) then message,'converged after' + $
          ''+strcompress(string(iteration))+' iterations!',/continue
        
        tossed = lindgen(n_orig)
        tossed(orig_indices) = -1L
        tss = where(tossed ge 0,ntss)
        if ntss gt 0 then tossed = tossed(tss)
        return,yfit             ; fit is good, no outliers!
    endif
    
    use = worst(out_of_bounds:nworst-1l)
    all_gone = n_elements(use) le n_orig*(1.-max_toss)
    
    if not all_gone then begin
        use = use(sort(use))
        x = x(use)
        y = y(use)
        if defined(weights) then weights = weights(use)
        yfit = curvefit(x, y, weights, apar, sigma,  $
                        FUNCTION_NAME = function_name, $
                        ITMAX=itmax, ITER=iter, TOL=tol,  $
                        CHI2=chi2, NODERIVATIVE=noderivative,  $
                        CHISQ = chisq)
        
        my_chi = total((y-yfit)^2,/nan)
        goodness = my_chi/(n_elements(use)-nsvd)
        
        if keyword_set(show) then begin
            color = !d.n_colors*(((iteration+1) mod 4)*.1 + .3)
            if ((iteration+1) mod 4) eq 0 then begin
                plot,x-x(0),y-yfit,/ynozero,title=title
            endif
            oplot,x-x(0),y-yfit,color=color
            oplot,var_range(x-x(0)), $
              [1,1]*(!y.crange(0) > (-my_sigma)),color=red
            oplot,var_range(x-x(0)), $
              [1,1]*(!y.crange(1) <  my_sigma),color=red
            print,'Hit space bar to continue...'
            dummy = get_kbrd(1)
        endif
    endif
    frac_change = 2.0*abs(goodness-goodness_was)/$
      (goodness+goodness_was)
    goodness_grew = goodness gt goodness_was
    converged = (frac_change lt eps) or goodness_grew
    
    if goodness_grew or all_gone then begin
        apar = apar_was
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
    if defined(function_name) then begin
        call_procedure, function_name, xc, apar, yfit
    endif else begin
        call_procedure, 'funct', xc, apar, yfit
    endelse
    
    tossed = lindgen(n_orig)
    tossed(orig_indices) = -1L
    tss = where(tossed ge 0,ntss)
    if ntss gt 0 then tossed = tossed(tss)
endif

if keyword_set(show) then message,'converged after ' + $
  ''+strcompress(string(iteration))+' iterations!',/continue
return,yfit
end
