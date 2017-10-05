;+
;NAME: barrel_sp_fitgrid2.pro
;DESCRIPTION: BARREL low-level spectral folding routine, method 2
;             (single model file, single drm)
;
;REQUIRED INPUTS:
;subspec   background subtracted count spectrum, cts/keV
;subspecerr    its error bars
;model     spectral model of electron spectrum (default is exponential)
;          1 = exponential
;          2 = monoenergetic
;drm       response matrix for correct payload altitude and chosen PID
;          of electrons
;phmean    energy bin centers for the photons dimension
;phwidth   energy bin widths for the photons dimension
;usebins   which energy channels to use in minimizing chisquare
;startpar  Starting value of spectral parameter
;startnorm Starting value of spectral normalization
;points    Number of points on each side of starting values to test
;scaling   Range around the starting values to test -- for example,
;          points=2 and scaling=1.5 means that the values tested are
;          x/1.5, x/1.25, x, x*1.25, x*1.5
;
;OPTIONAL INPUTS:
;none
;
;OUTPUTS:
;bestpar   best-fit value of the spectral parameter
;bestnorm   best-fit value of the normalization parameter
;bestparn   array location of bestpar
;bestnormn  array location of bestnorm
;modvals    values of the best-fit function at the data bin centers
;chiarray   array of chi-square values
;bestchi    lowest chi-square value
;pararray   array of spectral parameter values
;normarray  array of normalization parameter values
;
;CALLS:  None.
;
;STATUS: Passed early test on artificial data
;
;TO BE ADDED: N/A
;
;REVISION HISTORY:
;Version 1.0 DMS 7/24/12 derived from barrel_fitgrid1
;               11/12/13 insist on only one value of bestparn, etc.
;-

pro barrel_sp_fitgrid2, subspec, subspecerr, modelspec, drm, phmean, phwidth, usebins,$
      startnorm, points, scaling, bestnorm, bestnormn, modvals, $
      chiarray, bestchi, normarray 

;Set up the vectors of values for parameters and normalizations:
pts = 2*points + 1
normvector = [findgen(pts)-points]*scaling[0]/points*startnorm + startnorm

;Set up the output arrays:
chiarray = fltarr(pts)

;Initialize best chi-square as something awful:
bestchi = 1.d10

;Loop away!

foldvals = reform( (modelspec*phwidth) # drm)
for j = 0, pts-1 do $         ;over normalization
         chiarray[j] = total ( ( (subspec[usebins] - normvector[j]*foldvals[usebins])/subspecerr[usebins] )^2 )
normarray = normvector

;Find the best fit and set output parameters:

bestchi = min(chiarray)
w = (where(chiarray EQ bestchi))[0]
bestnorm = normarray[w]
bestnormn = (where(normvector EQ bestnorm))[0] - points
modvals = bestnorm*reform( (modelspec*phwidth) # drm )

end



