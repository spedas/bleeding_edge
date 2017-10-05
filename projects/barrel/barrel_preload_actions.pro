;+
;NAME: barrel_preload_actions
;
;DESCRIPTION: CDF-to-TDAS pre-import routine for BARREL data
;
;REQUIRED INPUTS: (see Required Keyword Arguments, below)
; **NOTE** 'barrel_preload_actions' is not intended to be a user-facing routine.  
;            Please use the BARREL master load routine 'barrel_load_data.pro', or
;            individual load routines of form 'barrel_load_<datatype>.pro'
;
;REQUIRED KEYWORD ARGUMENTS:
; VDATATYPES:   String [array] of valid datatype identifiers, appropriate for desired datatype
; VLEVELS:       String [array] of valid level codes, appropriate for desired datatype
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
; /GET_SUPPORT_DATA: Load support_data variables as well as data variables.
; TPLOTNAMES:   (passed through to 'cdf2tplot' and 'cdf_info_to_tplot')
; VARFORMAT:    String (passed through to 'cdf2tplot').
;
; (FILE_RETRIEVE KEYWORDS-- descriptions borrowed from file_retrieve.pro)
; /DOWNLOADONLY:
;               Set to 1 to only download files but not load files into memory.
; /NO_SERVER:   Set to 1 to prevent any contact with a remote server.
; /NO_DOWNLOAD: Identical to NO_SERVER keyword. Obsolete, but retained for backward compatibility
; /NO_UPDATE:   Set to 1 to prevent contact to server if local file already exists. (this is similar to no_clobber)
; /NO_CLOBBER:  Set to 1 to prevent existing files from being overwritten. (A warning message will be displayed if remote server has)
;
;RETURN VALUE:
; a structure, with tags 'level' and 'tplot_variables'
; -1, if required keyword (VLEVELS or VDATATYPES) not specified
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
;Version 0.96a KBY 07/04/2014 RC1; definitive campaign 2 payload list (+ fix for wildcarded looping)
;Version 0.95b KBY 12/29/2013 enable campaign 2 payloads
;Version 0.93e KBY 08/28/2013 updated documentation
;Version 0.93c KBY 08/23/2013 BARREL payload identifiers shortened to alphanumeric build
;               order only (e.g., '1A', '1B'), following change to CDF naming convention
;Version 0.92d KBY 07/04/2013 improved handling of VERSION keyword (original not overwritten)
;Version 0.92c KBY 06/05/2013 sanitize PROBE arguments; update VERSION defaults
;Version 0.92b KBY 06/04/2013 introduced VERSION keyword, with default preference for 'v01'
;Version 0.91a KBY 05/28/2013 updated to reflect namechange from 'gps' to 'ephm';
;               added file_retrieve keywords (no_download/update/clobber) and create/update 
;               a local copy of !barrel to override global defaults
;Version 0.90b KBY 04/25/2013 make request DATATYPE a guaranteed scalar (like request LEVEL)
;Version 0.90a KBY 04/19/2013 re-factoring of generic pre-load and read actions
;               from datatype specific load procedures
;
;-

FUNCTION barrel_preload_actions, probe=probe, datatype=datatype, trange=trange, $
                    level=level, version=version, $
                    vdatatypes=vdatatypes, vlevels=vlevels, $
                    verbose=verbose, get_support_data=get_support_data, $ 
                    downloadonly=downloadonly,$
                    no_download=no_download, no_server=no_server, $
                    no_update=no_update, no_clobber=no_clobber, $
                    tplotnames=tns, varformat=varformat, $
                    valid_names=valid_names, files=files

; generic TDAS and BDAS application settings
  ; initialize TDAS TT2000 conversion routines
  cdf_leap_second_init
  !cdf_leap_seconds.preserve_tt2000=0

  ; initialize BARREL specific settings
  barrel_init
  vb = keyword_set(verbose) ? verbose : 0
  vb = vb > !barrel.verbose

  ; explicit calls should override global defaults
  local_bangbarrel = !barrel    ; make a local copy
  IF KEYWORD_SET(downloadonly) THEN str_element, local_bangbarrel, 'downloadonly', downloadonly, /ADD_REPLACE
  IF KEYWORD_SET(no_download) THEN str_element, local_bangbarrel, 'no_download', no_download, /ADD_REPLACE
  IF KEYWORD_SET(no_server) THEN str_element, local_bangbarrel, 'no_server', no_server, /ADD_REPLACE
  IF KEYWORD_SET(no_update) THEN str_element, local_bangbarrel, 'no_update', no_update, /ADD_REPLACE
  IF KEYWORD_SET(no_clobber) THEN str_element, local_bangbarrel, 'no_clobber', no_clobber, /ADD_REPLACE

; make sure we have the required elements
IF not keyword_set(vdatatypes) THEN BEGIN
    dprint,verbose=vb,dlevel=1,'BARREL_PRELOAD_ACTIONS: please specify VDATATYPES.'
    RETURN,-1
ENDIF
IF not keyword_set(vlevels) THEN BEGIN
    ;MESSAGE, 'BARREL_PRELOAD_ACTIONS: please specify VLEVELS.'
    dprint,verbose=vb,dlevel=1,'BARREL_PRELOAD_ACTIONS: please specify VLEVELS.'
    RETURN,-1
ENDIF

; a custom load for the BARREL payloads
if (keyword_set(probe)) then $
    p_var = probe

; payload identifiers take the form "CLL_PP_S", where:
;   C  = campaign number (0 for non-campaign, 1 for 2012/2013, 2 for 2013/2014)
;   LL = numerical launch order payload identifier (00 for non-campaign data)
;   PP = alphanumerical build order payload identifier (e.g. 1A, 1B)
;   S  = launch site (0 for non-campaign, 1 for SANAE, 2 for Halley, 3 for Kiruna)
; NOTE: these are the long-form identifiers.  As of v0.93 and CDF v02+, a 
;       short-form identifier (of type "PP") is instead used in file and 
;       variable naming conventions.  The long-form identifier is 
;       nevertheless retained here, and may be searched against as below.

; campaign 1 (2012-2013), definitive list
year1 = ['101_1J_1','102_1B_2','103_1D_2','104_1K_1',$
         '106_1M_1','107_1N_1','108_1O_1','109_1I_2','110_1G_2',$
         '111_1C_2','112_1H_2','113_1Q_1','114_1R_1','115_1S_1',$
         '116_1T_1','117_1U_1','118_1A_2','119_1V_1']
     ; note, no data available for payload 1L (launch 05, identifier 105_1L_1)
     ;  or payload 1W (launch 20, identifier 120_1W_1)

; campaign 2 (2013-2014), definitive list
year2 = ['201_2T_2','202_2I_2','203_2W_1',     '205_2K_2',$
         '206_2X_1','207_2L_2','208_2M_2','209_2Y_1',     $ 
         '211_2A_1','212_2B_1','213_2N_2','214_2C_1','215_2O_2',$
         '216_2D_1','217_2P_2','218_2E_1','219_2F_1','220_2Q_2']
     ; note, no data available for payload 2J (launch 04, identifier 204_2J_2)
     ;  or payload 2Z (launch 10, identifier 210_2Z_1)
year3 = ['301_3A_3','302_3B_3','303_3C_3','304_3D_3','305_3E_3','306_3F_3', '305_3G_3']
year4 = ['401_4A_3','402_4B_3','403_4C_3','404_4D_3','405_4E_3','406_4F_3','407_4G_3','408_4H_3']
; non-campaign, pre-launch, and testing data         
  ; build order identifiers
  year1_bo = '1'+string(bindgen(1,25)+(byte('A'))[0])
  year2_bo = '2'+string(bindgen(1,25)+(byte('A'))[0])
  bo_identifiers = ['000_'+['00',year1_bo]+'_0', '000_'+['00',year2_bo]+'_0']
        ; NOTE: here we specify "0" values to indicate non-campaign data
  testing = bo_identifiers


; all valid payload designators
vprobes = [year1, year2, year3, year4] ; provision for next year's campaign
;vprobes = [year1, year2, testing] ; provision for non-campaign CDF data


; data source selection
  ; by payload name
  if not keyword_set(p_var) then p_var='*'                              ; default assignment
  p_var = STRSPLIT(STRJOIN(TEMPORARY(p_var),' '), ' ', /EXTRACT)        ; split-strings
  if STRCMP(p_var[0],'all',/FOLD_CASE) then p_var='*'                   ; special case
  balloons = STRARR(N_ELEMENTS(p_var))
  FOR s=0, N_ELEMENTS(p_var)-1 DO BEGIN
    IF STRLEN(p_var[s]) EQ 2 THEN BEGIN
        ; probe designator is alphanumeric build order (e.g. 1A,1B,..,1Y)
        balloons[s] = '???_'+p_var[s]+'_?'      ; i.e., wildcarded launch order designator
    ENDIF ELSE IF STRLEN(p_var[s]) EQ 3 THEN BEGIN
        ; probe designator is sequential launch order (e.g. 101,102,..,120)
        balloons[s] = p_var[s]+'_??_?'          ; i.e., wildcarded launch order designator
    ENDIF ELSE IF STRLEN(p_var[s]) EQ 6 THEN BEGIN
        balloons[s] = p_var[s]+'_?'             ; i.e., wildcarded launch site designator
    ENDIF ELSE balloons[s] = p_var[s]           ; i.e., hopefully "*" or a "CLL_PP_S" string
  ENDFOR
  balloons = strfilter(vprobes, balloons, delimiter=' ',/string, /FOLD_CASE)

  ; by datatype (expect that VDATATYPES is scalar; always default to 0th element)
  if not keyword_set(datatype) then datatype=vdatatypes[0];'*'
  if STRCMP(datatype[0],'all',/FOLD_CASE) then datatype=vdatatypes[0];'*'
  datatype = strfilter(vdatatypes, datatype, delimiter=' ',/string, /FOLD_CASE)
  datatype = datatype[0]
  dprint,verbose=vb,dlevel=4, '*********************************'
  dprint,verbose=vb,dlevel=4, '*******', datatype, N_ELEMENTS(datatype)
  dprint,verbose=vb,dlevel=4, '*********************************'

  ; by data level allowed for datatype (always default to 0th element in VLEVELS)
  if not keyword_set(level) then level=vlevels[0]
  if STRCMP(level[0],'all',/FOLD_CASE) then level=vlevels[0] ;default: first element
  level = strfilter(vlevels, level, delimiter=' ', /string, /FOLD_CASE)
  level = level[0]

  ; by CDF data revision number 
  ; NOTE: calls via "barrel_load_data" will default to VERSION assignment of 
  ;     known-working "file_version".  Only zeroth element of string array is
  ;     considered.  Fallback to wildcarded searches.
  IF KEYWORD_SET(version) THEN BEGIN
        ; sanitize input (allowed to modified "version")
        IF STRCMP(version[0],'all',/FOLD_CASE) THEN version='v[0-9][0-9]' ; catch unusual usage..
        IF (N_ELEMENTS(version) NE 1) THEN version=version[0]             ; make scalar 

        ; treatment of "version" (original now untouched)
        allowed_versions = ['v??',('v'+STRING(INDGEN(100),FORMAT='(I02)')),('.v'+STRING(INDGEN(100),FORMAT='(I02)'))]
        matched_versions = strfilter(allowed_versions, version, /string, /FOLD_CASE, COUNT=n_matches)

        IF (n_matches EQ 0) THEN BEGIN  ;(default to broad search)
            dprint,verbose=vb,dlevel=1,'BARREL_PRELOAD_ACTIONS: Specified VERSION not valid-- defaulting to /LAST_VERSION'
            this_version = 'v[0-9][0-9]'     ; wildcard for anything
            last_version = 1            ; find the highest version number
        ENDIF ELSE IF (n_matches EQ 1) THEN BEGIN 
            this_version = matched_versions  ;(the expected usage case)   
            last_version = 0            ; no need to seek a different version..
        ENDIF ELSE $ ;(n_matches GT 1) == TRUE, so we have a working wildcard!
            this_version = version
            last_version = 1            ; keep the wildcard, but find the highest version
  ENDIF ELSE BEGIN                      ;(default to broad search)
        this_version = 'v[0-9][0-9]'         ;(anything matching this pattern)
        last_version = 1                ;(find the highest version number)
  ENDELSE
  ; treat the special case of hidden directories..
  IF STRCMP(this_version,'.hidden_directory',1) THEN BEGIN
     ; developmental builds + any other non-public versions (e.g., unreleased data)
     vfolder = this_version                  ;(version is taken to indicate folder) 
     this_version = STRMID(version,1)        ; (strip initial "." character for CDF filename)
  ENDIF ELSE vfolder = this_version

addmaster=0
new_tpvars = ''         ; storage container for return product

; generic load of CDF files
valid = WHERE(balloons, n_balloons)
for s=0, n_balloons-1 do begin

    ; retrieve existing files
    balloonx = balloons[s]
    prefix = vfolder[0] + '/' + level[0] + '/' + STRMID(balloonx,4,2)
    datestyle1 = 'yyMMDD'       ; used in the file path
    datestyle2 = 'YYYYMMDD'     ; used in the file name
    filepath_date = file_dailynames(file_format=datestyle1, trange=trange, addmaster=addmaster)
    filename_date = file_dailynames(file_format=datestyle2, trange=trange, addmaster=addmaster)
    relpathnames = prefix+'/'+filepath_date+'/'+ $
        'bar_'+STRMID(balloonx,4,2)+'_'+level[0]+'_'+datatype[0]+'_'+filename_date+'_' + this_version[0] + '.cdf'    ;v??.cdf'

    files = file_retrieve(relpathnames, _extra=local_bangbarrel, last_version=last_version)
    dprint,verbose=vb,dlevel=4, files

    ; extract payload identifier from filename
    basenames = FILE_BASENAME(files)
    sort_order = SORT(basenames)
    uniq_order = UNIQ(basenames[sort_order])
    reduced_set = basenames[sort_order[uniq_order]]
    set_identifier = WHERE(~STRMATCH(reduced_set, '*[\*\?\[\]\\]*'), n_unique)
    dprint,verbose=vb,dlevel=4, 'BASE IDENTIFIERS: ', n_unique
    IF n_unique GT 0 THEN identifier = STRMID(reduced_set[set_identifier[0]], 4, 2) $
        ELSE identifier = 'CLL_PP'      ; failure

    suf=''
    pre='brl'+identifier+'_'
    IF ~KEYWORD_SET(downloadonly) THEN cdf2tplot, file=files, varformat=varformat,$ 
        all=0, prefix=pre, suffix=suf,$
        verbose=vb, tplotnames=tns, /convert_int1_to_int2, $
        get_support_data=get_support_data

    if is_string(tns) then begin
        dprint,verbose=vb,dlevel=3, tns
        new_tpvars = [new_tpvars, tns]
    endif
endfor

not_empty = WHERE(new_tpvars, n_newvars)

IF (n_newvars GT 0) THEN $
    RETURN, {level:level, tplot_variables:new_tpvars} $
    ELSE RETURN, {level:level, tplot_variables:''}

END
