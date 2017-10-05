;+
;NAME: barrel_load_rcnt
;DESCRIPTION: CDF-to-TDAS import routine for BARREL (RCNT) 
;               data products
;
;REQUIRED INPUTS:
; none
;
;KEYWORD ARGUMENTS (OPTIONAL):
; PROBE:        String [array] of BARREL identifiers (e.g., '1A', '1B').
;                 Default is 'all' (i.e., all available payloads).  May also be
;                 a single string delimited by spaces (e.g., '1A 1B').
; DATATYPE:     String [array] of BARREL datatype identifiers (e.g. 'RCNT').
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
;Version 0.93e KBY 08/28/2013 explicit support for 'support_data' (e.g., FrameGroup);
;               support for noting VALID_MIN and VALID_MAX values
;Version 0.93d KBY 08/23/2013 quality indicator ("Q") renamed "Quality";
;               take unit labels from CDF metadata, update documentation.
;Version 0.93c KBY 08/23/2013 BARREL payload identifiers shortened to alphanumeric build
;               order only (e.g., '1A', '1B'), following change to CDF naming convention
;Version 0.93a KBY 08/16/2013 specify default value for 'unit'
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

pro barrel_load_rcnt, probe=probe, datatype=datatype, trange=trange, $
                    level=level, version=version, verbose=verbose, $
                    downloadonly=downloadonly, $
                    no_download=no_download, no_server=no_server, $
                    no_update=no_update, no_clobber=no_clobber, $
                    cdf_data=cdf_data, get_support_data=get_support_data, $
                    tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
                    varformat=varformat, valid_names=valid_names, files=files,$
                    CONVERT_L1_TO_PHYSICAL_UNITS=do_convert_L1


; specify VDATATYPES and VLEVELS for RCNT 
vlevels = ['l2','l1']        ; Zeroth element is our default (require only one level)
vdatatypes = ['rcnt']   ; Require only one datatype at this level

; submit request for PROBE, LEVEL, and DATATYPE
return_value = barrel_preload_actions(probe=probe,datatype=datatype, $ 
                trange=trange,level=level,version=version, $ 
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


            ; RCNT-class variables have name structure: 
            ;   brlPP_VARIABLE 
            ; 
            ; where 'brlPP' is the per-payload identifier, designating..  
            ;   brl = mission identifier (BARREL) 
            ;   PP  = alphanumerical payload identifier (build order) 
            ;   Note: the numerical part PP doubles as a campaign identifier 
            ;   C   = campaign identifier (1=2012-2013, 2=2012-2013)
            ;
            ; and VARIABLE designates the relevant RCNT-class variable
            ;   RCNT_FrameGroup
            ;   RCNT_PeakDet
            ;   RCNT_LowLevel
            ;   RCNT_Interrupt
            ;   RCNT_HighLevel
            ;   RCNT_Quality

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

            ; specify ISTP fill defaults for non-negative LONG/DOUBLE types
            ;max_fillvalue = -32768; non-negative INT (works for all non-negative)
            fill2nan = 0            ; not applicable
            
            breakpt = 6 
            CASE STRMID(tplot_var,breakpt) OF
                'FrameGroup': BEGIN
                        colors=0
                    END
                'Quality': BEGIN
                        colors=0
                    END
                'PeakDet': BEGIN
                        ;IF (level EQ 'l1') THEN unit='cnts/4sec' ELSE unit='cnts/sec'
                        IF (level EQ 'l2') THEN fill2nan = max_fillvalue 
                                ; non-negative LONG at L1, non-negative DOUBLE at L2
                                ; replace ISTP fill values (-1E-31) w/ NaN 
                        colors = 0
                    END
                'LowLevel': BEGIN
                        ;IF (level EQ 'l1') THEN unit='cnts/4sec' ELSE unit='cnts/sec'
                        IF (level EQ 'l2') THEN fill2nan = max_fillvalue 
                                ; non-negative LONG at L1, non-negative DOUBLE at L2
                                ; replace ISTP fill values (-1E-31) w/ NaN 
                        colors = 0
                    END
                'Interrupt': BEGIN
                        ;IF (level EQ 'l1') THEN unit='cnts/4sec' ELSE unit='cnts/sec'
                        IF (level EQ 'l2') THEN fill2nan = max_fillvalue 
                                ; non-negative LONG at L1, non-negative DOUBLE at L2
                                ; replace ISTP fill values (-1E-31) w/ NaN 
                        colors = 0
                    END
                'HighLevel': BEGIN
                        ;IF (level EQ 'l1') THEN unit='cnts/4sec' ELSE unit='cnts/sec'
                        IF (level EQ 'l2') THEN fill2nan = max_fillvalue 
                                ; non-negative LONG at L1, non-negative DOUBLE at L2
                                ; replace ISTP fill values (-1E-31) w/ NaN 
                        colors = 0
                    END
                ELSE: print, 'no matches for: ', tplot_var
            ENDCASE
            ; rename with inserted class identifer 
            new_name = STRMID(tplot_var,0,breakpt)+'RCNT_'+STRMID(tplot_var,breakpt) 
            ; search for existing variables, and delete
            exists = tnames(new_name, cnt) 
            IF (cnt NE 0) THEN store_data, new_name, /DELETE
            ; rename as appropriate 
            store_data, tplot_var, NEWNAME=new_name 
            tplot_var = new_name

            dprint, dlevel=4,'TPLOT_VAR: ', tplot_var

            ; report STATE type as 'none'? (e.g., neither POS nor VEL)
            str_element, dl_str, 'data_att.st_type', 'none', /ADD

            str_element, dl_str, 'data_att.units', unit, /ADD
            str_element, dl_str, 'colors', colors, /ADD
            str_element, dl_str, 'labels', labels, /ADD
            str_element, dl_str, 'labflag', 1, /add
;            str_element, dl_str, 'min_value', max_fillvalue, /ADD
            IF (validmin_does_exist) THEN str_element, dl_str, 'min_value', validmin, /add
            IF (validmax_does_exist) THEN str_element, dl_str, 'max_value', validmax, /add
            str_element, dl_str, 'ytitle', tplot_var, /ADD
            str_element, dl_str, 'ysubtitle', '['+unit+']', /ADD
            str_element, dl_str, 'datagap', 60, /ADD           
            ;str_element, l_str, 'ynozero', 1, /ADD           
            store_data, tplot_var, data=d_str, limit=l_str, dlimit=dl_str, MIN=fill2nan
        ENDIF
    ENDFOR
ENDIF

END
