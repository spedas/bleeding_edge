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
; $LastChangedDate: 2026-06-24 16:13:45 -0700 (Wed, 24 Jun 2026) $
; $LastChangedRevision: 34598 $
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
  trange = tr + [-1.d0, 1.d0] * oneday * 30.d0
  dates = time_intervals(trange=trange, /daily_res)
  FOR i=0, N_ELEMENTS(probes)-1 DO BEGIN
     ; SPK & CK
     prefix = 'esc-' + (probes[i]).substring(0, 0)
     bsp   = prefix + '_orb-???-eph_' + ['YYYYMMDD-????????', '????????-YYYYMMDD'] + '_v??.bsp'
     bc    = prefix + '_orb-pre-ck_YYYYMMDD-????????_v??.bc'

     IF src.no_server EQ 1 THEN BEGIN
        spath = src.local_data_dir
        urls  = ['', '']
     ENDIF ELSE BEGIN
        spath = src.remote_data_dir
        urls  = STRSPLIT(STRING(IDL_BASE64(src.user_pass)), ':', /extract)
     ENDELSE 

     ; SPK
     pspk = 0 ; = predictive SPK 
     tspk = trange
     SPK:
     IF (pspk) THEN $
        spks = esc_mission_phase(dates) + '/' + probes[i] + '/ephemeris/predictive/' + time_string(dates, tformat='YYYY/MM/' + prefix) + '*.bsp' $
     ELSE spks = 'science/' + probes[i] + '/ephemeris/reconstructed/' + time_string(dates, tformat='YYYY/' + prefix) + '*.bsp'
     
     spks = spks[UNIQ(spks)]
     w = WHERE(STRMATCH(spks, '*prelaunch*') EQ 0, nw)
     IF nw GT 0 THEN spks = spks[w]
     
     FOR j=0, N_ELEMENTS(spks)-1 DO BEGIN
        aspk = spath + spks[j]
        spd_download_expand, aspk, url_username=urls[0], url_password=urls[1], no_server=src.no_server;, /last_version
        append_array, spk, TEMPORARY(aspk)
     ENDFOR 
     w = WHERE(spk NE '', nw)
     IF nw GT 0 THEN BEGIN
        spk = spk[w]

        arr = FILE_BASENAME(spk)
        s   = SORT(arr)
        spk = spk[(s[UNIQ(arr[s])])[SORT(s[UNIQ(arr[s])])]]
        undefine, arr, s
        
        tspk_s = time_double(FILE_BASENAME(spk), tformat=bsp[0])
        tspk_e = time_double(FILE_BASENAME(spk), tformat=bsp[1])
        ; Only using the latest version.
        ispk = UNIQ(tspk_s)
        spk  = spk[ispk]
        tspk_s = tspk_s[ispk]
        tspk_e = tspk_e[ispk]

        ;w = WHERE(tspk GE trange[0] AND tspk LE trange[1], nw)
        undefine, WHERE(tspk_s GT tspk[1] OR tspk_e LT tspk[0], complement=w, ncomplement=nw)
        IF nw GT 0 THEN BEGIN
           IF ~(pspk) THEN BEGIN
              v = WHERE(tspk_s[w] LE tspk[0] AND tspk_e[w] GE tspk[1], nv)
              IF nv EQ 0 THEN BEGIN
                 pspk = 1
                 tspk = [MAX([tspk_s, tspk_e]), trange[1]]
              ENDIF
           ENDIF ELSE pspk = 0
           IF src.no_server EQ 1 THEN spk = spk.replace(src.local_data_dir, '') $
           ELSE spk = spk.replace(src.remote_data_dir, '')
           spk = esc_file_retrieve(spk[w], source=src, /valid_only, verbose=verbose)
        ENDIF ELSE BEGIN
           IF ~(pspk) THEN pspk = 1
        ENDELSE 
     ENDIF 
     
     IF nw GT 0 THEN append_array, kernels, spk
     undefine, spk
     IF (pspk) THEN GOTO, SPK
     
     ; CK
     cks  = esc_mission_phase(dates) + '/' + probes[i] + '/ephemeris/predictive/' + time_string(dates, tformat='YYYY/MM/' + prefix) + '*.bc'
     cks  = cks[UNIQ(cks)]
     w = WHERE(STRMATCH(cks, '*prelaunch*') EQ 0, nw)
     IF nw GT 0 THEN cks = cks[w]

     FOR j=0, N_ELEMENTS(cks)-1 DO BEGIN
        ack = spath + cks[j]
        spd_download_expand, ack, url_username=urls[0], url_password=urls[1], no_server=src.no_server ;, /last_version
        append_array, ck, TEMPORARY(ack)
     ENDFOR
     w = WHERE(ck NE '', nw)
     IF nw GT 0 THEN BEGIN
        ck = ck[w]

        arr = FILE_BASENAME(ck)
        s   = SORT(arr)
        ck = ck[(s[UNIQ(arr[s])])[SORT(s[UNIQ(arr[s])])]]
        undefine, arr, s

        tck = time_double(FILE_BASENAME(ck), tformat=bc)
        
        ; Only using the latest version.
        ick = UNIQ(tck)
        ck  = ck[ick]
        tck = tck[ick]

        w = WHERE(tck GE trange[0] AND tck LE trange[1], nw)
        IF nw GT 0 THEN BEGIN
           IF src.no_server EQ 1 THEN ck = ck.replace(src.local_data_dir, '') $
           ELSE ck = ck.replace(src.remote_data_dir, '')
           ck = esc_file_retrieve(ck[w], source=src, /valid_only, verbose=verbose)
        ENDIF
     ENDIF

     IF nw GT 0 THEN append_array, kernels, ck
     undefine, ck
      
  ENDFOR
  IF KEYWORD_SET(clear) THEN cspice_kclear
  IF KEYWORD_SET(load)  THEN spice_kernel_load, kernels, info=info, maxiv=10000

  RETURN, kernels
END 
