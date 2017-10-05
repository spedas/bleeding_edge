;+
;NAME: barrel_sp_fold_m2.pro
;DESCRIPTION: BARREL mid-level spectral folding routine
;             method2 = single-parameter file-based spectrum, single drm
;
;REQUIRED INPUTS:
;subspec   background subtracted count spectrum
;subspecerr    its error bars
;modlfile  Input model spectrum.  Required format is
;          starting energy boundary, ending energy boundary, flux
;          it will be interpolated to phebins if necessary.  Comment
;          lines beginning with characters not = '0123456789.-' are
;          allowed at the start.
;drm       response matrix for correct payload altitude and chosen PID
;          of electrons
;phebins   energy channel boundaries (length = length of spectrum + 1)
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
;params            best fit parameters (only one in this case)
;param_ranges      range on best fit parameter (1 sigma)
;modvals           values of the fit function at the centers of the energy bins
;chisquare         chi-square (not reduced)
;dof               degrees of freedom associated with chisquare
;
;CALLS:
;barrel_sp_readmodelspec, barrel_sp_fitgrid2
;
;STATUS: 
;
;TO BE ADDED:
;
;REVISION HISTORY:
;Version 1.0 DMS 7/24/12 -- split out from barrel_folding as new middle layer;
;                           fixed "dof" to use "usebins" (at the same
;                           time as fixing "fitgrid1" to use "usebins")
;Version 2.3 DMS ;8/26/12 -- Removed redundant routine identifier from "message"
;Version 3.4 DMS 4/17/14 -- save elecmodel for best fit e- spectrum
;-

pro  barrel_sp_fold_m2, subspec, subspecerr, modlfile, drm, phebins, phmean, phwidth, ctwidth, usebins, maxcycles,  $
         params, param_ranges, elecmodel, modvals, chisquare, dof, quiet=quiet, verbose=verbose

barrel_sp_readmodelspec, modlfile, phebins, phmean, modelspec

tryspec = (modelspec*phwidth) # drm

;Find a starting normalization by scaling area of model and data
;(this will be the same procedure for every starting model):  

startnorm = total( subspec[usebins]*ctwidth[usebins] ) / total( tryspec[usebins]*ctwidth[usebins] )

;Try a starting range around these trial values.  If the minimum 
;chi-square is not on the boundary, zoom in.  If it is, zoom out.
;In either case, recenter.

points = 10   ;always run a 21x21(x21) grid
scaling = [0.5]  ;[norm]: best value +/- 50%

if keyword_set(verbose) then $
    print,'iter#', 'startnorm','bestnorm','scalenorm','bestchi',$
          format='(a8,2a11,a13,a10)'

;Iterate the fit, adjusting the scale dynamically:
for i=0, maxcycles-1 do begin
 
    barrel_sp_fitgrid2, subspec, subspecerr, modelspec, drm, phmean, phwidth, usebins, $
         startnorm, points, scaling, bestnorm, bestnormn, modvals, $
         chiarray, bestchi, normarray

   ;;if best value is not on boundary, zoom in or finish.
   ;;Note that zooming in or out on scalingdrm doesn't do anything if
   ;;you aren't using two drms.

   if abs(bestnormn) NE points and scaling[0] GE 0.001 then scaling[0] /= 2.5
 
   ;;If scaling is now very fine, break.  Note that the last values of the
   ;;scaling parameters recorded here aren't really the last
   ;;values used, the last value used could be 2.5 times higher in one or more:
   if scaling[0] LT 0.001 then break

   if abs(bestnormn) EQ points then scaling[0] *= 2.0

   if keyword_set(verbose) then $
      print,i,startnorm,bestnorm,scaling[0],bestchi,$
          format='(i8,2f11.3,f13.6,f13.4)'

   startnorm = bestnorm

endfor

;If it never got to the finest scale, break with error:
if scaling[0] GT 0.001 then $
    message, 'Fit failed to converge in maximum number of cycles.'

;Set most output variables (either 2 or 3 best-fit params depending on
;treatment of response matrices:
params = [bestnorm]
chisquare = bestchi
dof = n_elements(usebins) - 2

;Only one thing left: the error on the parameters.  This requires more
;effort.  Here we will wander radially outwards until we find that the
;whole boundary has chisq > chimin
;Always center on the best value:
startnorm = bestnorm
points = 10

;Create masks for the outer boundary of the chi-square space:
edges = intarr(2*points+1)
edges[0] = 1
edges[2*points] = 1

;Create initial values for error bar search:
scaling = [0.1]   ;first guess
scaling0 = scaling
minscaling = scaling
goingup = 0

for i=0, maxcycles-1 do begin

  barrel_sp_fitgrid2, subspec, subspecerr, modelspec, drm, phmean, phwidth, usebins, $
         startnorm, points, scaling, bestnorm, bestnormn, modvals, $
         chiarray, bestchi, normarray

  ;;First see if the contour is completely closed:
  ;;Look for chisq < min_chisq + 1 on boundary:
  w1 = where(edges and (chiarray LE chisquare + 1.),nw)

  ;;If the boundary is entirely outside of the chi-square contour, zoom
  ;;in by a factor of 2, unless you had already zoomed out, in which 
  ;;case you've actually identified the right scale:
  if (nw EQ 0) then begin
       if goingup then break
       scaling[0] /= 2.0
       continue
  endif
       
  if (nw GT 0) then begin
       goingup = 1
       scaling[0] *= 2.0
  endif

endfor

;Now that we've found the appropriate scaling (within a factor
;of 2 of the point where the last good fit appears on the boundary), 
;do one very fine map of chisquare space to find the error bars:

points = 40

barrel_sp_fitgrid2, subspec, subspecerr, modelspec, drm, phmean, phwidth, usebins, $
         startnorm, points, scaling, bestnorm, bestnormn, modvals, $
         chiarray, bestchi, normarray

;Pick out the subset of points within the min(chisquare)+1. contour:
w = where(chiarray LT chisquare + 1., nw)
if nw EQ 0 then message, 'Failure in finding error bars.'

;This makes up the last needed output parameter: ranges of the parameters
param_ranges = [ [min(normarray[w]),max(normarray[w])] ]

;Added in v3.4: electron spectrum model values
elecmodel= modelspec*bestnorm

end

