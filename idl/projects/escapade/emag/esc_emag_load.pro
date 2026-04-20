;+
;
;PROCEDURE:       ESC_EMAG_LOAD
;
;PURPOSE:         Loads the ESCAPADE EMAG CDF file(s).
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
;     FILES:      If set, returns the file name(s) to be loaded.
;
;    SOURCE:      Specifies the file source information. Default is esc_file_source().
;
; PRELAUNCH:      If set explicitly, the data will be loaded from the prelaunch directory.
;
;COMMISSION:      If set explicitly, the date will be loaded from the commissioning directory.
;
;   SCIENCE:      If set explicitly, the date will be loaded from the science directory.
;
;    FRAMES:      Specifies which frames (i.e., coordinate systems) will be loaded.
;                 Default is to load all frames.
;
;     TNAME:      If set, returns tplot variables to be created.
;
;     IPATH:      Explicitly specifies the input path for loading the CDF file(s) (e.g., for testing purposes).
;
;        HK:      If set, loads the EMAG housekeeping CDF file(s).
;
;CREATED BY:      Takuya Hara on 2026-01-09.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2026-04-18 17:09:18 -0700 (Sat, 18 Apr 2026) $
; $LastChangedRevision: 34381 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/emag/esc_emag_load.pro $
;
;-
PRO esc_emag_load, itime, verbose=verbose, level=level, no_server=no_server, blue=blue, gold=gold, files=afile, source=source, $
                   prelaunch=prelaunch, commissioning=commissioning, science=science, frames=frames, tname=rname, ipath=ipath, hk=hk

  IF undefined(itime) THEN get_timespan, trange ELSE trange = itime
  IF is_string(trange) THEN trange = time_double(trange)

  IF KEYWORD_SET(blue) THEN append_array, probes, 'blue'
  IF KEYWORD_SET(gold) THEN append_array, probes, 'gold'
  IF undefined(probes) THEN probes = ['blue', 'gold']
  IF N_ELEMENTS(probes) EQ 2 THEN both = 1 ELSE both = 0
  
  IF undefined(source) THEN src = esc_file_source() ELSE src = source
  IF undefined(level) THEN lvl = 'l1' ELSE lvl = level.tolower()
  fname = 'esc-p_emag_lvl_prodYYYY-MM-DD_*.cdf'
  yymm  = 'YYYY/MM/'
  
  phases = ['prelaunch', 'commissioning', 'science']
  IF KEYWORD_SET(prelaunch) THEN ip = 0
  IF KEYWORD_SET(commissioning) THEN ip = 1
  IF KEYWORD_SET(science) THEN ip =2
  rpath = 'phase/probe/emag/'
  ;IF undefined(ip) THEN ip = -1 ; science

  ;rpath = phases[ip] + '/probe/emag/'

  IF ~undefined(ip) THEN rpath = rpath.replace('phase', phases[ip])
  prod  = ['']
  IF KEYWORD_SET(hk) THEN append_array, prod, 'housekeeping_'

  FOR i=0, N_ELEMENTS(probes)-1 DO FOR pp=0, N_ELEMENTS(prod)-1 DO BEGIN
     prefix = fname.replace('esc-p', 'esc-' + (probes[i]).substring(0, 0))
     prefix = prefix.replace('lvl', lvl)
     prefix = prefix.replace('prod', prod[pp])
     path = rpath.replace('probe', probes[i]) + lvl + '/'

     IF undefined(ip) THEN BEGIN
        date = time_intervals(trange=trange, /daily)
        path = REPLICATE(path, N_ELEMENTS(date))
        path = path.replace('phase', esc_mission_phase(TEMPORARY(date)))
     ENDIF 
     
     undefine, files
     
     IF undefined(ipath) THEN $
        files = esc_file_retrieve(yymm + prefix, remote_data_dir=path, trange=trange, /daily, /last_version, /valid_only, no_server=no_server, verbose=verbose, source=src) $
     ELSE BEGIN
        yymm  = ''
        files = file_retrieve(yymm + prefix, local_data_dir=ipath, trange=trange, /daily, /last_version, /valid_only, /no_server)
     ENDELSE
     
     w = WHERE(files NE '', nw)
     IF nw EQ 0 THEN BEGIN
        dprint, dlevel=2, verbose=verobse, 'No file(s) found.'
        CONTINUE
     ENDIF 
     append_array, afile, files[w]

     CASE pp OF ; products
        0: BEGIN ; science
           IF ~undefined(frames) THEN varformat = STRJOIN((probes[i]).substring(0, 0) + '_emag_' + frames.tolower(), ' ')
     
           cdf2tplot, files[w], prefix='esc', tplotnames=tname, varformat=TEMPORARY(varformat)
           IF ~undefined(tname) THEN BEGIN
              options, tname, /def, labels=['X', 'Y', 'Z'], labflag=-1, constant=0., colors='bgr'
              suffix = STRSPLIT(tname, '_', /extract)
              IF is_string(suffix) THEN suffix = suffix[-1] ELSE suffix = (suffix.toarray())[*, -1]
              FOR j=0, N_ELEMENTS(tname)-1 DO options, tname[j], /def, ytitle=(probes[i]).toupper() + '!CB' + suffix[j]
              append_array, rname, tname
           ENDIF
           get_data, tname[0], data=d
           btot = tname[0].replace(suffix[0], 'tot')
           store_data, btot, data={x: d.x, y: SQRT(TOTAL(d.y*d.y, 2))}, dl=dl
           append_array, rname, btot
           options, TEMPORARY(btot), /def, ytitle=(probes[i]).toupper() + '!C|B|', ysubtitle='[nT]'
        END
        1: BEGIN ; housekeeping
           cdf2tplot, files[w], prefix='esc', tplotnames=tname
           FOR j=0, N_ELEMENTS(tname)-1 DO BEGIN
              IF ~((tname[j]).matches('esc' + (probes[i]).substring(0, 0) + '_emag_hk')) THEN BEGIN
                 store_data, tname[j], newname=(tname[j]).replace('esc' + (probes[i]).substring(0, 0), 'esc' + (probes[i]).substring(0, 0) + '_emag_hk')
                 tname[j] = (tname[j]).replace('esc' + (probes[i]).substring(0, 0), 'esc' + (probes[i]).substring(0, 0) + '_emag_hk')
              ENDIF 
           ENDFOR 
           append_array, rname, tname
        END
     ENDCASE 
     undefine, tname
  ENDFOR

  IF (both) THEN BEGIN
     line_colors, 5
     store_data, 'esc_emag_tot', data='esc' + ['b', 'g'] + '_emag_tot', dlim={labels: ['BLUE', 'GOLD'], labflag: -1, colors: [2, 5], ytitle: 'ESCAPADE', ysubtitle: '|B| [nT]'}
     append_array, rname, 'esc_emag_tot'
  ENDIF 
  RETURN
END 
