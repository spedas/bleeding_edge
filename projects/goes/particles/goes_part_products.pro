;+
;Procedure:
;  goes_part_products
;
;Purpose:
;  Generate particle spectrograms for GOES MAGED/MAGPD data.

;Data Products:
;  'energy' - energy spectrogram
;  'phi' - azimuthal spectrogram 
;  'theta' - latitudinal spectrogram
;  'gyro' - gyrophase spectrogram
;  'pa' - pitch angle spectrogram
;
;
;Calling Sequence:
;  goes_part_products, probe=probe, datatype=datatype [,trange=trange] [outputs=outputs] ...
;
;
;Example Usage:
;  -energy, phi, and theta spectrograms
;    goes_part_products, probe='15', datatype='maged', outputs='phi theta energy'
;
;  -field aligned spectrograms
;    goes_part_products, probe='15', datatype='maged', output='pa gyro', $
;                       mag_name = 'g15_H_enp_1'
;
;  -limit range of input data (gyro and pa limits do not affect phi/theta spectra)
;    goes_part_products, probe='15', datatype='maged', output = 'energy pitch', $
;                       energy = [15,1e5], $  ;eV
;                       pitch = [45,135]
;
;
;Input Keywords:
;  probe:  Spacecraft designation, '13', '14', or '15'
;  datatype:  Data type, 'maged' or magpd'
;
;  trange:  Two element time range [start,end]
;  outputs:  List of requested outputs, array or space separated list, default='energy'
;            Valid entries: 'energy', 'phi', 'theta', 'pa', 'gyro'
;
;  energy:  Two element energy range [min,max], in eV
;  phi:  Two element phi range [min,max], in degrees, spacecraft spin plane
;  theta:  Two element theta range [min,max], in degrees, latitude from spacecraft spin plane
;  pitch:  Two element pitch angle range [min,max], in degrees, magnetic field pitch angle
;  gyro:  Two element gyrophase range [min,max], in degrees, gyrophase  
;
;  mag_name:  Tplot variable containing magnetic field data for moments and FAC transformations 
;    
;  fac_type:  Select the field aligned coordinate system variant.
;             Existing options: 'phigeo', 'mphigeo' (default), 'rgeo'
;  regrid:  Two element array specifying the resolution of the field-aligned data
;           over a full sphere [n_gyro,n_pitch], default is [10,5] 
;  
;  suffix:  Suffix to append to output tplot variable names 
;
;  datagap:  Setting for tplot variables, controls how long a gap must be before it is drawn. 
;            (can also manually degap)
;
;  display_object:  Object allowing dprint to export output messages  
;  uncorrected: use uncorrected data           
;  g_interpolate: interpolate uncorrected data
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
;  
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-04-11 09:42:10 -0700 (Tue, 11 Apr 2017) $
;$LastChangedRevision: 23134 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/goes/particles/goes_part_products.pro $
;-

function goes_part_intersection, set_a, set_b
  ; intersection of two sets 
  newset = []
  for i = 0, n_elements(set_a)-1 do begin
    if where(set_a[i] eq set_b) ge 0 then begin
      newset=[newset,set_a[i]]
    endif
  endfor
  return, newset
 
end

pro goes_uncor_flux_interpol, g_interpolate=g_interpolate
  ;interpolate uncorrected data producing '_dtc_uncori_flux'
  ;if keyword g_interpolate is not set, we try to find and use common points in the data
  ;otherwise, we perform interpolation 
  
  if ~keyword_set(g_interpolate) || g_interpolate eq 0 then g_interpolate=0 else g_interpolate=1
  
  names = tnames('*_dtc_uncor_flux')
  if n_elements(names) lt 1 or names[0] eq '' then begin
    dprint, "Error. No uncorected data found."
    return 
  endif
  
  if g_interpolate eq 0 then begin
    ;without interpolation (default)
    for i=0,n_elements(names)-1 do begin
      ; g15_maged_40keV_dtc_uncor_flux  40,75,150,275,475
      get_data, names[i], data=d
      curtime = d.x
      if i gt 0 then begin
        fulltime = goes_part_intersection(fulltime, curtime)        
      endif else begin
        fulltime = curtime
      endelse
      if fulltime eq !null then break
    endfor
    if n_elements(fulltime) lt 150 then begin ;few points, do interpolation 
      dprint, "Warning: Few time points are common. Interpolation will be used althought it wasn't explicitly requested."
      g_interpolate = 1
    endif
  endif 
  
  if g_interpolate eq 1 then begin
    ;with interpolation
    ; find maximum elements and interpolate using that
    n_max = 0 
    i_max = -1
    time_list = [0]
    for i=0,n_elements(names)-1 do begin
      ; g15_maged_40keV_dtc_uncor_flux  40,75,150,275,475
      get_data, names[i], data=d, limits=dlim
      curtime = d.x
      if n_max lt n_elements(curtime) then begin
        n_max = n_elements(curtime)
        i_max = i
      endif
    endfor
    
    if i_max ge 0 then begin
      dprint, "Starting GOES interpolation for uncorrected variables."
          
      curname = names[i_max]
      get_data, curname, data=d0, limits=dlim
      t0 = d0.x 
      if strlen(curname) lt 15 then begin
        dprint, "Error: Variable name too short."  
        return 
      endif
      
      new_name = strmid(curname, 0, strlen(curname)-15) +  '_dtc_uncori_flux'
      copy_data, curname, new_name
      
      for i=0,n_elements(names)-1 do begin
        if i eq i_max then continue
        ; for the new name, replace '_dtc_uncor_flux' with '_dtc_uncori_flux'
        curname = names[i]
        if strlen(curname) lt 15 then continue        
        new_name = strmid(curname, 0, strlen(curname)-15) +  '_dtc_uncori_flux'
        
        get_data, curname, data=d, limits=dlim
        ndim = size(d.y, /dimensions) 
        yn = make_array(n_elements(t0), 9, /double)       
        for j=0, 8 do begin
          yn[j] = interpol(d.y[*, j], d.x, t0)
        endfor 
        store_data, new_name, data={x:t0, y:yn}, limits=dlim      
        
      endfor
    endif else begin
      dprint, "Error: Coultn't find any data to interpolate."
    endelse    
    
  endif

end


pro goes_part_products, $

           probe=probe, $
           datatype=datatype, $

           energy=energy,$ ;two element energy range [min,max]
           trange=trange,$ ;two element time range [min,max]
                                
           phi=phi_in,$ ;angle limist 2-element array [min,max], in degrees, spacecraft spin plane
           theta=theta,$ ;angle limits 2-element array [min,max], in degrees, normal to spacecraft spin plane
           pitch=pitch,$ ;angle limits 2-element array [min,max], in degrees, magnetic field pitch angle
           gyro=gyro_in,$ ;angle limits 2-element array [min,max], in degrees, gyrophase  
           
           outputs=outputs,$ ;list of requested output types 
           
           regrid=regrid, $ ;When performing FAC transforms, loss of resolution in sample bins occurs.(because the transformed bins are not aligned with the sample bins)  
                            ;To resolve this, the FAC distribution is resampled at higher resolution.  This 2 element array specifies that resolution.[nphi,ntheta]
           
           suffix=suffix, $ ;tplot suffix to apply when generating outputs
           
           datagap=datagap, $ ;setting for tplot variables, controls how long a gap must be before it is drawn.(can also manually degap)
                  
           fac_type=fac_type,$ ;select the field aligned coordinate system variant. Existing options: "phigeo,mphigeo, xgse"
           
           mag_name=mag_name, $ ;tplot variable containing magnetic field data for moments and FAC transformations 
           
           error=error,$ ;indicate error to calling routine 1=error,0=success
           
           start_angle=start_angle, $ ;select a different start angle
           
           tplotnames=tplotnames, $ ;set of tplot variable names that were created
         
           get_data_structures=get_data_structures, $  ;pass out aggregated fac data structures
           
           display_object=display_object, $ ;object allowing dprint to export output messages
            
           uncorrected=uncorrected, $ ;use uncorrected data 
           
           g_interpolate=g_interpolate, $ ;interpolate uncorrected points
             
           _extra=ex  ; TBD: consider implementing as _strict_extra 


  compile_opt idl2
  
  twin = systime(/sec)
  error = 1
  
  if ~keyword_set(g_interpolate) || g_interpolate eq 0 then g_interpolate=0 else g_interpolate=1
    
  if ~keyword_set(uncorrected) || uncorrected eq 0 then uncorrected = 0 else begin 
    ;use uncorrected data, interpolate first
    uncorrected=1
    goes_uncor_flux_interpol,g_interpolate=g_interpolate
  endelse
  
  if undefined(probe) then begin
    dprint, 'ERROR: Must provide a probe designation, e.g. probe=''g13'''
    return
  endif else if n_elements(probe) gt 1 then begin
    dprint, 'ERROR: Multiple probes not supported'
    return
  endif

  if undefined(datatype) then begin
    dprint, 'ERROR: Must provide a probe designation, e.g. datatype=''magpd'''
    return
  endif else if n_elements(datatype) gt 1 then begin
    dprint, 'ERROR: Multiple data types not supported'
    return
  endif

  if undefined(outputs) then begin
    outputs = ['energy']
  endif
  
  outputs_lc = strlowcase(outputs)
  if n_elements(outputs_lc) eq 1 then begin 
    outputs_lc = strsplit(outputs_lc,' ',/extract)
  endif
  
  if undefined(suffix) then begin
    suffix = ''
  endif
    
  if undefined(datagap) then begin
     datagap = 600.
  endif

  if undefined(regrid) then begin
    regrid = [10,5] ;rough original resolution (should use more?)
  endif

  if undefined(pitch) then begin
    pitch = [0,180.]
  endif 
  
  if undefined(theta) then begin
    theta = [-90,90.]
  endif 
  
  if undefined(phi_in) then begin
    phi = [270,90.]
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
    mag_name = 'g'+probe+'_H_enp_1'
  endif
  
  if undefined(fac_type) then begin
    fac_type = 'mphigeo'
  endif
  
  fac_type_lc = strlowcase(fac_type)
  
  ;If set, this prevents concatenation from previous calls
  undefine,tplotnames
  

  ;--------------------------------------------------------
  ;Get array of sample times and initialize indices for loop
  ;--------------------------------------------------------
  

  times = goes_get_dist(probe=probe, datatype=datatype, trange=trange, uncorrected=uncorrected, /times)
   
  if size(times,/type) ne 5 then begin
    dprint,dlevel=1, 'No g'+probe+' '+datatype+' data has been loaded.'
    return
  endif

  if ~undefined(trange) then begin

    trd = time_double(trange)
    time_idx = where(times ge trd[0] and times le trd[1], nt)

    if nt lt 1 then begin
      dprint,dlevel=1, 'No g'+probe+' '+datatype+' data for time range ',time_string(trd)
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
  fac_outputs = ['pa','gyro','fac_energy']
  fac_requested = is_string(ssl_set_intersection(outputs_lc,fac_outputs))
  if fac_requested then begin
    goes_pgs_make_fac, times, mag_name, fac_output=fac_matrix, $
                       fac_type=fac_type_lc, display_object=display_object
    ;remove FAC outputs if there was an error, return if no outputs remain
    if undefined(fac_matrix) then begin
      fac_requested = 0
      outputs_lc = ssl_set_complement(fac_outputs,outputs_lc)
      if ~is_string(outputs_lc) then begin
        return
      endif
    endif
  endif


  ;--------------------------------------------------------
  ;Loop over time to build the spectrograms/moments
  ;--------------------------------------------------------
  
  for i = 0,n_elements(time_idx)-1 do begin
  
    spd_pgs_progress_update,last_tm,i,n_elements(time_idx)-1,display_object=display_object,type_string='g'+probe+'_'+datatype
  
    ;Get the data structure for this samgple

    dist = goes_get_dist(probe=probe, datatype=datatype, index=time_idx[i], uncorrected=uncorrected, /structure)

    ;Sanitize data (unnecessary at the moment)
;    goes_pgs_clean_data,dist,output=clean_data,units=units_lc
    clean_data = temporary(dist)
    
    ;Copy bin status prior to application of angle/energy limits.
    ;Phi limits will need to be re-applied later after phi bins
    ;have been aligned across energy (in case of irregular grid). 
    if fac_requested then begin
      pre_limit_bins = clean_data.bins 
    endif
    
    ;Apply phi, theta, & energy limits
    spd_pgs_limit_range,clean_data,phi=phi,theta=theta,energy=energy 

    ;Build theta spectrogram
    if in_set(outputs_lc, 'theta') then begin
      spd_pgs_make_theta_spec, clean_data, spec=theta_spec, yaxis=theta_y
    endif
    
    ;Build phi spectrogram
    if in_set(outputs_lc, 'phi') then begin
      spd_pgs_make_phi_spec, clean_data, spec=phi_spec, yaxis=phi_y ;, n_factor=2
    endif
    
    ;Build energy spectrogram
    if in_set(outputs_lc, 'energy') then begin
      spd_pgs_make_e_spec, clean_data, spec=en_spec, yaxis=en_y
    endif
    
    ;Perform transformation to FAC, regrid data, and apply limits in new coords
    if fac_requested then begin
      
      ;limits will be applied to energy-aligned bins
      clean_data.bins = temporary(pre_limit_bins)
      
      ;align bins across energies 
      ; -ensures smoother statistics and less jagged edges
      ;TODO: may be unnecessary for GOES
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
      spd_pgs_make_theta_spec, clean_data, spec=pa_spec, yaxis=pa_y, /colatitude
    endif
    
    ;Build gyrophase spectrogram
    if in_set(outputs_lc, 'gyro') then begin
      spd_pgs_make_phi_spec, clean_data, spec=gyro_spec, yaxis=gyro_y
    endif
    
    ;Build energy spectrogram from field aligned distribution
    if in_set(outputs_lc, 'fac_energy') then begin
      spd_pgs_make_e_spec, clean_data, spec=fac_en_spec,  yaxis=fac_en_y
    endif
    
  endfor
 
 
  ;Place nans in regions outside the requested range
  ; -This is mainly to remove "bleeding" seen when limiting the range
  ;  along a coordinate where the data is not regularly gridded.
  ;  To obtain a complete spectrogram for the limited range all intersecting
  ;  bins must be used.  This means that many bins that intersect the 
  ;  limited range but may extend far past it are left active.
  ;TODO: may be unnecessary for GOES
  spd_pgs_clip_spec, y=phi_y, z=phi_spec, range=phi
 
 
  ;--------------------------------------------------------
  ;Create tplot variables for requested data types
  ;--------------------------------------------------------

  if uncorrected eq 1 then datasuf='_dtc_uncor_flux_' else datasuf='_dtc_cor_flux_'
  tplot_prefix = 'g'+probe+'_'+datatype+datasuf
  units_lc = 'flux'
 

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

  ;Return transformed data structures
  if arg_present(get_data_structures) and is_struct(clean_data_all) then begin
    get_data_structures = temporary(clean_data_all)
  endif

  error = 0
  
  dprint,'Complete. Runtime: ',systime(/sec) - twin,' secs' 
end
