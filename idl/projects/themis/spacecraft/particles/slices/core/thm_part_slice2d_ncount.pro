
;+
;Procedure:
;  thm_part_slice2d_ncount
;
;Purpose:
;  Helper function for thm_part_slice2d_getxyz
;  Converts one count value to requested units and returns converted data array.
;
;Input:
;  dat: 3d data structure to be used
;  units: string describing new units
;
;Output:
;  return value: array of data corresponding to the specified number of counts
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-04 18:05:22 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20331 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/core/thm_part_slice2d_ncount.pro $
;
;-
function thm_part_slice2d_ncount, dist_in, units, threshold, regrid=regrid

    compile_opt idl2, hidden


  ;copy in case an original was passed in
  dist = dist_in
  
  ;get instrument type
  thm_pgs_get_datatype, ptr_new(dist), instrument=instrument

  ;set to desired level & units
  ; -this can be done w/o an explicit unit conversion becaue only
  ;   the "data" field is modified by unit conversions
  dist.data[*] = threshold
  dist.units_name = 'counts'

  ;apply sanitization to get a congruent data structure
  if instrument eq 'esa' then begin
    thm_pgs_clean_esa, temporary(dist), units, output=dist, _extra=ex
  endif else if instrument eq 'sst' then begin
    thm_pgs_clean_sst, temporary(dist), units, output=dist, sst_sun_bins=sst_sun_bins,_extra=ex
  endif else if instrument eq 'combined' then begin
    thm_pgs_clean_cmb, temporary(dist), units, output=dist
  endif else begin
    dprint, dlevel=0, 'WARNING: Instrument type unrecognized'
    return, 0
  endelse 

  if ~is_struct(dist) then begin
    dprint, dlevel=0, 'WARNING: Error sanitizing data for count threshold'
    return, 0
  endif  

  ;apply regridding
  if keyword_set(regrid) then begin
    thm_part_slice2d_regridsphere, dist, regrid=regrid, data=data, fail=fail 
    if keyword_set(fail) then begin
      dprint, dlevel=0, fail
      return, 0
    endif
    return, data
  endif
  
  return, dist.data
      
end

