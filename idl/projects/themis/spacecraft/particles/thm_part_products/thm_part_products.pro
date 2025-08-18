;+
;PROCEDURE: 
;  thm_part_products
;
;
;PURPOSE:
;  Generate spectra and moments from  THEMIS particle data. 
;  Provides different angular view and angle restriction options 
;  in spacecraft and field alligned coordinates.
;
;
;Data Products:
;  'energy' - energy spectrogram
;  'phi' - azimuthal spectrogram 
;  'theta' - elevation spectrogram
;  'gyro' - gyrophase spectrogram
;  'pa' - pitch angle spectrogram
;  'moments' - distribution moments (density, velocity, etc.)
;
;
;Calling Sequence:
;  thm_part_products, probe=probe, datatype=datatype, trange=trange [,outputs=outputs] ...
;
;
;Example Usage:
;  See crib sheets in .../themis/examples/
;
;
;Input Keywords:
;  probe:  Spacecraft designation, e.g. 'a','b'
;  datatype:  Particle datatype, e.g. 'psif, 'peib'
;  trange:  Two element time range [start,end]
;
;  outputs:  List of requested outputs, array or space separated list, default='energy'
;
;  dist_array:  Data loaded manually with thm_part_dist_array or thm_part_combine.
;               If specified then probe and dataytpe are not needed; trange is optional.
;               Outputs will be in the data's units (probably counts, or eflux for combined) 
;               unless specified with UNITS keyword.
;
;  energy:  Two element energy range [min,max], in eV
;  phi:  Two element phi range [min,max], in degrees, spacecraft spin plane
;  theta:  Two element theta range [min,max], in degrees, latitude from spacecraft spin plane
;  pitch:  Two element pitch angle range [min,max], in degrees, magnetic field pitch angle
;  gyro:  Two element gyrophase range [min,max], in degrees, gyrophase  
;
;  mag_name:  Tplot variable containing magnetic field data for moments and FAC transformations 
;  pos_name:  Tplot variable containing spacecraft position for FAC transformations
;  sc_pot_name:  Tplot variable containing spacecraft potential data for moments corrections
;    
;  units:  Specify units of output variables.  Must be 'eflux' to calculate moments.
;            'counts' -   #
;            'rate'   -   # / s
;            'flux'   -   # / (cm^2 * s * sr * eV)
;            'eflux'  -  eV / (cm^2 * s * sr * eV)  <default>
;            'df'     -  s^3 /(cm^3 * km^3)
;
;  regrid:  Two element array specifying the resolution [azimuth,elevation]
;           used to regrid the data; default is [16,8].  Field aligned data
;           is always regridded while phi and theta spectra are regridded if
;           this keyword is specified.
;
;  fac_type:  Select the field aligned coordinate system variant.
;             Existing options: 'phigeo', 'mphigeo', 'xgse'
;  
;  sst_sun_bins:  Array of which sst bins to decontaminate (list of bins numbers, not the old mask array)
;                 Set to -1 to disable.
;  esa_bgnd_remove:  Set to 0 to disable ESA background removal, 
;                    otherwise default anode-based background will be subtracted.
;                    See thm_crib_esa_bgnd_remove for more keyword options.
;  esa_bgnd_advanced:  Apply advanced ESA background subtraction. 
;                      Must call thm_load_esa_bkg first to calculate background.
;                      Disables default background removal.
;
;  suffix:  Suffix to append to output tplot variable names 
;
;  start_angle:  Set a start angle for azimuthal spectrogram y axis
;  
;  get_error:  Flag to return error estimates (*_sigma variables)     
;
;  datagap:  Setting for tplot variables, controls how long a gap must be before it is drawn. 
;            (can also manually degap)
;
;  display_object:  Object allowing dprint to export output messages
;
;  coord: if set, then velocity and flux variables are created for the
;         input coordinate system, in addition to the DSL variables
;Output Keywords:
;  tplotnames:  List of tplot variables that were created
;  get_data_structures:  Set to named variable to return data structures when generating
;                        field aligned outputs.  This may considerably slow the process!
;  error:  Error status flag for calling routine, 1=error 0=success
;
;
;Notes: 
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2019-01-08 14:14:59 -0800 (Tue, 08 Jan 2019) $
;$LastChangedRevision: 26441 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_products/thm_part_products.pro $
;-

pro thm_part_products,probe=probe,$ ;The requested spacecraft ('a','b','c','d','e','f')
                         
                     datatype=datatype,$ ;The requested data type (e.g 'psif', 'peib', 'peer', etc...) 
                     
                     trange=trange,$ ;required for now
                     energy=energy,$ ;energy range
                     
                     phi=phi_in,$ ;angle limits 2-element array [min,max], in degrees, spacecraft spin plane
                     theta=theta,$ ;angle limits 2-element array [min,max], in degrees, normal to spacecraft spin plane
                     pitch=pitch,$ ;angle limits 2-element array [min,max], in degrees, magnetic field pitch angle
                     gyro=gyro_in,$ ;angle limits 2-element array [min,max], in degrees, gyrophase  
                     
                     outputs=outputs,$ ;list of requested output types (simpler than the angle=angle & /energy setup from before
                     ;Options are "energy","theta","phi","pa",and "gyro"
                     
                     units=units,$ ;scalar unit conversion for data 
                     
                     regrid=regrid_in, $ ;When performing FAC transforms, loss of resolution in sample bins occurs.(because the transformed bins are not aligned with the sample bins)  
                                      ;To resolve this, the FAC distribution is resampled at higher resolution.  This 2 element array specifies that resolution.[nphi,ntheta]
                     
                     suffix=suffix, $ ;tplot suffix to apply when generating outputs
                     
                     datagap=datagap, $ ;setting for tplot variables, controls how long a gap must be before it is drawn.(can also manually degap)
                     
                     get_error=get_error, $ ;flag to return error estimates (*_sigma variables)
                     
                     fac_type=fac_type,$ ;select the field aligned coordinate system variant. Existing options: "phigeo,mphigeo, xgse"
                     
                     mag_name=mag_name, $ ;tplot variable containing magnetic field data for moments and FAC transformations 
                     sc_pot_name=sc_pot_name, $ ;tplot variable containing spacecraft potential data for moments
                     pos_name=pos_name, $ ;tplot variable containing spacecraft position for FAC transformations
                  
                     ;see thm_pgs_clean_sst.pro to see how decontamination is done for SST 
                     ;see thm_crib_sst.pro for examples on using the decontamination keywords
                     sst_sun_bins=sst_sun_bins,$ ; which sst bins to decontaminate(list of bins numbers, not the old mask array)
                     sst_method_clean=sst_method_clean,$ ;how to decontaminate sst data (default/only: manual)
                     
                     dist_array=dist_array, $ ;use to pass in data from thm_part_dist_array, useful if you want to modify the data before spectra generation
                     
                     error=error,$ ;indicate error to calling routine 1=error,0=success
                     
                     start_angle=start_angle, $ ;select a different start angle
                      
                     tplotnames=tplotnames, $ ;set of tplot variable names that were created
                     
                     sst_cal=sst_cal,$
                     esa_bgnd_remove=esa_bgnd_remove,$
                     esa_bgnd_advanced=esa_bgnd_advanced,$
                    
                     erange=erange, $ ; deprecated.  Here just to post a warning if someone is accidentally using the old keyword'

                     get_data_structures=get_data_structures, $  ;pass out aggregated fac data structures
                    
                     display_object=display_object, $ ;object allowing dprint to export output messages

                      enormalize=enormalize, $ ; divides flux with maximum flux
                      coord = coord, $ ;For moments, convert to this coordinate system
                     _extra=ex ;TBD: consider implementing as _strict_extra 


  compile_opt idl2
  
  twin = systime(/sec)
  error = 1

  if n_elements(probe) gt 1 then begin
    dprint,"ERROR: thm_part_products doesn't support multiple probes. It can be called multiple times instead.",dlevel=1
    return
  endif else if n_elements(probe) eq 1 && n_elements(strsplit(probe,' ',/extract)) gt 1 then begin
    dprint,"ERROR: thm_part_products doesn't support multiple probes. It can be called multiple times instead.",dlevel=1
    return
  endif
  
  if n_elements(datatype) gt 1 then begin
    dprint,"ERROR: thm_part_products doesn't support multiple datatypes. It can be called multiple times instead.",dlevel=1
    return
  endif else if n_elements(datatype) eq 1 && n_elements(strsplit(datatype,' ',/extract)) gt 1 then begin
    dprint,"ERROR: thm_part_products doesn't support multiple datatypes. It can be called multiple times instead.",dlevel=1
    return
  endif
  
  if ~undefined(erange) then begin
    dprint,'ERROR: erange= keyword deprecated.  Using "energy=" instead.',dlevel=1
    return
  endif
  
  ;get probe, datatype, and units from input structures if provided
  ;this will not overwrite variables that are already set
  thm_pgs_get_datatype, dist_array, probe=probe, datatype=datatype, units=units
  
  if undefined(datatype) then begin
    dprint,dlevel=1,"ERROR: no datatype specified."
    return
  endif
  
  if undefined(probe) then begin
    dprint,dlevel=1,"ERROR: no probe specified."
    return
  endif
  
  datatype_lc = strlowcase(datatype[0])
  probe_lc = strlowcase(probe[0])
  
  inst_format = 'th'+probe_lc+'_'+datatype_lc
  
  esa = strmid(datatype_lc,1,1) eq 'e'
  sst = strmid(datatype_lc,1,1) eq 's'
  combined = strmid(datatype_lc,1,1) eq 't'

  ;enable "best practices" keywords by default
  
  if sst && undefined(sst_cal) && strlowcase(strmid(datatype,3,1)) ne 'r' then begin
    sst_cal = 1
    dprint,'New SST calibrations being enabled by default(disable with sst_cal=0)',dlevel=1
  endif
  
  if keyword_set(sst_cal) && strlowcase(strmid(datatype,3,1)) eq 'r' then begin
    dprint,"Warning, new SST calibrations do not work with reduced distribution data",dlevel=1 
  endif
  
  if esa then begin
    if keyword_set(esa_bgnd_advanced) then begin
      if keyword_set(esa_bgnd_remove) then $
        dprint, 'Disabling default ESA background subtraction', dlevel=1
      esa_bgnd_remove = 0
    endif
    if undefined(esa_bgnd_remove) then begin
      esa_bgnd_remove = 1
      dprint,'ESA background removal being enabled by default (disable with esa_bgnd_remove=0)',dlevel=1
    endif
  endif

  if undefined(outputs) then begin
    ;outputs = ['energy','phi','theta'] ;default to energy phi theta
    outputs = ['energy'] ;default changed at vassilis's request
  endif
  
  outputs_lc = strlowcase(outputs)
  if n_elements(outputs_lc) eq 1 then begin 
    outputs_lc = strsplit(outputs_lc,' ',/extract)
  endif


  if undefined(suffix) then begin
    suffix = ''
  endif

  if undefined(units) then begin
    units_lc = 'eflux'
  endif else begin
    units_lc = strlowcase(units)
  endelse
  
  if undefined(datagap) then begin
     datagap = 600.
  endif

  if undefined(regrid_in) then begin
    regrid = [16,8] ;default 16 phi x 8 theta regrid
  endif else begin
    regrid = regrid_in
  endelse

;I don't think that this is needed(fingers crossed)
;  if ~undefined(trange) then begin
;    timespan,trange
;  endif

  if undefined(pitch) then begin
    pitch = [0,180.]
  endif 
  
  if undefined(theta) then begin
    theta = [-90,90.]
  endif 
  
  if undefined(phi_in) then begin
    phi = [0,360.]
  endif else begin
    if abs(phi_in[1]-phi_in[0]) gt 360 then begin
      dprint, 'ERROR: Phi restrictons must have range no larger than 360 degrees'
      return
    endif
    phi = spd_pgs_map_azimuth(phi_in)
    ;catch offset full ranges
    if phi[0] eq phi[1] then phi = [0,360.]
  endelse
  
  if undefined(gyro_in) then begin
    gyro = [0,360.]
  endif else begin
    if abs(gyro_in[1]-gyro_in[0]) gt 360 then begin
      dprint, 'ERROR: Gyrophase restrictons must have range no larger than 360 degrees'
      return
    endif
    gyro = spd_pgs_map_azimuth(gyro_in)
    ;catch offset full ranges
    if gyro[0] eq gyro[1] then gyro = [0,360.]
  endelse
  
  ;Create energy spectrogram after FAC transformation if limits are not 
  ;identical to the default.
  if ~array_equal(gyro,[0,360.]) or ~array_equal(pitch,[0,180.]) then begin
    idx = where(outputs_lc eq 'energy', nidx)
    if nidx gt 0 then begin
      outputs_lc[idx] = 'fac_energy'
    endif
  endif
  
  if undefined(mag_name) then begin
    mag_name = 'th'+probe_lc+'_fgs'
  endif
  
  if undefined(pos_name) then begin
    pos_name = 'th'+probe_lc+'_state_pos'
  endif
  
  if is_struct(ex) then begin
    if in_set(strlowcase(tag_names(ex)),'scpot') then begin
      dprint,'ERROR: scpot keyword is deprecated.  Please use sc_pot_name'
      return
    endif else if in_set(strlowcase(tag_names(ex)),'scpot_suffix') then begin
      dprint,'ERROR: scpot_suffix keyword is deprecated.  Please use sc_pot_name'
      return
    endif
  endif
  
  if undefined(sc_pot_name) then begin
    sc_pot_name = 'th'+probe_lc+'_pxxm_pot' 
  endif
  
  if undefined(fac_type) then begin
    fac_type = 'mphigeo'
  endif
  
  fac_type_lc = strlowcase(fac_type)
  
  ;If set, this prevents concatenation from previous calls
  undefine,tplotnames
  
  
  ;--------------------------------------------------------
  ;Get array of sample times and initilize indices for loop
  ;--------------------------------------------------------
  
  if size(dist_array,/type) eq 10 then begin
    ;extract 1-d time_array from dist_array
    thm_pgs_dist_array_times,dist_array,times=times
  endif else begin
    times= thm_part_dist(inst_format,/times,sst_cal=sst_cal,_extra=ex)
  endelse

  if size(times,/type) ne 5 then begin
    dprint,dlevel=1, 'No ',inst_format,' data has been loaded.  Use thm_part_load to load particle data.'
    return
  endif

  if ~undefined(trange) then begin

    trd = time_double(trange)
    time_idx = where(times ge trd[0] and times le trd[1], nt)

    if nt lt 1 then begin
      dprint,dlevel=1, 'No ',inst_format,' data for time range ',time_string(trd)
      return
    endif
    
  endif else begin
    time_idx = lindgen(n_elements(times))
  endelse

  if (size(dist_array,/type)) eq 10 then begin
    ;identify the starting indexes for the dist array iterator at requested trange
    thm_pgs_dist_array_start,dist_array,time_idx,dist_ptr_idx=dist_ptr_idx,dist_seg_idx=dist_seg_idx
  endif

;copied over from tpm2,
;time correction to point at bin center is applied for ESA, but not for SST
;JMM, 2018-02-23 -- SST time correction is applied in L0 to L1
;                   processing, not needed here.
;  if sst then begin
;    times += 1.5
;  endif

  times=times[time_idx]


  ;--------------------------------------------------------
  ;Prepare support data
  ;--------------------------------------------------------
  
  ;create rotation matrix to field aligned coordinates if needed
  fac_requested = in_set(outputs_lc,'pa') || in_set(outputs_lc,'gyro') || in_set(outputs_lc,'fac_energy')
  if fac_requested then begin
    thm_pgs_make_fac,times,mag_name,pos_name,probe_lc,fac_output=fac_matrix,fac_type=fac_type_lc,display_object=display_object
    ;remove FAC outputs if there was an error, return if no outputs remain
    if undefined(fac_matrix) then begin
      fac_requested = 0
      outputs_lc = ssl_set_complement(['pa','gyro','fac_energy'],outputs_lc)
      if array_equal(outputs_lc,-1) then begin
        return
      endif
    endif
  endif

  ;get support data for moments calculation
  if in_set(outputs_lc,'moments') then begin
    if units_lc ne 'eflux' then begin
      dprint,dlevel=1,'Warning: Moments can only be calculated if data is in eflux.  Skipping product.'
      outputs_lc[where(outputs_lc eq 'moments')] = ''
    endif else begin
      thm_pgs_clean_support, times, probe_lc, mag_name, sc_pot_name, mag_out=mag_data, sc_pot_out=sc_pot_data
    endelse
  endif


  ;--------------------------------------------------------
  ;Loop over time to build the spectrograms/moments
  ;--------------------------------------------------------
  for i = 0,n_elements(time_idx)-1 do begin
  
    spd_pgs_progress_update,last_tm,i,n_elements(time_idx)-1,display_object=display_object,type_string=strupcase(inst_format)
  
    ;Get the data structure for this samgple
    if size(dist_array,/type) eq 10 then begin
      ;get the data from the dist_array for current index
      thm_pgs_dist_array_data,dist_array,data=data,dist_ptr_idx=dist_ptr_idx,dist_seg_idx=dist_seg_idx
    endif else begin
      data = thm_part_dist(inst_format,index=time_idx[i],sst_cal=sst_cal,_extra=ex)
    endelse
    
    ;Apply eclipse corrections if present
    thm_part_apply_eclipse, data, eclipse=eclipse
    
    ;Sanitize Data.
    ;#1 removes uneeded fields from struct to increase efficiency
    ;#2 performs some basic transforms so that esa and sst are represented more consistently
    ;#3 converts to physical units
    if esa then begin
      thm_pgs_clean_esa,data,units_lc,output=clean_data,esa_bgnd_advanced=esa_bgnd_advanced,bgnd_remove=esa_bgnd_remove,_extra=ex ;output is anonymous struct of goodies
    endif else if sst then begin
      thm_pgs_clean_sst,data,units_lc,output=clean_data,sst_sun_bins=sst_sun_bins,sst_method_clean=sst_method_clean,_extra=ex
    endif else if combined then begin
      thm_pgs_clean_cmb,data,units_lc,output=clean_data
    endif else begin
      dprint,dlevel=1,'Instrument type unrecognized'
      return
    endelse 
    
    ;Copy bin status prior to application of angle/energy limits.
    ;Phi limits will need to be re-applied later after phi bins
    ;have been aligned across energy (only necessary for ESA). 
    if fac_requested then begin
      pre_limit_bins = clean_data.bins 
    endif
    
    ;Apply phi, theta, & energy limits
    spd_pgs_limit_range,clean_data,phi=phi,theta=theta,energy=energy 
    
    ;Calculate moments
    ;  -data must be in 'eflux' units 
    if in_set(outputs_lc, 'moments') then begin
      spd_pgs_moments, clean_data, moments=moments, sigma=mom_sigma,delta_times=delta_times, get_error=get_error, mag_data=mag_data, sc_pot_data=sc_pot_data, index=i , _extra = ex
    endif
    ;Build energy spectrogram
    if in_set(outputs_lc, 'energy') then begin
      spd_pgs_make_e_spec, clean_data, spec=en_spec, sigma=en_sigma, yaxis=en_y, enormalize=enormalize
    endif
 
    ;regrid data for theta & phi spectra if regrid array was specified
    ;save original data for any FAC products (don't interpolate twice)
    if ~undefined(regrid_in) && (in_set(outputs_lc, 'theta') || in_set(outputs_lc, 'phi')) then begin
      if fac_requested then orig_data = clean_data
      spd_pgs_regrid, clean_data, regrid, output=clean_data
    endif

    ;Build theta spectrogram
    if in_set(outputs_lc, 'theta') then begin
      spd_pgs_make_theta_spec, clean_data, spec=theta_spec, sigma=theta_sigma, yaxis=theta_y
    endif
    
    ;Build phi spectrogram
    if in_set(outputs_lc, 'phi') then begin
      spd_pgs_make_phi_spec, clean_data, spec=phi_spec, sigma=phi_sigma, yaxis=phi_y
    endif
    
    ;Perform transformation to FAC, regrid data, and apply limits in new coords
    if fac_requested then begin
      
      ;if data was regridded for phi/theta spec then get the original
      if ~undefined(orig_data) then clean_data = temporary(orig_data)

      ;limits will be applied to energy-aligned bins
      clean_data.bins = temporary(pre_limit_bins)
      
      ;align bins across energies 
      ; -ensures smoother statistics and less jagged edges
      ; -better matches plots from tpm2
      spd_pgs_align_phi, clean_data
      spd_pgs_limit_range,clean_data,phi=phi,theta=theta,energy=energy 
      
      ;perform FAC transformation and interpolate onto a new, regular grid 
      spd_pgs_do_fac,clean_data,reform(fac_matrix[i,*,*],3,3),output=clean_data,error=error
      spd_pgs_regrid,clean_data,regrid,output=clean_data
      
      clean_data.theta = 90-clean_data.theta ;pitch angle is specified in co-latitude
      
      ;apply gyro & pitch angle limits(identical to phi & theta, just in new coords)
      spd_pgs_limit_range,clean_data,phi=gyro,theta=pitch
      
      ;agreggate transformed data structures if requested
      if arg_present(get_data_structures) then begin
        clean_data_all = array_concat(clean_data, clean_data_all,/no_copy)
      endif
      
    endif
    
    ;Build pitch angle spectrogram
    if in_set(outputs_lc,'pa') then begin
      spd_pgs_make_theta_spec, clean_data, spec=pa_spec, sigma=pa_sigma, yaxis=pa_y, /colatitude
    endif
    
    ;Build gyrophase spectrogram
    if in_set(outputs_lc, 'gyro') then begin
      spd_pgs_make_phi_spec, clean_data, spec=gyro_spec, sigma=gyro_sigma, yaxis=gyro_y
    endif
    
    ;Build energy spectrogram from field aligned distribution
    if in_set(outputs_lc, 'fac_energy') then begin
      spd_pgs_make_e_spec, clean_data, spec=fac_en_spec, sigma=fac_en_sigma, yaxis=fac_en_y, enormalize=enormalize
    endif
    
  endfor

  ;Place nans in regions outside the requested range
  ; -This is mainly to remove "bleeding" seen when limiting the range
  ;  along a coordinate where the data is not regularly gridded.
  ;  To obtain a complete spectrogram for the limited range all intersecting
  ;  bins must be used.  This means that many bins that intersect the 
  ;  limited range but may extend far past it are left active.
  ; -Currently, phi for ESA is the only non-regular case.
  spd_pgs_clip_spec, y=phi_y, z=phi_spec, range=phi
  spd_pgs_clip_spec, y=phi_y, z=phi_sigma, range=phi
 
 
  ;--------------------------------------------------------
  ;Create tplot variables for requested data types
  ;--------------------------------------------------------

  tplot_prefix = 'th'+probe_lc+'_'+datatype_lc+'_'+units_lc+'_'
  tplot_mom_prefix = 'th'+probe_lc+'_'+datatype_lc+'_'

  ;Energy Spectrograms
  if ~undefined(en_spec) then begin
    thm_pgs_make_tplot, tplot_prefix+'energy'+suffix, x=times, y=en_y, z=en_spec, ylog=1, units=units_lc,datagap=datagap,tplotnames=tplotnames
    if keyword_set(get_error) then begin
      thm_pgs_make_tplot, tplot_prefix+'energy_sigma'+suffix, x=times, y=en_y, z=en_sigma, ylog=1, units=units_lc,datagap=datagap,tplotnames=tplotnames
    endif
  endif
 
  ;Theta Spectrograms
  if ~undefined(theta_spec) then begin
    thm_pgs_make_tplot, tplot_prefix+'theta'+suffix, x=times, y=theta_y, z=theta_spec, yrange=theta,units=units_lc,datagap=datagap,tplotnames=tplotnames
    if keyword_set(get_error) then begin
      thm_pgs_make_tplot, tplot_prefix+'theta_sigma'+suffix, x=times, y=theta_y, z=theta_sigma, yrange=theta,units=units_lc,datagap=datagap,tplotnames=tplotnames
    endif
  endif
  
  ;Phi Spectrograms
  if ~undefined(phi_spec) then begin
    ;phi range may be wrapped about phi=0, this keeps an invalid range from being passed to tplot
    phi_y_range = (undefined(start_angle) ? 0:start_angle) + [0,360]
    thm_pgs_make_tplot, tplot_prefix+'phi'+suffix, x=times, y=phi_y, z=phi_spec, yrange=phi_y_range,units=units_lc,datagap=datagap,tplotnames=tplotnames
    spd_pgs_shift_phi_spec, names=tplot_prefix+'phi'+suffix, start_angle=start_angle
    if keyword_set(get_error) then begin
      thm_pgs_make_tplot, tplot_prefix+'phi_sigma'+suffix, x=times, y=phi_y, z=phi_sigma, yrange=phi_y_range,units=units_lc,datagap=datagap,tplotnames=tplotnames
      spd_pgs_shift_phi_spec, names=tplot_prefix+'phi_sigma'+suffix, start_angle=start_angle
    endif
  endif
  
  ;Pitch Angle Spectrograms
  if ~undefined(pa_spec) then begin
    thm_pgs_make_tplot, tplot_prefix+'pa'+suffix, x=times, y=pa_y, z=pa_spec, yrange=pitch,units=units_lc,datagap=datagap,tplotnames=tplotnames
    if keyword_set(get_error) then begin
      thm_pgs_make_tplot, tplot_prefix+'pa_sigma'+suffix, x=times, y=pa_y, z=pa_sigma, yrange=pitch,units=units_lc,datagap=datagap,tplotnames=tplotnames
    endif
  endif
  
  ;Gyrophase Spectrograms
  if ~undefined(gyro_spec) then begin
    ;gyro range may be wrapped about gyro=0, this keeps an invalid range from being passed to tplot
    gyro_y_range = (undefined(start_angle) ? 0:start_angle) + [0,360]
    thm_pgs_make_tplot, tplot_prefix+'gyro'+suffix, x=times, y=gyro_y, z=gyro_spec, yrange=gyro_y_range,units=units_lc,datagap=datagap,tplotnames=tplotnames
    spd_pgs_shift_phi_spec, names=tplot_prefix+'gyro'+suffix, start_angle=start_angle
    if keyword_set(get_error) then begin
      thm_pgs_make_tplot, tplot_prefix+'gyro_sigma'+suffix, x=times, y=gyro_y, z=gyro_sigma, yrange=gyro_y_range,units=units_lc,datagap=datagap,tplotnames=tplotnames
      spd_pgs_shift_phi_spec, names=tplot_prefix+'gyro_sigma'+suffix, start_angle=start_angle
    endif
  endif
  
  ;Field-Aligned Energy Spectrograms
  if ~undefined(fac_en_spec) then begin
    thm_pgs_make_tplot, tplot_prefix+'energy'+suffix, x=times, y=fac_en_y, z=fac_en_spec, ylog=1, units=units_lc,datagap=datagap,tplotnames=tplotnames
    if keyword_set(get_error) then begin
      thm_pgs_make_tplot, tplot_prefix+'energy_sigma'+suffix, x=times, y=fac_en_y, z=fac_en_sigma, ylog=1, units=units_lc,datagap=datagap,tplotnames=tplotnames
    endif
  endif
  
  ;Moments Variables
  if ~undefined(moments) then begin
    moments.time = times
    thm_pgs_moments_tplot, moments, prefix=tplot_mom_prefix, suffix=suffix, tplotnames=tplotnames, coord = coord ;added coord, 2019-01-07, jmm
  endif

  ;Moments Error Esitmates
  if ~undefined(mom_sigma) then begin
    mom_sigma.time = times
    thm_pgs_moments_tplot, mom_sigma, /get_error, prefix=tplot_mom_prefix, suffix=suffix, tplotnames=tplotnames, coord = coord ;added coord, 2019-01-07, jmm
  endif
  if ~undefined(delta_times) then begin
    store_data,tplot_mom_prefix+'delta_time',data={x:times,y:delta_times},verbose=0
    tplotnames = array_concat(tplot_mom_prefix+'delta_time',tplotnames)
  endif
  
  ;Return transformed data structures
  if arg_present(get_data_structures) and is_struct(clean_data_all) then begin
    get_data_structures = temporary(clean_data_all)
  endif
  
  error = 0

  dprint,'Complete. Runtime: ',systime(/sec) - twin,' secs' 
end
