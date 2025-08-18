;+
;
; PROCEDURE: SPP_FLD_LOAD
;
; PURPOSE:   Load data from the PSP/FIELDS instrument suite.
;
; KEYWORDS:
;
;  Commonly used input keywords:
;
;   LEVEL:          Specifies the level of FIELDS files to be loaded.
;                   Level = 2 is the default value.
;
;                   Level 2 and Level 3 data products from PSP/FIELDS are
;                   public. This routine is also used by FIELDS SOC to load
;                   the non-public Level 1 and Level 1b data files, which are
;                   used for production of the Level 2s.
;
;   NO_LOAD:        Don't load the CDF files (i.e., download only).
;
;   NO_SERVER:      Disable contact with remote server. Can be used to load
;                   files which are already downloaded on a local machine,
;                   avoiding check for more recent files on the server.
;
;   NO_STAGING:     Early in the PSP mission, some FIELDS CDF files were
;                   stored in a '/staging/' directory on the server at
;                   UCB/SSL. Setting this option points the load routine
;                   away from these directories, which were retired in
;                   mid-2020.
;
;                   The wrapper routine PSP_FLD_LOAD sets NO_STAGING=1 by
;                   default, and by the end of 2020 this will be the
;                   default option for SPP_FLD_LOAD as well.
;
;   TRANGE:         Two element vector indicating time range for loading data.
;                   The format for TRANGE is the same as for the TPLOT routine.
;                   If TIMESPAN procedure is used to set the desired time range
;                   before SPP_FLD_LOAD is called, that time range is used by
;                   default.
;
;   TYPE:           String identifying the type of data to be loaded.
;                   The default value is "mag_SC_4_Sa_per_Cyc"
;
;   VARFORMAT:      Can be used to manually specify variables which will be
;                   loaded from the CDF file. See CDF2TPLOT documentation
;                   for details.
;
;   VERSION:        Used to manually specify the version of FIELDS CDF that
;                   will be searched for. By default, the routine will find
;                   and load the most recent version.
;
;  Commonly used output keywords:
;
;   FILES:          Optional keyword output that will return the full file path
;                   of files that are downloaded and loaded into TPLOT
;                   variables by this routine.
;
;   Other keywords:
;
;   DOWNSAMPLE:     Used in FIELDS L1 -> L2 data processing of downsampled
;                   MAG data. No effect on L2/L3 data, or other (non-MAG)
;                   L1 data.
;
;   FILEPREFIX:     Manually set the subdirectory where this routine
;                   will search for FIELDS data files.
;                   Typically users do not need to change this from the default
;                   value.
;
;   GET_SUPPORT:    Load support data from the CDF file. See CDF2TPLOT
;                   documentation for details.
;
;   LONGTERM_EPHEM: Flag that can be set to load longterm (mission length)
;                   ephemeris files. (These are Level 1 files, currently not
;                   publicly available.)
;
;   PATHFORMAT:     Can be used to manually set the format of the FIELDS
;                   CDF filenames.
;                   Typically users do not need to change this from the default
;                   value.
;
;   TNAME_PREFIX:   Can be set to add a string prefix in front of any TPLOT
;                   variables created by this routine.
;
; EXAMPLE:
;
;   IDL> timespan, '2019-04-03', 4
;   IDL> spp_fld_load, type = 'mag_RTN_4_Sa_per_Cyc'
;
;   For more examples, see SPP_FLD_EXAMPLES.
;
; CREATED BY:       Davin Larson December 2018
;                   maintained by Marc Pulupa, 2019-2023
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2025-07-03 13:46:25 -0700 (Thu, 03 Jul 2025) $
; $LastChangedRevision: 33424 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spp_fld_load.pro $
;
;-

pro spp_fld_load, trange = trange, type = type, files = files, $
  fileprefix = fileprefix, $
  tname_prefix = tname_prefix, tname_suffix = tname_suffix, $
  pathformat = pathformat, $
  no_load = no_load, varformat = varformat, $
  no_server = no_server, $
  longterm_ephem = longterm_ephem, $
  level = level, get_support = get_support, downsample = downsample, $
  no_staging = no_staging, use_staging = use_staging, version = version
  compile_opt idl2

  if n_elements(no_staging) eq 0 then no_staging = 1

  if keyword_set(use_staging) then no_staging = 0

  if not keyword_set(type) then begin
    DPRINT, 'Choices for type include: mag_SC mag_RTN rfs_lfr rfs_hfr mag_SC_4_Sa_per_Cyc'
    DPRINT, 'See the directories at: "http://research.ssl.berkeley.edu/data/psp/data/sci/fields/l2/" for other valid entries'
    type = 'mag_SC_4_Sa_per_Cyc'
    DPRINT, 'Default is: ', type
  endif

  if n_elements(pathformat) eq 1 then pf_in = pathformat

  ;
  ; By default, set level = 2. Level 2 data are lowest level public data
  ; from PSP/FIELDS.
  ;

  if not keyword_set(level) then level = 2

  ;
  ; Automatically set Level = 1 for some Level 1 data types.
  ;

  l1_types = ['rfs_lfr_auto', 'rfs_hfr_auto', $
    'rfs_hfr_cross', 'rfs_lfr_hires', $
    'dfb_ac_bpf1', 'dfb_ac_bpf2', $
    'dfb_dc_bpf1', 'dfb_dc_bpf2', $
    'aeb1_hk', 'aeb2_hk', $
    'mago_survey', 'magi_survey', $
    'dcb_analog_hk', 'dcb_memory', $
    'dcb_ssr_telemetry', 'dcb_events', 'f1_100bps', 'dfb_hk']

  dummy = where(l1_types eq type, l1_type_flag)

  if (strpos(type, 'ephem') eq 0) or (l1_type_flag ne 0) then level = 1
  if (strpos(type, 'sc_hk_') eq 0) or (strpos(type, 'sc_fsw_') eq 0) then $
    level = 1
  if strpos(type, 'dfb_wf') eq 0 and strlen(type) eq 8 then level = 1

  ;
  ; Automatically set Level = 1.5 for L1b files.
  ; L1b files are an intermediate DFB data product derived from DFB waveform
  ; and burst waveform Level 1 files, which are used to organize and pre-sort
  ; the data before applying the Level 2 calibrations.
  ;

  if strpos(type, 'dfb_wf_vdc') eq 0 and type ne 'dfb_wf_vdc' then level = 1.5
  if strpos(type, 'dfb_wf_edc') eq 0 and type ne 'dfb_wf_edc' then level = 1.5
  if strpos(type, 'dfb_wf_b') eq 0 then level = 1.5
  if strpos(type, 'dfb_dbm_b') eq 0 then level = 1.5
  if strpos(type, 'magi') eq 0 and $
    type ne 'magi_survey' and type ne 'magi_hk' then level = 1.5

  ; SCaM data is Level 3

  if type eq 'merged_scam_wf' or type eq 'sqtn_rfs_V1V2' or $
    type eq 'rfs_lfr_qtn' then level = 3

  ;
  ; If the type keyword is set to DFB AC or DC spectra or cross spectra,
  ; without specifying which particular data source, then SPP_FLD_LOAD
  ; will look for all possible types of spectra. Example:
  ;
  ; timespan, '2020-01-20'
  ;
  ; spp_fld_load, type = 'dfb_ac_spec_dV34hg' ; Load dV34hg spectra only
  ; spp_fld_load, type = 'dfb_ac_spec'        ; Load all available AC spectra
  ;

  if type eq 'dfb_dc_spec' or type eq 'dfb_ac_spec' or $
    type eq 'dfb_dc_xspec' or type eq 'dfb_ac_xspec' then begin
    if level eq 1 then begin
      spec_types = ['1', '2', '3', '4']
    endif else begin
      if type eq 'dfb_dc_spec' or type eq 'dfb_ac_spec' then begin
        spec_types = ['dV12hg', 'dV34hg', 'dV12lg', 'dV34lg', $
          'SCMulfhg', 'SCMvlfhg', 'SCMwlfhg', $
          'SCMulflg', 'SCMvlflg', 'SCMwlflg', $
          'SCMdlfhg', 'SCMelfhg', 'SCMflfhg', $
          'SCMdlflg', 'SCMelflg', 'SCMflflg', $
          'SCMmf', 'V5hg']
      endif else begin
        spec_types = ['SCMdlfhg_SCMelfhg', $ ; cross spectral data types
          'SCMdlfhg_SCMflfhg', $
          'SCMelfhg_SCMflfhg', $
          'SCMulfhg_SCMvlfhg', $
          'SCMulfhg_SCMwlfhg', $
          'SCMvlfhg_SCMwlfhg', $
          'dV12hg_dV34hg']
      endelse
    endelse

    all_files = []

    foreach spec_type, spec_types do begin
      spp_fld_load, trange = trange, type = type + '_' + spec_type, files = files, $
        fileprefix = fileprefix, $
        tname_prefix = tname_prefix, tname_suffix = tname_suffix, $
        pathformat = pathformat, $
        no_load = no_load, varformat = varformat, $
        level = level, get_support = get_support, downsample = downsample, $
        no_staging = no_staging

      all_files = [all_files, files]

      pathformat = !null
      files = !null

      if (tnames('psp_fld_l2_dfb_?c_*spec*_' + spec_type))[0] ne '' then begin
        options, 'psp_fld_l2_dfb_?c_xspec_power*', $
          'no_interp', 1
        options, 'psp_fld_l2_dfb_?c_*spec*_' + spec_type, $
          'no_interp', 1
      end
    end

    if max(strlen(all_files)) gt 0 then $
      files = all_files[where(strlen(all_files) gt 0)] else files = !null

    return
  endif

  ;
  ; If the type keyword is set to DFB AC or DC bandpass filter data,
  ; without specifying which particular data source, then SPP_FLD_LOAD
  ; will look for all possible types of bandpass files. Example:
  ;
  ; timespan, '2020-01-20'
  ;
  ; spp_fld_load, type = 'dfb_ac_bpf_dV34hg'  ; Load dV34hg bandpass only
  ; spp_fld_load, type = 'dfb_ac_bpf'         ; Load all available AC bandpass
  ;

  if type eq 'dfb_dc_bpf' or type eq 'dfb_ac_bpf' then begin
    spec_types = ['dV12hg', 'dV34hg', $
      'SCMulfhg', 'SCMvlfhg', 'SCMwlfhg', $
      'SCMulflg', 'SCMvlflg', 'SCMwlflg', $
      'SCMumfhg', 'V5hg']

    all_files = []

    foreach spec_type, spec_types do begin
      spp_fld_load, trange = trange, type = type + '_' + spec_type, files = files, $
        fileprefix = fileprefix, $
        tname_prefix = tname_prefix, tname_suffix = tname_suffix, $
        pathformat = pathformat, $
        no_load = no_load, varformat = varformat, $
        level = level, get_support = get_support, downsample = downsample, $
        no_staging = no_staging

      all_files = [all_files, files]

      pathformat = !null
      files = !null

      if (tnames('psp_fld_l2_dfb_?c_bpf_' + spec_type + '_avg'))[0] ne '' then begin
        options, 'psp_fld_l2_dfb_?c_bpf_' + spec_type + ['_avg', '_peak'], $
          'no_interp', 1
      end
    end

    if max(strlen(all_files)) gt 0 then $
      files = all_files[where(strlen(all_files) gt 0)] else files = !null

    return
  endif

  ;
  ; By default, FIELDS files use 1 file per day, with the day specified in the
  ; file name as YYYYMMDD.
  ;
  ; Some large volume data types, specified below, use 4 files per day, with
  ; the time specified in the file name as YYYYMMDDhh, where
  ; hh = 00, 06, 12, or 18.
  ;

  daily_names = 1

  ;
  ; Specify subdirectory where FIELDS data files are stored.
  ;
  ; See notes in header on the FILEPREFIX and NO_STAGING keywords.
  ;

  if not keyword_set(fileprefix) then begin
    case level of
      3: fileprefix = 'psp/data/sci/fields/staging/l3/'
      2: fileprefix = 'psp/data/sci/fields/staging/l2/'
      else: fileprefix = 'psp/data/sci/fields/staging/l1/'
    endcase
  endif

  if keyword_set(no_staging) then $
    fileprefix = str_sub(fileprefix, '/staging/', '/')

  ;
  ; Most FIELDS data products are 1 file / day.
  ; Some larger volume data products are divided into four six-hour
  ; segments per day, and need the "resolution" and "pathformat"
  ; keywords altered.
  ;
  ; TODO: consolidate all these IF statements, reduce redundant lines
  ;

  if not keyword_set(pathformat) then begin
    if level eq 3 then begin
      if type eq 'rfs_lfr' or type eq 'rfs_hfr' or $
        type eq 'dust' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l3_TYPE_YYYYMMDD_v??.cdf'
        resolution = 3600l * 24l ; hours
        daily_names = 1
      endif else if type eq 'sqtn_rfs_V1V2' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l3_TYPE_YYYYMMDD_v?.?.cdf'
        resolution = 3600l * 24l ; hours
        daily_names = 1
        tname_prefix = 'psp_fld_l3_sqtn_rfs_V1V2_'
      endif else if type eq 'rfs_lfr_qtn' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l3_TYPE_YYYYMM*_*_v??.cdf'
        if n_elements(tname_prefix) eq 0 then $
          tname_prefix = 'psp_fld_l3_rfs_lfr_qtn_'
      endif else begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l3_TYPE_YYYYMMDDhh_v??.cdf'
        resolution = 3600l * 6l ; hours
        daily_names = 0
      endelse
    endif else if level eq 2 then begin
      pathformat = 'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDD_v??.cdf'
      if type eq 'mag_SC' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDDhh_v??.cdf'
        resolution = 3600l * 6l ; hours
        daily_names = 0
      endif
      if (type eq 'dfb_dbm_dvac') or (type eq 'dfb_dbm_vac') then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDDhh_v??.cdf'
        resolution = 3600l * 6l ; hours
        daily_names = 0
      endif
      if type eq 'mag_RTN' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDDhh_v??.cdf'
        resolution = 3600l * 6l ; hours
        daily_names = 0
      endif
      if type eq 'mag_VSO' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDDhh_v??.cdf'
        resolution = 3600l * 6l ; hours
        daily_names = 0
      endif
      if type eq 'dfb_wf_dvdc' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDDhh_v??.cdf'
        resolution = 3600l * 6l ; hours
        daily_names = 0
      endif
      if type eq 'dfb_wf_vdc' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDDhh_v??.cdf'
        resolution = 3600l * 6l ; hours
        daily_names = 0
      endif
      if type eq 'dfb_wf_scm' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDDhh_v??.cdf'
        resolution = 3600l * 6l ; hours
        daily_names = 0
      endif
      if type eq 'dfb_dbm_dvac' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDDhh_v??.cdf'
        resolution = 3600l * 6l ; hours
        daily_names = 0
      endif
      if type eq 'dfb_dbm_scm' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDDhh_v??.cdf'
        resolution = 3600l * 6l ; hours
        daily_names = 0
      endif
      if type eq 'dfb_dbm_vdc' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDDhh_v??.cdf'
        resolution = 3600l * 6l ; hours
        daily_names = 0
      endif
      if type eq 'dfb_dbm_dvdc' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDDhh_v??.cdf'
        resolution = 3600l * 6l ; hours
        daily_names = 0
      endif
    endif else if level eq 1.5 then begin
      pathformat = 'TYPE/YYYY/MM/spp_fld_l1b_TYPE_YYYYMMDD_v??.cdf'
      if type eq 'magi_SC' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l1b_TYPE_YYYYMMDDhh_v??.cdf'
        resolution = 3600l * 6l ; hours
        daily_names = 0
      endif
      if type eq 'magi_RTN' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l1b_TYPE_YYYYMMDDhh_v??.cdf'
        resolution = 3600l * 6l ; hours
        daily_names = 0
      endif
    endif else begin
      pathformat = 'TYPE/YYYY/MM/spp_fld_l1_TYPE_YYYYMMDD_v??.cdf'
    endelse
  endif

  ;
  ; The DFB spectra and bandpass files are organized in folders which allow
  ; more than one type of file in the folder--for example, in the first encounter
  ; the DC spectra folder for 2018/11 contains dV12hg, SCMdlfhg, SCMdlfhg,
  ; and SCMelfhg files.  The below string substitution makes sure the load
  ; routine is addressing this correctly.
  ;

  if (strmid(type, 0, 12) eq 'dfb_dc_xspec') or (strmid(type, 0, 12) eq 'dfb_ac_xspec') and level eq 2 then begin
    pathformat = 'DIR' + pathformat

    pathformat = str_sub(pathformat, 'DIRTYPE', strmid(type, 0, 12))
  endif

  if (strmid(type, 0, 10) eq 'dfb_dc_bpf') or (strmid(type, 0, 10) eq 'dfb_ac_bpf') and level eq 2 then begin
    pathformat = 'DIR' + pathformat

    pathformat = str_sub(pathformat, 'DIRTYPE', strmid(type, 0, 10))
  endif

  if (strmid(type, 0, 11) eq 'dfb_dc_spec') or (strmid(type, 0, 11) eq 'dfb_ac_spec') and level eq 2 then begin
    pathformat = 'DIR' + pathformat

    pathformat = str_sub(pathformat, 'DIRTYPE', strmid(type, 0, 11))
  endif

  ;
  ; Add the prefix (URL to remote sever directory), and substitute TYPE
  ; with the actual file type.
  ;

  pathformat = str_sub(pathformat, 'TYPE', type)
  pathformat = fileprefix + pathformat

  ;
  ; Some type names include 'ss' (e.g. 'rfs_hfr_cross'), which we have to
  ; escape so the download routine does not interpret it as seconds in
  ; a time format string.
  ;

  pathformat = str_sub(pathformat, 'ss', 's\s')

  ;
  ; Level 1.5 = Level 1b data products, stored in the "/l1b/" folder
  ; on the server.
  ;

  if level eq 1.5 then pathformat = str_sub(pathformat, '/l1/', '/l1b/')
  if level eq 1.5 then pathformat = str_sub(pathformat, '_l1_', '_l1b_')

  ;
  ; Special case for loading longterm ephemeris files
  ;

  if n_elements(longterm_ephem) gt 0 then begin
    pathformat = str_sub(pathformat, 'YYYY/MM/', 'full_mis\sion/')

    pathformat = str_sub(pathformat, 'YYYYMMDD', $
      '20180812_090000_20300101_090000')

    ;
    ; Solar Orbiter longterm ephemeris
    ;

    if pathformat.contains('solo') then begin
      pathformat = str_sub(pathformat, '20180812_090000_20300101_090000', $
        '20200210_050000_20301120_050000')
    endif
  endif

  ;
  ; The routine can optionally download specific versions of the CDF files.
  ; By default the latest version is loaded.
  ;

  if n_elements(version) eq 1 then begin
    pathformat = str_sub(pathformat, 'v??', $
      'v' + string(version, format = '(I02)'))
  endif

  ;
  ; Retrieve files based on the path format.
  ;

  files = spp_file_retrieve(key = 'FIELDS', pathformat, trange = trange, source = src, $
    /last_version, daily_names = daily_names, /valid_only, $
    resolution = resolution, shiftres = 0, no_server = no_server)

  if files[0] eq '' then begin
    DPRINT, 'No valid files found'
    return
  end

  if not keyword_set(no_load) then begin
    if level eq 1 then begin
      ;
      ; Generic routine for loading L1s. This is a wrapper routine which
      ; calls data-type specific routines in the SPP/FIELDS/l1 subdirectory
      ; in SPEDAS.
      ;

      spp_fld_load_l1, files, varformat = varformat, downsample = downsample, $
        add_prefix = tname_prefix, add_suffix = tname_suffix
    endif else begin
      ;
      ; Level 2 and Level 3 files are loaded with the default SPEDAS
      ; cdf2tplot routine. RFS has an instrument-specific routine--this is
      ; because the large number of variables included in the RFS data files
      ; make them slow to load without some pre-processing to avoid attempts
      ; to load variables with zero records.
      ;

      if strmatch(type, 'rfs_?fr') then begin
        psp_fld_rfs_load_l2, files, varformat = varformat
      endif else begin
        if n_elements(varformat) gt 0 then begin
          cdf2tplot, files, varformat = varformat, $
            prefix = tname_prefix, suffix = tname_suffix, /load_labels, tplotnames = tn
        endif else begin
          cdf2tplot, files, prefix = tname_prefix, suffix = tname_suffix, $
            /all, /load_labels, tplotnames = tn
        endelse
      endelse

      ;
      ; Set TPLOT plotting options for specific data types
      ;

      if strmatch(type, 'mag_*') then begin
        r = where(tn.matches('quality_flag'))
        qf_root = tn[r[0]]

        r = where(tn.matches('mag_RTN') and $
          not tn.matches('(_MET|_range|_mode|_rate|_packet_index)'), /null)
        options, tn[r], /def, ytitle = 'MAG RTN', $
          psym_lim = 300, $
          colors = 'bgr', $
          qf_root = qf_root ; To simplify dealing with pre/suffixes for qf filtering
        options, tn[r], max_points = 10000 ; not a default option, so users can turn it off

        r = where(tn.matches('mag_SC') and $
          not tn.matches('(_zero|_MET|_range|_mode|_rate|_packet_index)'), /null)
        options, tn[r], /def, ytitle = 'MAG SC', $
          psym_lim = 300, $
          colors = 'bgr', $
          qf_root = qf_root ; see above
        options, tn[r], max_points = 10000 ; see above

        r = where(tn.matches('mag_VSO') and $
          not tn.matches('(_MET|_range|_mode|_rate|_packet_index)'), /null)
        options, tn[r], /def, ytitle = 'MAG VSO', psym_lim = 300
        options, tn[r], /def, colors = 'bgr'
        options, tn[r], max_points = 10000 ; see above
      endif

      if strmatch(type, 'magi_*') then begin
        r = where(tn.matches('quality_flag'))
        qf_root = tn[r[0]]

        r = where(tn.matches('magi_RTN') and $
          not tn.matches('(_MET|_range|_mode|_rate|_packet_index)'), /null)
        options, tn[r], /def, ytitle = 'MAGi RTN', $
          psym_lim = 300, $
          colors = 'bgr', $
          qf_root = qf_root ; To simplify dealing with pre/suffixes for qf filtering
        options, tn[r], max_points = 10000 ; not a default option, so users can turn it off

        r = where(tn.matches('magi_SC') and $
          not tn.matches('(_zero|_MET|_range|_mode|_rate|_packet_index)'), /null)
        options, tn[r], /def, ytitle = 'MAGi SC', $
          psym_lim = 300, $
          colors = 'bgr', $
          qf_root = qf_root ; see above
        options, tn[r], max_points = 10000 ; see above
      endif

      if strmatch(type, 'dfb_wf_*') then begin
        if tnames('psp_fld_l2_dfb_wf_dVdc_sensor') ne '' then begin
          options, 'psp_fld_l2_dfb_wf_dVdc_sensor', 'ytitle', 'DFB WF dV_DC'
          options, 'psp_fld_l2_dfb_wf_dVdc_sensor', colors = 'br', /default
          options, 'psp_fld_l2_dfb_wf_dVdc_sensor', 'max_points', 10000
          options, 'psp_fld_l2_dfb_wf_dVdc_sensor', 'psym_lim', 300
        endif

        if tnames('psp_fld_l2_dfb_wf_dVdc_sc') ne '' then begin
          options, 'psp_fld_l2_dfb_wf_dVdc_sc', 'ytitle', 'DFB WF dV_DC'
          options, 'psp_fld_l2_dfb_wf_dVdc_sc', colors = 'br', /default
          options, 'psp_fld_l2_dfb_wf_dVdc_sc', 'max_points', 10000
          options, 'psp_fld_l2_dfb_wf_dVdc_sc', 'psym_lim', 300
        endif

        if tnames('psp_fld_l2_dfb_wf_V1dc') ne '' then begin
          options, 'psp_fld_l2_dfb_wf_V1dc', 'ytitle', 'DFB WF V1_DC'
          options, 'psp_fld_l2_dfb_wf_V2dc', 'ytitle', 'DFB WF V2_DC'
          options, 'psp_fld_l2_dfb_wf_V3dc', 'ytitle', 'DFB WF V3_DC'
          options, 'psp_fld_l2_dfb_wf_V4dc', 'ytitle', 'DFB WF V4_DC'
          options, 'psp_fld_l2_dfb_wf_V5dc', 'ytitle', 'DFB WF V5_DC'

          options, 'psp_fld_l2_dfb_wf_V?dc', 'max_points', 10000
          options, 'psp_fld_l2_dfb_wf_V?dc', 'psym_lim', 300
        endif

        if tnames('psp_fld_l2_dfb_wf_scm_hg_sc') ne '' or $
          tnames('psp_fld_l2_dfb_wf_scm_lg_sc') ne '' then begin
          options, 'psp_fld_l2_dfb_wf_scm_hg_s*', 'ytitle', 'DFB WF SCM'
          options, 'psp_fld_l2_dfb_wf_scm_?g_s*', colors = 'bgr', /default
          options, 'psp_fld_l2_dfb_wf_scm_?g_s*', 'max_points', 10000
          options, 'psp_fld_l2_dfb_wf_scm_?g_s*', 'psym_lim', 300
        endif
      endif

      if strmatch(type, 'dfb_wf_edc') then begin
        if tnames('psp_fld_l3_dfb_wf_edc_sc') ne '' then begin
          options, 'psp_fld_l3_dfb_wf_edc_' + $
            ['sc', 'vxb_sc', 'leff', 'angdev', 'offset', 'corrcoeff'], $
            'colors', 'br'

          edc_tnames = tnames('psp_fld_l3_dfb_wf_edc*', n_edc_tnames)

          for i = 0, n_edc_tnames - 1 do begin
            options, edc_tnames[i], 'ytitle', 'DFB WF EDC!C' + $
              strmid(edc_tnames[i], 22)
          endfor
        endif
      endif

      if strmatch(type, 'dfb_dbm*') then begin
        foreach tn, tnames('psp_fld_l2_' + type + '*') do begin
          tn_split = strsplit(strmid(tn, 15), '_', /ex)
          if n_elements(tn_split) eq 3 then $
            options, tn, 'psym', 1
          options, tn, 'ytitle', strupcase(strjoin(tn_split, '!C'))
        endforeach
      endif

      if strmatch(type, 'merged_scam_wf') then begin
        options, 'psp_fld_l3_merged_scam_wf_SC', 'ytitle', 'SCaM SC'
        options, 'psp_fld_l3_merged_scam_wf_uvw', 'ytitle', 'SCaM uvw'
        options, 'psp_fld_l3_merged_scam_wf_*', 'ysubtitle', '[nT]'
        options, 'psp_fld_l3_merged_scam_' + $
          ['wf_*', 'scm_sample_rate', 'mag_offset_*'], colors = 'bgr', /default
        options, 'psp_fld_l3_merged_scam_rxn_whl', colors = 'bgrk', /default
        options, 'psp_fld_l3_merged_scam_wf_SC', 'max_points', 10000
        options, 'psp_fld_l3_merged_scam_wf_SC', 'psym_lim', 300

        options, 'psp_fld_l3_merged_scam_???_sample_rate', 'colors', 'r'
        options, 'psp_fld_l3_merged_scam_mag_range', 'colors', 'r'

        options, 'psp_fld_l3_merged_scam_scm_sample_rate', 'ytitle', 'SCaM!CSCM Rate'
        options, 'psp_fld_l3_merged_scam_mag_sample_rate', 'ytitle', 'SCaM!CMAG Rate'
        options, 'psp_fld_l3_merged_scam_rxn_whl', 'ytitle', 'SCaM!CRXN WHL'
        options, 'psp_fld_l3_merged_scam_mag_range', 'ytitle', 'SCaM!CMAG Range'
        options, 'psp_fld_l3_merged_scam_mag_offset_uvw', 'ytitle', 'SCaM!CMAG Off!Cuvw'
        options, 'psp_fld_l3_merged_scam_mag_offset_SC', 'ytitle', 'SCaM!CMAG Off'
      end

      if strmatch(type, 'aeb') then begin
        aeb_tnames = tnames('psp_fld_l2_aeb*', n_aeb_tnames)

        for i = 0, n_aeb_tnames - 1 do begin
          ytitle = strupcase(((aeb_tnames[i]).subString(11)))

          options, aeb_tnames[i], 'ytitle', ytitle.replace('_', '!C')

          options, aeb_tnames[i], 'datagap', 7200d

          if strmatch(aeb_tnames[i], '*TEMP') eq 0 then begin
            options, aeb_tnames[i], 'tplot_routine', 'psp_fld_aeb_mplot'
          endif
        endfor

        if tnames('psp_fld_l2_aeb1_PA1_TEMP') ne '' then begin
          options, 'psp_fld_l2_aeb1_PA1_TEMP', 'colors', ['b']
          options, 'psp_fld_l2_aeb1_PA2_TEMP', 'colors', ['g']
          options, 'psp_fld_l2_aeb1_V1_*', 'colors', ['b']
          options, 'psp_fld_l2_aeb1_V2_*', 'colors', ['g']
        endif

        if tnames('psp_fld_l2_aeb2_PA3_TEMP') ne '' then begin
          options, 'psp_fld_l2_aeb2_PA3_TEMP', 'colors', ['r']
          options, 'psp_fld_l2_aeb2_PA4_TEMP', 'colors', ['m']
          options, 'psp_fld_l2_aeb2_V3_*', 'colors', ['r']
          options, 'psp_fld_l2_aeb2_V4_*', 'colors', ['m']
        endif
      endif

      if strmatch(type, 'rfs_lfr_qtn') then begin
        options, 'psp_fld_l3_rfs_lfr_qtn_N_elec*', 'ylog', 1
        options, 'psp_fld_l3_rfs_lfr_qtn_N_elec*', 'psym', -3
        options, 'psp_fld_l3_rfs_lfr_qtn_N_elec_dqf', 'ylog'
        options, 'psp_fld_l3_rfs_lfr_qtn_N_elec', 'ytitle', 'LFR QTN Ne'
      endif

      if strmatch(type, 'sqtn_rfs*') then begin
        sqtn = 'psp_fld_l3_sqtn_rfs_V1V2_'

        get_data, sqtn + 'electron_density', $
          data = d_ne, al = al_ne
        get_data, sqtn + 'electron_density_delta', $
          data = d_delta

        store_data, sqtn + 'electron_density_ddelta', $
          data = {x: d_ne.x, $
            y: [[d_ne.y - d_delta.y[*, 0]], [d_ne.y + d_delta.y[*, 1]]]}

        options, sqtn + 'electron_density', 'ytitle', 'SQTN Ne'
        options, sqtn + 'electron_core_temperature', 'ytitle', 'SQTN Tc'
        options, sqtn + 'electron_density_delta', 'ytitle', 'SQTN dNe'
        options, sqtn + 'electron_density_ddelta', 'ytitle', 'SQTN Ne+/-dNe'

        options, sqtn + 'electron_density*', 'psym', -3
        options, sqtn + 'electron_density*', 'ylog', 1
        options, sqtn + 'electron_density_*delta', 'colors', ['r', 'k']
        options, sqtn + 'electron_density_*delta', 'ysubtitle', $
          al_ne.ysubtitle
        options, sqtn + 'electron_core_temperature', 'ylog', 1

        if tnames(sqtn + 'density_quality_flag') ne '' then begin
          options, sqtn + 'density_quality_flag', 'ytitle', 'SQTN Quality'
          options, sqtn + 'density_quality_flag', 'psym', 3
          options, sqtn + 'density_quality_flag', 'yrange', [-0.5, 4.5]
          options, sqtn + 'density_quality_flag', 'ystyle', 1
          options, sqtn + 'density_quality_flag', 'yminor', 1
        endif
      endif

      ;
      ; Quality flags
      ;
      ; From the CDF metadata:
      ;
      ; FIELDS quality flags. This is a bitwise variable, meaning that
      ; multiple flags can be set for a single time, by adding flag values.
      ; Current flagged values are:
      ; 1: FIELDS antenna bias sweep,
      ; 2: PSP thruster firing,
      ; 4: SCM Calibration,
      ; 8: PSP rotations for MAG calibration (MAG rolls),
      ; 16: FIELDS MAG calibration sequence,
      ; 32: SWEAP SPC in electron mode,
      ; 64: PSP Solar limb sensor (SLS) test.
      ; 128: PSP spacecraft is off umbra pointing.
      ;
      ; A value of zero corresponds to no set flags.
      ;
      ; These plot options set up the BITPLOT routine to display the flags
      ; individually, on separate lines in a single TPLOT panel.
      ;
      ; The flags loaded from a L2/L3 files are at a default resolution of 1
      ; minute. The routine PSP_FLD_QF_FILTER will filter TPLOT variables
      ; based on these quality flags.
      ;

      qf_name = 'psp_fld_l?_quality_flags'

      if n_elements(tname_prefix) eq 1 then qf_name = tname_prefix + qf_name
      if n_elements(tname_suffix) eq 1 then qf_name = qf_name + tname_suffix

      foreach qf_tname, tnames(qf_name) do begin
        if qf_tname ne '' then begin
          options, qf_name, 'tplot_routine', 'bitplot'
          options, qf_name, 'psyms', [2]

          qf_labels = $
            ['BIAS_SWP', 'THRUSTER', 'SCM_CAL', $
            'MAG_ROLL', 'MAG_CAL', 'SPC_EMODE', 'SLS_CAL', 'OFF_UMBRA', $
            'HF_NOISE', 'ANT_RAILS', 'ANOM_BIAS']

          nbits = n_elements(qf_labels)

          options, qf_name, 'numbits', nbits
          options, qf_name, 'yticks', nbits + 1
          options, qf_name, 'ytickname', $
            [' ', string(indgen(nbits), format = '(I2)'), ' ']
          options, qf_name, 'labels', qf_labels
          options, qf_name, 'ytitle', 'Quality Flags'
          options, qf_name, 'ysubtitle', ' '
          options, qf_name, 'colors', [0, 1, 2, 6]
          options, qf_name, 'yticklen', 1
          options, qf_name, 'ygridstyle', 1
          options, qf_name, 'yminor', 1
        endif
      endforeach
    endelse
  endif

  if n_elements(pf_in) eq 1 then pathformat = pf_in
end
