;Helper function for eflux calculations
Function temp_mvn_sta_eflux, cmn_dat

  apid = strupcase(cmn_dat.apid)
  npts = n_elements(cmn_dat.time)
  iswp = cmn_dat.swp_ind
  ieff = cmn_dat.eff_ind
  iatt = cmn_dat.att_ind
  mlut = cmn_dat.mlut_ind
  nenergy = cmn_dat.nenergy
  nmass = cmn_dat.nmass
  nbins = cmn_dat.nbins
  ndef = cmn_dat.ndef
  nanode = cmn_dat.nanode
  If(apid Eq 'C0' Or apid Eq 'C2' Or apid Eq 'C4' Or apid Eq 'C6') Then Begin
     gf = reform(cmn_dat.gf[iswp,*,0]*((iatt eq 0)#replicate(1.,nenergy)) +$
                 cmn_dat.gf[iswp,*,1]*((iatt eq 1)#replicate(1.,nenergy)) +$
                 cmn_dat.gf[iswp,*,2]*((iatt eq 2)#replicate(1.,nenergy)) +$
                 cmn_dat.gf[iswp,*,3]*((iatt eq 3)#replicate(1.,nenergy)), npts*nenergy)#replicate(1.,nmass)
     gf = cmn_dat.geom_factor*reform(gf,npts,nenergy,nmass)
     eff = cmn_dat.eff[ieff,*,*]
     dt = cmn_dat.integ_t#replicate(1.,nenergy*nmass)
     eflux = (cmn_dat.data-cmn_dat.bkg)*cmn_dat.dead/(gf*eff*dt)
  Endif Else If(apid Eq 'C8' Or apid Eq 'CA') Then Begin
     gf = reform(cmn_dat.gf[iswp,*,*,0]*((iatt eq 0)#replicate(1.,nenergy*nbins)) +$
                 cmn_dat.gf[iswp,*,*,1]*((iatt eq 1)#replicate(1.,nenergy*nbins)) +$
                 cmn_dat.gf[iswp,*,*,2]*((iatt eq 2)#replicate(1.,nenergy*nbins)) +$
                 cmn_dat.gf[iswp,*,*,3]*((iatt eq 3)#replicate(1.,nenergy*nbins)), npts,nenergy,nbins)
     gf = cmn_dat.geom_factor*gf
     eff = cmn_dat.eff[ieff,*,*]
     dt = cmn_dat.integ_t#replicate(1.,nenergy*nbins)
     eflux = (cmn_dat.data-cmn_dat.bkg)*cmn_dat.dead/(gf*eff*dt)
  Endif Else Begin
     gf = reform(cmn_dat.gf[iswp,*,*,0]*((iatt eq 0)#replicate(1.,nenergy*nbins)) +$
                 cmn_dat.gf[iswp,*,*,1]*((iatt eq 1)#replicate(1.,nenergy*nbins)) +$
                 cmn_dat.gf[iswp,*,*,2]*((iatt eq 2)#replicate(1.,nenergy*nbins)) +$
                 cmn_dat.gf[iswp,*,*,3]*((iatt eq 3)#replicate(1.,nenergy*nbins)), npts*nenergy*nbins)$
          #replicate(1.,nmass)
     gf = cmn_dat.geom_factor*reform(gf,npts,nenergy,nbins,nmass)
     eff = cmn_dat.eff[ieff,*,*,*]
     dt = cmn_dat.integ_t#replicate(1.,nenergy*nbins*nmass)
     eflux = (cmn_dat.data-cmn_dat.bkg)*cmn_dat.dead/(gf*eff*dt)
  Endelse
  Return, float(eflux)
End

;+
;NAME:
; mvn_sta_cmn_l2gen.pro
;PURPOSE:
; turn a MAVEN STA common block into a L2 CDF.
;CALLING SEQUENCE:
; mvn_sta_cmn_l2gen, cmn_dat
;INPUT:
; cmn_dat = a structrue with the data:
; tags are:   
;   PROJECT_NAME    STRING    'MAVEN'
;   SPACECRAFT      STRING    '0'
;   DATA_NAME       STRING    'C6 Energy-Mass'
;   APID            STRING    'C6'
;   UNITS_NAME      STRING    'counts'
;   UNITS_PROCEDURE STRING    'mvn_sta_convert_units'
;   VALID           INT       Array[21600]
;   QUALITY_FLAG    INT       Array[21600]
;   TIME            DOUBLE    Array[21600]
;   END_TIME        DOUBLE    Array[21600]
;   DELTA_T         DOUBLE    Array[21600]
;   INTEG_T         DOUBLE    Array[21600]
;   EPROM_VER       INT       Array[21600]
;   HEADER          LONG      Array[21600]
;   MODE            INT       Array[21600]
;   RATE            INT       Array[21600]
;   SWP_IND         INT       Array[21600]
;   MLUT_IND        INT       Array[21600]
;   EFF_IND         INT       Array[21600]
;   ATT_IND         INT       Array[21600]
;   NENERGY         INT             32
;   ENERGY          FLOAT     Array[9, 32, 64]
;   DENERGY         FLOAT     Array[9, 32, 64]
;   NBINS           INT              1
;   BINS            INT       Array[1]
;   NDEF            INT              1
;   NANODE          INT              1
;   THETA           FLOAT           0.00000
;   DTHETA          FLOAT           90.0000
;   PHI             FLOAT           0.00000
;   DPHI            FLOAT           360.000
;   DOMEGA          FLOAT           8.88577
;   GF              FLOAT     Array[9, 32, 4]
;   EFF             FLOAT     Array[128, 32, 64]
;   GEOM_FACTOR     FLOAT       0.000195673
;   DEAD1           FLOAT           420.000
;   DEAD2           FLOAT           660.000
;   DEAD3           FLOAT           460.000
;   NMASS           INT             64
;   MASS            FLOAT         0.0104389
;   MASS_ARR        FLOAT     Array[9, 32, 64]
;   TOF_ARR         FLOAT     Array[5, 32, 64]
;   TWT_ARR         FLOAT     Array[5, 32, 64]
;   CHARGE          FLOAT           1.00000
;   SC_POT          FLOAT     Array[21600]
;   MAGF            FLOAT     Array[21600, 3]
;   QUAT_SC         FLOAT     Array[21600, 4]
;   QUAT_MSO        FLOAT     Array[21600, 4]
;   BINS_SC         LONG      Array[21600]
;   POS_SC_MSO      FLOAT     Array[21600, 3]
;   BKG             FLOAT     Array[21600, 32, 64]
;   DEAD            FLOAT     Array[21600, 32, 64]
;   DATA            DOUBLE    Array[21600, 32, 64]
; All of this has to go into the CDF, also Epoch, tt200, MET time
; variables; some of the names are changed to titles given in the SIS
; Data is changed from double to float prior to output
;KEYWORDS:
; otp_struct = this is the structure that is passed into
;              cdf_save_vars to creat the file
; directory = Set this keyword to direct the output into this
;             directory; the default is to populate the MAVEN STA
;             database. /disks/data/maven/pfp/sta/l2
; no_compression = if set, do not compress the CDF file
;HISTORY:
; 28-apr-2014, jmm, jimm@ssl.berkeley.edu
; jun-2014, jmm added compression - no_compression
; 10-jun-2014, jmm, added delete keyword,changed compression scheme
; 11-jun-2014, changed filenaming no more R value
; 18-jun-2014, added changes suggested by Bob McGuire, fixed epoch and
; tt200 attribute types
; 7-7-2014, jmm, deleted no_cdfconvert option, added md5sum
; 22-jul-2014, jmm, added revisoining
; 2-oct-2014, jmm, ISTP compliance
; 1-nov-2014, jmm, PDS compliance
; 6-nov-2014, jmm, Corrects clock drift 
; 22-dec-2014, jmm, added eprom_ver and header
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-10-21 15:41:49 -0700 (Wed, 21 Oct 2015) $
; $LastChangedRevision: 19131 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/l2util/mvn_sta_cmn_l2gen.pro $
;-
Pro mvn_sta_cmn_l2gen, cmn_dat, otp_struct = otp_struct, directory = directory, $
                       no_compression = no_compression, _extra = _extra

;Need to keep track of spice kernels
  common mvn_spc_met_to_unixtime_com, cor_clkdrift, icy_installed, kernel_verified, time_verified, sclk, tls

;Keep track of software versioning here
  sw_vsn = mvn_sta_current_sw_version()
  sw_vsn_str = 'v'+string(sw_vsn, format='(i2.2)')

  If(~is_struct(cmn_dat)) Then Begin
     message,/info,'No Input Structure'
     Return
  Endif
;First, global attributes
  global_att = {Acknowledgment:'None', $
                Data_type:'CAL>Calibrated', $
                Data_version:'0', $
                Descriptor:'STATIC>Supra-Thermal Thermal Ion Composition Particle Distributions', $
                Discipline:'Space Physics>Planetary Physics>Particles', $
                File_naming_convention: 'mvn_descriptor_datatype_yyyyMMdd', $
                Generated_by:'MAVEN SOC' , $
                Generation_date:'2014-04-28' , $
                HTTP_LINK:'http://lasp.colorado.edu/home/maven/', $
                Instrument_type:'Particles (space)' , $
                LINK_TEXT:'General Information about the MAVEN mission' , $
                LINK_TITLE:'MAVEN home page' , $
                Logical_file_id:'mvn_sta_l2_c6_00000000_v00_r00.cdf' , $
                Logical_source:'urn:nasa:pds:maven.static.c:data.c6_2e64m' , $
                Logical_source_description:'MAVEN Supra-Thermal And Thermal Ion Composition Particle Distributions', $
                Mission_group:'MAVEN' , $
                MODS:'Rev-1 2014-04-28' , $
                PI_name:'J. P. McFadden', $
                PI_affiliation:'U.C. Berkeley Space Sciences Laboratory', $
                PDS_collection_id:'MAVEN', $
                PDS_sclk_start_count:0.0d0, $
                PDS_sclk_stop_count:0.0d0, $
                PDS_start_time:'YYYY-MM-DDThh:mm:ss.sssZ', $
                PDS_stop_time:'YYYY-MM-DDThh:mm:ss.sssZ', $
                Spacecraft_clock_kernel:'', $
                Leapseconds_kernel:'', $
                Planet:'Mars', $
                Project:'MAVEN', $
                Rules_of_use:'Open Data for Scientific Use' , $
                Source_name:'MAVEN>Mars Atmosphere and Volatile Evolution Mission', $
                TEXT:'STATIC>Supra-Thermal And Thermal Ion Composition Particle Distributions', $
                Time_resolution:'4 sec', $
                Title:'MAVEN STATIC Ion Spectra'}

;Now variables and attributes
  cvars = strlowcase(tag_names(cmn_dat))

;Need to relabel if nbins Eq 1
  If(cmn_dat.nbins Eq 1) Then Begin
     nenbnm = 'NENERGY, NMASS'
     nenbna = 'NENERGY, NATT'
  Endif Else Begin
     nenbnm = 'NENERGY, NBINS, NMASS'
     nenbna = 'NENERGY, NBINS, NMASS'
  Endelse

; Here are variable names, type, catdesc, and lablaxis, from the SIS
  rv_vt =  [['EPOCH', 'TT2000', 'UTC time from 01-Jan-2000 12:00:00.000 including leap seconds), one element per ion distribution (NUM_DISTS elements)', 'TT2000'], $
            ['TIME_MET', 'DOUBLE', 'Mission elapsed time for this data record, one element per ion distribution (NUM_DISTS elements)', 'Mission Elapsed Time'], $
            ['TIME_EPHEMERIS', 'DOUBLE', 'Time used by SPICE program (NUM_DISTS elements)', 'SPICE Ephemeris Time'], $
            ['TIME_UNIX', 'DOUBLE', 'Unix time (elapsed seconds since 1970-01-01/00:00 without leap seconds) for this data record, one element per ion distribution. This time is the center time of data collection. (NUM_DISTS elements)', 'Unix Time'], $
            ['TIME_START', 'DOUBLE', 'Unix time at the start of data collection. (NUM_DISTS elements)', 'Interval start time (unix)'], $
            ['TIME_END', 'DOUBLE', 'Unix time at the end of data collection. (NUM_DISTS elements)', 'Interval end time (unix)'], $
            ['TIME_DELTA', 'DOUBLE', 'Averaging time. (TIME_END - TIME_START). (NUM_DISTS elements).', 'Averaging time'], $
            ['TIME_INTEG', 'DOUBLE', 'Integration time. (TIME_DELTA/N_ENERGY). (NUM_DISTS elements).', 'Integration time'], $
            ['EPROM_VER', 'INTEGER', 'An integer designating the version of the flight eprom load. (NUM_DISTS elements)', 'Eprom version'], $
            ['HEADER', 'LONG', 'A long integer that consists of bytes 12-15 in data packet header. See MAVEN_PF_FSW_021_CTM.xls for definition of header bits. (NUM_DISTS elements)', 'Header'], $
            ['VALID', 'INTEGER', 'Validity flag codes valid data (bit 0), test pulser on (bit 1), diagnostic mode (bit 2), data compression type (bit 3-4), packet compression (bit 5) (NUM_DISTS elements)', ' Valid flag'], $
            ['MODE', 'INTEGER', 'Decoded mode number. (NUM_DISTS elements)', 'Mode number'], $
            ['RATE', 'INTEGER', 'Decoded telemetry rate number. (NUM_DISTS elements)', 'Telemetry rate number'], $
            ['SWP_IND', 'INTEGER', 'Index that identifies the energy and deflector sweep look up tables (LUT) for the sensor. SWP_IND is an index that selects the following support data arrays: ENERGY, DENERGY, THETA, DTHETA, PHI, DPHI, DOMEGA, GF and MASS_ARR. (NUM_DISTS elements), SWP_IND Le NSWP', 'Sweep index'], $
            ['MLUT_IND', 'INTEGER', 'Index that identifies the onboard mass look up table (MLUT). MLUT_IND is an index that selects the following support data: TOF_ARR. (NUM_DISTS elements) MLUT Le NMLUT', 'MLUT index'], $
            ['EFF_IND', 'INTEGER', 'Index that identifies the efficiency calibration table to be used. EFF_IND is an index that selects the following support data: EFF. (NUM_DISTS elements) EFF_IND Le NEFF', 'Efficiency index'], $
            ['ATT_IND', 'INTEGER', 'Index that identifies the attenuator state (0 = no attenuation, 1 = electrostatic attenuation, 2 = mechanical attenuation, 3 = mechanical and electrostatic attenuation). (NUM_DISTS elements)', 'Attenuator state'], $
            ['SC_POT', 'FLOAT', 'Spacecraft potential (NUM_DISTS elements)', 'Spacecraft potential'], $
            ['MAGF', 'FLOAT', 'Magnetic field vector with dimension (NUM_DISTS, 3)', 'Magnetic field'], $
            ['QUAT_SC', 'FLOAT', 'Quaternion elements to rotate from STATIC coordinates (same as APP coordinates) to SC coordinates (NUM_DISTS, 3)', 'Quaternion to SC'], $
            ['QUAT_MSO', 'FLOAT', 'Quaternion elements to rotate from STATIC coordinates (same as APP coordinates) to MSO coordinates (NUM_DISTS, 3)', 'Quaternion to MSO'], $
            ['BINS_SC', 'INTEGER', 'Integer array of 1s and 0s with dimension (NUM_DISTS, NBINS) with 0s used to identify angle bins that include spacecraft surfaces. If NBINS=1, then BINS_SC is used to identify those times, value=0, when the spacecraft is in STATICs FOV.', 'Bins flag'], $
            ['POS_SC_MSO', 'FLOAT', 'Spacecraft position in MSO coordinates with dimension (NUM_DISTS, 3)', 'SC position MSO'], $
            ['BKG', 'FLOAT', 'Background counts array with dimensions (NUM_DISTS, '+nenbnm+')', 'Background counts'], $
            ['DEAD', 'FLOAT', 'Dead time correction array with dimensions (NUM_DISTS, '+nenbnm+'), values 0.0 to 1.0, divide by this to correct.', 'Dead_time correction'], $
            ['DATA', 'FLOAT', 'Counts array with dimensions (NUM_DISTS, '+nenbnm+')', 'Data counts'], $
            ['EFLUX', 'FLOAT', 'Differential energy flux array with dimensions (NUM_DISTS, '+nenbnm+')', 'Energy flux'], $
            ['QUALITY_FLAG', 'INTEGER', 'Quality flag (NUM_DISTS elements)', 'Quality flag']]
;Use Lower case for variable names
  rv_vt[0, *] = strlowcase(rv_vt[0, *])

;No need for lablaxis values here, just use the name
  nv_vt = [['PROJECT_NAME', 'STRING', 'MAVEN'], $
           ['SPACECRAFT', 'STRING', '0'], $
           ['DATA_NAME', 'STRING', 'XX YYY where XX is the APID and YYY is the array abbreviation (64e2m, 32e32m, etc.)'], $
           ['APID', 'STRING', 'XX, where XX is the APID'], $
           ['UNITS_NAME', 'STRING', 'eflux'], $
           ['UNITS_PROCEDURE', 'STRING', 'mvn_convert_sta_units, name of IDL routine used for units conversion '], $
           ['NUM_DISTS', 'INTEGER', 'Number of measurements or times in the file'], $
           ['NENERGY', 'INTEGER', 'Number of energy bins'], $
           ['NBINS', 'INTEGER', 'Number of solid angle bins'], $
           ['NMASS', 'INTEGER', 'Number of mass bins'], $
           ['NDEF', 'INTEGER', 'Number of deflector angle bins'], $
           ['NANODE', 'INTEGER', 'Number of anode bins'], $
           ['NATT', 'INTEGER', 'Number of attenuator states: 4 '], $
           ['NSWP', 'INTEGER', 'Number of sweep tables - will increase over mission as new sweep modes are added'], $
           ['NEFF', 'INTEGER', 'Number of efficiency arrays - will increase over mission as sensor degrades'], $
           ['NMLUT', 'INTEGER', 'Number of MLUT tables - will increase over mission as new modes are developed'], $
           ['BINS', 'INTEGER', 'Array with dimension NBINS containing 1 OR 0 used to flag bad solid angle bins'], $
           ['ENERGY', 'FLOAT', 'Energy array with dimension (NSWP, '+nenbnm+')'], $
           ['DENERGY', 'FLOAT', 'Delta Energy array with dimension (NSWP,  '+nenbnm+')'], $
           ['THETA', 'FLOAT', 'Angle array with with dimension (NSWP,  '+nenbnm+')'], $
           ['DTHETA', 'FLOAT', 'Delta Angle array with dimension (NSWP,  '+nenbnm+')'], $
           ['PHI', 'FLOAT', 'Angle array with dimension (NSWP,  '+nenbnm+')'], $
           ['DPHI', 'FLOAT', 'Delta Angle array with dimension (NSWP,  '+nenbnm+')'], $
           ['DOMEGA', 'FLOAT', 'Delta Solid Angle array with dimension (NSWP, '+nenbnm+')'], $
           ['GF', 'FLOAT', 'Geometric Factor array with dimension (NSWP, '+nenbna+')'], $
           ['EFF', 'FLOAT', 'Efficiency array with dimension (NEFF, '+nenbnm+')'], $
           ['MASS_ARR', 'FLOAT', 'Mass array with dimension (NSWP, '+nenbnm+'). Nominal mass of a mass bin in units of AMUs based on TOF. This array is not integer AMU.'], $
           ['TOF_ARR', 'FLOAT', 'Time-of-flight (TOF) array with dimension (NMLUT, '+nenbnm+'). Gives average TOF value for mass bins.'], $
           ['TWT_ARR', 'FLOAT', 'Time-of-flight Weight (TWT) array with dimension (NMLUT, '+nenbnm+'). Gives number of TOF bins in a given mass bin. Used for normalizing a mass spectra.'], $
           ['GEOM_FACTOR', 'FLOAT', 'Geometric factor of a single 22.5 degree sector'], $
           ['MASS', 'FLOAT', 'Proton mass (0.01044) in units of MeV/c2'], $
           ['CHARGE', 'FLOAT', 'Proton charge (1)'], $
           ['DEAD_TIME_1', 'FLOAT', 'Dead time for processed events. Dead time corrections are generally not necessary. Corrections require use of STATIC APID DA rate packets.'], $
           ['DEAD_TIME_2', 'FLOAT', 'Dead time for rejected events. Dead time corrections are generally not necessary. Corrections require use of STATIC APID DA rate packets.'], $
           ['DEAD_TIME_3', 'FLOAT', 'Dead time for stop-no-start events. Dead time corrections are generally not necessary. Corrections require use of STATIC APID DA rate packets.']]
;Use Lower case for variable names
  nv_vt[0, *] = strlowcase(nv_vt[0, *])

;Create variables for epoch, tt_2000, MET, hacked from mvn_pf_make_cdf.pro
  cdf_leap_second_init
  date_range = time_double(['2013-11-18/00:00','2040-12-31/23:59'])
  met_range = date_range-date_range[0]
  epoch_range = time_epoch(date_range)
  et_range = time_ephemeris(date_range)
  tt2000_range = long64((add_tt2000_offset(date_range)-time_double('2000-01-01/12:00'))*1e9)

;If TIME_MET is in the structure, then we're working from L2
;files, use that version, and recalculate center, start and end times,
;this is done to ensure that the latest SPICE clock kernel is used
;during reprocessing
  If(tag_exist(cmn_dat, 'met')) Then Begin
     met_center = cmn_dat.met
     center_time = mvn_spc_met_to_unixtime(met_center)
     offset = center_time - 0.5*(cmn_dat.time+cmn_dat.end_time)
     cmn_dat.time = cmn_dat.time+offset
     cmn_dat.end_time = cmn_dat.end_time+offset
     date = time_string(median(center_time), precision=-3, format=6)
     num_dists = n_elements(center_time)
  Endif Else Begin
;Use center time for time variables
     center_time = 0.5*(cmn_dat.time+cmn_dat.end_time)
;Grab the date, and clip anything plus or minus 10 minutes from the
;start or end of the date
     date = time_string(median(center_time), precision=-3, format=6)
     trange = time_double(date)+[-600.0d0, 87000.0d0]
     cmn_dat = mvn_sta_cmn_tclip(temporary(cmn_dat), trange)
;Reset center time
     center_time = 0.5*(cmn_dat.time+cmn_dat.end_time)
     num_dists = n_elements(center_time)
;met_center at the spacecraft
     timespan, date, 1
     met_center = mvn_spc_met_to_unixtime(center_time, /reverse)
     Endelse
;Initialize
  otp_struct = -1
  count = 0L
;First handle RV variables
  lrv = n_elements(rv_vt[0, *])
  For j = 0L, lrv-1 Do Begin
;Either the name is in the common block or not, names not in the
;common block have to be dealt with as special cases. Vectors will
;need label and component variables
     is_tvar = 0b
     vj = rv_vt[0, j]
     Have_tag = where(cvars Eq vj, nhave_tag)
     If(nhave_tag Gt 0) Then Begin
        dvar = cmn_dat.(have_tag)
     Endif Else Begin
;Case by case basis
        Case vj of
           'epoch': Begin
              dvar = double(long64((add_tt2000_offset(center_time)-time_double('2000-01-01/12:00'))*1e9))
              is_tvar = 1b
           End
           'time_met': Begin
              dvar = met_center
              is_tvar = 1b
           End
           'time_ephemeris': Begin
              dvar = time_ephemeris(center_time)
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
           'eflux': Begin       ;eflux is calculated
              dvar = temp_mvn_sta_eflux(cmn_dat)
           End
           Else: Begin
              message, /info, 'Variable '+vj+' Unaccounted for.'
           End
        Endcase
     Endelse
;change data to float from double
     if(vj eq 'data') then dvar = float(dvar) 

     cdf_type = idl2cdftype(dvar, format_out = fmt, fillval_out = fll, validmin_out = vmn, validmax_out = vmx)
;Change types for CDF time variables
     If(vj eq 'epoch') Then cdf_type = 'CDF_TIME_TT2000'

     dtype = size(dvar, /type)
;variable attributes here, but only the string attributes, the others
;depend on the data type
     vatt = {catdesc:'NA', display_type:'NA', fieldnam:'NA', $
             units:'None', depend_time:'NA', $
             depend_0:'NA', depend_1:'NA', depend_2:'NA', $
             depend_3:'NA', var_type:'NA', $
             coordinate_system:'sensor', $
             scaletyp:'NA', lablaxis:'NA',$
             labl_ptr_1:'NA',labl_ptr_2:'NA',labl_ptr_3:'NA', $
             form_ptr:'NA', monoton:'NA',var_notes:'None'}

;fix fill vals, valid mins and valid max's here
     str_element, vatt, 'fillval', fll, /add
     str_element, vatt, 'format', fmt, /add
     If(vj Eq 'epoch') Then Begin
        xtime = time_double('9999-12-31/23:59:59.999')
        xtime = long64((add_tt2000_offset(xtime)-time_double('2000-01-01/12:00'))*1e9)
        str_element, vatt, 'fillval', xtime, /add_replace
        str_element, vatt, 'validmin', tt2000_range[0], /add
        str_element, vatt, 'validmax', tt2000_range[1], /add
     Endif Else If(vj Eq 'time_met') Then Begin
        str_element, vatt, 'validmin', met_range[0], /add
        str_element, vatt, 'validmax', met_range[1], /add
     Endif Else If(vj Eq 'time_ephemeris') Then Begin
        str_element, vatt, 'validmin', et_range[0], /add
        str_element, vatt, 'validmax', et_range[1], /add
     Endif Else If(vj Eq 'time_unix' Or vj Eq 'time_start' Or vj Eq 'time_end') Then Begin
        str_element, vatt, 'validmin', date_range[0], /add
        str_element, vatt, 'validmax', date_range[1], /add
     Endif Else Begin
        str_element, vatt, 'validmin', vmn, /add
        str_element, vatt, 'validmax', vmx, /add
;scalemin and scalemax depend on the variable's values
        str_element, vatt, 'scalemin', vmn, /add
        str_element, vatt, 'scalemax', vmx, /add
        ok = where(finite(dvar), nok)
        If(nok Gt 0) Then Begin
           vatt.scalemin = min(dvar[ok])
           vatt.scalemax = max(dvar[ok])
        Endif
     Endelse
     vatt.catdesc = rv_vt[2, j]
;data is log scaled, everything else is linear, set data, support data
;display type here
     IF(vj Eq 'data' Or vj Eq 'bkg' Or vj Eq 'eflux') Then Begin
        vatt.scaletyp = 'log' 
        vatt.display_type = 'spectrogram'
        vatt.var_type = 'data'
     Endif Else Begin
        vatt.scaletyp = 'linear'
        vatt.display_type = 'time_series'
        vatt.var_type = 'support_data'
     Endelse

     vatt.fieldnam = rv_vt[3, j] ;shorter name
;Units
     If(is_tvar) Then Begin ;Time variables
        If(vj Eq 'epoch') Then vatt.units = 'nanosec' Else vatt.units = 'sec'
     Endif Else Begin
        If(strpos(vj, 'time') Ne -1) Then vatt.units = 'sec' $ ;time interval sizes
        Else If(vj Eq 'sc_pot') Then vatt.units = 'volts' $
        Else If(vj Eq 'magf') Then vatt.units = 'nT' $
        Else If(vj Eq 'data' Or vj Eq 'bkg') Then vatt.units = 'Counts' $
        Else If(vj Eq 'eflux') Then vatt.units = 'eV/sr/sec' ;check this
     Endelse

;Depends and labels
     vatt.depend_time = 'time_unix'
     vatt.depend_0 = 'epoch'
     vatt.lablaxis = rv_vt[3, j]

;Assign labels and components for vectors
     If(vj Eq 'magf') Then Begin
        vatt.depend_1 = 'compno_3'
        vatt.labl_ptr_1 = 'magf_labl'
     Endif Else If(vj Eq 'pos_sc_mso') Then Begin
        vatt.depend_1 = 'compno_3'
        vatt.labl_ptr_1 = 'pos_sc_mso_labl'
     Endif Else If(vj Eq 'quat_sc') Then Begin
        vatt.depend_1 = 'compno_4'
        vatt.labl_ptr_1 = 'quat_sc_labl'
     Endif Else If(vj Eq 'quat_mso') Then Begin
        vatt.depend_1 = 'compno_4'
        vatt.labl_ptr_1 = 'quat_mso_labl'
     Endif Else IF(vj Eq 'data' Or vj Eq 'bkg' Or vj Eq 'eflux' Or vj Eq 'dead') Then Begin
       If(cmn_dat.nbins Eq 1) Then Begin
;For ISTP compliance, it looks as if the depend's are switched,
;probably because we transpose it all in the file
           vatt.depend_2 = 'compno_'+strcompress(/remove_all, string(cmn_dat.nenergy))
           vatt.depend_1 = 'compno_'+strcompress(/remove_all, string(cmn_dat.nmass))
           vatt.labl_ptr_2 = vj+'_energy_labl_'+strcompress(/remove_all, string(cmn_dat.nenergy))
           vatt.labl_ptr_1 = vj+'_mass_labl_'+strcompress(/remove_all, string(cmn_dat.nmass))
        Endif Else If(cmn_dat.nmass Eq 1) Then Begin
           vatt.depend_2 = 'compno_'+strcompress(/remove_all, string(cmn_dat.nenergy))
           vatt.depend_1 = 'compno_'+strcompress(/remove_all, string(cmn_dat.nbins))
           vatt.labl_ptr_2 = vj+'_energy_labl_'+strcompress(/remove_all, string(cmn_dat.nenergy))
           vatt.labl_ptr_1 = vj+'_bin_labl_'+strcompress(/remove_all, string(cmn_dat.nbins))
        Endif Else Begin
           vatt.depend_3 = 'compno_'+strcompress(/remove_all, string(cmn_dat.nenergy))
           vatt.depend_2 = 'compno_'+strcompress(/remove_all, string(cmn_dat.nbins))
           vatt.depend_1 = 'compno_'+strcompress(/remove_all, string(cmn_dat.nmass))
           vatt.labl_ptr_3 = vj+'_energy_labl_'+strcompress(/remove_all, string(cmn_dat.nenergy))
           vatt.labl_ptr_2 = vj+'_bin_labl_'+strcompress(/remove_all, string(cmn_dat.nbins))
           vatt.labl_ptr_1 = vj+'_mass_labl_'+strcompress(/remove_all, string(cmn_dat.nmass))
        Endelse
     Endif
 
;Time variables are monotonically increasing:
     If(is_tvar) Then vatt.monoton = 'INCREASE' Else vatt.monoton = 'FALSE'

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
     ndim = size(dvar, /n_dimen)
     dims = size(dvar, /dimen)
     vsj.ndimen = ndim-1
     If(ndim Gt 1) Then vsj.d[0:ndim-2] = dims[1:*]
     vsj.dataptr = ptr_new(dvar)
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
           'natt': Begin
              dvar = fix(4)
           End
           'nswp': Begin
              dvar = fix(n_elements(cmn_dat.energy[*,0,0]))
           End
           'neff': Begin
              dvar = fix(n_elements(cmn_dat.eff[*,0,0]))
           End
           'nmlut': Begin
              dvar = fix(n_elements(cmn_dat.tof_arr[*,0,0]))
           End
           'dead_time_1': Begin
              dvar = cmn_dat.dead1
           End
           'dead_time_2': Begin
              dvar = cmn_dat.dead2
           End
           'dead_time_3': Begin
              dvar = cmn_dat.dead3
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
        str_element, vatt, 'fillval', fll, /add
        str_element, vatt, 'validmin', vmn, /add
        str_element, vatt, 'validmax', vmx, /add
;scalemin and scalemax depend on the variable's values
        str_element, vatt, 'scalemin', vmn, /add
        str_element, vatt, 'scalemax', vmx, /add
        ok = where(finite(dvar), nok)
        If(nok Gt 0) Then Begin
           vatt.scalemin = min(dvar[ok])
           vatt.scalemax = max(dvar[ok])
        Endif
     Endif
     vatt.catdesc = nv_vt[2, j]
     vatt.fieldnam = nv_vt[0, j]
     If(vj Eq 'energy' Or vj Eq 'denergy') Then vatt.units = 'eV' $
     Else If(vj Eq 'theta' Or vj Eq 'dtheta') Then vatt.units = 'Degrees' $
     Else If(vj Eq 'phi' Or vj Eq 'dphi') Then vatt.units = 'Degrees' $
     Else IF(vj Eq 'domega') Then vatt.units = 'Steradians' $
     Else If(vj Eq 'mass_arr') Then vatt.units = 'AMU' $
     Else If(vj Eq 'mass') Then vatt.units = 'MeV/c^2'

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
     
;Now compnos, need 3, 4, nenergy, nbin, nmass, but only unique ones,
;and you only need compno_1 if nenergy is 1
  ext_compno = [3, 4, cmn_dat.nenergy]
  If(cmn_dat.nbins Gt 1) Then ext_compno = [ext_compno, cmn_dat.nbins]
  If(cmn_dat.nmass Gt 1) Then ext_compno = [ext_compno, cmn_dat.nmass]
  ss0 = sort(ext_compno)
  ext_compno = ext_compno(ss0)
  ss = uniq(ext_compno)
  ext_compno = ext_compno[ss]
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
  lablvars = ['magf_labl', 'pos_sc_mso_labl', 'quat_sc_labl', 'quat_mso_labl', $
              'data_energy_labl_'+strcompress(/remove_all, string(cmn_dat.nenergy)), $
              'bkg_energy_labl_'+strcompress(/remove_all, string(cmn_dat.nenergy)), $
              'eflux_energy_labl_'+strcompress(/remove_all, string(cmn_dat.nenergy)), $
              'dead_energy_labl_'+strcompress(/remove_all, string(cmn_dat.nenergy))]
  If(cmn_dat.nbins Gt 1) Then Begin
     lablvars = [lablvars, $
              'data_bin_labl_'+strcompress(/remove_all, string(cmn_dat.nbins)), $
              'bkg_bin_labl_'+strcompress(/remove_all, string(cmn_dat.nbins)), $
              'eflux_bin_labl_'+strcompress(/remove_all, string(cmn_dat.nbins)), $
              'dead_bin_labl_'+strcompress(/remove_all, string(cmn_dat.nbins))]
  Endif
  If(cmn_dat.nmass Gt 1) Then Begin
     lablvars = [lablvars, $
              'data_mass_labl_'+strcompress(/remove_all, string(cmn_dat.nmass)), $
              'bkg_mass_labl_'+strcompress(/remove_all, string(cmn_dat.nmass)), $
              'eflux_mass_labl_'+strcompress(/remove_all, string(cmn_dat.nmass)), $
              'dead_mass_labl_'+strcompress(/remove_all, string(cmn_dat.nmass))]
  Endif

  For j = 0, n_elements(lablvars)-1 Do Begin
     vj = lablvars[j]
     Case vj of
        'magf_labl':Begin
           dvar = ['Bx', 'By', 'Bz']
        End
        'pos_sc_mso_labl':Begin
           dvar = ['X (MSO)', 'Y (MSO)', 'Z (MSO)']
        End
        'quat_sc_labl':Begin
           dvar = ['Q1 (SC)', 'Q2 (SC)', 'Q3 (SC)', 'Q4 (SC)']
        End 
        'quat_mso_labl':Begin
           dvar = ['Q1 (MSO)', 'Q2 (MSO)', 'Q3 (MSO)', 'Q4 (MSO)']
        End
        Else: Begin
           xj = strsplit(vj, '_', /extract)
           nj = Fix(xj[3])
           aj = xj[0]+'@'+strupcase(xj[1])
           dvar = aj+strcompress(/remove_all, string(indgen(nj)))
        End
     Endcase
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
     
  nvars = n_elements(vstr)
  natts = n_tags(global_att)+n_tags(vstr[0])

  inq = {ndims:0l, decoding:'HOST_DECODING', $
         encoding:'IBMPC_ENCODING', $
         majority:'ROW_MAJOR', maxrec:-1,$
         nvars:0, nzvars:nvars, natts:natts, dim:lonarr(1)}

;time resolution and UTC start and end
  If(num_dists Gt 0) Then Begin
     tres = 86400.0/num_dists
     tres = strcompress(string(tres, format = '(f8.1)'))+' sec'
  Endif Else tres = '   0.0 sec'
  global_att.time_resolution = tres

;times for PDS attributes
  PDS_time = time_string(minmax(center_time), tformat='YYYY-MM-DDThh:mm:ss.fffZ')
  PDS_met =  mvn_spc_met_to_unixtime(minmax(center_time), /reverse)
  PDS_etime = time_ephemeris(minmax(center_time))
  cspice_sce2c, -202, PDS_etime[0], PDS_sclk0
  cspice_sce2c, -202, PDS_etime[1], PDS_sclk1
  global_att.PDS_sclk_start_count = pds_sclk0
  global_att.PDS_sclk_stop_count = pds_sclk1
  global_att.PDS_start_time = pds_time[0]
  global_att.PDS_stop_time = pds_time[1]
;save kernel values
  If(is_string(sclk)) Then global_att.Spacecraft_clock_kernel = file_basename(sclk[0])
  If(is_string(tls)) Then global_att.Leapseconds_kernel = file_basename(tls[0])

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

  If(cmn_dat.nenergy Gt 1) Then estring = strcompress(/remove_all, string(cmn_dat.nenergy))+'e' Else estring = ''
  If(cmn_dat.nmass Gt 1) Then mstring = strcompress(/remove_all, string(cmn_dat.nmass))+'m' Else mstring = ''
  If(cmn_dat.ndef Gt 1) Then dstring = strcompress(/remove_all, string(cmn_dat.ndef))+'d' Else dstring = ''
  If(cmn_dat.nanode Gt 1) Then astring = strcompress(/remove_all, string(cmn_dat.nanode))+'a' Else astring = ''

  ext = strcompress(strlowcase(cmn_dat.apid), /remove_all)+'-'+estring+dstring+astring+mstring

  file0 = 'mvn_sta_l2_'+ext+'_'+date+'_'+sw_vsn_str+'.cdf'
  fullfile0 = dir+file0

;Fix ISTP compliance for data types here, 
  ext1_arr = [strcompress(/remove_all, string(cmn_dat.nenergy))+' Energies', $
              strcompress(/remove_all, string(cmn_dat.ndef))+' Deflector Angle bins', $
              strcompress(/remove_all, string(cmn_dat.nanode))+' Anode bins', $
              strcompress(/remove_all, string(cmn_dat.nmass))+' Masses']


  otp_struct.g_attributes.data_type = 'l2_'+ext+'>Level 2 data, APID: '+cmn_dat.apid+', '+strjoin(ext1_arr, ', ')

  otp_struct.g_attributes.PDS_collection_id = ext

;save the file -- full database management
  mvn_sta_cmn_l2file_save, otp_struct, fullfile0, no_compression = no_compression, _extra = _extra

  Return
End

