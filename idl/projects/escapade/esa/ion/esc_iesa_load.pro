;+
;
;PROCEDURE:       ESC_IESA_LOAD
;
;PURPOSE:         Loads the ESCAPADE EESA-i CDF file(s).
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
; PRELAUNCH:      If set, prelaunch data will be loaded.
;
;COMMISSION:      If set, commissioning data will be loaded.
;
;     CLEAR:      If set, clears the EESA-i common blocks.
;
;CREATED BY:      Takuya Hara on 2026-02-07.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2026-05-13 14:45:03 -0700 (Wed, 13 May 2026) $
; $LastChangedRevision: 34454 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/ion/esc_iesa_load.pro $
;
;-
PRO esc_iesa_load, itime, product=product, data=data, verbose=verbose, level=level, blue=blue, gold=gold, files=afile, $
                   ipath=ipath, source=source, no_server=no_server, prelaunch=prelaunch, commissioning=commissioning, clear=clear

  COMMON esc_iesa_fe_com, escb_iesa_fe, escg_iesa_fe    ; Fine Energies (0x134)
  COMMON esc_iesa_fm_com, escb_iesa_fm, escg_iesa_fm    ; Fine Masses   (0x147)
  COMMON esc_iesa_f4d_com, escb_iesa_f4d, escg_iesa_f4d ; Fine 4D       (0x125)
  COMMON esc_iesa_sw_com, escb_iesa_sw, escg_iesa_sw    ; Solar Wind    (0x139)

  IF KEYWORD_SET(clear) THEN BEGIN
     undefine, escb_iesa_fe,  escg_iesa_fe
     undefine, escb_iesa_fm,  escg_iesa_fm
     undefine, escb_iesa_f4d, escg_iesa_f4d
     undefine, escb_iesa_sw,  escg_iesa_sw
  ENDIF 
  
  IF undefined(itime) THEN get_timespan, trange ELSE trange = itime
  IF is_string(trange) THEN trange = time_double(trange)

  IF KEYWORD_SET(blue) THEN append_array, probes, 'blue'
  IF KEYWORD_SET(gold) THEN append_array, probes, 'gold'
  IF undefined(probes) THEN probes = ['blue', 'gold']
  IF N_ELEMENTS(probes) EQ 2 THEN both = 1 ELSE both = 0
  
  IF undefined(source) THEN src = esc_file_source() ELSE src = source
  IF undefined(level) THEN lvl = 'l1' ELSE lvl = level.tolower()

  yyyymm = 'YYYY/MM/'
  fname  = 'esc-p_eesai_lvl_*prod*_YYYY-MM-DD_*.cdf'

  phases = ['prelaunch', 'commissioning', 'science']
  IF KEYWORD_SET(prelaunch) THEN ip = 0
  IF KEYWORD_SET(commissioning) THEN ip = 1
  IF undefined(ip) THEN ip = -1 ; science

  rpath = phases[ip] + '/probe/eesai/'

  IF undefined(product) THEN prod = 'f4d' ELSE prod = product
  IF ~undefined(ipath) THEN yyyymm = ''
  
  FOR i=0, N_ELEMENTS(probes)-1 DO FOR j=0, N_ELEMENTS(prod)-1 DO BEGIN
     prefix = fname.replace('esc-p', 'esc-' + (probes[i]).substring(0, 0))
     prefix = yyyymm + prefix.replace('lvl', lvl)
     prefix = prefix.replace('prod', prod[j])
     path = rpath.replace('probe', probes[i]) + lvl + '/'

     undefine, files
     IF undefined(ipath) THEN $
        files = esc_file_retrieve(prefix, remote_data_dir=path, trange=trange, /daily, /last_version, /valid_only, no_server=no_server, verbose=verbose, source=src) $
     ELSE files = file_retrieve(prefix, local_data_dir=ipath, trange=trange, /daily, /last_version, /valid_only, /no_server)
     ;ELSE files = FILE_SEARCH(ipath + time_string(trange, tformat=prefix))

     w = WHERE(files NE '', nw)
     IF nw EQ 0 THEN BEGIN
        dprint, dlevel=2, verbose=verobse, 'No file(s) found.'
        CONTINUE
     ENDIF 
     append_array, afile, files[w]

     cdfi = cdf_load_vars(files[w], /all)

     prefix = (probes[i]).substring(0, 0) + '_eesai_'
     vname = cdfi.vars.name
     
     ndat  = N_ELEMENTS(*cdfi.vars[0].dataptr)
     undefine, data

     IF prod[j] EQ 'fm' THEN BEGIN
        w = WHERE(vname EQ prefix + 'nenergy', nw)
        IF nw EQ 1 THEN nenergy = *cdfi.vars[w].dataptr
     ENDIF 
     
     data = REPLICATE(esc_iesa_struct(prod[j], probe=probes[i], nenergy=TEMPORARY(nenergy)), ndat)
     tags = TAG_NAMES(data[0])

     DEFSYSV, '!CDF_LEAP_SECONDS', exists=exists
     IF NOT KEYWORD_SET(exists) THEN BEGIN
        cdf_leap_second_init
        DEFSYSV, '!CDF_LEAP_SECONDS', exists=exists
        IF NOT KEYWORD_SET(exists) THEN BEGIN
           dprint, dlevel=2, 'Error: !CDF_LEAP_SECONDS, must be defined to convert CDFs with TT2000 times.'
           RETURN
        ENDIF
     ENDIF 
     data.time = time_double(*(cdfi.vars[0].dataptr), /tt2000)

     is = WHERE(vname EQ prefix + 'spoiler_state', n_is)
     ip = WHERE(vname EQ prefix + 'sweep_table', n_ip)
     IF (n_is + n_ip) EQ 2 THEN emode = 7B * (*cdfi.vars[is].dataptr) + (*cdfi.vars[ip].dataptr)
     ia = WHERE(vname EQ prefix + 'lut_phi_ind', n_ia)
     IF n_ia GT 0 THEN amode = *cdfi.vars[ia].dataptr
     
     FOR k=1L, cdfi.nv-1 DO BEGIN
        it = WHERE(prefix + tags.tolower() EQ vname[k], nt)
        IF nt EQ 0 THEN CONTINUE

        IF (*(cdfi.vars[k].attrptr)).var_type EQ 'metadata' THEN BEGIN
           IF cdfi.vars[k].d[0] EQ 14 THEN BEGIN
              IF undefined(amode) OR (cdfi.vars[k].d[2] NE 128) THEN data.(it) = TRANSPOSE((*(cdfi.vars[k].dataptr))[emode, *, *, *], SHIFT([0:ndimen(*(cdfi.vars[k].dataptr))-1], -1)) $
              ELSE BEGIN
                 aidx = INTARR(data[0].nbins, 8)
                 FOR ia=0, 7 DO aidx[*, ia] = REFORM(TRANSPOSE(amode[*, ia] ## REPLICATE(1L, 8) + 16L * REPLICATE(1L, data[0].nanode) ## INDGEN(data[0].ndef)), data[0].nbins)
                 aidx = REBIN(TRANSPOSE(aidx[*, data.lut_id]), ndat, data[0].nbins, /sample)
                 eidx = REBIN(emode, ndat, data[0].nbins, /sample)

                 tdata = REFORM(TRANSPOSE(*(cdfi.vars[k].dataptr), [0, 2, 1, 3]), cdfi.vars[k].d[0]*cdfi.vars[k].d[2], cdfi.vars[k].d[1], cdfi.vars[k].d[3])
                 idx = eidx + LONG(cdfi.vars[k].d[0]) * aidx
                 tdata = TRANSPOSE(REFORM(tdata[idx, *, *], ndat, data[0].nbins, cdfi.vars[k].d[1], cdfi.vars[k].d[3]), [2, 1, 3, 0])
                 data.(it) = TEMPORARY(tdata)

                 undefine, aidx, eidx, idx
              ENDELSE 
           ENDIF ELSE BEGIN
              IF ndimen(*(cdfi.vars[k].dataptr)) LE 1 THEN data.(it) = REPLICATE(*(cdfi.vars[k].dataptr), ndat) $
              ELSE data.(it) = REBIN(*(cdfi.vars[k].dataptr), [(SIZE(*(cdfi.vars[k].dataptr)))[1:-3], ndat], /sample)
           ENDELSE 
        ENDIF ELSE data.(it) = TRANSPOSE(*(cdfi.vars[k].dataptr), SHIFT([0:ndimen(*(cdfi.vars[k].dataptr))-1], -1))
     ENDFOR
     data.end_time = data.time + data.dp_cadence
     data.cnts     = data.data

     CASE (prod[j]).toupper() OF
        'FE': BEGIN             ; Fine Energies
           IF probes[i] EQ 'blue' THEN escb_iesa_fe = data ELSE escg_iesa_fe = data
        END
        'FM': BEGIN             ; Fine Masses
           IF probes[i] EQ 'blue' THEN escb_iesa_fm = data ELSE escg_iesa_fm = data
        END
        'F4D': BEGIN            ; Fine 4D
           IF probes[i] EQ 'blue' THEN escb_iesa_f4d = data ELSE escg_iesa_f4d = data
        END
        'SW': BEGIN             ; Solar Wind
           IF probes[i] EQ 'blue' THEN escb_iesa_sw = data ELSE escg_iesa_sw = data
        END
        ELSE: dprint, dlevel=2, verbose=verbose, 'No EESA-i science products matched.'
     ENDCASE  
  ENDFOR

  RETURN
END 
