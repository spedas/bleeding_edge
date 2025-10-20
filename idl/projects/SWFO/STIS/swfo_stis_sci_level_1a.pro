;+
;FUNCTION:  SWFO_STIS_SCI_LEVEL_1A
;PURPOSE: Creates an array of structures,
; where each structure has fields corresponding
; to the Level 1a data product for SWFO STIS, using
; the array of Level 0b structures produced
; by SWFO_STIS_SCI_LEVEL_0b.pro or read from
; a Level 0b netcdf via swfo_ncdf_read.
;
; This data product sorts the science counts into
; each detector and sensor (O1-O3, F1-F3),
; retrieves the energy bins and bin widths
; (which can vary depending on commanding,
;  see SWFO_STIS_ADC_MAP),
; scales counts if the decimation flag is enabled,
; determines the noise histogram, std dev (sigma),
; and center (baseline),
; and assigns quality flags for instrument
; and spacecraft conditions that can affect the
; observation.
;
; Example call:
;  > l1a =   swfo_stis_sci_level_1a(l0b)
;
; Cribsheets that demonstrate Level 1a loading:
; - swfo_stis_sci_qflag_crib.pro: quality flag demo
;
; $LastChangedBy: rjolitz $
; $LastChangedDate: 2025-10-17 13:37:17 -0700 (Fri, 17 Oct 2025) $
; $LastChangedRevision: 33770 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_sci_level_1a.pro $


function swfo_stis_sci_level_1a,l0b_structs , verbose=verbose, cal=cal
  ;,format=format,reset=reset
  output = !null
  nd = n_elements(l0b_structs)

  nan48=replicate(!values.f_nan,48)

  ; ; for NOAA files, the detectorbits will be 3 x N_samples:
  ; check_detector_bit = where(size(l0b_structs[0].detector_bits, /dim) eq 3, n)
  ; l0b_from_noaa = (n eq 1)
  ; SSL calculates noise histogram in l0b, NOAA only has raw noise counts.

  ; Get the tag names from Level 0b to see if
  ; tags already inside:
  tags = tag_names(l0b_structs)

  ; NOAA files do not determine the noise histogram in level 0b,
  ; only the raw counts. Need to calculate the noise histogram
  index = (where("NSE_HISTOGRAM" eq tags,nse_hist_not_in_l0b))[0]

  ; Old code to evaluate noise histogram, want to eval packet-by-packet
  ; instead:
  ; if nse_hist_not_in_l0b eq 0 then begin
  ;   nse_counts = l0b_structs.nse_counts
  ;   nse_histogram = fltarr(60, nd)
  ;   nse_histogram[*, 1:-1] = nse_counts[*, 1:-1] - nse_counts[*, 0:-2]
  ; endif else nse_histogram = l0b_structs.nse_histogram

  ; Files starting with E2E testing include spacecraft data,
  ; so can include s/c flags:
  index = (where("REACTION_WHEEL_SPEED_RPM" eq tags,sc_info_present))[0]

  ; Get the cal values if not defined:
  if ~isa(cal,'dictionary') then cal = swfo_stis_inst_response_calval()
  ; cal.rate_threshold /= 10  ; comment out, after testing

  ;L1a = {swfo_stis_L1a,  $
  L1a = {  $
    time:0d, $
    time_unix: 0d, $
    time_MET:  0d, $
    time_GR:  0d, $
    ; hash:   0UL, $
    ; noise columns:
    noise_res: 0b, $
    noise_period: 0., $
    noise_histogram: replicate(0.,60),  $
    noise_total: replicate(0.,6),  $
    noise_baseline: replicate(!values.f_nan,6),  $
    noise_sigma: replicate(!values.f_nan,6),  $
    sci_duration: 0u , $
    sci_nbins:   0u,  $
 ;   sci_counts : replicate(!values.f_nan,672),  $    ; remove to increase performance
    ;    sci_adc    : replicate(!values.f_nan,672),  $
    ;    sci_dadc    : replicate(!values.f_nan,672),  $
    total14:  fltarr(14) , $
    total6:   fltarr(6) , $
    rate6:   fltarr(6) , $
    rate14:  fltarr(14) , $
    geom_O1: nan48, rate_O1: nan48, SPEC_O1: nan48, spec_O1_nrg: nan48, spec_O1_dnrg: nan48, spec_O1_adc:  nan48, spec_O1_dadc:  nan48, $
    geom_O2: nan48, rate_O2: nan48, SPEC_O2: nan48, spec_O2_nrg: nan48, spec_O2_dnrg: nan48, spec_O2_adc:  nan48, spec_O2_dadc:  nan48, $
    geom_O3: nan48, rate_O3: nan48, SPEC_O3: nan48, spec_O3_nrg: nan48, spec_O3_dnrg: nan48, spec_O3_adc:  nan48, spec_O3_dadc:  nan48, $
    geom_O12: nan48, rate_O12: nan48, SPEC_O12: nan48, spec_O12_nrg: nan48, spec_O12_dnrg: nan48, spec_O12_adc:  nan48, spec_O12_dadc:  nan48, $
    geom_O13: nan48, rate_O13: nan48, SPEC_O13: nan48, spec_O13_nrg: nan48, spec_O13_dnrg: nan48, spec_O13_adc:  nan48, spec_O13_dadc:  nan48, $
    geom_O23: nan48, rate_O23: nan48, SPEC_O23: nan48, spec_O23_nrg: nan48, spec_O23_dnrg: nan48, spec_O23_adc:  nan48, spec_O23_dadc:  nan48, $
    geom_O123: nan48, rate_O123: nan48, SPEC_O123: nan48, spec_O123_nrg: nan48, spec_O123_dnrg: nan48, spec_O123_adc:  nan48, spec_O123_dadc:  nan48, $
    geom_F1: nan48, rate_F1: nan48, SPEC_F1: nan48, spec_F1_nrg: nan48, spec_F1_dnrg: nan48, spec_F1_adc:  nan48, spec_F1_dadc:  nan48, $
    geom_F2: nan48, rate_F2: nan48, SPEC_F2: nan48, spec_F2_nrg: nan48, spec_F2_dnrg: nan48, spec_F2_adc:  nan48, spec_F2_dadc:  nan48, $
    geom_F3: nan48, rate_F3: nan48, SPEC_F3: nan48, spec_F3_nrg: nan48, spec_F3_dnrg: nan48, spec_F3_adc:  nan48, spec_F3_dadc:  nan48, $
    geom_F12: nan48, rate_F12: nan48, SPEC_F12: nan48, spec_F12_nrg: nan48, spec_F12_dnrg: nan48, spec_F12_adc:  nan48, spec_F12_dadc:  nan48, $
    geom_F13: nan48, rate_F13: nan48, SPEC_F13: nan48, spec_F13_nrg: nan48, spec_F13_dnrg: nan48, spec_F13_adc:  nan48, spec_F13_dadc:  nan48, $
    geom_F23: nan48, rate_F23: nan48, SPEC_F23: nan48, spec_F23_nrg: nan48, spec_F23_dnrg: nan48, spec_F23_adc:  nan48, spec_F23_dadc:  nan48, $
    geom_F123: nan48, rate_F123: nan48, SPEC_F123: nan48, spec_F123_nrg: nan48, spec_F123_dnrg: nan48, spec_F123_adc:  nan48, spec_F123_dadc:  nan48, $
    fpga_rev: 0b, $
    model_sun_sc_angle_deg: !values.f_nan, $
    measured_sun_sc_angle_deg: !values.f_nan, $
    modeled_spacecraft_sun_vxyz_sc: replicate(!values.f_nan,3), $
    sun_stis_angle_deg: !values.f_nan, $
    quality_bits: 0ULl, $
    sci_resolution: 0b, $
    sci_translate: 0u, $
    gap:0}


  ; Old: struct assign
  L1a_strcts = replicate(L1a, nd )
 ; struct_assign , l0b_structs,  l1a_strcts, /nozero, verbose = verbose

 ; L1a_strcts = replicate({swfo_stis_l1a}, nd )   using a named structure prevents everything from being backward compatible
  struct_assign , l0b_structs,  l1a_strcts, /nozero, verbose = verbose

  L1a_strcts.time = l0b_structs.time_unix

  ; See if duration in the file, relabel to sci_duration:
  index = (where("DURATION" eq tags,duration_present))[0]
  if duration_present then L1a_strcts.sci_duration = l0b_structs.duration

  ; Indices of each coincidence,
  ; first for ions (O detector)
  ; and next for electrons (F detector)
  index_O123 = cal.coincidence_map.O123
  index_O23 = cal.coincidence_map.O23
  index_O13 = cal.coincidence_map.O13
  index_O12 = cal.coincidence_map.O12
  index_O3 = cal.coincidence_map.O3
  index_O2 = cal.coincidence_map.O2
  index_O1 = cal.coincidence_map.O1
  index_F123 = cal.coincidence_map.F123
  index_F23 = cal.coincidence_map.F23
  index_F13 = cal.coincidence_map.F13
  index_F12 = cal.coincidence_map.F12
  index_F3 = cal.coincidence_map.F3
  index_F2 = cal.coincidence_map.F2
  index_F1 = cal.coincidence_map.F1

    ; print, nd

  for i=0l,nd-1 do begin
    l0b = l0b_structs[i]
    L1a = L1a_strcts[i]

    mapd = swfo_stis_adc_map(data_sample=l0b)  
    nrg = mapd.nrg
    dnrg = mapd.dnrg
    adc = mapd.adc
    dadc = mapd.dadc
    geom = mapd.geom

    d = l0b.sci_counts
    d = reform(d,48,14)

    ; Moved from swfo_stis_sci_apdat__define
    ; when decimation active (e.g. high count rates)
    ; drops in sensitivity to allow resolution of higher fluxes
    dec = l0b.decimation_factor_bits
    ; berkeley version: decimation_Factor is read out 
    ; as bytes with an order '6532' for Channels 6,5,3,2.
    if n_elements(dec) ne 4 then dec = [dec, ishft(dec,-2),ishft(dec,-4),ishft(dec,-6)] and 3 else dec = dec and 3

    if total(/preserve,dec) gt 0 then begin
      dec6 = [0, dec[0], dec[1],0, dec[2]  , dec[3] ]
      ; Ion fill in:
      ; Channels 2, 3, 5, and 6
      scale6 = 2. ^ dec6
      ;                      1     2    3      4     5      6      7
      ;                     C1    C2   C12    C3    C13    C23   C123
      scale14 = scale6[  [ 0,3,  1,4,  1,4,   2,5,   2,5,   2,5,   2,5    ]                       ]   ; Note :  still need to work on coincident decimation
      dprint,dlevel=3,'Decimation is on! ',scale6
      dprint,dlevel=3, scale14
      for ch = 0,13 do begin
        d[*,ch]  *= scale14[ch]
      endfor
    endif

    ; Noise value determination (copied from swfo_stis_nse_apdat::handler2,
    ; swfo_stis_nse_level_1)
    ; nse_level_1_str = swfo_stis_nse_level_1(l0b, /from_l0b)

    noise_bits = l0b.nse_noise_bits
    if n_elements(noise_bits) eq 3 then begin
      noise_enable = noise_bits[0]
      noise_res = noise_bits[1]
      noise_period = noise_bits[2]
    endif else begin
      noise_enable = ishft(noise_bits, -11)
      noise_res = ishft(noise_bits,-8) and 7u
      noise_period = noise_bits and 255u
    endelse

    ; Determine the ADC values for each noise count
    ; bin, which is scaled by 2^N where N is the noise
    ; resolution as read from the header:
    noise_scale = 2.^(fix(noise_res) - 3)
    noise_adc_bins = (findgen(10)-4.5) * noise_scale

    ; New code 8/2/25: This will be eval'ed element by element,
    ; rather than assuming all data:
    if nse_hist_not_in_l0b eq 0 then begin
      ; if no packets for a while or no last nse counts, define:
      if n_elements(last_nse_counts) eq 0 || (abs(l0b.time_unix-last_time_unix) gt 300) then begin
         last_nse_counts = l0b.nse_counts
         last_time_unix = l0b.time_unix
      endif
      ; Need to convert to float:
      nse_histogram_i = float(l0b.nse_counts - last_nse_counts)
      ; log for the next iteration:
      last_nse_counts = l0b.nse_counts
    endif else begin
      ; if present, use the noise histogram
      ; nse_histogram_i = nse_histogram[*, i]
      nse_histogram_i = l0b.nse_histogram
    endelse

    ; Flatten into 60-element array for storage into l1a:
    ; l1a.noise_histogram = reform(nse_histogram[*, *, i], 60)
    l1a.noise_histogram = nse_histogram_i

    ; Rescale into 10 (n_noise_channels) x 6 (n_detectors)
    nse_histogram_i = reform(nse_histogram_i, 10, 6)

    noise_stats = replicate(swfo_stis_nse_find_peak(),6)
    for j=0,5 do begin
      ; IMPORTANT: ignore end channel! susceptible to overflow:
      ; noise_stats[j] = swfo_stis_nse_find_peak(nse_histogram[0:8, j, i],noise_adc_bins[0:8])
      noise_stats[j] = swfo_stis_nse_find_peak(nse_histogram_i[0:9, j],noise_adc_bins[0:9])
    endfor
    ; stop

    ; Store noise info into l1a:
    l1a.noise_res = noise_res
    l1a.noise_period = noise_period
    l1a.noise_total = noise_stats.a
    l1a.noise_baseline = noise_stats.x0
    l1a.noise_sigma = noise_stats.s

    ; also move over sci_translate and resolution, since
    ; defines the energy values that the bins correspond to:
    l1a.sci_translate = l0b.sci_translate
    l1a.sci_resolution = l0b.sci_resolution

    ; get the total counts per coincidence and detector:
    total14=total(d,1)
    total6 = fltarr(6)
    foreach tid,[0,1] do begin
      total6[0+tid*3]=total14[0+tid]+total14[4+tid]+total14[ 8+tid]+total14[12+tid]
      total6[1+tid*3]=total14[2+tid]+total14[4+tid]+total14[10+tid]+total14[12+tid]
      total6[2+tid*3]=total14[6+tid]+total14[8+tid]+total14[10+tid]+total14[12+tid]
    endforeach
    L1a.total14 = total14
    l1a.total6  = total6

    ; Get the duration of counts to calculate rate:
    duration = l0b.duration
    rate = d / duration  ; count rate (#/s)
    flux = rate / geom / dnrg ; flux (#/s/cm2/eV)

    ; Quality flag is a 64 bit word.
    ; The first element is the playback, but that is not
    ; stored in the l0b (currently encoded in the filename).
    ; UPDATE 2025/10/6: Since playback encoded in level 0b,
    ; reference that
    ; So for now, set the keyword:
    ; q = ulong64(keyword_set(pb))
    ; q = 0LL
    q = l0b.quality_bits

    ; Qflag: Bits at positional index 1-6 are 0 or 1
    ; for each channel (Ch 1-6). Set bit if any pulser on:
    pulser_bits = l0b.pulser_bits
    if n_elements(pulser_bits) eq 3 then pulsers = pulser_bits[2] else pulsers = pulser_bits
    ; pulser_flag = (pulsers and 0x3full)
    ; q = q OR ishft(pulser_flag*1ull, cal.pulser_on_qflag_index[0])

    ; new code, triggers if pulsers enabled AND pulser bit set:
    pulser_enabled = (pulsers and 64ull) ne 0
    q = q OR ishft(pulser_enabled and (pulsers and 1ull) ne 0, cal.pulser_on_qflag_index[0])
    q = q OR ishft(pulser_enabled and (pulsers and 2ull) ne 0, cal.pulser_on_qflag_index[1])
    q = q OR ishft(pulser_enabled and (pulsers and 4ull) ne 0, cal.pulser_on_qflag_index[2])
    q = q OR ishft(pulser_enabled and (pulsers and 8ull) ne 0, cal.pulser_on_qflag_index[3])
    q = q OR ishft(pulser_enabled and (pulsers and 16ull) ne 0, cal.pulser_on_qflag_index[4])
    q = q OR ishft(pulser_enabled and (pulsers and 32ull) ne 0, cal.pulser_on_qflag_index[5])
    ; if q ne 0 then stop

    ; Bits at positional index 7-12 are 0 or 1 if high noise
    ; and defined for Ch 1-6.
    nse_flag = l1a.noise_sigma gt cal.noise_sigma_threshold
    ; q = q or ishft(nse_flag.frombits()*1ull, 7)
    q = q or ishft(nse_flag[0]*1ull, cal.high_noise_sigma_qflag_index[0])
    q = q or ishft(nse_flag[1]*1ull, cal.high_noise_sigma_qflag_index[1])
    q = q or ishft(nse_flag[2]*1ull, cal.high_noise_sigma_qflag_index[2])
    q = q or ishft(nse_flag[3]*1ull, cal.high_noise_sigma_qflag_index[3])
    q = q or ishft(nse_flag[4]*1ull, cal.high_noise_sigma_qflag_index[4])
    q = q or ishft(nse_flag[5]*1ull, cal.high_noise_sigma_qflag_index[5])
    ; if q ne 0 then stop

    ; Bit at positional index 13 is 1 if any detector disabled else 0
    detector_bits = l0b.detector_bits
    if n_elements(detector_bits) eq 3 then detectors_enabled = detector_bits[2] else detectors_enabled = detector_bits
    det_flag = (not detectors_enabled and 0x3fub) ne 0
    q = q or ishft(det_flag*1ull, cal.any_detector_disabled_qflag_index)
    ; if det_flag ne 0 then stop

    ; Bits at positional index 14-17 are 1 if decimation factor
    ; active (whether by 2x or 4x) on Ch 1,2,4,5
    ; In NOAA file, decimation bits are separated into 4 columns:
    ; Assume the decimation bits are ordered as: 6,5,3,2
    dec_flag = dec ne 0
    q = q or ishft(dec_flag[0]*1ull, cal.decimation_qflag_index[0])
    q = q or ishft(dec_flag[1]*1ull, cal.decimation_qflag_index[1])
    q = q or ishft(dec_flag[2]*1ull, cal.decimation_qflag_index[2])
    q = q or ishft(dec_flag[3]*1ull, cal.decimation_qflag_index[3])

    ; if dec_flag ne 0 then stop

    ; Q flag: bits at positional index 18-23 are set if
    ; the count rate exceeds the threshold in the cal table,
    ; for channels 1-6:
    rate6 = total6/duration
    l1a.rate6 = rate6
    l1a.rate14 = total14/duration
    rate_flag = rate6 gt cal.count_rate_threshold
    q = q or ishft(rate_flag[0]*1ull, cal.high_rate_qflag_index[0])
    q = q or ishft(rate_flag[1]*1ull, cal.high_rate_qflag_index[1])
    q = q or ishft(rate_flag[2]*1ull, cal.high_rate_qflag_index[2])
    q = q or ishft(rate_flag[3]*1ull, cal.high_rate_qflag_index[3])
    q = q or ishft(rate_flag[4]*1ull, cal.high_rate_qflag_index[4])
    q = q or ishft(rate_flag[5]*1ull, cal.high_rate_qflag_index[5])
    ; if total(rate_flag) ne 0 then stop

    ; Q flag: bit at positional index 24 set if temperature
    ; limit exceeded:
    temps = [l0b.temp_dap, l0b.temp_sensor1, l0b.temp_sensor2]
    temp_dap_flag = temps[0] lt cal.dap_temperature_range[0] or temps[0] gt cal.dap_temperature_range[1]
    temp_s1_flag = temps[1] lt cal.sensor_1_temperature_range[0] or temps[1] gt cal.sensor_1_temperature_range[1]
    temp_s2_flag = temps[2] lt cal.sensor_2_temperature_range[0] or temps[2] gt cal.sensor_2_temperature_range[1]
    temp_flag = (temp_s1_flag or temp_s2_flag) or temp_dap_flag
    q = q or ishft(temp_flag*1ull, cal.extreme_temperature_qflag_index)
    ; if temp_flag ne 0 then stop

    ; Q flag: bit at position index 25 set if nonstandard configuration,
    ; where standard config defined as:
    ; - sci_translate = 16
    ; - nonlut_mode (second bit of detector_bits) = 0 [AKA log bins]
    ; - use_lut mode = 0 [AKA no LUT used]
    ; - noise_enable = 1 (AKA noise measuring mode is active)
    ; - user_09 = 1 (AKA not doing CPT)
    ;   - CAVEAT: user_09 will be non-1 A LOT in the Xray
    ;     and ion gun tests.
    translate_flag = (l0b.sci_translate ne 16)
    if n_elements(detector_bits) eq 3 then nonlut_bits = detector_bits[1] else nonlut_bits = ishft(detector_bits, -6) and 1
    nonlut_flag = nonlut_bits ne 0
    ptcu_bits = l0b.ptcu_bits
    if n_elements(ptcu_bits) eq 4 then uselut_bit = ptcu_bits[3] else uselut_bit = ptcu_bits and 1
    uselut_flag = uselut_bit ne 0
    noise_enable_flag = noise_enable ne 1
    user_09_flag = l0b.user_09 ne 1
    nonstandard_flag = translate_flag or nonlut_flag or uselut_flag or noise_enable_flag or user_09_flag
    q = q or ishft(nonstandard_flag * 1ull, cal.nonstandard_config_qflag_index)
    ; if nonstandard_flag ne 0 then stop

    ; Q flag: bits at positional index 26-30 will be set in Level 1b.
    ; since 26-29 are for the the pixel merging and 30 is for electron contamination.

    ; Q flag: bit at position 31 unset, reserved for future use.

    ; Q flag: bits at positional index 32-35 set if reaction wheel
    ; speed for each reaction wheel are too high (known to cause noise)
    ; - Warning - APID does not exist for calibration datasets
    if sc_info_present ne 0 then begin
      reax_wheel_flag = abs(l0b.reaction_wheel_speed_rpm) gt cal.reaction_wheel_speed_threshold
      q = q or ishft(reax_wheel_flag[0]*1ull, cal.high_reaction_wheel_speed_qflag_index[0])
      q = q or ishft(reax_wheel_flag[1]*1ull, cal.high_reaction_wheel_speed_qflag_index[1])
      q = q or ishft(reax_wheel_flag[2]*1ull, cal.high_reaction_wheel_speed_qflag_index[2])
      q = q or ishft(reax_wheel_flag[3]*1ull, cal.high_reaction_wheel_speed_qflag_index[3])

      ; Q flag: bit at position 38 if any IRU invalid
      ; IRU order:
      ; - misalignment bypass - nominally 0
      ; - memory effect error - nominally 0
      ; - health (X, Y, Z) - nominally 1
      ; - valid (X, Y, Z) - nominally 1

      if n_elements(l0b.iru_bits) eq 3 then iru_bad = array_equal(l0b.iru_bits, [0, 0, 1, 1, 1, 1, 1, 1]) ne 1 $
        else iru_bad = l0b.iru_bits ne 63
      ; stop

      


      q = q or ishft(iru_bad*1ull, cal.bad_iru_qflag_index)

      ; Q flag: bit at position 39 if spacecraft off-pointing
      ; by +/- 5 deg:

      ; For testing, need to use measured sun vector
      ; since modeled sun vec wasn't modeled. Code below for
      ; modeled, since that is the proper sun truth.
      ; comment in after deploy:

      ; ADMSUNVX[Y,Z] / measured_sun_vector_xyz is the measured sun vector in SC coordinates
      ; this is the only vector simulated in MR3
      meas_sun_vec_sc = l0b.measured_sun_vector_xyz

      ; ; ADSCSUNVX[Y,Z] / modeled_spacecraft_sun_vxyz is the modeled sun vector is in ECI coordinates
      model_sun_vec_eci = l0b.modeled_spacecraft_sun_vxyz
      ; ; this is the quaternion that converts from EGI to s/c coordinates
      quaternion = l0b.body_frame_attitude_q1234
      ; ; Put the modeled sun vector into s/c body coordinates:
      model_sun_vec_sc = quaternion_rotation(model_sun_vec_eci, quaternion, last_index=1)
      l1a.modeled_spacecraft_sun_vxyz_sc = model_sun_vec_sc

      ; Angle between X_sc and sun:
      model_sun_sc_angle_deg = acos(model_sun_vec_sc[0]) / !dtor
      l1a.model_sun_sc_angle_deg = model_sun_sc_angle_deg

      measured_sun_sc_angle_deg = acos(meas_sun_vec_sc[0]) / !dtor
      l1a.measured_sun_sc_angle_deg = measured_sun_sc_angle_deg

      ; Angle is ~15 deg when Earth pointing, 0 deg sun pointing
      ; - set flag if earth pointing?  +/-5 deg
      ; 10/17/25: currently using the measured, since the rotation
      ;  into sc frame from ECI on the model_sun vector isn't returning
      ;  a sensible number.
      offpointing_flag = (measured_sun_sc_angle_deg gt cal.maximum_swfo_sun_offpointing_angle)

      q = q or ishft(offpointing_flag*1ull, cal.swfo_offpointing_qflag_index)

      ; Q flag: bit at position 40 if sun in STIS FOV
      ; Since STIS has a larger FOV of (80 x 60 deg acceptance)
      ; the sun can intrude if it has an angle within 40 deg of the boresight

      ; STIS requirement that center of field-of-view is
      ; 50 deg. in the ecliptic off sun-earth line in "ahead" direction
      ; in spacecraft reference frame, unit vector for the FOV is (0.643, 0, 0.766)
      stis_fov = cal.stis_boresight_sc_unit_vector

      ; Likewise, calculate angle between STIS FOV center and sun:
      sun_sc = meas_sun_vec_sc
      sun_stis_angle_deg = acos(stis_fov[0]*sun_sc[0] + stis_fov[2]*sun_sc[2]) / !dtor
      l1a.sun_stis_angle_deg = sun_stis_angle_deg

      ; Sun in STIS FOV flag: angle subtended by fov 60 x 80 deg, angle of
      ; sun relative to center of boresight between 30-40
      ; - set flag if under 40
      sun_in_stis_fov_flag = (sun_stis_angle_deg lt cal.minimum_stis_sun_angle)
      q = q or ishft(sun_in_stis_fov_flag*1ull, cal.sun_in_stis_fov_qflag_index)

    endif


    ; print, q.tobinary()
    l1a.quality_bits = q

    ; stop

    ; Now, store information for each coincidence-specific quantity:
    ; Fill in ion AKA O info
    l1a.geom_O1   = geom[*, index_O1]
    l1a.geom_O2   = geom[*, index_O2]
    l1a.geom_O12  = geom[*, index_O12]
    l1a.geom_O3   = geom[*, index_O3]
    l1a.geom_O13  = geom[*, index_O13]
    l1a.geom_O23  = geom[*, index_O23]
    l1a.geom_O123 = geom[*, index_O123]

    l1a.spec_O1   = flux[*, index_O1]
    l1a.spec_O2   = flux[*, index_O2]
    l1a.spec_O12  = flux[*, index_O12]
    l1a.spec_O3   = flux[*, index_O3]
    l1a.spec_O13  = flux[*, index_O13]
    l1a.spec_O23  = flux[*, index_O23]
    l1a.spec_O123 = flux[*, index_O123]

    l1a.rate_O1   = rate[*, index_O1]
    l1a.rate_O2   = rate[*, index_O2]
    l1a.rate_O12  = rate[*, index_O12]
    l1a.rate_O3   = rate[*, index_O3]
    l1a.rate_O13  = rate[*, index_O13]
    l1a.rate_O23  = rate[*, index_O23]
    l1a.rate_O123 = rate[*, index_O123]

    l1a.spec_O1_nrg   = nrg[*, index_O1]
    l1a.spec_O2_nrg   = nrg[*, index_O2]
    l1a.spec_O12_nrg  = nrg[*, index_O12]
    l1a.spec_O3_nrg   = nrg[*, index_O3]
    l1a.spec_O13_nrg  = nrg[*, index_O13]
    l1a.spec_O23_nrg  = nrg[*, index_O23]
    l1a.spec_O123_nrg = nrg[*, index_O123]

    l1a.spec_O1_dnrg   = dnrg[*, index_O1]
    l1a.spec_O2_dnrg   = dnrg[*, index_O2]
    l1a.spec_O12_dnrg  = dnrg[*, index_O12]
    l1a.spec_O3_dnrg   = dnrg[*, index_O3]
    l1a.spec_O13_dnrg  = dnrg[*, index_O13]
    l1a.spec_O23_dnrg  = dnrg[*, index_O23]
    l1a.spec_O123_dnrg = dnrg[*, index_O123]

    l1a.spec_O1_adc   = adc[*, index_O1]
    l1a.spec_O2_adc   = adc[*, index_O2]
    l1a.spec_O12_adc  = adc[*, index_O12]
    l1a.spec_O3_adc   = adc[*, index_O3]
    l1a.spec_O13_adc  = adc[*, index_O13]
    l1a.spec_O23_adc  = adc[*, index_O23]
    l1a.spec_O123_adc = adc[*, index_O123]

    l1a.spec_O1_dadc   = dadc[*, index_O1]
    l1a.spec_O2_dadc   = dadc[*, index_O2]
    l1a.spec_O12_dadc  = dadc[*, index_O12]
    l1a.spec_O3_dadc   = dadc[*, index_O3]
    l1a.spec_O13_dadc  = dadc[*, index_O13]
    l1a.spec_O23_dadc  = dadc[*, index_O23]
    l1a.spec_O123_dadc = dadc[*, index_O123]

    ; Fill in elec AKA F info
    l1a.geom_F1   = geom[*, index_F1]
    l1a.geom_F2   = geom[*, index_F2]
    l1a.geom_F12  = geom[*, index_F12]
    l1a.geom_F3   = geom[*, index_F3]
    l1a.geom_F13  = geom[*, index_F13]
    l1a.geom_F23  = geom[*, index_F23]
    l1a.geom_F123 = geom[*, index_F123]

    l1a.spec_F1   = flux[*, index_F1]
    l1a.spec_F2   = flux[*, index_F2]
    l1a.spec_F12  = flux[*, index_F12]
    l1a.spec_F3   = flux[*, index_F3]
    l1a.spec_F13  = flux[*, index_F13]
    l1a.spec_F23  = flux[*, index_F23]
    l1a.spec_F123 = flux[*, index_F123]

    l1a.rate_F1   = rate[*, index_F1]
    l1a.rate_F2   = rate[*, index_F2]
    l1a.rate_F12  = rate[*, index_F12]
    l1a.rate_F3   = rate[*, index_F3]
    l1a.rate_F13  = rate[*, index_F13]
    l1a.rate_F23  = rate[*, index_F23]
    l1a.rate_F123 = rate[*, index_F123]

    l1a.spec_F1_nrg   = nrg[*, index_F1]
    l1a.spec_F2_nrg   = nrg[*, index_F2]
    l1a.spec_F12_nrg  = nrg[*, index_F12]
    l1a.spec_F3_nrg   = nrg[*, index_F3]
    l1a.spec_F13_nrg  = nrg[*, index_F13]
    l1a.spec_F23_nrg  = nrg[*, index_F23]
    l1a.spec_F123_nrg = nrg[*, index_F123]

    l1a.spec_F1_dnrg   = dnrg[*, index_F1]
    l1a.spec_F2_dnrg   = dnrg[*, index_F2]
    l1a.spec_F12_dnrg  = dnrg[*, index_F12]
    l1a.spec_F3_dnrg   = dnrg[*, index_F3]
    l1a.spec_F13_dnrg  = dnrg[*, index_F13]
    l1a.spec_F23_dnrg  = dnrg[*, index_F23]
    l1a.spec_F123_dnrg = dnrg[*, index_F123]

    l1a.spec_F1_adc   = adc[*, index_F1]
    l1a.spec_F2_adc   = adc[*, index_F2]
    l1a.spec_F12_adc  = adc[*, index_F12]
    l1a.spec_F3_adc   = adc[*, index_F3]
    l1a.spec_F13_adc  = adc[*, index_F13]
    l1a.spec_F23_adc  = adc[*, index_F23]
    l1a.spec_F123_adc = adc[*, index_F123]

    l1a.spec_F1_dadc   = dadc[*, index_F1]
    l1a.spec_F2_dadc   = dadc[*, index_F2]
    l1a.spec_F12_dadc  = dadc[*, index_F12]
    l1a.spec_F3_dadc   = dadc[*, index_F3]
    l1a.spec_F13_dadc  = dadc[*, index_F13]
    l1a.spec_F23_dadc  = dadc[*, index_F23]
    l1a.spec_F123_dadc = dadc[*, index_F123]

    ; DEFUNCT: Below code is shorter and easier to read,
    ; but str_element is time-consuming and inappropriate
    ; for this high-throughput routine:

    ; out = {time:l0b.time}
    ; str_element,/add,out,'hash',mapd.codes.hashcode()
    ; str_element,/add,out,'sci_duration',l0b.sci_duration
    ; str_element,/add,out,'sci_nbins',l0b.sci_nbins
    ; str_element,/add,out,'gap',0
    ; foreach w,mapd.wh,key do begin
    ;   ;      str_element,/add,out,'cnts_'+key,counts[w]
    ;   ;      str_element,/add,out,'rate_'+key,counts[w]/ l0b.sci_duration

    ;   str_element,/add,out,'spec_'+key,flux[w]
    ;   str_element,/add,out,'spec_'+key+'_nrg',nrg[w]
    ;   str_element,/add,out,'spec_'+key+'_dnrg',dnrg[w]

    ;   ;    str_element,/add,out,'spec_'+key+'_adc',adc[w]
    ;   ;    str_element,/add,out,'spec_'+key+'_dadc',dadc[w]
    ; endforeach


    L1a_strcts[i] = l1a

    ;    if nd eq 1 then   return, out
    ;    if i  eq 0 then   output = replicate(out,nd) else output[i] = out

  endfor

  return,L1a_strcts

end

