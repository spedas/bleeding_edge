;+
;NAME:
; mvn_sta_cmn_d7_l2gen.pro
;PURPOSE:
; turn a MAVEN STA RATES common block into a L2 CDF.
;CALLING SEQUENCE:
; mvn_sta_cmn_d7_l2gen, cmn_dat
;INPUT:
; cmn_dat = a structure with the data:
;   PROJECT_NAME    STRING    'MAVEN'
;   SPACECRAFT      STRING    '0'
;   DATA_NAME       STRING    'd7 fsthkp'
;   APID            STRING    'd7'
;   VALID           INT       Array[14336]
;   QUALITY_FLAG    INT       Array[14336]
;   TIME            DOUBLE    Array[14336]
;   HKP_RAW         INT       Array[14336]
;   HKP_CALIB       FLOAT     Array[14336]
;   HKP_IND         LONG      Array[14336]
;   NHKP            INT             24
;   HKP_CONV        DOUBLE    Array[8, 24]
;   HKP_LABELS      STRING    Array[24]
; ? don't know yet, but this is written from the SIS assuming
; that everything is in the structure except for n_elements
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
; 13-jun-2014, jmm, hacked from mvn_sta_cmn_l2gen.pro
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-10-21 15:41:49 -0700 (Wed, 21 Oct 2015) $
; $LastChangedRevision: 19131 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/l2util/mvn_sta_cmn_d7_l2gen.pro $
;-
Pro mvn_sta_cmn_d7_l2gen, cmn_dat, otp_struct = otp_struct, directory = directory, $
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
                Data_type:'l2_d7-fsthkp>Level 2 Fast Housekeeping', $
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

  apid = strlowcase(cmn_dat.apid)

; Here are variable names, type, catdesc, and lablaxis, from the SIS
  rv_vt =  [['EPOCH', 'TT2000', 'UTC time from 01-Jan-2000 12:00:00.000 including leap seconds), one element per ion distribution (NUM_DISTS elements)', 'TT2000'], $
            ['TIME_MET', 'DOUBLE', 'Mission elapsed time for this data record, one element per ion distribution (NUM_DISTS elements)', 'Mission Elapsed Time'], $
            ['TIME_EPHEMERIS', 'DOUBLE', 'Time used by SPICE program (NUM_DISTS elements)', 'SPICE Ephemeris Time'], $
            ['TIME_UNIX', 'DOUBLE', 'Unix time (elapsed seconds since 1970-01-01/00:00 without leap seconds) for this data record, one element per ion distribution. This time is the center time of data collection. (NUM_DISTS elements)', 'Unix Time'], $
            ['VALID', 'INTEGER', 'Validity flag codes valid data (bit 0), test pulser on (bit 1), diagnostic mode (bit 2), data compression type (bit 3-4), packet compression (bit 5) (NUM_DISTS elements)', ' Valid flag'], $
            ['HKP_RAW', 'INTEGER', 'Housekeeping array of dimension (NUM_DISTS) of raw housekeeping values ', 'hxkp_raw'], $
            ['HKP_CALIB', 'FLOAT', 'Housekeeping array of dimension (NUM_DISTS) of calibrated housekeeping values', 'hkp'], $
            ['HKP_IND', 'INTEGER', 'Index defines the selected fast housekeeping channel (NUM_DISTS elements). HKP_IND can be used to select support data.', 'hkp_ind'], $
            ['QUALITY_FLAG', 'INTEGER', 'Quality flag (NUM_DISTS elements)', 'Quality flag']]
;Use Lower case for variable names
  rv_vt[0, *] = strlowcase(rv_vt[0, *])

;No need for lablaxis values here, just use the name
  nv_vt = [['PROJECT_NAME', 'STRING', 'MAVEN'], $
           ['SPACECRAFT', 'STRING', '0'], $
           ['DATA_NAME', 'STRING', 'XX YYY where XX is the APID and YYY is the array abbreviation (64e2m, 32e32m, etc.)'], $
           ['APID', 'STRING', 'XX, where XX is the APID'], $
           ['NUM_DISTS', 'INTEGER', 'Number of measurements or times in the file'], $
           ['NHKP', 'INTEGER', 'Number of housekeeping channels - 99'], $
           ['HKP_CONV', 'INTEGER', 'Calibration parameters to convert raw housekeeping value to calibrated housekeeping with dimension (8,NHKP)'], $
           ['HKP_LABELS', 'STRING', 'Housekeeping label string array with dimension NHKP']]

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
     cmn_dat.time = center_time
     date = time_string(median(center_time), precision=-3, format=6)
     num_dists = n_elements(center_time)
  Endif Else Begin
;Use center time for time variables
     center_time = cmn_dat.time
;Grab the date, and clip anything plus or minus 10 minutes from the
;start or end of the date
     date = time_string(median(center_time), precision=-3, format=6)
     trange = time_double(date)+[-600.0d0, 87000.0d0]
     cmn_dat = mvn_sta_cmn_tclip(temporary(cmn_dat), trange)
;Reset center time
     center_time = cmn_dat.time
     num_dists = n_elements(center_time)
;met_center at the spacecraft
     timespan, date, 1
     met_center = mvn_spc_met_to_unixtime(center_time, /reverse)
  Endelse
;Initialize
  otp_struct = -1
  count = 0L
;FIrst handle RV variables
  lrv = n_elements(rv_vt[0, *])
  For j = 0L, lrv-1 Do Begin
;Either the name is in the common block or not, names not in the
;common block have to be dealt with as special cases. Vectors will
;need label and component variables
     is_tvar = 0b
     vj = rv_vt[0, j]
     Have_tag = where(cvars Eq vj, nhave_tag)
     have_dvar = 1b             ;Mostly all vars will be filled
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
           Else: Begin
              message, /info, 'Variable '+vj+' Unaccounted for; Skipping'
              have_dvar = 0b
           End
        Endcase
     Endelse

     If(have_dvar Eq 0) Then Continue

;change data to float from double
     if(vj eq 'hkp') then dvar = float(dvar) 

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
             form_ptr:'NA', monoton:'NA'}

;fix fill vals, valid mins and valid max's here
     str_element, vatt, 'fillval', fll, /add
     str_element, vatt, 'format', fmt, /add
     If(vj Eq 'epoch') Then Begin
        xtime = time_double('9999-12-31/23:59:59.999')
        xtime = long64((add_tt2000_offset(xtime)-time_double('2000-01-01/12:00'))*1e9)
        str_element, vatt, 'fillval', xtime, /add
        str_element, vatt, 'validmin', tt2000_range[0], /add
        str_element, vatt, 'validmax', tt2000_range[1], /add
     Endif Else If(vj Eq 'time_met') Then Begin
        str_element, vatt, 'validmin', met_range[0], /add
        str_element, vatt, 'validmax', met_range[1], /add
     Endif Else If(vj Eq 'time_ephemeris') Then Begin
        str_element, vatt, 'validmin', et_range[0], /add
        str_element, vatt, 'validmax', et_range[1], /add
     Endif Else If(vj Eq 'time_unix') Then Begin
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
;Data or support data?
     IF(vj Eq 'hkp_raw' Or vj Eq 'hkp') Then Begin
        vatt.scaletyp = 'linear' 
        vatt.display_type = 'time_series'
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
     Endif

;Depends and labels
     vatt.depend_time = 'time_unix'
     vatt.depend_0 = 'epoch'
     vatt.lablaxis = rv_vt[3, j]

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
     have_dvar = 1b
     If(nhave_tag Gt 0) Then Begin
        dvar = cmn_dat.(have_tag)
     Endif Else Begin
;Case by case basis
        Case vj of
           'num_dists': Begin
              dvar = num_dists
           End        
           'nhkp': Begin
              dvar = 99         ;may not need this
           End        
           Else: Begin
              message, /info, 'Variable '+vj+' Unaccounted for. Skipping'
              have_dvar = 0b
           End
        Endcase
     Endelse
     If(have_dvar Eq 0) Then continue
     cdf_type = idl2cdftype(dvar, format_out = fmt, fillval_out = fll, validmin_out = vmn, validmax_out = vmx)
     dtype = size(dvar, /type)
;variable attributes here, but only the string attributes, the others
;depend on the data type
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

  ext = strcompress(strlowcase(cmn_dat.apid), /remove_all)+'-fsthkp'

  file0 = 'mvn_sta_l2_'+ext+'_'+date+'_'+sw_vsn_str+'.cdf'
  fullfile0 = dir+file0

;save the file -- full database management
  mvn_sta_cmn_l2file_save, otp_struct, fullfile0, no_compression = no_compression, _extra = _extra

  Return
End
