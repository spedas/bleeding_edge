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
;
;.r /Users/cmfowler/IDL/STATIC_routines/CDFs/Software/mvn_sta_l3_cdf_density.pro ;for testing only
;-
;

pro mvn_sta_l3_cdf_temperature_v2, filename, global_att, qualc=qualc, success=success

proname = 'mvn_sta_l3_cdf_temperature'

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

    ;get the spice kernels and parent files from the tplot structure

    tvartmp = 'mvn_sta_l3_temperature_o2+'
    get_data, tvartmp, data=dd, dlimit=dl, limit=s
    spiceloaded = s.spiceloaded  
    parent_files = strjoin(s.parent_files,' ')
    

    ;Save unix time array as it's own tplot variable, where data.x is TT2000 and data.y are the corresponding UNIX times. This will be a
    ;separate tplot variable stored in the CDF structure:
    tnametime = 'mvn_sta_l3_temperature_unixtimes'
    store_data, tnametime, data={x: dd.x, y: dd.x}  ;all data.x arrays are identical between variables
    options, tnametime, ytitle='UNIX time'

    ;Add CDF structures to each tplot variable:
    tvars1 = ['mvn_sta_l3_temperature_product','mvn_sta_l3_temperature_o2+', 'mvn_sta_l3_temperature_abs_uncertainty', 'mvn_sta_l3_temperature_quality_flag', $
              'mvn_sta_l3_temperature_mvn_pos_geo', 'mvn_sta_l3_temperature_mvn_pos_mso', 'mvn_sta_l3_temperature_mvn_sza', $
              'mvn_sta_l3_temperature_mvn_lst','mvn_sta_l3_temperature_mvn_alt_iau','mvn_sta_l3_temperature_att_mode','mvn_sta_l3_temperature_unixtimes']
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

        store_data, tvars1[vv], data=ddtmp, dlimit=dltmp, limit=lltmp ;resave variable
     endfor
     
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
;     tmp = where(strmatch(spiceloaded,'maven_misc.tf',/fold), count)
;     if (count gt 0) then mvnframename2 = file_basename(spiceloaded[tmp])

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
        varlist = ['epoch', tvars1, 'mode_att_index', 'mso_index','geo_index']
        

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
;        id21 = cdf_attcreate(fileid, 'Additional_MAVEN_frames_kernel',         /global_scope)
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
;        cdf_attput, fileid, 'Additional_MAVEN_frames_kernel',         0, $
;          mvnframename2[0]
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
    cdf_attput, fileid, 'CATDESC',   varlist[vndx], $
      'TT2000 time',                 /ZVARIABLE

    cdf_varput, fileid, varlist[vndx], time_tt2000


    ;=====
    ;--1--
    ;=====
    ;mvn_sta_l3_temperature_product:
    tvartmp = 'mvn_sta_l3_temperature_product'
    get_data, tvartmp, data=ddtmp, limit=s  
    
    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    
    vndx = (where(varlist eq 'mvn_sta_l3_temperature_product'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], /CDF_FLOAT, /ZVARIABLE)

    cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid, 'F1.0',        /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid, 'Temperature method, 0=energy beamwidth, 1=angular beamwidth',  /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid, !values.f_nan,         /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

    cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.0,                 /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 1.0,                 /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN', varlist[vndx], 0.,                 /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX', varlist[vndx], 1.,                 /ZVARIABLE
    cdf_attput, fileid, 'UNITS',    varlist[vndx], 'na',                 /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',  varlist[vndx],  'Temperature derivation method for O2+. 0 = energy beamwidth from c6 data, 1 = angular beamwidth from c8 data.', /ZVARIABLE

    cdf_varput, fileid, varlist[vndx], ddtmp.y

    ;=====
    ;--2--
    ;=====
    ;mvn_sta_l3_sta_att_mode
     tvartmp='mvn_sta_l3_temperature_att_mode'
     get_data, tvartmp, data=ddtmp, limit=s
 
    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    
     dim_vary = [1]
     dim = 2
     vndx = (where(varlist eq 'mvn_sta_l3_temperature_att_mode'))[0]
     varid = cdf_varcreate(fileid, varlist[vndx], /CDF_FLOAT, dim_vary, DIM = dim, $
        /ZVARIABLE)

    cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid, 'F1.0',        /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid, 'STATIC mode and attenuator state. 0=mode, 1=attenuator',  /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid, 'metadata', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid,  !values.f_nan,         /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

    cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.,                      /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 7,                   /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN', varlist[vndx], 0.,                      /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX', varlist[vndx], 7,                    /ZVARIABLE
    cdf_attput, fileid, 'UNITS',    varlist[vndx], 'na',                /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',  varlist[vndx], 'STATIC mode and attenuator states. Mode, can have values =<7. Attenuator can have values 0-3: 0 = no attenuation, 1 = electrostatic (x10), 2 = mechanical (x100), 3 = electrostatic and mechanical (x1000).', /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_0', varlist[vndx], 'epoch',                 /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_1', varlist[vndx], 'mode_att_index',                /ZVARIABLE
      
    cdf_varput, fileid, varlist[vndx], transpose(ddtmp.y)
    ;; transpose is needed because IDL is column dominant and CDFs are normal row dominant
    
    ;###########
    ;V VARIABLE:
    ; needed for 2D arrays
    ; make it a byte because it's more efficient for storage
    dim_vary = [1]
    dim = 2
    vndx = (where(varlist eq 'mode_att_index'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], dim_vary, dim=dim, /CDF_BYTE, /REC_NOVARY, $
      /ZVARIABLE)
    cdf_varput, fileid, varlist[vndx], bindgen(2)
    
    ;=====
    ;--3--
    ;=====
    ;mvn_sta_l3_temperature
    tvartmp='mvn_sta_l3_temperature_o2+'
    get_data, tvartmp, data=ddtmp, limit=s
        
    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    
    vndx = (where(varlist eq 'mvn_sta_l3_temperature_o2+'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], /CDF_FLOAT, /ZVARIABLE)

    cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid, 'Ion temperature',  /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid, 'data', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid, !values.f_nan,         /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

    cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.0,                 /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 100.0,                 /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN', varlist[vndx], min(ddtmp.y,/nan),                 /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX', varlist[vndx], max(ddtmp.y,/nan),                 /ZVARIABLE
    cdf_attput, fileid, 'UNITS',    varlist[vndx], 'eV',                 /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',  varlist[vndx], 'Ion temperature for the Maxwellian core of the O2+.', /ZVARIABLE

    cdf_varput, fileid, varlist[vndx], ddtmp.y   

    ;=====
    ;--4--
    ;=====
    ;mvn_sta_l3_temperature_abs_uncertainty
    tvartmp='mvn_sta_l3_temperature_abs_uncertainty'
    get_data, tvartmp, data=ddtmp, limit=s

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    
    vndx = (where(varlist eq 'mvn_sta_l3_temperature_abs_uncertainty'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], /CDF_FLOAT, /ZVARIABLE)

    cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid, 'Uncertainty in ion temperature [eV]',  /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid, !values.f_nan,         /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

    cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.0,                 /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 100.0,                 /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN', varlist[vndx], min(ddtmp.y,/nan),                 /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX', varlist[vndx], max(ddtmp.y,/nan),                 /ZVARIABLE
    cdf_attput, fileid, 'UNITS',    varlist[vndx], 'eV',                 /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',  varlist[vndx], 'Absolute uncertainty in ion temperature for O2+.', /ZVARIABLE

    cdf_varput, fileid, varlist[vndx], ddtmp.y

    ;=====
    ;--5--
    ;=====
    ;mvn_sta_l3_temperature_quality_flag
    tvartmp='mvn_sta_l3_temperature_quality_flag'
    get_data, tvartmp, data=ddtmp, limit=s

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    
    vndx = (where(varlist eq 'mvn_sta_l3_temperature_quality_flag'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], /CDF_FLOAT, /ZVARIABLE)

    cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid, 'F1.0',        /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid, 'Quality flag, 0=good, 1=caution.',  /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid, 'metadata', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid, !values.f_nan,         /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

    cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.0,                 /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 1.0,                 /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN', varlist[vndx], min(ddtmp.y,/nan),                 /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX', varlist[vndx], max(ddtmp.y,/nan),                 /ZVARIABLE
    cdf_attput, fileid, 'UNITS',    varlist[vndx], 'na',                 /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',  varlist[vndx], 'Quality flag for ion temperature for O2+. 0 = good, 1 = caution.', /ZVARIABLE

    cdf_varput, fileid, varlist[vndx], ddtmp.y

    ;=====
    ;--6--
    ;=====
    ;mvn_sta_l3_temperature_mvn_pos_mso
    tvartmp='mvn_sta_l3_temperature_mvn_pos_mso'
    get_data, tvartmp, data=ddtmp, limit=s

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    
    dim_vary = [1]
    dim = 3
    vndx = (where(varlist eq 'mvn_sta_l3_temperature_mvn_pos_mso'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], /CDF_FLOAT, dim_vary, DIM = dim, $
      /ZVARIABLE)

    cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid, 'F15.3',        /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid, 'Position [MSO, km]',  /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid,  !values.f_nan,         /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

    cdf_attput, fileid, 'VALIDMIN', varlist[vndx], -10000.,                      /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 10000,                   /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN', varlist[vndx], min(ddtmp.y,/nan),                      /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX', varlist[vndx], max(ddtmp.y,/nan),                    /ZVARIABLE
    cdf_attput, fileid, 'UNITS',    varlist[vndx], 'km',                /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',  varlist[vndx], 'MAVEN X (0), Y (1), Z (2) position in the MSO coordinate system, units of km.', /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_0', varlist[vndx], 'epoch',                 /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_1', varlist[vndx], 'mso_index',                /ZVARIABLE
    
    cdf_varput, fileid, varlist[vndx], transpose(ddtmp.y)
    
    ;###########
    ;V VARIABLE:
    ; needed for 2D arrays
    ; make it a byte because it's more efficient for storage
    
    dim_vary = [1]
    dim = 3

    vndx = (where(varlist eq 'mso_index'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx],dim_vary,dim=dim, /CDF_BYTE, /REC_NOVARY, $
      /ZVARIABLE)
    cdf_varput, fileid, varlist[vndx], bindgen(3)
    
    ;=====
    ;--7--
    ;=====
    ;mvn_sta_l3_temperature_mvn_pos_geo
    tvartmp='mvn_sta_l3_temperature_mvn_pos_geo'
    get_data, tvartmp, data=ddtmp, limit=s

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    
    dim_vary = [1]
    dim = 3
    vndx = (where(varlist eq 'mvn_sta_l3_temperature_mvn_pos_geo'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], /CDF_FLOAT, dim_vary, DIM = dim, $
      /ZVARIABLE)

    cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid, 'F15.3',        /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid, 'Position [GEO, km]',  /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid,  !values.f_nan,         /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

    cdf_attput, fileid, 'VALIDMIN', varlist[vndx], -10000.,                      /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 10000,                   /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN', varlist[vndx], min(ddtmp.y,/nan),                      /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX', varlist[vndx], max(ddtmp.y,/nan),                    /ZVARIABLE
    cdf_attput, fileid, 'UNITS',    varlist[vndx], 'km',                /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',  varlist[vndx], 'MAVEN X (0), Y (1), Z (2) position in the GEO coordinate system, units of km.', /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_0', varlist[vndx], 'epoch',                 /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_1', varlist[vndx], 'geo_index',                /ZVARIABLE
    
    cdf_varput, fileid, varlist[vndx], transpose(ddtmp.y)
    
    ;###########
    ;V VARIABLE:
    ; needed for 2D arrays
    ; make it a byte because it's more efficient for storage
    dim_vary = [1]
    dim = 3
    vndx = (where(varlist eq 'geo_index'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], dim_vary, dim=dim, /CDF_UINT1, /REC_NOVARY, $
      /ZVARIABLE)
    cdf_varput, fileid, varlist[vndx], bindgen(3)
 
    ;=====
    ;--8--
    ;=====
    ;mvn_sta_l3_temperature_mvn_sza
    tvartmp='mvn_sta_l3_temperature_mvn_sza'
    get_data, tvartmp, data=ddtmp, limit=s

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    
    vndx = (where(varlist eq 'mvn_sta_l3_temperature_mvn_sza'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], /CDF_FLOAT, /ZVARIABLE)

    cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid, 'F5.2',        /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid, 'SZA [degrees]',  /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid, !values.f_nan,         /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

    cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.0,                 /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 180.0,                 /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN', varlist[vndx], min(ddtmp.y,/nan),                 /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX', varlist[vndx], max(ddtmp.y,/nan),                 /ZVARIABLE
    cdf_attput, fileid, 'UNITS',    varlist[vndx], 'degrees',                 /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',  varlist[vndx], 'MAVEN solar zenith angle, units of degrees.', /ZVARIABLE

    cdf_varput, fileid, varlist[vndx], ddtmp.y
        
    ;=====
    ;--9--
    ;=====
    ;mvn_sta_l3_temperature_mvn_lst
    tvartmp='mvn_sta_l3_temperature_mvn_lst'
    get_data, tvartmp, data=ddtmp, limit=s

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    
    vndx = (where(varlist eq 'mvn_sta_l3_temperature_mvn_lst'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], /CDF_FLOAT, /ZVARIABLE)

    cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid, 'F5.2',        /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid, 'LST [hours]',  /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid, !values.f_nan,         /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

    cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.0,                 /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 24.0,                 /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN', varlist[vndx], min(ddtmp.y,/nan),                 /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX', varlist[vndx], max(ddtmp.y,/nan),                 /ZVARIABLE
    cdf_attput, fileid, 'UNITS',    varlist[vndx], 'hours',                 /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',  varlist[vndx], 'MAVEN local solar time, units of hours.', /ZVARIABLE

    cdf_varput, fileid, varlist[vndx], ddtmp.y
        
    ;=====
    ;--10--
    ;=====
    ;mvn_sta_l3_temperature_mvn_alt_iau
    tvartmp='mvn_sta_l3_temperature_mvn_alt_iau'
    get_data, tvartmp, data=ddtmp, limit=s

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    
    vndx = (where(varlist eq 'mvn_sta_l3_temperature_mvn_alt_iau'))[0]
    varid = cdf_varcreate(fileid, varlist[vndx], /CDF_FLOAT, /ZVARIABLE)

    cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid, 'Altitude [IAU, km]',  /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid, !values.f_nan,         /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

    cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.0,                 /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 10000.0,                 /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN', varlist[vndx], min(ddtmp.y,/nan),                 /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX', varlist[vndx], max(ddtmp.y,/nan),                 /ZVARIABLE
    cdf_attput, fileid, 'UNITS',    varlist[vndx], 'km',                 /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',  varlist[vndx], 'MAVEN altitude in the IAU reference frame, units of km.', /ZVARIABLE

    cdf_varput, fileid, varlist[vndx], ddtmp.y
       
    ;=====
    ;-11--
    ;=====
    ;Store UNIX times as a new variable, rather than as metadata. Tidies up files and will save space - no duplicate info in each
    ;variable.
    tvartmp='mvn_sta_l3_temperature_unixtimes'
    get_data, tvartmp, data=ddtmp, limit=s

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    
    vndx = (where(varlist eq 'mvn_sta_l3_temperature_unixtimes'))[0]
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


