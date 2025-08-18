;+
;NAME: barrel_sp_fold.pro
;DESCRIPTION: BARREL top-level spectral folding routine
;
;REQUIRED INPUTS:
;ss        spectrum structure
; 
;OPTIONAL INPUTS:
;method    1 = single-parameter spectrum, single drm, use "model"
;          2 = single fixed (file input) spectrum, single drm
;          3 = double fixed (file input) spectrum, single drm
;          4 = single-parameter spectrum, dual drm, use "model"
;          5 = single fixed (file input)) spectrum, dual drm
;          6 = double fixed (file input)) spectrum, dual drm
;model     spectral model of electron spectrum (default is exponential)
;          1 = exponential
;          2 = monoenergetic
;fitrange  energy range to use for fitting (regardless of full range
;          of ebins) (this is a vector [start,end]
;maxcycles Maximum number of times to try rescaling range for fit parameters
;quiet     Don't make graphs + screen output
;verbose   show some debugging info as fits go along
;modlfile        Filename for inputting a handmade model component
;secondmodlfile  Filename for inputting a second handmade model component
;bkg_renorm      match background to source > 3 MeV before subtracting
;systematic_error_frac    Fraction of bkg-subtracted value to be added
;                         in quadrature with statistical errors.
;                         Typical value might be 0.1 (10%)
;
;OUTPUTS (written into ss structure):
;params            best fit parameters
;param_ranges      ranges on best fit parameters (1 sigma) (2x2 array)
;chisquare         chi-square (not reduced)
;dof               degrees of freedom associated with chisquare
;modvals           values of the fit function at the centers of the energy bins
;
;CALLS:
;edge_products(), (imported from solarsoft), barrel_sp_fold_m1
;through barrel_sp_fold_m6
;
;NOTES: 
;
;STATUS: Tested for methods 1&4 on artificial data.
;
;TO BE ADDED:
;     Support for other spectral models
;     Support for single + summed fixed spectra (from file), varying normalization
;
;REVISION HISTORY:
;Version 1.0 DMS 7/18/12 -- split out from barrel_folding as the new top layer
;                7/24/12 -- fixed minimum of plot to account for
;                           possible values << 1 (fixed threshold for minimum
;                           of plot changed to 1.d-6 instead of 0.5
;                           when there are real values that are too low)
;          2.3   8/19/12 -- added support for method 3
;          2.5   1/5/13 --  rewrite to support new general
;                           spectroscopy structure ss
;          2.6   5/29/13 -- adding support for L2 MSPC files (already cts/keV)
;          2.8   7/8/13  -- remove call to idl_screen_graphics()
;          3.0   9/9/13  -- set ss.numparams here instead of upstream at barrel_sp_make()
;          3.2   10/29/13 - Print total, background, and net count
;                           rates just before proceeding to fit
;                11/12/13 - plot data before fitting in case fit crashes
;                11/12/13 - bkg_renorm defaults to zero, not 1.
;          3.4   4/17/14  - Report counts & electron flux for best fit.
;                           Keep track of best-fit model in electron
;                           space and save it and print the total.
;                           Fixed bug that would use bkg_renorm
;                           regardless of setting.
;                           Make explicit that method 4 isn't ready yet.
;          3.5   8/12/14    Option for adding a fraction of the
;                           background-subtracted spectrum as error
;                           This keeps very small error bars at low
;                           energies from over-dominating the fit, and
;                           represents, e.g., systematic uncertainties
;                           in the response matrix.
;          3.6 2/12/15      pass altitude to _m1 for initial param. guess
;          9/23/15          Change x-axes for plots to [10,1000] always
;                           broadened range of default ratio plot
;                           residuals=2 counts only pts in fit range.
;-


pro barrel_sp_fold, ss,  maxcycles=maxcycles, quiet=quiet, verbose=verbose, bkg_renorm=bkg_renorm,$
      method=method, model=model, fitrange=fitrange, modlfile=modlfile, $
      secondmodlfile=secondmodlfile,residuals=residuals,systematic_error_frac=systematic_error_frac

if not keyword_set(maxcycles) then maxcycles = 30
if not keyword_set(method) then method=1
if not keyword_set(model) then model=1
if not keyword_set(fitrange) then fitrange=[110., 2500.]
if not keyword_set(residuals) then residuals=1
ss.method = method
ss.model = model
ss.fitrange = fitrange
if not keyword_set(bkg_renorm) then bkg_renorm=0
ss.bkg_renorm=bkg_renorm
if keyword_set(modlfile) then ss.modlfile = modlfile
if keyword_set(secondmodlfile) then ss.secondmodlfile = secondmodlfile

;CHECK CONSISTENCY OF INPUT PARAMETERS
if (method GE 4) and (ss.drm2type eq -1) then $
       message, 'BARREL_SP_FOLD: Method > 3 requires a second response matrix (drm2).  This is not yet available.'
if (method ne 1 and method ne 4 and (ss.modlfile eq "")) then $
       message, 'BARREL_SP_FOLD: This method requires a filename for an input model (modlfile)'
if (method eq 3 or method eq 6 and (ss.modlfile eq "" or ss.secondmodlfile eq "")) then $
       message, 'BARREL_SP_FOLD: This method requires two filenames for input models (modlfile, secondmodlfile)'

;Create energy bin centers and widths, find bins to use in fit:
edge_products, ss.ebins, mean=ctmean, width=ctwidth
edge_products, ss.elebins, mean=elmean, width=elwidth

usebins = where(ctmean GE fitrange[0] and ctmean LE fitrange[1])

;Subtract background & calculate error bars on subtracted spectrum -- cts/keV:
srcspec = ss.srcspec/ss.srclive 
bkgspec = ss.bkgspec/ss.bkglive 
srcspecerr = ss.srcspecerr/ss.srclive
bkgspecerr = ss.bkgspecerr/ss.bkglive
renorm = 1.
if bkg_renorm then begin 
   ;normalize bkg so that it matches src at high energies.
   ;med.spectra will only go up to 4 MeV, so we are keeping a
   ;band at least 750 keV up to that, even though the hardest
   ;drep might put a few counts into the bottom of this range.

   w=where(ctmean GT 3250. and ctmean LT 6750.)
   renorm = total( srcspec[w] ) / total( bkgspec[w] )
   if not keyword_set(quiet) then print,'Background renormalization factor: ',renorm   
endif

bkgspec = bkgspec * renorm
subspec = srcspec - bkgspec
subspecerr = sqrt( srcspecerr^2. + (bkgspecerr*renorm)^2 )
if keyword_set(systematic_error_frac) then $
   subspecerr = sqrt(subspecerr^2 + (subspec*systematic_error_frac)^2)
print,'Total count rate:            ',total(srcspec*ctwidth),' c/s'
print,'Background count rate:       ',total(bkgspec*ctwidth),' c/s'
print,'Net count rate in fit range: ',total(subspec[usebins]*ctwidth[usebins]),' c/s'
print,'Net count rate total:        ',total(subspec*ctwidth),' c/s'

if not keyword_set(quiet) then begin

    ;;plot the data points:
    window,xsize=500,ysize=800
    loadct2,13
    !p.multi=[0,1,3]

    plot,ctmean,srcspec,/xlog,/ylog,xrange=[10,10000],$
         yrange=[max([1.d-2,min(srcspec)/1.5]),max(srcspec)*1.5],$
         xtitle='Energy, keV',ytitle='counts/keV/s',psym=3,$
         position=[0.12,0.65,0.97,0.98],charsize=2
    oplot,ctmean,bkgspec,col=2
    if renorm NE 1. then oplot,ctmean,bkgspec/renorm,col=4
    for i=0, n_elements(subspec)-1 do begin
         oplot,[ctmean[i],ctmean[i]],$
               [srcspec[i]-srcspecerr[i],srcspec[i]+srcspecerr[i]], psym=0
         oplot,[ctmean[i]-ctwidth[i]/2.,ctmean[i]+ctwidth[i]/2.],$
               [srcspec[i],srcspec[i]], psym=0
    endfor

endif

;Do the actual fitting according to the chosen method:
case method of
1: barrel_sp_fold_m1, subspec, subspecerr, model, ss.drm, ss.elebins, elmean, elwidth, ctwidth, ctmean, usebins, maxcycles, $
         params, param_ranges, elecmodel, modvals, chisquare, dof, ss.altitude, quiet=quiet, verbose=verbose
2: barrel_sp_fold_m2, subspec, subspecerr, modlfile, ss.drm, ss.elebins, elmean, elwidth, ctwidth, usebins, maxcycles, $
         params, param_ranges, elecmodel, modvals, chisquare, dof, quiet=quiet, verbose=verbose
3: barrel_sp_fold_m3, subspec, subspecerr, modlfile, secondmodlfile, ss.drm, ss.elebins, elmean, elwidth, ctwidth, usebins, maxcycles,  $
         params, param_ranges, elecmodel, modvals, secondmodvals, chisquare, dof, quiet=quiet, verbose=verbose
4: barrel_sp_fold_m4, subspec, subspecerr, model, ss.drm, ss.drm2, elmean, elwidth, ctwidth, usebins, maxcycles, $
         params, param_ranges, elecmodel, modvals, chisquare, dof, quiet=quiet, verbose=verbose
endcase    

numparams=n_elements(params)
ss.numparams=numparams

;Fill in the fit results in the structure:
ss.params[0:numparams-1] = params
ss.param_ranges[0:numparams-1,*] = param_ranges
ss.modvals = modvals
if (method eq 3 or method eq 6) then ss.secondmodvals=secondmodvals
ss.chisq = chisquare
ss.chi_dof = dof
ss.subspec = subspec
ss.subspecerr = subspecerr
ss.elecmodel = elecmodel

;Show results and make a plot if requested:
if not keyword_set(quiet) then begin
    print,'Best normalization and range:          ',params[0],$
       '  (',param_ranges[0,0],param_ranges[1,0],')  '
    if (method EQ 2) then begin
        print,'(This is relative to the input model file and gives e-/cm2/s/keV'
        print,'When multiplied by it.)'
    endif
    if (method EQ 3 or method EQ 6) then $
    print,'Best second normalization and range:          ',params[1],$
       '  (',param_ranges[0,1],param_ranges[1,1],')  '
    if (method EQ 1 or method EQ 4) then $
    print,'Best spectral parameter and range:     ',params[1],$
       '  (',param_ranges[0,1],param_ranges[1,1],')  '
    if (method EQ 5) then $
      print,'Best drm interpolation and range:          ',params[1],$
       '  (',param_ranges[0,1],param_ranges[1,1],')  '
    if (method EQ 4 or method EQ 6) then $
      print,'Best drm interpolation and range:          ',params[2],$
       '  (',param_ranges[0,2],param_ranges[1,2],')  '
   
    print,'Chi-square, DOF, reduced, probability: ',chisquare,dof,chisquare/dof,1.-chisqr_pdf(chisquare,dof)
    
    ;sum model components if necessary:
    if method EQ 3 or method EQ 6 then modv=modvals+secondmodvals else modv=modvals

    modelrate_fitrange = total( modv[usebins]*ctwidth[usebins] )
    modelrate_all = total( modv*ctwidth )

    print,'Count rate from model, within fit range and total: ',$
          modelrate_fitrange, modelrate_all, ' c/s'

    print,'Model electrons/cm2/s, total: ', total ( ss.elecmodel*elwidth )

    yrangemin = max([1.d-6,min(subspec)/1.5])

    plot,ctmean,subspec,/xlog,/ylog,xrange=[10,10000],$
         yrange=[yrangemin,max(subspec)*1.5],$
         xtitle='Energy, keV',ytitle='counts/keV/s',psym=3,$
         position=[0.12,0.3,0.97,0.6],charsize=2    
    ;;overplot the model:
    if method EQ 3 or method EQ 6 then begin
          oplot,ctmean,modvals,color=4,psym=0
          oplot,ctmean,secondmodvals,color=3,psym=0
          oplot,ctmean,modvals+secondmodvals,color=2,psym=0
    endif else   oplot,ctmean,modvals,color=3,psym=0

    ;;What you will really see is the error bars.
    ;;Plot data points that were not used in a different color:
    for i=0, n_elements(subspec)-1 do begin
       if ctmean[i] GE fitrange[0] and ctmean[i] LE fitrange[1] then col=0 else col=6
         oplot,[ctmean[i],ctmean[i]],$
               [max([subspec[i]-subspecerr[i],yrangemin]),subspec[i]+subspecerr[i]], psym=0, color=col
         oplot,[ctmean[i]-ctwidth[i]/2.,ctmean[i]+ctwidth[i]/2.],$
               [subspec[i],subspec[i]], psym=0, color=col
    endfor

    ;Show the residuals in difference format:

    case residuals of
    2: begin  ;Plot ratio with large scale visible
       plot,ctmean,subspec/modv,psym=3,/xlog,xrange=[10,10000],yrange=[.01,100.],/ylog,$
          xtitle='Energy, keV',ytitle='data/model',position=[0.12,0.05,0.97,0.20],charsize=2

       for i=0, n_elements(subspec)-1 do begin
          if ctmean[i] GE fitrange[0] and ctmean[i] LE fitrange[1] then col=0 else col=6
            oplot,[ctmean[i]-ctwidth[i]/2.,ctmean[i]+ctwidth[i]/2.],$
               [subspec[i]/modv[i],subspec[i]/modv[i]], psym=0, color=col
       endfor
    end

    3: begin  ;Plot differences on linear scale (usually favors low-energy points)
       plot,ctmean,subspec-modv,psym=3,/xlog,xrange=[10,10000],$
           xtitle='Energy, keV',ytitle='data-model',position=[0.12,0.05,0.97,0.23],charsize=2    

       for i=0, n_elements(subspec)-1 do begin
          if ctmean[i] GE fitrange[0] and ctmean[i] LE fitrange[1] then col=0 else col=6
            mindraw=max( [min(subspec-modv),subspec[i]-modv[i]-subspecerr[i]] )
            maxdraw=min( [max(subspec-modv),subspec[i]-modv[i]+subspecerr[i]] )
            oplot,[ctmean[i],ctmean[i]],[mindraw,maxdraw], psym=0, color=col
            oplot,[ctmean[i]-ctwidth[i]/2.,ctmean[i]+ctwidth[i]/2.],$
               [subspec[i]-modv[i],subspec[i]-modv[i]], psym=0, color=col
       endfor
    end

    4: begin  ;Plot ratio on a large scale for bad situations
       plot,ctmean,subspec/modv,psym=3,/xlog,xrange=[10,10000],charsize=2,$
           xtitle='Energy, keV',ytitle='data/model',position=[0.12,0.05,0.97,0.23],yrange=[0.33333,3.]

       for i=0, n_elements(subspec)-1 do begin
          if ctmean[i] GE fitrange[0] and ctmean[i] LE fitrange[1] then col=0 else col=6
            oplot,[ctmean[i]-ctwidth[i]/2.,ctmean[i]+ctwidth[i]/2.],$
               [subspec[i]/modv[i],subspec[i]/modv[i]], psym=0, color=col
       endfor
    end

    5: begin  ;Plot ratio of subtracted to total (where smallish)
       plot,ctmean,subspec/srcspec,psym=3,/xlog,xrange=[10,10000],charsize=2,$
           xtitle='Energy, keV',ytitle='subtracted/total',position=[0.12,0.05,0.97,0.23],yrange=[-.5,.5]

       for i=0, n_elements(subspec)-1 do begin
          if ctmean[i] GE fitrange[0] and ctmean[i] LE fitrange[1] then col=0 else col=6
            oplot,[ctmean[i]-ctwidth[i]/2.,ctmean[i]+ctwidth[i]/2.],$
               [subspec[i]/srcspec[i],subspec[i]/srcspec[i]], psym=0, color=col
       endfor
    end

    else: begin  ;default is ratio with a limited scale
       plot,ctmean,subspec/modv,psym=3,/xlog,xrange=[10,10000],charsize=2,/ylog,$
           xtitle='Energy, keV',ytitle='data/model',position=[0.12,0.05,0.97,0.23],yrange=[0.5/1.1, 2.0*1.1]

       for i=0, n_elements(subspec)-1 do begin
          if ctmean[i] GE fitrange[0] and ctmean[i] LE fitrange[1] then col=0 else col=6
            oplot,[ctmean[i]-ctwidth[i]/2.,ctmean[i]+ctwidth[i]/2.],$
               [subspec[i]/modv[i],subspec[i]/modv[i]], psym=0, color=col
       endfor
    end

 endcase

 endif

end


