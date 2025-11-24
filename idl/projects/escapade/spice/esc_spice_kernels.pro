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
;NOTE:            As of 2025-11-17, the official ESCAPADE science team
;                 members only can use this function only under the UCB-SSL
;                 remote servers.
;
;CREATED BY:      Takuya Hara on 2025-11-17.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2025-11-17 15:31:13 -0800 (Mon, 17 Nov 2025) $
; $LastChangedRevision: 33848 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/spice/esc_spice_kernels.pro $
;
;-
FUNCTION esc_spice_kernels, trange=itime, verbose=verbose, blue=blue, gold=gold,     $
                            no_server=no_server, no_download=no_download, path=path, $
                            load=load, clear=clear, info=info

  COMPILE_OPT idl2
  oneday = 86400.d0
  IF ~undefined(blue) THEN bflg = FIX(blue) ELSE bflg = 0
  IF ~undefined(gold) THEN gflg = FIX(gold) ELSE gflg = 0
  IF (bflg + gflg EQ 0) THEN BEGIN
     ; loading both spacecraft
     bflg = 1
     gflg = 1
  ENDIF 

  IF undefined(path) THEN path = root_data_dir()
  mk = file_retrieve('escapade_*.tm', local_data_dir = path + 'escapade/science/kernels/mk/', /last_version, /valid_only, verbose=verbose)
  IF mk[0] EQ '' THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No meta kernel found.'
     RETURN, 0
  ENDIF 

  kernels = spice_mk_read(FILE_BASENAME(mk[0]), local_data_dir=FILE_DIRNAME(mk[0], /mark), /no_server)
  w = WHERE( ((FILE_BASENAME(kernels)).matches('^esc') EQ 1) AND $
             (((FILE_BASENAME(kernels)).matches('.bsp$') EQ 1) OR ((FILE_BASENAME(kernels)).matches('.bc$') EQ 1)), nw, complement=v, ncomplement=nv)
  IF nv GT 0 THEN kernels = kernels[v]
  undefine, w, nw, v, nv

  IF (bflg) THEN append_array, probes, 'blue'
  IF (gflg) THEN append_array, probes, 'gold'

  tr = timerange(itime)
  FOR i=0, N_ELEMENTS(probes)-1 DO BEGIN
     ; SPK
     prefix = 'esc-' + (probes[i]).substring(0, 0)
     ;bsp   = prefix + '_orb-pre-eph_*-*_v*.bsp'
     bsp   = prefix + '_orb-pre-eph_YYYYMMDD-????????_v??.bsp'
     spath = 'escapade/commissioning/' + probes[i] + '/ephemeris/predictive/'
     spk = file_retrieve('YYYY/MM/' + bsp, local_data_dir=path + spath, trange=tr + [-1.d0, 1.d0] * oneday * 30.d0, $
                         /daily_res, /last_version, /valid_only, /verbose)

     w = WHERE(spk NE '', nw)
     IF nw GT 0 THEN append_array, kernels, spk[w]
     undefine, spk 
  ENDFOR  
  IF KEYWORD_SET(clear) THEN cspice_kclear
  IF KEYWORD_SET(load)  THEN spice_kernel_load, kernels, info=info, maxiv=10000

  RETURN, kernels
END 
