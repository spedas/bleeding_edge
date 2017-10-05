
;+
;NAME:
; thm_sst_calib_params2
;PURPOSE:
;  This populates the correct fields of the dist struct so that data can be correctly calibrated.
;
;Inputs:
;  dist: The dist struct that will have its fields populated
;  param_structs: An array of parameter structs that contains the calibration parameters for each time
;
;Outputs:
;  error: Set to 1 if error occurred and 0 otherwise.  If error occurs calling routine should halt.
;  
;Keywords:
;  no_energy_efficiency: Set to disable energy efficiency calibrations
;  no_geom_efficiency: Set to disable the relative efficiencies of different anodes
;  no_dead_layer_offsets: Set to disable dead layer energy offsets
;NOTES:
;  #1 dist.time should be set by the time this is called
;  #2 uses the calibration parameters for full distribution on all types.
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2013-03-11 17:32:36 -0700 (Mon, 11 Mar 2013) $
;$LastChangedRevision: 11772 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/SST_cal_workdir/thm_sst_calib_params2.pro $
;-


pro thm_sst_calib_params2,dist,param_structs,error=err,no_energy_efficiency=no_energy_efficiency,no_geom_efficiency=no_geom_efficiency,no_dead_layer_offsets=no_dead_layer_offsets,set_deadtime_correction=set_deadtime_correction

  err=1

  thm_init
  
  ;num_params=56
  num_params=60
  ;num_params=203
    
  tg = tag_names(param_structs[0])
  
  if n_elements(tg) ne num_params then begin
    dprint,'ERROR: Incorrect number of parameters in calibration file.',dlevel=0
    dprint,'CAL File is incorrectly formatted or you need to download updated code',dlevel=0
    dprint,'Distribution Type: ' + dist.tplotname,dlevel=0
    dist = 0
    return 
  endif

  ;determine the correct parameters to use according to sample time
  ;uses the nearest parameters to dist.time that are dated before dist.time
  t = dist.time - time_double((param_structs[*]).time)

  idx = where(t gt 0,c) 
  
  if c eq 0 then begin
    dprint,'ERROR: calibration file has no parameters for this time',dlevel=0
    dprint,'CAL File is incorrectly formatted or you need to download updated code',dlevel=0
    dist = 0
    return 
  endif
  
  temp = min(t[idx],idx2)
  param_struct = param_structs[idx[idx2]]
  
  ;using n to denote the start of this param type in the cal file
  ;makes code more flexible when adding new parameters or moving files around
  n = 1
  
  for i = 0,15 do begin
  ;lower energy boundaries for each energy bin
    dist.en_low[i] = param_struct.(n+i)
  endfor
  n += 16
  
 for i = 0,15 do begin
    ;upper energy boundaries for each energy bin
    dist.en_high[i] = param_struct.(n+i)
  endfor
  n += 16
  
  if n_elements(set_deadtime_correction) eq 1 then begin
    dist.deadtime=set_deadtime_correction
  endif else begin
    dist.deadtime = param_struct.(n)
  endelse
  
 ; if ~keyword_set(no_deadtime_correction) then begin
    ;dead time correction factor(applies one value for all telescopes)

  ;endif else begin
  ;  dist.deadtime = 0
  ;endelse
  
  n++
  
  ;nominal(theoretical) geometric factor
  dist.geom_factor = param_struct.(n)
    
  n++
    
  det_idx = lindgen(16)
  
  ;Temporary. Following calibration parameters are only valid atm for full & burst modes
  dim = dimen(dist.data)
  if n_elements(dim) eq 1 || dim[1] ne 64 then begin
    err=0
    return
  endif
  
  
  ;selectively disable this part of the calibration using this keyword
  
  ;geometric efficiencies no longer used. Better result achieved using dead layer intercalibration
  ;pcruce 2013-03-07  
  if ~keyword_set(no_geom_efficiency) then begin
    for i = 0,3 do begin 
      ;correction factors to nominal geometric factor.  Allows for variance in manufacturing, and mechanical tolerances.
      ;allows different values for each theta(telescope aperture)
      ;note that values are rebinned so that one value is repeated for all energies/phi.  This way data can be scaled element by element.
      dist.gf[*,det_idx+i*16] = param_struct.(n+i)
    endfor
  endif else begin
    dist.gf[*] = 1.0
  endelse
  
  n += 4
 ; dist.gf=1.0
 
  if ~keyword_set(no_dead_layer_offsets) then begin
    for i = 0,3 do begin 
    ;one offset for each look direction
      dist.dead_layer_offsets[i] = param_struct.(n+i)
    endfor
  endif 
 
 
  n += 4
 
  ;attenuator scaling factors.  Vary from the nominal(1/64), due to manufacturing and mechnical tolerances.  
  ;allows different values for each theta(telescope aperture)
  ;note that values are rebinned so that one value is repeated for all energies/phi.  This way data can be scaled element by element.
  dist.att[*] = param_struct.(n)
  
  n++
  
  ;selectively disable this part of the calibration using this keyword
  if ~keyword_set(no_energy_efficiency) then begin 
  
    ;detector PHA bin efficiencies. 
    for i = 0,15 do begin
      dist.eff[i,*] = param_struct.(n+i)
    endfor
    
    n += 16
 
  endif else begin
    dist.eff=1.0
  endelse

  err = 0

end