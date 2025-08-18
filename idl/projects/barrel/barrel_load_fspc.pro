;+
;NAME: barrel_load_fspc
;DESCRIPTION: CDF-to-TDAS import routine for BARREL fast-speed spectral
;               (FSPC) data products (also 'FSPEC')
;
;REQUIRED INPUTS:
; none
;
;KEYWORD ARGUMENTS (OPTIONAL):
; PROBE:        String [array] of BARREL identifiers (e.g., '1A', '1B').
;                 Default is 'all' (i.e., all available payloads).  May also be
;                 a single string delimited by spaces (e.g., '1A 1B').
; DATATYPE:     String [array] of BARREL datatype identifiers (e.g. 'FSPC').
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
;Version 0.96a KBY 06/15/2014 fixed bug in FSPC1 reconstruction routine (campaign 1 compatibility)
;Version 0.95b KBY 12/29/2013 recreation of FSPC1 channel from FSPC1a + FSPC1b + FSPC1c components
;Version 0.95a KBY 12/27/2013 preliminary support for new FSPC variables "FSPC1a", "FSPC1b", "FSPC1c"
;Version 0.94a KBY 09/13/2013 support for new FSPC variable "FSPC_Edges"
;Version 0.93e KBY 08/28/2013 support for noting VALID_MIN and VALID_MAX values;
;               rename 'LCx' variables to 'FSPCx'
;Version 0.93d KBY 08/23/2013 quality indicator ("Q") renamed "Quality";
;               take unit labels from CDF metadata; update documentation.
;Version 0.93c KBY 08/23/2013 BARREL payload identifiers shortened to alphanumeric build
;               order only (e.g., '1A', '1B'), following change to CDF naming convention
;Version 0.93a KBY 08/16/2013 accomodate v02 CDF namechange of "LC[1-4]_ERROR" to "cnt_error[1-4]";
;              specify default value for "units" 
;Version 0.92 KBY 06/04/2013 introduced VERSION keyword
;Version 0.91c KBY 05/31/2013 handling of ISTP fill values
;Version 0.91b KBY 05/31/2013 check for and delete existing variables of same name
;Version 0.91a KBY 05/28/2013 added file_retrieve keywords (no_download/update/clobber)
;Version 0.90a KBY 04/19/2013 re-factoring of generic load actions; update CDF compatibility
;Version 0.83 KBY 11/28/2012 initial beta release
;Version 0.82 KBY 11/27/2012 debugging with updated CDF definitions
;Version 0.81 KBY 11/21/2012 new CDF definitions; updated treatment of PROBE 
;               keyword; distinction between L1 and L2 data product handling.
;Version 0.8 KBY 10/29/2012 from 'rbsp_load_efw_spec.pro' (Peter Schroeder),
;               and 'thm_load_goesmag.pro'
;
;-

pro barrel_load_fspc, probe=probe, datatype=datatype, trange=trange, $
                    level=level, version=version, verbose=verbose, $
                    downloadonly=downloadonly, $
                    no_download=no_download, no_server=no_server, $
                    no_update=no_update, no_clobber=no_clobber, $
                    cdf_data=cdf_data, get_support_data=get_support_data, $
                    tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
                    varformat=varformat, valid_names=valid_names, files=files, $
                    CONVERT_L1_TO_PHYSICAL_UNITS=do_convert_L1

; specify VDATATYPES and VLEVELS for FSPC
vlevels = ['l2','l1']   ; Zeroth element is our default (require only one level)
vdatatypes = ['fspc']   ; Require only one datatype at this level

; submit request for PROBE, LEVEL, and DATATYPE
return_value = barrel_preload_actions(probe=probe,datatype=datatype,$
                trange=trange,level=level,version=version, $
                vdatatypes=vdatatypes,vlevels=vlevels,$
                verbose=verbose,get_support_data=get_support_data,$
                    downloadonly=downloadonly, $
                    no_download=no_download, no_server=no_server, $
                    no_update=no_update, no_clobber=no_clobber, $
                tplotnames=tns,varformat=varformat,$
                valid_names=valid_names,files=files) 
; variables have been loaded from CDF to TDAS
new_tpvars = return_value.tplot_variables       ; string array of TPLOT variable handles
level = return_value.level                      ; the level that was loaded
not_empty = WHERE(new_tpvars, n_newvars)

; if necessary, calculate FSPC1 from components (FSPC1a + FSPC1b + FSPC1c)
IF (n_newvars GT 0) THEN BEGIN
    breakpt = 6
    balloons = STRMID(new_tpvars,0,breakpt) 
    sorted_balloons = balloons[SORT(balloons)] 
    unique_vector = UNIQ(sorted_balloons) 

    ; loop over balloons
    FOR i=0, N_ELEMENTS(unique_vector)-1 DO BEGIN
        pre = sorted_balloons[unique_vector[i]] 
        required = [pre+'FSPC1a',pre+'FSPC1b',pre+'FSPC1c'] 
        matching_names = strfilter(new_tpvars, required) 
        sorted_names = matching_names[SORT(matching_names)] 
        three_vector = UNIQ(sorted_names)
        fspc1_exists = (N_ELEMENTS(strfilter(new_tpvars, pre+'FSPC1')) GT 0)
        
        ; test for prerequisites
        IF (~fspc1_exists) AND (N_ELEMENTS(three_vector) EQ 3) THEN BEGIN
            ; an "FSPC1" variable does not exist.. attempt to calculate it
            get_data, sorted_names[three_vector[0]], DATA=lc1a, LIMITS=l_str, DLIMITS=dl_str 
            get_data, sorted_names[three_vector[1]], DATA=lc1b 
            get_data, sorted_names[three_vector[2]], DATA=lc1c

            ; ensure that a comparison is valid.  
            ; Require: 
            ;  1. same number of elements 
            ;  2. the elements of each time series are actually identical 
            ;req_dims = SIZE(b0.x, /DIMENSIONS) 
            ;pass_req1 = (SIZE(b1.x, /DIMENSIONS) EQ req_dims) $ 
            ;    AND (SIZE(b2.x, /DIMENSIONS) EQ req_dims) 
            ;pass_req2 = (TOTAL(b0.x NE b1.x) EQ 0) $ 
            ;    AND (TOTAL(b0.x NE b2.x) EQ 0) 
            pass_both_reqs = ARRAY_EQUAL(lc1a.x, lc1b.x) AND ARRAY_EQUAL(lc1a.x, lc1c.x)
       
            ;IF (pass_req1 AND pass_req2) THEN BEGIN 
            IF (pass_both_reqs) THEN BEGIN 
                ; assume that the y-dimensions are also valid / appropriately sized 
                fspc1 = (lc1a.y + lc1b.y + lc1c.y) 
                store_data, pre+'FSPC1', DATA={x:lc1a.x, y:fspc1}, LIMITS=l_str, DLIMITS=dl_str 
                new_tpvars = [new_tpvars, pre+'FSPC1']
                n_newvars += 1 
            ENDIF ELSE print, 'barrel_load_fspc: mismatched FSPC 1a/1b/1c entries-- no FSPC1 calculated'
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


            ; FSPC-class variables have name structure:
            ;   brlPP_VARIABLE 
            ; 
            ; where 'brlPP' is the per-payload identifier, designating..  
            ;   brl = mission identifier (BARREL) 
            ;   PP  = alphanumerical payload identifier (build order) 
            ;   Note: the numerical part PP doubles as a campaign identifier 
            ;   C   = campaign identifier (1=2012-2013, 2=2012-2013)
            ;
            ; and VARIABLE designates the relevant FSPC-class variable
            ;   FSPC1 (LC1)
            ;   FSPC1a (subchannel of FSPC1 [campaign 2 only])
            ;   FSPC1b (subchannel of FSPC1 [campaign 2 only])
            ;   FSPC1c (subchannel of FSPC1 [campaign 2 only])
            ;   FSPC2 (LC2
            ;   FSPC3 (LC3)
            ;   FSPC4 (LC4)
            ;   FSPC_cnt_error1 (standard error in LC1 countrate)
            ;   FSPC_cnt_error1a (standard error in LC1a countrate)
            ;   FSPC_cnt_error1b (standard error in LC1b countrate)
            ;   FSPC_cnt_error1c (standard error in LC1c countrate)
            ;   FSPC_cnt_error2 (standard error in LC2 countrate)
            ;   FSPC_cnt_error3 (standard error in LC3 countrate)
            ;   FSPC_cnt_error4 (standard error in LC4 countrate)
            ;   FSPC_Edges (calibrated bin boundaries)
            ;   FSPC_FrameGroup
            ;   FSPC_Quality
           
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

            ; handling of ISTP fill values (all of FSPC should be immune)            
            ;max_fillvalue = -32768  ; generic non-negative
            fill2nan = 0            ; not applicable
           
            breakpt = 6 
            CASE STRMID(tplot_var,breakpt) OF
                'FrameGroup': BEGIN
                        colors=0
                        
                        ; rename with inserted class identifier
                        new_name = STRMID(tplot_var,0,breakpt)+'FSPC_'+$
                            STRMID(tplot_var,breakpt)
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
                        new_name = STRMID(tplot_var,0,breakpt)+'FSPC_'+$
                            STRMID(tplot_var,breakpt)
                        ; search for existing variables, and delete
                        exists = tnames(new_name, cnt) 
                        IF (cnt NE 0) THEN store_data, new_name, /DELETE
                        ; rename as appropriate 
                        store_data, tplot_var, NEWNAME=new_name
                        tplot_var = new_name
                    END
                'FSPC1': BEGIN  ; fast spectrum 1 / lightcurve 1
                        colors = 2
                        ; if recreated from sum of [FSPC1a/1b/1c], fix labels
                        IF (dl_str.cdf.vname EQ 'FSPC1a') THEN BEGIN
                            ; assume that everything else also needs to be changed..
                            str_element, dl_str, 'cdf.VNAME', 'FSPC1', /ADD_REPLACE
                            str_element, dl_str, 'cdf.vatt.FIELDNAM', 'FSPC1', /ADD_REPLACE
                            str_element, dl_str, 'cdf.vatt.CATDESC', $
                                'Fast spectra (50ms) ch. 1 (reconstructed)', /ADD_REPLACE
                            str_element, dl_str, 'cdf.vatt.LABLAXIS', 'FSPC1', /ADD_REPLACE
                            str_element, dl_str, 'cdf.vatt.DELTA_PLUS_VAR', 'none (not reconstructed)', /ADD_REPLACE
                            str_element, dl_str, 'cdf.vatt.DELTA_MINUS_VAR', 'none (not recontructed)', /ADD_REPLACE
                            ;str_element, dl_str, 'LABELS', 'FSPC1', /ADD_REPLACE 
                            labels = 'FSPC1'    ; as this gets written out later
                        ENDIF
                    END
                'FSPC1a': BEGIN  ; fast spectrum 1a / lightcurve 1a [campaign 2 only]
                        colors = 1      ;(alternate LOADCT2 colors: magenta)
                    END
                'FSPC1b': BEGIN  ; fast spectrum 1b / lightcurve 1b [campaign 2 only]
                        colors = 3      ;(alternate LOADCT2 colors: cyan)
                    END
                'FSPC1c': BEGIN  ; fast spectrum 1c / lightcurve 1c [campaign 2 only]
                        colors = 5      ;(alternate LOADCT2 colors: yellow)
                    END
                'FSPC2': BEGIN  ; fast spectrum 2 / lightcurve 2
                        colors = 4
                    END
                'FSPC3': BEGIN  ; fast spectrum 3 / lightcurve 3
                        colors = 6
                    END
                'FSPC4': BEGIN  ; fast spectrum 4 / lightcurve 4
                        colors = 8
                    END
                'cnt_error1': BEGIN
                        
                        colors = 1
                        
                        ; rename with inserted class identifier
                        new_name = STRMID(tplot_var,0,breakpt)+'FSPC_'+$
                            STRMID(tplot_var,breakpt)
                        ; search for existing variables, and delete
                        exists = tnames(new_name, cnt) 
                        IF (cnt NE 0) THEN store_data, new_name, /DELETE
                        ; rename as appropriate 
                        store_data, tplot_var, NEWNAME=new_name
                        tplot_var = new_name
                    END
                'cnt_error1a': BEGIN
                        ; a L2 product only
                        colors = 1
                        
                        ; rename with inserted class identifier
                        new_name = STRMID(tplot_var,0,breakpt)+'FSPC_'+$
                            STRMID(tplot_var,breakpt)
                        ; search for existing variables, and delete
                        exists = tnames(new_name, cnt) 
                        IF (cnt NE 0) THEN store_data, new_name, /DELETE
                        ; rename as appropriate 
                        store_data, tplot_var, NEWNAME=new_name
                        tplot_var = new_name
                    END
                'cnt_error1b': BEGIN
                        ; a L2 product only
                        colors = 1
                        
                        ; rename with inserted class identifier
                        new_name = STRMID(tplot_var,0,breakpt)+'FSPC_'+$
                            STRMID(tplot_var,breakpt)
                        ; search for existing variables, and delete
                        exists = tnames(new_name, cnt) 
                        IF (cnt NE 0) THEN store_data, new_name, /DELETE
                        ; rename as appropriate 
                        store_data, tplot_var, NEWNAME=new_name
                        tplot_var = new_name
                    END
                'cnt_error1c': BEGIN
                        ; a L2 product only
                        colors = 1
                        
                        ; rename with inserted class identifier
                        new_name = STRMID(tplot_var,0,breakpt)+'FSPC_'+$
                            STRMID(tplot_var,breakpt)
                        ; search for existing variables, and delete
                        exists = tnames(new_name, cnt) 
                        IF (cnt NE 0) THEN store_data, new_name, /DELETE
                        ; rename as appropriate 
                        store_data, tplot_var, NEWNAME=new_name
                        tplot_var = new_name
                    END
                'cnt_error2': BEGIN
                        ; a L2 product only
                        colors = 1
                        
                        ; rename with inserted class identifier
                        new_name = STRMID(tplot_var,0,breakpt)+'FSPC_'+$
                            STRMID(tplot_var,breakpt)
                        ; search for existing variables, and delete
                        exists = tnames(new_name, cnt) 
                        IF (cnt NE 0) THEN store_data, new_name, /DELETE
                        ; rename as appropriate 
                        store_data, tplot_var, NEWNAME=new_name
                        tplot_var = new_name
                    END
                'cnt_error3': BEGIN
                        ; a L2 product only
                        colors = 1
                        
                        ; rename with inserted class identifier
                        new_name = STRMID(tplot_var,0,breakpt)+'FSPC_'+$
                            STRMID(tplot_var,breakpt)
                        ; search for existing variables, and delete
                        exists = tnames(new_name, cnt) 
                        IF (cnt NE 0) THEN store_data, new_name, /DELETE
                        ; rename as appropriate 
                        store_data, tplot_var, NEWNAME=new_name
                        tplot_var = new_name
                    END
                'cnt_error4': BEGIN
                        ; a L2 product only
                        colors = 1
                        
                        ; rename with inserted class identifier
                        new_name = STRMID(tplot_var,0,breakpt)+'FSPC_'+$
                            STRMID(tplot_var,breakpt)
                        ; search for existing variables, and delete
                        exists = tnames(new_name, cnt) 
                        IF (cnt NE 0) THEN store_data, new_name, /DELETE
                        ; rename as appropriate 
                        store_data, tplot_var, NEWNAME=new_name
                        tplot_var = new_name
                    END
                'FSPC_Edges': BEGIN
                        ; a L2 product only
                        colors = 6
                    END
                ELSE: print, 'no matches for: ', tplot_var
            ENDCASE

            dprint, dlevel=4,'TPLOT_VAR: ', tplot_var

            ; report STATE type as 'none'? (e.g., neither POS nor VEL)
            str_element, dl_str, 'data_att.st_type', 'none', /ADD

            str_element, dl_str, 'data_att.units', unit, /ADD
            str_element, dl_str, 'colors', colors, /ADD
            str_element, dl_str, 'labels', labels, /ADD
;            str_element, dl_str, 'min_value', max_fillvalue, /ADD ;(FSPC is immune from fill values, anyway)
            IF (validmin_does_exist) THEN str_element, dl_str, 'min_value', validmin, /add 
            IF (validmax_does_exist) THEN str_element, dl_str, 'max_value', validmax, /add 
            str_element, dl_str, 'labflag', 1, /add
            str_element, dl_str, 'ytitle', tplot_var, /ADD
            str_element, dl_str, 'ysubtitle', '['+unit+']', /ADD
            str_element, dl_str, 'datagap', 60, /ADD
            store_data, tplot_var, data=d_str, limit=l_str, dlimit=dl_str, MIN=fill2nan
        ENDIF
    ENDFOR
ENDIF

END
