; +
; NAME: THM_COTRANS_LMN
; 
; 
; , name_in, name_out, time, IMF, probe=probein, GSM=GSM, GSE=GSE, _Extra=ex
; 
; PURPOSE:
; 
; INPUTS (same as COTRANS.PRO):
;   name_in: data in the input coordinate system (t-plot variable name, or
;            array)
;   name_out: variable name for output (t-plot variable name, or array)
;   time: (optional) array of times for input values, if provided then the
;         first parameter is an array, and the second parameter is a named
;         variable to contain the output array.
;         
; KEYWORDS:
;   probe = Probe name. The default is 'all', i.e., load all available probes.
;           This can be an array of strings, e.g., ['a', 'b'] or a string
;           delimited by spaces, e.g., 'a b'
;   /GSM: Set to indicate input data is in GSM coordinates.
;   /GSE: Set to indicate input data is in GSE coordinates.   
; 
; NOTES:
;   Syntax: just like the function COTRANS.PRO
;       method 1: use tplot names, example:
;               thm_cotrans_lmn, 'tha_fgs_gse', 'tha_fgs_lmn'
;               then we can get a tplot name 'tha_fgs_lmn' to tplot or do other things
;       method 2: use variables, example:
;               thm_cotrans_lmn, gsedata, lmndata, time, probe='a', /gse
;               note time matched to the input data (gsedata here), the spacecraft which gets this
;               data, and the coordinate of the input data (/gse here) should be specified. and
;               the output (lmndata) is also matched to the variable time.
;    Use _EXTRA keyword to pass keywords to SOLARWIND_LOAD.PRO
;        resol - SW resolution in seconds
;        hro - use SW HRO database with default 1 min resolution
;        /hro,/min5 - use SW HRO database with 5 min resolution
;        h1 - use OMNI-2 1 hour SW database
;        wind - use WIND SW data
;               
; by Liu Jiang
; original edition: 09/21/2007
; latest edition: 10/26/2012
; by Vladimir Kondratovich:
; 2007/12/28 modified calls to take into account low-level changes. New SW keywords:
; 	resol - SW resolution in seconds
; 	hro - use SW HRO database with default 1 min resolution
; 	/hro,/min5 - use SW HRO database with 5 min resolution
; 	h1 - use OMNI-2 1 hour SW database
; 	wind - use WIND SW data
; by Lynn B. Wilson III:
; 2012/10/26 fixed bug when dl_in.cdf.gatt.source_name string is uppercase
;-

PRO thm_cotrans_lmn, name_in, name_out, time, PROBE=probein, GSM=GSM, GSE=GSE, _Extra=ex

    IF (N_PARAMS() EQ 2) THEN BEGIN
    ; get the data using t-plot name
        get_data,name_in,DATA=data_in,LIMIT=l_in,DLIMIT=dl_in ; krb
        data_in_coord = cotrans_get_coord(dl_in) ; krb
        ;probe = probein ; to be commended
;        probe = strmid(dl_in.cdf.gatt.source_name,2,1)
        ;;  LBW III : 2012/10/26
        IF ~KEYWORD_SET(probein) THEN BEGIN
          probe = STRLOWCASE(STRMID(dl_in.CDF.GATT.SOURCE_NAME,2,1))
        ENDIF ELSE BEGIN
          probe = STRLOWCASE(probein[0])
        ENDELSE
    ENDIF ELSE BEGIN
        data_in = {X:time, Y:name_in}
        probe = probein
        data_in_coord = 'unknown'
    ENDELSE
    ; examine if data input is correct
    IF STRMATCH(data_in_coord,'unknown') && ~ KEYWORD_SET(GSE) && ~ KEYWORD_SET(GSM) THEN BEGIN
        dprint, 'Please specify the coordinate of input data.'
        RETURN
    ENDIF

    IF KEYWORD_SET(GSE) THEN BEGIN
        if ~ STRMATCH(data_in_coord, 'unknown') && ~ STRMATCH(data_in_coord,'gse') THEN BEGIN
           dprint, 'coord of input '+name_in+': '+data_in_coord+'must be GSE'
           RETURN
        ENDIF
        data_in_coord = 'gse'
    ENDIF
    IF KEYWORD_SET(GSM) THEN BEGIN
        if ~ STRMATCH(data_in_coord, 'unknown') && ~ STRMATCH(data_in_coord,'gsm') THEN BEGIN
           dprint, 'coord of input '+name_in+': '+data_in_coord+'must be GSM'
           RETURN
        ENDIF
        data_in_coord = 'gsm'
    ENDIF
    ; transform coordinate to gsm no matter what the input coordinate is
    CASE 1 OF
        STRCMP(data_in_coord, 'gse'): BEGIN
            sub_GSE2GSM, data_in, data_med
            dprint, 'The input GSE data has been transformed to GSM'
        END
        STRCMP(data_in_coord, 'gsm'): BEGIN
            data_med = data_in
            dprint, 'The input data has already been in GSM coordinate'
        END
        ELSE: BEGIN
            dprint, 'The input coordinate is not supported yet'
            RETURN
        END
    ENDCASE
    ; transform data from gsm to lmn
    thm_gsm2lmn_wrap, data_med, data_conv, probe, _Extra=ex
    out_coord = 'lmn'
    ; store transformed data
    IF N_PARAMS() EQ 2 THEN BEGIN
        dl_conv = dl_in
        cotrans_set_coord,  dl_conv, out_coord ;krb
    ;; clear ytitle, so that it won't contain wrong info.
        str_element, dl_conv, 'ytitle', /DELETE
        dl_conv.LABELS = ['Bl', 'Bm', 'Bn']
        l_conv=l_in
        str_element, l_conv, 'ytitle', /DELETE

        store_data,name_out,DATA=data_conv,LIMIT=l_conv,DLIMIT=dl_conv ;krb
    ENDIF ELSE BEGIN
      ;;  LBW III : 2012/10/26
      IF (SIZE(data_conv,/TYPE) EQ 8) THEN name_out = data_conv.y
    ENDELSE
END
