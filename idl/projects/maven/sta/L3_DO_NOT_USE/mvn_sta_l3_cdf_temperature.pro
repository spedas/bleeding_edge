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

pro mvn_sta_l3_cdf_temperature, filename, global_att, qualc=qualc, success=success

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

    tvartmp = 'mvn_sta_l3_temperature_o2+'
    get_data, tvartmp, data=dd, dlimit=dl, limit=s
    spiceloaded = s.spiceloaded  
    parent_files = s.parent_files

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

        ;Make sure data.v are floats and not strings, for PDS. Define the codes later on for each variable.
        ;This is messy, but need to check specific variables here:
        case tvars1[vv] of
            'mvn_sta_l3_temperature_att_mode' : begin
              str_element, ddtmp, "v", [1, 2], /add  
              str_element, dltmp, "LABL_PTR_1", ['Att', 'Mode'],/add
              end ;NOTE: keep all these as integers for correct code in CDF file.                              
            'mvn_sta_l3_temperature_mvn_pos_mso' : str_element, ddtmp, "v", [1, 2, 3], /add  ;label with numbers for position
            'mvn_sta_l3_temperature_mvn_pos_geo' : str_element, ddtmp, "v", [1, 2, 3], /add    
            else :    
        endcase
        
        store_data, tvars1[vv], data=ddtmp, dlimit=dltmp, limit=lltmp ;resave variable

        ;Update CDF structure:
        tplot_add_cdf_structure, tvars1[vv]  ;this adds '.cdf.' structure to the limits tag of this variable. But this routine doesn't keep the new unix_time tag, so add that below:
        
        ;Now that .cdf is added, add the unix_time field:
        get_data, tvars1[vv], data=ddtmp, dlimit=dltmp, limit=lltmp
        str_element, ddtmp, 'unix_time', time_unix, /add  ;add this to the tplot variable
        store_data, tvars1[vv], data=ddtmp, dlimit=dltmp, limit=lltmp ;restore variable
   
    endfor
    
    ;Edit meta data fields in CDF structures here. I decided to hard code this incase there are any specific fields. It's long and messy... urgh...
    ;The limit structure in each tplot variable will now have a .cdf tag, which contains:
    ; CDF.VARS - field that describe the data (tplot y variable)
    ; CDF.DEPEND_0 - this field correspond to the time (tplot x variable);
    ; CDF.DEPEND_1 - supporting data (tplot v variable, this is the 5 ion species in STATIC data)
    ; Note - the PDS want us to use TT2000 for the time variable, so, for each tplot variable below, I am going to convert UNIX time
    ; to TT2000, and store this in the .x tag. I'll add another field to the s.cdf structure containing the UNIX times.
    
    
    ;=====
    ;--1--
    ;=====
    ;mvn_sta_l3_temperature_product:
    tvartmp = 'mvn_sta_l3_temperature_product'
    get_data, tvartmp, data=ddtmp, limit=s  ;using s to keep same as crib sheet

    ;##############
    ;TIME VARIABLE (depend_0):
    ; To define the CDF attributes retrieve the structure that is stored in "attrptr" pointer
    ; DEPEND_0 correspond to x. Note, cdf_x_attr_struct can be used for each tplot variable - it won't change.
    cdf_x_attr_struct = *s.CDF.DEPEND_0.attrptr  ;the * allows us to get the ptr (without *, variable remains as a ptr)
    cdf_x_attr_struct.CATDESC = 'TT2000 time'
    cdf_x_attr_struct.LABLAXIS = 'TT2000 time'
    cdf_x_attr_struct.VAR_TYPE = 'CDF_TIME_TT2000'  
    cdf_x_attr_struct.UNITS = 'seconds'
    str_element, cdf_x_attr_struct, 'MONOTON', 'INCREASE', /add
    str_element, cdf_x_attr_struct, 'scalemin', min(time_tt2000,/nan), /add
    str_element, cdf_x_attr_struct, 'scalemax', max(time_tt2000,/nan), /add
    str_element, cdf_x_attr_struct, 'spice_kernels', spiceloaded, /add
    str_element, cdf_x_attr_struct, 'parent_files', parent_files, /add
    cdf_x_attr_struct.FORMAT = 'I22'  ;need to check the right code from Joe Mafi   
    
    s.CDF.DEPEND_0.attrptr = ptr_new(cdf_x_attr_struct)  ;save updated CDF structure - use this on all following tplot variables
    
    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    cdf_y_attr_struct = *s.CDF.VARS.attrptr  ;copy structure
    cdf_y_attr_struct.CATDESC = 'Temperature derivation method for O2+. 0 = energy beamwidth from c6 data, 1 = angular beamwidth from c8 data.'
    cdf_y_attr_struct.LABLAXIS = 'Temperature method, 0=energy beamwidth, 1=angular beamwidth'
    cdf_y_attr_struct.UNITS = 'na'
    cdf_y_attr_struct.VAR_TYPE = 'Float number'
    cdf_y_attr_struct.FILLVAL = !values.f_nan
    str_element,cdf_y_attr_struct,'VAR_TYPE','data',/add  ;this seems to be needed for cdf_var_atts to find the 'data' type
    str_element, cdf_y_attr_struct, 'MONOTON', 'INCREASE', /add
    str_element, cdf_y_attr_struct, 'scalemin', 0
    str_element, cdf_y_attr_struct, 'scalemax', 1
    
    s.CDF.VARS.attrptr = ptr_new(cdf_y_attr_struct)

    ;###########
    ;V VARIABLE (depend_1):
    ; Depend_1 corresponds to each ion species
    ;None for a 1D Y array.

    ;Save CDF structure into tplot variable
    options,tvartmp,'CDF', s.CDF

    ;=====
    ;--2--
    ;=====
    ;mvn_sta_l3_sta_att_mode
     tvartmp='mvn_sta_l3_temperature_att_mode'
     get_data, tvartmp, data=ddtmp, limit=s
 
    ;##############
    ;TIME VARIABLE (depend_0):
    ; To define the CDF attributes retrieve the structure that is stored in "attrptr" pointer
    ; DEPEND_0 correspond to x
    s.CDF.DEPEND_0.attrptr = ptr_new(cdf_x_attr_struct)  ;save updated CDF structure

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    cdf_y_attr_struct = *s.CDF.VARS.attrptr  ;copy structure
    cdf_y_attr_struct.CATDESC = 'STATIC mode and attenuator states. Mode, can have values =<7. Attenuator can have values 0-3: 0 = no attenuation, 1 = electrostatic (x10), 2 = mechanical (x100), 3 = electrostatic and mechanical (x1000).'
    cdf_y_attr_struct.LABLAXIS = 'STATIC mode and attenuator'
    cdf_y_attr_struct.UNITS = 'na'
    cdf_y_attr_struct.VAR_TYPE = 'Float number'
    cdf_y_attr_struct.FILLVAL = !values.f_nan
    str_element,cdf_y_attr_struct,'VAR_TYPE','data',/add  ;this seems to be needed for cdf_var_atts to find the 'data' type
    str_element,cdf_y_attr_struct,'Labels','Mode, attenuator',/add  ;add to the cdf
    str_element, cdf_y_attr_struct, 'MONOTON', 'INCREASE', /add
    str_element, cdf_y_attr_struct, 'scalemin', 0
    str_element, cdf_y_attr_struct, 'scalemax', 7
    
    s.CDF.VARS.attrptr = ptr_new(cdf_y_attr_struct)

    ;###########
    ;V VARIABLE (depend_1):
    ; Depend_1 corresponds to each ion species
    cdf_v_attr_struct = *s.CDF.VARS.attrptr  ;copy structure
    cdf_v_attr_struct.CATDESC = 'STATIC mode and attenuator states. 1 = mode, 2 = attenuator.'
    cdf_v_attr_struct.LABLAXIS = 'STATIC mode and attenuator'
    cdf_v_attr_struct.UNITS = 'na'  ;note: no fields can be '' otherwise this causes tplot2cdf_vars_save to crash later
    cdf_v_attr_struct.VAR_TYPE = 'support_data'
    cdf_v_attr_struct.FORMAT = 'I1'
    cdf_v_attr_struct.FILLVAL = !values.f_nan
    cdf_v_attr_struct.validmin = 0
    cdf_v_attr_struct.validmax = 100
    ;The following is needed to convert the FILLVAL type; it gets stuck as INT = 0, which is the validmin value. This chagnes if to FLOAT = NaN
    str_element, cdf_v_attr_struct, 'FILLVAL', !values.f_nan, /add
    str_element, cdf_v_attr_struct, 'MONOTON', 'INCREASE', /add
    str_element, cdf_v_attr_struct, 'scalemin', 1
    str_element, cdf_v_attr_struct, 'scalemax', 2
    
    s.CDF.DEPEND_1.attrptr = ptr_new(cdf_v_attr_struct)
    
    ; Save CDF structure into tplot variable
    options,tvartmp,'CDF', s.CDF

    ;=====
    ;--3--
    ;=====
    ;mvn_sta_l3_temperature
    tvartmp='mvn_sta_l3_temperature_o2+'
    get_data, tvartmp, data=ddtmp, limit=s
    
    ;##############
    ;TIME VARIABLE (depend_0):
    ; To define the CDF attributes retrieve the structure that is stored in "attrptr" pointer
    ; DEPEND_0 correspond to x
    s.CDF.DEPEND_0.attrptr = ptr_new(cdf_x_attr_struct)  ;save updated CDF structure
    
    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    cdf_y_attr_struct = *s.CDF.VARS.attrptr  ;copy structure
    cdf_y_attr_struct.CATDESC = 'Ion temperature for the Maxwellian core of the O2+.'
    cdf_y_attr_struct.LABLAXIS = 'Ion temperature'
    cdf_y_attr_struct.UNITS = 'eV'
    cdf_y_attr_struct.VAR_TYPE = 'Float number'
    cdf_y_attr_struct.FILLVAL = !values.f_nan
    str_element,cdf_y_attr_struct,'VAR_TYPE','data',/add  ;this seems to be needed for cdf_var_atts to find the 'data' type
    str_element, cdf_y_attr_struct, 'MONOTON', 'INCREASE', /add
    str_element, cdf_y_attr_struct, 'scalemin', min(ddtmp.y,/nan)
    str_element, cdf_y_attr_struct, 'scalemax', max(ddtmp.y,/nan)

    s.CDF.VARS.attrptr = ptr_new(cdf_y_attr_struct)
    
    ;###########
    ;V VARIABLE (depend_1):
    ; Depend_1 corresponds to each ion species
    ;None for a 1D Y array.

    ; Save CDF structure into tplot variable
    options,tvartmp,'CDF', s.CDF
    

    ;=====
    ;--4--
    ;=====
    ;mvn_sta_l3_temperature_abs_uncertainty
    tvartmp='mvn_sta_l3_temperature_abs_uncertainty'
    get_data, tvartmp, data=ddtmp, limit=s

    ;##############
    ;TIME VARIABLE (depend_0):
    ; To define the CDF attributes retrieve the structure that is stored in "attrptr" pointer
    ; DEPEND_0 correspond to x
    s.CDF.DEPEND_0.attrptr = ptr_new(cdf_x_attr_struct)  ;save updated CDF structure

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    cdf_y_attr_struct = *s.CDF.VARS.attrptr  ;copy structure
    cdf_y_attr_struct.CATDESC = 'Absolute uncertainty in ion temperature for O2+'
    cdf_y_attr_struct.LABLAXIS = 'Uncertainty in ion temperature [eV]'
    cdf_y_attr_struct.UNITS = 'eV'
    cdf_y_attr_struct.VAR_TYPE = 'Float number'
    cdf_y_attr_struct.FILLVAL = !values.f_nan
    str_element,cdf_y_attr_struct,'VAR_TYPE','data',/add  ;this seems to be needed for cdf_var_atts to find the 'data' type
    str_element, cdf_y_attr_struct, 'MONOTON', 'INCREASE', /add
    str_element, cdf_v_attr_struct, 'scalemin', min(ddtmp.y,/nan)
    str_element, cdf_v_attr_struct, 'scalemax', max(ddtmp.y,/nan)
   
    s.CDF.VARS.attrptr = ptr_new(cdf_y_attr_struct)

    ;###########
    ;V VARIABLE (depend_1):
    ; Depend_1 corresponds to each ion species
    ;None for a 1D Y array.

    ; Save CDF structure into tplot variable
    options,tvartmp,'CDF', s.CDF
    
    ;=====
    ;--5--
    ;=====
    ;mvn_sta_l3_temperature_quality_flag
    tvartmp='mvn_sta_l3_temperature_quality_flag'
    get_data, tvartmp, data=ddtmp, limit=s

    ;##############
    ;TIME VARIABLE (depend_0):
    ; To define the CDF attributes retrieve the structure that is stored in "attrptr" pointer
    ; DEPEND_0 correspond to x
    s.CDF.DEPEND_0.attrptr = ptr_new(cdf_x_attr_struct)  ;save updated CDF structure

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    cdf_y_attr_struct = *s.CDF.VARS.attrptr  ;copy structure
    cdf_y_attr_struct.CATDESC = 'Quality flag for ion temperature for O2+. 0 = good, 1 = caution.'
    cdf_y_attr_struct.LABLAXIS = 'Quality flag, 0=good, 1=caution.'
    cdf_y_attr_struct.UNITS = 'na'
    cdf_y_attr_struct.VAR_TYPE = 'Float number'
    cdf_y_attr_struct.FILLVAL = !values.f_nan
    str_element,cdf_y_attr_struct,'VAR_TYPE','data',/add  ;this seems to be needed for cdf_var_atts to find the 'data' type
    str_element, cdf_y_attr_struct, 'MONOTON', 'INCREASE', /add
    str_element, cdf_v_attr_struct, 'scalemin', min(ddtmp.y,/nan)
    str_element, cdf_v_attr_struct, 'scalemax', max(ddtmp.y,/nan)

    s.CDF.VARS.attrptr = ptr_new(cdf_y_attr_struct)

    ;###########
    ;V VARIABLE (depend_1):
    ; Depend_1 corresponds to each ion species
    ;None for a 1D Y array.

    ; Save CDF structure into tplot variable
    options,tvartmp,'CDF', s.CDF
    
    
    ;=====
    ;--6--
    ;=====
    ;mvn_sta_l3_temperature_mvn_pos_mso
    tvartmp='mvn_sta_l3_temperature_mvn_pos_mso'
    get_data, tvartmp, data=ddtmp, limit=s

    ;##############
    ;TIME VARIABLE (depend_0):
    ; To define the CDF attributes retrieve the structure that is stored in "attrptr" pointer
    ; DEPEND_0 correspond to x
    s.CDF.DEPEND_0.attrptr = ptr_new(cdf_x_attr_struct)  ;save updated CDF structure

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    cdf_y_attr_struct = *s.CDF.VARS.attrptr  ;copy structure
    cdf_y_attr_struct.CATDESC = 'MAVEN X (1), Y (2), Z (3) position in the MSO coordinate system, units of km.'
    cdf_y_attr_struct.LABLAXIS = 'Position [MSO, km]'
    cdf_y_attr_struct.UNITS = 'km'
    cdf_y_attr_struct.VAR_TYPE = 'Float number'
    cdf_y_attr_struct.FILLVAL = !values.f_nan
    str_element,cdf_y_attr_struct,'VAR_TYPE','data',/add  ;this seems to be needed for cdf_var_atts to find the 'data' type
    str_element,cdf_y_attr_struct,'Labels','X, Y, Z',/add  ;add to the cdf
    str_element, cdf_y_attr_struct, 'MONOTON', 'INCREASE', /add
    str_element, cdf_v_attr_struct, 'scalemin', min(ddtmp.y,/nan)
    str_element, cdf_v_attr_struct, 'scalemax', max(ddtmp.y,/nan)
    
    s.CDF.VARS.attrptr = ptr_new(cdf_y_attr_struct)

    ;###########
    ;V VARIABLE (depend_1):
    ; Depend_1 corresponds to each ion species
    cdf_v_attr_struct = *s.CDF.VARS.attrptr  ;copy structure
    cdf_v_attr_struct.CATDESC = 'Labels: 1 = X, 2 = Y, 3 = Z, in MSO coordinates.'
    cdf_v_attr_struct.LABLAXIS = 'Position [MSO, km]'
    cdf_v_attr_struct.UNITS = 'km'  ;note: no fields can be '' otherwise this causes tplot2cdf_vars_save to crash later
    cdf_v_attr_struct.VAR_TYPE = 'support_data'
    cdf_v_attr_struct.FORMAT = 'I1'
    cdf_v_attr_struct.FILLVAL = !values.f_nan
    ;The following is needed to convert the FILLVAL type; it gets stuck as INT = 0, which is the validmin value. This chagnes if to FLOAT = NaN
    str_element, cdf_v_attr_struct, 'FILLVAL', !values.f_nan, /add
    ;These are needed to set the validmin/max values as ints as well:
    str_element, cdf_v_attr_struct, 'VALIDMIN', 0, /add
    str_element, cdf_v_attr_struct, 'VALIDMAX', 3, /add
    str_element, cdf_v_attr_struct, 'MONOTON', 'INCREASE', /add
    str_element, cdf_v_attr_struct, 'scalemin', 1
    str_element, cdf_v_attr_struct, 'scalemax', 3
    
    s.CDF.DEPEND_1.attrptr = ptr_new(cdf_v_attr_struct)
    
    ; Save CDF structure into tplot variable
    options,tvartmp,'CDF', s.CDF
    
    ;=====
    ;--7--
    ;=====
    ;mvn_sta_l3_temperature_mvn_pos_geo
    tvartmp='mvn_sta_l3_temperature_mvn_pos_geo'
    get_data, tvartmp, data=ddtmp, limit=s

    ;##############
    ;TIME VARIABLE (depend_0):
    ; To define the CDF attributes retrieve the structure that is stored in "attrptr" pointer
    ; DEPEND_0 correspond to x
    s.CDF.DEPEND_0.attrptr = ptr_new(cdf_x_attr_struct)  ;save updated CDF structure

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    cdf_y_attr_struct = *s.CDF.VARS.attrptr  ;copy structure
    cdf_y_attr_struct.CATDESC = 'MAVEN X (1), Y (2), Z (3) position in the GEO coordinate system, units of km.'
    cdf_y_attr_struct.LABLAXIS = 'Position [GEO, km]'
    cdf_y_attr_struct.UNITS = 'km'
    cdf_y_attr_struct.VAR_TYPE = 'Float number'
    cdf_y_attr_struct.FILLVAL = !values.f_nan
    str_element,cdf_y_attr_struct,'VAR_TYPE','data',/add  ;this seems to be needed for cdf_var_atts to find the 'data' type
    str_element,cdf_y_attr_struct,'Labels','X, Y, Z',/add  ;add to the cdf
    str_element, cdf_y_attr_struct, 'MONOTON', 'INCREASE', /add
    str_element, cdf_y_attr_struct, 'scalemin', min(ddtmp.y,/nan)
    str_element, cdf_y_attr_struct, 'scalemax', max(ddtmp.y,/nan)
    
    s.CDF.VARS.attrptr = ptr_new(cdf_y_attr_struct)

    ;###########
    ;V VARIABLE (depend_1):
    ; Depend_1 corresponds to each ion species
    cdf_v_attr_struct = *s.CDF.VARS.attrptr  ;copy structure
    cdf_v_attr_struct.CATDESC = 'Labels: 1 = X, 2 = Y, 3 = Z, in GEO coordinates.'
    cdf_v_attr_struct.LABLAXIS = 'Position [GEO, km]'
    cdf_v_attr_struct.UNITS = 'km'  ;note: no fields can be '' otherwise this causes tplot2cdf_vars_save to crash later
    cdf_v_attr_struct.VAR_TYPE = 'support_data'
    cdf_v_attr_struct.FORMAT = 'I1'
    cdf_v_attr_struct.FILLVAL = !values.f_nan
    ;The following is needed to convert the FILLVAL type; it gets stuck as INT = 0, which is the validmin value. This chagnes if to FLOAT = NaN
    str_element, cdf_v_attr_struct, 'FILLVAL', !values.f_nan, /add
    ;These are needed to set the validmin/max values as ints as well:
    str_element, cdf_v_attr_struct, 'VALIDMIN', 0, /add
    str_element, cdf_v_attr_struct, 'VALIDMAX', 3, /add
    str_element, cdf_v_attr_struct, 'MONOTON', 'INCREASE', /add
    str_element, cdf_v_attr_struct, 'scalemin', 1
    str_element, cdf_v_attr_struct, 'scalemax', 3
    
    s.CDF.DEPEND_1.attrptr = ptr_new(cdf_v_attr_struct)

    ; Save CDF structure into tplot variable
    options,tvartmp,'CDF', s.CDF
 
    ;=====
    ;--8--
    ;=====
    ;mvn_sta_l3_temperature_mvn_sza
    tvartmp='mvn_sta_l3_temperature_mvn_sza'
    get_data, tvartmp, data=ddtmp, limit=s

    ;##############
    ;TIME VARIABLE (depend_0):
    ; To define the CDF attributes retrieve the structure that is stored in "attrptr" pointer
    ; DEPEND_0 correspond to x
    s.CDF.DEPEND_0.attrptr = ptr_new(cdf_x_attr_struct)  ;save updated CDF structure

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    cdf_y_attr_struct = *s.CDF.VARS.attrptr  ;copy structure
    cdf_y_attr_struct.CATDESC = 'MAVEN solar zenith angle, units of degrees.'
    cdf_y_attr_struct.LABLAXIS = 'SZA [degrees]'
    cdf_y_attr_struct.UNITS = 'degrees'
    cdf_y_attr_struct.VAR_TYPE = 'Float number'
    cdf_y_attr_struct.FILLVAL = !values.f_nan
    str_element,cdf_y_attr_struct,'VAR_TYPE','data',/add  ;this seems to be needed for cdf_var_atts to find the 'data' type
    str_element, cdf_y_attr_struct, 'MONOTON', 'INCREASE', /add
    str_element, cdf_y_attr_struct, 'scalemin', min(ddtmp.y,/nan)
    str_element, cdf_y_attr_struct, 'scalemax', max(ddtmp.y,/nan)
   
    s.CDF.VARS.attrptr = ptr_new(cdf_y_attr_struct)

    ;###########
    ;V VARIABLE (depend_1):
    ; Depend_1 corresponds to each ion species
    ;None for a 1D Y array.
    
    ; Save CDF structure into tplot variable
    options,tvartmp,'CDF', s.CDF
    
    ;=====
    ;--9--
    ;=====
    ;mvn_sta_l3_temperature_mvn_lst
    tvartmp='mvn_sta_l3_temperature_mvn_lst'
    get_data, tvartmp, data=ddtmp, limit=s

    ;##############
    ;TIME VARIABLE (depend_0):
    ; To define the CDF attributes retrieve the structure that is stored in "attrptr" pointer
    ; DEPEND_0 correspond to x
    s.CDF.DEPEND_0.attrptr = ptr_new(cdf_x_attr_struct)  ;save updated CDF structure

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    cdf_y_attr_struct = *s.CDF.VARS.attrptr  ;copy structure
    cdf_y_attr_struct.CATDESC = 'MAVEN local solar time, units of hours.'
    cdf_y_attr_struct.LABLAXIS = 'LST [hours]'
    cdf_y_attr_struct.UNITS = 'hours'
    cdf_y_attr_struct.VAR_TYPE = 'Float number'
    cdf_y_attr_struct.FILLVAL = !values.f_nan
    str_element,cdf_y_attr_struct,'VAR_TYPE','data',/add  ;this seems to be needed for cdf_var_atts to find the 'data' type
    str_element, cdf_y_attr_struct, 'MONOTON', 'INCREASE', /add
    str_element, cdf_y_attr_struct, 'scalemin', min(ddtmp.y,/nan)
    str_element, cdf_y_attr_struct, 'scalemax', max(ddtmp.y,/nan)
   
    s.CDF.VARS.attrptr = ptr_new(cdf_y_attr_struct)

    ;###########
    ;V VARIABLE (depend_1):
    ; Depend_1 corresponds to each ion species
    ;None for a 1D Y array.

    ; Save CDF structure into tplot variable
    options,tvartmp,'CDF', s.CDF
    
    ;=====
    ;--10--
    ;=====
    ;mvn_sta_l3_temperature_mvn_alt_iau
    tvartmp='mvn_sta_l3_temperature_mvn_alt_iau'
    get_data, tvartmp, data=ddtmp, limit=s

    ;##############
    ;TIME VARIABLE (depend_0):
    ; To define the CDF attributes retrieve the structure that is stored in "attrptr" pointer
    ; DEPEND_0 correspond to x
    s.CDF.DEPEND_0.attrptr = ptr_new(cdf_x_attr_struct)  ;save updated CDF structure

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    cdf_y_attr_struct = *s.CDF.VARS.attrptr  ;copy structure
    cdf_y_attr_struct.CATDESC = 'MAVEN altitude in the IAU reference frame, units of km.'
    cdf_y_attr_struct.LABLAXIS = 'Altitude [IAU, km]'
    cdf_y_attr_struct.UNITS = 'km'
    cdf_y_attr_struct.VAR_TYPE = 'Float number'
    cdf_y_attr_struct.FILLVAL = !values.f_nan
    str_element,cdf_y_attr_struct,'VAR_TYPE','data',/add  ;this seems to be needed for cdf_var_atts to find the 'data' type
    str_element, cdf_y_attr_struct, 'MONOTON', 'INCREASE', /add
    str_element, cdf_y_attr_struct, 'scalemin', min(ddtmp.y,/nan)
    str_element, cdf_y_attr_struct, 'scalemax', max(ddtmp.y,/nan)
    
    s.CDF.VARS.attrptr = ptr_new(cdf_y_attr_struct)

    ;###########
    ;V VARIABLE (depend_1):
    ; Depend_1 corresponds to each ion species
    ;None for a 1D Y array.

    ; Save CDF structure into tplot variable
    options,tvartmp,'CDF', s.CDF
    
    
    ;=====
    ;-11--
    ;=====
    ;Store UNIX times as a new variable, rather than as metadata. Tidies up files and will save space - no duplicate info in each
    ;variable.
    ;mvn_sta_l3_density_unixtimes
    tvartmp='mvn_sta_l3_temperature_unixtimes'
    get_data, tvartmp, data=ddtmp, limit=s

    ;##############
    ;TIME VARIABLE (depend_0):
    ; To define the CDF attributes retrieve the structure that is stored in "attrptr" pointer
    ; DEPEND_0 correspond to x
    s.CDF.DEPEND_0.attrptr = ptr_new(cdf_x_attr_struct)  ;save updated CDF structure

    ;###########
    ;Y VARIABLE:
    ; VARS correspond to y
    cdf_y_attr_struct = *s.CDF.VARS.attrptr  ;copy structure
    cdf_y_attr_struct.CATDESC = 'UNIX timestamps that correspond to the TT2000 timestamps.'
    cdf_y_attr_struct.LABLAXIS = 'UNIX time [s]'
    cdf_y_attr_struct.UNITS = 's'
    cdf_y_attr_struct.VAR_TYPE = 'Double precision number'
    cdf_y_attr_struct.FILLVAL = !values.f_nan
    str_element,cdf_y_attr_struct,'VAR_TYPE','data',/add  ;this seems to be needed for cdf_var_atts to find the 'data' type
    str_element, cdf_y_attr_struct, 'MONOTON', 'INCREASE', /add
    str_element, cdf_y_attr_struct, 'scalemin', min(ddtmp.y,/nan)
    str_element, cdf_y_attr_struct, 'scalemax', max(ddtmp.y,/nan)

    s.CDF.VARS.attrptr = ptr_new(cdf_y_attr_struct)

    ;###########
    ;V VARIABLE (depend_1):
    ; Depend_1 corresponds to each ion species
    ;None for a 1D Y array.

    ; Save CDF structure into tplot variable
    options,tvartmp,'CDF', s.CDF


    ;===========
    ;Final save:
    ;===========
    tplot2cdf, tvars=tvars1, filename=filename, g_attributes=global_att, /tt2000, default_cdf_structure=0  ;.X is now long64 so /TT2000 should work

success=1

end


