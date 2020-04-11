
;PROCEDURE xfer_parameters
;PURPOSE:
;  transfers values between an array and a structure.
;  Used only by the FIT procedure.
;USAGE:
;  xfer_parameters,struct,names,array,/array_to_struct
;or:
;  xfer_parameters,struct,names,array,/struct_to_array
;

pro xfer_parameters,params,names, a,  fullnames=fullnames,varname=varname, num_params=pos ,$
    struct_to_array=struct_to_array, $
    array_to_struct=array_to_struct


if size(/type,params) ne 8 then return
tags = tag_names(params)


if keyword_set(names) then begin
   if size(/type,names) le 3 then p_names=tags[names] else begin
      if size(/n_dimen,names) eq 0 then p_names=strsplit(names,' ',/extract) else p_names=names
   endelse
endif else begin
;      dts = data_type(params,/struct)
;   w = where(dts eq 5 or dts eq 8,c)
;   if c ne 0 then  p_names = tags[w]
   p_names = tags
endelse

a_to_s = keyword_set(array_to_struct)

np = n_elements(p_names)

if a_to_s eq 0 then a = 0.d
fullnames = ''
pos = 0
if not keyword_set(varname) then varname=''

for nstr =0,n_elements(params)-1 do begin

for n=0,np-1  do begin
   name = strupcase(p_names[n])
   dotpos = strpos(name,'.',0)
   basename = strmid(name,0,uint(dotpos))         ; parse strings
   if dotpos gt 0 then begin
      subnames = strmid(name,dotpos+1,100)
      subnames = strsplit(subnames,':',/extract)
   endif else subnames = ''
   parenpos1 = strpos(basename,'[',0)
   if parenpos1 gt 0 then begin
      parenpos2 = strpos(basename,']',parenpos1)
      indnum= strmid(basename,parenpos1+1,parenpos2-parenpos1-1)
      indnum= strsplit(indnum,',',/extract)   ; returns an array!
      indnum = fix(indnum)
      basename2 = strmid(name,0,parenpos1)
   endif else begin
      indnum=0
      basename2 = basename
   endelse
   ind = (where(basename2 eq tags,count))[0]
   if count ge 1 then begin
      v = params[nstr].(ind)
      dt = size(/type,v)
      if dt eq 8 then begin        ; structure elements handled recursively
         ns = n_elements(v)
         if ns gt 1 then  indnums = string(indgen(ns),format="('[',i0.0,']')")  else indnums = ''
         if size(/n_dimen,indnum) ne 0  then begin
            v = v[indnum]
            indnums = indnums[indnum]
         endif else indnum = indgen(ns)
         prefix = basename2+indnums+'.'
         at = a[pos:*]
         xfer_parameters,v,subnames,at,fullnames=elnames,num_p=ns ,array_to_struct=a_to_s,varname=prefix
         if a_to_s then begin
         ;   (params[nstr].(ind))[indnum] = v          ; tough to get IDL to do this!
            param = params[nstr]
            vt = param.(ind)
            for i=0, n_elements(indnum)-1 do    vt[indnum[i]] = v[i]
            param.(ind) = vt
            params[nstr] = param
         endif  else  a=[a,at]
         fullnames = [fullnames,elnames]
         pos = pos + ns
      endif else begin            ;    extract numerical values
         if not keyword_set(names) and dt ne 5 then continue
         ns = n_elements(v)
         if ns gt 1 then  indnums = string(indgen(ns),format="('[',i0.0,']')")  else indnums = ''
         if size(/n_dimen,indnum) ne 0  then begin
            v = v[indnum]
            indnums = indnums[indnum]
         endif else indnum = indgen(ns)
         ns = n_elements(indnums)
         if a_to_s then v = a[pos:pos+ns-1]
         if a_to_s then  params[nstr].(ind)[indnum] = v[*]  else  a=[a,v[*]]
         fullnames = [fullnames,varname[nstr mod n_elements(varname)]+basename2+indnums]
         pos = pos + ns
      endelse
   endif else dprint,verbose=verbose,dlevel=0,'index not found'
endfor

endfor

if pos gt 0 then begin
   if a_to_s eq 0 then a = a[1:*]
   fullnames= fullnames[1:*]
endif

return
end






;+
; NAME:
;       FIT
;
; PURPOSE:
;       Non-linear least squares fit to a user defined function.
;       This procedure is an improved version of CURVEFIT that allows fitting
;       to a subset of the function parameters.
;       The function may be any non-linear function.
;       If available, partial derivatives can be calculated by
;       the user function, else this routine will estimate partial derivatives
;       with a forward difference approximation.
;
; CATEGORY:
;       E2 - Curve and Surface Fitting.
;
; CALLING SEQUENCE:
;       FIT,X, Y, PARAMETERS=par, NAMES=string, $
;             FUNCTION_NAME=string, ITMAX=ITMAX, ITER=ITER, TOL=TOL, $
;             /NODERIVATIVE
;
; INPUTS:
;       X:  A row vector of independent variables.  The FIT routine does
;     not manipulate or use X, it simply passes X
;     to the user-written function.
;
;       Y:  A row vector containing the dependent variable.
;
; KEYWORD INPUTS:
;
;       FUNCTION_NAME:  The name of the function to fit.
;          If omitted, "FUNC" is used. The procedure must be written as
;          described under RESTRICTIONS, below.
;
;       PARAMETERS:  A structure containing the starting parameter values
;          for the function.  Final values are also passed back through
;          this variable.  The fitting function must accept this keyword.
;          If omitted, this structure is obtained from the user defined
;          function.
;
;       NAMES: The parameters to be fit.  Several options exist:
;          A string with parameter names delimited by spaces.
;          A string array specifying which parameters to fit.
;          An integer array corresponding to elements within the PARAMETERS structure.
;          If undefined, then FIT will attemp to fit to all double precision
;          elements of the PARAMETERS structure.
;
;       WEIGHT:   A row vector of weights, the same length as Y.
;          For no weighting,
;            w(i) = 1.0.
;          For instrumental weighting,
;            w(i) = 1.0/y(i), etc.
;          if not set then w is set to all one's  (equal weighting)
;
;       DY:  A row vector of errors in Y.  If set, then WEIGHTS are set to:
;               W = 1/DY^2 and previous values of the WEIGHTS are replaced.
;
;       ERROR_FACTOR: set this keyword to have DY set to ERROR_FACTOR * Y.
;
;       ITMAX:  Maximum number of iterations. Default = 20.
;
;       TOL:    The convergence tolerance. The routine returns when the
;               relative decrease in chi-squared is less than TOL in an
;               interation. Default = 1.e-5.
;
;       NODERIVATIVE:  (optional)
;            If set to 1 then the partial derivatives will be estimated in CURVEFIT using
;               forward differences.
;            If set to 0 then the user function is forced to provide
;               partial derivatives.
;            If not provided then partial derivatives will be determined
;               from the user function only if it has the proper keyword
;               arguments.
;
;       VERBOSE: Verbose level (0: prints only errors, 1: prints results, 2: prints each iteration)
;              (see "DPRINT" for more info)
;       MAXPRINT: Maximum number of parameters to display while iterating
;               (Default is 8)
;       SILENT:  Equivalent to VERBOSE=0
;
; KEYWORD OUTPUTS:
;       ITER:   The actual number of iterations which were performed.
;
;       CHI2:   The value of chi-squared on exit.
;
;       FULLNAMES:  A string array containing the parameter names.
;
;       P_VALUES:  A vector with same dimensions as FULLNAMES, that
;           contains the final values for each parameter.  These values
;           will be the same as the values returned in PARAMETERS.
;
;       P_SIGMA:  A vector containing the estimated uncertainties in P_VALUES.
;
;       FITVALUES:  The fitted function values:
;
; OUTPUT
;       Returns a vector of calculated values.
;
; COMMON BLOCKS:
;       NONE.
;
; RESTRICTIONS:
;       The function to be fit must be defined and called FUNC,
;       unless the FUNCTION_NAME keyword is supplied.  This function,
;       must accept values of X (the independent variable), the keyword
;       PARAMETERS, and return F (the function's value at X).
;       if the NODERIV keyword is not set. then the function must also accept
;       the keywords: P_NAMES and PDER (a 2d array of partial derivatives).
;       For an example, see "GAUSS2".
;
;   The calling sequence is:
;
;       CASE 1:    (NODERIV is set)
;          F = FUNC(X,PAR=par)               ; if NODERIV is set  or:
;             where:
;          X = Variable passed into function.  It is the job of the user-written
;             function to interpret this variable. FIT does NOT use X.
;          PAR = structure containing function parameters, input.
;          F = Vector of NPOINT values of function, y(i) = funct(x), output.
;
;       CASE 2:     (NODERIV is not set)
;          F = FUNC(X,PAR=par,NAMES=names,PDER=pder)
;             where:
;          NAMES = string array of parameters to be fit.
;          PDER = Array, (NPOINT, NTERMS), of partial derivatives of FUNC.
;             PDER(I,J) = Derivative of function at ith point with
;             respect to jth parameter.  Optional output parameter.
;             PDER should not be calculated if P_NAMES is not
;             supplied in call. If the /NODERIVATIVE keyword is set in the
;             call to FIT then the user routine will never need to
;             calculate PDER.
;
; PROCEDURE:
;       Adapted from "CURVEFIT", least squares fit to a non-linear
;       function, pages 237-239, Bevington, Data Reduction and Error
;       Analysis for the Physical Sciences.
;
;       "This method is the Gradient-expansion algorithm which
;       combines the best features of the gradient search with
;       the method of linearizing the fitting function."
;
;       Iterations are performed until the chi square changes by
;       only TOL or until ITMAX iterations have been performed.
;
;       The initial guess of the parameter values should be
;       as close to the actual values as possible or the solution
;       may not converge.
;
;EXAMPLE:  Fit to a gaussian plus a quadratic background:
;  Here is the user-written procedure to return F(x) and the partials, given x:
;
;See the function "GAUSSIAN" for an example function to fit to.
;
;x=findgen(10)-4.5                          ; Initialize independent variables.
;y=[1.7,1.9,2.1,2.7,4.6,5.5,4.4,1.7,0.5,0.3]; Initialize dependent variables.
;plot,x,y,psym=4                            ; Plot data.
;xv = findgen(100)/10.-5.                   ; get better resolution abscissa.
;oplot,xv,gaussian(xv,par=p)                ; Plot initial guess.
;help,p,/structure                          ; Display initial guess.
;fit,x,y,func='gaussian',par=p,fit=f        ; Fit to all parameters.
;oplot,x,f,psym=1                           ; Use '+' to plot fitted values.
;oplot,xv,gaussian(xv,par=p)                ; Plot fitted function.
;help,p,/structure                          ; Display new parameter values.
;
;names =tag_names(p)                        ; Obtain parameter names.
;p.a2 = 0                                   ; set quadratic term to 0.
;names = names([0,1,2,3,4])                 ; Choose a subset of parameters.
;print,names                                ; Display subset of names
;fit,x,y,func='gaussian',par=p,names=names  ; Fit to subset.
;
;   Please Note:  Typically the initial guess for parameters must be reasonably
;   good, otherwise the routine will not converge.  In this example the data
;   was selected so that the default parameters would converge.
;
;The following functions can be used with FIT:
;   "gaussian", "polycurve", "power_law", "exponential", "gauss2", "igauss"
;
;KNOWN BUGS:
;   Do NOT trust the P_SIGMA Values (uncertainty in the parameters) if the
;   the value of flambda gets large. I believe
;   That some error (relating to flambda) was carried over from CURVEFIT. -Davin
;
;MODIFICATION HISTORY:
;       Function adapted from CURVEFIT Written, DMS, RSI, September, 1982
;       and last modified by Mark Rivers, U. of Chicago, Febuary 12, 1995.
;       Davin Larson, U of California, November 1995, MAJOR MODIFICATIONS:
;           - Changed FUNCTION_NAME to a function (instead of procedure) that
;             accepts a structure to hold the parameters.  This makes the usage
;             much more user friendly, and allows a subset of parameters to
;             be fit.
;           - Allowed vectors and recursively searched structures to be fit as well.
;           
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2020-04-10 15:18:30 -0700 (Fri, 10 Apr 2020) $
; $LastChangedRevision: 28548 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/fitting/fit.pro $
;           
;           
;-

pro fit, x, yt, $
          FUNCTION_NAME = Function_Name, $
          weight = w,  $
          dy     =dy,  $
          error_factor = error_fac, $
          parameters = params, $
          names = p_names,  $
          p_values = a, $
          p_sigma  = sigma, $
          p_limits = p_limits, $
          fullnames = fullnames, $
          itmax=itmax, iter=iter, tol=tol, chi2=chi2, $
          maxprint=maxprint, $
          noderivative=noderivative, $
          logfit = logfit, $
          debug = debug, $
          testname = testname, $
          minresolution = minres, $
          pre_result = pre_result, $
          result = result, $
          fitvalues = fitvalues, $
          overplot = overplot, $
          silent = silent, $
          verbose = verbose,  $
          summary = summary, $
          qflag = qflag          ;added ajh

       common fit_com, function_name_com,b,c,d,e
       str_element,params,'func',function_name_com
       if keyword_set(function_name) then function_name_com=function_name
       if not keyword_set(function_name_com) then function_name_com="FUNC"

       logf = keyword_set(logfit)
       fitvalues = 0
       result = 0
       qflag = 0                ;added ajh
       chisqr = !values.f_nan


; SET ALL DEFAULTS:
       ;Name of function to fit

       if n_elements(tol) eq 0 then tol = 1.e-6     ;Convergence tolerance
       if n_elements(itmax) eq 0 then itmax = 20    ;Maximum # iterations
       chi2= !values.f_nan

       ;derstr +="  parameter names= '"+string(strupcase(p_names),/print)+"'"

       ;check for derivative option:
       if n_elements(NODERIVATIVE) eq 0 then begin
           wh = where(routine_info(/functions) eq strupcase(function_name_com), compiled)
           if compiled eq 0 then resolve_routine,/is_function,function_name_com
           args = routine_info(function_name_com,/funct,/param)
           kw_args = strmid(args.kw_args,0,4)
           wh = where((kw_args eq 'PDER') or (kw_args eq 'P_NA'),c)
           NODERIVATIVE = c ne 2
       endif

       if keyword_set(silent) then verbose = 0

       derstr = "FUNCTION= '"+strupcase(function_name_com)+"'   "
       derstr +='Partial derivatives computed '+ [ 'analytically','numerically' ]
       if keyword_set(dy) then derstr += ' (weighted fit)'
       printdat,p_names,/value,output=str
       dprint,verbose=verbose,dlevel=2,derstr[NODERIVATIVE]+'  '+str

       ; If we will be estimating partial derivatives then compute machine
       ; precision
       if NODERIVATIVE then begin
          res = machar(DOUBLE=1)
          eps = sqrt(res.eps)
       endif


;Get params structure if not defined
       if not keyword_set(params) then $
           yfit = call_function( Function_name_com, param=params)

       type = size(/type,params)
       if type ne 8 then begin
           message,'PARAMETERS must be a structure.'
       endif

       ndat = n_elements(yt)
       if ndat eq 0 then begin
          dprint,dlevel=1,'No data provided. Assuming function is to be minimized'
          w = 1.d
          y =  0d
 ;         return
       endif else begin
         y = yt[*]  
         if keyword_set(error_fac) then dy = error_fac*y
         if keyword_set(dy) then begin
           if logf then w = (y/dy[*])^2 else w=1/(dy[*])^2
         endif
         if logf then y = alog(y)
         if n_elements(w) eq 0 then w = replicate(1.d, n_elements(y) )
       endelse

;       if  0 then begin
;         wh = where(finite(yt),ngood)
;         if ngood ne n_elements(yt) then begin
;           if ngood eq 0 then begin
;             message,/info,'No valid data!'
;             return
;           endif
;           message,/info,'Warning! Invalid data is ignored.'
;;           x = x
;         endif
;       endif


       flambda = 0.001          ;Initial lambda


       if not keyword_set(maxprint) then maxprint = 10
       nterms_last = 0
       nformat='(a4,40(" ",a11))'
       gformat='(a4,40(" ",g11.4))'
       vformat='(i3,":",20(" ",g11.4))'
       sformat='("Unc:",20(" ",g11.4))'

       params_0 = params
       xfer_parameters,params,p_names,a,fullnames=fullnames,num_p=nterms,/struct_to_array
       if nterms eq 0 then begin
         dprint,'No parameters to fit'
         qflag = 6
         goto , done
       endif

       if  keyword_set(p_limits) then begin
          xfer_parameters,p_limits[0],p_names,a_min,/struct_to_array
          xfer_parameters,p_limits[1],p_names,a_max,/struct_to_array
          a = a_min > a < a_max
          xfer_parameters,params,p_names,a,/array_to_struct
          dprint,dlevel=3,'LLIM',0.,a_min,format = gformat  ;  'Limiting parameter range'
          dprint,dlevel=3,'ULIM',0.,a_max,format = gformat  ;  'Limiting parameter range'
       endif else begin
          a_min = replicate( -!values.d_infinity, nterms)
          a_max = replicate(  !values.d_infinity, nterms)
          p_min= params
          xfer_parameters,p_min,p_names,a_min,/array_to_struct
          p_max= params
          xfer_parameters,p_max,p_names,a_max,/array_to_struct
          p_limits = [p_min,p_max]
      endelse

       for iter = 1, itmax do begin   ; Iteration loop
          xfer_parameters,params,p_names,a,fullnames=fullnames,num_p=nterms,/struct_to_arr

;          pder = dblarr(n_elements(y),nterms)
          if keyword_set(NODERIVATIVE) then begin  ;  Evaluate function and estimate partial derivatives
            yfit = (call_function( Function_name_com, x, param=params))[*]
            ndat = n_elements(yfit)
            pder = dblarr(ndat,nterms)
            if logf then yfit = alog(yfit)
            xfer_parameters,params,p_names,a,/struct_to_array
            for term=0, nterms-1 do begin
              p = a       ; Copy current parameters
              ; Increment size for forward difference derivative
              inc = eps * abs(p[term])
              if (inc eq 0.) then inc = eps
              if keyword_set(minres) then inc = inc > minres
              p[term] = p[term] + inc
              tparams = params
              xfer_parameters,tparams,p_names,p,/array_to_struct
              yfit1 = (call_function( Function_name_com, x, param=tparams))[*]
              if logf then yfit1 = alog(yfit1)
              pder[*,term] = (yfit1-yfit)/inc
            endfor
          endif else begin       ; The user's procedure will compute partial derivatives
            pder = dblarr(ndat,nterms)
            yfit = (call_function(Function_name_com, x, param=params, p_na=fullnames,pder = pder))[*]
            if logf then begin
              pder = pder / (yfit # replicate(1.,nterms) )
              yfit = alog(yfit)
            endif
            xfer_parameters,params,p_names,a,/struct_to_array
          endelse

          mp = (nterms < maxprint)-1
          if nterms ne nterms_last then $
            dprint,verbose=verbose,dlevel=2,'Iter','Chi',fullnames[0:mp],'Lambda',format=nformat
          nterms_last = nterms

          if not keyword_set(testname) then begin
            pderthresh = 1e-12
            pdernz = total(/nan,abs(pder) gt pderthresh,1) gt 0
            wpdernz = where(pdernz,npdernz)
            wpderaz = where(pdernz eq 0,nz)
            if npdernz ne nterms then begin
              dprint,verbose=verbose,'Warning: Not fitting the following parameters: ',fullnames[wpderaz],dlevel=1
            endif
          endif else begin
             wpdernz=indgen(nterms)
             npdernz = nterms
          endelse
          if npdernz le 0 then begin
             dprint,verbose=verbose,dlevel=0,'No free parameters to fit!'
             qflag = 5
             chisq1 = !values.f_nan
             goto, done
          endif

          nfree = ndat - npdernz ; Degrees of freedom
          if nfree lt 0 then begin
            dprint,verbose=verbose,dlevel=0, 'Not enough data points.'
            nfree = .25d  ; ???
          endif
          if nfree eq 0 then begin
            dprint,verbose=verbose,dlevel=1,'Warning: No Degrees of Freedom'
            nfree = 0.5d
          endif

          diag = lindgen(npdernz)*(npdernz+1) ; Subscripts of diagonal elements

;         Evaluate alpha and beta matricies.
          ds = ((y-yfit)*w)[*]
          wf = where(finite(ds),/null)
          ds = ds[wf]
          pder = pder[wf,*]
          if npdernz gt 1 then beta = ds # pder[*,wpdernz]   else  beta = [total(ds * pder[*,wpdernz],/nan)]
          if n_elements(yt) eq 0 then w_pder = 1 else w_pder = w[*] # replicate(1.,npdernz)
          alpha = transpose(pder[*,wpdernz]) # (w_pder * pder[*,wpdernz])
          chisq1 = total(/nan,w*(y-yfit)^2)/nfree ; Present chi squared.

          dprint,verbose=verbose,dlevel=2,strtrim(iter,2),sqrt(chisq1),a[0:mp],flambda,format=gformat

          ; If a good fit, no need to iterate
          all_done = chisq1 lt total(/nan,abs(y))/1e7/nfree
;
;         Invert modified curvature matrix to find new parameters.
          flambda=1e-5
          tparams = params
          repeat begin
             flambda = flambda*10.
             c = sqrt(alpha[diag] # alpha[diag])
             array = alpha/c
             array[diag] = array[diag]*(1.+flambda)
;             if nterms gt 1 then array = invert(array) $
;             else array = 1/array
             array = invert(array)
             b = a
             b[wpdernz] = a[wpdernz]+ array/c # transpose(beta) ; New params
             b = a_min >  b  < a_max         ; limit range of parameters
             if ~total(finite(b)) then begin
                dprint,'Bad Parameters'
             endif
             xfer_parameters,tparams,p_names,b,/array_to_struct
             yfit = (call_function( Function_name_com, x, param=tparams))[*]
             if logf then yfit = alog(yfit)
             chisqr = total(/nan,w*(y-yfit)^2)/nfree         ; New chisqr
             if finite(chisqr) eq 0 then begin
               qflag = 4                   ;added ajh
               dprint,dlevel=0,verbose=verbose,'Invalid Data or Parameters in function '+function_name_com+' Aborting'
               dprint,dlevel=0,verbose=verbose,iter,sqrt(chisq1),b[0:mp],format=vformat
               ;   dprint,'Determinant=',determ(array,/check)
               if keyword_set(debug) then stop
               goto,done2
             endif
             if flambda ge 1e5 then  begin
               qflag = 2                   ;added ajh
               dprint,dlevel=1,verbose=verbose,'flambda too large (',flambda,') for ',function_name_com,' Aborting'
               dprint,dlevel=1,verbose=verbose,iter,sqrt(chisq1),b[0:mp],format=vformat
               ;   print,'Determinant=',determ(array,/check)
               if keyword_set(debug) then stop
               goto,done2
             endif

;        if all_done then goto, done
             if keyword_set(debug) then stop
          endrep until chisqr le chisq1

;          flambda = flambda/10.  ; Decrease flambda by factor of 10
          a=b                     ; Save new parameter estimate.
          params = tparams
          if ((chisq1-chisqr)/chisq1) le tol then goto,done  ; Finished?
       endfor                        ;iteration loop

       qflag = 3                ;added ajh
       dprint,verbose=verbose,dlevel=1, 'Failed to converge'

done2:
done:
       sigma = replicate(!values.d_nan,nterms)
       if npdernz ge 1 then begin
         sigma[wpdernz] = sqrt(array[diag]/alpha[diag] * sqrt(chisqr)) ; Return sigma's        
       endif
;       sigma[wpdernz] = sqrt(array[diag]/alpha[diag] * (1+flambda)) ; Return sigma's
;       sigma[wpdernz] = sqrt((invert(alpha/c))[diag]/alpha[diag] ) ; Return sigma's
       chi2 = float(chisq1)                          ; Return chi-squared
;       IF iter NE itmax+1 THEN qflag = 1 ;added ajh
       dprint,verbose=verbose,dlevel=1,strtrim(iter+1,2),sqrt(chi2),a[0:mp],flambda,format=gformat
       dprint,verbose=verbose,dlevel=2,'Unc:',sqrt(chi2),sigma[0:mp],flambda,format=gformat
       dprint,verbose=verbose,dlevel=4,'Chi2 =',chi2,'  flambda =',flambda
       if logf then yfit = exp(yfit)
       fitvalues = yfit
       if arg_present(summary) then begin
          summary ={ p_names:fullnames, p_values:a, p_sigma:sigma, chi:sqrt(chi2), nterms:nterms, nparamsnz:nparamsnz ,its:iter, qflag:qflag}
       endif
       if arg_present(result) then begin
          nul_params = fill_nan(params)
          dparams = nul_params
          xfer_parameters,dparams,p_names,sigma,/array_to_struct
          ;pre_struct = {time:systime(1), index:0l }
          result = { par:params,  dpar:dparams,  chi:sqrt(chi2),  nterms:nterms, npdernz:npdernz ,its:iter , qflag:qflag ,ndat:ndat}
          if keyword_set(pre_result) then result = create_struct(pre_result,result)
          if qflag ge 4 then begin
              result.par = nul_params
              result.dpar = nul_params
          endif
       endif
       if keyword_set(overplot) then begin
          xv = dgen()
          oplot,xv,call_function(Function_name_com,xv, param=params)
       endif
       return
END

