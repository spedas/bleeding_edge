;+
;NAME: barrel_load_data
;DESCRIPTION: master CDF-to-TDAS import routine for BARREL data products
;
;REQUIRED INPUTS:
; none
;
;KEYWORD ARGUMENTS (OPTIONAL):
; PROBE:        String [array] of BARREL launch order designators (e.g. '101').
;                 Default is 'all' (i.e., all available payloads).  May also be
;                 a single string delimited by spaces (e.g., '101 102').
;               If string contains two character alphanumeric identifiers 
;                 (e.g., '1A 1B'), then PROBE is assumed to specify a build order 
;                 designator instead.
; DATATYPE:     String [array] of BARREL datatype identifiers (e.g. 'MAGN',
;                 'FSPC','MSPC','SSPC','HKPG','GPS','PPS','RCNT').
; TRANGE:       Time range for tplot (2 element array).  Loads data in whole-day
;                 chunks, and will prompt user if not specified.
; LEVEL:        String [array] of data level code (e.g. 'l1', 'l2').
; VERSION:      String specifying data revision number (e.g. 'v01', 'v02').
; /VERBOSE:       
; CDF_DATA:     (not implemented)
; /GET_SUPPORT_DATA: Load support_data variables as well as data variables.
; TPLOTNAMES:   if specified, a named variable into which a list of TPLOT 
;                 variable names is written immediately after import.
; MAKE_MULTI_TPLOTVAR: (not implemented)
; VARFORMAT:    String (passed through to 'cdf2tplot').
; /VALID_NAMES: (not implemented) 
; FILES:        if specified, a named variable into which a list of source 
;                 filenames is written.
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
;Version 0.96c JMM 07/01/2016, defaults to v05
;Version 0.96b JGS 07/02/2015 RC1, defaults to v04 dataset
;Version 0.96a KBY 07/07/2014 RC1, defaults to v03 dataset
;Version 0.95b KBY 12/29/2013 default to v02 dataset
;Version 0.93e KBY 08/16/2013 rename "barrel_load_gps.pro" to "barrel_load_ephm.pro";
;               DROP SUPPORT/COMPATIBILITY FOR v01 CDFs
;Version 0.93a KBY 08/16/2013 deprecate "PPS-" datatype in favor of "MISC"
;Version 0.92c KBY 06/05/2013 string-split input of LEVEL; make VERSION scalar string
;Version 0.92a KBY 06/04/2013 introduced VERSION keyword
;Version 0.91a KBY 05/28/2013 updated to reflect namechange from 'gps' to 'ephm'; 
;               added file_retrieve keywords (no_download/update/clobber)
;Version 0.90a KBY 04/19/2013 updated for pending release of revised CDFs
;Version 0.83 KBY 11/28/2012 initial beta release
;Version 0.81 KBY 11/21/2012 new CDF definitions; updated treatment of PROBE keyword.
;Version 0.8 KBY 10/29/2012 from 'rbsp_load_efw_spec.pro' (Peter Schroeder),
;               and 'thm_load_goesmag.pro'
;
;-

pro barrel_load_data, probe=probe, datatype=datatype, trange=trange, $
                    level=level, version=version, verbose=verbose, $
                    downloadonly=downloadonly, $
                    no_download=no_download, no_server=no_server, $
                    no_update=no_update, no_clobber=no_clobber, $
                    cdf_data=cdf_data, get_support_data=get_support_data, $
                    tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
                    varformat=varformat, valid_names=valid_names, files=files, $
                    CONVERT_L1_TO_PHYSICAL_UNITS=do_convert_L1

dprint, verbose=verbose, dlevel=4, 'BARREL data analysis software v0.96b' ; bdas_version

file_version = 'v05'    ; default argument to VERSION (public release), jmm 2016-07-01
vlevels = ['l2','l1']   ; master level: accepts multiple inputs
vdatatypes = ['FSPC','EPHM','HKPG','MAGN','MSPC','MISC','RCNT','SSPC']   
                        ; master level: accepts multiple inputs 

; define aliases (match first four characters)
fspc_aliases = ['FAST', 'FSPEC', 'SPECTRUM', 'ALL']
gps_aliases = ['EPHEMERIS', 'GPS', 'GPS-', 'LOCATION', 'ALL']
hkpg_aliases = ['HSK', 'ALL']
magn_aliases = ['MAG', 'FGM', 'ALL']

mspc_aliases = ['MEDIUM', 'MSPEC', 'SPECTRUM', 'ALL']
misc_aliases = ['PPS', 'PPS-', 'ALL']   ; (v01 label is 'PPS-'; requires manual load)
rcnt_aliases = ['COUNTERS', 'ALL']
sspc_aliases = ['SLOW', 'SSPEC', 'SPECTRUM', 'ALL']


if not keyword_set(datatype) then datatype='*'
datatype = STRSPLIT(STRJOIN(TEMPORARY(datatype),' '), ' ', /EXTRACT)
print, 'REQUESTED DATATYPES: ', datatype

; search DATATYPE aliases
fspc_request = strfilter(fspc_aliases, datatype, /FOLD_CASE, COUNT=n_fspc)
gps_request = strfilter(gps_aliases, datatype, /FOLD_CASE, COUNT=n_gps)
hkpg_request = strfilter(hkpg_aliases, datatype, /FOLD_CASE, COUNT=n_hkpg)
magn_request = strfilter(magn_aliases, datatype, /FOLD_CASE, COUNT=n_magn)

mspc_request = strfilter(mspc_aliases, datatype, /FOLD_CASE, COUNT=n_mspc)
misc_request = strfilter(misc_aliases, datatype, /FOLD_CASE, COUNT=n_misc)
rcnt_request = strfilter(rcnt_aliases, datatype, /FOLD_CASE, COUNT=n_rcnt)
sspc_request = strfilter(sspc_aliases, datatype, /FOLD_CASE, COUNT=n_sspc)

;DIAGNOSTIC: print, [n_fspc, n_gps, n_hkpg, n_magn, n_mspc, n_misc, n_rcnt, n_sspc]
vdatatype_key = WHERE([n_fspc, n_gps, n_hkpg, n_magn, n_mspc, n_misc, n_rcnt, n_sspc], n_aliased)

not_aliased = strfilter(vdatatypes, datatype, delimiter=' ',/string, /FOLD_CASE)
print, '  NOT ALIASED: ', not_aliased
IF (n_aliased GT 0) THEN BEGIN
    are_aliased = vdatatypes[vdatatype_key]
    print, '  ARE ALIASED: ', are_aliased
    datatype = [not_aliased, are_aliased]
    sorted_dtypes = datatype[SORT(datatype)]
    datatype = sorted_dtypes[UNIQ(sorted_dtypes)]
ENDIF ELSE datatype = not_aliased
print, 'Requesting... ', datatype


; parse LEVEL keyword
if not keyword_set(level) then level='*'
level = STRSPLIT(STRJOIN(TEMPORARY(level),' '), ' ', /EXTRACT)
if STRCMP(level[0],'all',/FOLD_CASE) then level='*'
                        ; master level: accepts multiple inputs
level = strfilter(vlevels, level, delimiter=' ', /string, /FOLD_CASE)

; parse VERSION keyword
if not keyword_set(version) then version=file_version
version = STRSPLIT(STRJOIN(TEMPORARY(version),' '), ' ', /EXTRACT)
version = version[0]

addmaster=0

; call FILETYPE specific routines from here, if requested
IF TOTAL(strfilter(datatype,'FSPC', /BYTE), /INTEGER) THEN $
    barrel_load_fspc, PROBE=probe, DATATYPE='FSPC', LEVEL=level, $
      VERSION=version, TRANGE=trange, VERBOSE=verbose, $
                    DOWNLOADONLY=downloadonly,$
                    no_download=no_download, no_server=no_server, $
                    no_update=no_update, no_clobber=no_clobber, $
      TPLOTNAMES=tns, MAKE_MULTI_TPLOTVAR=make_multi_tplotvar, $
      CDF_DATA=cdf_data, GET_SUPPORT_DATA=get_support_data, $
      VARFORMAT=varformat, VALID_NAMES=valid_names, FILES=file_src, $
      CONVERT_L1_TO_PHYSICAL_UNITS=do_convert_L1

IF TOTAL(strfilter(datatype,'EPHM', /BYTE), /INTEGER) THEN $
    barrel_load_ephm, PROBE=probe, DATATYPE='EPHM', LEVEL=level, $
      VERSION=version, TRANGE=trange, VERBOSE=verbose, $
                    DOWNLOADONLY=downloadonly,$
                    no_download=no_download, no_server=no_server, $
                    no_update=no_update, no_clobber=no_clobber, $
      TPLOTNAMES=tns, MAKE_MULTI_TPLOTVAR=make_multi_tplotvar, $
      CDF_DATA=cdf_data, GET_SUPPORT_DATA=get_support_data, $
      VARFORMAT=varformat, VALID_NAMES=valid_names, FILES=file_src, $
      CONVERT_L1_TO_PHYSICAL_UNITS=do_convert_L1

IF TOTAL(strfilter(datatype,'HKPG', /BYTE), /INTEGER) THEN $
    barrel_load_hkpg, PROBE=probe, DATATYPE='HKPG', LEVEL=level, $
     VERSION=version, TRANGE=trange, VERBOSE=verbose, $
     DOWNLOADONLY=downloadonly,$
                    no_download=no_download, no_server=no_server, $
                    no_update=no_update, no_clobber=no_clobber, $
     TPLOTNAMES=tns, MAKE_MULTI_TPLOTVAR=make_multi_tplotvar, $
     CDF_DATA=cdf_data, GET_SUPPORT_DATA=get_support_data, $
     VARFORMAT=varformat, VALID_NAMES=valid_names, FILES=file_src, $
      CONVERT_L1_TO_PHYSICAL_UNITS=do_convert_L1

IF TOTAL(strfilter(datatype,'MAGN', /BYTE), /INTEGER) THEN $
    barrel_load_magn, PROBE=probe, DATATYPE='MAGN', LEVEL=level, $
      VERSION=version, TRANGE=trange, VERBOSE=verbose, $
      DOWNLOADONLY=downloadonly,$
                    no_download=no_download, no_server=no_server, $
                    no_update=no_update, no_clobber=no_clobber, $
      TPLOTNAMES=tns, MAKE_MULTI_TPLOTVAR=make_multi_tplotvar, $
      CDF_DATA=cdf_data, GET_SUPPORT_DATA=get_support_data, $
      VARFORMAT=varformat, VALID_NAMES=valid_names, FILES=file_src, $
      CONVERT_L1_TO_PHYSICAL_UNITS=do_convert_L1

IF TOTAL(strfilter(datatype,'MSPC', /BYTE), /INTEGER) THEN $
    barrel_load_mspc, PROBE=probe, DATATYPE='MSPC', LEVEL=level, $
      VERSION=version, TRANGE=trange, VERBOSE=verbose, $
      DOWNLOADONLY=downloadonly,$
                    no_download=no_download, no_server=no_server, $
                    no_update=no_update, no_clobber=no_clobber, $
      TPLOTNAMES=tns, MAKE_MULTI_TPLOTVAR=make_multi_tplotvar, $
      CDF_DATA=cdf_data, GET_SUPPORT_DATA=get_support_data, $
      VARFORMAT=varformat, VALID_NAMES=valid_names, FILES=file_src, $
      CONVERT_L1_TO_PHYSICAL_UNITS=do_convert_L1

IF TOTAL(strfilter(datatype,'MISC', /BYTE), /INTEGER) THEN $
    barrel_load_misc, PROBE=probe, DATATYPE='MISC', LEVEL=level, $
     VERSION=version, TRANGE=trange, VERBOSE=verbose, $
     DOWNLOADONLY=downloadonly,$
                    no_download=no_download, no_server=no_server, $
                    no_update=no_update, no_clobber=no_clobber, $
     TPLOTNAMES=tns, MAKE_MULTI_TPLOTVAR=make_multi_tplotvar, $
     CDF_DATA=cdf_data, GET_SUPPORT_DATA=get_support_data, $
     VARFORMAT=varformat, VALID_NAMES=valid_names, FILES=file_src, $
      CONVERT_L1_TO_PHYSICAL_UNITS=do_convert_L1

IF TOTAL(strfilter(datatype,'RCNT', /BYTE), /INTEGER) THEN $
    barrel_load_rcnt, PROBE=probe, DATATYPE='RCNT', LEVEL=level, $
     VERSION=version, TRANGE=trange, VERBOSE=verbose, $
     DOWNLOADONLY=downloadonly,$
                    no_download=no_download, no_server=no_server, $
                    no_update=no_update, no_clobber=no_clobber, $
     TPLOTNAMES=tns, MAKE_MULTI_TPLOTVAR=make_multi_tplotvar, $
     CDF_DATA=cdf_data, GET_SUPPORT_DATA=get_support_data, $
     VARFORMAT=varformat, VALID_NAMES=valid_names, FILES=file_src, $
      CONVERT_L1_TO_PHYSICAL_UNITS=do_convert_L1

IF TOTAL(strfilter(datatype,'SSPC', /BYTE), /INTEGER) THEN $
    barrel_load_sspc, PROBE=probe, DATATYPE='SSPC', LEVEL=level, $
      VERSION=version, TRANGE=trange, VERBOSE=verbose, $
      DOWNLOADONLY=downloadonly,$
                    no_download=no_download, no_server=no_server, $
                    no_update=no_update, no_clobber=no_clobber, $
      TPLOTNAMES=tns, MAKE_MULTI_TPLOTVAR=make_multi_tplotvar, $
      CDF_DATA=cdf_data, GET_SUPPORT_DATA=get_support_data, $
      VARFORMAT=varformat, VALID_NAMES=valid_names, FILES=file_src, $
      CONVERT_L1_TO_PHYSICAL_UNITS=do_convert_L1
print, "Data accessed is version: ", version, " Current default version is: ", file_version
END
