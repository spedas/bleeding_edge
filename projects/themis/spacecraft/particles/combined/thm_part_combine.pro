;+
;
;Procedure:
;  thm_part_combine.pro
;
;
;Purpose:
;  Create combined particle distributions from ESA and SST data.
;  This distributions acts as a new data type and can be passed 
;  to most THEMIS/SPEDAS particle product routines to create 
;  combined ESA/SST plots.
;  
;  Combined distributions are created in three steps:
;    a) Linear time interpolation
;         -time samples are matched by linearly interpolating the  
;          data set with lower time resolution to match the other
;    b) Linear spherical interpolation
;         -both data sets are interpolated onto the same angular grid
;    c) Energy gap interpolation
;         -once all times/angles match the gap between the 
;          ESA and SST energy ranges is filled in with a logarithmic 
;          linear interpolation (log(flux) vs log(energy))
;          
;
;Calling Sequence:
;  combined_dist = thm_part_combine( probe=probe, trange=trange, 
;                     esa_datatype=esa_datatype, sst_datatype=sst_datatype
;                     [,units=units] [,regrid=regrid] [,energies=energies]
;                     [,orig_esa=orig_esa] [,orig_sst=orig_sst] ... ) 
;                    
;
;Inputs:
;  probe:  Probe designation (string).
;  trange:  Two element array specifying time range (string or double). 
;  esa_datatype:  ESA datatype designation (string).
;  sst_datatype:  SST datatype designation (string). 
;  units:  String specifying output units ('flux', 'eflux', or 'df') 
;  esa_dist:  Pass in manually loaded ESA particle data (see thm_part_dist_array)
;             Must be used with SST_DIST 
;  sst_dist:  Pass in manually loaded SST particle data (see thm_part_dist_array)
;             Must be used with ESA_DIST
;  regrid:  Two element array specifying the number of points used to regrid
;           the data in phi and theta respectively (int or float). 
;  energies:  Array specifying the energy interpolation mid-point targets for all output bins above the ESA.(gap & SST)
;             If unspecified, a hardcoded set of defaults is used. 
;  sst_sun_bins:  Array list of SST bins to mask (bin indices) (int).
;  sst_min_energy: Set to minimum energy to toss bins that are having problems from instrument degradation. (float)
;  esa_max_energy: Set to maximum energy to toss bins that are having problems from instrument contamination.(float) 
;  set_counts:  Set all data to this # of counts before interpolation (for comparison).
;  only_sst: Interpolates ESA to match SST and returns SST(only) with interpolated bins.(Backwards compatibility: functionality of thm_sst_load_calibrate)
;  interp_to_esa: Combined product but data interpolated to match ESA(instead of always interpolating to higher resolution)
;  interp_to_sst: Combined product but data interpolated to match SST(instead of always interpolating to higher resolution)
;  get_sun_direction: Load sun direction with particle data (for 2D slices)
;  esa_bgnd_advanced: Apply advanced ESA background subtraction 
;                     Must call thm_load_esa_bkg first to calculate background
;                     Disables default anode-based background removal
;  extrapolate_esa: Flag to extrapolate from ESA data where no valid SST data exists
;                   instead of throwing error.  Not recommended - use with caution!
;  remove_one_count: removes all bins that are less than one count, suggestion from heli hietala(heli@igpp.ucla.edu)
;  sst_data_mask:  The name of a tplot variable containing a 1-dimensional, 0-1 array indicating SST samples to exclude(0=exclude,1=include),
;                  If values don't match the times of particle data, they'll be nearest neighbor interpolated to match.
;  
;  
;Outputs:
;  combined_dist: Pointer array to combined distribution data.  This is analagous
;                 to the arrays returned by thm_part_dist_array with each element
;                 referencing a distinct mode, or in this case combination of modes.
;  orig_esa: Pointer array to original ESA distribution data.
;  orig_sst: Pointer array to original SST distribution data.
;
;
;General Notes:
;  Combined distributions can be used with the following routines in the same
;  way as output from thm_part_dist_array:
;
;            thm_part_products
;            thm_part_slice2d
;            thm_part_conv_units (unit conversion)
;            
;            thm_part_moments (wrapper/deprecated)
;            thm_part_getspec (wrapper/deprecated)
;            
;  Processing more than 1-2 hours of data (full) at once may cause older systems to 
;  run out of memory.  Typical run times 30-60+ sec.
;  
;
;  SST:  This routine automatically uses the /sst_cal option when loading sst full
;        or burst data and sets default contamination removal options.  No calibrations or contamination
;        removal are applied for reduced data.  Other contamination
;        options may be passed through to override the defaults, see SST contamination 
;        removal crib for options.
;
;
;Developer Notes:
;  In general this code makes the following assumptions about the particle data:
;  
;    -(ESA & SST) The dimensions of all fields will remain constant within a mode.
;    -(ESA & SST) A single distribution's energy bins are constant across all look angles.
;    -(ESA & SST) Energy bins may change within a mode (they probably never will but 
;                 this is assumed for safety).
;    -(ESA & SST) Look directions, while general constant within a mode, may change at
;                 any point due to eclipse corrections to phi values.
;  
;  All E/phi/theta items above are assumed for the bin widths as well.  Greater
;  uniformity is assumed as the data is replaced with interpolated versions.
;     
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2017-10-02 11:19:09 -0700 (Mon, 02 Oct 2017) $
;$LastChangedRevision: 24078 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/combined/thm_part_combine.pro $
;
;-

function thm_part_combine, probe=probe, $
                      esa_datatype=esa_datatype, $
                      sst_datatype=sst_datatype, $
                      esa_dist=esa_dist, $
                      sst_dist=sst_dist, $
                      trange=trange, $
                      units=units,  $
                      regrid=regrid, $
                      energies=energies, $
                      sst_sun_bins=sst_sun_bins, $
                      sst_min_energy=sst_min_energy,$
                      esa_max_energy=esa_max_energy,$
                      set_counts=set_counts, $
                      orig_esa=orig_esa, $
                      orig_sst=orig_sst, $
                      only_sst=only_sst,$ ;Interpolates ESA to match SST and returns SST(only) with interpolated bins. (Backwards compatibility: functionality of thm_sst_load_calibrate)
                      interp_to_esa=interp_to_esa,$ ;Combined product but data interpolated to match ESA(instead of always interpolating to higher resolution)
                      interp_to_sst=interp_to_sst,$ ;Combined product but data interpolated to match SST(instead of always interpolating to higher resolution)
                      get_sun_direction=get_sun_direction, $
                      esa_bgnd_advanced=esa_bgnd_advanced, $
                      extrapolate_esa=extrapolate_esa, $
                      remove_one_count=remove_one_count,$
                      remove_counts=remove_counts, $
                      sst_data_mask=sst_data_mask,$
                      get_error=get_error,$ ;propagate errors, jmm, 2017-09-29
                      _extra=_extra

    compile_opt idl2
     

  ;-------------------------------------------------------------------------------------------
  ;Check inputs and set defaults
  ;-------------------------------------------------------------------------------------------

  heap_gc  ;free memory just in case
  thm_init ;color table & stuffs

  ;get probe and datatype from input structures if provided
  ;this will not overwrite variables that are already set
  thm_pgs_get_datatype, esa_dist, probe=probe, datatype=esa_datatype
  thm_pgs_get_datatype, sst_dist, probe=probe, datatype=sst_datatype  

  if ~undefined(probe) then begin
    probe=probe ;placeholder for validation code
  endif else begin
    dprint, dlevel=1, 'Must specify probe/spacecraft'
    return, 0
  endelse
  
  if ~undefined(esa_datatype) then begin
    esa_datatype=esa_datatype
  endif else begin
    dprint, dlevel=1, 'Must specify ESA data type'
    return, 0
  endelse
  
  if ~undefined(sst_datatype) then begin
    sst_datatype=sst_datatype
  endif else begin
    dprint, dlevel=1, 'Must specify SST data type'
    return, 0
  endelse
  
  if undefined(units) then begin
    units_lc = 'eflux'
  endif else begin
    units_lc = strlowcase(units)
  endelse
  
  if ~in_set(units_lc, ['flux','eflux','df']) then begin
    dprint, dlevel=1, 'Invalid units requested; must be "flux", "eflux", or "df"'  
    return, 0
  endif
  
  if undefined(regrid) then begin
    regrid = [16,8]
  endif
  
  if ~undefined(trange) then begin
    trange=trange
  endif else begin
    trange=timerange()
  endelse

  ;ensure only one background removal method is used  
  esa_bgnd_remove = ~keyword_set(esa_bgnd_advanced)

  ;minimum count threshold will be applied in cleaning routines
  if ~undefined(remove_one_count) && undefined(remove_counts) then begin
    remove_counts=1.
  endif

  if ~undefined(energies) then begin
    energies=energies
  endif else begin
    ;picked fairly arbitrarily
    if strlowcase(strmid(sst_datatype,2,1)) eq 'i' then begin
      energies = [25000,26000.,28000.,30000.0,34000.0,41000.0,53000.0,67400.0,95400.0,142600.,207400.,297000.,421800.,654600.,1.13460e+06,2.32980e+06,4.00500e+06]
    endif else begin
      energies = [27000,28000.,29000.,30000.0, 31000.0,41000.0,52000.0,65500.0,93000.0,139000.,203500.,293000.,408000.,561500.,719500.]
    endelse
  endelse
  
  start_time=systime(/sec)


  ;-------------------------------------------------------------------------------------------
  ;Load Data
  ;-------------------------------------------------------------------------------------------

  ;load pointers to distribution arrays
  if (ptr_valid(esa_dist))[0] xor (ptr_valid(sst_dist))[0] then begin
    dprint, dlevel=0, 'ESA_DIST and SST_DIST keywords bust be used simultaneously; canceling.'
    return, 0
  endif else if (ptr_valid(esa_dist))[0] and (ptr_valid(sst_dist))[0] then begin
    thm_part_copy, sst_dist, sst
    thm_part_copy, esa_dist, esa
  endif else begin
    sst_cal = stregex(sst_datatype, 'ps[ei]r', /bool, /fold_case) ? 0b:1b
    sst = thm_part_dist_array(probe=probe,type=sst_datatype,trange=trange,sst_cal=sst_cal,_extra=_extra)
    esa = thm_part_dist_array(probe=probe,type=esa_datatype,trange=trange,bgnd_remove=esa_bgnd_remove,_extra=_extra)
  endelse

  if ~ptr_valid(sst[0]) or ~ptr_valid(esa[0]) then begin
    dprint, dlevel=0, 'Unable to load data.  Check requested datatype and time range.'
    return, 0
  endif

  ;copy out original dists if requested
  ;(this is mainly for testing and may not be a useful feature)
  if arg_present(orig_sst) then thm_part_copy, sst, orig_sst
  if arg_present(orig_esa) then thm_part_copy, esa, orig_esa

  ;fix counts to specified level if requested
  ;in this case the output can then be used as comparison with real data
  if ~undefined(set_counts) && is_num(set_counts) then begin
    thm_part_set_counts, sst, set_counts
    thm_part_set_counts, esa, set_counts
  endif

  ;convert to flux and remove unnecessary fields from structures
  ;(energy interpolation should be perfomed in flux)
  thm_cmb_clean_sst, sst, units='flux', sst_sun_bins=sst_sun_bins,sst_min_energy=sst_min_energy,sst_data_mask=sst_data_mask, remove_counts=remove_counts
  thm_cmb_clean_esa, esa, units='flux', esa_max_energy=esa_max_energy, esa_bgnd_advanced=esa_bgnd_advanced, remove_counts=remove_counts

  ;-------------------------------------------------------------------------------------------
  ;Time interpolation
  ;-------------------------------------------------------------------------------------------
  
  ;get number of samples for each instrument
  for i=0, n_elements(esa)-1 do n_esa_samples = array_concat(n_elements(*esa[i]),n_esa_samples)
  for i=0, n_elements(sst)-1 do n_sst_samples = array_concat(n_elements(*sst[i]),n_sst_samples)

  ;interpolate to instrument with higher time resolution
 
  ;TODO: Calling both interpolations is a quick fix that prevents a crash.
  ;The interpolation logic used in the SST matching, matches source to target, but not target to source.
  ;To ensure they're mutually matching for the combine operation and prevent errors, you need to call it forward & backwards.
  ;But this is inefficient. Aaron said he's got a plan to rewrite time interpolation to interpolate mutually in the future
  if ~keyword_set(interp_to_sst) && ~keyword_set(only_sst) && (total(n_esa_samples) gt total(n_sst_samples) || keyword_set(interp_to_esa)) then begin
    thm_part_time_interpolate,sst,esa,error=time_interp_error
    thm_part_time_interpolate,esa,sst,error=time_interp_error
  endif else begin
    thm_part_time_interpolate,esa,sst,error=time_interp_error
    thm_part_time_interpolate,sst,esa,error=time_interp_error
  endelse
  
  
  if keyword_set(time_interp_error) then message, 'time interp error'
  
  
  ;-------------------------------------------------------------------------------------------
  ;Angular interpolation
  ;-------------------------------------------------------------------------------------------

  ;interpolate both ESA and SST angles on to the same grid
  ;  TODO: allow interpolate to one instruments angles? (interpolating to ESA could be awful)
  thm_part_sphere_interp,esa,sst,regrid=regrid,error=esa_sphere_interp_error,get_error=get_error
  thm_part_sphere_interp,sst,esa,regrid=regrid,error=sst_sphere_interp_error,get_error=get_error

  if keyword_set(esa_sphere_interp_error) then message, 'ESA sphere interp error'
  if keyword_set(sst_sphere_interp_error) then message, 'SST sphere interp error'
  
  
  ;-------------------------------------------------------------------------------------------
  ;Energy interpolation
  ;-------------------------------------------------------------------------------------------
  
  ;do this as normal for now
  thm_part_energy_interp,sst,esa,energies,error=energy_interp_error,extrapolate_esa=extrapolate_esa,get_error=get_error
  
  if keyword_set(energy_interp_error) then message, 'energy interp error'

  ;-------------------------------------------------------------------------------------------
  ;Form final distribution
  ;-------------------------------------------------------------------------------------------

  ;create output product
  thm_part_merge_dists, esa, sst, out_dist=out_dist, only_sst=only_sst,$
           probe=probe, esa_datatype=esa_datatype, sst_datatype=sst_datatype

  ;convert into requested units
  thm_part_conv_units, out_dist, units=units_lc

;remove negative values, which can show up even without interpolation
;there should never be negative values in the 3d data arrays, which
;are counts-based, jmm, 2017-05-05
  ndist = n_elements(out_dist)
  For j = 0, ndist-1 Do Begin
     If(ptr_valid(out_dist[j]) && is_struct(*out_dist[j])) Then Begin
        (*out_dist[j]).data = (*out_dist[j]).data > 0
        (*out_dist[j]).scaling = (*out_dist[j]).scaling > 0
     Endif
  Endfor

  ;if original data is being passed out ensure the units are identical to primary output
  if arg_present(orig_sst) then thm_part_conv_units, orig_sst, units=units_lc
  if arg_present(orig_esa) then thm_part_conv_units, orig_esa, units=units_lc

  ;add sun direction if requested
  if keyword_set(get_sun_direction) then begin
    thm_part_addsun, out_dist, probe=probe, trange=trange
  endif

  print, string(10b), 'FINISHED - RUNTIME: '+strtrim(systime(/sec)-start_time,2)+' sec', string(10b)
  
  heap_gc ;why not?
  
  return, out_dist

end
