;+
;NAME: barrel_sp_fold_m3.pro
;DESCRIPTION: BARREL mid-level spectral folding routine
;             method3 = two file-based spectral shapes, single drm
;
;REQUIRED INPUTS:
;subspec   background subtracted count spectrum
;subspecerr    its error bars
;modlfile Input model spectrum.  Required format is
;          starting energy boundary, ending energy boundary, flux
;          it will be interpolated to phebins if necessary.  Comment
;          lines beginning with characters not = '0123456789.-' are
;          allowed at the start.
;secondmodlfile Second input model spectrum. 
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
;params            best fit parameters
;param_ranges      ranges on best fit parameters (1 sigma) (2x2 array)
;modvals           values of the fit function at the centers of the energy bins (first component) 
;secondmodvals     values of the fit function at the centers of the energy bins (second component) 
;chisquare         chi-square (not reduced)
;dof               degrees of freedom associated with chisquare
;
;CALLS:
;barrel_sp_fitgrid3.pro
;
;STATUS: 
;
;TO BE ADDED:
;
;REVISION HISTORY:
;Version 1.0 DMS 8/18/12
;Version 3.4 DMS 4/17/14 -- save elecmodel for best fit e- spectrum
;-

pro  barrel_sp_fold_m3, subspec, subspecerr, modlfile, secondmodlfile, drm, phebins, phmean, phwidth, ctwidth, usebins, maxcycles,  $
         params, param_ranges, elecmodel,modvals, secondmodvals, chisquare, dof, quiet=quiet, verbose=verbose

barrel_sp_readmodelspec, modlfile, phebins, phmean, modelspec1
barrel_sp_readmodelspec, secondmodlfile, phebins, phmean, modelspec2

;Initial starting parameter is equal parts of each model
tryspec1 = (modelspec1*phwidth) # drm
tryspec2 = (modelspec2*phwidth) # drm

;Find a starting normalization by scaling area of model and data;
;start with the assumption that each component carries half the counts.
startnorm1 = total( subspec[usebins]*ctwidth[usebins] ) / total( tryspec1[usebins]*ctwidth[usebins] ) / 2.
startnorm2 = total( subspec[usebins]*ctwidth[usebins] ) / total( tryspec2[usebins]*ctwidth[usebins] ) / 2.

;Try a starting range around these trial values.  If the minimum 
;chi-square is not on the boundary, zoom in.  If it is, zoom out.
;In either case, recenter.

points = 10   ;always run a 21x21(x21) grid
scaling = [0.5,0.5]  ;[norm1,norm2]: best values +/- 50%

if keyword_set(verbose) then $
    print,'iter#', 'startnorm1','startnorm2','bestnorm1','bestnorm2','scalenorm1','scalenorm2','bestchi',$
          format='(a8,4a11,2a13,a10)'

;Iterate the fit, adjusting the scale dynamically:
for i=0, maxcycles-1 do begin

    barrel_sp_fitgrid3, subspec, subspecerr, modelspec1, modelspec2, drm, phmean, phwidth, usebins, startnorm1, $
         startnorm2, points, scaling, bestnorm1, bestnorm2, bestnorm1n, bestnorm2n, modvals, secondmodvals, $
         chiarray, bestchi, norm1array, norm2array

   ;;if best value is not on boundary, zoom in or finish.
   ;;Note that zooming in or out on scalingdrm doesn't do anything if
   ;;you aren't using two drms.

   if abs(bestnorm1n) NE points and scaling[0] GE 0.001 then scaling[0] /= 2.5
   if abs(bestnorm2n) NE points and scaling[1] GE 0.001 then scaling[1] /= 2.5

   ;;If scaling is now very fine, break.  Note that the last values of the
   ;;scaling parameters recorded here aren't really the last
   ;;values used, the last value used could be 2.5 times higher in one or more:
   if scaling[0] LT 0.001 and scaling[1] LT 0.001 then break

   if abs(bestnorm1n) EQ points then scaling[0] *= 2.0
   if abs(bestnorm2n) EQ points then scaling[1] *= 2.0

   if keyword_set(verbose) then $
      print,i,startnorm1,startnorm2,bestnorm1,bestnorm2,scaling[0],scaling[1],bestchi,$
          format='(i8,4f11.3,2f13.6,f13.4)'

   startnorm1 = bestnorm1
   startnorm2 = bestnorm2

endfor

;If it never got to the finest scale, break with error:
if scaling[0] GT 0.001 or scaling[1] GT 0.001 then $
    message, ' Fit failed to converge in maximum number of cycles.'

;Set most output variables (either 2 or 3 best-fit params depending on
;treatment of response matrices:
params = [bestnorm1, bestnorm2]
chisquare = bestchi
dof = n_elements(usebins) - 2

;Only one thing left: the error on the parameters.  This requires more
;effort.  Here we will wander radially outwards until we find that the
;whole boundary has chisq > chimin
;Always center on the best value:
startnorm1 = bestnorm1
startnorm2 = bestnorm2
points = 10

;Create masks for the outer boundary of the chi-square space:
edges1 = intarr(2*points+1,2*points+1)
edges2 = intarr(2*points+1,2*points+1)
edges1[0,*] = 1
edges1[2*points,*] = 1
edges2[*,0] = 1
edges2[*,2*points] = 1

;Create initial values for error bar search:
scaling = [0.1, 0.1]   ;first guess
scaling0 = scaling
minscaling = scaling
goingup = [0,0]

if keyword_set(verbose) then print,'Starting search for error contour.'

for i=0, maxcycles-1 do begin

    barrel_sp_fitgrid3, subspec, subspecerr, modelspec1, modelspec2, drm, phmean, phwidth, usebins, startnorm1, $
         startnorm2, points, scaling, bestnorm1, bestnorm2, bestnorm1n, bestnorm2n, modvals, secondmodvals, $
         chiarray, bestchi, norm1array, norm2array

  ;;First see if the contour is completely closed:
  ;;Look for chisq < min_chisq + 1 on boundary:
  w1 = where(edges1 and (chiarray LE chisquare + 1.),nw1)
  w2 = where(edges2 and (chiarray LE chisquare + 1.),nw2)
  nw=[nw1,nw2]

  ;;If the boundary is entirely outside of the chi-square contour, zoom
  ;;in by a factor of 2, unless you had already zoomed out, in which 
  ;;case you've actually identified the right scale:
  if (total(nw) EQ 0) then begin
       if (total(goingup) EQ 2) then break
       for j=0,1 do if (not goingup[j]) then scaling[j] /= 2.0
       continue
  endif

  ;;If boundary not entirely clear, take each axis separately, and
  ;;expand or contract the scaling:
  for j=0,1 do begin
    if (nw[j] GT 0) then begin
      goingup[j] = 1
      scaling[j] *= 2.0
    endif else begin  
      if (not goingup[j]) then scaling[j] /= 2.0
    endelse
  endfor

  if keyword_set(verbose) then begin
      print,i,startnorm1,startnorm2,bestnorm1,bestnorm2,scaling[0],scaling[1],bestchi,$
          format='(i8,4f11.3,2f13.6,f13.4)'
;      This is a useful diagnostic check on the contour changing algorithm:
;      contour,chiarray,levels=[chisquare+1.,chisquare+3.,chisquare+20.]
  endif

endfor

;Now that we've found the appropriate scaling (within a factor
;of 2 of the point where the last good fit appears on the boundary), 
;do one very fine map of chisquare space to find the error bars:

points = 40

barrel_sp_fitgrid3, subspec, subspecerr, modelspec1, modelspec2, drm, phmean, phwidth, usebins, startnorm1, $
         startnorm2, points, scaling, bestnorm1, bestnorm2, bestnorm1n, bestnorm2n, modvals, secondmodvals, $
         chiarray, bestchi, norm1array, norm2array

;Pick out the subset of points within the min(chisquare)+1. contour:
w = where(chiarray LT chisquare + 1., nw)
if nw EQ 0 then message, 'Failure in finding error bars.'

;This makes up the last needed output parameter: ranges of the parameters
param_ranges = [ [min(norm1array[w]),max(norm1array[w])],[min(norm2array[w]),max(norm2array[w])] ]

;Added in v3.4: electron spectrum model values
elecmodel= modelspec1*bestnorm1 + modelspec2*bestnorm2

end

