;+
;
;PROCEDURE:       ESC_EPH_LOAD
;
;PURPOSE:         Loads the ESCAPADE ancillary ephemeris CDF file(s).
;
;INPUTS:          Time range to be loaded.
;
;KEYWORDS:
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
; PRELAUNCH:      If set, the prelaunch data will be loaded.
;
;COMMISSION:      If set, the commissioning data will be loaded.
;
;    FRAMES:      Specifies which frames (i.e., coordinate systems) will be loaded.
;                 Default is to load all frames.
;
;        RE:      If set, the output data is normalized by Earth radii.
;
;        RM:      If set, the output data is normalized by Mars radii.
;
;CREATED BY:      Takuya Hara on 2026-02-05.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2026-02-27 17:42:42 -0800 (Fri, 27 Feb 2026) $
; $LastChangedRevision: 34209 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/spice/esc_eph_load.pro $
;
;-
PRO esc_eph_load, itime, verbose=verbose, no_server=no_server, blue=blue, gold=gold, files=afile, source=source, $
                  prelaunch=prelaunch, commissioning=commissioning, frames=frames, re=re, rm=rm

  r_m = 3389.9d0                ; Mars radii [km]
  r_e = !const.r_earth * 1.d-3  ; Earth radii [km]
  r_p = 1.d0
  
  IF undefined(itime) THEN get_timespan, trange ELSE trange = itime
  IF is_string(trange) THEN trange = time_double(trange)

  IF KEYWORD_SET(blue) THEN append_array, probes, 'blue'
  IF KEYWORD_SET(gold) THEN append_array, probes, 'gold'
  IF undefined(probes) THEN probes = ['blue', 'gold']
  IF N_ELEMENTS(probes) EQ 2 THEN both = 1 ELSE both = 0

  IF KEYWORD_SET(rm) THEN BEGIN
     r_p = r_m
     yunit = '[R!DM!N]'
  ENDIF 
  IF KEYWORD_SET(re) THEN BEGIN
     r_p = r_e
     yunit = '[R!DE!N]'
  ENDIF
  
  IF undefined(source) THEN src = esc_file_source(verbose=verbose) ELSE src = source
  fname = 'YYYY/MM/esc-p_anc-eph_YYYY-MM-DD_*.cdf'
  
  phases = ['prelaunch', 'commissioning', 'science']
  IF KEYWORD_SET(prelaunch) THEN ip = 0
  IF KEYWORD_SET(commissioning) THEN ip = 1
  IF undefined(ip) THEN ip = -1 ; science

  rpath = phases[ip] + '/probe/ancillary/ephemeris/'
  FOR i=0, N_ELEMENTS(probes)-1 DO BEGIN
     prefix = fname.replace('esc-p', 'esc-' + (probes[i]).substring(0, 0))
     path = rpath.replace('probe', probes[i])

     undefine, files
     files = esc_file_retrieve(prefix, remote_data_dir=path, trange=trange, /daily, /last_version, /valid_only, no_server=no_server, verbose=verbose, source=src)

     w = WHERE(files NE '', nw)
     IF nw EQ 0 THEN BEGIN
        dprint, dlevel=2, verbose=verobse, 'No file(s) found.'
        CONTINUE
     ENDIF 
     append_array, afile, files[w]

     IF ~undefined(frames) THEN varformat = 'esc_' + STRJOIN((probes[i]).substring(0, 0) + '_eph_' + frames.tolower(), ' ')

     cdf2tplot, files[w], tplotnames=tname, varformat=TEMPORARY(varformat)
     IF ~undefined(tname) THEN BEGIN
        yes = WHERE(STRMATCH(tname, '*qrot*') EQ 1, n_yes, complement=no, ncomplement=n_no)
        IF n_yes GT 0 THEN BEGIN
           ; After MOI
           stop
        ENDIF 
        IF n_no GT 0 THEN BEGIN
           options, tname, /def, labels=['X', 'Y', 'Z'], labflag=-1, constant=0., colors='bgr'
           FOR j=0, N_ELEMENTS(tname)-1 DO BEGIN
              get_data, tname[j], data=data, dl=dl
              options, tname[j], ytitle='ESC-' + ((probes[i]).toupper()).substring(0, 0), ysubtitle=dl.cdf.vatt.lablaxis + ' ' + dl.ysubtitle, /def
              IF r_p NE 1. THEN BEGIN
                 store_data, tname[j], data={x: data.x, y: data.y/r_p}
                 options, tname[j], ysubtitle=dl.cdf.vatt.lablaxis + ' ' + yunit, /def
              ENDIF 
           ENDFOR 
        ENDIF 
     ENDIF

     undefine, tname, yes, no, n_yes, n_no
  ENDFOR

  RETURN
END 
