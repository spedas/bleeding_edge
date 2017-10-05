;+
;NAME:
; fa_esa_cmn_l2gen.pro
;PURPOSE:
; turn a FAST ESA common block into a L2 CDF.
;CALLING SEQUENCE:
; fa_esa_cmn_l2gen, cmn_dat
;INPUT:
; cmn_dat = a structrue with the data:
;   PROJECT_NAME    STRING    'FAST'
;   DATA_NAME       STRING    'Iesa Burst'
;   DATA_LEVEL      STRING    'Level 1'
;   UNITS_NAME      STRING    'Compressed'
;   UNITS_PROCEDURE STRING    'fa_convert_esa_units'
;   VALID           INT       Array[59832]
;   DATA_QUALITY    BYTE      Array[59832]
;   TIME            DOUBLE    Array[59832]
;   END_TIME        DOUBLE    Array[59832]
;   INTEG_T         DOUBLE    Array[59832]
;   DELTA_T         DOUBLE    Array[59832]
;   NBINS           BYTE      Array[59832]
;   NENERGY         BYTE      Array[59832]
;   GEOM_FACTOR     FLOAT     Array[59832]
;   DATA_IND        LONG      Array[59832]
;   GF_IND          INT       Array[59832]
;   BINS_IND        INT       Array[59832]
;   MODE_IND        BYTE      Array[59832]
;   THETA_SHIFT     FLOAT     Array[59832]
;   THETA_MAX       FLOAT     Array[59832]
;   THETA_MIN       FLOAT     Array[59832]
;   BKG             FLOAT     Array[59832]
;   DATA0           BYTE      Array[48, 32, 59832]
;   DATA1           FLOAT     NaN (48, 64, ntimes) (here single NaN means no data)
;   DATA2           FLOAT     NaN (96, 32, ntimes)
;   ENERGY          FLOAT     Array[96, 32, 2]
;   BINS            BYTE      Array[96, 32]
;   THETA           FLOAT     Array[96, 32, 2]
;   GF              FLOAT     Array[96, 64]
;   DENERGY         FLOAT     Array[96, 32, 2]
;   DTHETA          FLOAT     Array[96, 32, 2]
;   EFF             FLOAT     Array[96, 32, 2]
;   DEAD            FLOAT       1.10000e-07
;   MASS            FLOAT         0.0104389
;   CHARGE          INT              1
;   SC_POT          FLOAT     Array[59832]
;   BKG_ARR         FLOAT     Array[96, 64]
;   HEADER_BYTES    BYTE      Array[44, 59832]
;   DATA            BYTE      Array[59832, 96, 64]
;   EFLUX           FLOAT     Array[59832, 96, 64]
;   ENERGY_FULL     FLOAT     Array[59832, 96, 64]
;   DENERGY_FULL    FLOAT     Array[59832, 96, 64]
;   PITCH_ANGLE     FLOAT     Array[59832, 96, 64]
;   DOMEGA          FLOAT     Array[59832, 96, 64]
;KEYWORDS:
; otp_struct = this is the structure that is passed into
;              cdf_save_vars to create the file
; directory = Set this keyword to direct the output into this
;             directory; the default is './'
; fullfile_out = the output filename
;HISTORY:
; Hacked from mvn_sta_cmn_l2gen.pro, 22-jul-2015
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-11-02 13:57:47 -0700 (Wed, 02 Nov 2016) $
; $LastChangedRevision: 22261 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2util/fa_esa_cmn_l2gen.pro $
;-
Pro fa_esa_cmn_l2gen, cmn_dat, esa_type=esa_type, $
                      otp_struct = otp_struct, $
                      directory = directory, $
                      fullfile_out = fullfile0, $
                      no_compression = no_compression, $
                      _extra = _extra

;Keep track of software versioning here
  sw_vsn = fa_esa_current_sw_version()
  sw_vsn_str = 'v'+string(sw_vsn, format='(i2.2)')

  If(~is_struct(cmn_dat)) Then Begin
     message,/info,'No Input Structure'
     Return
  Endif
  If(cmn_dat.orbit_start Ne cmn_dat.orbit_end) Then Begin
     message,/info,'No multiple orbit files plaese'
     Return
  Endif

;Get the start time for this orbit:
;  tt = fa_orbit_to_time(cmn_dat.orbit_start)
;  date = time_string(tt[1], format=6)
;First, global attributes
  global_att = {Acknowledgment:'None', $
                Data_type:'CAL>Calibrated', $
                Data_version:'0', $
                Descriptor:'FA_ESA>Fast Auroral SnapshoT Explorer, Electrostatic Analyzer', $
                Discipline:'Space Physics>Planetary Physics>Particles', $
                File_naming_convention: 'descriptor_datatype_yyyyMMddHHmmss', $
                Generated_by:'FAST SOC' , $
                Generation_date:'2015-07-28' , $
                HTTP_LINK:'http://sprg.ssl.berkeley.edu/fast/', $
                Instrument_type:'Particles (space)' , $
                LINK_TEXT:'General Information about the FAST mission' , $
                LINK_TITLE:'FAST home page' , $
                Logical_file_id:'fa_esa_l2_XXX_00000000000000_v00.cdf' , $
                Logical_source:'fa_esa_l2_XXX' , $
                Logical_source_description:'FAST Ion and Electron Particle Distributions', $
                Mission_group:'FAST' , $
                MODS:'Rev-1 2015-07-28' , $
                PI_name:'J. P. McFadden', $
                PI_affiliation:'U.C. Berkeley Space Sciences Laboratory', $
                Planet:'Earth', $
                Project:'FAST', $
                Rules_of_use:'Open Data for Scientific Use' , $
                Source_name:'FAST>Fast Auroral SnapshoT Explorer', $
                TEXT:'ESA>Electrostatic Analyzer', $
                Time_resolution:'1 sec', $
                Title:'FAST ESA Electron and Ion Distributions'}

;Now variables and attributes
  cvars = strlowcase(tag_names(cmn_dat))
;What type of data? ext is for filenames ext1, 2 for labels
  If(keyword_set(esa_type)) Then Begin
     ext = strlowcase(strcompress(/remove_all, esa_type[0])) 
  Endif Else Begin
     type_test = strlowcase(strcompress(/remove_all, cmn_dat.data_name))
     Case type_test Of
        'iesasurvey': ext = 'ies'
        'iesaburst': ext = 'ieb'
        'eesasurvey': ext = 'ees'
        'eesaburst': ext = 'eeb'
        Else: ext = 'oops'
     Endcase
  Endelse        
  Case ext Of
     'ies': Begin
        ext1 = 'Survey Ion '
        ext2 = 'Differential survey-mode ion ' 
     End
     'ieb': Begin
        ext1 = 'Burst Ion '
        ext2 = 'Differential burst-mode ion ' 
     End
     'ees': Begin
        ext1 = 'Survey Electron '
        ext2 = 'Differential survey-mode electron ' 
     End
     'eeb': Begin
        ext1 = 'Burst Electron '
        ext2 = 'Differential burst-mode electron ' 
     End
     Else: Begin 
        ext1 = ext
        ext2 = ext
     End
  Endcase

; Here are variable names, type, catdesc, and lablaxis
  rv_vt =  [['epoch', 'CDF_EPOCH', 'CDF EPOCH time, one element per ion distribution (NUM_DISTS elements)', 'CDF_EPOCH'], $
            ['time_unix', 'DOUBLE', 'Unix time (elapsed seconds since 1970-01-01/00:00 without leap seconds) for each data record, one element per distribution. This time is the center time of data collection. (NUM_DISTS elements)', 'Unix Time'], $
            ['time_start', 'DOUBLE', 'Unix time at the start of data collection. (NUM_DISTS elements)', 'Interval start time (unix)'], $
            ['time_end', 'DOUBLE', 'Unix time at the end of data collection. (NUM_DISTS elements)', 'Interval end time (unix)'], $
            ['time_delta', 'DOUBLE', 'Averaging time. (TIME_END - TIME_START). (NUM_DISTS elements).', 'Averaging time'], $
            ['time_integ', 'DOUBLE', 'Integration time. (TIME_DELTA/N_ENERGY). (NUM_DISTS elements).', 'Integration time'], $
            ['header_bytes', 'BYTE', 'The packet header bytes. (44XNUM_DISTS elements)', 'Header'], $
            ['valid', 'INTEGER', 'Validity flag codes valid data from CDF, 0 for invalid data, 1 for good data', ' Valid flag'], $
            ['data_quality', 'INTEGER', 'Quality flag (NUM_DISTS elements)', 'Quality flag, 0 for good quality, add 2 for counter overflow overflow, add 4 for excess dead_time above 0.90'], $
            ['nbins', 'INTEGER', 'Number of angluar bins (NUM_DISTS elements)', 'Number of bins'], $
            ['nenergy', 'INTEGER', 'Number of energies (NUM_DISTS elements)', 'Number of energies'], $
            ['geom_factor', 'DOUBLE', 'GEOM_FACTOR, Geometrical factor used in calibration (NUM_DISTS elements)', 'Geometric Factor'], $
            ['gf_ind', 'INTEGER', 'Index for the value of the Geometrical factor for data (NUM_DISTS elements)', 'GF index'], $
            ['bins_ind', 'INTEGER', 'Index for the number of angular bins for data (NUM_DISTS elements)', 'Bins index'], $
            ['mode_ind', 'INTEGER', 'Index for the data mode (0-2 for survey data, 0-1 for burst data) (NUM_DISTS elements)', 'Mode index'], $
            ['theta_shift', 'DOUBLE', 'Angular shift (NUM_DISTS elements)', 'Angular shift, converts theta bin values to pitch angles'], $
            ['theta_max', 'DOUBLE', 'Angular maximum (NUM_DISTS elements)', 'Angular max'], $
            ['theta_min', 'DOUBLE', 'Angular minimum (NUM_DISTS elements)', 'Angular min'], $
            ['bkg', 'FLOAT', 'Background counts array with dimensions (NUM_DISTS)', 'Background counts'], $
            ['sc_pot', 'FLOAT', 'Spacecraft potential (NUM_DISTS elements)', 'Spacecraft potential'], $
            ['data', 'BYTE', ext1+'Raw Counts data with dimensions (96, 64, NUM_DISTS)', ext1+'Raw Counts'], $
            ['eflux', 'FLOAT', ext2+'Differential energy flux array with dimensions (96, 64, NUM_DISTS) (as plasmagrams)', ext1+'Energy flux'], $
            ['eflux_movie', 'FLOAT', ext1+'Plasmagram movie', ext1+'Energy Flux'],$
            ['eflux_byE_atA', 'FLOAT', ext1+'Spectrograms by energy at sample pitch angles', ext1+'Energy Flux'],$
            ['eflux_byA_atE', 'FLOAT', ext1+'Spectrograms by pitch_angle at sample energies', ext1+'Energy Flux'],$
            ['pitch_angle_median', 'FLOAT', '---> Median Pitch Angle', 'Median Pitch Angle'],$
            ['energy_median', 'FLOAT', '---> Median Energy', 'Median Energy'],$
            ['pitch_angle', 'FLOAT', 'Pitch Angle values for each distribution (96, 64, NUM_DISTS)', 'Pitch Angle'], $
            ['domega', 'FLOAT', 'Solid angle for each distribution (96, 64, NUM_DISTS)', 'DOmega'], $
            ['energy_full', 'FLOAT', 'Angular values for each distribution (96, 64, NUM_DISTS)', 'Energy'], $
            ['denergy_full', 'FLOAT', 'Energy bin size for each distribution (96, 64, NUM_DISTS)', 'DEnergy'], $
            ['orbit_number', 'FLOAT', 'Orbit number for this file, does not change, so only 2 entries per file', 'Orbit_number'], $ 
            ['orbit_number_time', 'DOUBLE', 'Time array, unix time for orbit number', 'Orbit Number Time'], $
            ['orbit_number_epoch', 'CDF_EPOCH', 'CDF Epoch array for orbit number', 'Orbit Number Epoch']]

;Use Lower case for variable names; try to relax this assumption
;  rv_vt[0, *] = strlowcase(rv_vt[0, *])

;No need for lablaxis values here, just use the name
  nv_vt = [['project_name', 'STRING', 'FAST'], $
           ['data_name', 'STRING', cmn_dat.data_name], $
           ['data_level', 'STRING', 'Level 2'], $
           ['units_name', 'STRING', 'eflux'], $
           ['units_procedure', 'STRING', 'fa_esa_convert_esa_units, name of IDL routine used for units conversion '], $
           ['num_dists', 'INTEGER', 'Number of measurements or times in the file'], $
           ['bins', 'INTEGER', 'Array with dimension NBINS containing 1 OR 0 used to flag bad angle bins'], $
           ['energy', 'FLOAT', 'Energy array with dimension (96,64 or 32,nmode)'], $
           ['denergy', 'FLOAT', 'Delta Energy array with dimension (96, 64 or 32, 2 or 3)'], $
           ['theta', 'FLOAT', 'Angle array with with dimension (96, 64 or 32, 2 or 3)'], $
           ['dtheta', 'FLOAT', 'Delta Angle array with with dimension (96, 64 or 32, 2 or 3)'], $
           ['gf', 'FLOAT', 'Geometric Factor array with dimension (96, 64)'], $
           ['eff', 'FLOAT', 'Efficiency array with dimension (96, 64 or 32, 2 or 3)'], $
           ['dead', 'FLOAT', 'Dead time in seconds for 1 processed count'], $
           ['mass', 'FLOAT', 'Proton or Electron mass in units of MeV/c2'], $
           ['charge', 'FLOAT', 'Proton or Electron charge (1 or -1)'], $
           ['bkg_arr', 'FLOAT', 'Background counts array with dimension (96, 64)'], $
           ['orbit_start', 'LONG', 'Start Orbit of file'], $
           ['orbit_end', 'LONG', 'End Orbit of file']]

;Create variables for epoch
  cdf_leap_second_init
  date_range = time_double(['1996-08-21/00:00:00','2009-05-01/00:00:00'])
  epoch_range = time_epoch(date_range)

;Use center time for time variables
  center_time = 0.5*(cmn_dat.time+cmn_dat.end_time)
  num_dists = n_elements(center_time)

;Initialize
  otp_struct = -1
  count = 0L
;First handle RV variables
  lrv = n_elements(rv_vt[0, *])
  For j = 0L, lrv-1 Do Begin
;Either the name is in the common block or not, names not in the
;common block have to be dealt with as special cases. Vectors will
;need label and component variables
     is_virtual = 0b
     is_tvar = 0b
     vj = rv_vt[0, j]
     Have_tag = where(cvars Eq vj, nhave_tag)
     If(nhave_tag Gt 0) Then Begin
        dvar = cmn_dat.(have_tag)
        If(vj Eq 'header_bytes') Then dvar = transpose(dvar)
     Endif Else Begin
;Case by case basis
        Case vj of
           'epoch': Begin
              dvar = time_epoch(center_time)
              is_tvar = 1b
           End
           'time_unix': Begin
              dvar = center_time
              is_tvar = 1b
           End
           'time_start': Begin
              dvar = cmn_dat.time
              is_tvar = 1b
           End
           'time_end': Begin
              dvar = cmn_dat.end_time
              is_tvar = 1b
           End
           'time_delta': dvar = cmn_dat.delta_t
           'time_integ': dvar = cmn_dat.integ_t
           'orbit_number': dvar = [cmn_dat.orbit_start, cmn_dat.orbit_end]
           'orbit_number_time': Begin
              dvar = minmax(center_time)
              is_tvar = 1b
           End
           'orbit_number_epoch': Begin
              dvar = time_epoch(minmax(center_time))
              is_tvar = 1b
           End
           'eflux_movie':Begin
              dvar = 1.0 ;do this for data typing
              is_virtual = 1b
           End
           'eflux_byE_atA':Begin
              dvar = 1.0
              is_virtual = 1b
           End
           'eflux_byA_atE':Begin
              dvar = 1.0
              is_virtual = 1b
           End
           'energy_median':Begin
              is_virtual = 1b
              dvar = 1.0
           End
           'pitch_angle_median':Begin
              dvar = 1.0
              is_virtual = 1b
           End
           Else: Begin
              message, /info, 'Variable '+vj+' Unaccounted for.'
           End
        Endcase
     Endelse
;variable attributes here, but only the string attributes, the others
;depend on the data type
     vatt = {catdesc:'NA', display_type:'NA', fieldnam:'NA', $
             units:'None', depend_time:'NA', $
             depend_0:'NA', depend_1:'NA', depend_2:'NA', $
             depend_3:'NA', var_type:'NA', $
             coordinate_system:'sensor', $
             scaletyp:'NA', lablaxis:'NA',$
             labl_ptr_1:'NA',labl_ptr_2:'NA',labl_ptr_3:'NA', $
             form_ptr:'NA', monoton:'FALSE',var_notes:'None'}
     cdf_type = idl2cdftype(dvar, format_out = fmt, fillval_out = fll, validmin_out = vmn, validmax_out = vmx)
;Change types for CDF time variables
     If(vj eq 'epoch' Or vj Eq 'orbit_number_epoch') Then cdf_type = 'CDF_EPOCH'
     dtype = size(dvar, /type)
;probably the same for all vars
     vatt.catdesc = rv_vt[2, j]
     vatt.lablaxis = rv_vt[3, j]
     vatt.fieldnam = rv_vt[3, j] ;shorter name
     vatt.depend_0 = 'epoch'
     vatt.depend_time = 'time_unix'
     vatt.var_type='data'
     str_element, vatt, 'fillval', fll, /add
     str_element, vatt, 'format', fmt, /add
;Handle virtual variables separately
     If(vj Eq 'eflux_movie') Then Begin
        vatt.units='eV/(cm^2-s-sr-eV)'
        vatt.scaletyp='log'
        vatt.display_type = 'plasmagram>THUMBSIZE>166>xsz=4,ysz=7>xx=pitch_angle_median,y=energy_median,z=data'
        str_element, vatt, 'validmin', 0.0, /add
        str_element, vatt, 'validmax', 1.0e10, /add
        vatt.depend_2 = 'energy_median'
        vatt.depend_1 = 'pitch_angle_median'
        str_element, vatt, 'virtual', 'true', /add
        str_element, vatt, 'funct', 'alternate_view', /add
        str_element, vatt, 'component_0', 'eflux', /add
     Endif Else If(vj Eq 'eflux_byE_atA') Then Begin
        vatt.units='eV/(cm^2-s-sr-eV)'
        vatt.scaletyp='log'
        vatt.display_type = 'spectrogram>y=energy_median,z=eflux_byE_atA(2,*),z=eflux_byE_atA(8,*),z=eflux_byE_atA(14,*),z=eflux_byE_atA(20,*),z=eflux_byE_atA(26,*),z=eflux_byE_atA(32,*),z=eflux_byE_atA(50,*)'
        str_element, vatt, 'validmin', 0.0, /add
        str_element, vatt, 'validmax', 1.0e10, /add
        vatt.depend_2 = 'energy_median'
        vatt.depend_1 = 'pitch_angle_median'
        str_element, vatt, 'virtual', 'true', /add
        str_element, vatt, 'funct', 'alternate_view', /add
        str_element, vatt, 'component_0', 'eflux', /add
        vatt.labl_ptr_1 = 'eflux_bypitch_labl'
        vatt.labl_ptr_2 = 'eflux_byenergy_labl'        
     Endif Else If(vj Eq 'eflux_byA_atE') Then Begin
        vatt.units='eV/(cm^2-s-sr-eV)'
        vatt.scaletyp='log'
        vatt.display_type =  'spectrogram>y=compno_64,z=eflux_byA_atE(*,2),z=eflux_byA_atE(*,8),z=eflux_byA_atE(*,14),z=eflux_byA_atE(*,20),z=eflux_byA_atE(*,26),z=eflux_byA_atE(*,32),z=eflux_byA_atE(*,38),z=eflux_byA_atE(*,44),z=eflux_byA_atE(*,76)'
        str_element, vatt, 'validmin', 0.0, /add
        str_element, vatt, 'validmax', 1.0e10, /add
        vatt.depend_2 = 'energy_median'
        vatt.depend_1 = 'pitch_angle_median'
        str_element, vatt, 'virtual', 'true', /add
        str_element, vatt, 'funct', 'alternate_view', /add
        str_element, vatt, 'component_0', 'eflux', /add
        vatt.labl_ptr_1 = 'eflux_bypitch_labl'
        vatt.labl_ptr_2 = 'eflux_byenergy_labl'        
     Endif Else If(vj Eq 'energy_median') Then Begin
        vatt.units = 'eV'
        vatt.scaletyp = 'log'
        vatt.display_type = 'stack_plot'
        str_element, vatt, 'validmin', 0.0, /add
        str_element, vatt, 'validmax', 200000.0, /add
        str_element, vatt, 'scalemin', 1.0, /add
        str_element, vatt, 'scalemax', 100000.0, /add
        vatt.depend_1 = 'compno_64'
        vatt.labl_ptr_1 = 'angle_labl_64'
        str_element, vatt, 'virtual', 'true', /add
        str_element, vatt, 'funct', 'arr_slice', /add
        str_element, vatt, 'component_0', 'energy_full', /add
        str_element, vatt, 'arr_index', 16, /add
        str_element, vatt, 'arr_dim', 0, /add        
     Endif Else If(vj Eq 'pitch_angle_median') Then Begin
        vatt.units = 'degrees'
        vatt.scaletyp = 'linear'
        vatt.display_type = 'stack_plot'
        str_element, vatt, 'validmin',-360.0, /add
        str_element, vatt, 'validmax', 360.0, /add
        str_element, vatt, 'scalemin', -20.0, /add
        str_element, vatt, 'scalemax', 380.0, /add
        vatt.depend_1 = 'compno_64'
        vatt.labl_ptr_1 = 'angle_labl_64'
        str_element, vatt, 'virtual', 'true', /add
        str_element, vatt, 'funct', 'arr_slice', /add
        str_element, vatt, 'component_0', 'pitch_angle', /add
        str_element, vatt, 'arr_index', 24, /add
        str_element, vatt, 'arr_dim', 1, /add        
     Endif Else Begin
;fix valid mins and valid max's here
        If(vj Eq 'eflux') Then Begin
           str_element, vatt, 'validmin', 0.0, /add
           str_element, vatt, 'validmax', 1.0e10, /add
        Endif Else If(vj Eq 'epoch' Or vj Eq 'orbit_number_epoch') Then Begin
           str_element, vatt, 'fillval', -1.0d+31, /add_replace ;istp
           str_element, vatt, 'validmin', epoch_range[0], /add
           str_element, vatt, 'validmax', epoch_range[1], /add
        Endif Else If(vj Eq 'time_unix' Or vj Eq 'time_start' Or vj Eq 'time_end' $
                      Or vj Eq 'orbit_number_time') Then Begin
           str_element, vatt, 'validmin', date_range[0], /add
           str_element, vatt, 'validmax', date_range[1], /add
        Endif Else If(vj Eq 'theta_shift' Or vj Eq 'pitch_angle' Or vj Eq 'dpitch_angle' Or $
                      vj Eq 'theta_min' Or vj Eq 'theta_max') Then Begin
           str_element, vatt, 'validmin', -400.0, /add
           str_element, vatt, 'validmax', 400.0, /add
        Endif Else Begin
           str_element, vatt, 'validmin', vmn, /add
           str_element, vatt, 'validmax', vmx, /add
        Endelse
;data is log scaled, everything else is linear, set data, support data
;display type here
        IF(vj Eq 'data' Or vj Eq 'eflux') Then Begin
           vatt.scaletyp = 'log' 
           vatt.display_type = 'plasmagram>THUMBSIZE>166>xsz=4,ysz=7>xx=pitch_angle_median,y=energy_median,z=data'
        Endif Else Begin
           vatt.scaletyp = 'linear'
           vatt.display_type = 'time_series'
           If(vj eq 'bkg' Or vj Eq 'theta_shift' Or vj Eq 'pitch_angle' Or $
              vj Eq 'dpitch_angle' Or vj Eq 'theta_min' Or vj Eq 'theta_max' Or $
              vj Eq 'sc_pot') Then Begin
              dummy = 1         ;var type is already 'data'
           Endif Else vatt.var_type = 'support_data'
        Endelse
;Units
        If(is_tvar) Then Begin  ;Time variables
           vatt.units = 'sec'
        Endif Else Begin
           If(strpos(vj, 'time') Ne -1) Then vatt.units = 'sec' $ ;time interval sizes
           Else If(strpos(vj, 'theta') Ne -1 Or strpos(vj, 'pitch') Ne -1) Then vatt.units = 'degrees' $
           Else If(strpos(vj, 'energy') Ne -1) Then vatt.units = 'eV' $
           Else If(strpos(vj, 'omega') Ne -1) Then vatt.units = 'ster' $
           Else If(vj Eq 'sc_pot') Then vatt.units = 'volts' $
           Else If(vj Eq 'data') Then vatt.units = 'Counts' $
           Else If(vj Eq 'eflux') Then vatt.units = 'eV/(cm^2-s-sr-eV)' ;check this, checked 2016-10-24, jmm
        Endelse
           
;Depends and labels
        If(strpos(vj, 'orbit_number') Ne -1) Then Begin
           vatt.depend_time = 'orbit_number_time'
           vatt.depend_0 = 'orbit_number_epoch'
        Endif Else Begin
           vatt.depend_time = 'time_unix'
           vatt.depend_0 = 'epoch'
        Endelse
        If(vj Eq 'theta_shift') Then vatt.lablaxis = 'Angular shift' ;jmm, 2016-06-17
;Assign labels and components for vectors
        If(vj Eq 'data' Or vj Eq 'eflux' Or $
           vj Eq 'pitch_angle' Or vj Eq 'energy_full' Or $
           vj Eq 'denergy_full' Or vj Eq 'domega') Then Begin
;For ISTP compliance, it looks as if the depend's are switched,
;probably because we transpose it all in the file
;??? Check this ???
           vatt.depend_2 = 'energy_median'
           vatt.depend_1 = 'pitch_angle_median'
        Endif
;Time variables are monotonically increasing:
        If(is_tvar) Then vatt.monoton = 'INCREASE' Else vatt.monoton = 'FALSE'
     Endelse
;delete all 'NA' tags
     vatt_tags = tag_names(vatt)
     nvatt_tags = n_elements(vatt_tags)
     rm_tag = bytarr(nvatt_tags)
     For k = 0, nvatt_tags-1 Do Begin
        If(is_string(vatt.(k)) && vatt.(k) Eq 'NA') Then rm_tag[k] = 1b
     Endfor
     xtag = where(rm_tag Eq 1, nxtag)
     If(nxtag Gt 0) Then Begin
        tags_to_remove = vatt_tags[xtag]
        For k = 0, nxtag-1 Do str_element, vatt, tags_to_remove[k], /delete
     Endif
;Create and fill the variable structure
     vsj = {name:'', num:0, is_zvar:1, datatype:'', $
            type:0, numattr: -1, numelem: 1, recvary: 1b, $
            numrec:0L, ndimen: 0, d:lonarr(6), dataptr:ptr_new(), $
            attrptr:ptr_new()}
     vsj.name = vj
     vsj.datatype = cdf_type
     vsj.type = dtype
     vsj.numrec = num_dists
;It looks as if you do not include the time variation?
;No data if it's a virtual variable
     If(~is_virtual) Then Begin
        ndim = size(dvar, /n_dimen)
        dims = size(dvar, /dimen)
        vsj.ndimen = ndim-1
        If(ndim Gt 1) Then vsj.d[0:ndim-2] = dims[1:*]
        vsj.dataptr = ptr_new(dvar)
     Endif
     vsj.attrptr = ptr_new(vatt)
;Append the variables structure
     If(count Eq 0) Then vstr = vsj Else vstr = [vstr, vsj]
     count = count+1
  Endfor
;Now the non-record variables
  nrv = n_elements(nv_vt[0, *])
  For j = 0L, nrv-1 Do Begin
     vj = nv_vt[0, j]
     Have_tag = where(cvars Eq vj, nhave_tag)
     If(nhave_tag Gt 0) Then Begin
        dvar = cmn_dat.(have_tag)
;Set any 1d array value to a scalar, for ISTP
        If(n_elements(dvar) Eq 1) Then dvar = dvar[0]
     Endif Else Begin
;Case by case basis
        Case vj of
           'num_dists': Begin
              dvar = num_dists
           End        
           Else: Begin
              message, /info, 'Variable '+vj+' Unaccounted for.'
           End
        Endcase
     Endelse
     cdf_type = idl2cdftype(dvar, format_out = fmt, fillval_out = fll, validmin_out = vmn, validmax_out = vmx)
     dtype = size(dvar, /type)
;variable attributes here, but only the string attributes, the others
;depend on the data type, note that these are metadata, not support_data
     vatt = {catdesc:'NA', fieldnam:'NA', $
             units:'NA', var_type:'metadata', $
             coordinate_system:'sensor'}
     str_element, vatt, 'format', fmt, /add
;Don't need mins and maxes for string variables
     If(~is_string(dvar)) Then Begin
;angles from 0.0 t0 360.0
        If(vj Eq 'theta' Or vj Eq 'dtheta') Then Begin
           str_element, vatt, 'validmin', 0.0, /add
           str_element, vatt, 'validmax', 360.0, /add
        Endif Else Begin
           str_element, vatt, 'validmin', vmn, /add
           str_element, vatt, 'validmax', vmx, /add
        Endelse
        str_element, vatt, 'fillval', fll, /add
        str_element, vatt, 'scalemin', vmn, /add
        str_element, vatt, 'scalemax', vmx, /add
     Endif
     vatt.catdesc = nv_vt[2, j]
     vatt.fieldnam = nv_vt[0, j]
     If(vj Eq 'energy' Or vj Eq 'denergy') Then vatt.units = 'eV' $
     Else If(vj Eq 'theta' Or vj Eq 'dtheta') Then vatt.units = 'Degrees'

;Create and fill the variable structure
     vsj = {name:'', num:0, is_zvar:1, datatype:'', $
            type:0, numattr: -1, numelem: 1, recvary: 0b, $
            numrec:-1L, ndimen: 0, d:lonarr(6), dataptr:ptr_new(), $
            attrptr:ptr_new()}
     vsj.name = vj
     vsj.datatype = cdf_type
     vsj.type = dtype
;Include all dimensions
     ndim = size(dvar, /n_dimen)
     dims = size(dvar, /dimen)
     vsj.ndimen = ndim
     If(ndim Gt 0) Then vsj.d[0:ndim-1] = dims
     vsj.dataptr = ptr_new(dvar)
     vsj.attrptr = ptr_new(vatt)
;Append the variables structure
     If(count Eq 0) Then vstr = vsj Else vstr = [vstr, vsj]
     count = count+1
  Endfor
;Now compnos, need 96, 64
  ext_compno = [96, 64]
  vcompno = 'compno_'+strcompress(/remove_all, string(ext_compno))
  For j = 0, n_elements(vcompno)-1 Do Begin
     vj = vcompno[j]
     xj = strsplit(vj, '_', /extract)
     nj = Fix(xj[1])
;Component attributes
     vatt =  {catdesc:vj, fieldnam:vj, $
              fillval:0, format:'I3', $
              validmin:0, dict_key:'number', $
              validmax:255, var_type:'metadata'}
;Also a data array
     dvar = 1+indgen(nj)
;Create and fill the variable structure
     vsj = {name:'', num:0, is_zvar:1, datatype:'', $
            type:0, numattr: -1, numelem: 1, recvary: 0b, $
            numrec:-1L, ndimen: 0, d:lonarr(6), dataptr:ptr_new(), $
            attrptr:ptr_new()}
     vsj.name = vj
     vsj.datatype = 'CDF_INT2'
     vsj.type = 2
;Include all dimensions
     ndim = size(dvar, /n_dimen)
     dims = size(dvar, /dimen)
     vsj.ndimen = ndim
     If(ndim Gt 0) Then vsj.d[0:ndim-1] = dims
     vsj.dataptr = ptr_new(dvar)
     vsj.attrptr = ptr_new(vatt)
;Append the variables structure
     If(count Eq 0) Then vstr = vsj Else vstr = [vstr, vsj]
     count = count+1
  Endfor
;Labels now
  lablvars = ['energy_labl_96', 'angle_labl_64']
  For j = 0, n_elements(lablvars)-1 Do Begin
     vj = lablvars[j]
     xj = strsplit(vj, '_', /extract)
     nj = Fix(xj[2])
     aj = xj[0]+'@'+strupcase(xj[1])
     dvar = aj+strcompress(/remove_all, string(indgen(nj)))
     ndv = n_elements(dvar)
     numelem = strlen(dvar[ndv-1]) ;needed for numrec
     fmt = 'A'+strcompress(/remove_all, string(numelem))
;Label attributes
     vatt =  {catdesc:vj, fieldnam:vj, $
              format:fmt, dict_key:'label', $
              var_type:'metadata'}
;Create and fill the variable structure
     vsj = {name:'', num:0, is_zvar:1, datatype:'', $
            type:0, numattr: -1, numelem: 1, recvary: 0b, $
            numrec:-1L, ndimen: 0, d:lonarr(6), dataptr:ptr_new(), $
            attrptr:ptr_new()}
     vsj.name = vj
     vsj.datatype = 'CDF_CHAR'
     vsj.type = 1
     vsj.numelem = numelem
;Include all dimensions
     ndim = size(dvar, /n_dimen)
     dims = size(dvar, /dimen)
     vsj.ndimen = ndim
     If(ndim Gt 0) Then vsj.d[0:ndim-1] = dims
     vsj.dataptr = ptr_new(dvar)
     vsj.attrptr = ptr_new(vatt)
;Append the variables structure
     If(count Eq 0) Then vstr = vsj Else vstr = [vstr, vsj]
     count = count+1
  Endfor
;more labels
  vj = 'eflux_bypitch_labl'
  nj = 64
  dvar = ext1+'eflux @ PA '+strcompress(string(indgen(nj)+1), /remove_all)
  vatt =  {catdesc:'Energy Flux by Pitch Angle labels', $
           fieldnam:'Energy Flux by Pitch Angle labels', $
           format:'A29', dict_key:'label>angle', $
           var_type:'metadata'}
  vsj = {name:'', num:0, is_zvar:1, datatype:'', $
         type:0, numattr: -1, numelem: 1, recvary: 0b, $
         numrec:-1L, ndimen: 0, d:lonarr(6), dataptr:ptr_new(), $
         attrptr:ptr_new()}
  vsj.name = vj
  vsj.datatype = 'CDF_CHAR'
  vsj.type = 1
  vsj.numelem = nj
  ndim = size(dvar, /n_dimen)
  dims = size(dvar, /dimen)
  vsj.ndimen = ndim
  If(ndim Gt 0) Then vsj.d[0:ndim-1] = dims
  vsj.dataptr = ptr_new(dvar)
  vsj.attrptr = ptr_new(vatt)
  If(count Eq 0) Then vstr = vsj Else vstr = [vstr, vsj]
  count = count+1
  vj = 'eflux_byenergy_labl'
  nj = 96
  dvar = ext1+'eflux @ Energy '+strcompress(string(indgen(nj)+1), /remove_all)
  vatt =  {catdesc:'Energy Flux by Energy labels', $
           fieldnam:'Energy Flux by Energy labels', $
           format:'A33', dict_key:'label>energy', $
           var_type:'metadata'}
  vsj = {name:'', num:0, is_zvar:1, datatype:'', $
         type:0, numattr: -1, numelem: 1, recvary: 0b, $
         numrec:-1L, ndimen: 0, d:lonarr(6), dataptr:ptr_new(), $
         attrptr:ptr_new()}
  vsj.name = vj
  vsj.datatype = 'CDF_CHAR'
  vsj.type = 1
  vsj.numelem = nj
  ndim = size(dvar, /n_dimen)
  dims = size(dvar, /dimen)
  vsj.ndimen = ndim
  If(ndim Gt 0) Then vsj.d[0:ndim-1] = dims
  vsj.dataptr = ptr_new(dvar)
  vsj.attrptr = ptr_new(vatt)
  If(count Eq 0) Then vstr = vsj Else vstr = [vstr, vsj]
  count = count+1
  nvars = n_elements(vstr)
  natts = n_tags(global_att)+n_tags(vstr[0])

  inq = {ndims:0l, decoding:'HOST_DECODING', $
         encoding:'IBMPC_ENCODING', $
         majority:'COLUMN_MAJOR', maxrec:-1,$
         nvars:0, nzvars:nvars, natts:natts, dim:lonarr(1)}

;time resolution and UTC start and end
  If(num_dists Gt 0) Then Begin
     tres = 86400.0/num_dists
     tres = strcompress(string(tres, format = '(f8.1)'))+' sec'
  Endif Else tres = '   0.0 sec'
  global_att.time_resolution = tres

  otp_struct = {filename:'', g_attributes:global_att, inq:inq, nv:nvars, vars:vstr}

;Create filename and call cdf_save_vars.
  If(keyword_set(directory)) Then Begin
     dir = directory
     If(~is_string(file_search(dir))) Then file_mkdir, dir
     temp_string = strtrim(dir, 2)
     ll = strmid(temp_string, strlen(temp_string)-1, 1)
     If(ll Ne '/' And ll Ne '\') Then temp_string = temp_string+'/'
     dir = temporary(temp_string)
  Endif Else dir = './'

;SPDF requests full start time in the filename
  date = time_string(min(center_time), format=6)
  orb_string = string(long(cmn_dat.orbit_start), format = '(i5.5)')
  file0 = 'fa_esa_l2_'+ext+'_'+date+'_'+orb_string+'_'+sw_vsn_str+'.cdf'
  fullfile0 = dir+file0
  
  otp_struct.g_attributes.data_type = 'l2_'+ext+'>Level 2 data: '+cmn_dat.data_name
  otp_struct.g_attributes.logical_file_id = file0
  otp_struct.g_attributes.logical_source = 'fa_esa_l2_'+ext
;save the file -- full database management
  dummy = cdf_save_vars2(otp_struct, fullfile0, /no_file_id_update)
  If(~keyword_set(no_compression)) Then Begin
      spawn, '/usr/local/pkg/cdf-3.6.2_CentOS-6.7/bin/cdfconvert '+fullfile0+' '+fullfile0+' -blockingfactor optimal -compressnonepoch -compression cdf:none -delete'
  Endif

  Return
End
