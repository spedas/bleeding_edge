;+
;NAME: barrel_sp_fitgrid3.pro
;DESCRIPTION: BARREL low-level spectral folding routine, method 3
;             ( two file-based spectral shapes, single drm)
;
;REQUIRED INPUTS:
;subspec   background subtracted count spectrum, cts/keV
;subspecerr    its error bars
;modelspec1    first spectral component (at all energies)
;modelspec2    second spectral component 
;drm       response matrix for correct payload altitude and chosen PID
;          of electrons
;phmean    energy bin centers for the photons dimension
;phwidth   energy bin widths for the photons dimension
;usebins   which energy channels to use in minimizing chisquare
;startnorm1    Starting value of normalization of 1st component
;startnorm2    Starting value of normalization of 2nd component
;points    Number of points on each side of starting values to test
;scaling   Range around the starting values to test -- for example,
;          points=2 and scaling=1.5 means that the values tested are
;          x/1.5, x/1.25, x, x*1.25, x*1.5
;
;OPTIONAL INPUTS:
;none
;
;OUTPUTS:
;bestnorm1  best-fit value of the first normalization
;bestnorm2  best-fit value of the second normalization
;bestnorm1n   array location of bestnorm1
;bestnorm2n   array location of bestnorm2
;modvals1          values of the fit function at the centers of the energy bins (first component) 
;modvals2          values of the fit function at the centers of the energy bins (second component) 
;chiarray   array of chi-square values
;bestchi    lowest chi-square value
;norm1array   array of first normalization parameter values
;norm2array   array of second normalization parameter values
;
;CALLS:  None.
;
;STATUS: Passed early test on artificial data
;
;TO BE ADDED: N/A
;
;REVISION HISTORY:
;First version with release 2.3, 8/26/12
;               11/12/13 insist on only one value of bestparn, etc.
;
;-

pro barrel_sp_fitgrid3, subspec, subspecerr, modelspec1, modelspec2, drm, phmean, phwidth, usebins, startnorm1,$
      startnorm2, points, scaling, bestnorm1, bestnorm2, bestnorm1n, bestnorm2n, modvals1, modvals2, $
      chiarray, bestchi, norm1array, norm2array 

;Set up the vectors of values for parameters and normalizations:
pts = 2*points + 1
norm1vector  = [findgen(pts)-points]*scaling[0]/points*startnorm1 + startnorm1
norm2vector = [findgen(pts)-points]*scaling[1]/points*startnorm2 + startnorm2

;Set up the output arrays:
norm1array = fltarr(pts,pts)
norm2array = fltarr(pts,pts)
chiarray = fltarr(pts,pts)

;Initialize best chi-square as something awful:
bestchi = 1.d10

;Loop away!

for j = 0, pts-1 do begin         ;over normalization 1
  foldvals1 =  reform( (norm1vector[j]*modelspec1*phwidth) # drm)

  for i = 0, pts-1 do begin         ;over normalization 2
   foldvals2 =  reform( (norm2vector[i]*modelspec2*phwidth) # drm)

   ;Test different normalizations against the data:

   norm1array[j,i] = norm1vector[j]
   norm2array[j,i] = norm2vector[i]
   chiarray[j,i] = total ( ( (subspec[usebins] - (foldvals1[usebins]+foldvals2[usebins])) / subspecerr[usebins] )^2 )

  endfor
endfor

;Find the best fit and set output parameters:

bestchi = min(chiarray)
w = (where(chiarray EQ bestchi))[0]
bestnorm1 = norm1array[w]
bestnorm2 = norm2array[w]
bestnorm1n = (where(norm1vector EQ bestnorm1))[0] - points
bestnorm2n = (where(norm2vector EQ bestnorm2))[0] - points
modvals1 = bestnorm1 * reform( (modelspec1*phwidth) # drm)
modvals2 = bestnorm2 * reform( (modelspec2*phwidth) # drm)

end



