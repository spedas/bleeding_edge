;+
;////////////////////////////////////////////////////////////////
; - This is a hacked version of 'mms_part_products', which 
;   enables us to plot many spectrograms.
; - Please see moka_mms_part_products_crib.pro
;////////////////////////////////////////////////////////////////
;
;Procedure:
;  mms_part_products
;
;Purpose:
;  Generate spectra and moments from 3D MMS particle data.
;
;   -----------------------------------------------------------------------------------------
;   |  !!!!!! words of caution <------ by egrimes, 4/7/2016:                                |
;   |   While you can use mms_part_products to generate particle moments for FPI from       |
;   |   the distributions, these calculations are currently missing several important       |
;   |   components, including photoelectron removal and S/C potential corrections.          |
;   |   The official moments released by the team include these, and are the scientific     |
;   |   products you should use in your analysis; see mms_load_fpi_crib to see how to load  |
;   |   the FPI moments released by the team (des-moms, dis-moms datatypes)                 |
;   -----------------------------------------------------------------------------------------
;
;Data Products:
;  'energy' - energy spectrogram
;  'phi' - azimuthal spectrogram 
;  'theta' - latitudinal spectrogram
;  'gyro' - gyrophase spectrogram
;  'pa' - pitch angle spectrogram
;  'moments' - distribution moments (density, velocity, etc.)
;  'dist' - dump all distribution data for later processing 
;
;Calling Sequence:
;  mms_part_products, tplot_name [,trange=trange] [outputs=outputs] ...
;
;
;Example Usage:
;  -energy, phi, and theta spectrograms
;    mms_part_products, 'mms2_des_dist_brst', outputs='phi theta energy'
;
;  -field aligned spectrograms, limited time range
;    mms_part_products, 'mms2_des_dist_brst', output='pa gyro', $
;                       pos_name = 'mms2_defeph_pos', $
;                       mag_name = 'mms2_fgm_bvec'
;
;  -limit range of input data (gyro and pa limits do not affect phi/theta spectra)
;    mms_part_products, 'mms2_des_dist_brst', output = 'energy pitch', $
;                       energy = [15,1e5], $  ;eV
;                       pitch = [45,135]
;
;Arguments:
;  tplot_name:  Name of the tplot variable containing MMS 3D particle distribution data
;
;
;Input Keywords:
;  trange:  Two element time range [start,end]
;  outputs:  List of requested outputs, array or space separated list, default='energy'
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
;  vel_name:  Tplot variable containing velocity data in km/s for use with /subtract_bulk
;    
;  units:  Secify units of output variables.  Must be 'eflux' to calculate moments.
;            'flux'   -   # / (cm^2 * s * sr * eV)
;            'eflux'  -  eV / (cm^2 * s * sr * eV)  <default>
;            'df_cm'  -  s^3 / cm^6
;            'df'     -  s^3 / km^6
;
;  fac_type:  Select the field aligned coordinate system variant.
;             Existing options: "phigeo,mphigeo, xgse"
;  regrid:  Two element array specifying the resolution of the field-aligned data.
;           [n_gyro,n_pitch], default is [32,16]
;  no_regrid:  (experimental) Skip regrid step when converting to field aligned coordinates.
;              
;  
;  suffix:  Suffix to append to output tplot variable names 
;
;  probe:  Specify probe designation when it cannot be parsed from tplot_name
;  species:  Specify species when it cannot be parsed from tplot_name
;  instrument:  Specify instrument when it cannot be parsed from tplot_name
;  input_units:  (HPCA only) Specify units of input data when they cannot be parsed from tplot_name
;
;  start_angle:  Set a start angle for azimuthal spectrogram y axis
;    
;  datagap:  Setting for tplot variables, controls how long a gap must be before it is drawn. 
;            (can also manually degap)
;  subtract_bulk:  Flag to subtract velocity vector from distribution before
;                  calculation of field aligned angular spectra.
;
;  display_object:  Object allowing dprint to export output messages
;
;  
;Output Keywords:
;  tplotnames:  List of tplot variables that were created
;  get_data_structures:  Set to named variable to return structures directly when
;                        generating field aligned outputs.  This may considerably
;                        slow the process!
;  error:  Error status flag for calling routine, 1=error 0=success
;
;
;Notes: 
;  -See warning above in purpose description!
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-10-06 09:35:27 -0700 (Thu, 06 Oct 2016) $
;$LastChangedRevision: 22050 $
;$URL: svn+ssh://ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/mms_part_products.pro $
;-
pro moka_mms_part_products, $
                     in_tvarname, $ ;the tplot variable name for the MMS being processed
                                    ;specify this or use probe, instr, rate, level, species

                     probe=probe, $ ;can be specified if not in tplot variable name
                                    ;needed for some FAC
                     instrument=instrument, $ ;can be specified if not in tplot variable name 
                     species=species, $ ;can be specified if not in tplot variable name
                     input_units=input_units, $ ;specify hpca units if not in varname

                     energy=energy,$ ;two element energy range [min,max]
                     trange=trange,$ ;two element time range [min,max]
                                          
                     phi=phi_in,$ ;angle limist 2-element array [min,max], in degrees, spacecraft spin plane
                     theta=theta,$ ;angle limits 2-element array [min,max], in degrees, normal to spacecraft spin plane
                     pitch=pitch,$ ;angle limits 2-element array [min,max], in degrees, magnetic field pitch angle
                     gyro=gyro_in,$ ;angle limits 2-element array [min,max], in degrees, gyrophase  
   
                     outputs=outputs,$ ;list of requested output types (simpler than the angle=angle & /energy setup from before
                     
                     units=units,$ ;scalar unit conversion for data 
                     
                     regrid=regrid, $ ;When performing FAC transforms, loss of resolution in sample bins occurs.(because the transformed bins are not aligned with the sample bins)  
                                      ;To resolve this, the FAC distribution is resampled at higher resolution.  This 2 element array specifies that resolution.[nphi,ntheta]
                     
                     no_regrid=no_regrid, $ ;flag to skip regrid step when converting to fac
                     
                     suffix=suffix, $ ;tplot suffix to apply when generating outputs
                     
                     subtract_bulk=subtract_bulk, $ ;subtract bulk velocity from FAC angular spectra
                     
                     datagap=datagap, $ ;setting for tplot variables, controls how long a gap must be before it is drawn.(can also manually degap)
                            
                     fac_type=fac_type,$ ;select the field aligned coordinate system variant. Existing options: "phigeo,mphigeo, xgse"
                     
                     mag_name=mag_name, $ ;tplot variable containing magnetic field data for moments and FAC transformations 
                     sc_pot_name=sc_pot_name, $ ;tplot variable containing spacecraft potential data for moments
                     pos_name=pos_name, $ ;tplot variable containing spacecraft position for FAC transformations
                     vel_name=vel_name, $ tplot variable containing velocity data in km/s
                     
                     error=error,$ ;indicate error to calling routine 1=error,0=success
                     
                     start_angle=start_angle, $ ;select a different start angle
                      
                     tplotnames=tplotnames, $ ;set of tplot variable names that were created
                   
                     get_data_structures=get_data_structures, $  ;pass out aggregated fac data structures
                     
                     display_object=display_object, $ ;object allowing dprint to export output messages

                     silent=silent, $ ;supress pop-up messages

                     _extra=ex ;TBD: consider implementing as _strict_extra 


  compile_opt idl2
  
  twin = systime(/sec)
  error = 1
  
  if ~is_string(in_tvarname) then begin
    dprint, dlevel=0, 'No input data, please specify tplot variable'
    return
  endif
  
  if ~undefined(erange) then begin
    dprint,'ERROR: erange= keyword deprecated.  Using "energy=" instead.',dlevel=1
    return
  endif

  ;enable "best practices" keywords by default
  
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

  if undefined(regrid) then begin
    regrid = [32,16] ;default 16 phi x 8 theta regrid
  endif

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
    idx = where(outputs_lc eq 'moments', nidx)
    if nidx gt 0 then begin
      outputs_lc[idx] = 'fac_moments'
    endif
  endif
  
;  if undefined(mag_name) then begin
;    mag_name = 'th'+probe_lc+'_fgs'
;  endif
;  
;  if undefined(pos_name) then begin
;    pos_name = 'th'+probe_lc+'_state_pos'
;  endif
;  
;  if undefined(sc_pot_name) then begin
;    sc_pot_name = 'th'+probe_lc+'_pxxm_pot' 
;  endif
  
  if undefined(fac_type) then begin
    fac_type = 'mphigeo'
  endif
  
  fac_type_lc = strlowcase(fac_type)
  
  ;If set, this prevents concatenation from previous calls
  undefine,tplotnames
  

  ;--------------------------------------------------------
  ;Remind user that l2 moments should be used preferentially and FAC moments are experimental
  ;--------------------------------------------------------
  
  if in_set(outputs_lc,'moments') || in_set(outputs_lc,'fac_moments') then begin

    msg = 'Moments generated with mms_part_products may be missing several important '+ $
          'corrections, including photoelectron removal and spacecraft potential.  '+ $
          'The official moments released by the instrument teams include these and '+ $
          'are the scientific products that should be used for analysis.'
    msg += ~in_set(outputs_lc,'fac_moments') ? '' : ssl_newline()+ssl_newline()+ $
          'Field aligned moments should be considered experimental.  '+ $
          'All output variables will be in the coordinates defined by '+ $
          'the fac_type option (default: ''mphigeo'').'

    if ~keyword_set(silent) then begin
      msg += ssl_newline()+ssl_newline()+'Use /silent to disable this warning.'
      dummy = dialog_message(msg, /center, title='MMS_PART_PRODUCTS:  Warning')
    endif else begin
      dprint, dlevel=2, '=========================================================='
      dprint, dlevel=2, 'WARNING:  '
      dprint, dlevel=2, msg 
      dprint, dlevel=2, '=========================================================='
    endelse

  endif
  

  ;--------------------------------------------------------
  ;Get array of sample times and initialize indices for loop
  ;--------------------------------------------------------
  
  times = mms_get_dist(in_tvarname, /times, probe=probe, species=species, $
                       instrument=instrument, units=input_units)

  if size(times,/type) ne 5 then begin
    dprint,dlevel=1, 'No ',in_tvarname,' data has been loaded.'
    return
  endif

  if ~undefined(trange) then begin

    trd = time_double(trange)
    time_idx = where(times ge trd[0] and times le trd[1], nt)

    if nt lt 1 then begin
      dprint,dlevel=1, 'No ',in_tvarname,' data for time range ',time_string(trd)
      return
    endif
    
  endif else begin
    time_idx = lindgen(n_elements(times))
  endelse
  
  times = times[time_idx]


  ;--------------------------------------------------------
  ;Prepare support data
  ;--------------------------------------------------------
  
  ;create rotation matrix to field aligned coordinates if needed
  fac_outputs = ['pa','gyro','fac_energy','fac_moments']
  fac_requested = is_string(ssl_set_intersection(outputs_lc,fac_outputs))
  if fac_requested then begin
    mms_pgs_make_fac,times,mag_name,pos_name,fac_output=fac_matrix,fac_type=fac_type_lc,display_object=display_object,probe=probe
    ;remove FAC outputs if there was an error, return if no outputs remain
    if undefined(fac_matrix) then begin
      fac_requested = 0
      outputs_lc = ssl_set_complement(fac_outputs,outputs_lc)
      if ~is_string(outputs_lc) then begin
        return
      endif
    endif
  endif
  
  ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  ; moka (added 'pad')
  ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  ;get support data for moments calculation 
  if in_set(outputs_lc,'moments') || in_set(outputs_lc,'fac_moments') || in_set(outputs_lc,'pad') then begin
    if units_lc ne 'eflux' then begin
      dprint,dlevel=1,'Warning: Moments can only be calculated if data is in eflux.  Skipping product.'
      outputs_lc[where(strmatch(outputs_lc,'*moments'))] = ''
    endif else begin
      mms_pgs_clean_support, times, probe, mag_name=mag_name, sc_pot_name=sc_pot_name, mag_out=mag_data, sc_pot_out=sc_pot_data
    endelse
  endif
  dist_tmp = mms_get_dist(in_tvarname, time_idx[0], /structure, probe=probe, $
    species=species, instrument=instrument, units=input_units)
  wegy = dist_tmp.ENERGY[*,0,0]
  ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  
  ;get support data for bulk velocity subtraction
  if keyword_set(subtract_bulk) then begin
    mms_pgs_clean_support, times, probe, vel_name=vel_name, vel_out=vel_data
  endif


  ;--------------------------------------------------------
  ;Loop over time to build the spectrograms/moments
  ;--------------------------------------------------------
  
  for i = 0,n_elements(time_idx)-1 do begin
  
    spd_pgs_progress_update,last_tm,i,n_elements(time_idx)-1,display_object=display_object,type_string=in_tvarname
  
    ;Get the data structure for this samgple

    dist = mms_get_dist(in_tvarname, time_idx[i], /structure, probe=probe, $
                        species=species, instrument=instrument, units=input_units)

    ;Sanitize Data.
    ;#1 removes uneeded fields from struct to increase efficiency
    ;#2 Reforms into angle by energy data 
  
    mms_pgs_clean_data,dist,output=clean_data,units=units_lc
    
    ;Copy bin status prior to application of angle/energy limits.
    ;Phi limits will need to be re-applied later after phi bins
    ;have been aligned across energy (in case of irregularl grid). 
    if fac_requested then begin
      pre_limit_bins = clean_data.bins 
    endif
    
    ;Apply phi, theta, & energy limits
    spd_pgs_limit_range,clean_data,phi=phi,theta=theta,energy=energy 
    
    ;Calculate moments
    ;  -data must be in 'eflux' units 
    if in_set(outputs_lc, 'moments') then begin
      spd_pgs_moments, clean_data, moments=moments, delta_times=delta_times, mag_data=mag_data, sc_pot_data=sc_pot_data, index=i , _extra = ex
    endif 

    ;Build theta spectrogram
    if in_set(outputs_lc, 'theta') then begin
      spd_pgs_make_theta_spec, clean_data, spec=theta_spec, yaxis=theta_y
    endif
    
    ;Build phi spectrogram
    if in_set(outputs_lc, 'phi') then begin
      spd_pgs_make_phi_spec, clean_data, spec=phi_spec, yaxis=phi_y
    endif
    
    ;Build energy spectrogram
    if in_set(outputs_lc, 'energy') then begin
      spd_pgs_make_e_spec, clean_data, spec=en_spec, yaxis=en_y
    endif
    
    ;--------- moka ---------------------
    ;Build PAD
    if in_set(outputs_lc, 'pad') then begin
      moka_mms_clean_data, dist,output=this_dist,units=units_lc
      if keyword_set(subtract_bulk) then begin
        moka_pgs_make_pad, this_dist, spec=pad_spec, xaxis=pad_agl, mag_data=mag_data[i,*], wegy=wegy, $
          vel_data=vel_data[i,*], /subtract_bulk
      endif else begin
        moka_pgs_make_pad, this_dist, spec=pad_spec, xaxis=pad_agl, mag_data=mag_data[i,*], wegy=wegy
      endelse
    endif
    ;------------------------------------
    
    ;Perform transformation to FAC, regrid data, and apply limits in new coords
    if fac_requested then begin
      
      ;limits will be applied to energy-aligned bins
      clean_data.bins = temporary(pre_limit_bins)
      
      ;split hpca angle bins to be equal width in phi/theta
      ;this is needed when skipping the regrid step
      if keyword_set(no_regrid) && instrument eq 'hpca' then begin
        mms_pgs_split_hpca, clean_data, output=clean_data
      endif

      spd_pgs_limit_range,clean_data,phi=phi,theta=theta,energy=energy 
      
      ;perform FAC transformation and interpolate onto a new, regular grid 
      spd_pgs_do_fac,clean_data,reform(fac_matrix[i,*,*],3,3),output=clean_data,error=error

      ;nearest neighbor interpolation to regular grid in FAC
      if ~keyword_set(no_regrid) then begin
        spd_pgs_regrid,clean_data,regrid,output=clean_data
      endif

      ;shift by bulk velocity vector if requested
      if keyword_set(subtract_bulk) && ~undefined(vel_data) then begin
        spd_pgs_v_shift, clean_data, vel_data[i,*], matrix=reform(fac_matrix[i,*,*],3,3), error=error
      endif
      
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
      spd_pgs_make_theta_spec, clean_data, spec=pa_spec, yaxis=pa_y, /colatitude, resolution=regrid[1]
    endif
    
    ;Build gyrophase spectrogram
    if in_set(outputs_lc, 'gyro') then begin
      spd_pgs_make_phi_spec, clean_data, spec=gyro_spec, yaxis=gyro_y, resolution=regrid[0]
    endif
    
    ;Build energy spectrogram from field aligned distribution
    if in_set(outputs_lc, 'fac_energy') then begin
      spd_pgs_make_e_spec, clean_data, spec=fac_en_spec,  yaxis=fac_en_y
    endif
    
    ;Calculate FAC moments
    ;  -data must be in 'eflux' units 
    if in_set(outputs_lc, 'fac_moments') then begin
      clean_data.theta = 90-clean_data.theta ;convert back to latitude for moments calc
      ;re-add required fields stripped by FAC transform (should fix there if feature becomes standard)
      clean_data = create_struct('charge',dist.charge,'magf',[0,0,0.],'sc_pot',0.,clean_data)
      spd_pgs_moments, clean_data, moments=fac_moments, sc_pot_data=sc_pot_data, index=i, _extra=ex
    endif 
    
  endfor
 
 
  ;Place nans in regions outside the requested range
  ; -This is mainly to remove "bleeding" seen when limiting the range
  ;  along a coordinate where the data is not regularly gridded.
  ;  To obtain a complete spectrogram for the limited range all intersecting
  ;  bins must be used.  This means that many bins that intersect the 
  ;  limited range but may extend far past it are left active.
  ; -e.g: phi for HPCA is irregular
  spd_pgs_clip_spec, y=phi_y, z=phi_spec, range=phi
 
 
  ;--------------------------------------------------------
  ;Create tplot variables for requested data types
  ;--------------------------------------------------------

  tplot_prefix = in_tvarname+'_'
 

  ;NOTE: these test for generating spectra will not work if we decide to loop over probe/datatype
  
  ;Energy Spectrograms
  if ~undefined(en_spec) then begin
    spd_pgs_make_tplot, tplot_prefix+'energy'+suffix, x=times, y=en_y, z=en_spec, ylog=1, units=units_lc,datagap=datagap,tplotnames=tplotnames
  endif
 
  ;Theta Spectrograms
  if ~undefined(theta_spec) then begin
    spd_pgs_make_tplot, tplot_prefix+'theta'+suffix, x=times, y=theta_y, z=theta_spec, yrange=theta,units=units_lc,datagap=datagap,tplotnames=tplotnames
  endif
  
  ;Phi Spectrograms
  if ~undefined(phi_spec) then begin
    ;phi range may be wrapped about phi=0, this keeps an invalid range from being passed to tplot
    phi_y_range = (undefined(start_angle) ? 0:start_angle) + [0,360]
    spd_pgs_make_tplot, tplot_prefix+'phi'+suffix, x=times, y=phi_y, z=phi_spec, yrange=phi_y_range,units=units_lc,datagap=datagap,tplotnames=tplotnames
    spd_pgs_shift_phi_spec, names=tplot_prefix+'phi'+suffix, start_angle=start_angle
  endif
  
  ;Pitch Angle Spectrograms
  if ~undefined(pa_spec) then begin
    spd_pgs_make_tplot, tplot_prefix+'pa'+suffix, x=times, y=pa_y, z=pa_spec, yrange=pitch,units=units_lc,datagap=datagap,tplotnames=tplotnames
  endif
  
  ;Gyrophase Spectrograms
  if ~undefined(gyro_spec) then begin
    ;gyro range may be wrapped about gyro=0, this keeps an invalid range from being passed to tplot
    gyro_y_range = (undefined(start_angle) ? 0:start_angle) + [0,360]
    spd_pgs_make_tplot, tplot_prefix+'gyro'+suffix, x=times, y=gyro_y, z=gyro_spec, yrange=gyro_y_range,units=units_lc,datagap=datagap,tplotnames=tplotnames
    spd_pgs_shift_phi_spec, names=tplot_prefix+'gyro'+suffix, start_angle=start_angle
  endif
  
  ;Field-Aligned Energy Spectrograms
  if ~undefined(fac_en_spec) then begin
    spd_pgs_make_tplot, tplot_prefix+'energy'+suffix, x=times, y=fac_en_y, z=fac_en_spec, ylog=1, units=units_lc,datagap=datagap,tplotnames=tplotnames
  endif
  
  ;Moments Variables
  if ~undefined(moments) then begin
    moments.time = times
    spd_pgs_moments_tplot, moments, prefix=tplot_prefix, suffix=suffix, tplotnames=tplotnames
  endif

  ;FAC Moments Variables
  if ~undefined(fac_moments) then begin
    fac_moments.time = times
    fac_mom_suffix = '_mag' + (undefined(suffix) ? '' : suffix)
    spd_pgs_moments_tplot, fac_moments, /no_mag, prefix=tplot_prefix, suffix=fac_mom_suffix, tplotnames=tplotnames
  endif

  if ~undefined(pad_spec) then begin
    units = units_lc
    ;general settings for all spectrograms
    dlimits = {ylog:0, zlog:1, spec:1, ystyle:1, zstyle:1,$
      extend_y_edges:1,$ ;if this option is set, tplot only plots to bin center on the top and bottom of the specplot
      x_no_interp:1,y_no_interp:1,$ ;copied from original thm_part_getspec, don't think this is strictly necessary, since specplot interpolation is disabled by default
      ztitle:spd_units_string(units,/units_only),minzlog:1,data_att:{units:units}}
    store_data,tplot_prefix+'pad'+suffix,data={X:times, Y:pad_spec, V1:wegy, V2:pad_agl},dl=dlimits
  endif
  
  ;Return transformed data structures
  if arg_present(get_data_structures) and is_struct(clean_data_all) then begin
    get_data_structures = temporary(clean_data_all)
  endif

  error = 0
  
  dprint,'Complete. Runtime: ',systime(/sec) - twin,' secs' 
end
