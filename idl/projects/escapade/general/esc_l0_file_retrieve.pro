;+
;
;FUNCTION:        ESC_L0_FILE_RETRIEVE
;
;PURPOSE:         Retrieves (downloads if necessary) ESCAPADE L0 raw packet data files.
;
;INPUTS:          Time range specified via the TRANGE keyword.
;                 APID(s) specified via the APID keyword.
;
;KEYWORDS:
;
;    TRANGE:      Specifies the time range to retrieve.
;                 If not set, the time range is determined by get_timespan.
;
;      APID:      Specifies the APID(s) to retrieve.
;
;      BLUE:      If set, retrieves only BLUE spacecraft data.
;
;      GOLD:      If set, retrieves only GOLD spacecraft data.
;
;    SOURCE:      Specifies the file source information. Default is esc_file_source().
;
; PRELAUNCH:      If set explicitly, retrieves files from the prelaunch directory.
;
;COMMISSION:      If set explicitly, retrieves files from the commissioning directory.
;
;   SCIENCE:      If set explicitly, retrieves files from the science directory.
;
;CREATED BY:      Takuya Hara on 2026-03-03.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2026-04-18 16:56:24 -0700 (Sat, 18 Apr 2026) $
; $LastChangedRevision: 34380 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/general/esc_l0_file_retrieve.pro $
;
;-
FUNCTION esc_l0_file_retrieve, trange=itime, apid=apid, verbose=verbose, blue=blue, gold=gold,  $
                               source=source,   no_server=no_server, last_version=last_version, $
                               prelaunch=prelaunch, commissioning=commissioning, science=science

  IF undefined(itime) THEN get_timespan, trange ELSE trange = itime
  IF is_string(trange) THEN trange = time_double(trange)

  IF KEYWORD_SET(blue) THEN append_array, probes, 'blue'
  IF KEYWORD_SET(gold) THEN append_array, probes, 'gold'
  IF undefined(probes) THEN probes = ['blue', 'gold']

  IF undefined(source) THEN src = esc_file_source(verbose=verbose, last_version=last_version, no_server=no_server) ELSE src = source
  fname = 'esc-p_l0_apid0x???_YYYY-MM-DD_r??.dat'
  yymm  = 'YYYY/MM/'

  phases = ['prelaunch', 'commissioning', 'science']
  IF KEYWORD_SET(prelaunch) THEN ip = 0
  IF KEYWORD_SET(commissioning) THEN ip = 1
  IF KEYWORD_SET(science) THEN ip = 2
  ;IF undefined(ip) THEN ip = -1 ; science
  ;rpath = phases[ip] + '/probe/l0/'

  rpath = 'phase/probe/l0/'
  IF ~undefined(ip) THEN rpath = rpath.replace('phase', phases[ip])
  
  IF undefined(apid) THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No APID(s) specified for retrieval.'
     RETURN, ''
  ENDIF ELSE apids = apid
  IF ~is_string(apids) THEN apids = roundst(apids)
  
  FOR i=0, N_ELEMENTS(probes)-1 DO FOR pp=0, N_ELEMENTS(apids)-1 DO BEGIN
     prefix = fname.replace('esc-p', 'esc-' + (probes[i]).substring(0, 0))
     prefix = prefix.replace('???', apids[pp])
     path = rpath.replace('probe', probes[i])

     IF undefined(ip) THEN BEGIN
        date = time_intervals(trange=trange, /daily)
        path = REPLICATE(path, N_ELEMENTS(date))
        path = path.replace('phase', esc_mission_phase(TEMPORARY(date)))
     ENDIF 

     undefine, afile
     afile = esc_file_retrieve(yymm + prefix, remote_data_dir=path, trange=trange, /daily, /valid_only,     $
                               no_server=no_server, last_version=last_version, verbose=verbose, source=src) 

     w = WHERE(afile NE '', nw)
     IF nw EQ 0 THEN BEGIN
        dprint, dlevel=2, verbose=verobse, 'No file(s) found.'
        CONTINUE
     ENDIF
     append_array, files, afile[w]
  ENDFOR 

  IF undefined(files) THEN files = ''
  RETURN, files
END
