;+
;Procedure:
;  mms_get_hpca_dist
;
;Purpose:
;  Returns pseudo-3D particle data structures containing mms hpca data
;  for use with spd_slice2d.
;
;Calling Sequence:
;  data = mms_get_hpca_dist(tname [,index] [,trange=trange] [,/times] [,/structure]
;                                 [,probe=probe] [,species=species] [,units=units] )
;
;Input:
;  tname: Tplot variable containing the desired data.
;  single_time: Return a single time nearest to the time specified by single_time (supersedes trange and index)
;  index:  Index of time samples to return (supersedes trange)
;  trange:  Two element time range to constrain the requested data
;  times:  Flag to return full array of time samples
;  structure:  Flag to return a structure array instead of a pointer.  
;
;  probe: Specify probe if not present or correct in input_name 
;  species:  Specify species if not present or correct in input_name
;  units:  Specify units of input data if not present or correct in input_name
;
;
;Output:
;  return value: pointer to array of pseudo 3D particle distribution structures
;                or 0 in case of error
;
;Notes:
;     The HPCA data is required to be at the center of the measurement interval for this routine
;     to work properly; be sure to use the keyword: /center_measurement when calling mms_load_hpca
;     
;     Still a work in progress; report bugs to egrimes@igpp.ucla.edu
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2020-11-12 13:32:47 -0800 (Thu, 12 Nov 2020) $
;$LastChangedRevision: 29351 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/hpca/mms_get_hpca_dist.pro $
;-

function mms_get_hpca_dist, tname, index, trange=trange, times=times, structure=structure, $
                            probe=probe, species=species, units=units, single_time=single_time

    compile_opt idl2, hidden


name = (tnames(tname))[0]
if name eq '' then begin
  dprint, dlevel=0, 'Variable: "'+tname+'" not found'
  return, 0
endif

;pull data and metadata
get_data, name, ptr=p, dlimits=dl


if ~is_struct(p) then begin
  dprint, dlevel=0, 'Variable: "'+tname+'" contains invalid data'
  return, 0
endif

if size(*p.y,/n_dim) ne 3 then begin
  dprint, dlevel=0, 'Variable: "'+tname+'" has wrong number of elements'
  return, 0
endif

if ~is_struct(dl) then begin
  dprint, dlevel=0, 'Variable: "'+tname+'" contains invalid metadata'
  return, 0
endif

if ~tag_exist(dl, 'centered_on_load') then begin
  dprint, dlevel=0, '########################### WARNING #############################'
  dprint, dlevel=0, '#################################################################'
  dprint, dlevel=0, 'Variable: "'+tname+'" does not appear to be at the center of the accumulation interval; /center_measurement is keyword required for HPCA distributions prior to calling this routine. You can ignore this warning if you have manually centered the data to the accumulation interval using a method other than the /center_measurement keyword in the call to mms_load_hpca'
  dprint, dlevel=0, '#################################################################'
  dprint, dlevel=0, '########################### WARNING #############################'
endif

;get some basic info from name
var_info = stregex(name, 'mms([1-4])_hpca_([^_]+)_(.+)', /subexpr, /extract)

if var_info[0] ne '' then begin
  if undefined(probe)then probe = var_info[1]
  if undefined(species) then species = var_info[2]
  if undefined(units) then units = var_info[3]
endif

;double check that required info is defined
if undefined(probe) || undefined(species) || undefined(units) then begin
  dprint, 'Cannot determine probe/species/units from variable name, please specify by keyword'
  return, 0
endif

;make sure units are recognizable to transform routine
units_name = units eq 'phase_space_density' ? 'df_cm' : units
if ~stregex(units_name,'^((e?flux)|(df(_[ck]m)?)|(psd))$',/bool,/fold) then begin
  dprint, 'Units not recognized: "'+units+'"  Please verify variable name or keyword input'
  return, 0
endif

; Match particle data to azimuth data
;-----------------------------------------------------------------

;get azimuths and full dist sample times from ancillary variable
get_data, 'mms'+probe+'_hpca_azimuth_angles_per_ev_degrees', ptr=azimuth

if ~is_struct(azimuth) then begin
  dprint, dlevel=0, 'No azimuth data found for the current time range'
  return, 0
endif

; check if the time series is monotonic
; to avoid doing incorrect calculations when there's a problem with the CDF files
time_data = *azimuth.x

wherenonmono = where(time_data[1:*] le time_data, countnonmono)
if countnonmono ne 0 then begin
  dprint, dlevel = 0, 'Error, non-monotonic data found in the HPCA Epoch_Angles time series data'
  return, 0
endif

;find azimuth times with complete 1/2 spins of particle data
;this is used to determine the number of 3D distributions that will be created
;and where their corresponding data is located in the particle data structure
n_times = n_elements((*azimuth.y)[0,0,*])  ;# data samples for each azimuth array 
data_idx = value_locate(*p.x, time_data)  ;data index corresponding to each azimuth array
full = where( (data_idx[1:*] - data_idx[0:n_elements(data_idx)-2]) eq n_times, n_full)
if n_full eq 0 then begin
  dprint, dlevel=0, 'Azimuth data does not cover current data''s time range'
  return, 0
endif

;filter times when azimuth data is all zero
;  -just check the first energy & elevation
;  -assume azimuth values are positive
valid_az = where( total((*azimuth.y)[full,0,0,*],4) ne 0, n_valid_az, ncomp=n_blank)
if n_blank gt 0 then begin
  if n_valid_az eq 0 then begin
    dprint, dlevel=0, 'Azimuth data is all zero for requested time range'
    return, 0
  endif
  full = full[valid_az]
  n_full = n_elements(full)
endif


; Return matched times if requested
;   -This allows calling code to loop over indices without having to determine
;    which (azimuth) times are associate with complete data sets
;   -These times are not center of distribution but center of first energy sweep
;------------------------------------------------------------------
if keyword_set(times) then begin
  return, (time_data)[full]
endif

; Allow calling code to request a time range or specify index to specific sample.
;-----------------------------------------------------------------
if ~undefined(single_time) then begin
  nearest_time = find_nearest_neighbor((time_data)[full], time_double(single_time))
  if nearest_time eq -1 then begin
    dprint, 'Cannot find requested time in the data set: ' + time_string(single_time)
    return, 0
  endif
  nearest_index = where((time_data)[full] eq nearest_time, n_full)
  full = full[nearest_index[0]]
endif else begin
  if ~undefined(index) then begin
    full = full[index]
    n_full = n_elements(full)
  endif else if ~undefined(trange) then begin
    tr = minmax(time_double(trange))
    index = where( (time_data)[full] ge tr[0] and (time_data)[full] lt tr[1], n_full)
    if n_full eq 0 then begin
      dprint, 'No data in time range: '+strjoin(time_string(tr),' ')
      return, 0
    endif
    full = full[index]
  endif
endelse

if n_elements(data_idx) gt 1 && data_idx[0] eq -1 then data_idx = data_idx[1:*]
data_idx = data_idx[full]


; Initialize energies, angles, and support data
;-----------------------------------------------------------------

;final dimensions for a single distribution (energy-azimuth-elevation)
azimuth_dim = dimen(*azimuth.y) ;time-energy-elevation-azimuth
dim = azimuth_dim[ [1,4,3] ]   ;energy-azimuth-elevation
base_arr = fltarr(dim)

;mass & charge of species
;  -slice routines assume mass in eV/(km/s)^2
case species of 
  'hplus':begin
    mass = 1.04535e-2
    charge = 1.
  end
  'heplus':begin
    mass = 4.18138e-2
    charge = 1.
  end
  'heplusplus':begin
    mass = 4.18138e-2
    charge = 2.
  end
  'oplus':begin
    mass = 0.167255
    charge = 1.
  end
  'oplusplus':begin
    mass = 0.167255
    charge = 2.
  end
  else: begin
    dprint, dlevel=0, 'Cannot determine species'
    return, 0
  endelse
endcase

;energy bins are constant
energy = rebin(*p.v2, dim)

;elevations bins are constant
;  -convert to from colat to lat
theta = rebin( reform( float(90 - *p.v1),[1,1,dim[2]] ), dim)
dtheta = replicate(22.5, dim)

;azimuths are be populated below


; Create standard 3D distributions
;-----------------------------------------------------------------

;basic template structure that is compatible with spd_slice2d
template = {  $
  project_name: 'MMS', $
  spacecraft: probe, $
  data_name: 'HPCA '+species, $
  units_name: units_name, $
  units_procedure: 'mms_part_conv_units', $ ;placeholder
  species:species, $
  valid: 1b, $

  charge: charge, $
  mass: mass, $  
  time: 0d, $
  end_time: 0d, $

  data: base_arr, $
  bins: base_arr+1, $ ;must be set or data will be considered invalid

  energy: energy, $
  denergy: base_arr, $
  nenergy: dim[0], $ ; # of energies
  nbins: dim[1]*dim[2], $ ; # thetas * # phis
  phi: base_arr, $
  dphi: base_arr, $
  theta: theta, $
  dtheta: dtheta $
}

dist = replicate(template, n_full)


; Populate the structures
;-----------------------------------------------------------------

;get start/end times
;  -this assumes that the times from the particle (and angle) data 
;   are at the center of the corresponding energy sweep
;  -also assumes that there are no gaps in the data
dt = (time_data)[1:*] - (time_data)[0:*]  ;delta-time for each 1/2 spin
dt_sweep = (*p.x)[1:*] - (*p.x)[0:*]        ;delta-time for each full energy sweep
dist.time = (time_data)[full] - dt_sweep[data_idx]
dist.end_time = dist.time + dt[full]  ;index won't exceed elements due to selection criteria

;get azimuth 
;  -shift from time-energy-elevation-azimuth to energy-azimuth-elevation-time
;   (time must be last to be added to structure array)
dist.phi = transpose( (*azimuth.y)[full,*,*,*], [1,3,2,0])

;get dphi
;  -use median distance between subsequent phi measurements within each distribution
;   (median is used to discard large differences across 0=360)
;  -preserve dimensionality in case differences arise across energy or elevation
dphi = median( (*azimuth.y)[full,*,*,1:*] - (*azimuth.y)[full,*,*,0:*], dim=4 ) ;get median across phi
dphi = rebin( dphi, [dimen(dphi),dim[1]] ) ;expand back to original dimensions
dist.dphi = transpose( dphi, [1,3,2,0] ) ;shuffle dimensions


data_times = *p.x

;copy particle data
for i=0,  n_elements(dist)-1 do begin
  ; need to extract the data from the center of the half-spin
  if data_idx[i]-n_times/2. lt 0 then start_idx = 0 else start_idx = data_idx[i]-n_times/2.
  if data_idx[i]+n_times/2.-1 ge n_elements(data_times) then end_idx = n_elements(data_times)-1 else end_idx = data_idx[i]+n_times/2.-1
  ;shift from azimuth-energy-elevation to energy-azimuth-elevation
  dist[i].data = transpose( (*p.y)[start_idx:end_idx,*,*], [1,0,2])
endfor

;ensure phi values are in [0,360]
;  -this may be unnecessary with new spinangle cdfs
;dist.phi = (dist.phi + 360) mod 360

;spd_slice2d accepts pointers or structures
;pointers are more versatile & efficient, but less user friendly
if keyword_set(structure) then begin
  return, dist 
endif else begin
  return, ptr_new(dist,/no_copy)
endelse


end
