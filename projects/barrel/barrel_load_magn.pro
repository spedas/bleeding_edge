;+
;NAME: barrel_load_magn
;DESCRIPTION: CDF-to-TDAS import routine for BARREL magnetometer (MAGN) 
;               data products (also 'MAG', 'FGM')
;
;REQUIRED INPUTS:
; none
;
;KEYWORD ARGUMENTS (OPTIONAL):
; PROBE:        String [array] of BARREL identifiers (e.g., '1A', '1B').
;                 Default is 'all' (i.e., all available payloads).  May also be
;                 a single string delimited by spaces (e.g., '1A 1B').
; DATATYPE:     String [array] of BARREL datatype identifiers (e.g. 'MAGN').
; TRANGE:       Time range for tplot (2 element array).  Loads data in whole-day
;                 chunks, and will prompt user if not specified.
; LEVEL:        String [array] of data level code (e.g. 'l1', 'l2').
; VERSION:      String specifying data revision number (e.g. 'v01', 'v02').
; /VERBOSE:       
; CDF_DATA:     (not implemented)
; /GET_SUPPORT_DATA: Load support_data variables as well as data variables.
; TPLOTNAMES:   (passed through to 'cdf2tplot' and 'cdf_info_to_tplot')
; MAKE_MULTI_TPLOTVAR: (not implemented)
; VARFORMAT:    String (passed through to 'cdf2tplot').
; /VALID_NAMES: (not implemented) 
; FILES:        (not implemented)
;
; (FILE_RETRIEVE KEYWORDS-- descriptions borrowed from file_retrieve.pro)
; /DOWNLOADONLY:
;               Set to 1 to only download files but not load files into memory.
; /NO_SERVER:   Set to 1 to prevent any contact with a remote server.
; /NO_DOWNLOAD: Identical to NO_SERVER keyword. Obsolete, but retained for backward compatibility
; /NO_UPDATE:   Set to 1 to prevent contact to server if local file already exists. (this is similar to no_clobber)
; /NO_CLOBBER:  Set to 1 to prevent existing files from being overwritten. (A warning message will be displayed if remote server has)
;
;OUTPUTS:
; none
;
;STATUS: 
;
;TO BE ADDED: n/a
;
;EXAMPLE:
;
;REVISION HISTORY:
;Version 0.96a KBY 06/15/2014 removed dead code 
;Version 0.93e KBY 08/28/2013 explicit support for 'support_data' (e.g., FrameGroup);
;               support for noting VALID_MIN and VALID_MAX values
;Version 0.93d KBY 08/23/2013 quality indicator ("Q") renamed "Quality";
;               take unit labels from CDF metadata; update documentation.
;Version 0.93c KBY 08/23/2013 BARREL payload identifiers shortened to alphanumeric build
;               order only (e.g., '1A', '1B'), following change to CDF naming convention
;Version 0.93a KBY 08/16/2013 accomodate v02 CDF namechange of "MAG_[X,Y,Z]" to "MAG_[X,Y,Z]_uncalibrated"
;               via variable rename (back to MAG_X/Y/Z); fix bug with handling of VERSION keyword;
;               specify default value for "unit"
;Version 0.92 KBY 06/04/2013 introduced VERSION keyword
;Version 0.91c KBY 05/31/2013 handling of ISTP fill values
;Version 0.91b KBY 05/31/2013 check for and delete existing variables of same name
;Version 0.91a KBY 05/28/2013 added file_retrieve keywords (no_download/update/clobber)
;Version 0.90a KBY 04/22/2013 re-factoring of generic load actions; update CDF compatibility
;Version 0.83 KBY 11/28/2012 initial beta release
;Version 0.82 KBY 11/27/2012 debugging with updated CDF definitions
;Version 0.81 KBY 11/21/2012 new CDF definitions; updated treatment of PROBE 
;               keyword; distinction between L1 and L2 data product handling.
;Version 0.8 KBY 10/29/2012 from 'rbsp_load_efw_spec.pro' (Peter Schroeder),
;               and 'thm_load_goesmag.pro'
;
;-

pro barrel_load_magn, probe=probe, datatype=datatype, trange=trange, $
                    level=level, version=version, verbose=verbose, $
                    downloadonly=downloadonly, $
                    no_download=no_download, no_server=no_server, $
                    no_update=no_update, no_clobber=no_clobber, $
                    cdf_data=cdf_data, get_support_data=get_support_data, $
                    tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
                    varformat=varformat, valid_names=valid_names, files=files, $
                    CONVERT_L1_TO_PHYSICAL_UNITS=do_convert_L1


; specify VDATATYPES and VLEVELS for MAGN
vlevels = ['l2','l1']   ; Zeroth element is our default (require only one level)
vdatatypes = ['magn']   ; Require only one datatype at this level

; submit request for PROBE, LEVEL, and DATATYPE
return_value = barrel_preload_actions(probe=probe,datatype=datatype, $ 
                trange=trange,level=level, version=version, $ 
                vdatatypes=vdatatypes,vlevels=vlevels, $ 
                verbose=verbose,get_support_data=get_support_data, $ 
                    downloadonly=downloadonly, $
                    no_download=no_download, no_server=no_server, $
                    no_update=no_update, no_clobber=no_clobber, $
                tplotnames=tns,varformat=varformat, $ 
                valid_names=valid_names,files=files) 
; variables have been loaded from CDF to TDAS 
new_tpvars = return_value.tplot_variables       ; string array of TPLOT variable handles 
level = return_value.level                      ; the level that was loaded 
not_empty = WHERE(new_tpvars, n_newvars)

; for v02+ data products, perform variable renaming as appropriate
v02_rename = 1
IF (v02_rename EQ 1) THEN BEGIN 
    breakpt = 6
    prototype = 'brl??_MAG_?_uncalibrated'
    match_index = strfilter(new_tpvars, prototype, COUNT=cnt, /INDEX)
    IF (cnt GT 0) THEN uncalibrated_flag = 1    ; set an "uncalibrated" flag
    FOR i=0, cnt-1 DO BEGIN
        ; rename as appropriate
        old_name = new_tpvars[match_index[i]]
        new_name = STRMID(old_name,0,11)         ; lops off the "_uncalibrated" part 
            ; delete existing entries of target name..
            exists = tnames(new_name, cnt)
            IF (cnt NE 0) THEN store_data, new_name, /DELETE
        print, ' ', old_name, ' > ', new_name   ; diagnostic
        store_data, old_name, NEWNAME=new_name 
        new_tpvars[match_index[i]] = new_name
    ENDFOR 
ENDIF
    
; calculate B_total from L1 results (if appropriate)
IF ((level EQ 'l1') AND (keyword_set(do_convert_L1)) AND (n_newvars NE 0)) THEN BEGIN
    breakpt = 6 
    balloons = STRMID(new_tpvars,0,breakpt)
    sorted_balloons = balloons[SORT(balloons)]
    unique_vector = UNIQ(sorted_balloons)
    FOR i=0, N_ELEMENTS(unique_vector)-1 DO BEGIN
        ; calculate B_TOTAL
        pre = sorted_balloons[unique_vector[i]]
        required = [pre+'MAG_X',pre+'MAG_Y',pre+'MAG_Z']
        matching_names = strfilter(new_tpvars, required)
        sorted_names = matching_names[SORT(matching_names)]
        three_vector = UNIQ(sorted_names)
        IF N_ELEMENTS(three_vector) EQ 3 THEN BEGIN
            get_data, sorted_names[three_vector[0]], DATA=b0, LIMITS=l_str, DLIMITS=dl_str
            get_data, sorted_names[three_vector[1]], DATA=b1
            get_data, sorted_names[three_vector[2]], DATA=b2
            
            ; ensure that a comparison is valid.
            ; Require:
            ;  1. same number of elements
            ;  2. the elements of each time series are actually identical
            pass_both_reqs = ARRAY_EQUAL(b0.x, b1.x) AND ARRAY_EQUAL(b0.x, b2.x)
            
            IF (pass_both_reqs) THEN BEGIN
                ; assume that the y-dimensions are also valid / appropriately sized
                b_total = SQRT(DOUBLE(b0.y)^2 + DOUBLE(b1.y)^2 + DOUBLE(b2.y)^2)
                store_data, pre+'Total', DATA={x:b0.x, y:b_total}, LIMITS=l_str, DLIMITS=dl_str
                new_tpvars = [new_tpvars, pre+'Total']
            ENDIF ELSE print, 'barrel_load_magn: mismatched Bxyz entries-- no B_total calculated'
        ENDIF
    ENDFOR
ENDIF

not_empty = WHERE(new_tpvars, n_newvars)

; post-load variable configuration
IF (n_newvars GT 0) THEN BEGIN
    tplotnames = new_tpvars[not_empty]
    FOR i=0, N_ELEMENTS(tplotnames)-1 DO BEGIN
        tplot_var = tplotnames[i]
        get_data, tplot_var, data=d_str, limit=l_str, dlimit=dl_str
        
        ; if data is of type "data" or "support_data", we may want to customize it 
        IF size(/type, dl_str) EQ 8 && ((dl_str.cdf.vatt.var_type EQ 'data') OR $ 
            (dl_str.cdf.vatt.var_type EQ 'support_data')) THEN BEGIN

            ; build and populate a minimal dl_str.data_att
            spd_new_units, tplot_var
            spd_new_coords, tplot_var

            str_element, dl_str, 'data_att', success=yes_data_att
            IF ~yes_data_att THEN BEGIN
                data_att = {units:'', coord_sys:'none'}
                str_element, dl_str, 'data_att', data_att, /add
            ENDIF

            ; Add 'none' to coord_sys if it doesn't exist
            str_element, dl_str.data_att, 'coord_sys', success=yes_coord
            IF yes_coord THEN coord=dl_str.data_att.coord_sys


            ; MAGN-class variables have name structure: 
            ;   brlPP_VARIABLE 
            ; 
            ; where 'brlPP' is the per-payload identifier, designating..  
            ;   brl = mission identifier (BARREL) 
            ;   PP  = alphanumerical payload identifier (build order) 
            ;   Note: the numerical part PP doubles as a campaign identifier 
            ;   C   = campaign identifier (1=2012-2013, 2=2012-2013)
            ;
            ; and VARIABLE designates the relevant MAGN-class variable
            ;   MAG_X
            ;   MAG_Y
            ;   MAG_Z
            ;   B_Total
            ;   MAGN_FrameGroup
            ;   MAGN_Quality

            ; extract useful information from CDF metadata..  
            ; 1) test for existence of the "dl_str.cdf.vatt.UNITS" tag 
            str_element, dl_str.cdf.vatt, 'units', units_test, success = units_do_exist 
            IF (units_do_exist) THEN unit = units_test $        ; set default to CDF specification 
               ELSE unit = 'none'                              ; set default units to 'none' 
            ; 2) test for existence of the "dl_str.cdf.vatt.LABLAXIS" tag 
            str_element, dl_str.cdf.vatt, 'lablaxis', label_test, success = label_does_exist 
            IF (label_does_exist) THEN labels = label_test $    ; set default to CDF specification 
               ELSE labels = 'none'                            ; set default label to 'none' 
            ; 3) test for existence of the "dl_str.cdf.vatt.FILLVAL" tag 
            str_element, dl_str.cdf.vatt, 'fillval', fillval_test, success = fillval_does_exist 
            IF (fillval_does_exist) THEN max_fillvalue = fillval_test $ ; set default to CDF specification 
               ELSE max_fillvalue = !Values.F_NAN                      ; set default to NaN
            ; 4) test for existence of the "dl_str.cdf.vatt.VALIDMIN" tag 
            str_element, dl_str.cdf.vatt, 'validmin', validmin, success = validmin_does_exist 
            ; 5) test for existence of the "dl_str.cdf.vatt.VALIDMAX" tag 
            str_element, dl_str.cdf.vatt, 'validmax', validmax, success = validmax_does_exist  

            ; handling of ISTP fill values (all of MAGN should be immune)            
            ;max_fillvalue = -2^31 + 1   ; generic non-negative LONG
            fill2nan = 0                ; not applicable

            breakpt = 6
            CASE STRMID(tplot_var,breakpt) OF
                'FrameGroup': BEGIN
                        colors=0
                        
                        ; rename with inserted class identifier
                        new_name = STRMID(tplot_var,0,breakpt)+'MAGN_'+$
                           STRMID(tplot_var, breakpt)
                        ; search for existing variables, and delete
                        exists = tnames(new_name, cnt) 
                        IF (cnt NE 0) THEN store_data, new_name, /DELETE
                        ; rename as appropriate 
                        store_data, tplot_var, NEWNAME=new_name
                        tplot_var = new_name
                    END
                'Quality': BEGIN
                        colors=0
                        
                        ; rename with inserted class identifier
                        new_name = STRMID(tplot_var,0,breakpt)+'MAGN_'+$
                           STRMID(tplot_var, breakpt)
                        ; search for existing variables, and delete
                        exists = tnames(new_name, cnt) 
                        IF (cnt NE 0) THEN store_data, new_name, /DELETE
                        ; rename as appropriate 
                        store_data, tplot_var, NEWNAME=new_name
                        tplot_var = new_name
                    END
                'MAG_X': BEGIN
                        ; specify units 
                        ;IF ((level EQ 'l1') AND (not keyword_set(do_convert_L1))) THEN $
                        ;     unit = 'ADC Value' ELSE unit='microT'
                        IF ((level EQ 'l1') AND (keyword_set(do_convert_L1))) THEN $
                             unit = 'microT'
                        ; nominal conversion of L1 product to physical units
                        IF ((level EQ 'l1') AND (keyword_set(do_convert_L1))) THEN BEGIN 
                             print, 'L1 data product.. converting to physical units' 
                             new_y = (FLOAT(d_str.y) - 8388608.0)/ 83886.070
                             d_str = {x:d_str.x, y:new_y} 
                        ENDIF
                        IF SIZE(uncalibrated_flag, /TYPE) EQ 1 THEN $
                            labels=labels+'!C(uncalibrated)'
                        colors = 2
                    END
                'MAG_Y': BEGIN
                        ; specify units 
                        ;IF ((level EQ 'l1') AND (not keyword_set(do_convert_L1))) THEN $
                        ;     unit = 'ADC Value' ELSE unit='microT'
                        IF ((level EQ 'l1') AND (keyword_set(do_convert_L1))) THEN $
                             unit = 'microT'
                        ; nominal conversion of L1 product to physical units
                         IF ((level EQ 'l1') AND (keyword_set(do_convert_L1))) THEN BEGIN 
                             print, 'L1 data product.. converting to physical units' 
                             new_y = (FLOAT(d_str.y) - 8388608.0)/ 83886.070
                             d_str = {x:d_str.x, y:new_y} 
                        ENDIF
                        IF SIZE(uncalibrated_flag, /TYPE) EQ 1 THEN $
                            labels=labels+'!C(uncalibrated)'
                        colors = 4
                    END
                'MAG_Z': BEGIN
                        ; specify units 
                        ;IF ((level EQ 'l1') AND (not keyword_set(do_convert_L1))) THEN $
                        ;     unit = 'ADC Value' ELSE unit='microT'
                        IF ((level EQ 'l1') AND (keyword_set(do_convert_L1))) THEN $
                             unit = 'microT'
                        ; nominal conversion of L1 product to physical units
                         IF ((level EQ 'l1') AND (keyword_set(do_convert_L1))) THEN BEGIN 
                             print, 'L1 data product.. converting to physical units' 
                             new_y = (FLOAT(d_str.y) - 8388608.0)/ 83886.070
                             d_str = {x:d_str.x, y:new_y} 
                        ENDIF
                        IF SIZE(uncalibrated_flag, /TYPE) EQ 1 THEN $
                            labels=labels+'!C(uncalibrated)'
                        colors = 6
                    END
                'Total': BEGIN
                        ; specify units 
                        ;IF ((level EQ 'l1') AND (not keyword_set(do_convert_L1))) THEN $
                        ;     unit = 'ADC Value' ELSE unit='microT'
                        IF ((level EQ 'l1') AND (keyword_set(do_convert_L1))) THEN $
                             unit = 'microT'
                        ; nominal conversion of L1 product to physical units
                         IF ((level EQ 'l1') AND (keyword_set(do_convert_L1))) THEN BEGIN 
                             print, 'L1 data product.. converting to physical units' 
                             new_y = (FLOAT(d_str.y) - 8388608.0)/ 83886.070
                             d_str = {x:d_str.x, y:new_y} 
                        ENDIF
                        IF SIZE(uncalibrated_flag, /TYPE) EQ 1 THEN $
                            labels=labels+'!C(uncalibrated)'
                        colors = 0
                        
                        ; rename as 'B_Total'
                        new_name = STRMID(tplot_var,0,breakpt)+'MAG_B'+$
                            STRMID(tplot_var,breakpt)
                        ; search for existing variables, and delete
                        exists = tnames(new_name, cnt) 
                        IF (cnt NE 0) THEN store_data, new_name, /DELETE
                        ; rename as appropriate 
                        store_data, tplot_var, NEWNAME=new_name
                        tplot_var = new_name
                    END
                ELSE: print, 'no matches for: ', tplot_var
            ENDCASE

            dprint, dlevel=4,'TPLOT_VAR: ', tplot_var

            ; report STATE type as 'none'? (e.g., neither POS nor VEL)
            str_element, dl_str, 'data_att.st_type', 'none', /ADD

            str_element, dl_str, 'data_att.units', unit, /ADD
            str_element, dl_str, 'colors', colors, /ADD
            str_element, dl_str, 'labels', labels, /ADD
            str_element, dl_str, 'labflag', 1, /add
;            str_element, dl_str, 'min_value', max_fillvalue, /add
            IF (validmin_does_exist) THEN str_element, dl_str, 'min_value', validmin, /add
            IF (validmax_does_exist) THEN str_element, dl_str, 'max_value', validmax, /add
            str_element, dl_str, 'ytitle', tplot_var, /ADD
            str_element, dl_str, 'ysubtitle', '['+unit+']', /ADD
            str_element, dl_str, 'datagap', 60, /ADD           
            str_element, l_str, 'ynozero', 1, /ADD           
            store_data, tplot_var, data=d_str, limit=l_str, dlimit=dl_str, MIN=fill2nan
        ENDIF
    ENDFOR
ENDIF

END
