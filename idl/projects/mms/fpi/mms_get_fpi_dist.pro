;+
;Procedure:
;  mms_get_fpi_dist
;
;Purpose:
;  Returns 3D particle data structures containing MMS FPI
;  data for use with SPEDAS particle routines. 
;
;Calling Sequence:
;  data = mms_get_fpi_dist(tname [,index] [,trange=trange] [,/times] [,/structure]
;                                [,probe=probe] [,species=species] )
;
;Input:
;  tname: Tplot variable containing the desired data.
;  single_time: Return a single time nearest to the time specified by single_time (supersedes trange and index)
;  index:  Index of time samples to return (supersedes trange)
;  trange:  Two element time range to constrain the requested data
;  times:  Flag to return full array of time samples
;  structure:  Flag to return a structure array instead of a pointer.  
;
;  probe: specify probe if not present or correct in input_name 
;  species:  specify species if not present or correct in input_name
;  subtract_error: subtract the distErr (variable specified by the keyword: error) data before returning
;  error: variable name of the disterr variable, e.g.:
;        'mms#_des_disterr_fast'
;         
;        for fast survey electron data
;         
;Output:
;  return value: pointer to array of 3D particle distribution structures
;                or 0 in case of error
;
;Notes:
;  -FPI angles stored in tplot describe instrument look directions, 
;   this converts those to presumed trajectories (swaps direction).
;
;  - Updated to accept FPI error data on 22Sept2017 
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2019-04-10 08:51:06 -0700 (Wed, 10 Apr 2019) $
;$LastChangedRevision: 26986 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_get_fpi_dist.pro $
;-

function mms_get_fpi_dist, tname, index, trange=trange, times=times, structure=structure, $
                           species = species, probe = probe, single_time = single_time, $
                           data_rate = data_rate, level = level, subtract_error=subtract_error, $
                           error=error

    compile_opt idl2, hidden

if ~undefined(level) then level = strlowcase(level) else level = 'l2'

name = (tnames(tname))[0]
if name eq '' then begin
  dprint, 'Variable: "'+tname+'" not found'
  return, 0
endif

;pull data and metadata
get_data, name, ptr=p, dlimits=dl

if ~is_struct(p) then begin
  dprint, 'Variable: "'+tname+'" contains invalid data'
  return, 0
endif

if size(*p.y,/n_dim) ne 4 then begin
  dprint, 'Variable: "'+tname+'" has wrong number of elements'
  return, 0
endif

;get info from tplot variable name
var_info = stregex(tname, 'mms([1-4])_d([ei])s_dist(err)?_(brst|fast|slow).*', /subexpr, /extract)

;use info from the variable name if not explicitly set
if var_info[0] ne '' then begin
  if ~is_string(probe) then probe = var_info[1]
  if ~is_string(species) then species = var_info[2]
 ; if undefined(data_rate) then data_rate = var_info[4]
endif

;double check that required info is defined
if ~is_string(probe) || ~is_string(species) then begin
  dprint, 'Cannot determine probe/species from variable name, please specify by keyword'
  return, 0
endif

;return times
;calling code could use get_data but this allows for consistency with other code
if keyword_set(times) then begin
  return, *p.x
endif

if keyword_set(subtract_error) && ~keyword_set(error) then begin
  dprint, dlevel = 0, 'Error, no error variable provided; be sure to specify the name of the tplot variable containing the error via the keyword: error'
  return, -1
endif

if ~keyword_set(subtract_error) && keyword_set(error) then begin
  dprint, dlevel = 0, 'Warning: error data provided, but error subtraction not requested (no error will be subtracted)'
endif

if keyword_set(subtract_error) && keyword_set(error) then begin
  get_data, error, ptr=errdata
  if ~is_struct(errdata) then begin
    dprint, dlevel = 0, 'Error, no error variable found.'
    return, -1
  endif
endif

; Allow calling code to request a time range and/or specify index
; to specific sample.  This allows calling code to extract 
; structures one at time and improves efficiency in other cases.
;-----------------------------------------------------------------

; single_time supersedes index and trange
if ~undefined(single_time) then begin
  nearest_time = find_nearest_neighbor(*p.x, time_double(single_time))
  if nearest_time eq -1 then begin
    dprint, 'Cannot find requested time in the data set: ' + time_string(single_time)
    return, 0
  endif
  index = where(*p.x eq nearest_time)
  n_times = n_elements(index)
endif else begin
  ;index supersedes time range
  if undefined(index) then begin
    if ~undefined(trange) then begin
      tr = minmax(time_double(trange))
      index = where( *p.x ge tr[0] and *p.x lt tr[1], n_times)
      if n_times eq 0 then begin
        dprint, 'No data in time range: '+strjoin(time_string(tr, tformat='YYYY-MM-DD/hh:mm:ss.fff'),' ')
        return, 0
      endif
    endif else begin
      n_times = n_elements(*p.x)
      index = lindgen(n_times)
    endelse
  endif else begin
    n_times = n_elements(index)
  endelse
endelse 

; Initialize angles, and support data
;-----------------------------------------------------------------

;dimensions
;data is stored as azimuth x elevation x energy x time
;time must be last for fields to be added to time varying structure array
;slice code expects energy to be the first dimension
dim = (size(*p.y,/dim))[1:*]
dim = dim[[2,0,1] ]
base_arr = dblarr(dim)

;support data
;  -slice routines assume mass in eV/(km/s)^2
case strlowcase(species) of 
  'i': begin
         mass = 1.04535e-2
         charge = 1.
         data_name = 'FPI Ion'
         if keyword_set(data_rate) and keyword_set(level) then begin
             if data_rate eq 'brst' and level eq 'l2' then integ_time = .150
             if data_rate eq 'brst' and level eq 'acr' then integ_time = 0.0375
         endif
         if keyword_set(data_rate) && data_rate eq 'fast' then  integ_time = 4.5
       end
  'e': begin
         mass = 5.68566e-06
         charge = -1.
         data_name = 'FPI Electron'
         if keyword_set(data_rate) and keyword_set(level)  then begin
           if data_rate eq 'brst' and level eq 'l2' then integ_time = .03
           if data_rate eq 'brst' and level eq 'acr' then integ_time = 0.0075
         endif
         if keyword_set(data_rate) && data_rate eq 'fast' then  integ_time = 4.5
       end
  else: begin
    dprint, 'Cannot determine species'
    return, 0
  endelse
endcase

;elevations are constant across time
;convert colat -> lat
theta = rebin( reform(90-*p.v2,[1,1,dim[2]]), dim )

dphi = replicate(11.25, dim)
dtheta = replicate(11.25, dim)


; Create standard 3D distribution
;-----------------------------------------------------------------


;basic template structure that is compatible with spd_slice2d
template = {  $
  project_name: 'MMS', $
  spacecraft: probe, $
  data_name: data_name, $
  ;units_name: 'f (s!U3!N/cm!U6!N)', $
  units_name: 'df_cm', $
  units_procedure: 'mms_part_conv_units', $ ;placeholder
  species:species,$
  valid: 1b, $

  charge: charge, $
  mass: mass, $  
  time: 0d, $
  end_time: 0d, $

  data: base_arr, $
  bins: base_arr+1, $ ;must be set or data will be considered invalid

  energy: base_arr, $
  denergy: base_arr, $ ;placeholder
  nenergy: dim[0], $ ; # of energies
  nbins: dim[1]*dim[2], $ ; # thetas * # phis
  phi: base_arr, $
  dphi: dphi, $
  theta: theta, $
  dtheta: dtheta $
}

dist = replicate(template, n_times)

; Populate
;-----------------------------------------------------------------
if undefined(integ_time) then begin
    ; if the user didn't specify data_rate, we'll have to guess the integration time from 
    ; the metadata
;    if is_struct(dl) then begin
;      str_element, dl, 'cdf.gatt.time_resolution', time_resolution, success=s
;      if s eq 1 then begin
;        tres = strsplit(time_resolution, ' ', /extract)
;        if tres[1] eq 'milliseconds' then factor_to_seconds = 1000.0 else factor_to_seconds = 1.
;        integ_time = float((tres)[0])/factor_to_seconds
;      endif
;    endif
    ; time resolution not in the metadata, try to guess it from the data
  ;  if s eq 0 then begin
  ; if n_elements(index) eq 1 then begin
  ;    if index ne 0 then begin
  ;        integ_time = (*p.x)[index]-(*p.x)[index-1] 
  ;    endif else begin
  ;        integ_time = (*p.x)[index+1]-(*p.x)[index]
  ;    endelse
  ; endif else begin
  ;    integ_time = (*p.x)[index[0]+1]-(*p.x)[index[0]]
  ; endelse
  ; if is_array(integ_time) then integ_time = integ_time[0]
 
   ; new way of determining integration time, 7/19/2017
   ; use the median of the delta times
   times = (*p.x)
   delta_t = times[1:*]-times[*]
   integ_time = average(delta_t, /nan, /ret_median)
  
;    endif
   ; now that we're taking the integration time from the data, we need to make sure it's a known integration time
   ; for the FPI dataset; this is so that we can stop/error if the integration time is outside of any known values
   ; update on 7/13/17 by egrimes; changed to percent error check for known integration times; halt if % error is >= 2%
   known_integration_times = [0.0075, 0.03, 0.0375, .150, 4.5, 59] 
   find_int_time = where(abs(known_integration_times-integ_time)/integ_time lt 0.02, itime_count)
   if itime_count eq 0 then begin
      dprint, dlevel = 0, 'Error, problem finding integration time from the data; this shouldn''t happen; contact: egrimes@igpp.ucla.edu'
      stop
   endif else dprint, dlevel = 4, 'No integration time specified in mms_get_fpi_dist; guessed ' + strcompress(string(integ_time), /rem) + ' seconds from the data'

endif
dist.time = (*p.x)[index]
dist.end_time = (*p.x)[index] + integ_time

;shuffle data to be energy-azimuth-elevation-time
dist.data = transpose((*p.y)[index,*,*,*],[3,1,2,0])

if keyword_set(subtract_error) && ~undefined(errdata) then begin
  dist.data = dist.data-transpose((*errdata.y)[index,*,*,*],[3,1,2,0])
endif 

if size(/n_dim, *p.v3) eq 1 then begin
  e0 = *p.v3 ;fast data uses constant table
endif else begin
  e0 = reform( transpose((*p.v3)[index,*]), [dim[0],1,1,n_times])
endelse
dist.energy = rebin( e0, [dim,n_times] )

;get azimuth values for each time sample and copy into
;structure array with the correct dimensions
if size(/n_dim, *p.v1) eq 1 then begin
  phi0 = transpose(*p.v1) ;fast data uses constant table
endif else begin
  phi0 = reform( transpose((*p.v1)[index,*]), [1,dim[1],1,n_times])
endelse

dist.phi = rebin( phi0, [dim,n_times] )

;convert angles to SPEDAS convention
;  -MMS convention stores angles as look direction of instrument whereas
;   SPEDAS uses presumed particle trajectories
;ensure phi is in [0,360) 
dist.phi = (dist.phi + 180) mod 360
dist.theta = -dist.theta

;spd_slice2d accepts pointers or structures
;pointers are more versatile & efficient, but less user friendly
if keyword_set(structure) then begin
  return, dist 
endif else begin
  return, ptr_new(dist,/no_copy)
endelse


end