;+
;NAME: barrel_sp_fitgrid1.pro
;DESCRIPTION: BARREL low-level spectral folding routine, method 1
;             (analytic spectral model, single drm)
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
;Version 1.0 DMS 6/23/12 as barrel_fitgrid
;Version 2.0 DMS 7/18/12 added "usebins" -- functionality was missing
;                        before -- renamed "bestvals" to "modvals"
;Version 2.4 DMS 8/26/12 added support for monoenergetic spectrum
;                        removed redundant routine ID in "message"
;               11/12/13 insist on only one value of bestparn, etc.
;Version 3.4 DMS 4/17/14 fixed modvals and foldvals to be /chan 
;                        instead of /keV for model=2 (monoenergetic)
;-

pro barrel_sp_fitgrid1, subspec, subspecerr, model, drm, phmean, phwidth, usebins, startpar,$
      startnorm, points, scaling, bestpar, bestnorm, bestparn, bestnormn, modvals, $
      chiarray, bestchi, pararray, normarray 

;Set up the vectors of values for parameters and normalizations:
pts = 2*points + 1
normvector = [findgen(pts)-points]*scaling[0]/points*startnorm + startnorm
parvector  = [findgen(pts)-points]*scaling[1]/points*startpar + startpar
parrange=[min(parvector),max(parvector)]

if model EQ 2 then begin
   ;;Reassign minimum/maximum if they are going to force the fit to go
   ;;out of range (this is particular to the monoenergetic model)
    minpossible = phmean[1]
    w=where(parvector LE minpossible,nl)
    maxpossible = phmean[n_elements(phmean)-2]
    w=where(parvector GE maxpossible,ng)
    if nl GT 0 or ng GT 0 then begin
       parstart = max([minpossible,min(parvector)])
       parend =   min([maxpossible,max(parvector)])
       parvector = findgen(pts)*(parend-parstart)/(1.*pts) + parstart
       print,'rescaled from ',parrange, ' to ',[min(parvector),max(parvector)]
    endif
 endif



;Set up the output arrays:
pararray = fltarr(pts,pts)
normarray = fltarr(pts,pts)
chiarray = fltarr(pts,pts)

;Initialize best chi-square as something awful:
bestchi = 1.d10

;Loop away!

for j = 0, pts-1 do begin         ;over spectral parameter

   ;Set up the model, photons/bin:
   if model EQ 1 then begin
         vals = exp(-phmean/parvector[j])*phwidth
         foldvals = reform(vals # drm)
   endif else if model EQ 2 then begin
      ;;In order to differentiate between different energies within one input
      ;;bin, evaluate the bins to either side, fit a quadratic, and
      ;;interpolate to the exact target energy:
         vals1 = phmean*0.
         vals2 = phmean*0.
         vals3 = phmean*0.
         bin2 = (where( abs(phmean-parvector[j]) eq min(abs(phmean-parvector[j])) ))[0]
         bin1 = bin2 - 1
         bin3 = bin2 + 1
         if bin1 LT 0 or bin3 GT n_elements(phmean)-1 then message, 'Tried energy out of range.'
         vals1[bin1]=1.
         vals2[bin2]=1.
         vals3[bin3]=1.
         foldvals1 = reform(vals1 # drm)
         foldvals2 = reform(vals2 # drm)
         foldvals3 = reform(vals3 # drm)
         foldvals = foldvals2*0.
         for i=0,n_elements(foldvals1)-1 do begin
            y = [foldvals1[i],foldvals2[i],foldvals3[i]]
            x = [phmean[bin1],phmean[bin2],phmean[bin3]]
            r = poly_fit(x,y,2)
            foldvals[i] = r[0] + r[1]*parvector[j] + r[2]*parvector[j]^2
         endfor
;??Are we sure we want to multiply by width?  Is the chi-square done
;/keV or /channel?
         foldvals *= phwidth[bin2]
   endif  else message, 'Only exponential or monoenergetic spectra are currently supported.'

   ;Test different normalizations against the data:
   for i = 0, pts-1 do begin      
         normarray[i,j] = normvector[i]
         pararray[i,j] = parvector[j]
         chiarray[i,j] = total ( ( (subspec[usebins] - normvector[i]*foldvals[usebins])/subspecerr[usebins] )^2 )
   endfor

endfor

;Find the best fit and set output parameters:

bestchi = min(chiarray)
w = (where(chiarray EQ bestchi))[0]
bestpar = pararray[w]
bestnorm = normarray[w]
bestparn = (where(parvector EQ bestpar))[0] - points
bestnormn = (where(normvector EQ bestnorm))[0] - points
if model EQ 1 then       modvals = bestnorm*reform( (exp(-phmean/bestpar)*phwidth) # drm ) $
else if model EQ 2 then  begin
          modvals = 0.*phmean
          w = (where( abs(phmean-bestpar) eq min(abs(phmean-bestpar))))[0]
          modvals[w]= bestnorm*phwidth[w]
          modvals = modvals#drm
endif

end



