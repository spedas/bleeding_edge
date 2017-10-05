;+
;Procedure:
;  spd_slice2d_get_data
;
;
;Purpose:
;  Helper function for spd_slice2d.pro
;  Returns an array of averaged data along with the corresponding
;  bin centers and widths in spherical coordinates. This routine
;  will apply energy range constraints and count thresholds.
;  
;         
;Input:
;  dist_array: Array of 3d data structures
;  trange: Two element time range
;  erange: Two element array specifying min/max energies to be used
;  energy: flag to get energy instead of velocity bins for radial distances
;   
;   
;Output:
;  data: N element array containing averaged particle data
;  rad: N element array of bin centers along r (eV or km/s)
;  phi: N element array of bin centers along phi
;  theta: N element array of bin centers along theta
;  dr: N element array of bin widths along r (eV or km/s)
;  dp: N element array of bin widths along phi
;  dt: N element array of bin widths along theta
; 
; 
;Notes:
; 
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-10-02 20:01:21 -0700 (Fri, 02 Oct 2015) $
;$LastChangedRevision: 18995 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_slice2d_get_data.pro $
;-

pro spd_slice2d_get_data, ptr_array, trange=trange, erange=erange, energy=energy, $
                          data=data_out, rad=rad_out, phi=phi_out, theta=theta_out, $
                          dp=dp_out, dt=dt_out, dr=dr_out, $
                          fail=fail

    compile_opt idl2, hidden



  ;------------------------------------------------------------------
  ;Loop over pointers (modes/datatypes)
  ;------------------------------------------------------------------
  for j=0, n_elements(ptr_array)-1 do begin
      
      
    ;Get indexes of dat structures in reqested time window
    times_ind = spd_slice2d_intrange(ptr_array[j], trange, n=ndat)
    if ndat eq 0 then begin
      missing = keyword_set(missing) ? missing++:1
      dprint, dlevel=2, 'No '+(*ptr_array[j])[0].data_name+' data in time range: ' + $
                        time_string(trange[0])+ ' - ' + time_string(trange[1])
      continue
    endif
    
    
    ;------------------------------------------------------------------
    ;Loop over sample times
    ;------------------------------------------------------------------
    for i=0, n_elements(times_ind)-1 do begin
      
      ;copy data for ease, performance hit is negligible
      dist = ( (*ptr_array[j])[times_ind] )[i]

      ;If this sample's angle or energy bins or mass differ from last then
      ;collate any aggregated data and continue 
      if ~spd_slice2d_checkbins(dist, last) then begin 
        spd_slice2d_collate, $
          data_t = data_t, weight_t = weight_t, $
          rad_in = rad,  dr_in = dr, $
          phi_in = phi, dp_in = dp, $
          theta_in = theta, dt_in = dt, $
          
          data_out = data_out, $
          rad_out = rad_out, dr_out = dr_out, $
          phi_out = phi_out, dp_out = dp_out, $
          theta_out = theta_out, dt_out = dt_out, $
          
          fail = fail
        if keyword_set(fail) then return
      endif
      
      ;Copy current data for comparison in next iteration
      last = dist
      
      ;Find active, valid bins
      bins = (dist.bins ne 0) and finite(dist.data)
  
      ;Find bins within energy limits
      if keyword_set(erange) then begin
        n = dimen1(dist.energy)
        energies = spd_slice2d_get_ebounds(dist)
        ecenters = (energies[0:n-1,*,*]+energies[1:n,*,*])/ 2
        bins = bins and (ecenters ge erange[0] and ecenters le erange[1])
      endif
  
      ;Get data & bin boundaires
      ;Coordinates will only be calculated/copied if the arrays are not 
      ;in existence, otherwise this just copies the data and bins arrays.
      spd_slice2d_get_sphere, dist, energy=energy, data=data, $
          rad=rad, phi=phi, theta=theta, dr=dr, dp=dp, dt=dt
    
    
      ;Sum of counts over current set of samples
      data_t = keyword_set(data_t) ? data_t+data:data
  
  
      ;Keep track of valid bins within energy range.  This array will later be used
      ;to average bins and discard any that are out of range or invalid.
      weight_t = keyword_set(weight_t) ? (weight_t + bins):bins
      
    endfor
    ;------------------------------------------------------------------
    ;End loop over sample times
    ;------------------------------------------------------------------
    
    
  endfor
  ;------------------------------------------------------------------
  ;End loop over pointers
  ;------------------------------------------------------------------


  ;Collate any remaing data
  spd_slice2d_collate, $
    data_t = data_t, weight_t = weight_t, $
    rad_in = rad,  dr_in = dr, $
    phi_in = phi, dp_in = dp, $
    theta_in = theta, dt_in = dt, $
    
    data_out = data_out, $
    rad_out = rad_out, dr_out = dr_out, $
    phi_out = phi_out, dp_out = dp_out, $
    theta_out = theta_out, dt_out = dt_out, $

    fail = fail

    
  if keyword_set(fail) then return
  
  
  ;Check that data was found in the time range
  if keyword_set(missing) && missing eq n_elements(ptr_array) then begin
    fail = 'No distributions exist within the given time window: '+ $
           time_string(trange[0])+ ' + '+strtrim(trange[1],2)+' sec).'
    dprint, dlevel=0, fail
    return  
  endif
  

  return
  
end
