;+
;NAME: barrel_sp_fitgrid4.pro
;DESCRIPTION: BARREL low-level spectral folding routine for method 4
;   (analytic spectral function, dual DRMs)
;
;REQUIRED INPUTS:
;subspec   background subtracted count spectrum, cts/keV
;subspecerr    its error bars
;model     spectral model of electron spectrum (default is exponential)
;          1 = exponential
;          2 = monoenergetic
;drm       response matrix for correct payload altitude and chosen PID
;          of electrons
;drm2      second response matrix; interpolation between these two is
;          the last fit parameter
;phmean    energy bin centers for the photons dimension
;phwidth   energy bin widths for the photons dimension
;usebins   which energy channels to use in minimizing chisquare
;startpar  Starting value of spectral parameter
;startnorm Starting value of spectral normalization
;startdrm  Starting value of drm parameter
;points    Number of points on each side of starting values to test
;scaling   Range around the starting values to test -- for example,
;             points=2 and scaling=1.5 means that the values tested are
;             x/1.5, x/1.25, x, x*1.25, x*1.5
;             scaling[0]=norm, scaling[1]=spectral parameter,
;             scaling[2]=drm and works differently (direct value
;             rather than fractional)
;OPTIONAL INPUTS:
;none
;
;OUTPUTS:
;bestpar   best-fit value of the spectral parameter
;bestnorm   best-fit value of the normalization parameter
;bestdrm    best-fit value of the drm interpolation
;bestparn   array location of bestpar
;bestnormn  array location of bestnorm
;bestdrmn   array location of bestdrm
;modvals   values of the best-fit function at the data bin centers
;chiarray   array of chi-square values
;bestchi    lowest chi-square value
;pararray   array of spectral parameter values
;normarray  array of normalization parameter values
;drmarray   array of drm parameter values
;
;CALLS:  None.
;
;STATUS: not yet tested
;
;TO BE ADDED: N/A
;
;REVISION HISTORY:
;Version 1.0 DMS 7/12/12 based on barrel_fitgrid2
;Version 2.0 DMS 7/18/12 added "usebins" -- functionality was missing
;                        before -- renamed "bestvals" to "modvals"
;                        "scaling" becomes an array instead of 3
;                        variables with different names
;Version 2.1 DMS 7/24/12 Add code to omit unphysical drm scale regions
;               11/12/13 insist on only one value of bestparn, etc.
;-

pro barrel_sp_fitgrid4, subspec, subspecerr, model, drm, drm2, phmean, phwidth, usebins, startpar, $
      startnorm, startdrm, points, scaling, bestpar, bestnorm, bestdrm, $
      bestparn, bestnormn, bestdrmn, modvals, chiarray, bestchi, pararray, normarray, $
      drmarray,debug=debug

;Set up the vectors of values for parameters and normalizations:
pts = 2*points + 1
normvector = [findgen(pts)-points]*scaling[0]/points*startnorm + startnorm
parvector  = [findgen(pts)-points]*scaling[1]/points*startpar + startpar
drmvector  = [findgen(pts)-points]*scaling[2]/points + startdrm

;Rescale drm vector to omit unphysical regions (< 0, > 1):
drmlow = where(drmvector LT 0., nlow)
drmhigh = where(drmvector GT 1., nhigh)
drmmin = min(drmvector)
drmmax = max(drmvector)
if nlow GT 0 then drmmin = 0.
if nhigh GT 0 then drmmax = 1.
if (nlow GT 0 or nhigh GT 0) then drmvector = drmmin + (drmmax-drmmin)*findgen(pts)/(1.*(pts-1.))

;Set up the output arrays:
pararray = fltarr(pts,pts,pts)
normarray = fltarr(pts,pts,pts)
drmarray = fltarr(pts,pts,pts)
chiarray = fltarr(pts,pts,pts)

;Initialize best chi-square as something awful:
bestchi = 1.d10

;Loop away!

for k=0, pts-1 do begin  ;over drm

  thisdrm = drm*drmvector[k] + drm2*(1.0 - drmvector[k])

  for j = 0, pts-1 do begin         ;over spectral parameter

   ;Set up the model, photons/bin:
   if model EQ 1 then begin
         vals = exp(-phmean/parvector[j])*phwidth
   endif else message, 'BARREL_SP_FITGRID: Only exponential spectrum is currently supported.'

   ;Fold through response matrix
   foldvals = reform(vals # thisdrm)

   ;Test different normalizations against the data:
   for i = 0, pts-1 do begin      
         normarray[i,j,k] = normvector[i]
         pararray[i,j,k] = parvector[j]
         drmarray[i,j,k] = drmvector[k]
         chiarray[i,j,k] = total ( ( (subspec[usebins] - normvector[i]*foldvals[usebins])/subspecerr[usebins])^2 )
   endfor

  endfor

endfor

;Find the best fit and set output parameters:

bestchi = min(chiarray)
w = (where(chiarray EQ bestchi))[0]
bestpar = pararray[w]
bestnorm = normarray[w]
bestdrm = drmarray[w]
bestparn = (where(parvector EQ bestpar))[0] - points
bestnormn = (where(normvector EQ bestnorm))[0] - points
bestdrmn = (where(drmvector EQ bestdrm))[0] - points
drmbest =  drm*bestdrm + drm2*(1.0 - bestdrm)
if model EQ 1 then modvals = bestnorm*reform( (exp(-phmean/bestpar)*phwidth) # drmbest )

end



