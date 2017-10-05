;+
;NAME: barrel_load_hkpg
;DESCRIPTION: CDF-to-TDAS import routine for BARREL housekeeping (HKPG) data
;               (also 'HSK')
;
;REQUIRED INPUTS:
; none
;
;KEYWORD ARGUMENTS (OPTIONAL):
; PROBE:        String [array] of BARREL identifiers (e.g., '1A', '1B').
;                 Default is 'all' (i.e., all available payloads).  May also be
;                 a single string delimited by spaces (e.g., '1A 1B').
; DATATYPE:     String [array] of BARREL datatype identifiers (e.g. 'HKPG').
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
;Version 0.93e KBY 08/28/2013 explicit support for 'support_data' (e.g., FrameGroup);
;               support for noting VALID_MIN and VALID_MAX values
;Version 0.93d KBY 08/23/2013 quality indicator ("Q") renamed "Quality";
;               take unit labels from CDF metadata; update documentation.
;Version 0.93c KBY 08/23/2013 BARREL payload identifiers shortened to alphanumeric build
;               order only (e.g., '1A', '1B'), following change to CDF naming convention
;Version 0.93a KBY 08/16/2013 specify default value for 'unit'
;Version 0.92 KBY 06/04/2013 introduced VERSION keyword
;Version 0.91c KBY 05/31/2013 handling of ISTP fill values
;Version 0.91b KBY 05/31/2013 check for and delete existing variables of same name
;Version 0.91a KBY 05/28/2013 added file_retrieve keywords (no_download/update/clobber)
;Version 0.90c KBY 05/03/2013 corrected shift in conversion tables
;Version 0.90a KBY 04/22/2013 re-factoring of generic load actions; update CDF compatibility
;Version 0.83 KBY 11/28/2012 initial beta release
;Version 0.82 KBY 11/27/2012 debugging with updated CDF definitions
;Version 0.81 KBY 11/21/2012 new CDF definitions; updated treatment of PROBE 
;               keyword; distinction between L1 and L2 data product handling.
;Version 0.8 KBY 10/29/2012 from 'rbsp_load_efw_spec.pro' (Peter Schroeder),
;               and 'thm_load_goesmag.pro'
;
;-

pro barrel_load_hkpg, probe=probe, datatype=datatype, trange=trange, $
                    level=level, version=version, verbose=verbose, $
                    downloadonly=downloadonly, $
                    no_download=no_download, no_server=no_server, $
                    no_update=no_update, no_clobber=no_clobber, $
                    cdf_data=cdf_data, get_support_data=get_support_data, $
                    tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
                    varformat=varformat, valid_names=valid_names, files=files, $
                    CONVERT_L1_TO_PHYSICAL_UNITS=do_convert_L1

; specify VDATATYPES and VLEVELS for HKPG
vlevels = ['l2','l1']        ; Zeroth element is our default (require only one level)
vdatatypes = ['hkpg']   ; Require only one datatype at this level

; submit request for PROBE, LEVEL, and DATATYPE
return_value = barrel_preload_actions(probe=probe,datatype=datatype,$ $
                trange=trange,level=level,version=version,$ 
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

hkpg_names_table = [$
    ; Temperatures (+ 3 Aux Voltages)
    'T0_Scint',$
    'T1_Mag',$
    'T2_ChargeCont',$
    'T3_Battery',$
    'T4_PowerConv',$
    'T5_DPU',$
    'T6_Modem',$
    'T7_Structure',$
    'T8_Solar1',$
    'T9_Solar2',$
    'T10_Solar3',$
    'T11_Solar4',$
    'T12_TermTemp',$
    'T13_TermBatt',$
    'T14_TermCap',$
    'T15_CCStat',$
    ; Voltages
    'V0_VoltAtLoad',$
    'V1_Battery',$
    'V2_Solar1',$
    'V3_POS_DPU',$
    'V4_POS_XRayDet',$
    'V5_Modem',$
    'V6_NEG_XRayDet',$
    'V7_NEG_DPU',$
    'V8_Mag',$
    'V9_Solar2',$
    'V10_Solar3',$
    'V11_Solar4',$
    ; Currents
    'I0_TotalLoad',$
    'I1_TotalSolar',$
    'I2_Solar1',$
    'I3_POS_DPU',$
    'I4_POS_XRayDet',$
    'I5_Modem',$
    'I6_NEG_XRayDet',$
    'I7_NEG_DPU']
hkpg_units_table = [$
    ; Temperatures (+ 3 Aux Voltages)
    'deg C',$   ;   HKPG_T0_Scint 
    'deg C',$   ;   HKPG_T1_Mag
    'deg C',$   ;   HKPG_T2_ChargeCont
    'deg C',$   ;   HKPG_T3_Battery
    'deg C',$   ;   HKPG_T4_PowerConv
    'deg C',$   ;   HKPG_T5_DPU
    'deg C',$   ;   HKPG_T6_Modem
    'deg C',$   ;   HKPG_T7_Structure
    'deg C',$   ;   HKPG_T8_Solar1
    'deg C',$   ;   HKPG_T9_Solar2
    'deg C',$   ;   HKPG_T10_Solar3 
    'deg C',$   ;   HKPG_T11_Solar4
    'deg C',$   ;   HKPG_T12_TermTemp
    'V',$       ;   HKPG_T13_TermBatt
    'V',$       ;   HKPG_T14_TermCap
    'V',$       ;   HKPG_T15_CCStat
    ; Voltages
    'V',$       ;   HKPG_V0_VoltAtLoad
    'V',$       ;   HKPG_V1_Battery
    'V',$       ;   HKPG_V2_Solar1
    'V',$       ;   HKPG_V3_POS_DPU
    'V',$       ;   HKPG_V4_POS_XRayDet
    'V',$       ;   HKPG_V5_Modem
    'V',$       ;   HKPG_V6_NEG_XRayDet
    'V',$       ;   HKPG_V7_NEG_DPU
    'V',$       ;   HKPG_V8_Mag
    'V',$       ;   HKPG_V9_Solar2
    'V',$       ;   HKPG_V10_Solar3
    'V',$       ;   HKPG_V11_Solar4
    ; Currents
    'mA',$      ;   HKPG_I0_TotalLoad
    'mA',$      ;   HKPG_I1_TotalSolar
    'mA',$      ;   HKPG_I2_Solar1
    'mA',$      ;   HKPG_I3_POS_DPU
    'mA',$      ;   HKPG_I4_POS_XRayDet
    'mA',$      ;   HKPG_I5_Modem
    'mA',$      ;   HKPG_I6_NEG_XRayDet
    'mA']       ;   HKPG_I7_NEG_DPU
hkpg_label_table = [$
    ; Temperatures (+ 3 Aux Voltages)
    'Scintillator Temp',$       ;   HKPG_T0_Scint 
     'Magnetometer Temp',$      ;   HKPG_T1_Mag
     'Charge Controller Temp',$ ;   HKPG_T2_ChargeCont
     'Battery Temp',$           ;   HKPG_T3_Battery
     'DC-DC Power Converter Temp',$     ;   HKPG_T4_PowerConv
    'DPU Temp',$                ;   HKPG_T5_DPU
    'Modem Temp',$              ;   HKPG_T6_Modem
    'Payload Structure Temp',$  ;   HKPG_T7_Structure
    'Solar Panel 1 Temp',$      ;   HKPG_T8_Solar1 
    'Solar Panel 2 Temp',$      ;   HKPG_T9_Solar2
    'Solar Panel 3 Temp',$      ;   HKPG_T10_Solar3 
    'Solar Panel 4 Temp',$      ;   HKPG_T11_Solar4
    'Terminate Temp',$          ;   HKPG_T12_TermTemp
    'Terminate Battery Voltage',$       ;   HKPG_T13_TermBatt
    'Terminate Capacitor Voltage',$     ;   HKPG_T14_TermCap
    'Charge Controller Status',$;   HKPG_T15_CCStat
    ; Voltages
    'Voltage at Load',$         ;   HKPG_V0_VoltAtLoad
    'Battery Voltage',$         ;   HKPG_V1_Battery
    'Solar Panel 1 Voltage',$   ;   HKPG_V2_Solar1
    'DPU +5V Voltage',$         ;   HKPG_V3_POS_DPU
    'PMT +5V Voltage',$         ;   HKPG_V4_POS_XRayDet
    'Modem Voltage',$           ;   HKPG_V5_Modem
    'PMT -5V Voltage',$         ;   HKPG_V6_NEG_XRayDet
    'DPU -5V Voltage',$         ;   HKPG_V7_NEG_DPU
    'MAG +5V Voltage',$         ;   HKPG_V8_Mag
    'Solar Panel 2 Voltage',$   ;   HKPG_V9_Solar2
    'Solar Panel 3 Voltage',$   ;   HKPG_V10_Solar3
    'Solar Panel 4 Voltage',$   ;   HKPG_V11_Solar4
    ; Currents
    'Total Current at Load',$   ;   HKPG_I0_TotalLoad
    'Total Solar Current',$     ;   HKPG_I1_TotalSolar
    'Solar Panel 1 Current',$   ;   HKPG_I2_Solar1
    'DPU +5V Current',$         ;   HKPG_I3_POS_DPU
    'PMT +5V Current',$         ;   HKPG_I4_POS_XRayDet
    'Modem Current',$           ;   HKPG_I5_Modem
    'PMT -5V Current',$         ;   HKPG_I6_NEG_XRayDet
    'DPU -5V Current']          ;   HKPG_I7_NEG_DPU

hkpg_lineM_table = [$   ; slope "m" in y=mx+b linear conversion
    ; Temperatures (+ 3 Aux Voltages)
    0.007629,$	;   HKPG_T0_Scint 
    0.007629,$	;   HKPG_T1_Mag
    0.007629,$	;   HKPG_T2_ChargeCont
    0.007629,$	;   HKPG_T3_Battery
    0.007629,$	;   HKPG_T4_PowerConv
    0.007629,$	;   HKPG_T5_DPU
    0.007629,$	;   HKPG_T6_Modem
    0.007629,$	;   HKPG_T7_Structure
    0.007629,$	;   HKPG_T8_Solar1
    0.007629,$	;   HKPG_T9_Solar2
    0.007629,$	;   HKPG_T10_Solar3 
    0.007629,$	;   HKPG_T11_Solar4
    0.007629,$	;   HKPG_T12_TermTemp
    0.0003052,$ ;   HKPG_T13_TermBatt (actually an auxiliary voltage)
    0.0003052,$ ;   HKPG_T14_TermCap (actually an auxiliary voltage)
    0.0001526,$ ;   HKPG_T15_CCStat (actually an auxiliary voltage)
    ; Voltages
    0.0003052,$ ;   HKPG_V0_VoltAtLoad
    0.0003052,$ ;   HKPG_V1_Battery
    0.0006104,$ ;   HKPG_V2_Solar1
    0.0001526,$ ;   HKPG_V3_POS_DPU
    0.0001526,$ ;   HKPG_V4_POS_XRayDet
    0.0003052,$ ;   HKPG_V5_Modem
    -0.0001526,$;   HKPG_V6_NEG_XRayDet
    -0.0001526,$;   HKPG_V7_NEG_DPU
    0.0001526,$ ;   HKPG_V8_Mag
    0.0006104,$ ;   HKPG_V9_Solar2
    0.0006104,$ ;   HKPG_V10_Solar3
    0.0006104,$ ;   HKPG_V11_Solar4
    ; Currents
    0.00005086,$;   HKPG_I0_TotalLoad
    0.00006104,$;   HKPG_I1_TotalSolar
    0.00006104,$;   HKPG_I2_Solar1
    0.00001017,$;   HKPG_I3_POS_DPU
    0.000001017,$;   HKPG_I4_POS_XRayDet
    0.00005086,$;   HKPG_I5_Modem
    -0.0000001261,$;   HKPG_I6_NEG_XRayDet
    -0.000001017];   HKPG_I7_NEG_DPU

hkpg_lineB_table = [$   ; intercept "b" in y=mx+b linear conversion
    ; Temperatures (+ 3 Aux Voltages)
    -273.15,$   ;   HKPG_T0_Scint 
    -273.15,$   ;   HKPG_T1_Mag
    -273.15,$   ;   HKPG_T2_ChargeCont
    -273.15,$   ;   HKPG_T3_Battery
    -273.15,$   ;   HKPG_T4_PowerConv
    -273.15,$   ;   HKPG_T5_DPU
    -273.15,$   ;   HKPG_T6_Modem
    -273.15,$   ;   HKPG_T7_Structure
    -273.15,$   ;   HKPG_T8_Solar1
    -273.15,$   ;   HKPG_T9_Solar2
    -273.15,$   ;   HKPG_T10_Solar3 
    -273.15,$   ;   HKPG_T11_Solar4
    -273.15,$   ;   HKPG_T12_TermTemp
    0.,$        ;   HKPG_T13_TermBatt
    0.,$        ;   HKPG_T14_TermCap
    0.,$        ;   HKPG_T15_CCStat
    ; Voltages
    0.,$        ;   HKPG_V0_VoltAtLoad
    0.,$        ;   HKPG_V1_Battery
    0.,$        ;   HKPG_V2_Solar1
    0.,$        ;   HKPG_V3_POS_DPU
    0.,$        ;   HKPG_V4_POS_XRayDet
    0.,$        ;   HKPG_V5_Modem
    0.,$        ;   HKPG_V6_NEG_XRayDet
    0.,$        ;   HKPG_V7_NEG_DPU
    0.,$        ;   HKPG_V8_Mag
    0.,$        ;   HKPG_V9_Solar2
    0.,$        ;   HKPG_V10_Solar3
    0.,$        ;   HKPG_V11_Solar4
    ; Currents
    0.,$        ;   HKPG_I0_TotalLoad
    0.,$        ;   HKPG_I1_TotalSolar
    0.,$        ;   HKPG_I2_Solar1
    0.,$        ;   HKPG_I3_POS_DPU
    0.,$        ;   HKPG_I4_POS_XRayDet
    0.,$        ;   HKPG_I5_Modem
    0.,$        ;   HKPG_I6_NEG_XRayDet
    0.]         ;   HKPG_I7_NEG_DPU

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

            ;get_data, tplot_var, dlimitis, dlimits = dl_str <--????

            str_element, dl_str, 'data_att', success=yes_data_att
            IF ~yes_data_att THEN BEGIN
                data_att = {units:'', coord_sys:'none'}
                str_element, dl_str, 'data_att', data_att, /add
            ENDIF

            ; Add 'none' to coord_sys if it doesn't exist
            str_element, dl_str.data_att, 'coord_sys', success=yes_coord
            IF yes_coord THEN coord=dl_str.data_att.coord_sys


            ; HKPG-class variables have name structure:
            ;   brlPP_HKPG_VARIABLE 
            ;
            ; where 'brlPP' is the per-payload identifier, designating..  
            ;   brl = mission identifier (BARREL) 
            ;   PP  = alphanumerical payload identifier (build order) 
            ;   Note: the numerical part PP doubles as a campaign identifier 
            ;   C   = campaign identifier (1=2012-2013, 2=2012-2013)
            ;
            ; and VARIABLE designates the relevant HKPG-class variable
            ;   HKPG_FrameGroup
            ;   HKPG_Quality
            ;   HKPG_T0_Scint 
            ;   HKPG_T1_Mag
            ;   HKPG_T2_ChargeCont
            ;   HKPG_T3_Battery
            ;   HKPG_T4_PowerConv
            ;   HKPG_T5_DPU
            ;   HKPG_T6_Modem
            ;   HKPG_T7_Structure
            ;   HKPG_T8_Solar1
            ;   HKPG_T9_Solar2
            ;   HKPG_T10_Solar3 
            ;   HKPG_T11_Solar4
            ;   HKPG_T12_TermTemp
            ;   HKPG_T13_TermBatt
            ;   HKPG_T14_TermCap
            ;   HKPG_T15_CCStat
            ;   HKPG_V0_VoltAtLoad
            ;   HKPG_V1_Battery
            ;   HKPG_V2_Solar1
            ;   HKPG_V3_POS_DPU
            ;   HKPG_V4_POS_XRayDet
            ;   HKPG_V5_Modem
            ;   HKPG_V6_NEG_XRayDet
            ;   HKPG_V7_NEG_DPU
            ;   HKPG_V8_Mag
            ;   HKPG_V9_Solar2
            ;   HKPG_V10_Solar3
            ;   HKPG_V11_Solar4
            ;   HKPG_I0_TotalLoad
            ;   HKPG_I1_TotalSolar
            ;   HKPG_I2_Solar1
            ;   HKPG_I3_POS_DPU
            ;   HKPG_I4_POS_XRayDet
            ;   HKPG_I5_Modem
            ;   HKPG_I6_NEG_XRayDet
            ;   HKPG_I7_NEG_DPU
            ;   HKPG_numOfSats
            ;   HKPG_timeOffset
            ;   HKPG_termStatus
            ;   HKPG_cmdCounter
            ;   HKPG_modemCounter
            ;   HKPG_dcdCounter
            ;   HKPG_weeks
            
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

            ; specify defaults for non-negative INTEGER types
            ;max_fillvalue = -32768+1; non-negative INT
            fill2nan = 0            ; not applicable
            
            breakpt = 6 
            CASE STRMID(tplot_var,breakpt) OF
                'FrameGroup': BEGIN     ;   HKPG_FrameGroup
                        ;unit='none' 
                    END
                'Quality': BEGIN 
                        ;unit='none' 
                        ;labels='Quality Flag' 
                    END
                'numOfSats': BEGIN      ;   HKPG_numOfSats 
                        ;unit='none' 
                        ;labels='Number of GPS Satellites in view'
                    END
                'timeOffset': BEGIN     ;   HKPG_timeOffset 
                        ;unit='none' 
                        ;labels='Number of leap seconds'
                    END
                'termStatus': BEGIN     ;   HKPG_termStatus
                        ;unit='none' 
                        ;labels='Terminate Status Bit (high = terminated)'
                    END
                'cmdCounter': BEGIN     ;   HKPG_cmdCounter
                        ;unit='none' 
                        ;labels='Command Counter'
                    END
                'modemCounter': BEGIN   ;   HKPG_modemCounter
                        ;unit='none' 
                        ;labels='Modem Reset Counter'
                    END
                'dcdCounter': BEGIN     ;   HKPG_dcdCounter
                        ;unit='none' 
                        ;labels='Number of times DCD has been de-asserted'
                    END
                'weeks': BEGIN          ;   HKPG_weeks
                        ;unit='none' 
                        ;labels='Number of weeks since 6 Jan 1980'
                    END
                ELSE: BEGIN
                        variable_handle = STRMID(tplot_var,breakpt)
                        hkpg_id = WHERE(variable_handle EQ hkpg_names_table, n_matches)
                        IF (n_matches NE 0) THEN BEGIN
                          
                            ; collapse hkpg_id (make scalar; should be unique)
                            hkpg_id = hkpg_id[0]

                            ; assign label
                            ;labels = hkpg_label_table[hkpg_id]
                            
                            ; specify units 
                            ;IF ((level EQ 'l1') AND (not keyword_set(do_convert_L1))) THEN $
                            ;    unit = 'ADC Value' ELSE unit=hkpg_units_table[hkpg_id]
                            IF ((level EQ 'l1') AND (keyword_set(do_convert_L1))) THEN $
                                unit=hkpg_units_table[hkpg_id]

                            ; non-negative INTs at L1, possibly negative FLOATs at L2
                            ; at L1, use the defaults
                            ; for L1 conversions, replace ISTP fill values (-2^31) w/ NAN 
                            IF ((level EQ 'l1') AND (keyword_set(do_convert_L1))) THEN BEGIN 
                                print, 'L1 data product.. converting to physical units'
                                
                                ; address ISTP fill values *before* conversion 
                                fill2nan = max_fillvalue    ; replace ISTP fill values (-2^31) w/ NaN 
                                fill2nan_index = WHERE(d_str.y LE fill2nan, fillvalue_cnt) 
                                new_y = FLOAT(d_str.y) 
                                IF (fillvalue_cnt NE 0) THEN new_y[fill2nan_index] = !Values.F_NAN 

                                ; NOTE: the above should catch any out-of-range values
                                ;  VALIDMIN and VALIDMAX should be converted or neglected
                                validmin_does_exist = 0
                                validmax_does_exist = 0

                                ; proceed with nominal conversion 
                                m = hkpg_lineM_table[hkpg_id]
                                b = hkpg_lineB_table[hkpg_id]
                                new_y = m*TEMPORARY(new_y) + b
                                d_str = {x:d_str.x, y:new_y} 
                            ENDIF 
                            ; at L2, replace ISTP fill values (-1E31) w/ NaN 
                            IF (level EQ 'l2') THEN fill2nan = max_fillvalue 
   
                        ENDIF ELSE print, 'no matches for: ', tplot_var
                    END
            ENDCASE
            ; rename with inserted class identifer
            new_name = STRMID(tplot_var,0,breakpt)+'HKPG_'+STRMID(tplot_var,breakpt)
            ; search for existing variables, and delete
            exists = tnames(new_name, cnt) 
            IF (cnt NE 0) THEN store_data, new_name, /DELETE
            ; rename as appropriate 
            store_data, tplot_var, NEWNAME=new_name 
            tplot_var = new_name
            
            colors=6

            dprint, dlevel=4,'TPLOT_VAR: ', tplot_var

            ; report STATE type as 'none'? (e.g., neither POS nor VEL)
            str_element, dl_str, 'data_att.st_type', 'none', /ADD

            str_element, dl_str, 'data_att.units', unit, /ADD
            str_element, dl_str, 'colors', colors, /ADD
            str_element, dl_str, 'labels', labels, /ADD
            str_element, dl_str, 'labflag', 1, /add
;            str_element, dl_str, 'min_value', max_fillvalue+1, /ADD
            IF (validmin_does_exist) THEN str_element, dl_str, 'min_value', validmin, /add 
            IF (validmax_does_exist) THEN str_element, dl_str, 'max_value', validmax, /add 
            str_element, dl_str, 'ytitle', tplot_var, /ADD
            str_element, dl_str, 'ysubtitle', '['+unit+']', /ADD
            store_data, tplot_var, data=d_str, limit=l_str, dlimit=dl_str, MIN=fill2nan
        ENDIF
    ENDFOR
ENDIF


END
