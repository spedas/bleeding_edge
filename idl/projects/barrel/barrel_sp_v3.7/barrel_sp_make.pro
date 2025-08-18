;+
;NAME: barrel_sp_make.pro (function)
;DESCRIPTION: Creates spectroscopy data structure
;
;REQUIRED INPUTS: none
; 
;OPTIONAL INPUTS:
;numsrc           # of source spectrum time intervals (default 1)
;numbkg           # of background spectrum time intervals (default 1)
;slow             slow (256-channel) spectra versus default medium
;
;OUTPUTS:
;returns the spectroscopy system structure that is passed to all
;subsequent spectroscopy routines.  The structure content will vary
;with software version.
;
;CALLS:
;barrel_make_standard_energies(),barrel_make_standard_electron_energies()
;
;NOTES: 
;
;STATUS: up to date
;
;TO BE ADDED: only in response to changes in other routines
;
;
;REVISION HISTORY:
;Version 3.0 DMS 9/9/13
; revisions from 2.9:  add size options for slow spectra
;                      postpone numparams until fitting routine; leave
;                          room for a large number (10)
; 3.4       4/17/14    Add space for best fit model in e- space
;-

function barrel_sp_make, numsrc=numsrc, numbkg=numbkg, slow=slow

;Defines and returns a structure for BARREL spectroscopy

if not keyword_set(numsrc)  then numsrc=1
if not keyword_set(numbkg)  then numbkg=1
if not keyword_set(slow) then slow=0
if slow then siz=256 else siz=48
if slow then drmsize=256 else drmsize=184 

ss = {$
  payload: "",$                         ;Two-character payload ID (e.g. 1F)
  askdate: "",$                         ;requested start time
  askduration: -1.,$                    ;requested duration in hours
  altitude: -1.,$                       ;altitude in km 
  maglat: -1.,$                         ;magnetic latitude in degrees
  slow:slow,$                           ;slow or medium spectra (sspc or mspc)
  ebins: fltarr(siz+1)-1.,$             ;energy channel boundaries (keV)
  numsrc: floor(numsrc),$               ;number of source time intervals
  trange: dblarr(2,numsrc)-1.d  ,$      ;source time intervals in Unix epoch
  bkgmethod: -1, $                      ;1=from data stream, 2=from model
  numbkg: floor(numbkg),$               ;# of bkg intervals, up to 4
  bkgtrange: dblarr(2,numbkg)-1.d ,$    ;bkg time intervals in Unix epoch
  trange2: dblarr(2,numsrc)-1.d ,$      ;source time intervals in Unix epoch,
                                        ;rounded to real 4s periods used
  bkgtrange2: dblarr(2,numbkg)-1.d,$    ;bkg time intervals in Unix epoch,
                                        ;rounded to real 4s periods used
  level: "",$                           ;Data level (l1 or l2)
  srcspec: fltarr(siz)-1.d,$            ;summed source spectrum, deadtime corrected       
  srcspecerr: fltarr(siz)-1.d,$         ;error in summed source spectrum       
  bkgspec: fltarr(siz)-1.d,$            ;summed background spectrum, deadtime corrected        
  bkgspecerr: fltarr(siz)-1.d,$         ;error in summed background spectrum       
  srctime: -1.d,$                       ;source spectrum accum. time in seconds
  bkgtime: -1.d,$                       ;background spectrum accum. time in seconds
  srclive: -1.d,$                       ;source spectrum livetime, seconds (approx.)
  bkglive: -1.d,$                       ;background spectrum livetime, seconds (approx.)
  bkg_renorm:-1,$                       ;switch to renormalize bkg to match source > 3 MeV
  subspec: fltarr(siz)-1.d,$            ;background subtracted spectrum, deadtime corrected        
  subspecerr: fltarr(siz)-1.d,$         ;error in background subtracted spectrum       
  drmsize: floor(drmsize),$             ;# of drm rows (electron side)
  elebins: fltarr(drmsize+1)-1.d,$      ;energy boundaries on electron side (ct side is fixed)
  drm: fltarr(drmsize,siz)-1.d,$        ;response matrix
  drmtype: -1, $                        ;1=downward isotropic, 2=mirroring, 3=other
  drm2: fltarr(drmsize,siz)-1.d,$       ;second response matrix 
  drm2type: -1, $                       ;1=downward isotropic, 2=mirroring, 3=other
  method: -1,$                          ;fitting method (1-6)
  model: -1,$                           ;fitting model (1-2) = exponential, monoenergetic
  fitrange: fltarr(2)-1.,$              ;fitting range of energies
  modlfile: "",$                        ;model file, if not using analytical model
  secondmodlfile: "",$                  ;second model file, if any
  numparams: -1,$                       ;number of fit parameters
  params: fltarr(10)-1.,$               ;fit parameters
  param_ranges:fltarr(10,2)-1.,$        ;1-sigma ranges on fit parameters
  elecmodel:fltarr(drmsize),$           ;values for best electron model, e-/cm2/s/keV
  chisq: -1.,$                          ;chi-square of fit (unreduced)
  chi_dof: -1.,$                        ;degrees of freedom for chi-square of fit
  modvals: fltarr(siz)-1.,$             ;values of model fit at center of each bin
  secondmodvals: fltarr(siz)-1.}        ;values of 2nd component at center of each bin 

;Set up energy channels:
ss.ebins=barrel_make_standard_energies(slow=slow)
ss.elebins=barrel_make_standard_electron_energies(slow=slow)

return,ss
end




