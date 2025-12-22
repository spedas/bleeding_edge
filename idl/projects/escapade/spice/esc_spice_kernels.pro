;+
;
;FUNCTION:        ESC_SPICE_KERNELS
;
;PURPOSE:         Provides the ESCAPADE SPICE kernels.
;
;INPUTS:          None.
;
;KEYWORDS:
;
;    TRANGE:      Specifies the time range to be loaded.
;
;      BLUE:      If set, loading the BLUE spacecraft-related kernels.
;
;      GOLD:      If set, loading the GOLD spacecraft-related kernels.
;
;      PATH:      Specifies the parent directory where to load SPICE files.
;
;      LOAD:      If set, loading the identified SPICE kernels.
;
;     CLEAR:      If set, clearing the preloading SPICE kernels.
;
;      INFO:      Returns the loaded SPICE kernels informaiton.
;
;CREATED BY:      Takuya Hara on 2025-11-17.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2025-12-19 23:57:20 -0800 (Fri, 19 Dec 2025) $
; $LastChangedRevision: 33937 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/spice/esc_spice_kernels.pro $
;
;-
FUNCTION esc_spice_kernels, trange=itime, verbose=verbose, blue=blue, gold=gold,     $
                            no_server=no_server, no_download=no_download, path=path, $
                            load=load, clear=clear, info=info, source=source

  COMPILE_OPT idl2
  oneday = 86400.d0
  IF ~undefined(blue) THEN bflg = FIX(blue) ELSE bflg = 0
  IF ~undefined(gold) THEN gflg = FIX(gold) ELSE gflg = 0
  IF (bflg + gflg EQ 0) THEN BEGIN
     ; loading both spacecraft
     bflg = 1
     gflg = 1
  ENDIF 

  ;IF undefined(source) THEN src = esc_file_source() ELSE src = source
  ;IF KEYWORD_SET(no_download) OR KEYWORD_SET(no_server) THEN src.no_server = 1
  ;mk = file_retrieve('escapade_*.tm', local_data_dir = path + 'escapade/science/kernels/mk/', /last_version, /valid_only, verbose=verbose)
  mk = esc_file_retrieve('science/kernels/mk/escapade_*_v*.tm', verbose=verbose, source=src, $
                          local_data_dir=path, no_download=no_download, no_server=no_server, /valid_only)
  IF mk[0] EQ '' THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No meta kernel found.'
     RETURN, 0
  ENDIF   

  kernels = spice_mk_read(FILE_BASENAME(mk[0]), local_data_dir=FILE_DIRNAME(mk[0], /mark), /no_server)
  w = WHERE( ((FILE_BASENAME(kernels)).matches('^esc') EQ 1) AND $
             (((FILE_BASENAME(kernels)).matches('.bsp$') EQ 1) OR ((FILE_BASENAME(kernels)).matches('.bc$') EQ 1)), nw, complement=v, ncomplement=nv)
  IF nv GT 0 THEN kernels = kernels[v]
  undefine, w, nw, v, nv
  kernels = esc_file_retrieve(kernels.replace(src.local_data_dir, ''), verbose=verbose, source=src, /valid_only)

  
  IF (bflg) THEN append_array, probes, 'blue'
  IF (gflg) THEN append_array, probes, 'gold'

  tr = timerange(itime)
  FOR i=0, N_ELEMENTS(probes)-1 DO BEGIN
     ; SPK
     prefix = 'esc-' + (probes[i]).substring(0, 0)
     ;bsp   = prefix + '_orb-pre-eph_*-*_v*.bsp'
     bsp   = prefix + '_orb-pre-eph_YYYYMMDD-????????_v??.bsp'
     ;spath = 'escapade/commissioning/' + probes[i] + '/ephemeris/predictive/'
     ;spk = file_retrieve('YYYY/MM/' + bsp, local_data_dir=path + spath, trange=tr + [-1.d0, 1.d0] * oneday * 30.d0, $
     ;                    /daily_res, /last_version, /valid_only, /verbose)

     spath = 'commissioning/' + probes[i] + '/ephemeris/predictive/'
     IF src.no_server EQ 1 THEN BEGIN
        spath = src.local_data_dir + spath
        urls  = ['', '']
     ENDIF ELSE BEGIN
        spath = src.remote_data_dir + spath
        urls  = STRSPLIT(STRING(IDL_BASE64(src.user_pass)), ':', /extract)
     ENDELSE 
     spks = spd_uniq(time_intervals(tformat='YYYY/MM/' + prefix + '*.bsp', trange=tr + [-1.d0, 1.d0] * oneday * 30.d0, /daily_res))
     FOR j=0, N_ELEMENTS(spks)-1 DO BEGIN
        aspk = spath + spks[j]
        spd_download_expand, aspk, url_username=urls[0], url_password=urls[1], no_server=src.no_server;, /last_version
        append_array, spk, TEMPORARY(aspk)
     ENDFOR 
     w = WHERE(spk NE '', nw)
     IF nw GT 0 THEN BEGIN
        spk = spk[w]
        tspk = time_double(FILE_BASENAME(spk), tformat=bsp)

        ; Only using the latest version.
        ispk = UNIQ(tspk)
        spk  = spk[ispk]
        tspk = tspk[ispk]
        
        w = WHERE(tspk GE tr[0] - 30.d0*oneday AND tspk LE tr[1] + 30.d0*oneday, nw)
        IF nw GT 0 THEN BEGIN
           IF src.no_server EQ 1 THEN spk = spk.replace(src.local_data_dir, '') $
           ELSE spk = spk.replace(src.remote_data_dir, '')
           spk = esc_file_retrieve(spk[w], source=src, /valid_only, verbose=verbose)
        ENDIF 
     ENDIF 

     IF nw GT 0 THEN append_array, kernels, spk
     undefine, spk 
  ENDFOR
  IF KEYWORD_SET(clear) THEN cspice_kclear
  IF KEYWORD_SET(load)  THEN spice_kernel_load, kernels, info=info, maxiv=10000

  RETURN, kernels
END 
