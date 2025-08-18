;+
; !!!!!  CAUTION   !!!!!
;This is a higly experimental release of the part_products libraries
;for LEP-i data of the ERG (Arase) satellite. This includes
;work in progress, experimental changes, and transitional functions
;that might or might not be present in the following experimental
;releases and the official release of the software in future. The
;codes have not fully been checked and tested yet, so can contain
;serious bugs. The help documents below is premature and has still
;been being worked on. Users are encouraged to report any bugs, mistakes,
;typos, and such that they find to the author. Thanks in advance!
; !!!!!  CAUTION   !!!!!
;
;Procedure:
;  erg_lepi_part_products
;
;Purpose:
;  A general routine to generate various kinds of particle
;  spectrograms for LEPi data. 
;
;Data products (given to keyword "outputs"):
; 'energy' - energy spectrogram
; 'phi' - azimuthal (spin phase) spectrogram
; 'theta' - latitudinal (angles with respect to the spin axis)
;           spectrogram
; 'pa' - pitch angle spectrogram
; 'gyro' - gyrophase spectrogram
;
;Exmaple usage:
; IDL> erg_lepi_part_products, 'erg_lepi_l2_3dflux_FPDU', $
;        outputs='energy'
;
;Input arguments and keywords:
;  in_tvarname: a tplot variable of 3-D flux data. currently only
;               erg_lepi?_l2_3dflux_F?DU is acceptable.
;  species: a string of particle species name. currently the following
;          strings are acceptable: 'proton', 'oplus' 
;  trange: Two element time range [start, end]
;  outputs: List of requested outputs, default='energy'
;           Valid entries: 'energy', 'phi', 'theta', 'pa', 'gyro'
;
;  energy: Two element energy range [min,max] in eV
;  phi: Two element phi range [min,max], in degrees in the spin
;       plane
;  theta: Two element theta range [min,max], in degrees latitude
;         from the spin plane
;  pitch: Two element pitch angle range [min,max], in degrees
;  gyro: Two element gyrophase range [min,max], in degrees
;
;  mag_name: Tplot variable containing magnetic field data for FAC
;            transformations. Data in the DSI coordinates should be
;            given
;  pos_name: Tplot variable containing satellite position data in
;             the GSE coordinates, which is also necessary for
;             FAC transformations
;  fac_type: Select the field aligned coorindate system variant.
;            Existing options: '(m)phigeo', '(m)phism'
;  regrid: Two element array specifying the resolution of the
;          field-aligned data over a full sphere [n_gyro, n_pitch].
;          Default is [32,16] in (phi, theta).
;  no_regrid: suppress regridding the field-aligned data. If not set,
;             the data are always regridded to 16 phi x 16 theta by
;             default.
;  suffix: Suffix to append to output tplot variable name(s)
;  degap: Setting for output tplot variables, controls how long
;         a gap in time is filled in a spectrogram. You can
;         also set this manually with tdegap. 
;
;
;Author:
;  Yoshi Miyoshi, ERG Science Center, Nagoya Univ.
;  (E-mail miyoshi _at_ nagoya-u.jp)
;
;History:
;  Sep. 2018: The 1st experimental release 
; 
; Copyright T. Hori, Nagoya Univ.  2018 All right reserved  
; Please see LICENSE.txt attached for details. 
;
;$LastChangedDate: 2019-10-23 14:19:14 -0700 (Wed, 23 Oct 2019) $
;$LastChangedRevision: 27922 $
;-
pro erg_lepi_part_products, $
   in_tvarname, $
   species=species, $
   energy=energy, $
   trange=trange, $
   phi=phi_in, $
   theta=theta, $
   pitch=pitch, $
   gyro=gyro_in, $
   outputs=outputs, $
   units=units, $
   regrid=regrid, $
   no_regrid=no_regrid, $
   suffix=suffix, $
   datagap=datagap, $
   fac_type=fac_type, $
   mag_name=mag_name, $
   pos_name=pos_name, $
   error=error, $
   start_angle=start_angle, $
   tplotnames=tplotnames, $
   silent=silent, $
   no_ang_weighting=no_ang_weighting, $
   debug=debug, $
   _extra=_extra

  compile_opt idl2
  
  if undefined(debug) then debug = 0
  if undefined(no_ang_weighting) then no_ang_weighting = 0
  
  
  twin = systime(/sec)
  error = 1

  ;; Keywords and arguments
  if ~is_string(tnames(in_tvarname[0])) then begin
    dprint, dlevel=0, 'No input data, please specify tplot variable!'
    return
  endif
  in_tvarname = tnames(in_tvarname[0])
  instnm = (strsplit(/ext, in_tvarname, '_'))[1] ;; mepe or lepi 
  
  if undefined(outputs) then begin
    outputs = ['energy']  ;; by default
  endif

  outputs_lc = strlowcase(outputs)
  if n_elements(outputs_lc) eq 1 then begin
    outputs_lc = strsplit(outputs_lc, ' ', /extract)
  endif

  if undefined(suffix) then suffix = ''

  if undefined(units) then begin
    units_lc = 'flux'
  endif else begin
    units_lc = strlowcase(units)
  endelse

  if undefined(datagap) then begin
    datagap = 32.1 ;; by default
  endif

  ;; no_regrid is on if no_ang_weighting is set.
  if no_ang_weighting then no_regrid = 1
  
  if undefined(regrid) then begin
    regrid = [32, 16] ;; default: 32 phi x 16 theta regrid
  endif

  if undefined(pitch) then begin
    pitch = [0., 180.]
  endif

  if undefined(theta) then begin
    theta = [-90., 90.]
  endif

  if undefined(phi_in) then begin
    phi = [0., 360.]
  endif else begin
    if abs(phi_in[1]-phi_in[0]) gt 360 then begin
      dprint, 'ERROR: Phi restrictions must have range no larger than 360 deg'
      return
    endif
    phi = spd_pgs_map_azimuth(phi_in)
    if phi[0] eq phi[1] then phi = [0., 360.]
  endelse

  if undefined(gyro_in) then begin
    gyro = [0., 360.]
  endif else begin
    if abs(gyro_in[1]-gyro_in[0]) gt 360 then begin
      dprint, 'ERROR: Gyro restrictions must have range no larger than 360 deg'
      return
    endif
    gyro = spd_pgs_map_azimuth(phi_in)
    if gyro[0] eq gyro[1] then gyro = [0., 360.]
  endelse

  ;;Create energy spectrogram after FAC transformation if limits are not 
  ;;identical to the default.
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
    fac_type = 'mphism'
  endif
  fac_type_lc = strlowcase(fac_type)
  
  ;;Clear the given tplotnames to prevent concatenation
  undefine, tplotnames 

  ;;Preserve the original time range
  get_timespan, tr_org


  ;;--------------------------------------------------------
  ;;Get array of sample times and initialize indices for loop
  ;;--------------------------------------------------------
 
  case instnm of
    'lepi': begin
      times = erg_lepi_get_dist(in_tvarname, /times, species=species, $
                                units=input_units)
    end
    else: begin
      dprint, 'ERROR: Cannot find "lepi" in the given tplot variable name: '+in_tvarname
      return
    endelse
  endcase


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


  ;;--------------------------------------------------------
  ;;Prepare support data
  ;;--------------------------------------------------------
  
  ;;create rotation matrix to B-field aligned coordinates if needed
  fac_outputs = ['pa','gyro','fac_energy', 'fac_moments']
  fac_requested = is_string(ssl_set_intersection(outputs_lc,fac_outputs))
  if fac_requested then begin
    erg_pgs_make_fac,times,mag_name,pos_name,fac_output=fac_matrix,fac_type=fac_type_lc,display_object=display_object
    ;;remove FAC outputs if there was an error, return if no outputs remain
    if undefined(fac_matrix) then begin
      fac_requested = 0
      outputs_lc = ssl_set_complement(fac_outputs,outputs_lc)
      if ~is_string(outputs_lc) then begin
        return
      endif
    endif
  endif

  ;;create the magnetic field vector array for moment calculation
  magf = 0
  no_mag_for_moments = 0
  
  if in_set(outputs_lc, 'moments') || in_set(outputs_lc, 'fac_moments') then begin

    no_mag = undefined(mag_name)
    magnm = (tnames(mag_name))[0]
    if no_mag or magnm eq '' then begin
      dprint, 'the magnetic field data is not given!'
      no_mag_for_moments = 1
    endif else begin

      magtmp = magnm+'_pgs_temp'
      copy_data, magnm, magtmp
      tinterpol_mxn, magtmp, times, newname=magtmp, /nan_extrapolate
      get_data, magtmp, 0, magf  ;; [ time, 3] nT
      if debug then dprint, 'magf array is prepared for coordinate transformation referring to the B-field'

    endelse

  endif

  ;;-------------------------------------------------
  ;; Loop over time to build spectrograms and/or moments
  ;;-------------------------------------------------
  
  for i=0L, n_elements(time_idx)-1 do begin

    erg_pgs_progress_update, last_tm, i, n_elements(time_idx)-1, $
                             display_object=display_object, $
                             type_string=in_tvarname

    ;; Get the data structure for this sample
    case instnm of
      'lepi': begin
        dist = erg_lepi_get_dist(in_tvarname, time_idx[i], /structure, $
                                 species=species, units=input_units)
      end
      else: begin
        dprint, 'ERROR: Cannot find "lepi" in the given tplot variable name: '+in_tvarname
        return
      endelse
    endcase
    ;;help, dist, time_idx, i

    ;; To be implemented in future to remove unneeded fields from the
    ;; structure to increase efficiency and reform into angle by
    ;; energy data. 
    if ndimen(magf) eq 2 then magvec = reform( magf[ i, *] )

    erg_pgs_clean_data, dist, output=clean_data, units=units_lc, $
      magf=magvec
    
    
    if fac_requested then begin
      pre_limit_bins = clean_data.bins
    endif

    ;; Apply phi, theta, and energy limits
    erg_pgs_limit_range, clean_data, phi=phi, theta=theta, energy=energy, no_ang_weighting=no_ang_weighting

    ;; Calculate moments
    ;; -data must be in 'eflux' unit and the conversion is made internally
    ;; by moments_3d() called in spd_pgs_moments.. 
    if in_set(outputs_lc, 'moments') then begin
      erg_convert_flux_units, clean_data, units='eflux', output=clean_data_eflux
      magfarr = magf ;;& help,  magf
      if n_elements(magf) eq 1 and magf[0] eq 0 then undefine, magfarr

      spd_pgs_moments, clean_data_eflux, moments=moments, $
                       sigma=mom_sigma, delta_times=delta_times, $
                       get_error=get_error, $
                       mag_data=magfarr, sc_pot_data=sc_pot_data, $
                       index=i, _extra=_extra
    endif
    
    ;;Build theta spectrogram
    if in_set(outputs_lc, 'theta') then begin
      erg_pgs_make_theta_spec, clean_data, spec=theta_spec, yaxis=theta_y, no_ang_weighting=no_ang_weighting
    endif
    
    ;;Build phi spectrogram
    if in_set(outputs_lc, 'phi') then begin
      erg_pgs_make_phi_spec, clean_data, spec=phi_spec, yaxis=phi_y, no_ang_weighting=no_ang_weighting
    endif
    
    ;; Build energy spectrogram
    if in_set(outputs_lc, 'energy') then begin
      spd_pgs_make_e_spec, clean_data, spec=en_spec, yaxis=en_y
    endif

    ;;Perform transformation to FAC, regrid data, and apply limits in new coords
    if fac_requested then begin
      
      ;limits will be applied to energy-aligned bins
      clean_data.bins = temporary(pre_limit_bins)
      
      erg_pgs_limit_range,clean_data,phi=phi,theta=theta,energy=energy, no_ang_weighting=no_ang_weighting

      ;perform FAC transformation and interpolate onto a new, regular grid 
      erg_pgs_do_fac,clean_data,reform(fac_matrix[i,*,*],3,3),output=clean_data,error=error

      ;nearest neighbor interpolation to regular grid in FAC
      if ~keyword_set(no_regrid) then begin
        spd_pgs_regrid,clean_data,regrid,output=clean_data
      endif
      
      clean_data.theta = 90-clean_data.theta ;pitch angle is specified in co-latitude
      
      ;apply gyro & pitch angle limits(identical to phi & theta, just in new coords)
      erg_pgs_limit_range,clean_data,phi=gyro,theta=pitch, no_ang_weighting=no_ang_weighting
      
      ;;aggregate transformed data structures if requested
      ;;if arg_present(get_data_structures) then begin
      ;;  clean_data_all = array_concat(clean_data, clean_data_all,/no_copy)
      ;;endif

    endif
    
    ;Build pitch angle spectrogram
    if in_set(outputs_lc,'pa') then begin
      erg_pgs_make_theta_spec, clean_data, spec=pa_spec, yaxis=pa_y, /colatitude, resolution=regrid[1], $
                               no_ang_weighting=no_ang_weighting
    endif
    
    ;Build gyrophase spectrogram
    if in_set(outputs_lc, 'gyro') then begin
      erg_pgs_make_phi_spec, clean_data, spec=gyro_spec, yaxis=gyro_y, resolution=regrid[0], $
                             no_ang_weighting=no_ang_weighting
    endif
    
    ;Build energy spectrogram from field aligned distribution
    if in_set(outputs_lc, 'fac_energy') then begin
      spd_pgs_make_e_spec, clean_data, spec=fac_en_spec,  yaxis=fac_en_y
    endif
    ;;;;;;help, clean_data
    ;; Calculate FAC moments
    ;; -data must be in 'eflux' unit and the conversion is made internally
    ;; in moments_3d(). 
    if in_set(outputs_lc, 'fac_moments') then begin
      clean_data.theta = 90-clean_data.theta ;convert back to latitude for moments calc
      clean_data =  create_struct('charge', dist.charge, 'magf', [0, 0, 0.], $
                                  'species', dist.species, 'sc_pot', 0., $
                                 'units_name', units_lc, clean_data )
      erg_convert_flux_units, clean_data, units='eflux', output=clean_data_eflux
      ;;magfarr = magf ;;& help,  magf
      if n_elements(magf) eq 1 and magf[0] eq 0 then undefine, magfarr
      spd_pgs_moments, clean_data_eflux, moments=fac_moments, $
                       sigma=mom_sigma, delta_times=delta_times, $
                       get_error=get_error, $
                       sc_pot_data=sc_pot_data, $
                       index=i, _extra=_extra
    endif

  endfor


  ;;Place nans in regions outside the requested range
  ;; -This is mainly to remove "bleeding" seen when limiting the range
  ;;  along a coordinate where the data is not regularly gridded.
  ;;  To obtain a complete spectrogram for the limited range all intersecting
  ;;  bins must be used.  This means that many bins that intersect the 
  ;;  limited range but may extend far past it are left active.
  spd_pgs_clip_spec, y=phi_y, z=phi_spec, range=phi


  ;; Create tplot variables for requested data types

  tplot_prefix = in_tvarname+'_'

    ;;Energy Spectrograms
  if ~undefined(en_spec) then begin
    erg_pgs_make_tplot, tplot_prefix+'energy'+suffix, x=times, y=en_y, z=en_spec, ylog=1, units=units_lc,datagap=datagap,tplotnames=tplotnames, $
      ysubtitle=ysubtitle
  endif
 
  ;;Theta Spectrograms
  if ~undefined(theta_spec) then begin
    erg_pgs_make_tplot, tplot_prefix+'theta'+suffix, x=times, y=theta_y, z=theta_spec, yrange=theta,units=units_lc,datagap=datagap,tplotnames=tplotnames
  endif
  
  ;;Phi Spectrograms
  if ~undefined(phi_spec) then begin
    ;;phi range may be wrapped about phi=0, this keeps an invalid range from being passed to tplot
    phi_y_range = (undefined(start_angle) ? 0:start_angle) + [0,360]
    erg_pgs_make_tplot, tplot_prefix+'phi'+suffix, x=times, y=phi_y, z=phi_spec, yrange=phi_y_range,units=units_lc,datagap=datagap,tplotnames=tplotnames
    spd_pgs_shift_phi_spec, names=tplot_prefix+'phi'+suffix, start_angle=start_angle
  endif
  
  ;;Pitch Angle Spectrograms
  if ~undefined(pa_spec) then begin
    erg_pgs_make_tplot, tplot_prefix+'pa'+suffix, x=times, y=pa_y, z=pa_spec, yrange=pitch, units=units_lc, datagap=datagap, tplotnames=tplotnames
    options, tplotnames, ytickinterval=45., constant=[45.,90.,135.]
  endif
  
  ;;Gyrophase Spectrograms
  if ~undefined(gyro_spec) then begin
    ;;gyro range may be wrapped about gyro=0, this keeps an invalid range from being passed to tplot
    gyro_y_range = (undefined(start_angle) ? 0:start_angle) + [0,360]
    erg_pgs_make_tplot, tplot_prefix+'gyro'+suffix, x=times, y=gyro_y, z=gyro_spec, yrange=gyro_y_range,units=units_lc,datagap=datagap,tplotnames=tplotnames
    spd_pgs_shift_phi_spec, names=tplot_prefix+'gyro'+suffix, start_angle=start_angle
    options, tplotnames, ytickinterval=90., constant=[90.,180.,270.]
  endif
  
  ;;Field-Aligned Energy Spectrograms
  if ~undefined(fac_en_spec) then begin
    erg_pgs_make_tplot, tplot_prefix+'energy'+suffix, x=times, y=fac_en_y, z=fac_en_spec, ylog=1, units=units_lc,datagap=datagap,tplotnames=tplotnames, $
      ysubtitle=ysubtitle
  endif

  
  ;Moments Variables
  if ~undefined(moments) then begin
    moments.time = times
    if debug then dprint, 'erg_pgs_moments_tplot is just about to run now'
    erg_pgs_moments_tplot, moments, prefix=tplot_prefix, suffix=suffix, tplotnames=tplotnames, no_mag=no_mag_for_moments
  endif

  ;FAC Moments Variables
  if ~undefined(fac_moments) then begin
    fac_moments.time = times
    fac_mom_suffix = '_mag' + (undefined(suffix) ? '' : suffix)
    erg_pgs_moments_tplot, fac_moments, /no_mag, prefix=tplot_prefix, suffix=fac_mom_suffix, tplotnames=tplotnames
  endif  



  error = 0
  
  timespan, tr_org ;; Restore the original time range

  dprint, 'Complete. Runtime: ', systime(/sec)-twin, ' secs'
  
  return
end
