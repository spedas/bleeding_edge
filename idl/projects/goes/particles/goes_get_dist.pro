;+
;Procedure:
;  goes_get_dist
;
;Purpose:
;  Loads GOES MAGED and MAGPD data into standard SPEDAS particle structures
;  and returns pointer (or struct array) for use with goes_part_products
;  and spd_slice2d.
;
;Calling Sequence:
;  data = goes_get_dist( probe=probe, datatype=datatype 
;                        [,trange=trange] [,index=index]
;                        [/structure] [,/uncorrected] )
;
;Input:
;  probe:  probe designation, e.g. '15'
;  datatype:  data type, 'maged' or magpd'
;  trange:  (optional) 2-element time range, all loaded data used if not set
;  index:  (optional) specify index/indices of sample(s) to return, supercedes trange
;  times:  flag to return array of currently loaded sample times
;  structure:  flag to return structure array instead of pointer to structure array 
;  uncorrected:  flag to use dtc_uncor data
;
;Output:
;  return value:  pointer to structure array (defualt)
;                 structure array (/structure)
;                 array of numerical times (/times)
;                 0 - if error occurred
;
;Notes:
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2019-07-16 15:30:48 -0700 (Tue, 16 Jul 2019) $
;$LastChangedRevision: 27472 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/goes/particles/goes_get_dist.pro $
;-

function goes_get_dist, probe=probe, $
                        datatype=datatype_in, $
                        trange=trange, $
                        times=times, $
                        index=index, $
                        uncorrected=uncorrected, $
                        structure=structure

    compile_opt idl2, hidden


if n_elements(probe) ne 1 || ~is_string(probe,/blank) then begin
  dprint, dlevel=1, 'Invalid probe'
  return, 0
endif

if n_elements(datatype_in) ne 1 || ~is_string(datatype_in,/blank) then begin
  dprint, dlevel=1, 'Ivalid datatype'
  return, 0
endif else begin
  datatype = strlowcase(datatype_in)
endelse

if keyword_set(uncorrected) && uncorrected eq 1 then begin
  cor = 'uncori' ;Note it is assumed later that all variables have the same time array, so interpolated variables must be used here, jmm, 2019-07-16
endif else cor = 'cor'

;cor = keyword_set(uncorrected) ? 'uncor':'cor'
names = tnames('g'+probe+'_'+datatype+'_*keV_dtc_'+cor+'_flux')

get_data, names[0], ptr=p 

if ~is_struct(p) then begin
  dprint, dlevel=1, 'Variable: '+names[0]+' contains no valid data'
  return, 0
endif

;return times
;calling code could use get_data but this allows for consistency with other code
if keyword_set(times) then begin
  return, *p.x
endif


; Allow calling code to request a time range and/or specify index
; to specific sample.  This allows calling code to extract 
; structures one at time and improves efficiency in other cases.
;-----------------------------------------------------------------

;index supersedes time range
if undefined(index) then begin
  if ~undefined(trange) then begin
    tr = minmax(time_double(trange))
    index = where( *p.x ge tr[0] and *p.x lt tr[1], n_times)
    if n_times eq 0 then begin
      dprint, 'No data in time range: '+strjoin(time_string(tr),' ')
      return, 0
    endif
  endif else begin
    n_times = n_elements(*p.x)
    index = lindgen(n_times)
  endelse
endif else begin
  n_times = n_elements(index)
endelse


; Get energies from tplot variable names 
;-----------------------------------------------------------------

e_strings = (stregex(names, 'g'+probe+'_'+datatype+'_([0-9]+)keV_dtc_'+cor+'_flux', /sub, /extract))[1,*]

if in_set(e_strings,'') then begin
  dprint, dlevel=0, 'ERROR: Cannot read energy values from tplot variable names' ;shouldn't happen
  return, 0
endif


; Initialize angles, and support data
;-----------------------------------------------------------------

;support data
;  -masses are in eV/(km/s)^2
case strlowcase(datatype) of 
  'magpd': begin
         mass = 1.04535e-2
         charge = 1.
       end
  'maged': begin
         mass = 5.68566e-06
         charge = -1.
       end
  else: begin
    dprint, 'Cannot determine species'
    return, 0
  endelse
endcase

;telescope directions
;order determined by coping helper functions in goes_lib.pro
phi0 = [0., 0, 0, 0, 0, 325, 70, 35, 290]
theta0 = [0., 35, -70, -35, 70, 0, 0, 0, 0]

;dimensions
n_angles = n_elements(phi0)
dim = [n_elements(e_strings), n_angles*2]

;E/azimuth/elevations are constant across time
;add placeholder bins to cover the half sphere not seen by instrument
phi = rebin( transpose( [phi0,(phi0+180) mod 360]), dim )
theta = rebin( transpose( [theta0,theta0] ), dim )
energy = rebin( reform(float(e_strings)), dim ) * 1e3 ;eV

;use view cone width for dphi/dtheta
;these values are not used when generating spectrograms
dphi = replicate(30, dim)
dtheta = replicate(30, dim)


; Create standard 3D distribution
;-----------------------------------------------------------------

base_arr = fltarr(dim)

;basic template structure that is compatible with spd_slice2d
template = {  $
  project_name: 'GOES', $
  spacecraft: probe, $
  data_name: datatype, $
  units_name: 'flux', $
  units_procedure: '', $ ;placeholder
  species:strmid(datatype,3,1), $
  valid: 1b, $

  charge: charge, $
  mass: mass, $
  scaling: base_arr, $ ;placeholder
  time: 0d, $
  end_time: 0d, $

  data: base_arr, $
  bins: base_arr, $

  energy: energy, $
  denergy: base_arr, $ ;placeholder
  phi: phi, $
  dphi: dphi, $
  theta: theta, $
  dtheta: dtheta $
}

;set valid flag only for bins that contain real data
;the rest should remain 0 as placeholders for missing data
template.bins[*,0:n_angles-1] = 1

dist = replicate(template, n_times)


; Populate
;-----------------------------------------------------------------

;use time array of the first tplot variable in the list
;others' times will be checked against this
dist.time = (*p.x)[index]
dist.end_time = (*p.x)[index] + 30 ;TODO: get integ time

for i=0, dim[0]-1 do begin

  get_data, names[i], ptr=p_i

  if ~is_struct(p_i) then begin
    dprint, dlevel=1, 'Variable: '+names[i]+' contains no valid data'
    return, 0
  endif
  
  if n_elements(*p_i.x) ne n_elements(*p.x) || $
     ~array_equal((*p_i.x)[index],dist.time) then begin
     dprint, dlevel=1, 'Sample times for '+names[i]+' do match those of other energies; check time range'
     return, 0
  endif

  ;copy data from tplot variable to corresponding energy
  dist.data[i,0:n_angles-1,*] = reform( transpose( (*p_i.y)[index,*] ), 1,n_angles,n_times)

endfor

;spd_slice2d accepts pointers or structures
;pointers are more versatile & efficient, but less user friendly
if keyword_set(structure) then begin
  return, dist 
endif else begin
  return, ptr_new(dist,/no_copy)
endelse


end



