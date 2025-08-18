;+
;NAME: barrel_sp_fold_m4.pro
;DESCRIPTION: BARREL mid-level spectral folding routine
;             method4 = analytical spectral model + dual DRMs
;
;REQUIRED INPUTS:
;subspec   background subtracted count spectrum
;subspecerr    its error bars
;model     spectral model of electron spectrum (default is exponential)
;          1 = exponential
;          2 = monoenergetic
;drm       response matrix for correct payload altitude and chosen PID
;          of electrons
;drm2      second response matrix (will find allowed interpolated
;          range between these two)
;phmean    energy channel centers (should have length = length of spectrum)
;          -- this is for the photons dimension
;phwidth   energy channel widths (should have length = length of spectrum)
;          -- this is for the photons dimension
;ctwidth   energy channel widths (should have length = length of spectrum)
;          -- this is for the counts dimension
;usebins   subset of energy channels (count space) to actually use for fitting
;maxcycles Maximum number of times to try rescaling range for fit parameters
;
;OPTIONAL INPUTS:
;quiet     Don't make graphs + screen output
;verbose   show some debugging info as fits go along
;
;OUTPUTS:
;params            best fit parameters
;param_ranges      ranges on best fit parameters (1 sigma) (2x2 array)
;modvals           values of the fit function at the centers of the energy bins
;chisquare         chi-square (not reduced)
;dof               degrees of freedom associated with chisquare
;
;CALLS:
;barrel_sp_fitgrid4.pro
;
;STATUS: 
;
;TO BE ADDED:
;     Support for other spectral models
;     Reasonable formula to guess e-folding or mono-E from count spectrum
;
;REVISION HISTORY:
;Version 1.0 DMS 7/18/12 -- split out from barrel_folding as new middle layer;
;                           fixed "dof" to use "usebins" (at the same
;                           time as fixing "fitgrid1" to use "usebins")
;Errors fixed 7/20/12 -- definition of "tryspec" didn't include
;                       multiplication by "phwidth", meaning lousy
;                       starting point for fits -- which converged anyway.
;Version 2.3 DMS ;8/26/12 -- fixed logical error in rescaling
;                            algorithm in search for chisquare+1 contour.
;                            Removed redundant routine identifier from "message"
;Version 2.4 DMS 8/26/12 -- added support for model 2 (monoenergetic)
;Version 3.4 DMS 4/17/14 -- save elecmodel for best fit e- spectrum
; 
;-

pro  barrel_sp_fold_m4, subspec, subspecerr, model, drm, drm2, phmean, phwidth, ctwidth, usebins, maxcycles,  $
         params, param_ranges, elecmodel, modvals, chisquare, dof, quiet=quiet, verbose=verbose

if model EQ 1 then begin
    ;;This formula for approximate e-folding from a count ratio between
    ;;two bands will be empirical from simulations.  For now, we will start
    ;;with folding energy = 300 keV
;    countratio = total(subspec[where(ebins GT ?? and ebins LT ??)]) / $  
;                 total(subspec[where(ebins GT ?? and ebins LT ??)]) 
;    startpar = ?? ;function of countratio
    startpar = 300.
    tryspec = (exp(-phmean/startpar)*phwidth) # drm
endif else if model EQ 2 then begin
    startpar = 1000.
    tryspec = phmean*0.
    tryspec[(where( abs(phmean-startpar) eq min(abs(phmean-startpar)) ))[0] ] = 1.
    tryspec = (tryspec*phwidth) # drm
endif  else message, 'Only exponential or monoenergetic spectrum is currently supported.'

;Find a starting normalization by scaling area of model and data
;(this will be the same procedure for every starting model):
startnorm = total( subspec[usebins]*ctwidth[usebins] ) / total( tryspec[usebins]*ctwidth[usebins] )

;Try a starting range around these trial values.  If the minimum 
;chi-square is not on the boundary, zoom in.  If it is, zoom out.
;In either case, recenter.

points = 10   ;always run a 21x21(x21) grid
scaling = [0.5,0.5,0.5]  ;[norm,par,drm]: best values +/- 50% (norm&par) or just +/- 0.5 (drm)

if keyword_set(verbose) then $
    print,'iter#', 'startpar','startnorm','startdrm','bestpar','bestnorm','bestdrm',$
       'scalepar','scalenorm','scaledrm','bestchi',$
          format='(a8,6a11,3a13,a10)'

;Iterate the fit, adjusting the scale dynamically:
for i=0, maxcycles-1 do begin

    barrel_sp_fitgrid4, subspec, subspecerr, model, drm, drm2, phmean, phwidth, usebins, startpar, $
         startnorm, startdrm, points, scaling, $
         bestpar, bestnorm, bestdrm, bestparn, bestnormn, bestdrmn, modvals, $
         chiarray, bestchi, pararray, normarray, drmarray,debug=verbose

   ;;if best value is not on boundary, zoom in or finish.
   ;;Note that zooming in or out on scalingdrm doesn't do anything if
   ;;you aren't using two drms.

   if abs(bestnormn) NE points and scaling[0] GE 0.001 then scaling[0] /= 2.5
   if abs(bestparn)  NE points and scaling[1] GE 0.001 then scaling[1] /= 2.5
   if abs(bestdrmn)  NE points and scaling[2] GE 0.001 then scaling[2] /= 2.5

   ;;If scaling is now very fine, break.  Note that the last values of the
   ;;scaling parameters recorded here aren't really the last
   ;;values used, the last value used could be 2.5 times higher in one or more:
   if scaling[0] LT 0.001 and scaling[1] LT 0.001 and scaling[2] LT 0.001 then break

   if abs(bestnormn) EQ points then scaling[0] *= 2.0
   if abs(bestparn) EQ points then scaling[1] *= 2.0
   if abs(bestdrmn) EQ points then scaling[2] *= 2.0

   if keyword_set(verbose) then $
      print,i,startpar,startnorm,startdrm,bestpar,bestnorm,bestdrm,scaling[1],scaling[0],scaling[2],bestchi,$
          format='(i8,6f11.3,3f13.6,f13.4)'

   startpar = bestpar
   startnorm = bestnorm
   startdrm = bestdrm

endfor

;If it never got to the finest scale, break with error:
if scaling[0] GT 0.001 or scaling[1] GT 0.001 or scaling[2] GT 0.001 then $
    message, 'Fit failed to converge in maximum number of cycles.'

;Set most output variables (either 2 or 3 best-fit params depending on
;treatment of response matrices:
params = [bestnorm, bestpar, bestdrm]
chisquare = bestchi
dof = n_elements(usebins) - 2

;Only one thing left: the error on the parameters.  This requires more
;effort.  Here we will wander radially outwards until we find that the
;whole boundary has chisq > chimin
;Always center on the best value:
startpar = bestpar
startnorm = bestnorm
stardrm = bestdrm
points = 10

;Create masks for the outer boundary of the chi-square space:
edges1 = intarr(2*points+1,2*points+1,2*points+1)
edges2 = intarr(2*points+1,2*points+1,2*points+1)
edges3 = intarr(2*points+1,2*points+1,2*points+1)
edges1[0,*,*] = 1
edges1[2*points,*,*] = 1
edges2[*,0,*] = 1
edges2[*,2*points,*] = 1
edges3[*,*,0] = 1
edges3[*,*,2*points] = 1

;Create initial values for error bar search:
scaling = [0.1, 0.1, 0.1]   ;first guess
scaling0 = scaling
minscaling = scaling
goingup = [0,0,0]

for i=0, maxcycles-1 do begin

   barrel_sp_fitgrid4, subspec, subspecerr, model, drm, drm2, phmean, phwidth, usebins, startpar, $
         startnorm, startdrm, points, scaling, $
         bestpar, bestnorm, bestdrm, bestparn, bestnormn, bestdrmn, modvals, $
         chiarray, bestchi, pararray, normarray, drmarray,debug=verbose

  ;;First see if the contour is completely closed:
  ;;Look for chisq < min_chisq + 1 on boundary:
  w1 = where(edges1 and (chiarray LE chisquare + 1.),nw1)
  w2 = where(edges2 and (chiarray LE chisquare + 1.),nw2)
  w3 = where(edges3 and (chiarray LE chisquare + 1.),nw3)
  nw=[nw1,nw2,nw3]

  ;;If the boundary is entirely outside of the chi-square contour, zoom
  ;;in ALL AXES by a factor of 2, unless you had already zoomed out, in which 
  ;;case you've actually identified the right scale:
  if (total(nw) EQ 0) then begin
       if (total(goingup) EQ 3) then break
       for j=0,2 do if (not goingup[j]) then scaling[j] /= 2.0
       continue
  endif

  ;;If boundary not entirely clear, take each axis separately, and
  ;;expand or contract the scaling:
  for j=0,2 do begin
    if (nw[j] GT 0) then begin
      goingup[j] = 1
      scaling[j] *= 2.0
    endif else begin  
      if (not goingup[j]) then scaling[j] /= 2.0 
    endelse
  endfor

endfor

;Now that we've found the appropriate scaling (within a factor
;of 2 of the point where the last good fit appears on the boundary), 
;do one very fine map of chisquare space to find the error bars:

points = 40

barrel_sp_fitgrid4, subspec, subspecerr, model, drm, drm2, phmean, phwidth, usebins, startpar, $
         startnorm, startdrm, points, scaling, $
         bestpar, bestnorm, bestdrm, bestparn, bestnormn, bestdrmn, modvals, $
         chiarray, bestchi, pararray, normarray, drmarray,debug=verbose

;Pick out the subset of points within the min(chisquare)+1. contour:
w = where(chiarray LT chisquare + 1., nw)
if nw EQ 0 then message, 'Failure in finding error bars.'

;This makes up the last needed output parameter: ranges of the parameters
param_ranges = [ [min(normarray[w]),max(normarray[w])],[min(pararray[w]),max(pararray[w])],$
                 [min(drmarray[w]),max(drmarray[w])] ]

;Added in v3.4: electron spectrum model values
if model EQ 1 then begin	
       elecmodel= bestnorm*exp(-phmean/bestpar)
endif else if model EQ 2 then begin   
       ;just as done in barrel_sp_fitgrid1.pro!
       elecmodel = 0.*phmean
       w = (where( abs(phmean-bestpar) eq min(abs(phmean-bestpar))))[0]
       elecmodel[w] = bestnorm 
endif

end

