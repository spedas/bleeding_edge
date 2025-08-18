;+
;Procedure:
;  thm_cmb_clean_sst
;
;
;Purpose:
;  Runs standard SST sanitation routine on data array.
;    -removes excess fields in data structures
;    -performs unit conversion (if UNITS specified)
;    -applies contamination removal (none or default bins)
;
;
;Calling Sequence:
;  thm_cmb_clean_sst, dist_array [,units] [,sst_sun_bins=sst_sun_bins]
;
;Input:
;  dist_array:  SST particle data array from thm_part_dist_array
;  units: String specifying output units
;  sst_sun_bins: Numerical list of contaminated bins to be removed
;  sst_data_mask:  The name of a tplot variable containing a 1-dimensional, 0-1 array indicating SST samples to exclude(0=exclude,1=include),
;                  If values don't match the times of particle data, they'll be nearest neighbor interpolated to match.
;
;Output:
;  none, modifies input
;  
;
;Notes:
;  Further unit conversions will not be possible after sanitation
;  due to the loss of some support quantities.
;
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2016-07-18 12:21:54 -0700 (Mon, 18 Jul 2016) $
;$LastChangedRevision: 21480 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/combined/thm_cmb_clean_sst.pro $
;
;-

pro thm_cmb_clean_sst, data, units=units, sst_sun_bins=sst_sun_bins,sst_method_clean=sst_method_clean,sst_data_mask=sst_data_mask,_extra=ex 

  compile_opt idl2,hidden

  if n_elements(sst_data_mask) ne 0 && tnames(sst_data_mask) ne '' then begin  ;first clause uses short circuit operation because tnames will mutate argument if undefined
    get_data,sst_data_mask,data=sst_mask
  endif
  
  ;loop over pointers
  for i=0, n_elements(data)-1 do begin

    ;loop over structures
    for j=0, n_elements(*data[i])-1 do begin
      
      ;sanitization
      thm_pgs_clean_sst, (*data[i])[j], units, output=temp, sst_sun_bins=sst_sun_bins,sst_method_clean=sst_method_clean,_extra=ex
      
      ;new struct array must be built
      if j eq 0 then begin
        temp_arr = replicate(temp, n_elements(*data[i]))
      endif else begin
        temp_arr[j] = temp
      endelse
      
    endfor

    if is_struct(sst_mask) then begin
      ;interpolate to match data times
      ;rounding creates a nearest neighbor interpolation
      ;consider checking to verify sst_mask.y contains values that are either 0 or 1 and warning if not in range
      mask_idx = where(~round(interpol(sst_mask.y,sst_mask.x,temp_arr.time)),mask_count)
      if mask_count ne 0 then begin
        temp_arr[mask_idx].bins=0
      endif
    endif

    ;remove repeated times
    if n_elements(temp_arr) gt 1 then begin
      idx = where(temp_arr.time ne shift(temp_arr.time,1),c)
      if c gt 0 then begin
        temp_arr = temp_arr[idx]
      endif else begin
        temp_arr = temp_arr[0]
      endelse
    endif
    ;remove repeated times
    ;idx = where((*data[i])
    
    ;replace data
    ptr_free, data[i]
    data[i] = ptr_new(temp_arr, /no_copy)
    
  endfor
  

end