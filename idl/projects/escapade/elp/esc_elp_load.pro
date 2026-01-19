;+
;
;PROCEDURE:       ESC_ELP_LOAD
;
;PURPOSE:         Loads the ESCAPADE ELP CDF file(s).
;
;INPUTS:          Time range to be loaded.
;
;KEYWORDS:
;
;     LEVEL:      Specifies the data level. Default is L1.
;
; NO_SERVER:      If set, prevents any contact with a remote server.
;
;      BLUE:      If set, loads only BLUE spacecraft data.
;
;      GOLD:      If set, loads only GOLD spacecraft data.
;
;        HK:      If set, loads also housekeeping data.
;
;     FILES:      If set, returns the file name(s) to be loaded.
;
;    SOURCE:      Specifies the file source information. Default is esc_file_source().
;
; PRELAUNCH:      If set, the prelaunch data will be loaded.
;
;COMMISSION:      If set, the commissioning data will be loaded.
;
;CREATED BY:      Takuya Hara on 2026-01-11.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2026-01-16 13:57:12 -0800 (Fri, 16 Jan 2026) $
; $LastChangedRevision: 34033 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/elp/esc_elp_load.pro $
;
;-
PRO esc_elp_load, itime, verbose=verbose, level=level, no_server=no_server, blue=blue, gold=gold, hk=hk, $
                  source=source, files=files, prelaunch=prelaunch, commissioning=commissioning
  IF undefined(itime) THEN get_timespan, trange ELSE trange = itime
  IF is_string(trange) THEN trange = time_double(trange)

  IF KEYWORD_SET(blue) THEN append_array, probes, 'blue'
  IF KEYWORD_SET(gold) THEN append_array, probes, 'gold'
  IF undefined(probes) THEN probes = ['blue', 'gold']
  IF N_ELEMENTS(probes) EQ 2 THEN both = 1 ELSE both = 0

  IF undefined(source) THEN src = esc_file_source() ELSE src = source
  IF undefined(level) THEN lvl = 'l1' ELSE lvl = level.tolower()
  fname = 'YYYY/MM/esc-p_elp_lvl_data_YYYY-MM-DD_*.cdf'

  phases = ['prelaunch', 'commissioning', 'science']
  IF KEYWORD_SET(prelaunch) THEN ip = 0
  IF KEYWORD_SET(commissioning) THEN ip = 1
  IF undefined(ip) THEN ip = -1 ; science

  rpath = phases[ip] + '/probe/elp/'
  FOR i=0, N_ELEMENTS(probes)-1 DO BEGIN
     prefix = fname.replace('esc-p', 'esc-' + (probes[i]).substring(0, 0))
     prefix = prefix.replace('lvl', lvl)
     path = rpath.replace('probe', probes[i]) + lvl + '/'

     IF KEYWORD_SET(hk) THEN append_array, prefix, prefix.replace('data', 'housekeeping')
     FOR j=0, N_ELEMENTS(prefix)-1 DO BEGIN
        afile =  esc_file_retrieve(prefix[j], remote_data_dir=path, trange=trange, /daily, /last_version, /valid_only, no_server=no_server, verbose=verbose, source=src)

        w = WHERE(afile NE '', nw)
        IF nw EQ 0 THEN BEGIN
           dprint, dlevel=2, verbose=verbose, 'No file(s) found.'
           CONTINUE
        ENDIF
        afile = afile[w]

        cdf2tplot, afile, prefix='esc'
        append_array, files, TEMPORARY(afile)
     ENDFOR
  ENDFOR  
  
  RETURN
END 
