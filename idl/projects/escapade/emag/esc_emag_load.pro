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
; PRELAUNCH:      If set, the prelaunch data will be loaded.
;
;COMMISSION:      If set, the commissioning data will be loaded.
;
;    FRAMES:      Specifies which frames (i.e., coordinate systems) will be loaded.
;                 Default is to load all frames.
;
;CREATED BY:      Takuya Hara on 2026-01-09.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2026-02-04 16:42:10 -0800 (Wed, 04 Feb 2026) $
; $LastChangedRevision: 34121 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/emag/esc_emag_load.pro $
;
;-
PRO esc_emag_load, itime, verbose=verbose, level=level, no_server=no_server, blue=blue, gold=gold, files=afile, source=source, $
                   prelaunch=prelaunch, commissioning=commissioning, frames=frames
  IF undefined(itime) THEN get_timespan, trange ELSE trange = itime
  IF is_string(trange) THEN trange = time_double(trange)

  IF KEYWORD_SET(blue) THEN append_array, probes, 'blue'
  IF KEYWORD_SET(gold) THEN append_array, probes, 'gold'
  IF undefined(probes) THEN probes = ['blue', 'gold']
  IF N_ELEMENTS(probes) EQ 2 THEN both = 1 ELSE both = 0
  
  IF undefined(source) THEN src = esc_file_source() ELSE src = source
  IF undefined(level) THEN lvl = 'l1' ELSE lvl = level.tolower()
  fname = 'YYYY/MM/esc-p_emag_lvl_YYYY-MM-DD_*.cdf'

  phases = ['prelaunch', 'commissioning', 'science']
  IF KEYWORD_SET(prelaunch) THEN ip = 0
  IF KEYWORD_SET(commissioning) THEN ip = 1
  IF undefined(ip) THEN ip = -1 ; science

  rpath = phases[ip] + '/probe/emag/'
  FOR i=0, N_ELEMENTS(probes)-1 DO BEGIN
     prefix = fname.replace('esc-p', 'esc-' + (probes[i]).substring(0, 0))
     prefix = prefix.replace('lvl', lvl)
     path = rpath.replace('probe', probes[i]) + lvl + '/'

     undefine, files
     files = esc_file_retrieve(prefix, remote_data_dir=path, trange=trange, /daily, /last_version, /valid_only, no_server=no_server, verbose=verbose, source=src)

     w = WHERE(files NE '', nw)
     IF nw EQ 0 THEN BEGIN
        dprint, dlevel=2, verbose=verobse, 'No file(s) found.'
        CONTINUE
     ENDIF 
     append_array, afile, files[w]

     IF ~undefined(frames) THEN varformat = STRJOIN((probes[i]).substring(0, 0) + '_emag_' + frames.tolower(), ' ')
     
     cdf2tplot, files[w], prefix='esc', tplotnames=tname, varformat=TEMPORARY(varformat)
     IF ~undefined(tname) THEN BEGIN
        options, tname, /def, labels=['X', 'Y', 'Z'], labflag=-1, constant=0., colors='bgr'
        suffix = ((STRSPLIT(tname, '_', /extract)).toarray())[*, -1]
        FOR j=0, N_ELEMENTS(tname)-1 DO options, tname[j], /def, ytitle=(probes[i]).toupper() + '!CB' + suffix[j]
     ENDIF
     get_data, tname[0], data=d
     btot = tname[0].replace(suffix[0], 'tot')
     store_data, btot, data={x: d.x, y: SQRT(TOTAL(d.y*d.y, 2))}, dl=dl
     options, TEMPORARY(btot), /def, ytitle=(probes[i]).toupper() + '!C|B|', ysubtitle='[nT]'

     undefine, tname
  ENDFOR

  IF (both) THEN BEGIN
     line_colors, 5
     store_data, 'esc_emag_tot', data='esc' + ['b', 'g'] + '_emag_tot', dlim={labels: ['BLUE', 'GOLD'], labflag: -1, colors: [2, 5], ytitle: 'ESCAPADE', ysubtitle: '|B| [nT]'}
  ENDIF 
  RETURN
END 
