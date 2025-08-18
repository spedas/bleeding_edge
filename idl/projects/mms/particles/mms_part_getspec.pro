;+
; Procedure:
;         mms_part_getspec
;
;
; Purpose:
;         This is a wrapper around mms_part_products that loads required 
;         support data (if not already loaded), and optionally creates
;         angular spectrograms with B-field and S/C ram directions specified 
;         using symbols
;
; Keywords:
;         probes: array of probes
;         instrument: fpi or hpca
;         species: depends on instrument:
;             FPI: 'e' for electrons, 'i' for ions
;             HPCA: 'hplus' for H+, 'oplus' for O+, 'heplus' for He+, 'heplusplus', for He++
;         outputs: list of requested output types, 
;             'energy' - energy spectrogram
;             'phi' - azimuthal spectrogram
;             'theta' - latitudinal spectrogram
;             'gyro' - gyrophase spectrogram
;             'pa' - pitch angle spectrogram
;             'multipad' - pitch angle spectrogram at every energy 
;                 (multi-dimensional PAD variable, to be used by mms_part_getpad)
;             'moments' - distribution moments (density, velocity, etc.) 
;         add_bfield_dir: add B-field direction (+, -) to the angular spectrograms (phi, theta)
;         add_ram_dir: add S/C ram direction (X) to the angular spectrograms (phi, theta)
;         dir_interval: number of seconds between B-field and S/C ram direction symbols on angular spectrogram plots
;         
;         subtract_bulk: subtract the bulk velocity prior to doing the calculations
;         subtract_error: subtract the distribution error prior to doing the calculations (FPI only, currently)
;         subtract_spintone: subtract the spin-tone from the velocity vector prior to bulk velocity subtraction (FPI versions 3.2 and later only)
;         
;         photoelectron_corrections: *experimental* photoelectron corrections for DES; enabled by default for DES moments; you can disable with photoelectron_corrections=0
;         remove_fpi_sw: Flag to remove the solar wind component from the FPI ion DFs prior to performing the calculations
;         sdc_units: Flag to convert moments_3d pressure tensor and heat flux outputs to nPa and mW/m^2 respectively, for compatibility with MMS SDC moments
;         
;     The following are found by default for the requested instrument/probe/data_rate; use these keywords 
;     to override the defaults:
;         mag_name:  Use a different tplot variable containing magnetic field data for moments and FAC transformations
;         pos_name:  Use a different tplot variable containing spacecraft position for FAC transformations
;         vel_name:  Use a different tplot variable containing velocity data in km/s when subtracting the bulk velocity
;         sc_pot_name: Use a different tplot variable containing spacecraft potential data
;  
; Notes:
;         Updated to automatically center HPCA measurements if not specified already, 18Oct2017
;         
;         Updated to automatically correct FPI-DES moments for photoelectrons, 20Sept2018
;         
;         FPI-DES internal photoelectrons are corrected using Dan Gershman's photoelectron model; see the following for details: 
;             Spacecraft and Instrument Photoelectrons Measured by the Dual Electron Spectrometers on MMS
;             https://agupubs.onlinelibrary.wiley.com/doi/full/10.1002/2017JA024518
;             
;         Spacecraft photoelectrons are corrected in moments_3d
;         
;$LastChangedBy: jwl $
;$LastChangedDate: 2025-07-12 19:14:21 -0700 (Sat, 12 Jul 2025) $
;$LastChangedRevision: 33459 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/mms_part_getspec.pro $
;-

pro mms_part_getspec, probes=probes, $
                      level=level, $
                      data_rate=data_rate, $
                      trange=trange, $
                      energy=energy,$ ;energy range
                      species=species, $ ; FPI: 'i' for ions, 'e' for electrons; HPCA: 'hplus' for H+, 'oplus' for O+, etc.
                      instrument=instrument, $ ; HPCA or FPI
                      
                      outputs=outputs,$ ;list of requested output types

                      units=units,$ ;scalar unit conversion for data
                        
                      phi=phi_in,$ ;angle limit 2-element array [min,max], in degrees, spacecraft spin plane
                      theta=theta,$ ;angle limits 2-element array [min,max], in degrees, normal to spacecraft spin plane
                      pitch=pitch,$ ;angle limits 2-element array [min,max], in degrees, magnetic field pitch angle
                      gyro=gyro_in,$ ;angle limits 2-element array [min,max], in degrees, gyrophase
                      
                      regrid=regrid, $ ;When performing FAC transforms, loss of resolution in sample bins occurs.(because the transformed bins are not aligned with the sample bins)
                      ;To resolve this, the FAC distribution is resampled at higher resolution.  This 2 element array specifies that resolution.[nphi,ntheta]
                      
                      suffix=suffix, $ ;tplot suffix to apply when generating outputs

                      datagap=datagap, $ ;setting for tplot variables, controls how long a gap must be before it is drawn.(can also manually degap)

                      forceload=forceload, $ --force data load (otherwise will try to use previously loaded data)

                      mag_suffix=mag_suffix,$
                        
                      subtract_bulk=subtract_bulk, $
                      subtract_error=subtract_error, $
                      subtract_spintone=subtract_spintone, $ ; FPI CDFs 3.2+ only
                      remove_fpi_sw=remove_fpi_sw, $
                      
                      ; the following are for overriding the defaults
                      vel_name=vel_name_user, $  ; Tplot variable containing velocity data in km/s for use with /subtract_bulk
                      mag_name=mag_name_user, $  ; Tplot variable containing magnetic field data for moments and FAC transformations
                      pos_name=pos_name_user, $  ; Tplot variable containing spacecraft position for FAC transformations
                      sc_pot_name=sc_pot_name_user, $ ; Tplot variable containing spacecraft potential for moments and spectra
                      center_measurement=center_measurement, $
                      tplotnames=tplotnames, $
                      
                      mag_data_rate=mag_data_rate, $
                      scpot_data_rate=scpot_data_rate, $
                      
                      photoelectron_corrections=photoelectron_corrections, $ ; Apply both internal photoelectron corrections (Dan Gershman's model) and correct for S/C potential (should not be used with either of the bottom two)
                      internal_photoelectron_corrections=internal_photoelectron_corrections, $ ; Only apply Dan Gershman's model (i.e., don't correct for the S/C potential in moments_3d)
                      correct_sc_potential=correct_sc_potential, $ ; only correect for the S/C potential (disables Dan Gershman's model)
                      zero_negative_values=zero_negative_values, $ ; keyword that tells mms_part_products to turn negative values to 0 after doing the photoelectron corrections (DES)
                      with_aspoc=with_aspoc, $
                      
                      cdf_version=cdf_version, $
                      latest_version=latest_version, $
                      major_version=major_version, $
                      min_version=min_version, $
                      
                      add_bfield_dir=add_bfield_dir, $
                      add_ram_dir=add_ram_dir, $
                      dir_interval=dir_interval, $
                      
                      spdf=spdf, $
                      sdc_units=sdc_units, $  ; Convert moments_3d ptens and qflux units to nPa and mW/m^2 respectively, for compatibility with MMS SDC moments
                      _extra=ex 

    compile_opt idl2

    start_time = systime(/seconds)
    
    if ~keyword_set(trange) then begin
        trange = timerange()
    endif else trange = timerange(trange)
    
    if ~keyword_set(units) then begin
      units_lc = 'eflux'
    endif else units_lc = strlowcase(units)

    if ~keyword_set(outputs) then begin
        outputs = ['phi','theta','energy','pa','gyro']
    endif else outputs = strlowcase(outputs)
    
    if n_elements(outputs) eq 1 then begin
      outputs = strsplit(outputs,' ',/extract)
    endif
    
    if ~keyword_set(instrument) then begin
        instrument = 'fpi'
    endif else instrument = strlowcase(instrument)
    
    if ~keyword_set(data_rate) then begin
        if instrument eq 'fpi' then data_rate = 'fast' else data_rate = 'srvy'
    endif else data_rate = strlowcase(data_rate)
    
    if data_rate eq 'brst' && undefined(mag_data_rate) then begin
      mag_data_rate = 'brst'
    endif else begin
      if undefined(mag_data_rate) then mag_data_rate = 'srvy'
    endelse
    if data_rate eq 'brst' && undefined(scpot_data_rate) then begin
      scpot_data_rate = 'brst'
    endif else begin 
      if undefined(scpot_data_rate) then scpot_data_rate = 'fast'
    endelse
    
    if ~keyword_set(species) then begin
        if instrument eq 'fpi' then species = 'e' else species = 'hplus'
    endif else species = strlowcase(species)
    
    if ~keyword_set(probes) then begin
        probes = ['1', '2', '3', '4']
    endif else probes = strcompress(string(probes), /rem)
    
    if ~keyword_set(mag_suffix) then mag_suffix = ''
    if ~keyword_set(dir_interval) then begin
      if mag_data_rate eq 'srvy' then dir_interval = 60d else dir_interval = 1
    endif
    
    if keyword_set(subtract_error) && instrument eq 'hpca' then begin
      dprint, dlevel = 0, 'Error, /subtract_error keyword currently only valid for FPI data. No disterr is being subtracted.'
      stop
    endif
    
    ; turn on photoelectron corrections if the user is requesting DES moments, to match the nominal FPI L2 moment calculations 
    if instrument eq 'fpi' && species eq 'e' && array_contains(outputs, 'moments') then begin
      if undefined(photoelectron_corrections) && undefined(internal_photoelectron_corrections) && undefined(correct_sc_potential) then photoelectron_corrections = 1b
    endif
    
    ; prevents concatenation from previous calls
    undefine, tplotnames
    
    ; HPCA is required to be at the center of the accumulation interval
    if instrument eq 'hpca' and ~keyword_set(center_measurement) then center_measurement = 1
    
    support_trange = trange + [-60,60]
    
    for probe_idx = 0, n_elements(probes)-1 do begin
        if ~spd_data_exists('mms'+strcompress(string(probes[probe_idx]), /rem)+'_fgm_b_gse_'+mag_data_rate+'_l2_bvec'+mag_suffix, trange[0], trange[1]) or keyword_set(forceload) then append_array, fgm_to_load, probes[probe_idx] else time_clip, 'mms'+strcompress(string(probes[probe_idx]), /rem)+'_fgm_b_gse_'+mag_data_rate+'_l2_bvec'+mag_suffix, trange[0], trange[1], newname='mms'+strcompress(string(probes[probe_idx]), /rem)+'_fgm_b_gse_'+mag_data_rate+'_l2_bvec'+mag_suffix
        if ~spd_data_exists('mms'+strcompress(string(probes[probe_idx]), /rem)+'_defeph_pos', trange[0], trange[1]) or keyword_set(forceload) then append_array, state_to_load, probes[probe_idx] else time_clip, 'mms'+strcompress(string(probes[probe_idx]), /rem)+'_defeph_pos', trange[0], trange[1], newname='mms'+strcompress(string(probes[probe_idx]), /rem)+'_defeph_pos'
        if ~spd_data_exists('mms'+strcompress(string(probes[probe_idx]), /rem)+'_edp_scpot_'+scpot_data_rate+'_l2', trange[0], trange[1]) or keyword_set(forceload) then append_array, scpot_to_load, probes[probe_idx] else time_clip, 'mms'+strcompress(string(probes[probe_idx]), /rem)+'_edp_scpot_'+scpot_data_rate+'_l2', trange[0], trange[1], newname='mms'+strcompress(string(probes[probe_idx]), /rem)+'_edp_scpot_'+scpot_data_rate+'_l2'
    endfor

    ; load state data (needed for coordinate transforms and field aligned coordinates)
    if defined(state_to_load) && undefined(pos_name_user) then mms_load_mec, probes=state_to_load, trange=support_trange, spdf=spdf, varformat='*_mec_v_gse* *_mec_r_gse*', /time_clip

    ; load magnetic field data
    if defined(fgm_to_load) && undefined(mag_name_user) then mms_load_fgm, probes=fgm_to_load, trange=support_trange, level='l2', suffix=mag_suffix, spdf=spdf, data_rate=mag_data_rate, /time_clip, varformat='*_fgm_b_gse_*'

    if defined(scpot_to_load) && (array_contains(outputs, 'fac_moments') || array_contains(outputs, 'moments')  || keyword_set(photoelectron_corrections) || keyword_set(internal_photoelectron_corrections)) then mms_load_edp, probes=scpot_to_load, trange=support_trange, level='l2', spdf=spdf, data_rate=scpot_data_rate, datatype='scpot', varformat='*_edp_scpot_*'

    if instrument eq 'fpi' then begin
        mms_load_fpi, probes=probes, trange=trange, data_rate=data_rate, level=level, $
            datatype='d'+species+'s-dist', /time_clip, center_measurement=center_measurement, $
            cdf_version=cdf_version, latest_version=latest_version, major_version=major_version, $
            min_version=min_version, spdf=spdf, varformat='*_d'+species+'s_dist_* *s_disterr_* *_d?s_startdelphi_count_* *_d?s_steptable_parity*'
            
        ; load the bulk velocity if the user requested to subtract it
        if keyword_set(subtract_bulk) && undefined(vel_name_user) then mms_load_fpi, probes=probes, trange=trange, data_rate=data_rate, level=level, $
            datatype='d'+species+'s-moms', spdf=spdf, varformat='*_d'+species+'s_bulkv_gse_* *s_bulkv_spintone_gse_*'
    endif else if instrument eq 'hpca' then begin
        mms_load_hpca, probes=probes, trange=trange, data_rate=data_rate, level=level, $
            datatype='ion', center_measurement=center_measurement,  $
            /major_version, $
            spdf=spdf, /time_clip, varformat='*_hpca_'+species+'_phase_space_density *_hpca_azimuth_angles_per_ev_degrees'
        
        ; load the bulk velocity if the user requested to subtract it
        if keyword_set(subtract_bulk) && undefined(vel_name_user) then mms_load_hpca, probes=probes, trange=trange, $
            data_rate=data_rate, level=level, datatype='moments', spdf=spdf, varformat='*_hpca_'+species+'_ion_bulk_velocity', /major_version
    endif
    
    for probe_idx = 0, n_elements(probes)-1 do begin
        if undefined(mag_name_user) then bname = 'mms'+probes[probe_idx]+'_fgm_b_gse_'+mag_data_rate+'_l2_bvec'+mag_suffix else bname = mag_name_user
        if undefined(pos_name_user) then pos_name = 'mms'+probes[probe_idx]+'_mec_r_gse' else pos_name = pos_name_user
        if undefined(sc_pot_name_user) then scpot_variable = 'mms'+probes[probe_idx]+'_edp_scpot_'+scpot_data_rate+'_l2' else scpot_variable = sc_pot_name_user

        ;;;;;;;;;;;;; kludge zone;;;;;;;;;;;
        if keyword_set(with_aspoc) then begin
          mms_load_aspoc, trange=trange, probe=probes[probe_idx]
          tinterpol, 'mms'+probes[probe_idx]+'_edp_scpot_'+scpot_data_rate+'_l2', 'mms'+probes[probe_idx]+'_aspoc_ionc_l2'
          calc, '"scpot_adjusted"="mms'+probes[probe_idx]+'_edp_scpot_'+scpot_data_rate+'_l2_interp"+"mms'+probes[probe_idx]+'_aspoc_ionc_l2"'
          scpot_variable = 'scpot_adjusted'
        endif
;        ;;;;;;;;;;;;; end kludge zone ;;;;;;;;;;;;


        if instrument eq 'fpi' then begin
            name = 'mms'+probes[probe_idx]+'_d'+species+'s_dist_'+data_rate
            if undefined(vel_name_user) then vel_name = 'mms'+probes[probe_idx]+'_d'+species+'s_bulkv_gse_'+data_rate else vel_name = vel_name_user
            if keyword_set(subtract_error) then error_variable = 'mms'+probes[probe_idx]+'_d'+species+'s_disterr_'+data_rate
            if keyword_set(subtract_spintone) && tnames(vel_name) ne '' && tnames('mms'+probes[probe_idx]+'_d'+species+'s_bulkv_spintone_gse_'+data_rate) ne '' then calc, '"'+'mms'+probes[probe_idx]+'_d'+species+'s_bulkv_gse_'+data_rate+'"="'+'mms'+probes[probe_idx]+'_d'+species+'s_bulkv_gse_'+data_rate+'"-"'+'mms'+probes[probe_idx]+'_d'+species+'s_bulkv_spintone_gse_'+data_rate+'"'
        endif else if instrument eq 'hpca' then begin
            name =  'mms'+probes[probe_idx]+'_hpca_'+species+'_phase_space_density'
            if undefined(vel_name_user) then vel_name = 'mms'+probes[probe_idx]+'_hpca_'+species+'_ion_bulk_velocity' else vel_name = vel_name_user
        endif

        mms_part_products, name, trange=trange, units=units_lc, $
            mag_name=bname, pos_name=pos_name, vel_name=vel_name, energy=energy, $
            pitch=pitch, gyro=gyro_in, phi=phi_in, theta=theta, regrid=regrid, $
            outputs=outputs, suffix=suffix, datagap=datagap, subtract_bulk=subtract_bulk, $
            tplotnames=tplotnames_thisprobe, subtract_error=subtract_error, $
            error_variable=error_variable, instrument=instrument, species=species, $
            sc_pot_name=scpot_variable, data_rate=data_rate, correct_photoelectrons=photoelectron_corrections, $
            internal_photoelectron_corrections=internal_photoelectron_corrections, $
            correct_sc_potential=correct_sc_potential, zero_negative_values=zero_negative_values, $
            remove_fpi_sw=remove_fpi_sw, sdc_units=sdc_units, _extra=ex

        if undefined(tplotnames_thisprobe) then continue ; nothing created by mms_part_products
        append_array, tplotnames, tplotnames_thisprobe

        if keyword_set(add_ram_dir) then begin
            ; average the velocity data before adding to the plot
            avg_data, 'mms'+probes[probe_idx]+'_mec_v_gse', dir_interval
            get_data, 'mms'+probes[probe_idx]+'_mec_v_gse_avg', data=velocity_gse
            cart_to_sphere, velocity_gse.Y[*, 0], velocity_gse.Y[*, 1], velocity_gse.Y[*, 2], vel_r, vel_theta, vel_phi, /PH_0_360
            store_data, name+'_phi_vdata', data={x: velocity_gse.X, y: vel_phi}
            store_data, name+'_theta_vdata', data={x: velocity_gse.X, y: vel_theta}
            options, name+'_phi_vdata', psym=7, linestyle=6 ; X
            options, name+'_theta_vdata', psym=7, linestyle=6 ; X
            store_data, name+'_phi_with_v'+suffix, data=name+'_phi'+suffix+' '+name+'_phi_vdata'
            store_data, name+'_theta_with_v'+suffix, data=name+'_theta'+suffix+' '+name+'_theta_vdata'
            ylim, name+'_phi_with_v'+suffix, 0., 360., 0
            ylim, name+'_theta_with_v'+suffix, -90., 90., 0
        endif
        if keyword_set(add_bfield_dir) then begin
            ; average the B-field before adding to the plot
            avg_data, bname, dir_interval
            get_data, bname+'_avg', data=b_field_data
            neg_b_field = -b_field_data.Y
            
            cart_to_sphere, b_field_data.Y[*, 0], b_field_data.Y[*, 1], b_field_data.Y[*, 2], r, theta, phi, /PH_0_360
            cart_to_sphere, neg_b_field[*, 0], neg_b_field[*, 1], neg_b_field[*, 2], negr, negtheta, negphi, /PH_0_360
            
            store_data, name+'_phi_bdata', data={x: b_field_data.X, y: phi}
            store_data, name+'_minusphi_bdata', data={x: b_field_data.X, y: negphi}
            store_data, name+'_theta_bdata', data={x: b_field_data.X, y: theta}
            store_data, name+'_minustheta_bdata', data={x: b_field_data.X, y: negtheta}
            
            usersym, [-1, 1], [0, 0] ; minus sign
            
            options, name+'_phi_bdata',psym=1, linestyle=6 ; +
            options, name+'_minusphi_bdata',psym=8, linestyle=6 ; -
            options, name+'_theta_bdata',psym=1, linestyle=6 ; +
            options, name+'_minustheta_bdata',psym=8, linestyle=6 ; -
            
            store_data, name+'_phi_with_b'+suffix, data=name+'_phi'+suffix+' '+name+'_phi_bdata '+name+'_minusphi_bdata'
            store_data, name+'_theta_with_b'+suffix, data=name+'_theta'+suffix+' '+name+'_theta_bdata '+name+'_minustheta_bdata'
            ylim, name+'_phi_with_b'+suffix, 0., 360., 0
            ylim, name+'_theta_with_b'+suffix, -90., 90., 0
        endif
        if keyword_set(add_bfield_dir) and keyword_set(add_ram_dir) then begin
            store_data, name+'_phi_with_bv'+suffix, data=name+'_phi'+suffix+' '+name+'_phi_bdata '+name+'_minusphi_bdata '+name+'_phi_vdata'
            store_data, name+'_theta_with_bv'+suffix, data=name+'_theta'+suffix+' '+name+'_theta_bdata '+name+'_minustheta_bdata '+name+'_theta_vdata'
            ylim, name+'_phi_with_bv'+suffix, 0., 360., 0
            ylim, name+'_theta_with_bv'+suffix, -90., 90., 0
        endif 
    endfor
    
end
