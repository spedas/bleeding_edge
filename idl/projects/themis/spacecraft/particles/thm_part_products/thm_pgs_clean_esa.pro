;+
;PROCEDURE: thm_pgs_clean_esa
;PURPOSE:
;  Helper routine for thm_part_products
;  Maps ESA data into simplified format for high-level processing.
;  Creates consistency for downstream routines and throws out extra fields to save memory 
;  
;Inputs(required):
;  data: ESA particle data structure from thm_part_dist, get_th?_pe??, thm_part_dist_array, etc...
;  units: string specifying the units (e.g. 'eflux')
;
;Outputs:
;   output structure elements:
;         data - particle data 2-d array, energy by angle. (Float or double)
;      scaling - scaling coefficient corresponding to 1 count/bin, used for error calculation (float or double)
;         time - sample start time(1-element double precision scalar)
;     end_time - sample end time(1-element double precision scalar)
;          phi - Measurment angle in plane parallel to spacecraft spin.(2-d array matching data array.) (Float or double)
;         dphi - Width of measurement angle in plane parallel to spacecraft spin.(2-d array matching data array.) (Float or double)
;        theta - Measurment angle in plane perpendicular to spacecraft spin.(2-d array matching data array.) (Float or double)
;       dtheta - Width of measurement angle in plane perpendicular to spacecraft spin. (2-d array matching data array.) (Float or double)
;       energy - Contains measurment energy for each component of data array. (2-d array matching data array.) (Float or double)
;      denergy - Width of measurment energy for each component of data array. (2-d array matching data array.)
;         bins - 0-1 array, indicating which bins are enabled for subsequent calculations. (2-d array matching data array.)  (Integer type.)
;       charge - expected particle charge (1-element float scalar)
;         mass - expected particle mass (1-element float scalar)
;         magf - placeholder for magnetic field vector (3-element float array)
;        scpot - placeholder for spacecraft potential (1-element float scalar)
;
;
;
;Keywords:
;
;  esa_max_energy: Set to maximum energy to toss bins that are having problems from instrument contamination. 
;  esa_bgnd_advanced: Flag to apply advanced background subtraction
;                         Background must be pre-calculated with thm_load_esa_bkg
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2019-02-19 11:17:18 -0800 (Tue, 19 Feb 2019) $
;$LastChangedRevision: 26643 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_products/thm_pgs_clean_esa.pro $
;-

;Note: Keep options for vectorizing open
pro thm_pgs_clean_esa,data,units,output=output,_extra=ex,esa_max_energy=esa_max_energy,esa_bgnd_advanced=esa_bgnd_advanced, remove_counts=remove_counts

  compile_opt idl2,hidden
  

  ;advanced background subtraction
  ;background must be calculated prior to this step
  ;see thm_load_esa_bkg and thm_pse_bkg_auto for more info
  if keyword_set(esa_bgnd_advanced) then begin
    ;data must be in counts, will return if it already is 
    data = conv_units(data,'counts',_extra=ex)
    if data.charge gt 0 then begin
      data = thm_pei_bkg_sub(data)
    endif else begin
      data = thm_pee_bkg_sub(data)
    endelse
  endif else begin
    thm_esa_bgnd_remove, data, _extra = ex
  endelse

  ;allow user to set threshold of N counts after background removal
  ;this is not recommended but could be useful
  if keyword_set(remove_counts) then begin
    thm_part_remove, data, threshold=remove_counts, /zero
  endif
  

  ;convert to requested units
  ;get scaling coefficient used to convert from counts->units
  ;  NOTE: for ESA the value of SCALE does not reflect dead time correction
  udata = conv_units(data,units,scale=scale,_extra=ex)
  scale = float(scale)
  if n_elements(scale) eq 1 then begin
    scale = replicate(scale,size(data.data,/dim))
  endif
  
  ;ensure phi values are in [0,360]
  udata.phi = udata.phi mod 360
  
  
  ;re-arrange energy bins to be in ascending order
  ;this assumes vectorization will be over single mode
  s = sort( udata[0].energy[*,0] )
  
  
  ;modify sorting indices to exclude top ESA energy (first element)
  ;this energy is turned off in the get_th?_pe?? routines for 
  ;all datatypes except 15 energy full electron
  if data.apid ne '457'xu || data.nenergy ne 15 then begin
    idx = where(s ne 0, ni)
    if ni gt 0 then s = s[idx]
  endif
  
    
  ;create standard array for output
  ;**extra dimension in case of later vectorization
  output = { data: udata.data[s,*,*], $
             scaling: scale[s,*,*], $
             time: udata.time, $
             end_time: udata.end_time, $
             phi: udata.phi[s,*,*], $
             dphi: udata.dphi[s,*,*], $
             theta: udata.theta[s,*,*], $
             dtheta: udata.dtheta[s,*,*], $
             energy: udata.energy[s,*,*], $
             denergy: udata.denergy[s,*,*], $
             bins: udata.bins[s,*,*], $
             charge:udata.charge, $
             mass:udata.mass, $
             magf:udata.magf, $
             sc_pot:udata.sc_pot $
            } 


  if ~undefined(esa_max_energy) then begin
 
    idx = where(min(output.energy,dimension=2) le esa_max_energy,c)

    if c eq 0 then begin
      message,'ERROR:esa_max_energy identifies zero valid bins'
    endif

    output = {data:output.data[idx,*], $ ;particle data 2-d array, energy by angle. (Float or double)
      scaling:output.scaling[idx,*], $ ;scaling coefficient corresponding to 1 count/bin, used for error calculation (float or double)
      time:output.time, $ ;sample start time(1-element double precision scalar)
      end_time:output.end_time, $ ;sample end time(1-element double precision scalar)
      phi:output.phi[idx,*], $ ;Measurment angle in plane parallel to spacecraft spin.(2-d array matching data array.) (Float or double)
      dphi:output.dphi[idx,*], $ ;Width of measurement angle in plane parallel to spacecraft spin.(2-d array matching data array.) (Float or double)
      theta:output.theta[idx,*], $ ;Measurment angle in plane perpendicular to spacecraft spin.(2-d array matching data array.) (Float or double)
      dtheta:output.dtheta[idx,*], $ ;Width of measurement angle in plane perpendicular to spacecraft spin. (2-d array matching data array.) (Float or double)
      energy:output.energy[idx,*], $ ;Contains measurment energy for each component of data array. (2-d array matching data array.) (Float or double)
      denergy:output.denergy[idx,*], $ ;Width of measurment energy for each component of data array. (2-d array matching data array.)
      bins:output.bins[idx,*], $ ; 0-1 array, indicating which bins are enabled for subsequent calculations. (2-d array matching data array.)  (Integer type.)
      charge:output.charge, $ ;expected particle charge (1-element float scalar)
      mass:output.mass, $ ;expected particle mass (1-element float scalar)
      magf:output.magf, $ ;placeholder for magnetic field vector(3-element float array)
      sc_pot:output.sc_pot $ ;placeholder for spacecraft potential (1-element float scalar)
    }

  endif

end
