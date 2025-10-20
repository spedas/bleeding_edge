;+
;FUNCTION:  SWFO_STIS_INST_RESPONSE_CALVAL
;PURPOSE: Creates a dictionary containing calibration constants
;   for determining calibrated SWFO STIS data for Level 1a and 1b. 
;       -  Will store the dictionary as a global variable
;     (swfo_stis_inst_response_calval_dict) for quick retrieval
;     on subsequent calls, unless /reset keyword used.
;       - Will save to a CDL-defined NetCDF if save set equal
;     to the path to an empty CDF.
;
; To test table, run:
;     calval = swfo_stis_inst_response_calval()
; To write to Netcdf, run:
;     calval = swfo_stis_inst_response_calval(save='<NETCDF_FILENAME_HERE>')
; Can test the Netcdf using:
;     alt_cal = swfo_ncdf_read(filenames='<NETCDF_FILENAME_HERE>')
;     printdat, alt_cal
; 
; $LastChangedBy: rjolitz $
; $LastChangedDate: 2025-10-18 18:55:35 -0700 (Sat, 18 Oct 2025) $
; $LastChangedRevision: 33771 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_inst_response_calval.pro $
; $Id: swfo_stis_inst_response_calval.pro 33771 2025-10-19 01:55:35Z rjolitz $



function swfo_stis_inst_response_calval,reset=reset, save=save

  common swfo_stis_inst_response_com, swfo_stis_inst_response_calval_dict, cal1, cal2

  if keyword_set(reset) then  obj_destroy,swfo_stis_inst_response_calval_dict
  
  if ~isa( swfo_stis_inst_response_calval_dict, 'dictionary') then begin
    calval = dictionary()
  endif else begin
    calval = swfo_stis_inst_response_calval_dict
  endelse

  if calval.isempty() then begin
    nan = !values.f_nan

    calval.instrument_name  = 'SWFO-STIS'
    ; Channel names / detector names:
    calval.channels = ['1', '2', '3', '4', '5', '6']
    calval.detectors = ['O1', 'O2', 'O3', 'F1', 'F2', 'F3']

    ; Geometric factor needs verification:
    ; calval.geometric_factor = .13 * [nan, .01,  1 , .99]   * !pi
    ; calval.geometric_factor = .2  * [nan, .01,1,1,.01,1,1]
    gf = 0.2 * [0.01, 1., 1., 0.01, 1., 1.]
    calval.geometric_factor = gf
    ; geom_raw = [nan, calval.geometric_factor]
    ; calval.geoms         = reform( geom_raw[[1,2,3,1,2,3]] , dim )
    ; calval.geoms_tid_fto = [1,1] #  geom_raw[det2fto] 

    ; Calibration result: ADC values for the Americium-241 59.5 keV line 
    ; for detectors O1, O2, O3, F1, F2, F3:
    calibrated_adc_bins = [    234.06952     ,  228.35745    ,  231.78710     ,  232.06377      ,  232.78850      ,  231.65691    ]  
    ; calibrated_adc_bins = [234.1  , 228.4 , 232.4, 233.4, 232.7,  232.5]
    detector_keV_per_adc = 59.5 / calibrated_adc_bins   ; for conversion from nrg to adc units 
    calval.detector_keV_per_adc = detector_keV_per_adc
    ; det_adc_scales = 1/detector_keV_per_adc

    ; Indices of the ion (O) and electron (F) in small pixel AR1 (1)
    ; and big pixel AR2 (3) for single coincidences (e.g. 1, 2, 3)
    ;Index:          0,        1,        2,        3,        4,         5,
    ;Channel #:      1,        4,        2,        5,      1-2,       4-5,
    ;Detector:      O1,       F1,      O2,       F2,      O12,       F12,
    ;Meaning:  Ion-AR1, Elec-AR1, Ion-AR3, Elec-AR3, Ion-AR13, Elec-AR13,
    ; -----------------------------
    ;      6,        7,        8,         9,       10,        11,      12,        13
    ;      3,        6,      1-3,       4-6,      2-3,       5-6,   1-2-3,     4-5-6
    ;     O3,       F3,      O13,       F13,      O23,       F56,    O123,      F123
    ;Ion-AR2, Elec-AR2, Ion-AR12, Elec-AR12, Ion-AR23, Elec-AR23, Ion-123, Elec-F123

    calval.coincidence =$
      ['O1', 'F1', 'O2', 'F2', 'O12', 'F12', 'O3', 'F3', 'O13', 'F13', 'O23', 'F23',$
       'O123', 'F123']
    calval.coincidence_index = indgen(14)
    calval.adc_coincidence_multiplier = [1, 1, 1, 1, 2, 2, 1, 1, 2, 2, 2, 2, 4, 4]
    calval.geometric_factor_coincidence_index = [0, 3, 1, 4, 0, 3, 2, 5, 0, 3, 1, 4, 0, 3]
    ; calval.geometric_factor_coincidence_index = [0, 3, 1, 4, 0, 3, 2, 5, 0, 3, 1, 4, 0, 3]

    ; TIDs / FTO IDs
    ; (Assume O is Telescope index 0, and F is Index 1)
    ; tid = [0, 1]
    
;    calval.telescope_id_map = reform(replicate_array([replicate(0, 48), replicate(1, 48)], 7), 672)
    ;i = indgen(48,14)
    
    calval.telescope_id_map = reform(byte((  indgen(48,14 ) / 48) mod 2), 672)

    fto_id = 1 + replicate(1,48) # indgen(7)
    calval.fto_logic_id_map =$
      [fto_id[*, 0], fto_id[*, 0], fto_id[*, 1], fto_id[*, 1], fto_id[*, 2],$
       fto_id[*, 2], fto_id[*, 3], fto_id[*, 3], fto_id[*, 4], fto_id[*, 4],$
       fto_id[*, 5], fto_id[*, 5], fto_id[*, 6], fto_id[*, 6]]

    ; Dictionary mapping coincidence type to positional index in the data array:
    calval.coincidence_map = dictionary()
    for i=0, 13 do calval.coincidence_map[calval.coincidence[i]] = i

    ; efficiency:
    ; scaling factor of the geometric factor.
    ; 0 for the lowest energy channel, 1 elsewhere:
    efficiency = replicate(1,48,14)  ; 48 x 14 array
    ; efficiency[0, *] = 0
    calval.efficiency = efficiency

    ; temperature coefficient:
    ; true energy = energy_coefficient + (T_difference) 
    calval.temperature_coefficient = 0.001 + fltarr(6)

    ; Deadtime:
    ; calval.deadtime_s = 1e-6
    calval.deadtime_s = 5e-6

    ; Criteria for deadtime correction:
    ; This accepts the big pixel if the deadtime correction below 1.2
    ; and de-emphasizes it as deadtime correction exceeds 1.8.
    calval.deadtime_correction_criteria = [1.2, 1.8]

    ; Criteria for Poisson statistics:
    ; This accepts the small pixel if the # counts above
    ; 100, only uses the big pixel if the # counts below/equal
    ; 1, weights by sqrt(N) between:
    calval.poisson_statistics_criteria = [1e2, 1e4]
    ; calval.poisson_statistics_criteria = [0, 1e4]
    calval.poisson_statistics_power_coefficient = 0.5

    ; Defunct: presumably unused information, left commented out here:
    ; names_fto = strsplit('1 2 12 3 13 23 123',/extract)
    ; names_fto = reform( transpose( [['O-'+names_fto],['F-'+names_fto]]))
    ; calval.detector_index = [0, 1]
    ; dim = [3,2]
    ; det2fto = [0, 1, 2, 1, 3,  1, 3, 1   ]
    ; det2fto = [1, 2, 1, 3,  1, 3, 1   ]
    ; fto2detmap  = [ [1,4], [2,5],  [1,4],  [3,6],  [3,6], [3,6], [3,6]] 
    ; s = 1/ reform(det_adc_scales,dim)
    ; nrg_scales = fltarr(2,7)
    ; for i=0,1 do  $
    ;   nrg_scales[i,*] = [ s[0,i]  , s[1,i] , average( s[[0,1],i] )  , s[2,i], average( s[[2,0],i] ),  average( s[[2,1],i] ), average( s[[0,1,2],i] )  ]
    ; calval.names_fto        = names_fto
    ; calval.adc_scales  = reform( det_adc_scales ,dim)
    ; calval.nrg_scales  = nrg_scales

    ; calval.adc_sigmas   = reform( [5.02   ,14.42  , 9.65  ,5.695,  13.88, 8.37 ]  ,dim)
    calval.adc_sigmas   = [5.02   ,14.42  , 9.65  ,5.695,  13.88, 8.37 ]
    calval.nrg_sigmas   = calval.adc_sigmas  * detector_keV_per_adc
    calval.nrg_thresholds  = calval.nrg_sigmas * 5

    ; For quality flag determination:
    calval.noise_sigma_threshold = [0.84, 1.4, 1.05, 0.84, 1.4, 1.05]
    calval.count_rate_threshold = [10e3, 10e3, 10e3, 10e3, 10e3, 10e3]
    calval.reaction_wheel_speed_threshold = [2000, 2000, 2000, 2000]
    calval.dap_temperature_range = [-35., 50.]
    calval.sensor_1_temperature_range = [-50., 45.]
    calval.sensor_2_temperature_range = [-50., 45.]
    calval.maximum_swfo_sun_offpointing_angle = 5.
    calval.minimum_stis_sun_angle = 40.
    ; STIS requirement that center of field-of-view is
    ; 50 deg. in the ecliptic off sun-earth line in "ahead" direction
    ; in spacecraft reference frame, unit vector for the FOV is (0.643, 0, 0.766)
    ; calval.stis_boresight_unit_vector = [cos(50. * !dtor), 0, sin(50. * !dtor)]
    calval.stis_boresight_sc_unit_vector = [0.643, 0, 0.766]
    calval.expected_pixel_ratio = [1e-3, 0.03]

    ; Qflag indices:
    calval.pulser_on_qflag_index = indgen(6) + 1
    calval.high_noise_sigma_qflag_index = indgen(6) + 7
    calval.any_detector_disabled_qflag_index = 13
    calval.decimation_qflag_index = indgen(4) + 14
    calval.high_rate_qflag_index = indgen(6) + 18
    calval.extreme_temperature_qflag_index = 24
    calval.nonstandard_config_qflag_index = 25
    calval.bad_ion_pixel_merge_qflag_index = [26, 27]
    calval.bad_elec_pixel_merge_qflag_index = [28, 29]
    calval.elec_contam_qflag_index = 30
    calval.high_reaction_wheel_speed_qflag_index = indgen(4) + 32
    calval.bad_iru_qflag_index = 38
    calval.swfo_offpointing_qflag_index = 39
    calval.sun_in_stis_fov_qflag_index = 40

    qflag_labels = strarr(64)
    qflag_labels[0] = "Playback"
    qflag_labels[calval.pulser_on_qflag_index] = ['P1 Enabled', 'P2 Enabled', 'P3 Enabled', 'P4 Enabled', 'P5 Enabled', 'P6 Enabled']
    qflag_labels[calval.high_noise_sigma_qflag_index] = ['1: High Nse Sigma', '2: High Nse Sigma', '3: High Nse Sigma', $
                                                         '4: High Nse Sigma', '5: High Nse Sigma', '6: High Nse Sigma']
    qflag_labels[calval.any_detector_disabled_qflag_index] = 'Disabled detectors'
    qflag_labels[calval.decimation_qflag_index] =  ['2: Dec On', '3: Dec on', '5: Dec on', '6: Dec on']
    qflag_labels[calval.high_rate_qflag_index] = ['1: Rate > Thr.', '2: Rate > Thr.', '3: Rate > Thr.', '4: Rate > Thr.', '5: Rate > Thr.', '6: Rate > Thr.']
    qflag_labels[calval.extreme_temperature_qflag_index] = 'T > Tlim'
    qflag_labels[calval.nonstandard_config_qflag_index] = 'Nonstand. config'
    qflag_labels[calval.bad_ion_pixel_merge_qflag_index] = ['Sus i+ merge: 100x O1 > O3', 'Sus i+ merge: 100x O1 < O3']
    qflag_labels[calval.bad_elec_pixel_merge_qflag_index] = ['Sus e- merge: 100x F1 > F3', 'Sus e- merge: 100x F1 < F3']
    qflag_labels[calval.elec_contam_qflag_index] = 'E- Contam'
    qflag_labels[calval.high_reaction_wheel_speed_qflag_index] = ['RxWh 1', 'RxWh 2', 'RxWh 3', 'RxWh 4']
    qflag_labels[calval.bad_iru_qflag_index] = 'any IRU invalid'
    qflag_labels[calval.swfo_offpointing_qflag_index] = 's/c offpointing'
    qflag_labels[calval.sun_in_stis_fov_qflag_index] = 'Sun in FOV'
    calval.qflag_labels = qflag_labels

    ; nonlut ADC corresponds to clog_17_6 (compressed log)
    calval.nonlut_adc_min  =$
      [   0,    1,    2,    3,$
          4,    5,    6,    7,$
          8,   10,   12,   14,$
         16,   20,   24,   28,$
         32,   40,   48,   56,$
         64,   80,   96,  112,$
        128,  160,  192,  224,$
        256,  320,  384,  448,$
        512,  640,  768,  896,$
       1024, 1280, 1536, 1792,$
       2048, 2560, 3072, 3584,$
       4096, 5120, 6144, 7168,$
       2L^13    ]

;    cal_functions = orderedhash()
    calval.nrglost_vs_nrgmeas = orderedhash()
    
    ; Geant simulation results for deadlayer / energy loss:
    ; Protons in O:
    EINC    = [3.5572231, 9.5011850, 19.054607, 51.946412, 170.25940, 581.35906, 1791.9807, 6245.3324]
    ELOST   = [0.75692672, 5.0485519, 11.489006, 15.762845, 12.833813, 7.9859661, 3.8584909, 1.1063090]
    Emeas    = [1.3318166, 8.2329514, 26.984297, 67.781489, 196.48678, 1214.6312, 5194.6412, 69894.733]
    ELOST   = [3.8584909, 9.8085852, 13.671814, 14.796677, 11.672128, 4.9693458, 1.4024602, 0.23119755]

    calval.modeled_proton_energy_loss_in_O = ELOST
    calval.modeled_proton_energy_measured_in_O = Emeas
    ; calval.nrglost_vs_nrgmeas['Proton-O'] = spline_fit3(!null,emeas,elost,/xlog,/ylog)

    ; Protons in F:
    Emeas    = [2.4111388, 21.544347, 94.044485, 419.00791, 5873.3907, 44554.225]
    ELOST = [266.69694, 255.38404, 234.17752, 151.81073, 26.237311, 5.8814151]
    ; calval.nrglost_vs_nrgmeas['Proton-F'] =  spline_fit3(!null,emeas,ELOST,/xlog,/ylog)
    calval.modeled_proton_energy_loss_in_F = ELOST
    calval.modeled_proton_energy_measured_in_F = Emeas

    ; Electrons in F:
    NRGMEAS = [1.3048349, 4.4554224, 19.448624, 138.74656, 427.67229]
    NRGLOST = [19.218670, 12.035385, 4.2277243, 0.74616804, 0.13914896]
    ; calval.nrglost_vs_nrgmeas['Electron-F'] =  spline_fit3(!null,NRGMEAS,NRGLOST,/xlog,/ylog)
    
    calval.modeled_electron_energy_loss_in_F = NRGLOST
    calval.modeled_electron_energy_measured_in_F = NRGMEAS

    ; This bit indicates whether to use the cubic spline for determining
    ; particle energy (1) or a fixed dead layer offset (0).
    calval.energy_response_function = 1

    calval.proton_O_dead_layer  = 12.  ;  keV
    calval.proton_F_dead_layer  = 300.  ; kev
    calval.electron_F_dead_layer = 10.  ; keV
    

    ; For l1b flag:
    ; Need a lot of parameters to determine the electron
    ; contamination flag:
    ; calval.electron_contam_factor = 0.5
    calval.contam_min_ion_count_rate = 1
    calval.contam_min_ion_energy = 100
    calval.contam_min_electron_count_rate = 10
    calval.contam_min_electron_energy = 100
    calval.contam_min_ion_ratio_energy = 100
    calval.contam_min_ion_ratio = 0.25
    calval.contam_ion_energy_range = [50, 1000]
    calval.contam_ion_max_deviation_power_law = 0.1


    ; For L2:
    calval.epam_ion_edge_energies = [47., 68., 115., 195., 315., 583., 1060., 1900., 4800.]
    calval.epam_electron_edge_energies = [45., 62., 102., 175., 315.]

    calval.responses = orderedhash()
    calval.rev_date = '$Id: swfo_stis_inst_response_calval.pro 33771 2025-10-19 01:55:35Z rjolitz $'
    swfo_stis_inst_response_calval_dict  = calval
    dprint,'Using Revision: '+calval.rev_date
  endif

  if keyword_set(save) then begin

    relabel = dictionary()
    relabel['nonlut_ADC_bins'] = 'nonlut_adc_min'
    relabel['energy_to_ADC_calibration'] = 'detector_keV_per_adc'
    relabel['dead_time'] = 'deadtime_s'
    relabel['dead_time_correction_criteria'] = 'deadtime_correction_criteria'
    relabel['electron_contamination_factor'] = 'electron_contam_factor'

    relabel['channel_names'] = 'channels'
    relabel['detector_names'] = 'detectors'
    relabel['coincidence_names'] = 'coincidence'

    if not file_test(save) then print, "Cannot save calval to '" + save + "', netcdf file does not exist."

    ; Get the Netcdf variable names:
    ncdf_list, save, vname=ncdf_fields, /var, /quiet
    print, ncdf_fields

    ; Open for writing:
    fid = ncdf_open(save, /write)

    ; First, identify the calvals that are neither in the netcdf nor the relabeled
    ; categories:
    relabel_vals = strlowcase((relabel.values()).toarray())
    calval_fields = strlowcase(calval.keys())
    calvals_not_in_ncdf = []
    foreach calval_varname, calval_fields do begin
      calval_index = where(strlowcase(ncdf_fields) eq calval_varname, nc)

      ; if the field is not found in NCDF fields, check if the calval name
      ; is in the relabeled array:
      if nc eq 0 then relabel_index = where(relabel_vals eq calval_varname, nc)

      ; if still no equivs, add to array:
      if nc eq 0 then calvals_not_in_ncdf = [calvals_not_in_ncdf, calval_varname]
    endforeach

    ; Next, iterate through the Netcdf columns and get the calval
    ; if present in the structure:
    skipped_fields = []
    written_fields = []
    foreach ncdf_varname_i, ncdf_fields do begin

      ; First, see if it is differently labeled in calvals
      ; vs the CDL
      relabel_inq = relabel.haskey(ncdf_varname_i)

      ; Get the name in calval for it, otherwise assume
      ; the calval name is same as ncdf:
      if relabel_inq then calval_varname_i = relabel[ncdf_varname_i] else calval_varname_i = ncdf_varname_i

      ; See if calval exists for ncdf_varname
      ; (since some are currently not included, e.g. EPAM_ELECTRON_EDGE_ENERGIES)
      calval_inq = calval.haskey(calval_varname_i)

      ; If in calval, write, otherwise skip:
      if calval_inq then begin
        ; If in there, put into the netcdf:
        calval_i = calval[calval_varname_i]
        ; stop
        ncdf_varput, fid, ncdf_varname_i, calval_i
        written_fields = [written_fields, ncdf_varname_i]
      endif else begin
        skipped_fields = [skipped_fields, ncdf_varname_i]

      endelse
    endforeach
    print, 'Fields written to NetCDF:'
    print, written_fields
    print, 'Fields in NetCDF not written since not in CALVAL: '
    print, skipped_fields
    print, 'FIELDS in CALVAL not in NetCDF: '
    print, calvals_not_in_ncdf

    ncdf_close, fid


  endif

  return, calval
end




