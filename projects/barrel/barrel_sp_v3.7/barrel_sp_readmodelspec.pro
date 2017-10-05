;+
;NAME: barrel_sp_readmodelspec.pro
;DESCRIPTION: Spectral model file reader for barrel folding routines.
;             File format must be 3 columns, start-energy, end-energy,
;             flux per keV at center of the bin.
;
;REQUIRED INPUTS:
;fname     spectrum file name
;phebins   energy channel boundaries desired (may or may not match file)
;phmean    energy channel centers
;
;OPTIONAL INPUTS:
;none
;
;OUTPUTS:
;outspec           model spectrum in flux per keV at the values phmean
;
;CALLS:
;none
;
;STATUS:           Tested with artificial data, both with and without interpolation
;
;TO BE ADDED:      N/A
;
;REVISION HISTORY:
;Version 1.0 DMS 7/24/12
;Version 3.4 DMS 4/17/14:  The interpolation kills a single-bin
;      (monoenergetic) flux or other narrow features.  Replace
;      "interpol" with "hsi_rebinner" for rebinning to our bins.
;      Warning: our bins are broad so we will lose some information
;      about where within the bin the flux actually is.  Use
;      method=1, model=2 (precise monoenergetic) for mono. models
;      instead.
;
;-

;Version 3.4 4/17/14 DMS: switch from using interpol() to brl_rebin()
;to handle monoenergetic case.

pro barrel_sp_readmodelspec, fname, phebins, phmean, outspec

;Read input spectrum model file.  Units of column 3 must be photons/keV.
n=datin(barrel_find_file(fname,'barrel_sp_v3.7'), 3, modeldata)
if n LT 3 then message, 'Error reading model file -- two few data points (< 3).'

;Compare energy channels in file to requested ones, and interpolate
;new ones if they don't match:

model_ebins = [reform(modeldata[0,*]),modeldata[1,n-1]]
if ( ( (size(model_ebins))[1] NE (size(phebins))[1] ) OR max(abs(model_ebins-phebins)) GT 1.0 ) then begin
   edge_products,model_ebins,mean=modelmean, width=modelwidth
   outspec = brl_rebin(reform(modeldata[2,*]),model_ebins,phebins,flux=1)
   ;; Set places where extrapolation < 0 equal to zero:
   outspec[where(outspec LT 0.)] = 0.
   if (max(modelmean) LT max(phmean)) or (min(modelmean) LT min(phmean)) then $
      print,'BARREL_SP_READMODELSPEC: WARNING: extrapolating model beyond specified range in ',fname
endif else outspec = reform(modeldata[2,*])

end
