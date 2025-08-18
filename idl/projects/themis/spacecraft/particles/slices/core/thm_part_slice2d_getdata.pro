;+
;Procedure:
;  thm_part_slice2d_getdata
;
;
;Purpose:
;  Helper function for thm_part_slice2d.pro
;  Returns an array of averaged data along with the corresponding
;  bin centers and widths in spherical coordinates. This routine
;  will apply energy range constraints and count thresholds.
;  
;         
;Input:
;  dist_array: Array of 3d data structures
;  units: String denoting data output units
;  regrid: 3 Element array specifying the new number of points desired in 
;          phi, theta, and energy respectively.
;  erange: Two element array specifying min/max energies to be used
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
;  2014-11-07 count threshold moved to main routine
;  2013-02-05 allow specific values for count threshold
;  2012-12-21 - 2013-07-02 count threshold applied before averaging
; 
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-04 18:05:22 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20331 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/core/thm_part_slice2d_getdata.pro $
;-

pro thm_part_slice2d_getdata, ptr_array, units=units, trange=trange, $ 
                             regrid=regrid, erange=erange, energy=energy, $
                             sst_sun_bins=sst_sun_bins, fix_counts=fix_counts, $
                             rad=rad_out, phi=phi_out, theta=theta_out, $
                             dp=dp_out, dt=dt_out, dr=dr_out, $
                             data=data_out, $
                             fail=fail, $
                             _extra=_extra

    compile_opt idl2, hidden


  thm_part_slice2d_const, c=c

  units_lc = strlowcase(units)

  ;------------------------------------------------------------------
  ;Loop over pointers (modes/datatypes)
  ;------------------------------------------------------------------
  for j=0, n_elements(ptr_array)-1 do begin
      
      
    ;Get indexes of dat structures in reqested time window
    times_ind = thm_part_slice2d_intrange(ptr_array[j], trange, n=ndat)
    if ndat eq 0 then begin
      missing = keyword_set(missing) ? missing++:1
      dprint, dlevel=2, 'No '+(*ptr_array[j])[0].data_name+' data in time range: ' + $
                        time_string(trange[0])+ ' - ' + time_string(trange[1])
      continue
    endif
    
    
    ;Determine data type for sanitization
    thm_pgs_get_datatype, ptr_array[j], instrument=instrument
    
    
    ;------------------------------------------------------------------
    ;Loop over sample times
    ;------------------------------------------------------------------
    for i=0, n_elements(times_ind)-1 do begin
      
      ;Copy data
      dist = ( (*ptr_array[j])[times_ind] )[i]

      
      ;Apply any eclipse corrections
      thm_part_apply_eclipse, dist, eclipse=eclipse
      
      
      ;Set counts to requested value.  This is for recursive calls
      ;with count_threshold/subtract_counts options
      if ~undefined(fix_counts) then begin
        if strlowcase(dist.units_name) ne 'counts' then begin
          fail = 'Data is not in counts, cannot determine '+strtrim(fix_counts,2)+'-count distribution'
          return
        endif
        dist.data[*] = float(fix_counts)
      endif 
      
      ;If this sample's angle or energy bins or mass differ from last then
      ;collate any aggregated data and continue 
      if ~thm_part_checkbins(dist, last) then begin 
        thm_part_slice2d_collate, $
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
      
      
      ;Use standard particle sanitization routines to perform unit
      ;conversion and contamination removal.  This sacrifices some
      ;efficiency in favor of standardization with spectra & moments code.
      if instrument eq 'esa' then begin
        thm_pgs_clean_esa, dist, units_lc, output=clean_dist, _extra=ex
      endif else if instrument eq 'sst' then begin
        thm_pgs_clean_sst, dist, units_lc, output=clean_dist, sst_sun_bins=sst_sun_bins,_extra=ex
      endif else if instrument eq 'combined' then begin
        thm_pgs_clean_cmb, dist, units_lc, output=clean_dist
      endif else begin
        dprint,dlevel=0,'WARNING: Instrument type unrecognized'
        clean_dist = dist
;        return
      endelse 
      
      
      ;Find active, valid bins.
      bins = (clean_dist.bins ne 0) and finite(clean_dist.data)
  
      ;Find bins within energy limits
      if keyword_set(erange) then begin
        n = dimen1(clean_dist.energy)
        energies = thm_part_slice2d_ebounds(clean_dist)
        ecenters = (energies[0:n-1,*]+energies[1:n,*])/ 2
        bins = bins and (ecenters ge erange[0] and ecenters le erange[1])
      endif
  
  
      ;Get data & coordinates.  Coordinates will only be calculated/copied
      ;if the arrays are not in existence, otherwise this just copies the 
      ;data and bins arrays.
      if keyword_set(regrid) then begin
      
        ;Regrid in spherical coordinates
        clean_dist.bins = bins ;ensure energy limited bins are used for regridding
        thm_part_slice2d_regridsphere, clean_dist, regrid=regrid, energy=energy, fail=fail,$ 
                   data=data, bins=bins, rad=rad, phi=phi, theta=theta, dr=dr, dp=dp, dt=dt
      
      endif else begin
      
        ;Get center of each bin plus dphi, dtheta, dr
        thm_part_slice2d_getsphere, clean_dist, energy=energy, fail=fail, $
                   data=data, rad=rad, phi=phi, theta=theta, dr=dr, dp=dp, dt=dt
        
      endelse
                                 
      if keyword_set(fail) then return
    
    
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
  thm_part_slice2d_collate, $
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
