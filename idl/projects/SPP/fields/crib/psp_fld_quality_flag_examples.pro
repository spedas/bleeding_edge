;+
;
; PROCEDURE:  PSP_FLD_QUALITY_FLAG_EXAMPLES
;
; PURPOSE:    Plot examples of FIELDS data with various quality flags active.
;
; KEYWORDS:
;
;   qf_type:  Specifies a quality flag. The routine will load and plot an
;             example of FIELDS data where that quality flag is active.
;
;             Options:  'BIAS_SWP', 'THRUSTER', 'SCM_CAL',
;                       'MAG_ROLL', 'MAG_CAL', 'SPC_EMODE',
;                       'SLS_CAL', 'OFF_UMBRA', 'OVERVIEW', 'ALL'
;
;             The 'qf_type' options correspond to the quality flags
;             included in the FIELDS Level 2 CDF files, with the
;             exception of the 'OVERVIEW' and 'ALL' type.
;             'OVERVIEW' plots an overview of all quality flags over
;             two example orbits, and 'ALL' plots all examples in
;             sequence.
;
;             If qf_type is set to 'BIAS_SWP' then two plots are created,
;             one showing a bias sweep from Encounter 1 and one from
;             Encounter 2. The difference between Encounter 1 sweeps
;             and those from subsequent Encounters is described below.
;
;  no_pause:  By default, the routine pauses after a plot is made, and
;             waits for a continue command at the IDL prompt. Setting
;             this keyword eliminates this pause.
;
; EXAMPLE:
;
;   IDL> psp_fld_quality_flag_examples, 'THRUSTER'
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2020-11-12 22:39:16 -0800 (Thu, 12 Nov 2020) $
; $LastChangedRevision: 29352 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/crib/psp_fld_quality_flag_examples.pro $
;
;-

pro psp_fld_quality_flag_examples, qf_type, $
  no_pause = no_pause

  if n_elements(no_pause) EQ 0 then pause = 1 else pause = 0

  if n_elements(qf_type) EQ 0 then begin

    print, ""
    print, "syntax: psp_fld_quality_flag_examples, qf_type"
    print, ""
    print, "See documentation in PSP_FLD_QUALITY_FLAG_EXAMPLES.PRO for details."
    print, ""

    return

  endif

  example_mag_roll    = 0
  example_mag_cal     = 0
  example_bias_sweep1 = 0
  example_bias_sweep2 = 0
  example_spc_emode   = 0
  example_sls_test    = 0
  example_thruster    = 0
  example_scm_cal     = 0
  example_off_umbra   = 0
  example_overall     = 0

  foreach type, qf_type do begin

    if type EQ 'ALL' or type EQ 'MAG_ROLL'  then example_mag_roll    = 1
    if type EQ 'ALL' or type EQ 'MAG_CAL'   then example_mag_cal     = 1
    if type EQ 'ALL' or type EQ 'BIAS_SWP' or type EQ 'BIAS_SWP1' then $
      example_bias_sweep1 = 1
    if type EQ 'ALL' or type EQ 'BIAS_SWP' or type EQ 'BIAS_SWP2' then $
      example_bias_sweep2 = 1
    if type EQ 'ALL' or type EQ 'SPC_EMODE' then example_spc_emode   = 1
    if type EQ 'ALL' or type EQ 'SLS_CAL'   then example_sls_test    = 1
    if type EQ 'ALL' or type EQ 'THRUSTER'  then example_thruster    = 1
    if type EQ 'ALL' or type EQ 'SCM_CAL'   then example_scm_cal     = 1
    if type EQ 'ALL' or type EQ 'OFF_UMBRA' then example_off_umbra   = 1
    if type EQ 'ALL' or type EQ 'OVERALL'   then example_overall     = 1

  endforeach

  if example_mag_roll or example_mag_cal then begin

    ;
    ; Magnetometer roll quality flag
    ; ------------------------------
    ;
    ; Several times each orbit, the PSP spacecraft rotates around the
    ; Sun-spacecraft axis. The primary purpose for these rotations is
    ; to characterize the magnetometer offsets, although several other
    ; PSP instruments use the rotations for calibrations.
    ;
    ; Typically, rotations are performed three times per orbit:
    ;   once prior to Encounter entry (0.25 au inbound)
    ;   once after Encounter exit (0.25 au outbound)
    ;   once near aphelion
    ;
    ; The pre- and post-Encounter rolls are performed with the spacecraft
    ; -Z axis aligned with the Sun-spacecraft line, as is the case during
    ; perihelion.
    ;
    ; The aphelion rotation attitude depends on solar distance--typically,
    ; during the first two years of the mission, the aphelion rotation was
    ; performed with the spacecraft -Z axis at an angle of 45 degrees from
    ; the Sun-spacecraft line.
    ;
    ; The rotations are planned and executed by the PSP guidance and control
    ; team. The rotations use the spacecraft reaction wheels, not the
    ; thrusters. Each rotation typically takes ~24 minutes.
    ;
    ; Following a rotation, the MAG instruments typically perform a MAG
    ; calibration sequence, which involves cycling several times through
    ; the ranges of the MAG instrument.
    ;
    ; In the FIELDS quality flag variable, a rotation is indicated by
    ; setting the MAG_ROLL flag to 1. The magnetometer calibration following
    ; the rotation is indicated by setting the MAG_CAL flag to 1.
    ;
    ; The example shown here is a rotation on 2018 December 17. The plot shows
    ; magnetometer data in both spacecraft and RTN coordinates. The rotation
    ; is apparent as a quasi-sinusoidal variation in the spacecraft coordinate
    ; data. In the RTN data, the effects of the rotation have been removed
    ; via the transformation from SC to RTN coordinates.
    ;
    ; Following the rotation, there is a MAG calibration. The steps in the
    ; waveform represent changes in the MAG range. Outside of these calibration
    ; times, the magnetometer range is chosen automatically--and for the
    ; first two years of the mission, the magnetometer has remained in the
    ; lowest amplitude range (range 0, +/-1024 nT).
    ;

    timespan, '2018-12-17', 2

    psp_fld_load, type = 'mag_SC_4_Sa_per_Cyc'
    psp_fld_load, type = 'mag_RTN_4_Sa_per_Cyc'

    if example_mag_roll then begin

      tplot_options, 'title', 'PSP/FIELDS MAG Roll + MAG Cal Quality Flag'

      tplot, ['psp_fld_l2_mag_*_4_Sa_per_Cyc', 'psp_fld_l2_quality_flags'], $
        trange = ['2018-12-17/00:00:00','2018-12-19/00:00:00']

      if pause then stop

    endif

    if example_mag_cal then begin

      tplot_options, 'title', 'PSP/FIELDS MAG Cal Quality Flag'

      tplot, ['psp_fld_l2_mag_*_4_Sa_per_Cyc', 'psp_fld_l2_quality_flags'], $
        trange = ['2018-12-18/12:00:00','2018-12-18/12:40:00']

      if pause then stop

    endif

  end

  if example_bias_sweep1 then begin

    ;
    ; Bias sweep flag
    ; ---------------
    ;
    ; The FIELDS electric field sensors are current biased. The bias current
    ; applied to the sensors brings the sensor potential close to the
    ; potential of the nearby plasma. This bias current places the antenna
    ; in an optimal position on the sensor Langmuir curve (minimum dV / dI)
    ; which minimizes the sensor response to density fluctuations. Minimizing
    ; this response minimizes the error in the electric field measurement.
    ;
    ; The electric field whip antennas are current biased in this manner. In
    ; addition, the stub and shield components of the antenna assemblies
    ; can be voltage biased, primarily for photo- and secondary electron
    ; control.
    ;
    ; Due to the changing plasma environment over the PSP orbit, the
    ; required bias currents and voltages must be adjusted (thus far, the
    ; primary adjustment has been to apply more bias current as the
    ; spacecraft approaches closer to the Sun, and the photoemission
    ; currents from the antennas grow.
    ;
    ; The optimum bias currents and voltages are determined by bias sweeps,
    ; which typically occur twice per day during the encounter phase of the
    ; orbit (solar distance < 0.25 au).
    ;
    ; More information on biasing the FIELDS antennas is available in:
    ; Bale et al. (2016), https://doi.org/10.1007/s11214-016-0244-5
    ;
    ; The bias sweep sequences during Encounter 1 included numerous sweeps
    ; of the whip bias current, with the shield and stub bias voltages
    ; set to different values for each whip current bias sweep.
    ; For all Encounters subsequent to Encounter 1, the bias sweep only varies
    ; the current applied to the whip, and the shield and stub bias voltages
    ; are held constant. Post-Encounter 1, the bias sweeps
    ; typically contain several phases:
    ;
    ;   - bias current of the V1 and V2 whips is swept at the same time
    ;   - bias current of the V3 and V4 whips is swept at the same time
    ;   - bias current of V5 is swept individually
    ;
    ; During the V1, V2 and V5 bias sweeps, the bias current on V3, V4 is zero.
    ; During the V3, V4 and V5 bias sweeps, the bias current on V1, V2 is zero.
    ;
    ; The FIELDS science team is preparing a new data product which will
    ; contain detailed information on the currents and voltages applied
    ; to each sensor during the bias sweeps.
    ;
    ; The plot below shows a typical bias sweep during Encounter 1. Bias
    ; sweeps are apparent in all electric field data products.
    ;

    timespan, '2018-11-06/12:00:00', 1./2

    psp_fld_load, type = 'rfs_lfr'
    psp_fld_load, type = 'dfb_wf_vdc'

    tplot_options, 'title', 'PSP/FIELDS Bias Sweep (Encounter 1) Quality Flag'

    options, 'psp_fld_l2_dfb_wf_V1dc', 'ytitle', 'DFB WF!CV1_DC'
    options, 'psp_fld_l2_dfb_wf_V3dc', 'ytitle', 'DFB WF!CV3_DC'
    options, 'psp_fld_l2_dfb_wf_V5dc', 'ytitle', 'DFB WF!CV5_DC'

    options, 'psp_fld_l2_rfs_lfr_auto_averages_ch?_V?V?', 'panel_size', 1.

    tplot, ['psp_fld_l2_rfs_lfr_auto_averages_ch0_V1V2',  $
      'psp_fld_l2_rfs_lfr_auto_averages_ch1_V3V4',  $
      'psp_fld_l2_dfb_wf_V1dc', $
      'psp_fld_l2_dfb_wf_V3dc', $
      'psp_fld_l2_dfb_wf_V5dc', $
      'psp_fld_l2_quality_flags'], $
      trange = ['2018-11-06/17:45:00','2018-11-06/18:30:00']

    if pause then stop

  endif

  if example_bias_sweep2 then begin

    ;
    ; The plot below shows a typical bias sweep post-Encounter 1.
    ;

    timespan, '2019-04-06'

    psp_fld_load, type = 'rfs_lfr'
    psp_fld_load, type = 'dfb_wf_vdc'

    options, 'psp_fld_l2_dfb_wf_V1dc', 'ytitle', 'DFB WF!CV1_DC'
    options, 'psp_fld_l2_dfb_wf_V3dc', 'ytitle', 'DFB WF!CV3_DC'
    options, 'psp_fld_l2_dfb_wf_V5dc', 'ytitle', 'DFB WF!CV5_DC'

    options, 'psp_fld_l2_rfs_lfr_auto_averages_ch?_V?V?', 'panel_size', 1.

    tplot_options, 'title', 'PSP/FIELDS Bias Sweep (Encounter 2) Quality Flag'

    tplot, ['psp_fld_l2_rfs_lfr_auto_averages_ch0_V1V2',  $
      'psp_fld_l2_rfs_lfr_auto_averages_ch1_V3V4',  $
      'psp_fld_l2_dfb_wf_V1dc', $
      'psp_fld_l2_dfb_wf_V3dc', $
      'psp_fld_l2_dfb_wf_V5dc', $
      'psp_fld_l2_quality_flags'], $
      trange = ['2019-04-06/23:00:00','2019-04-06/23:30:00']

    if pause then stop

  endif

  if example_spc_emode then begin

    ;
    ; Solar Probe Cup (SPC) Electron Mode quality flag
    ; ------------------------------------------------
    ;
    ; The PSP/SWEAP Faraday cup (SPC) instrument can operate in
    ; 'electron mode', a mode where the grid voltages on the cup are
    ; configured to collect and measure electron currents on the
    ; cup collector plates.
    ;
    ; Times when SPC is in electron mode are flagged in the FIELDS data,
    ; and shown in the 'psp_fld_l2_quality_flags' variable as
    ; SPC_EMODE = 1.
    ;
    ; Prior to launch, it was imagined that running the SPC in electron
    ; mode might generate distinguishable signals in some FIELDS data products,
    ; by creating a localized electric potential in the
    ; vicinity of the SPC that could be sensed by one or more FIELDS antennas.
    ;
    ; Through the first several PSP encounters, electron mode has been enabled
    ; only rarely, and there has been no apparent effect on any FIELDS
    ; data products. This may change as plasma conditions vary with
    ; radial distance, or if electron mode is enabled more frequently
    ; in future encounters.
    ;
    ; Detailed information on SPC operating modes is available in the
    ; instrument paper, Case et al. (2020), doi:10.3847/1538-4365/ab5a7b
    ;

    timespan, '2019-04-06'

    psp_fld_load, type = 'rfs_lfr'
    psp_fld_load, type = 'dfb_wf_vdc'

    options, 'psp_fld_l2_dfb_wf_V1dc', 'ytitle', 'DFB WF!CV1_DC'
    options, 'psp_fld_l2_dfb_wf_V3dc', 'ytitle', 'DFB WF!CV3_DC'
    options, 'psp_fld_l2_dfb_wf_V5dc', 'ytitle', 'DFB WF!CV5_DC'

    options, 'psp_fld_l2_rfs_lfr_auto_averages_ch?_V?V?', 'panel_size', 1.

    tplot_options, 'title', 'PSP/FIELDS SPC Electron Mode Quality Flag'

    tplot, ['psp_fld_l2_rfs_lfr_auto_averages_ch0_V1V2',  $
      'psp_fld_l2_rfs_lfr_auto_averages_ch1_V3V4',  $
      'psp_fld_l2_dfb_wf_V1dc', $
      'psp_fld_l2_dfb_wf_V3dc', $
      'psp_fld_l2_dfb_wf_V5dc', $
      'psp_fld_l2_quality_flags'], $
      trange = ['2019-04-06/11:40:00','2019-04-06/12:10:00']

    if pause then stop

  endif

  if example_sls_test then begin

    ;
    ; Solar Limb Sensor test quality flag
    ; -----------------------------------
    ;
    ; The PSP spacecraft includes solar limb sensors (SLS) which are
    ; used to ensure the spacecraft remains in a nominal attitude
    ; throughout perihelion. In this attitude, the sensors are in shadow
    ; behind the heat shield. If a sensor is illuminated during perihelion,
    ; the spacecraft autonomous guidance and control will correct the
    ; attitude.
    ;
    ; During an SLS test, which occurs far from perihelion, the spacecraft
    ; attitude is adjusted slightly, in order to illuminate the SLS
    ; detectors and confirm that they detect the illumination.
    ;
    ; During an SLS test, the potential of the boom-mounted sensor can change
    ; rapidly, as the sensor transitions from shadowed to sunlit.
    ;
    ; The example plot below shows an SLS test on 2019 March 3. Before and
    ; after the test, the spacecraft was at aphelion attitude, with the
    ; OFF_UMBRA flag set to 1. For the SLS test, the spacecraft transitions
    ; to the umbra attitude (spacecraft -Z axis aligned with Sun-spacecraft
    ; line.
    ;
    ; The effects of the SLS test are shown most clearly in the single
    ; ended voltage sensor data.
    ;

    timespan, '2019-03-03'

    psp_fld_load, type = 'mag_SC_4_Sa_per_Cyc'
    psp_fld_load, type = 'dfb_wf_vdc'

    options, 'psp_fld_l2_dfb_wf_V1dc', 'ytitle', 'DFB WF!CV1_DC'
    options, 'psp_fld_l2_dfb_wf_V5dc', 'ytitle', 'DFB WF!CV5_DC'

    tplot_options, 'title', 'PSP/FIELDS SLS Test Quality Flag'

    tplot, ['psp_fld_l2_dfb_wf_V1dc', $
      'psp_fld_l2_dfb_wf_V5dc', $
      'psp_fld_l2_quality_flags'], $
      trange = ['2019-03-03/13:00:00','2019-03-03/15:00:00']

    if pause then stop

  endif

  if example_overall then begin

    ;
    ; Overall summary plot of quality flags
    ; -------------------------------------
    ;
    ; This plot shows an overall view of Orbits 3 and 4, with all quality
    ; flags. It illustrates typical occurrence times of particular
    ; quality flags. Note: for PSP, the official encounter period for
    ; each orbit is defined by the interval when the spacecraft is at
    ; a radial distance from the Sun of <0.25 au.
    ;
    ;   BIAS_SWEEP flags occur throughout Encounter (typically for 2 intervals
    ;     per day)
    ;
    ;   THRUSTER flags can occur at any point in the orbit. Typically an
    ;     encounter includes several thruster events.
    ;
    ;   SCM_CAL always occurs near the start and end of the encounter period.
    ;     On occasion, additional SCM_CAL sequences are commanded for
    ;     diagnostic purposes.
    ;
    ;   MAG_ROLL and MAG_CAL events typically occur together (with the CAL
    ;     shortly after the ROLL). Each orbit includes a rotation/cal before
    ;     and after encounter, and most orbits also include a rotation/cal
    ;     near aphelion.
    ;
    ;   SPC_EMODE intervals are commanded by the SWEAP SPC, and typically
    ;     occur during encounter.
    ;
    ;   SLS_CAL sequences are commanded by the spacecraft, and always occur
    ;     outside of encounter.
    ;
    ;   The OFF_UMBRA flag is set when the spacecraft is not in umbra
    ;     orientation, with the SC -Z axis aligned with the Sun-spacecraft
    ;     line. Beyond 0.79 au, the spacecraft is always in OFF_UMBRA
    ;     attitude. Closer than 0.70 au, the spacecraft is always in umbra
    ;     orientation. In between these distances, the spacecraft attitude
    ;     can vary.
    ;

    timespan, '2019-07-01', 275

    psp_fld_load, type = 'mag_RTN_1min'

    options, 'psp_fld_l2_mag_RTN_1min', 'datagap', 300d
    options, 'psp_fld_l2_mag_RTN_1min', 'max_points'

    tplot_options, 'title', 'PSP/FIELDS Quality Flags'

    tplot, ['psp_fld_l2_mag_RTN_1min', $
      'psp_fld_l2_quality_flags']

    if pause then stop

  end

  if example_thruster then begin

    ;
    ; Thruster Firing quality flag
    ; ----------------------------
    ;
    ; The attitude of the PSP spacecraft is maintained primarily by the
    ; reaction wheels. Thrusters are also used for major trajectory
    ; correction maneuvers (TCM) and for automated and commanded
    ; momentum dumps (where built up momentum of the wheels is unloaded).
    ;
    ; For major TCMs, all instruments are turned off. For the smaller
    ; momentum dump thruster firings, the thruster plume creates a transient
    ; ionized plasma which is visible as a large disruption in the
    ; single ended voltage and dipole electric field measurements. The
    ; currents which open and close the thruster valves are also visible in
    ; magnetometer data.
    ;
    ; Automated momentum dumps occur at a rate of a few per Encounter, and
    ; consist of a series of several individual firings over seconds or
    ; tens of seconds. These times are marked in the FIELDS quality flags
    ; by setting the THRUSTER flag to 1.
    ;
    ; The below plot shows an example thruster firing, which occurred on
    ; 2019 April 7, close to PSP perihelion 2. The disruption from the
    ; ionized plasma is clearly visible in the DFB DC spectra and single
    ; ended voltage data, and the thruster valve openings and closings are
    ; visible in the MAG data (particularly the Bz component).
    ;

    timespan, '2019-04-07', 1./4

    psp_fld_load, type = 'dfb_dc_spec'
    psp_fld_load, type = 'dfb_wf_dvdc'
    psp_fld_load, type = 'mag_SC'

    tplot_options, 'title', 'PSP/FIELDS Thruster Flag'

    options, 'psp_fld_l2_dfb_dc_spec_dV12hg', 'ytitle', 'DC SC SPEC!CdV12'

    tplot, ['psp_fld_l2_dfb_dc_spec_dV12hg',$
      'psp_fld_l2_dfb_wf_dVdc_sensor',$
      'psp_fld_l2_mag_SC','psp_fld_l2_quality_flags'], $
      trange = ['2019-04-07/04:04:55','2019-04-07/04:05:25']

    if pause then stop

  end

  if example_scm_cal then begin

    ;
    ; Search Coil Magnetometer calibration quality flag
    ; -------------------------------------------------
    ;
    ; Several times per encounter, a calibration sequence designed to
    ; characterize the response of the Search Coil Magnetometer (SCM) is
    ; run on the spacecraft. Typically, this sequence is performed at least
    ; twice per orbit, prior to the start of the encounter phase (at 0.25 au
    ; inbound) and just after the end of encounter (at 0.25 au outbound).
    ;
    ; The SCM cal sequence is sometimes run more often, for example during
    ; Encounter 3, when it was used to help characterize the SCM u axis
    ; response. The SCM u axis response is discussed in more detail here
    ; https://fields.ssl.berkeley.edu/data/
    ;
    ; The SCM cal sequence is generated by the FIELDS DFB. It consists of
    ; a series of constant amplitude sine waves which step through
    ; several frequencies in the SCM bandpass range.
    ;
    ; The SCM sequence is apparent in all SCM data products, including the
    ; DFB SCM waveform and burst waveform, the DFB AC and DC spectra,
    ; and the DFB AC and DC bandpass filter.
    ;
    ; The plot below shows an SCM CAL sequence on 2018 October 31, at about
    ; 10:40. The first plot shows a DFB DC spectrum from the SCM,
    ; and the DFB SCM waveform. The spectrum measurement at 10:40 shows
    ; stripes corresponding to several of the discrete sine waves in the
    ; cal sequence. (They all appear in a single spectrum because the
    ; spectrum is averaged over the ~1 minute cadence of the DC spectra
    ; data product.)
    ;
    ; The zoomed in plot shows two of the lower freqency
    ; sine waves, towards the end of the sequence. The higher frequency
    ; sine waves are filtered out of the waveform data product.
    ;
    ; During a each SCM cal sequence, high and low gain DBM burst waveforms
    ; are also captured. The zoomed in plot shows the higher frequency sine
    ; waves visible in the DFB burst waveform data.
    ;

    timespan, '2018-10-31/06:00:00', 1./4

    psp_fld_load, type = 'dfb_dc_spec'
    psp_fld_load, type = 'dfb_wf_scm'
    psp_fld_load, type = 'dfb_dbm_scm'

    tplot_options, 'title', 'PSP/FIELDS SCM CAL Flag'

    options, 'psp_fld_l2_dfb_dc_spec_SCMdlfhg', 'ytitle', 'DC SC SPEC!CSCM d hg'

    tplot, ['psp_fld_l2_dfb_dc_spec_SCMdlfhg', $
      'psp_fld_l2_dfb_wf_scm_hg_sensor','psp_fld_l2_quality_flags'], $
      trange = ['2018-10-31/10:35:00','2018-10-31/10:45:00']

    if pause then stop

    tplot, ['psp_fld_l2_dfb_wf_scm_hg_sensor','psp_fld_l2_quality_flags'], $
      trange = ['2018-10-31/10:39:59','2018-10-31/10:40:09']

    if pause then stop

    get_data, 'psp_fld_l2_dfb_dbm_scmhgu', data = d_dbm_scmhgu
    get_data, 'psp_fld_l2_dfb_dbm_scmlgu', data = d_dbm_scmlgu

    store_data, 'psp_fld_l2_dfb_dbm_scmhgu_scm_cal', $
      data = {x:d_dbm_scmhgu.x[9] + reform(d_dbm_scmhgu.v[9,*]), $
      y:reform(d_dbm_scmhgu.y[9,*])}

    options, 'psp_fld_l2_dfb_dbm_scmhgu_scm_cal', 'ytitle', $
      'DFB DBM SCM u'

    options, 'psp_fld_l2_dfb_dbm_scmhgu_scm_cal', 'ysubtitle', $
      '[nT]'

    tplot, ['psp_fld_l2_dfb_dbm_scmhgu_scm_cal', $
      'psp_fld_l2_dfb_wf_scm_hg_sensor','psp_fld_l2_quality_flags'], $
      trange = ['2018-10-31/10:39:59.5','2018-10-31/10:40:05.5']

    if pause then stop

  end

  if example_off_umbra then begin

    ;
    ; Off Umbra quality flag
    ; ----------------------
    ;
    ; The OFF_UMBRA flag is set when the spacecraft is not in umbra
    ; orientation, with the SC -Z axis aligned with the Sun-spacecraft
    ; line. Beyond 0.79 au, the spacecraft is always in OFF_UMBRA
    ; attitude. Closer than 0.70 au, the spacecraft is always in umbra
    ; orientation. In between these distances, the spacecraft attitude
    ; can vary.
    ; 
    ; The example plot below shows several days during the outbound
    ; section of Encounter 3, when the spacecraft crosses the 0.79 au
    ; threshold and transitioned to off umbra orientation.
    ; 
    ; The spacecraft often has the opportunity to transmit Ka band 
    ; data to Earth at these solar distances--and during those Ka 
    ; contacts the FIELDS instrument is turned off. Therefore data 
    ; coverage is often intermittent at or near OFF_UMBRA periods.
    ;

    timespan, '2019-10-09', 5

    psp_fld_load, type = 'mag_RTN_1min'

    options, 'psp_fld_l2_mag_RTN_1min', 'datagap', 300d

    tplot_options, 'title', 'PSP/FIELDS Off Umbra Flag'

    tplot, ['psp_fld_l2_mag_RTN_1min', 'psp_fld_l2_quality_flags']

    if pause then stop

  endif

end