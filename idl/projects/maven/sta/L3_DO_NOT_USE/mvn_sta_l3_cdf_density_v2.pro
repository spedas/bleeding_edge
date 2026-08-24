;+
;Create CDFs of MAVEN-STATIC L3 density tplot files. This file takes a date as input, loads L3 density data into IDL tplot, and creates a CDF file of the data. 
;
;Using tplot2cdf.pro, under /general/CDF/.
;And /general/examples/crib_tplot2cdf_basic.pro
;
;
;INPUTS:
;filename: string: full filename of the saved CDF file. Routine bails if not set.
;
;global_att: IDL structure containing global attributes. Defined at a higher level. Routine will bail if this is not set.
;
;Set /qualc is using Mike Chaffins qual colors colortable. Leave if not.
;
;
;
;
;NOTES:
;No fields in any attributes can be blank strings (''), otherwise tplot2cdf fails. Use 'na' for now as placeholders.
;
;For tplot variables where the .v structure is a string (here, labels such as H+, He++, O+, O2+, CO2+), these must be converted below
; into flaot variables, to be compliant with PDS rules. These changes are made below for each variable (where needed). We won't make
; this change for the tplot save file equivalent files.
; 
;Here, we combine the density methods for light and heavy into one CDF file (combining mvn_sta_l3_density_heavy_method and
; mvn_sta_l3_density_light_method). This was based on feedback from PDS reviews, and because of changes required for the note above for
; the .v structure.
;
;2022-09-01: routine is updated to deal with the upcoming changes to the science tplot files, where only one density_method variable
; will be present (rather than separate for light and heavy ions).
;
;2024-06-27: added new structure elements in the .x attribute structure: spice_kernels and parent_files, are ech string arrays containing
;            the names of the spice kernels, and STATIC L2 files, that were used to generate these CDF files. This information is included
;            in the x attribute, which is then included in every output variable in the CDF file.
;
;.r /Users/cmfowler/IDL/STATIC_routines/CDFs/Software/mvn_sta_l3_cdf_density_v2.pro ;for testing only
;-
;

pro mvn_sta_l3_cdf_density_v2, filename, global_att, qualc=qualc, success=success

proname = 'mvn_sta_l3_cdf_density'

if size(filename,/type) ne 7 then begin
  print, ""
  print, proname, ": Filename must be set as a string."
  success=0
  return
endif

if size(filename,/type) eq 0 then begin
  print, ""
  print, proname, ": global_att must be set as a string."
  success=0
  return
endif

    ;Get SPICE kernels and parent files:
    get_data, 'mvn_sta_l3_density', data=dd, dlimit=dl, limit=s
    spiceloaded = s.spiceloaded
    parent_files = strjoin(s.parent_files,' ')

    ;Save unix time array as it's own tplot variable, where data.x is TT2000 and data.y are the corresponding UNIX times. This will be a
    ;separate tplot variable stored in the CDF structure:
    tnametime = 'mvn_sta_l3_density_unixtimes'
    store_data, tnametime, data={x: dd.x, y: dd.x}  ;all data.x arrays are identical between variables
      options, tnametime, ytitle='UNIX time'
    
    ;Add CDF structures to each tplot variable:
    tvars1 = ['mvn_sta_l3_density_method', 'mvn_sta_l3_density_att_mode', 'mvn_sta_l3_density', 'mvn_sta_l3_density_abs_uncertainty', $
              'mvn_sta_l3_density_perc_uncertainty', 'mvn_sta_l3_density_quality_flag', 'mvn_sta_l3_density_mvn_pos_mso', $
              'mvn_sta_l3_density_mvn_sza', 'mvn_sta_l3_density_mvn_alt_iau', 'mvn_sta_l3_density_unixtimes']
    neleTV = n_elements(tvars1)
    ;Add .cdf tag to structure: need to convert UNIX to TT2000 time before doing this, and save UNIX time for later:
    cdf_leap_second_init ;need to convert UNIX to TT2000
    for vv = 0l, neleTV-1l do begin
        get_data, tvars1[vv], data=ddtmp0, dlimit=dltmp, limit=lltmp  ;ddtmp0 is the original tplot structure
        time_unix = ddtmp0.x
        time_tt2000 = (long64((add_tt2000_offset(time_unix)-time_double('2000-01-01/12:00'))*1e9))  ;from J McT. I removed making this double(), as long64 is required for tplot2cdf whne using TT2000.
        
        ;Recreate data structure, as original double UNIX .x must be converted to long64:
        stags = tag_names(ddtmp0)  ;need to add each tag present:
        neleTGS = n_elements(stags)
        ddtmp = create_struct('x'   ,     time_tt2000)  ;start with tt2000 which is in every variable:
        for ns = 0l, neleTGS-1l do begin
            ;str_element,my_str,'my_tag_name','value',/add
            result = execute("if stags[ns] ne 'X' then str_element, ddtmp, stags[ns], ddtmp0."+stags[ns]+", /add")  ;Note 'X' must be upper case here!
        endfor
        ;Now, ddtmp is a duplicate of ddtmp0, but .X has been replaced with TT2000.

        ;Make sure data.v are floats and not strings, for PDS. Define the codes later on for each variable.
        ;This is messy, but need to check specific variables here:
        ;****This code is now obselete with udpated CDF routines 2024-07-17. Can remove once confirmed working.
      ;  case tvars1[vv] of
      ;      'mvn_sta_l3_density_att_mode' : str_element, ddtmp, "v", [1, 2], /add   ;NOTE: keep all these as integers for correct code in CDF file.                              
      ;      'mvn_sta_l3_density' : str_element, ddtmp, "v", [1, 2, 16, 32, 44], /add ;use amu/q values as the coding    
      ;      'mvn_sta_l3_density_abs_uncertainty' : str_element, ddtmp, "v", [1, 2, 16, 32, 44], /add
      ;      'mvn_sta_l3_density_perc_uncertainty' : str_element, ddtmp, "v", [1, 2, 16, 32, 44], /add
      ;      'mvn_sta_l3_density_quality_flag' : str_element, ddtmp, "v", [1, 2, 16, 32, 44], /add
      ;      'mvn_sta_l3_density_mvn_pos_mso' : str_element, ddtmp, "v", [1, 2, 3, 4], /add  ;label with numbers for position
      ;      'mvn_sta_l3_density_method' : str_element, ddtmp, "v", [1, 2, 16, 32, 44], /add    
      ;      else :    
      ;  endcase
        
        store_data, tvars1[vv], data=ddtmp, dlimit=dltmp, limit=lltmp ;resave variable
      ;**** This stuff can also be removed once new version is working:
      ;  ;Update CDF structure:
      ;  tplot_add_cdf_structure, tvars1[vv]  ;this adds '.cdf.' structure to the limits tag of this variable. But this routine doesn't keep the new unix_time tag, so add that below:
      ;  
      ;  ;Now that .cdf is added, add the unix_time field:
      ;  get_data, tvars1[vv], data=ddtmp, dlimit=dltmp, limit=lltmp
      ;  str_element, ddtmp, 'unix_time', time_unix, /add  ;add this to the tplot variable
      ;  store_data, tvars1[vv], data=ddtmp, dlimit=dltmp, limit=lltmp ;restore variable 
    endfor
        
    ;Edit meta data fields in CDF structures here. I decided to hard code this incase there are any specific fields. It's long and messy... urgh...
    ;The limit structure in each tplot variable will now have a .cdf tag, which contains:
    ; CDF.VARS - field that describe the data (tplot y variable)
    ; CDF.DEPEND_0 - this field correspond to the time (tplot x variable);
    ; CDF.DEPEND_1 - supporting data (tplot v variable, this is the 5 ion species in STATIC data)
    ; Note - the PDS want us to use TT2000 for the time variable, so, for each tplot variable below, I am going to convert UNIX time
    ; to TT2000, and store this in the .x tag. I'll add another field to the s.cdf structure containing the UNIX times.
    
    ;Identical to cdf_temperature_v2:
    ; get date ranges (for CDF files)
    ;    Launch       2013-11-18 UT
    ;    Nominal EOM  2032-01-01 UT

    date_range = time_double(['2013-11-18','2033-01-01'])

    epoch_range = time_epoch(date_range)
    tt2000_range = long64((add_tt2000_offset(date_range) $
      - time_double('2000-01-01/12:00'))*1e9)

    ;;;;; for saving spice you need to save:
    ;; naif (steal from Dave)
    ;; sclk (steal from Dave)
    ;
    ;; pck (orientation of planet wrt ecliptic)     Planetary CK
    ;; maven_v*.tf              MAVEN frames kernel
    ;; maven_misc.tf            MAVEN frames kernel additional
    ;; maven_static_v*.ti       STATIC instrument kernel
    ;; maven_orb_rec*.bsp    MAVEN SPK
    ;; mvn_sc_rel*.bc  MAVEN Spacecraft CK
    ;; mvn_app_rel*.bc MAVEN APP CK

    ; include SPICE kernels used
    ; spacecraft clock kernel
    i = where(strmatch(spiceloaded,'*sclk*',/fold), count)
    if (count gt 0) then driftname = file_basename(spiceloaded[i])

    ; leapseconds kernel
    j = where(strmatch(spiceloaded,'*.tls',/fold), count)
    if (count gt 0) then leapname = file_basename(spiceloaded[j])

    ; planetary ck kernel
    k = where(strmatch(spiceloaded,'pck*',/fold), count)
    if (count gt 0) then planckname = file_basename(spiceloaded[k])

    ; MAVEN frames kernel
    tmp = where(strmatch(spiceloaded,'maven_v*.tf',/fold), count)
    if (count gt 0) then mvnframename = file_basename(spiceloaded[tmp])

    ; additional MAVEN frames kernel
 ;   tmp = where(strmatch(spiceloaded,'maven_misc.tf',/fold), count)
 ;   if (count gt 0) then mvnframename2 = file_basename(spiceloaded[tmp])

    ; STATIC instrument kernel
    tmp = where(strmatch(spiceloaded,'maven_static_v*.ti',/fold), count)
    if (count gt 0) then staticframename = file_basename(spiceloaded[tmp])

    ;;;sometimes there are more than 1 of the following kernels
    ;;;if there are, then join them into a single string separated by a space

    ; MAVEN SPK kernel
    tmp = where(strmatch(spiceloaded,'maven_orb_rec*.bsp',/fold), count)
    if (count gt 0) then spkname = file_basename(spiceloaded[tmp])
    if (count gt 1) then spkname=strjoin(spkname[*],' ')

    ; MAVEN spacecraft CK kernel
    tmp = where(strmatch(spiceloaded,'mvn_sc_rel*.bc',/fold), count)
    if (count gt 0) then ckname = file_basename(spiceloaded[tmp])
    if (count gt 1) then ckname=strjoin(ckname[*],' ')

    ; MAVEN APP CK kernel
    tmp = where(strmatch(spiceloaded,'mvn_app_rel*.bc',/fold), count)
    if (count gt 0) then appckname = file_basename(spiceloaded[tmp])
    if (count gt 1) then appckname=strjoin(appckname[*],' ')


    ; create and populate CDF file

    fileid = cdf_create(filename, /single_file, /network_encoding, /clobber)

    ;;; CHRIS: you will need to add a variable here called something like
    ;;; "mass_per_charge" and use it as DEPENDS_1 for your density, uncertainty, etc. variables
    varlist = ['epoch', tvars1, 'mode_att_index', 'mso_index', 'geo_index', 'mass_per_charge']

    ;;; create the global attributes

    ; id0  = cdf_attcreate(fileid, 'TITLE',                      /global_scope)
    id1  = cdf_attcreate(fileid, 'Project',                    /global_scope)
    id2  = cdf_attcreate(fileid, 'Discipline',                 /global_scope)
    id3  = cdf_attcreate(fileid, 'Source_name',                /global_scope)
    id4  = cdf_attcreate(fileid, 'Descriptor',                 /global_scope)
    id5  = cdf_attcreate(fileid, 'Data_type',                  /global_scope)
    id6  = cdf_attcreate(fileid, 'Data_version',               /global_scope)
    id7  = cdf_attcreate(fileid, 'TEXT',                       /global_scope)
    ; id8  = cdf_attcreate(fileid, 'MODS',                       /global_scope)
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
    id19 = cdf_attcreate(fileid, 'Planetary_CK_kernel',         /global_scope)
    id20 = cdf_attcreate(fileid, 'MAVEN_frames_kernel',         /global_scope)
   ; id21 = cdf_attcreate(fileid, 'Additional_MAVEN_frames_kernel',         /global_scope)
    id22 = cdf_attcreate(fileid, 'STATIC_frame_kernel',         /global_scope)
    id23 = cdf_attcreate(fileid, 'MAVEN_SPK_kernel',         /global_scope)
    id24 = cdf_attcreate(fileid, 'MAVEN_spacecraft_CK_kernel',         /global_scope)
    id25 = cdf_attcreate(fileid, 'MAVEN_APP_CK_kernel',         /global_scope)


    ;        cdf_attput, fileid, 'TITLE',                      0, $
    ;          title
    cdf_attput, fileid, 'Project',                    0, $
      'MAVEN>Mars Atmosphere and Volatile EvolutioN Mission'
    cdf_attput, fileid, 'Discipline',                 0, $
      'Planetary Physics>Ionospheric Studies'
    cdf_attput, fileid, 'Source_name',                0, $
      'MAVEN>Mars Atmosphere and Volatile EvolutioN Mission'
    cdf_attput, fileid, 'Descriptor',                 0, $
      'STATIC>Supra-Thermal And Thermal Ion Composition Particle Distribution Moments'
    cdf_attput, fileid, 'Data_type',                  0, $
      'Time series plasma observations'
    cdf_attput, fileid, 'Data_version',               0, $
      global_att.data_version ; version
    cdf_attput, fileid, 'TEXT',                       0, $
      global_att.text
    ;        cdf_attput, fileid, 'MODS',                       0, $
    ;          'Revision 0'
    cdf_attput, fileid, 'Logical_file_id',            0, $
      global_att.logical_file_id
    cdf_attput, fileid, 'Logical_source',             0, $
      global_att.logical_source
    cdf_attput, fileid, 'Logical_source_description', 0, $
      global_att.logical_source_description
    cdf_attput, fileid, 'PI_name', 0, $
      global_att.pi_name
    cdf_attput, fileid, 'PI_affiliation',             0, $
      global_att.pi_affiliation
    cdf_attput, fileid, 'Instrument_type',            0, $
      global_att.instrument_type
    cdf_attput, fileid, 'Mission_group',              0, $
      'MAVEN'
    cdf_attput, fileid, 'Parents',                    0, $
      parent_files
    cdf_attput, fileid, 'Spacecraft_clock_kernel',    0, $
      driftname[0]
    cdf_attput, fileid, 'Leapseconds_kernel',         0, $
      leapname[0]
    cdf_attput, fileid, 'Planetary_CK_kernel',         0, $
      planckname[0]
    cdf_attput, fileid, 'MAVEN_frames_kernel',         0, $
      mvnframename[0]
   ;cdf_attput, fileid, 'Additional_MAVEN_frames_kernel',         0, $
   ;   mvnframename2[0]
    cdf_attput, fileid, 'STATIC_frame_kernel',         0, $
      staticframename[0]
    cdf_attput, fileid, 'MAVEN_SPK_kernel',         0, $
      spkname[0]
    cdf_attput, fileid, 'MAVEN_spacecraft_CK_kernel',         0, $
      ckname[0]
    cdf_attput, fileid, 'MAVEN_APP_CK_kernel',         0, $
      appckname[0]


    ;;;; create the variable attributes, then fill them in for each variable in the list.

    dummy = cdf_attcreate(fileid, 'FIELDNAM',     /variable_scope)
    dummy = cdf_attcreate(fileid, 'MONOTON',      /variable_scope)
    dummy = cdf_attcreate(fileid, 'FORMAT',       /variable_scope)
    dummy = cdf_attcreate(fileid, 'FORM_PTR',     /variable_scope)
    dummy = cdf_attcreate(fileid, 'LABLAXIS',     /variable_scope)
    dummy = cdf_attcreate(fileid, 'LABL_PTR_1',   /variable_scope)
    dummy = cdf_attcreate(fileid, 'LABL_PTR_2',   /variable_scope)
    dummy = cdf_attcreate(fileid, 'VAR_TYPE',     /variable_scope)
    dummy = cdf_attcreate(fileid, 'FILLVAL',      /variable_scope)
    dummy = cdf_attcreate(fileid, 'DEPEND_0',     /variable_scope)
    dummy = cdf_attcreate(fileid, 'DEPEND_1',     /variable_scope)
    dummy = cdf_attcreate(fileid, 'DEPEND_2',     /variable_scope)
    dummy = cdf_attcreate(fileid, 'DISPLAY_TYPE', /variable_scope)
    dummy = cdf_attcreate(fileid, 'VALIDMIN',     /variable_scope)
    dummy = cdf_attcreate(fileid, 'VALIDMAX',     /variable_scope)
    dummy = cdf_attcreate(fileid, 'SCALEMIN',     /variable_scope)
    dummy = cdf_attcreate(fileid, 'SCALEMAX',     /variable_scope)
    dummy = cdf_attcreate(fileid, 'TIME_BASE',    /variable_scope)
    dummy = cdf_attcreate(fileid, 'UNITS',        /variable_scope)
    dummy = cdf_attcreate(fileid, 'CATDESC',      /variable_scope)

  
    ;=====
    ;--0--
    ;=====
    ;epoch:

    vndx = (where(varlist eq 'epoch'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], /CDF_TIME_TT2000, /REC_VARY, /ZVARIABLE)

    cdf_attput, fileid, 'FIELDNAM',     varid, 'epoch',                /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid, 'I22',                        /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid, 'TT2000 time',                /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid, 'CDF_TIME_TT2000',               /ZVARIABLE
    ;cdf_attput, fileid, 'FILLVAL',      varid, long64(-9223372036854775808), /ZVARIABLE, /CDF_EPOCH
    cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',                /ZVARIABLE
    cdf_attput, fileid, 'VALIDMIN',  varlist[vndx], tt2000_range[0], /ZVARIABLE, /CDF_EPOCH
    cdf_attput, fileid, 'VALIDMAX',  varlist[vndx], tt2000_range[1], /ZVARIABLE, /CDF_EPOCH
    cdf_attput, fileid, 'SCALEMIN',  varlist[vndx], min(time_tt2000,/nan),       /ZVARIABLE, /CDF_EPOCH
    cdf_attput, fileid, 'SCALEMAX',  varlist[vndx], max(time_tt2000,/nan),  /ZVARIABLE, /CDF_EPOCH
    cdf_attput, fileid, 'TIME_BASE', varlist[vndx], 'J2000',         /ZVARIABLE
    cdf_attput, fileid, 'UNITS',     varlist[vndx], 'seconds',            /ZVARIABLE
    cdf_attput, fileid, 'MONOTON',   varlist[vndx], 'INCREASE',      /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',   varlist[vndx], 'TT2000 time',                 /ZVARIABLE

    cdf_varput, fileid, varlist[vndx], time_tt2000


    ;=====
    ;--1--
    ;=====
    ;mvn_sta_l3_density
    tvartmp='mvn_sta_l3_density'
    get_data, tvartmp, data=ddtmp, limit=s

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    dim_vary = [1]
    dim = 5
    vndx = (where(varlist eq 'mvn_sta_l3_density'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], dim_vary, dim=dim, /CDF_FLOAT, /ZVARIABLE)

    cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid, 'F1.0',        /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid, 'Ion density',  /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid, 'data', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid, !values.f_nan,  /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

    cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.0,                       /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 100000000.00,              /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN', varlist[vndx], min(ddtmp.y,/nan),         /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX', varlist[vndx], max(ddtmp.y,/nan),         /ZVARIABLE
    cdf_attput, fileid, 'UNITS',    varlist[vndx], '[cm^-3]',                 /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',  varlist[vndx], 'Ion density for each species (AMU/q value): H+ (1), He++ or H2+ (2), O+ (16), O2+ (32), CO2+ (44).', /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_0', varlist[vndx], 'epoch',                 /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_1', varlist[vndx], 'mass_per_charge',       /ZVARIABLE
    
    cdf_varput, fileid, varlist[vndx], transpose(ddtmp.y)
    ;str_element,cdf_y_attr_struct,'Labels','H+, He++ (m/q=2), O+, O2+, CO2+',/add  ;add to the cdf ;incase I need the label info

    ;###########
    ;V VARIABLE:
    ; needed for 2D arrays
    dim_vary = [1]
    dim = 5
    
    vndx = (where(varlist eq 'mass_per_charge'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], dim_vary,dim=dim, /CDF_FLOAT, /REC_NOVARY, /ZVARIABLE)
    cdf_varput, fileid, varlist[vndx], [1., 2., 16., 32., 44.]
    

    ;=====
    ;--1--
    ;=====
    ;mvn_sta_l3_density_method:
    tvartmp = 'mvn_sta_l3_density_method'
    get_data, tvartmp, data=ddtmp, limit=s  ;using s to keep same as crib sheet

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    dim_vary = [1]
    dim = 5
    vndx = (where(varlist eq 'mvn_sta_l3_density_method'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], dim_vary, dim=dim, /CDF_FLOAT, /ZVARIABLE)

    cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid, 'F1.0',        /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid, 'Density method, 0=high altitude, 1=periapsis',  /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid, !values.f_nan,  /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

    cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.0,              /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 1.0,              /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN', varlist[vndx], min(ddtmp.y,/nan),         /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX', varlist[vndx], max(ddtmp.y,/nan),         /ZVARIABLE
    cdf_attput, fileid, 'UNITS',    varlist[vndx], 'NA',                 /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',  varlist[vndx], 'Density derivation method for H+, He++ (m/q=2), O+, O2+, CO2+. 0 = high altitude method, 1 = periapsis method.', /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_0', varlist[vndx], 'epoch',                 /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_1', varlist[vndx], 'mass_per_charge',       /ZVARIABLE
    
    cdf_varput, fileid, varlist[vndx], transpose(ddtmp.y)

    ;###########
    ;V VARIABLE:
    ; needed for 2D arrays- only need to add each one (eg mass_per_charge) once (done above).

    
    ;=====
    ;--2--
    ;=====
    ;mvn_sta_l3_density_att_mode
    tvartmp='mvn_sta_l3_density_att_mode'
    get_data, tvartmp, data=ddtmp, limit=s

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    dim_vary = [1]
    dim = 2
    vndx = (where(varlist eq 'mvn_sta_l3_density_att_mode'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], dim_vary, dim=dim, /CDF_FLOAT, /ZVARIABLE)

    cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid, 'F1.0',        /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid, 'STATIC mode and attenuator states. 0 = mode, 1 = attenuator.',  /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid, !values.f_nan,  /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

    cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.0,              /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 7.0,              /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN', varlist[vndx], min(ddtmp.y,/nan),         /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX', varlist[vndx], max(ddtmp.y,/nan),         /ZVARIABLE
    cdf_attput, fileid, 'UNITS',    varlist[vndx], 'NA',                 /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',  varlist[vndx], 'STATIC mode and attenuator states. Mode, can have values =<7. Attenuator can have values 0-3: 0 = no attenuation, 1 = electrostatic (x10), 2 = mechanical (x100), 3 = electrostatic and mechanical (x1000).', /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_0', varlist[vndx], 'epoch',                 /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_1', varlist[vndx], 'mode_att_index',       /ZVARIABLE

    cdf_varput, fileid, varlist[vndx], transpose(ddtmp.y)

    ;###########
    ;V VARIABLE:
    ; needed for 2D arrays
    ; make it a byte because it's more efficient for storage     
    dim_vary = [1]
    dim = 2
    vndx = (where(varlist eq 'mode_att_index'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], dim_vary, dim=dim, /CDF_BYTE, /REC_NOVARY, /ZVARIABLE)
    cdf_varput, fileid, varlist[vndx], bindgen(2)


    ;=====
    ;--3--
    ;=====
    ;mvn_sta_l3_density_abs_uncertainty
    tvartmp='mvn_sta_l3_density_abs_uncertainty'
    get_data, tvartmp, data=ddtmp, limit=s

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    dim_vary = [1]
    dim = 5
    vndx = (where(varlist eq 'mvn_sta_l3_density_abs_uncertainty'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], dim_vary, dim=dim, /CDF_FLOAT, /ZVARIABLE)

    cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid, 'F1.0',        /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid, 'Uncertainty in ion density.',  /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid, !values.f_nan,  /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

    cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.0,              /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 100000000.0,              /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN', varlist[vndx], min(ddtmp.y,/nan),         /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX', varlist[vndx], max(ddtmp.y,/nan),         /ZVARIABLE
    cdf_attput, fileid, 'UNITS',    varlist[vndx], 'cm^-3',                 /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',  varlist[vndx], 'Absolute uncertainty in ion density for H+, He++ or H2+ (m/q=2), O+, O2+, CO2+, in units cm^-3.', /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_0', varlist[vndx], 'epoch',                 /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_1', varlist[vndx], 'mass_per_charge',       /ZVARIABLE

    cdf_varput, fileid, varlist[vndx], transpose(ddtmp.y)

    ;###########
    ;V VARIABLE:
    ; needed for 2D arrays

 
    ;=====
    ;--4--
    ;=====
    ;mvn_sta_l3_density_perc_uncertainty
    tvartmp='mvn_sta_l3_density_perc_uncertainty'
    get_data, tvartmp, data=ddtmp, limit=s

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    dim_vary = [1]
    dim = 5
    vndx = (where(varlist eq 'mvn_sta_l3_density_perc_uncertainty'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], dim_vary, dim=dim, /CDF_FLOAT, /ZVARIABLE)

    cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid, 'F1.0',        /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid, 'Uncertainty in ion density.',  /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid, !values.f_nan,  /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

    cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.0,              /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 100000000.0,              /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN', varlist[vndx], min(ddtmp.y,/nan),         /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX', varlist[vndx], max(ddtmp.y,/nan),         /ZVARIABLE
    cdf_attput, fileid, 'UNITS',    varlist[vndx], '%',                 /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',  varlist[vndx], 'Percentage uncertainty in ion density for H+, He++ or H2+ (m/q=2), O+, O2+, CO2+, in units of %.', /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_0', varlist[vndx], 'epoch',                 /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_1', varlist[vndx], 'mass_per_charge',       /ZVARIABLE

    cdf_varput, fileid, varlist[vndx], transpose(ddtmp.y)

    ;###########
    ;V VARIABLE:
    ; needed for 2D arrays
    

    ;=====
    ;--5--
    ;=====
    ;mvn_sta_l3_density_quality_flag
    tvartmp='mvn_sta_l3_density_quality_flag'
    get_data, tvartmp, data=ddtmp, limit=s
      
    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    dim_vary = [1]
    dim = 5
    vndx = (where(varlist eq 'mvn_sta_l3_density_quality_flag'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], dim_vary, dim=dim, /CDF_FLOAT, /ZVARIABLE)

    cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid, 'F1.0',        /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid, 'Quality flag, 0 = good, 1 = caution.',  /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid, !values.f_nan,  /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

    cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.0,              /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 1.0,              /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN', varlist[vndx], min(ddtmp.y,/nan),         /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX', varlist[vndx], max(ddtmp.y,/nan),         /ZVARIABLE
    cdf_attput, fileid, 'UNITS',    varlist[vndx], 'NA',                 /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',  varlist[vndx], 'Quality flag for ion density for H+, He++ or H2+ (amu/q=2), O+, O2+, CO2+. 0 = good, 1 = caution.', /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_0', varlist[vndx], 'epoch',                 /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_1', varlist[vndx], 'mass_per_charge',       /ZVARIABLE

    cdf_varput, fileid, varlist[vndx], transpose(ddtmp.y)

    ;###########
    ;V VARIABLE:
    ; needed for 2D arrays


    ;=====
    ;--6--
    ;=====
    ;mvn_sta_l3_density_mvn_pos_mso
    tvartmp='mvn_sta_l3_density_mvn_pos_mso'
    get_data, tvartmp, data=ddtmp, limit=s
    
    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    dim_vary = [1]
    dim = 4
    vndx = (where(varlist eq 'mvn_sta_l3_density_mvn_pos_mso'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], dim_vary, dim=dim, /CDF_FLOAT, /ZVARIABLE)

    cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid, 'F1.0',        /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid, 'Position [MSO, km].',  /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid, !values.f_nan,  /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

    cdf_attput, fileid, 'VALIDMIN', varlist[vndx], -10000000.0,              /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 10000000.0,              /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN', varlist[vndx], min(ddtmp.y,/nan),         /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX', varlist[vndx], max(ddtmp.y,/nan),         /ZVARIABLE
    cdf_attput, fileid, 'UNITS',    varlist[vndx], 'km',                 /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',  varlist[vndx], 'MAVEN X (1), Y (2), Z (3) and R (4) position in the MSO coordinate system, units of km.', /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_0', varlist[vndx], 'epoch',                 /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_1', varlist[vndx], 'mso_index',       /ZVARIABLE

    cdf_varput, fileid, varlist[vndx], transpose(ddtmp.y)

    ;###########
    ;V VARIABLE:
    ; needed for 2D arrays
    dim_vary = [1]
    dim = 4
    vndx = (where(varlist eq 'mso_index'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx],dim_vary,dim=dim, /CDF_BYTE, /REC_NOVARY, /ZVARIABLE)
    cdf_varput, fileid, varlist[vndx], bindgen(4)+1

    
    ;=====
    ;--7--
    ;=====
    ;mvn_sta_l3_density_mvn_sza
    tvartmp='mvn_sta_l3_density_mvn_sza'
    get_data, tvartmp, data=ddtmp, limit=s

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    vndx = (where(varlist eq 'mvn_sta_l3_density_mvn_sza'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], /CDF_FLOAT, /ZVARIABLE)

    cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid, 'F1.0',        /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid, 'SZA [degrees].',  /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid, !values.f_nan,  /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

    cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.0,              /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 180.0,              /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN', varlist[vndx], min(ddtmp.y,/nan),         /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX', varlist[vndx], max(ddtmp.y,/nan),         /ZVARIABLE
    cdf_attput, fileid, 'UNITS',    varlist[vndx], 'Degrees',                 /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',  varlist[vndx], 'MAVEN solar zenith angle, units of degrees.', /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_0', varlist[vndx], 'epoch',                 /ZVARIABLE

    cdf_varput, fileid, varlist[vndx], ddtmp.y

    ;###########
    ;V VARIABLE:
    ; needed for 2D arrays - not needed here

    
    ;=====
    ;--8--
    ;=====
    ;mvn_sta_l3_density_mvn_alt_iau
    tvartmp='mvn_sta_l3_density_mvn_alt_iau'
    get_data, tvartmp, data=ddtmp, limit=s

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    vndx = (where(varlist eq 'mvn_sta_l3_density_mvn_alt_iau'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], /CDF_FLOAT, /ZVARIABLE)

    cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid, 'F1.0',        /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid, 'Altitude [IAU, km].',  /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid, !values.f_nan,  /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

    cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.0,              /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 100000000.0,              /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN', varlist[vndx], min(ddtmp.y,/nan),         /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX', varlist[vndx], max(ddtmp.y,/nan),         /ZVARIABLE
    cdf_attput, fileid, 'UNITS',    varlist[vndx], 'km',                 /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',  varlist[vndx], 'MAVEN altitude in the IAU reference frame, units of km.', /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_0', varlist[vndx], 'epoch',                 /ZVARIABLE

    cdf_varput, fileid, varlist[vndx], ddtmp.y

    ;###########
    ;V VARIABLE:
    ; needed for 2D arrays - not needed here

    ;=====
    ;--9--
    ;=====
    ;Store UNIX times as a new variable, rather than as metadata. Tidies up files and will save space - no duplicate info in each
    ;variable.
    ;mvn_sta_l3_density_unixtimes
    tvartmp='mvn_sta_l3_density_unixtimes'
    get_data, tvartmp, data=ddtmp, limit=s

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y

    vndx = (where(varlist eq 'mvn_sta_l3_density_unixtimes'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], /CDF_DOUBLE, /ZVARIABLE)

    cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid, 'UNIX time [s]',  /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid, !values.f_nan,         /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

    cdf_attput, fileid, 'VALIDMIN', varlist[vndx], date_range[0],             /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX', varlist[vndx], date_range[1],                 /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN', varlist[vndx], min(ddtmp.y,/nan),                 /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX', varlist[vndx], max(ddtmp.y,/nan),                 /ZVARIABLE
    cdf_attput, fileid, 'UNITS',    varlist[vndx], 's',                 /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',  varlist[vndx], 'UNIX timestamps that correspond to the TT2000 timestamps.', /ZVARIABLE

    cdf_varput, fileid, varlist[vndx], ddtmp.y

    ;===========
    ;Final save:
    ;===========
    cdf_close,fileid

success=1

end


