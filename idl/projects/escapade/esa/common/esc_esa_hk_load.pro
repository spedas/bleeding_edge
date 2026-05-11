;+
;
;PROCEDURE:       ESC_ESA_HK_LOAD
;
;PURPOSE:         Loads the ESCAPADE EESA Housekeeping CDF file(s).
;
;INPUTS:          Time range to be loaded.
;
;KEYWORDS:
;
;   PRODUCT:      Specifies the science products abbreviation(s) to be loaded. 
;
;      DATA:      If set, returns the output data as a structure.
;
;     IPATH:      Explicitly specifies the input path for loading the CDF file(s) (e.g., for testing purposes).
;
;     LEVEL:      Specifies the data level. Default is L1.
;
; NO_SERVER:      If set, prevents any contact with a remote server.
;
;      BLUE:      If set, loads only BLUE spacecraft data.
;
;      GOLD:      If set, loads only GOLD spacecraft data.
;
;     FILES:      If set, returns the file name(s) to be loaded.
;
;    SOURCE:      Specifies the file source information. Default is esc_file_source().
;
; PRELAUNCH:      If set explicitly, the data will be loaded from the prelaunch directory.
;
;COMMISSION:      If set explicitly, the data will be loaded from the commissioning directory.
;
;   SCIENCE:      If set explicitly, the data will be loaded from the science directory.
;
;     CLEAR:      If set, clears the EESA housekeeping common blocks.
;
;     TPLOT:      If set, creates tplot variables.
;
;  VARNAMES:      If set, specifies the variable name(s) to be created tplot variable(s).
;
;CREATED BY:      Takuya Hara on 2026-05-06.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2026-05-07 13:34:55 -0700 (Thu, 07 May 2026) $
; $LastChangedRevision: 34444 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/common/esc_esa_hk_load.pro $
;
;-
PRO esc_esa_hk_load, itime, product=product, data=data, verbose=verbose, level=level, blue=blue, gold=gold, files=afile, clear=clear,    $
                     ipath=ipath, source=source, no_server=no_server, prelaunch=prelaunch, commissioning=commissioning, science=science, $
                     tplot=tplot, varnames=varnames
  
  COMMON esc_esa_ahk_com, escb_esa_ahk, escg_esa_ahk ; Analog Housekeeping
  COMMON esc_esa_dhk_com, escb_esa_dhk, escg_esa_dhk ; Digital Housekeeping

  IF KEYWORD_SET(clear) THEN undefine, escb_esa_ahk, escg_esa_ahk, escb_esa_dhk, escg_esa_dhk
  
  IF undefined(itime) THEN get_timespan, trange ELSE trange = itime
  IF is_string(trange) THEN trange = time_double(trange)

  IF KEYWORD_SET(blue) THEN append_array, probes, 'blue'
  IF KEYWORD_SET(gold) THEN append_array, probes, 'gold'
  IF undefined(probes) THEN probes = ['blue', 'gold']
  IF N_ELEMENTS(probes) EQ 2 THEN both = 1 ELSE both = 0
  
  IF undefined(source) THEN src = esc_file_source() ELSE src = source
  IF undefined(level) THEN lvl = 'l1' ELSE lvl = level.tolower()

  yyyymm = 'YYYY/MM/'
  fname  = 'esc-p_eesa_lvl_*prod*_YYYY-MM-DD_*.cdf'

  phases = ['prelaunch', 'commissioning', 'science']
  IF KEYWORD_SET(prelaunch) THEN ip = 0
  IF KEYWORD_SET(commissioning) THEN ip = 1
  IF KEYWORD_SET(science) THEN ip = 2

  rpath = 'phase/probe/eesa/'
  IF ~undefined(ip) THEN rpath = rpath.replace('phase', phases[ip])
  IF undefined(product) THEN prod = ['ahk', 'dhk'] ELSE prod = product
  IF ~undefined(ipath) THEN yyyymm = ''
  
  FOR i=0, N_ELEMENTS(probes)-1 DO FOR j=0, N_ELEMENTS(prod)-1 DO BEGIN
     prefix = fname.replace('esc-p', 'esc-' + (probes[i]).substring(0, 0))
     prefix = yyyymm + prefix.replace('lvl', lvl)

     ;pname = ['analog-hk', 'digital-hk']
     undefine, pname
     CASE (prod[j]).toupper() OF
        'AHK': pname = 'analog-hk'
        'DHK': pname = 'digital-hk'
        ELSE : dprint, dlevel=2, verbose=verbose, 'No EESA housekeeping products matched.'
     ENDCASE
     IF undefined(pname) THEN CONTINUE
     
     prefix = prefix.replace('prod', pname)
     path = rpath.replace('probe', probes[i]) + lvl + '/'

     IF undefined(ip) THEN BEGIN
        date = time_intervals(trange=trange, /daily)
        path = REPLICATE(path, N_ELEMENTS(date))
        path = path.replace('phase', esc_mission_phase(TEMPORARY(date)))
     ENDIF 
     
     undefine, files
     IF undefined(ipath) THEN $
        files = esc_file_retrieve(prefix, remote_data_dir=path, trange=trange, /daily, /last_version, /valid_only, no_server=no_server, verbose=verbose, source=src) $
     ELSE files = file_retrieve(prefix, local_data_dir=ipath, trange=trange, /daily, /last_version, /valid_only, /no_server)
     
     w = WHERE(files NE '', nw)
     IF nw EQ 0 THEN BEGIN
        dprint, dlevel=2, verbose=verobse, 'No file(s) found.'
        CONTINUE
     ENDIF 
     append_array, afile, files[w]

     cdfi = cdf_load_vars(files[w], /all, varname=vname, verbose=verbose)

     prefix = (probes[i]).substring(0, 0) + '_eesa_'
     vname = cdfi.vars.name
     tags  = vname.replace(prefix, '')
     
     ndat  = N_ELEMENTS(*cdfi.vars[0].dataptr)
     DEFSYSV, '!CDF_LEAP_SECONDS', exists=exists
     IF NOT KEYWORD_SET(exists) THEN BEGIN
        cdf_leap_second_init
        DEFSYSV, '!CDF_LEAP_SECONDS', exists=exists
        IF NOT KEYWORD_SET(exists) THEN BEGIN
           dprint, dlevel=2, 'Error: !CDF_LEAP_SECONDS, must be defined to convert CDFs with TT2000 times.'
           RETURN
        ENDIF
     ENDIF
     
     undefine, data
     str_element, data, 'time', time_double(*(cdfi.vars[0].dataptr), /tt2000), /add
     
     FOR k=1L, cdfi.nv-1 DO $
        IF (*(cdfi.vars[k].attrptr)).var_type EQ 'data' THEN str_element, data, tags[k], *cdfi.vars[k].dataptr, /add

     CASE (prod[j]).toupper() OF
        'AHK': IF probes[i] EQ 'blue' THEN escb_esa_ahk = data ELSE escg_esa_ahk = data
        'DHK': IF probes[i] EQ 'blue' THEN escb_esa_dhk = data ELSE escg_esa_dhk = data
        ELSE : dprint, dlevel=2, verbose=verbose, 'No EESA housekeeping products matched.'
     ENDCASE
     
     IF KEYWORD_SET(tplot) THEN BEGIN
        IF ~undefined(varnames) THEN vnames = strfilter(vname, varnames) ELSE vnames = vname
        cdf_info_to_tplot, cdfi, vnames, prefix='esc', verbose=verbose
        undefine, vnames
     ENDIF 
     undefine, cdfi, vname
  ENDFOR

  RETURN
END 
