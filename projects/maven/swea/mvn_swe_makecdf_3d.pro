;+
; NAME: 
;   MVN_SWE_MAKECDF_3D
; SYNTAX:
;	MVN_SWEA_MAKECDF_3D, DATA, FILE = FILE, VERSION = VERSION
; PURPOSE:
;	Routine to produce CDF file from SWEA 3D data structures
; INPUTS:
;   DATA: Structure with which to populate the CDF file
;         (nominally created by mvn_swe_get3d.pro)
; OUTPUT:
;   CDF file
; KEYWORDS:
;   FILE: full file name of the output file - only used for testing
;         if not specified (usually won't be), the program creates the appropriate filename
;   VERSION: integer; software version
;          - read from common block (SWE_CFG) defined in mvn_swe_calib.pro
;          - keyword no longer needed (but kept for compatibility)
; HISTORY:
;   Created by Matt Fillingim (with code stolen from JH and RL)
;   Added directory keyword, and deletion of old files, jmm, 2014-11-14
;   Read version number from common block; MOF: 2015-01-30
;   ISTP compliance scrub; DLM: 2016-04-08
; VERSION:
;   $LastChangedBy: dmitchell $
;   $LastChangedDate: 2018-11-18 14:23:15 -0800 (Sun, 18 Nov 2018) $
;   $LastChangedRevision: 26143 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_makecdf_3d.pro $
;
;-

pro mvn_swe_makecdf_3d, data, file = file, version = version, directory = directory

  @mvn_swe_com

  nrec = n_elements(data)

  if (nrec lt 2) then begin
    print, 'No 3D data!'
    print, 'CDF file not created.'
    return
  endif

; Identify data that do not use sweep table 3 (checksum C0),
; table 5 (checksum CC) or table 6 (checksum 82).  Table 3 is 
; primary during cruise, and was superceded by table 5 during 
; transition on Oct. 6, 2014.  Table 6 is very similar to 5, 
; except that it enables V0.  Include a 1-record buffer to 
; account for spectra obtained during the sweep table change. 
; Exclude these data from the CDF.

  indx = where(~mvn_swe_validlut(data.chksum), count)
  if (count gt 0L) then begin
    data[indx].valid = 0B
    data[(indx - 1L) > 0L].valid = 0B
    data[(indx + 1L) < (nrec - 1L)].valid = 0B

    indx = where(data.valid, nrec)
    if (nrec eq 0L) then begin
      print, 'No valid 3D data!'
      print, 'CDF file not created.'
      return
    endif
    data = temporary(data[indx])
  endif

; Get data type -- survey or archive

  CASE data[0].apid OF
    'A0'X: BEGIN
             tag = 'svy'
             title = 'MAVEN SWEA 3D Survey'
           END
    'A1'X: BEGIN
             tag = 'arc'
             title = 'MAVEN SWEA 3D Archive'
           END
    ELSE:  BEGIN
             PRINT, 'Invalid APID: ', data[0].apid
             tag = 'und'
             title = 'MAVEN SWEA 3D Undefined'
             STOP ; kind of harsh
           END
  ENDCASE

; Get date (avoid any potential weird first-record-of-day timing)

  mid = nrec/2
  dum_str = time_string(data[mid].time) ; use midpoint of day

  yyyy = strmid(dum_str, 0, 4)
  mm = strmid(dum_str, 5, 2)
  dd = strmid(dum_str, 8, 2)
  yyyymmdd = yyyy + mm + dd

  if (not keyword_set(file)) then begin

; hardcoded data directory path
; Added directory keyword, for testing, jmm, 2014-11-14

    if (keyword_set(directory)) then path = directory[0] else $
      path = '/disks/data/maven/data/sci/swe/l2/' + yyyy + '/' + mm + '/'
    if (n_elements(file_search(path)) Eq 0) then file_mkdir2, path, mode = '0775'o

; Create file name using SIS convention

    file = 'mvn_swe_l2_' + tag + '3d_' + yyyymmdd

; Read version number from common block (SWE_CFG) defined in mvn_swe_calib.pro

    if (not keyword_set(version)) then version = mvn_swe_version
    ver_str = string(version, format='(i2.2)')
    file = file + '_v' + ver_str

; Search for previously generated CDF files for this date.
; Check for latest revision number, add one to it (delete/overwrite old version)

    file_list = file_search(path + file + '*.cdf', count = nfiles)
    if (nfiles gt 0) then begin     ; file for this day already exists
      latest = file_list[nfiles-1]  ;  latest should be last in list
      old_rev_str = strmid(latest, 5, 2, /reverse_offset)
      revision = fix(old_rev_str) + 1
    endif else begin                ; file for this day does not yet exist
      revision = 1
    endelse

; Append version and revision to the file name
; file variable now contains full path, filename, and extension

    rev_str = string(revision, format='(i2.2)')

    head_file = file + '_r' + rev_str + '.cdf'
    temp_file = 'tmp_' + head_file
    file = path + head_file

  endif else begin ; if (not keyword_set(file))
    path = file_dirname(file) + '/'
    head_file = file_basename(file)
    temp_file = 'tmp_' + head_file
    ver_str = '00' ; needed in the header
    rev_str = '00' ; needed in the header
  endelse

  print, file

; Use a temporary filename to hide from the automated transfer bot while
; the file is being assembled.

  file = path + temp_file

; compute various times
; load leap seconds

  cdf_leap_second_init

; get date ranges (for CDF files)

  date_range = time_double(['2013-11-18/00:00', '2030-12-31/23:59'])

;met_range = date_range - time_double('2000-01-01/12:00') ; JH

  met_range = date_range - date_range[0] ; RL -- start at 0
  epoch_range = time_epoch(date_range)
  tt2000_range = long64((add_tt2000_offset(date_range) $
                 - time_double('2000-01-01/12:00'))*1e9)

; *** uses general/misc/time/time_epoch.pro ***
; time_epoch ==> return, 1000.d*(time_double(time) + 719528.d*24.d*3600.d)
; epoch is milliseconds from 0000-01-01/00:00:00.000

  epoch = time_epoch(data.time) ; time is unix time in swea structures

; *** uses general/misc/time/TT2000/add_tt2000_offest.pro ***

  tt2000 = long64((add_tt2000_offset(data.time) $
           - time_double('2000-01-01/12:00'))*1e9)

  t_start_str = time_string(data[0].time, tformat = 'YYYY-MM-DDThh:mm:ss.fffZ')
  t_end_str = time_string(data[nrec-1].end_time, tformat = 'YYYY-MM-DDThh:mm:ss.fffZ')

; include SPICE kernels used
; spacecraft clock kernel

  i = where(strmatch(swe_kernels,'*sclk*',/fold), count)
  if (count gt 0) then driftname = file_basename(swe_kernels[i])

; leapseconds kernel

  j = where(strmatch(swe_kernels,'*.tls',/fold), count)
  if (count gt 0) then leapname = file_basename(swe_kernels[j])

; create and populate CDF file

  fileid = cdf_create(file, /single_file, /network_encoding, /clobber)

  varlist = ['epoch', 'time_tt2000', 'time_met', 'time_unix', $
             'binning', 'counts', 'diff_en_fluxes', 'geom_factor', $
             'g_engy', 'de_over_e', 'accum_time', 'energy', 'elev', $
             'g_elev', 'azim', 'g_azim', 'num_dists', 'dindex', $
             'az_label','el_label','en_label']

  id0  = cdf_attcreate(fileid, 'TITLE',                      /global_scope)
  id1  = cdf_attcreate(fileid, 'Project',                    /global_scope)
  id2  = cdf_attcreate(fileid, 'Discipline',                 /global_scope)
  id3  = cdf_attcreate(fileid, 'Source_name',                /global_scope)
  id4  = cdf_attcreate(fileid, 'Descriptor',                 /global_scope)
  id5  = cdf_attcreate(fileid, 'Data_type',                  /global_scope)
  id6  = cdf_attcreate(fileid, 'Data_version',               /global_scope)
  id7  = cdf_attcreate(fileid, 'TEXT',                       /global_scope)
  id8  = cdf_attcreate(fileid, 'MODS',                       /global_scope)
  id9  = cdf_attcreate(fileid, 'Logical_file_id',            /global_scope)
  id10 = cdf_attcreate(fileid, 'Logical_source',             /global_scope)
  id11 = cdf_attcreate(fileid, 'Logical_source_description', /global_scope)
  id12 = cdf_attcreate(fileid, 'PI_name',                    /global_scope)
  id13 = cdf_attcreate(fileid, 'PI_affiliation',             /global_scope)
  id14 = cdf_attcreate(fileid, 'Instrument_type',            /global_scope)
  id15 = cdf_attcreate(fileid, 'Mission_group',              /global_scope)
  id16 = cdf_attcreate(fileid, 'Parents',                    /global_scope)
  id17 = cdf_attcreate(fileid, 'Spacecraft_clock_kernel',    /global_scope)
  id18 = cdf_attcreate(fileid, 'Leapseconds_kernel',         /global_scope)
  id19 = cdf_attcreate(fileid, 'PDS_collection_id',          /global_scope)
  id20 = cdf_attcreate(fileid, 'PDS_start_time',             /global_scope)
  id21 = cdf_attcreate(fileid, 'PDS_stop_time',              /global_scope)
  id22 = cdf_attcreate(fileid, 'PDS_sclk_start_count',       /global_scope)
  id23 = cdf_attcreate(fileid, 'PDS_sclk_stop_count',        /global_scope)

  cdf_attput, fileid, 'TITLE',                      0, $
    title
  cdf_attput, fileid, 'Project',                    0, $
    'MAVEN'
  cdf_attput, fileid, 'Discipline',                 0, $
    'Planetary Physics>Planetary Plasma Interactions'
;   'Planetary Physics>Particles'
  cdf_attput, fileid, 'Source_name',                0, $
    'MAVEN>Mars Atmosphere and Volatile Evolution Mission'
  cdf_attput, fileid, 'Descriptor',                 0, $
    'SWEA>Solar Wind Electron Analyzer'
  cdf_attput, fileid, 'Data_type',                  0, $
    'CAL>Calibrated'
  cdf_attput, fileid, 'Data_version',               0, $
    ver_str ; version
  cdf_attput, fileid, 'TEXT',                       0, $
    'MAVEN SWEA 3D Distributions'
  cdf_attput, fileid, 'MODS',                       0, $
    'Revision 0'
  cdf_attput, fileid, 'Logical_file_id',            0, $
    head_file
  cdf_attput, fileid, 'Logical_source',             0, $
    'swea.calibrated.' + tag + '_3d'
  cdf_attput, fileid, 'Logical_source_description', 0, $
    'DERIVED FROM: MAVEN SWEA (Solar Wind Electron Analyzer) 3D Distributions'
  cdf_attput, fileid, 'PI_name',                    0, $
    'David L. Mitchell (mitchell@ssl.berkeley.edu)'
  cdf_attput, fileid, 'PI_affiliation',             0, $
    'UC Berkeley Space Sciences Laboratory'
  cdf_attput, fileid, 'Instrument_type',            0, $
    'Plasma and Solar Wind'
  cdf_attput, fileid, 'Mission_group',              0, $
    'MAVEN'
  cdf_attput, fileid, 'Parents',                    0, $
    'None'
  cdf_attput, fileid, 'Spacecraft_clock_kernel',    0, $
    driftname[0]
  cdf_attput, fileid, 'Leapseconds_kernel',         0, $
    leapname[0]
  cdf_attput, fileid, 'PDS_collection_id',          0, $
    'data.' + tag + '_3d'
;   'urn:nasa:pds:maven.swea.calibrated:data.' + tag + '_3d'
  cdf_attput, fileid, 'PDS_start_time',             0, $
    t_start_str
  cdf_attput, fileid, 'PDS_stop_time',              0, $
    t_end_str

;jmm, 2014-01-30, changed met to sclk count

  PDS_etime = time_ephemeris([data[0].time, data[nrec-1].end_time])
  cspice_sce2c, -202, PDS_etime[0], PDS_sclk0
  cspice_sce2c, -202, PDS_etime[1], PDS_sclk1
  cdf_attput, fileid, 'PDS_sclk_start_count',       0, $
    PDS_sclk0
  cdf_attput, fileid, 'PDS_sclk_stop_count',        0, $
    PDS_sclk1

  dummy = cdf_attcreate(fileid, 'FIELDNAM',     /variable_scope)
  dummy = cdf_attcreate(fileid, 'MONOTON',      /variable_scope)
  dummy = cdf_attcreate(fileid, 'FORMAT',       /variable_scope)
  dummy = cdf_attcreate(fileid, 'FORM_PTR',     /variable_scope)
  dummy = cdf_attcreate(fileid, 'LABLAXIS',     /variable_scope)
  dummy = cdf_attcreate(fileid, 'LABL_PTR_1',   /variable_scope)
  dummy = cdf_attcreate(fileid, 'LABL_PTR_2',   /variable_scope)
  dummy = cdf_attcreate(fileid, 'LABL_PTR_3',   /variable_scope)
  dummy = cdf_attcreate(fileid, 'VAR_TYPE',     /variable_scope)
  dummy = cdf_attcreate(fileid, 'FILLVAL',      /variable_scope)
  dummy = cdf_attcreate(fileid, 'DEPEND_0',     /variable_scope)
  dummy = cdf_attcreate(fileid, 'DEPEND_1',     /variable_scope)
  dummy = cdf_attcreate(fileid, 'DEPEND_2',     /variable_scope)
  dummy = cdf_attcreate(fileid, 'DEPEND_3',     /variable_scope)
  dummy = cdf_attcreate(fileid, 'DISPLAY_TYPE', /variable_scope)
  dummy = cdf_attcreate(fileid, 'VALIDMIN',     /variable_scope)
  dummy = cdf_attcreate(fileid, 'VALIDMAX',     /variable_scope)
  dummy = cdf_attcreate(fileid, 'SCALEMIN',     /variable_scope)
  dummy = cdf_attcreate(fileid, 'SCALEMAX',     /variable_scope)
  dummy = cdf_attcreate(fileid, 'TIME_BASE',    /variable_scope)
  dummy = cdf_attcreate(fileid, 'UNITS',        /variable_scope)
  dummy = cdf_attcreate(fileid, 'CATDESC',      /variable_scope)

; *** epoch *** (Points to tt2000)

  varid = cdf_varcreate(fileid, varlist[0], /CDF_TIME_TT2000, /REC_VARY, /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[1],                   /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'I22',                        /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[1],                   /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data',               /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, long64(-9223372036854775808), /ZVARIABLE, /CDF_EPOCH
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',                /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN',  'epoch', tt2000_range[0], /ZVARIABLE, /CDF_EPOCH
  cdf_attput, fileid, 'VALIDMAX',  'epoch', tt2000_range[1], /ZVARIABLE, /CDF_EPOCH
  cdf_attput, fileid, 'SCALEMIN',  'epoch', tt2000[0],       /ZVARIABLE, /CDF_EPOCH
  cdf_attput, fileid, 'SCALEMAX',  'epoch', tt2000[nrec-1],  /ZVARIABLE, /CDF_EPOCH
  cdf_attput, fileid, 'TIME_BASE', 'epoch', 'J2000',         /ZVARIABLE
  cdf_attput, fileid, 'UNITS',     'epoch', 'ns',            /ZVARIABLE
  cdf_attput, fileid, 'MONOTON',   'epoch', 'INCREASE',      /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',   'epoch', $
    'Time, center of sample, in TT2000 time base', /ZVARIABLE

  cdf_varput, fileid, 'epoch', tt2000

; *** time_met ***

  varid = cdf_varcreate(fileid, varlist[2], /CDF_DOUBLE, /REC_VARY, /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[2],     /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'F25.6',        /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[2],     /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.d31,         /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', 'time_met', met_range[0],     /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', 'time_met', met_range[1],     /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', 'time_met', data[0].met,      /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', 'time_met', data[nrec-1].met, /ZVARIABLE
  cdf_attput, fileid, 'UNITS',    'time_met', 's',              /ZVARIABLE
  cdf_attput, fileid, 'MONOTON',  'time_met', 'INCREASE',       /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  'time_met', $
    'Time, center of sample, in raw mission elapsed time', /ZVARIABLE
  cdf_attput, fileid, 'DEPEND_0', 'time_met', 'epoch', /ZVARIABLE

  cdf_varput, fileid, 'time_met', data.met

; *** time_unix ***

  varid = cdf_varcreate(fileid, varlist[3], /CDF_DOUBLE, /REC_VARY, /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[3],     /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'F25.6',        /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[3],     /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.d31,         /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', 'time_unix', date_range[0],     /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', 'time_unix', date_range[1],     /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', 'time_unix', data[0].time,      /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', 'time_unix', data[nrec-1].time, /ZVARIABLE
  cdf_attput, fileid, 'UNITS',    'time_unix', 's',               /ZVARIABLE
  cdf_attput, fileid, 'MONOTON',  'time_unix', 'INCREASE',        /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  'time_unix', $
    'Time, center of sample, in Unix time', /ZVARIABLE
  cdf_attput, fileid, 'DEPEND_0', 'time_unix', 'epoch', /ZVARIABLE

  cdf_varput, fileid, 'time_unix', data.time

; *** binning ***

  varid = cdf_varcreate(fileid, varlist[4], /CDF_UINT1, /REC_VARY, /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[4],     /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'I7',           /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[4],     /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, 255B,           /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', 'binning', 1B,       /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', 'binning', 4B,       /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', 'binning', 1B,       /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', 'binning', 4B,       /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  'binning', $
    'Energy binning factor: 1 = 64 energies, 2 = 32 energies, 4 = 16 energies', $
    /ZVARIABLE
  cdf_attput, fileid, 'DEPEND_0', 'binning', 'epoch', /ZVARIABLE

  cdf_varput, fileid, 'binning', byte(2.^data.group)

; *** counts ***

  dim_vary = [1, 1, 1]
  dim = [64, 16, 6]  
  varid = cdf_varcreate(fileid, varlist[5], /CDF_FLOAT, dim_vary, DIM = dim, /REC_VARY, /ZVARIABLE) 

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[5],     /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'F15.1',        /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[5],     /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', 'counts', 0.,                      /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', 'counts', 1.e10,                   /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', 'counts', 0.,                      /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', 'counts', 1.e6,                    /ZVARIABLE
  cdf_attput, fileid, 'UNITS',    'counts', 'counts',                /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  'counts', 'Raw Instrument Counts', /ZVARIABLE
  cdf_attput, fileid, 'DEPEND_0', 'counts', 'epoch',                 /ZVARIABLE
  cdf_attput, fileid, 'DEPEND_3', 'counts', 'energy',                /ZVARIABLE
  cdf_attput, fileid, 'DEPEND_2', 'counts', 'azim',                  /ZVARIABLE
  cdf_attput, fileid, 'DEPEND_1', 'counts', 'dindex',                /ZVARIABLE

; DEPEND_X are in reverse order for row-major (PDS) vs. column-major (IDL)
; DEPEND_1 should point to 'elev', but 'elev' is 2-dimensional, so ...
; dindex is a dummy variable (no information content) for ISTP compliance

; Convert to units of raw counts

  mvn_swe_convert_units, data, 'counts'

; Extract geometric factor; look for changes with time that are caused
; by MCP bias adjustments (these are rare).  When this happens, scale 
; the raw counts to compensate for the change in geometric factor, 
; because there can be only one geometric factor per UT day.

  gf_i = data.gf[0,0]
  geom_factor = median([gf_i])  ; most common value
  scale = geom_factor/gf_i      ; unity except on days when MCP bias is adjusted
  scale = replicate(1.,64*96) # scale
  scale = reform(scale,64,96,nrec)

; reform arrays: [64, 96] --> [64, 16, 6]

  dum_counts = data.data * scale ; [64, 96, nrec]
  dum_counts = reform(dum_counts, 64, 16, 6, nrec, /overwrite)

  cdf_varput, fileid, 'counts', dum_counts

; *** diff_en_fluxes -- Differential energy fluxes ***

  dim_vary = [1, 1, 1]
  dim = [64, 16, 6]  
  varid = cdf_varcreate(fileid, varlist[6], /CDF_FLOAT, dim_vary, DIM = dim, /REC_VARY, $
    /ZVARIABLE) 

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[6],    /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'E15.7',       /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[6],    /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'data',        /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,        /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series', /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', 'diff_en_fluxes', 0.,       /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', 'diff_en_fluxes', 1.e14,    /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', 'diff_en_fluxes', 0.,       /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', 'diff_en_fluxes', 1.e11,    /ZVARIABLE
  cdf_attput, fileid, 'UNITS',    'diff_en_fluxes', $
    'eV/[eV cm^2 sr s]', /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE', 'diff_en_fluxes', 'data',  /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  'diff_en_fluxes', $
    'Calibrated differential energy flux', /ZVARIABLE
  cdf_attput, fileid, 'DEPEND_0', 'diff_en_fluxes', 'epoch', /ZVARIABLE
  cdf_attput, fileid, 'DEPEND_3', 'diff_en_fluxes', 'energy',/ZVARIABLE
  cdf_attput, fileid, 'DEPEND_2', 'diff_en_fluxes', 'azim',  /ZVARIABLE
  cdf_attput, fileid, 'DEPEND_1', 'diff_en_fluxes', 'dindex',/ZVARIABLE
  cdf_attput, fileid, 'LABL_PTR_1','diff_en_fluxes','el_label',/ZVARIABLE
  cdf_attput, fileid, 'LABL_PTR_2','diff_en_fluxes','az_label',/ZVARIABLE
  cdf_attput, fileid, 'LABL_PTR_3','diff_en_fluxes','en_label',/ZVARIABLE

; DEPEND_X are in reverse order for row-major (PDS) vs. column-major (IDL)
; DEPEND_1 should point to 'elev', but 'elev' is 2-dimensional, so ...
; dindex is a dummy variable (no information content) for ISTP compliance

; convert to units of energy flux

  mvn_swe_convert_units, data, 'eflux'

; reform arrays: [64, 96] --> [64, 16, 6]

  dum_diff_en_fluxes = data.data
  dum_diff_en_fluxes = reform(dum_diff_en_fluxes, 64, 16, 6, nrec, /overwrite)

  cdf_varput, fileid, 'diff_en_fluxes', dum_diff_en_fluxes

; *** geom_factor -- Geometric factor ***

  varid = cdf_varcreate(fileid, varlist[7], /CDF_FLOAT, /REC_NOVARY, /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[7],     /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[7],     /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', 'geom_factor', 0.0,             /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', 'geom_factor', 1.0,             /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', 'geom_factor', 0.0,             /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', 'geom_factor', 1.e-2,           /ZVARIABLE
  cdf_attput, fileid, 'UNITS',    'geom_factor', 'cm^2 sr eV/eV', /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  'geom_factor', $
    'Full sensor geometric factor (per anode) at 1.4 keV', /ZVARIABLE

  cdf_varput, fileid, 'geom_factor', geom_factor

; *** g_engy -- Relative sensitivity as a function of energy ***

  dim_vary = [1]
  dim = 64
  varid = cdf_varcreate(fileid, varlist[8], /CDF_FLOAT, dim_vary, DIM = dim, /REC_NOVARY, $
    /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[8],     /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[8],     /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', 'g_engy', 0.0,             /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', 'g_engy', 2.0,             /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', 'g_engy', 0.0,             /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', 'g_engy', 0.2,             /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  'g_engy', $
    'Relative sensitivity as a function of energy',          /ZVARIABLE

; Average over angles to get gf as a function of energy
; Use midpoint of the data because the efficiency is constant
; over the coarse of a single UT day.  (Changes in efficiency
; occur over much longer time scales, and are tracked by in-
; flight calibration and cross calibration.)

  g_engy = average(data[mid].eff*data[mid].gf, 2, /nan)
  g_engy = g_engy/geom_factor

  cdf_varput, fileid, 'g_engy', g_engy

; *** de_over_e -- DE/E ***

  dim_vary = [1]
  dim = 64
  varid = cdf_varcreate(fileid, varlist[9], /CDF_FLOAT, dim_vary, DIM = dim, /REC_NOVARY, $
    /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[9],     /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[9],     /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', 'de_over_e', 0.0,               /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', 'de_over_e', 1.0,               /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', 'de_over_e', 0.0,               /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', 'de_over_e', 0.3,               /ZVARIABLE
  cdf_attput, fileid, 'UNITS',    'de_over_e', 'eV/eV',           /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  'de_over_e', 'DeltaE/E (FWHM)', /ZVARIABLE

  de_over_e = data[mid].denergy[*,0]/data[mid].energy[*,0] ; [64]

  cdf_varput, fileid, 'de_over_e', de_over_e

; *** accum_time -- Accumulation Time ***

  varid = cdf_varcreate(fileid, varlist[10], /CDF_FLOAT, /REC_NOVARY, /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[10],    /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[10],    /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', 'accum_time', 0.0,                 /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', 'accum_time', 1.0,                 /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', 'accum_time', 0.0,                 /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', 'accum_time', 0.1,                 /ZVARIABLE
  cdf_attput, fileid, 'UNITS',    'accum_time', 's',                 /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  'accum_time', 'Accumulation time', /ZVARIABLE

  cdf_varput, fileid, 'accum_time', data[mid].integ_t

; *** energy ***

  dim_vary = [1]
  dim = 64
  varid = cdf_varcreate(fileid, varlist[11], /CDF_FLOAT, dim_vary, DIM = dim, /REC_NOVARY, $
    /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[11],    /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[11],    /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', 'energy', 0.,         /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', 'energy', 5.e4,       /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', 'energy', 0.,         /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', 'energy', 5.e3,       /ZVARIABLE
  cdf_attput, fileid, 'UNITS',    'energy', 'eV',       /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  'energy', 'Energies', /ZVARIABLE

  energy = data[mid].energy[*, 0]

  cdf_varput, fileid, 'energy', energy

; *** elev -- Elevation Angle ***

  dim_vary = [1, 1]
  dim = [64, 6]
  varid = cdf_varcreate(fileid, varlist[12], /CDF_FLOAT, dim_vary, DIM = dim, /REC_NOVARY, $
  /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[12],    /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[12],    /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', 'elev', -180.,                     /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', 'elev', 180.,                      /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', 'elev', -90.,                      /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', 'elev', 90.,                       /ZVARIABLE
  cdf_attput, fileid, 'UNITS',    'elev', 'degrees',                 /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  'elev', 'Elevation angle (theta)', /ZVARIABLE

; reform arrays: [64, 96] --> [64, 16, 6] --> just want [64, 6]

  dum_theta = reform(data[mid].theta, 64, 16, 6)
  elev = reform(dum_theta[*, 0, *])

  cdf_varput, fileid, 'elev', elev

; *** g_elev -- Relative Sensitivity as a Function of Elevation ***

  dim_vary = [1, 1]
  dim = [64, 6]
  varid = cdf_varcreate(fileid, varlist[13], /CDF_FLOAT, dim_vary, DIM = dim, /REC_NOVARY, $
  /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[13],    /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[13],    /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', 'g_elev', 0., /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', 'g_elev', 2., /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', 'g_elev', 0., /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', 'g_elev', 2., /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  'g_elev', $
    'Relative sensitivity as a function of elevation',       /ZVARIABLE

; Decompose relative angular sensitivity into azimuth and elevation terms

  dum_eff = reform(data[mid].eff, 64, 16, 6)
  eff_azim = average(dum_eff[*,*,1:4],3)  ; average over mid elevations
  eff_elev = average(dum_eff,2)           ; average over azimuth

  g_azim = reform(eff_azim[0,*]/average(eff_azim[0,*]))             ; normalize
  g_elev = eff_elev
  for i=0,63 do g_elev[i,*] = eff_elev[i,*]/average(eff_elev[i,*])  ; normalize

  cdf_varput, fileid, 'g_elev', g_elev

; *** Deflection Index

  dim_vary = [1]
  dim = 6

  varid = cdf_varcreate(fileid, varlist[17], dim_vary, DIM = dim, /CDF_UINT1, /REC_NOVARY,/ZVARIABLE)
  cdf_attput, fileid, 'FIELDNAM',    varid, varlist[17],    /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',      varid, 'I7',           /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',    varid, varlist[17],    /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',    varid, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',     varid, 255B,           /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE',varid, 'time_series',  /ZVARIABLE
  cdf_attput, fileid, 'VALIDMIN', 'dindex', 0B,             /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', 'dindex', 5B,             /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', 'dindex', 0B,             /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', 'dindex', 5B,             /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  'dindex', 'Deflection Index for CDF compatibility',/ZVARIABLE

  cdf_varput,fileid,'dindex',bindgen(6)

; *** azim -- Azimuth Angles ***

  dim_vary = [1]
  dim = 16
  varid = cdf_varcreate(fileid, varlist[14], /CDF_FLOAT, dim_vary, DIM = dim, /REC_NOVARY, $
  /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[14],    /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[14],    /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', 'azim', 0.,                    /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', 'azim', 360.,                  /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', 'azim', 0.,                    /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', 'azim', 360.,                  /ZVARIABLE
  cdf_attput, fileid, 'UNITS',    'azim', 'degrees',             /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  'azim', 'Azimuth angle (phi)', /ZVARIABLE

; reform arrays: [64, 96] --> [64, 16, 6] --> just want [16]

  dum_phi = reform(data[mid].phi, 64, 16, 6)
  azim = reform(dum_phi[0, *, 0])

  cdf_varput, fileid, 'azim', azim

; *** g_azim -- Relative Sensitivity as a Function of Azimuth ***

  dim_vary = [1]
  dim = 16
  varid = cdf_varcreate(fileid, varlist[15], /CDF_FLOAT, dim_vary, DIM = dim, /REC_NOVARY, /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[15],    /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[15],    /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', 'g_azim', 0., /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', 'g_azim', 2., /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', 'g_azim', 0., /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', 'g_azim', 2., /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  'g_azim', $
    'Relative sensitivity as a function of azimuth', /ZVARIABLE

  cdf_varput, fileid, 'g_azim', g_azim

; *** Azimuth Label

  dim_vary = [1]
  dim = 16

  varid = cdf_varcreate(fileid, varlist[18], dim_vary, DIM = dim, /CDF_CHAR, /REC_NOVARY,/ZVARIABLE,numelem=3)
  cdf_attput, fileid, 'FIELDNAM', varid, varlist[18], /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',   varid, 'A3',        /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE', varid, 'metadata',  /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',  varid, " ",         /ZVARIABLE
  cdf_attput, fileid, 'CATDESC', 'az_label','Azimuth Axis Label for CDF compatibility',/ZVARIABLE

  labs = 'A' + strcompress(string(indgen(16)),/rem)
  len = strlen(labs)
  w = where(len lt 3)
  if (w[0] ne -1) then labs(w) = ' ' + labs(w)

  cdf_varput, fileid, 'az_label', labs


; *** Elevation (deflection) Label

  dim_vary = [1]
  dim = 6

  varid = cdf_varcreate(fileid, varlist[19], dim_vary, DIM = dim, /CDF_CHAR, /REC_NOVARY,/ZVARIABLE,numelem=2)
  cdf_attput, fileid, 'FIELDNAM', varid, varlist[19], /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',   varid, 'A2',        /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE', varid, 'metadata',  /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',  varid, " ",         /ZVARIABLE
  cdf_attput, fileid, 'CATDESC', 'el_label','Deflection Axis Label for CDF compatibility',/ZVARIABLE

  cdf_varput, fileid, 'el_label', 'D' + strcompress(string(indgen(6)),/rem)

; *** Energy Label

  dim_vary = [1]
  dim = 64

  varid = cdf_varcreate(fileid, varlist[20], dim_vary, DIM = dim, /CDF_CHAR, /REC_NOVARY,/ZVARIABLE,numelem=3)
  cdf_attput, fileid, 'FIELDNAM', varid, varlist[20], /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',   varid, 'A3',        /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE', varid, 'metadata',  /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',  varid, " ",         /ZVARIABLE
  cdf_attput, fileid, 'CATDESC', 'en_label','Energy Axis Label for CDF compatibility',/ZVARIABLE

  labs = 'E' + strcompress(string(indgen(64)),/rem)
  len = strlen(labs)
  w = where(len lt 3)
  if (w[0] ne -1) then labs(w) = ' ' + labs(w)

  cdf_varput, fileid, 'en_label', labs

; *** num_dists -- Number of Distributions ***

  varid = cdf_varcreate(fileid, varlist[16], /CDF_INT4, /REC_NOVARY, /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[16],       /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'I12',             /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[16],       /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data',    /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, long(-2147483648), /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',     /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', 'num_dists', 0L,     /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', 'num_dists', 43200L, /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', 'num_dists', 0L,     /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', 'num_dists', 43200L, /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  'num_dists', $
    'Number of distributions in file', /ZVARIABLE

  cdf_varput, fileid, 'num_dists', long(nrec)

  cdf_close,fileid

; Rename the file to the original

  tofile = path + head_file
  cmd = 'mv ' + file + ' ' + tofile
  spawn, cmd, result, err
  if (err ne '') then begin
    print, "Error renaming file: "
    print, "  ", cmd
    print, "  ", err
    return
  endif
  file = tofile

; compression, md5, and permissions (rw--rw--r--)

  mvn_l2file_compress, file

; Try to make sure maven has group ownership
; (only works for the file's owner)

  cmd = 'chgrp maven ' + file
  spawn, cmd, result, err
  if (err ne '') then begin
    print, "Error changing group for file: "
    print, "  ", cmd
    print, "  ", err
  endif

  cmd = 'chgrp maven ' + file_dirname(file) + '/' + file_basename(file, '.cdf') + '.md5'
  spawn, cmd, result, err
  if (err ne '') then begin
    print, "Error changing group for file: "
    print, "  ", cmd
    print, "  ", err
  endif

;Delete old files, jmm, 2014-11-14, include md5's, jmm, 2014-11-25

  if (nfiles Gt 0) then begin
     for j = 0, nfiles-1 do begin
        file_delete, file_list[j]
        md5j = file_dirname(file_list[j]) + '/' + $
               file_basename(file_list[j], '.cdf') + '.md5'
        if(keyword_set(file_search(md5j))) then file_delete, md5j
     endfor
  endif
  
  return

end
