;+
;NAME: barrel_load_mspc
;DESCRIPTION: CDF-to-TDAS import routine for BARREL medium-speed spectral 
;               (MSPC) data products (also 'MSPEC')
;
;REQUIRED INPUTS:
; none
;
;KEYWORD ARGUMENTS (OPTIONAL):
; PROBE:        String [array] of BARREL identifiers (e.g., '1A', '1B').
;                 Default is 'all' (i.e., all available payloads).  May also be
;                 a single string delimited by spaces (e.g., '1A 1B').
; DATATYPE:     String [array] of BARREL datatype identifiers (e.g. 'MSPC').
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
;Version 0.95a KBY 12/23/2013 fixed intermittant display of colorbar bug
;Version 0.94b KBY 10/02/2013 fixed mislabeling of MSPC "cnt_error" variable
;Version 0.93e KBY 08/28/2013 support for noting VALID_MIN and VALID_MAX values
;Verison 0.93d KBY 08/25/2013 update documentation.
;Version 0.93c KBY 08/23/2013 BARREL payload identifiers shortened to alphanumeric build
;               order only (e.g., '1A', '1B'), following change to CDF naming convention
;Version 0.93b KBY 08/23/2013 quality indicator ("Q") renamed "Quality";
;               insert datatype identifier in "cnt_error" variable name;
;               take unit labels from CDF metadata; remove timestamp shift (see v0.90b)
;Version 0.93a KBY 08/16/2013 accomodate v02 CDF namechange of "MSPC_ERROR" to "cnt_error";
;              specify default value for "unit"
;Version 0.92f KBY 08/09/2013 CDF-specified "energy bin centers" unmodified
;Version 0.92 KBY 06/04/2013 introduced VERSION keyword
;Version 0.91c KBY 05/31/2013 handling of ISTP fill values
;Version 0.91b KBY 05/31/2013 check for and delete existing variables of same name
;Version 0.91a KBY 05/28/2013 updated MPM's 'brl_makeedges.pro" to most recent version;
;               added file_retrieve keywords (no_download/update/clobber)
;Version 0.90c KBY 05/03/2013 fixed bug in timestamp shift
;Version 0.90a KBY 04/22/2013 re-factoring of generic load actions; update CDF compatibility
;Version 0.83 KBY 11/28/2012 initial beta release
;Version 0.82 KBY 11/27/2012 debugging with updated CDF definitions
;Version 0.81 KBY 11/21/2012 new CDF definitions; updated treatment of PROBE 
;               keyword; distinction between L1 and L2 data product handling.
;Version 0.8 KBY 10/29/2012 from 'rbsp_load_efw_spec.pro' (Peter Schroeder),
;               and 'thm_load_goesmag.pro'
;
;-

pro barrel_load_mspc, probe=probe, datatype=datatype, trange=trange, $
                    level=level, version=version, verbose=verbose, $
                    downloadonly=downloadonly, $
                    no_download=no_download, no_server=no_server, $
                    no_update=no_update, no_clobber=no_clobber, $
                    cdf_data=cdf_data, get_support_data=get_support_data, $
                    tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
                    varformat=varformat, valid_names=valid_names, files=files, $
                    CONVERT_L1_TO_PHYSICAL_UNITS=do_convert_L1


; specify VDATATYPES and VLEVELS for MSPC
vlevels = ['l2','l1']        ; Zeroth element is our default (require only one level)
vdatatypes = ['mspc']   ; Require only one datatype at this level

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


            ; MSPC-class variables have name structure: 
            ;   brlPP_VARIABLE 
            ; 
            ; where 'brlPP' is the per-payload identifier, designating..  
            ;   brl = mission identifier (BARREL) 
            ;   PP  = alphanumerical payload identifier (build order) 
            ;   Note: the numerical part PP doubles as a campaign identifier 
            ;   C   = campaign identifier (1=2012-2013, 2=2012-2013)
            ;
            ; and VARIABLE designates the relevant MSPC-class variable
            ;   MSPC_FrameGroup
            ;   MSPC
            ;   MSPC_cnt_error (standard error in MSPC countrate) [L2 only]
            ;   MSPC_Quality
            ;

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

            breakpt = 6
            CASE STRMID(tplot_var,breakpt) OF
                'FrameGroup': BEGIN
                        colors=0
                        ;max_fillvalue = -32768  ; (immune) non-negative INT 
                        fill2nan = 0            ; not applicable
                        
                        ; rename with inserted class identifier 
                        new_name = STRMID(tplot_var,0,breakpt)+'MSPC_'+$
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
                        ;max_fillvalue = -32768  ; (immune) non-negative INT 
                        fill2nan = 0            ; not applicable
                        
                        ; rename with inserted class identifier
                        new_name = STRMID(tplot_var,0,breakpt)+'MSPC_'+$
                            STRMID(tplot_var,breakpt)
                        ; search for existing variables, and delete
                        exists = tnames(new_name, cnt) 
                        IF (cnt NE 0) THEN store_data, new_name, /DELETE
                        ; rename as appropriate 
                        store_data, tplot_var, NEWNAME=new_name
                        tplot_var = new_name
                    END
                'cnt_error': BEGIN      ; a L2 only data product
                        
                        ; handling of ISTP fill values 
                        ;max_fillvalue = -2L^31+1        ; no L1 value, non-negative DOUBLE at L2
                        IF (level EQ 'l2') THEN $ 
                            fill2nan = max_fillvalue $  ; replace ISTP fill values (-1E31) w/ NaN 
                            ELSE fill2nan = 0           ; not applicable 

                        ; rename with inserted class identifier 
                        new_name = STRMID(tplot_var,0,breakpt)+'MSPC_'+$ 
                            STRMID(tplot_var,breakpt) 
                        ; search for existing variables, and delete 
                        exists = tnames(new_name, cnt) 
                        IF (cnt NE 0) THEN store_data, new_name, /DELETE 
                        ; rename as appropriate 
                        store_data, tplot_var, NEWNAME=new_name 
                        tplot_var = new_name
                    END
                'MSPC': BEGIN
                       
                        ; handling of ISTP fill values 
                        ;max_fillvalue = -2L^31+1        ; non-negative LONG at L1
                                                        ; non-negative DOUBLE at L2 
                        
                        IF (level EQ 'l2') THEN $ 
                            fill2nan = max_fillvalue $  ; replace ISTP fill values (-1E31) w/ NaN 
                            ELSE fill2nan = 0           ; not applicable 
                        
                        IF ((level EQ 'l1') AND (KEYWORD_SET(do_convert_L1))) THEN BEGIN
                            ; address ISTP fill values *before* conversion
                            fill2nan = max_fillvalue    ; replace ISTP fill values (-2^31) w/ NaN
                            fill2nan_index = WHERE(d_str.y LE fill2nan, fillvalue_cnt) 
                            new_y = DOUBLE(d_str.y) 
                            IF (fillvalue_cnt NE 0) THEN new_y[fill2nan_index] = !Values.F_NAN 
                           
                            ; NOTE: the above should catch any out-of-range values
                            ;  VALIDMIN and VALIDMAX should be converted or neglected
                            validmin_does_exist = 0
                            validmax_does_exist = 0

                            ; restore to usual structure
                            d_str = {x:d_str.x, y:new_y, v:d_str.v}
                        ENDIF
                            
                        ; make unit assignments    
                        IF ((level EQ 'l1') AND (not keyword_set(do_convert_L1))) THEN BEGIN
                            z_units = unit              ;[cnts/4sec]
                            unit = 'MSPC channel#'
                        ENDIF ELSE IF (level EQ 'l1') THEN BEGIN
                            ; L1>L2 conversion 
                            z_units = unit + '/keV/sec' ;(describe actions)
                            unit='keV'
                        ENDIF ELSE BEGIN
                            z_units = unit              ;[cnts/keV/sec]
                            unit = 'keV'
                        ENDELSE

                        ; Note: nuances in TPLOT/SPECPLOT plotting 
                        ; 1) CDF epoch timestamps are for the start of each accumulation.  
                        ;       TPLOT/SPECPLOT interpret this timestamp as the "center" 
                        ;       of the accumulation period, and plot accordingly.  
                        ;    IF THIS BEHAVIOR IS UNDESIREABLE, A MANUAL SHIFT MAY BE 
                        ;       INTRODUCED TO THE TIMESTAMP VARIABLE!  
                        ; 2) The 'data.v' variable represents "channel center", with edges 
                        ;       defined by the DELTA_PLUS_VAR and DELTA_MINUS_VAR variables.  
                        ;    THESE EDGES ARE NOT RECOGNIZED BY TPLOT/SPECPLOT, WHICH WILL 
                        ;       INSTEAD CALCULATE EDGES AS THE ARITHMATIC MEAN OF CENTERS!  
   
                        ; actions on L2 and converted L1 
                        IF ~((level EQ 'l1') AND (not keyword_set(do_convert_L1))) THEN BEGIN 
                            ; CDF-generator code (as of ~07/14/2013) 
                            ;   scale = 2.4414 
                            ;   half_width = (raw_edges[i + 1] - raw_edges[i]) / 2 
                            ;   mid_point = scale * (raw_edges[i] + half_width) 
                            
                            ; Adaptation: 
                            ; retrieve energy channel edges from MPM's code 
                            edges = (brl_makeedges()).med
                            IF ((level EQ 'l1') AND (keyword_set(do_convert_L1)) AND (0)) THEN BEGIN 
                                ; experimental support for updated "brl_makeedges" version
                                
                                ; form variable strings
                                pp_stem = STRMID(tplot_var,0,breakpt)
                                print, 'EXPERIMENTAL LOAD: '+pp_stem
                                pp = STRMID(pp_stem,3,2)
                                xtal_temp_varname = pp_stem + 'HKPG_T0_Scint' 
                                dpu_temp_varname = pp_stem + 'HKPG_T5_DPU' 
                                peak511_varname = pp_stem + 'SSPC_Peak_511'
                                hkpg_prerequisites = [xtal_temp_varname, dpu_temp_varname] 
                                hkpg_prerequisites2 = ['T0_Scint', 'T5_DPU']
                                sspc_prerequisites = [peak511_varname] 
                                sspc_prerequisites2 = ['Peak_511']

                                ; check to see whether we have available the HKPG & SSPC support variables
                                hkpg_prereqs_exists = tnames(hkpg_prerequisites, hkpg_p_cnt)
                                sspc_prereqs_exists = tnames(sspc_prerequisites, sspc_p_cnt)
                                
                                ; if these don't exist, stop to load them (selective load!)
                                IF (hkpg_p_cnt NE N_ELEMENTS(hkpg_prerequisites)) THEN BEGIN
                                    ; load in the necessary HKPG variable(s)
                                    barrel_load_data, PROBE=pp, DATATYPE='HKPG', trange=trange, $ 
                                        level=level, version=version, verbose=verbose, $ 
                                        downloadonly=downloadonly, $ 
                                        no_download=no_download, no_server=no_server, $ 
                                        no_update=no_update, no_clobber=no_clobber, $ 
                                        cdf_data=cdf_data, get_support_data=get_support_data, $ 
                                        tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $ 
                                        varformat=hkpg_prerequisites2, valid_names=valid_names, files=files, $ 
                                        CONVERT_L1_TO_PHYSICAL_UNITS=do_convert_L1
                                        ; NOTE: we don't have to worry about unconverted L1 due to a lower-level IF/THEN block
                                ENDIF ; ELSE they exist
                                IF (sspc_p_cnt NE N_ELEMENTS(sspc_prerequisites)) THEN BEGIN
                                    ; load in the necessary SSPC variable(s)
                                    barrel_load_data, PROBE=pp, DATATYPE='SSPC', trange=trange, $ 
                                        level=level, version=version, verbose=verbose, $ 
                                        downloadonly=downloadonly, $ 
                                        no_download=no_download, no_server=no_server, $ 
                                        no_update=no_update, no_clobber=no_clobber, $ 
                                        cdf_data=cdf_data, get_support_data=get_support_data, $ 
                                        tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $ 
                                        varformat=sspc_prerequisites2, valid_names=valid_names, files=files, $ 
                                        CONVERT_L1_TO_PHYSICAL_UNITS=do_convert_L1
                                        ; NOTE: we don't have to worry about unconverted L1 due to a lower-level IF/THEN block
                                ENDIF ; ELSE it exists
                                
                                ; get y-value arrays for each quantity
                                GET_DATA, xtal_temp_varname, DATA=xtal_temp_full
                                xtal_temp = xtal_temp_full.y & w = WHERE(FINITE(xtal_temp))
                                xtal_temp = MEAN(xtal_temp[w])
                                
                                GET_DATA, dpu_temp_varname, DATA=dpu_temp_full 
                                dpu_temp = dpu_temp_full.y & w = WHERE(FINITE(dpu_temp))
                                dpu_temp = MEAN(dpu_temp[w])

                                GET_DATA, peak511_varname, DATA=peak511_full 
                                peak511 = peak511_full.y & w = WHERE(FINITE(peak511))
                                peak511 = MEAN(peak511[w])
                                print, edges
                                edges = (brl_makeedges(flightID=pp, xtal_temp=xtal_temp, dpu_temp=dpu_temp, peak511=peak511)).med       
                                print, edges
                            ENDIF 
                            
                            ; get channel widths [keV] 
                            n_channels = N_ELEMENTS(edges)-1 
                            widths = edges[IndGEN(n_channels)+1] - edges[IndGEN(n_channels)] 
                            
                            ; calculate nominal bin centers 
                            centers = edges[IndGEN(n_channels)] + widths/2.  
                            ; done!  


                          integration_time = 4. * 0.99989        ; (4 frames)*(999.89ms/frame) 
                          ; nominal mapping to energy space (converted L1 only) 
                            IF ((level EQ 'l1') AND (keyword_set(do_convert_L1))) THEN BEGIN
                            ; scale counts by channel width and integration time 
                                new_y = (d_str.y/REBIN($
                                    REFORM(widths,1,N_ELEMENTS(widths)), $
                                    N_ELEMENTS(d_str.x), $
                                    N_ELEMENTS(d_str.y)/N_ELEMENTS(d_str.x))) $
                                    / integration_time      
                            ENDIF ELSE new_y = TEMPORARY(d_str.y)
                            
                            one_cnt_level = MIN((1./widths)/integration_time)
                            offset = one_cnt_level/1.^(-6)      ; introduces a small offset to get us off of zero in a LOG plot
                            ;str_element, l_str, 'zrange', [one_cnt_level,200], /ADD 
                            ylim, l_str, 100, MAX(edges), LOG=1 

                            IF ((level EQ 'l1') AND (keyword_set(do_convert_L1))) THEN $
                                new_v = centers ELSE new_v = d_str.v
                            
                            ; prepare modified data for new variable
                            d_str = {x:d_str.x, y:(new_y+offset), v:new_v}
                        
                        ENDIF ; ELSE 
                            ; no ylimits defined (linear scale)
                            ; no zrange defined (linear scale)
                        str_element, l_str, 'NO_COLOR_SCALE', 0, /ADD_REPLACE
                        str_element, l_str, 'X_NO_INTERP', 1, /ADD
                        str_element, l_str, 'Y_NO_INTERP', 1, /ADD
                        str_element, l_str, 'ztitle', z_units, /ADD
                        str_element, l_str, 'zlog', 1, /ADD
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
;            str_element, dl_str, 'min_value', max_fillvalue, /ADD
            IF (validmin_does_exist) THEN str_element, dl_str, 'min_value', validmin, /add
            IF (validmax_does_exist) THEN str_element, dl_str, 'max_value', validmax, /add
            str_element, dl_str, 'ytitle', tplot_var, /ADD
            str_element, dl_str, 'ysubtitle', '['+unit+']', /ADD
            str_element, dl_str, 'datagap', 60, /ADD
            store_data, tplot_var, data=d_str, limit=l_str, dlimit=dl_str, MIN=fill2nan
        ENDIF 
    ENDFOR
ENDIF


END
