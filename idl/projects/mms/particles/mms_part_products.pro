;+
;Procedure:
;  mms_part_products
;
;Purpose:
;  Generate spectra and moments from 3D MMS particle data.
;
;
;Data Products:
;  'energy' - energy spectrogram
;  'phi' - azimuthal spectrogram 
;  'theta' - latitudinal spectrogram
;  'gyro' - gyrophase spectrogram
;  'pa' - pitch angle spectrogram
;  'multipad' - pitch angle spectrogram at each energy (multi-dimensional tplot variable, 
;       you'll need to use mms_part_getpad to generate PADs at various energies)
;  'moments' - distribution moments (density, velocity, etc.)
;
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
;  units:  Specify units of output variables.  Must be 'eflux' to calculate moments.
;            'flux'   -   # / (cm^2 * s * sr * eV)
;            'eflux'  -  eV / (cm^2 * s * sr * eV)  <default>
;            'df_cm'  -  s^3 / cm^6
;            'df_km'     -  s^3 / km^6
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
;  subtract_bulk:  Flag to subtract bulk velocity (experimental)
;  remove_fpi_sw: Flag to remove the solar wind component from the FPI ion DFs prior to performing the calculations
;  use_sdc_units: Flag to convert moments_3d pressure tensor and qflux outputs to nPa and mW/m^2 respectively, for compatibility with MMS SDC moments
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
;  -FPI-DES photoelectrons are corrected using Dan Gershman's photoelectron model; see the following for details:
;     Spacecraft and Instrument Photoelectrons Measured by the Dual Electron Spectrometers on MMS
;     https://agupubs.onlinelibrary.wiley.com/doi/full/10.1002/2017JA024518
;     
;  -Note that there may still be slight differences between the PGS moments and the official moments released by the team.
;     The official moments released by the team are the scientific
;     products you should use in your analysis.
;  
;  - Note: versions of this code between 28July2021 and 5Nov2021 automatically removed negative values 
;          after photoelectron corrections; this functionality is now available by setting the keyword: /zero_negative_values
;
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2025-07-12 19:14:21 -0700 (Sat, 12 Jul 2025) $
;$LastChangedRevision: 33459 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/mms_part_products.pro $
;-
pro mms_part_products, $
                     in_tvarname, $ ;the tplot variable name for the MMS being processed
                                    ;specify this or use probe, instr, rate, level, species

                     data_rate=data_rate, $
                     probe=probe, $ ;can be specified if not in tplot variable name
                                    ;needed for some FAC
                     instrument=instrument, $ ;can be specified if not in tplot variable name 
                     species=species, $ ;can be specified if not in tplot variable name
                     input_units=input_units, $ ;specify hpca units if not in varname

                     energy=energy,$ ;two element energy range [min,max]
                     trange=trange,$ ;two element time range [min,max]
                                          
                     phi=phi_in,$ ;angle limits 2-element array [min,max], in degrees, spacecraft spin plane
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
                     subtract_error=subtract_error, $ ; subtract the distribution error variable from the data prior to doing the calculations
                     error_variable=error_variable, $ ; name of the tplot variable containing the distribution error (required if /subtract_error keyword is specified)
                     
                     datagap=datagap, $ ;setting for tplot variables, controls how long a gap must be before it is drawn.(can also manually degap)
                            
                     fac_type=fac_type,$ ;select the field aligned coordinate system variant. Existing options: "phigeo,mphigeo, xgse"
                     
                     mag_name=mag_name, $ ;tplot variable containing magnetic field data for moments and FAC transformations 
                     sc_pot_name=sc_pot_name, $ ;tplot variable containing spacecraft potential data for moments
                     pos_name=pos_name, $ ;tplot variable containing spacecraft position for FAC transformations
                     vel_name=vel_name, $ tplot variable containing velocity data in km/s
                     
                     correct_photoelectrons=correct_photoelectrons, $ ; Apply both internal photoelectron corrections (Dan Gershman's model) and correct for S/C potential (should not be used with either of the bottom two)
                     internal_photoelectron_corrections=internal_photoelectron_corrections, $ ; Only apply Dan Gershman's model (i.e., don't correct for the S/C potential in moments_3d)
                     correct_sc_potential=correct_sc_potential, $ ; only correect for the S/C potential (disables Dan Gershman's model)
                     zero_negative_values=zero_negative_values, $ ; keyword that tells mms_part_products to turn negative values to 0 after doing the photoelectron corrections (DES)

                     error=error,$ ;indicate error to calling routine 1=error,0=success
                     
                     start_angle=start_angle, $ ;select a different start angle
                      
                     tplotnames=tplotnames, $ ;set of tplot variable names that were created
                   
                     get_data_structures=get_data_structures, $  ;pass out aggregated fac data structures
                     
                     display_object=display_object, $ ;object allowing dprint to export output messages

                     silent=silent, $ ;suppress pop-up messages
                     remove_fpi_sw=remove_fpi_sw, $ ; remove the solar wind component from the FPI distribution data prior to performing the calculations
                     sdc_units=sdc_units, $ ; Convert moment_3d pressure tensor output from eV/cm^3 to nPa, and heat flux to mW/m^2, for consistency with units used by MMS SDC moments
                     _extra=ex ;TBD: consider implementing as _strict_extra 


  compile_opt idl2
  
  twin = systime(/sec)
  error = 1
  
  ; no regridding allowed when you subtract the bulk velocity because 
  ; regridding assumes energies are constant across angles (which is
  ; not the case after the bulk velocity is subtracted)
  if keyword_set(subtract_bulk) then no_regrid = 1
  
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
    regrid = [32,16] ;default 32 phi x 16 theta regrid
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
      dprint, 'ERROR: Phi restrictions must have range no larger than 360 degrees'
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
      dprint, 'ERROR: Gyrophase restrictions must have range no larger than 360 degrees'
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
    if ~keyword_set(correct_photoelectrons) then begin
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
  fac_outputs = ['multipad', 'pa', 'gyro', 'fac_energy', 'fac_moments']
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
  
  ;get support data for moments calculation
  if in_set(outputs_lc,'moments') || in_set(outputs_lc,'fac_moments') || keyword_set(correct_photoelectrons) || keyword_set(internal_photoelectron_corrections) then begin
    if units_lc ne 'eflux' then begin
      dprint,dlevel=1,'Warning: Moments can only be calculated if data is in eflux.  Skipping product.'
      outputs_lc[where(strmatch(outputs_lc,'*moments'))] = ''
    endif else begin
      mms_pgs_clean_support, times, probe, mag_name=mag_name, sc_pot_name=sc_pot_name, mag_out=mag_data, sc_pot_out=sc_pot_data
    endelse
  endif

  ;get support data for bulk velocity subtraction
  if keyword_set(subtract_bulk) then begin
    mms_pgs_clean_support, times, probe, vel_name=vel_name, vel_out=vel_data
  endif
  
  ; the standard way of concatenating the spectra variables doesn't work for the multi-dimensional PAD
  ; so we need to allocate the memory before going into the loop over times
  if in_set(outputs_lc, 'multipad') then begin
    dist = mms_get_dist(in_tvarname, time_idx[0], /structure, probe=probe, $
      species=species, instrument=instrument, units=input_units, $
      subtract_error=subtract_error, error=error_variable)
  
    multi_pad_out = dblarr(n_elements(time_idx), (dimen(dist.data))[0], (dimen(dist.data))[2])
  endif
  
  ; grab the FPI photoelectron model if needed
  if keyword_set(correct_photoelectrons) || keyword_set(internal_photoelectron_corrections) then begin
    fpi_photoelectrons = mms_part_des_photoelectrons(in_tvarname)
    
    if ~is_struct(fpi_photoelectrons) && fpi_photoelectrons eq -1 then begin
      dprint, dlevel=0, 'Photoelectron model missing for this date; re-run without photoelectron corrections' 
      return
    endif
    
    ; will need stepper parities for burst mode data
    if data_rate eq 'brst' then begin
      scprefix = (strsplit(in_tvarname, '_', /extract))[0]
      get_data, scprefix+'_des_steptable_parity_brst', data=parity
      
      ; the following is so that we can use scope_varfetch using the parity_num found in the loop over times
      ; (scope_varfetch doesn't work with structure.structure syntax)
      bg_dist_p0 = fpi_photoelectrons.bgdist_p0
      bg_dist_p1 = fpi_photoelectrons.bgdist_p1
      n_0 = fpi_photoelectrons.n_0
      n_1 = fpi_photoelectrons.n_1
    endif
    get_data, 'mms'+probe+'_des_startdelphi_count_'+data_rate, data=startdelphi
  endif
  
  if keyword_set(remove_fpi_sw) && instrument eq 'fpi' && species eq 'i' then begin
    dprint, dlevel=2, 'Removing solar wind component from FPI ion data'
  endif else if keyword_set(remove_fpi_sw) then begin
    dprint, dlevel=0, 'Error, remove_fpi_sw keyword only valid for FPI ions. No solar wind removal applied.
    remove_fpi_sw = 0b
  endif
  
  ;--------------------------------------------------------
  ;Loop over time to build the spectrograms/moments
  ;--------------------------------------------------------
  for i = 0l,n_elements(time_idx)-1 do begin
  
    spd_pgs_progress_update,last_tm,i,n_elements(time_idx)-1,display_object=display_object,type_string=in_tvarname
  
    ;Get the data structure for this sample

    dist = mms_get_dist(in_tvarname, time_idx[i], /structure, probe=probe, $
                        species=species, instrument=instrument, units=input_units, $
                        subtract_error=subtract_error, error=error_variable)
    
    if keyword_set(remove_fpi_sw) && instrument eq 'fpi' && species eq 'i' then begin
      mms_fpi_remove_sw, dist=dist, newdist=newdist, /quiet
      dist = newdist
    endif
                      
    str_element, dist, 'orig_energy', dist.energy[*, 0, 0], /add

    if keyword_set(correct_photoelectrons) || keyword_set(internal_photoelectron_corrections) then begin

      ; From Dan Gershman's release notes on the FPI photoelectron model:
      ; Find the index I in the startdelphi_counts_brst or startdelphi_counts_fast array
      ; [360 possibilities] whose corresponding value is closest to the measured
      ; startdelphi_count_brst or startdelphi_count_fast for the skymap of interest. The
      ; closest index can be approximated by I = floor(startdelphi_count_brst/16) or I =
      ; floor(startdelphi_count_fast/16)
      start_delphi_I = floor(startdelphi.Y[i]/16.)

      if data_rate eq 'brst' then begin
        parity_num = strcompress(string(fix(parity.Y[i])), /rem)
        
        bg_dist = scope_varfetch('bg_dist_p'+parity_num)
        n_value = scope_varfetch('n_'+parity_num)
        
        fphoto = bg_dist.Y[start_delphi_I, *, *, *]

        ; need to interpolate using SC potential data to get Nphoto value
        nphoto_scpot_dependent = reform(n_value.Y[start_delphi_I, *])
        nphoto = interpol(nphoto_scpot_dependent, n_value.V, sc_pot_data[i])
      endif else begin
        fphoto = fpi_photoelectrons.bg_dist.Y[start_delphi_I, *, *, *]
        
        ; need to interpolate using SC potential data to get Nphoto value
        nphoto_scpot_dependent = reform(fpi_photoelectrons.N.Y[start_delphi_I, *])
        nphoto = interpol(nphoto_scpot_dependent, fpi_photoelectrons.N.V, sc_pot_data[i])
      endelse

      ; now, the corrected distribution function is simply f_corrected = f-fphoto*nphoto
      ; note: transpose is to shuffle fphoto*nphoto to energy-azimuth-elevation, to match dist.data
      corrected_df = dist.data-transpose(reform(fphoto*nphoto), [2, 0, 1])
      
      if keyword_set(zero_negative_values) then begin
        where_neg = where(corrected_df lt 0, neg_count)
        if neg_count ne 0 then begin
          corrected_df[where_neg] = 0d
        endif
      endif
      
      dist.data = corrected_df
    endif

    ;Sanitize Data.
    ;#1 removes unneeded fields from struct to increase efficiency
    ;#2 Reforms into angle by energy data 
    mms_pgs_clean_data,dist,output=clean_data,units=units_lc

    ;split hpca angle bins to be equal width in phi/theta
    ;this is needed when skipping the regrid step
    if instrument eq 'hpca' then begin
      mms_pgs_split_hpca, clean_data, output=clean_data
    endif

    ; subtract the bulk velocity
    if keyword_set(subtract_bulk) then begin
      spd_pgs_v_shift, clean_data, vel_data[i,*], error=error
    endif
    
    if units_lc eq 'eflux' then begin ; from mms_convert_flux_units
      ;get mass of species
      case dist.species of
        'i': A=1;H+
        'hplus': A=1;H+
        'heplus': A=4;He+
        'heplusplus': A=4;He++
        'oplus': A=16;O+
        'oplusplus': A=16;O++
        'e': A=1d/1836;e-
        else: message, 'Unknown species: '+species_lc
      endcase

      ;scaling factor between df and flux units
      flux_to_df = A^2 * 0.5447d * 1d6

      ;convert between km^6 and cm^6 for df
      cm_to_km = 1d30

      ;calculation will be kept simple and stable as possible by
      ;pre-determining the final exponent of each scaling factor
      ;rather than multiplying by all applicable in/out factors
      ;these exponents should always be integers!
      ;    [energy, flux_to_df, cm_to_km]
      in = [0,0,0]
      out = [0,0,0]

      ;get input/output scaling exponents
      case dist.units_name of
        'flux': in = [1,0,0]
        'eflux':
        'df_km': in = [2,-1,0]
        'df_cm': in = [2,-1,1]
        else: message, 'Unknown input units: '+units_in
      endcase

      case units_lc of
        'flux':out = -[1,0,0]
        'eflux':
        'df_km': out = -[2,-1,0]
        'df_cm': out = -[2,-1,1]
        else: message, 'Unknown output units: '+units_out
      endcase

      exp = in + out

      ;ensure everything is double prec first for numerical stability
      ;  -target field won't be mutated since it's part of a structure
      clean_data.data = double(clean_data.psd) * double(clean_data.orig_energy)^exp[0] * (flux_to_df^exp[1] * cm_to_km^exp[2])
    endif
 
    ;Copy bin status prior to application of angle/energy limits.
    ;Phi limits will need to be re-applied later after phi bins
    ;have been aligned across energy (in case of irregular grid). 
    if fac_requested then begin
      pre_limit_bins = clean_data.bins 
    endif
    
    ;Apply phi, theta, & energy limits
    spd_pgs_limit_range,clean_data,phi=phi,theta=theta,energy=energy 
    
    ;Calculate moments
    ;  -data must be in 'eflux' units 
    if in_set(outputs_lc, 'moments') then begin
      spd_pgs_moments, clean_data, moments=moments, delta_times=delta_times, mag_data=mag_data, sc_pot_data=keyword_set(internal_photoelectron_corrections) ? 0 : sc_pot_data, index=i , _extra = ex
    endif 

    ;Build theta spectrogram
    if in_set(outputs_lc, 'theta') then begin
      mms_pgs_make_theta_spec, clean_data, spec=theta_spec, yaxis=theta_y
    endif
    
    ;Build phi spectrogram
    if in_set(outputs_lc, 'phi') then begin
      mms_pgs_make_phi_spec, clean_data, spec=phi_spec, yaxis=phi_y
    endif
    
    ;Build energy spectrogram
    if in_set(outputs_lc, 'energy') then begin
      mms_pgs_make_e_spec, clean_data, spec=en_spec, yaxis=en_y, energy=energy
    endif

    ;Perform transformation to FAC, regrid data, and apply limits in new coords
    if fac_requested then begin
      
      ;limits will be applied to energy-aligned bins
      clean_data.bins = temporary(pre_limit_bins)
      
      spd_pgs_limit_range,clean_data,phi=phi,theta=theta,energy=energy 
      
      ;perform FAC transformation and interpolate onto a new, regular grid 
      spd_pgs_do_fac,clean_data,reform(fac_matrix[i,*,*],3,3),output=clean_data,error=error

      ;nearest neighbor interpolation to regular grid in FAC
      if ~keyword_set(no_regrid) then begin
        spd_pgs_regrid,clean_data,regrid,output=clean_data
      endif

      
      clean_data.theta = 90-clean_data.theta ;pitch angle is specified in co-latitude
      
      ;apply gyro & pitch angle limits(identical to phi & theta, just in new coords)
      spd_pgs_limit_range,clean_data,phi=gyro,theta=pitch
      
      ;aggregate transformed data structures if requested
      if arg_present(get_data_structures) then begin
        clean_data_all = array_concat(clean_data, clean_data_all,/no_copy)
      endif

    endif

    ;Build pitch angle spectrogram
    if in_set(outputs_lc,'pa') then begin
      mms_pgs_make_theta_spec, clean_data, spec=pa_spec, yaxis=pa_y, /colatitude, resolution=regrid[1]
    endif

    if in_set(outputs_lc, 'multipad') then begin
      mms_pgs_make_multipad_spec, clean_data, spec=multi_pad_out, yaxis=pad_agl, /colatitude, resolution=regrid[1], wegy=pad_en, time_idx=i
    endif

    ;Build gyrophase spectrogram
    if in_set(outputs_lc, 'gyro') then begin
      mms_pgs_make_phi_spec, clean_data, spec=gyro_spec, yaxis=gyro_y, resolution=regrid[0]
    endif
    
    ;Build energy spectrogram from field aligned distribution
    if in_set(outputs_lc, 'fac_energy') then begin
      mms_pgs_make_e_spec, clean_data, spec=fac_en_spec,  yaxis=fac_en_y, energy=energy
    endif
    
    ;Calculate FAC moments
    ;  -data must be in 'eflux' units 
    if in_set(outputs_lc, 'fac_moments') then begin
      clean_data.theta = 90-clean_data.theta ;convert back to latitude for moments calc
      ;re-add required fields stripped by FAC transform (should fix there if feature becomes standard)
      if undefined(sc_pot_data) || keyword_set(internal_photoelectron_corrections) then scpot=0.0 else scpot = sc_pot_data[i]
      if ~keyword_set(no_regrid) then clean_data = create_struct('charge',dist.charge,'magf',[0,0,0.],'sc_pot',scpot,clean_data)
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
    options, tplot_prefix+'energy'+suffix, ysubtitle='[eV]'
  endif
 
  ;Theta Spectrograms
  if ~undefined(theta_spec) then begin
    spd_pgs_make_tplot, tplot_prefix+'theta'+suffix, x=times, y=theta_y, z=theta_spec, yrange=theta,units=units_lc,datagap=datagap,tplotnames=tplotnames
    options, tplot_prefix+'theta'+suffix, ysubtitle='[deg]'
  endif
  
  ;Phi Spectrograms
  if ~undefined(phi_spec) then begin
    ;phi range may be wrapped about phi=0, this keeps an invalid range from being passed to tplot
    phi_y_range = (undefined(start_angle) ? 0:start_angle) + [0,360]
    spd_pgs_make_tplot, tplot_prefix+'phi'+suffix, x=times, y=phi_y, z=phi_spec, yrange=phi_y_range,units=units_lc,datagap=datagap,tplotnames=tplotnames
    options, tplot_prefix+'phi'+suffix, ysubtitle='[deg]'
  endif
  
  ;Pitch Angle Spectrograms
  if ~undefined(pa_spec) then begin
    spd_pgs_make_tplot, tplot_prefix+'pa'+suffix, x=times, y=pa_y, z=pa_spec, yrange=pitch,units=units_lc,datagap=datagap,tplotnames=tplotnames
    options, tplot_prefix+'pa'+suffix, ysubtitle='[deg]'
  endif
  
  if in_set(outputs_lc, 'multipad') && ~undefined(multi_pad_out) then begin
    mms_pgs_make_tplot, tplot_prefix+'pad'+suffix, x=times, v2=pad_agl, v1=pad_en, z=multi_pad_out, yrange=pitch,units=units_lc,datagap=datagap,tplotnames=tplotnames
  endif
  
  ;Gyrophase Spectrograms
  if ~undefined(gyro_spec) then begin
    ;gyro range may be wrapped about gyro=0, this keeps an invalid range from being passed to tplot
    gyro_y_range = (undefined(start_angle) ? 0:start_angle) + [0,360]
    spd_pgs_make_tplot, tplot_prefix+'gyro'+suffix, x=times, y=gyro_y, z=gyro_spec, yrange=gyro_y_range,units=units_lc,datagap=datagap,tplotnames=tplotnames
    options, tplot_prefix+'gyro'+suffix, ysubtitle='[deg]'
  endif
  
  ;Field-Aligned Energy Spectrograms
  if ~undefined(fac_en_spec) then begin
    spd_pgs_make_tplot, tplot_prefix+'energy'+suffix, x=times, y=fac_en_y, z=fac_en_spec, ylog=1, units=units_lc,datagap=datagap,tplotnames=tplotnames
    options, tplot_prefix+'energy'+suffix, ysubtitle='[eV]'
  endif

  ;Moments Variables
  if ~undefined(moments) then begin
    moments.time = times
    spd_pgs_moments_tplot, moments, prefix=tplot_prefix, suffix=suffix, tplotnames=tplotnames, coords='DBCS', use_mms_sdc_units=sdc_units
  endif

  ;FAC Moments Variables
  if ~undefined(fac_moments) then begin
    fac_moments.time = times
    fac_mom_suffix = '_mag' + (undefined(suffix) ? '' : suffix)
    spd_pgs_moments_tplot, fac_moments, /no_mag, prefix=tplot_prefix, suffix=fac_mom_suffix, tplotnames=tplotnames, coords='FA', use_mms_sdc_units=sdc_units
  endif

  ;Return transformed data structures
  if arg_present(get_data_structures) and is_struct(clean_data_all) then begin
    get_data_structures = temporary(clean_data_all)
  endif

  error = 0
  
  dprint,'Complete. Runtime: ',systime(/sec) - twin,' secs' 
end
