;+
;
;PROCEDURE:       ESC_EESA_LOAD
;
;PURPOSE:         Loads the ESCAPADE EESA-e CDF file(s).
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
;CREATED BY:      Takuya Hara on 2026-03-04.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2026-04-18 19:30:56 -0700 (Sat, 18 Apr 2026) $
; $LastChangedRevision: 34384 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/electron/esc_eesa_load.pro $
;
;-
PRO esc_eesa_load, itime, product=product, data=data, verbose=verbose, level=level, blue=blue, gold=gold, files=afile, $
                   ipath=ipath, source=source, no_server=no_server, prelaunch=prelaunch, commissioning=commissioning, science=science

  IF undefined(itime) THEN get_timespan, trange ELSE trange = itime
  IF is_string(trange) THEN trange = time_double(trange)

  IF KEYWORD_SET(blue) THEN append_array, probes, 'blue'
  IF KEYWORD_SET(gold) THEN append_array, probes, 'gold'
  IF undefined(probes) THEN probes = ['blue', 'gold']
  IF N_ELEMENTS(probes) EQ 2 THEN both = 1 ELSE both = 0
  
  IF undefined(source) THEN src = esc_file_source() ELSE src = source
  IF undefined(level) THEN lvl = 'l1' ELSE lvl = level.tolower()

  yyyymm = 'YYYY/MM/'
  fname  = 'esc-p_eesae_lvl_*prod*_YYYY-MM-DD_*.cdf'

  phases = ['prelaunch', 'commissioning', 'science']
  IF KEYWORD_SET(prelaunch) THEN ip = 0
  IF KEYWORD_SET(commissioning) THEN ip = 1
  IF KEYWORD_SET(science) THEN ip = 2
  ;IF undefined(ip) THEN ip = -1 ; science

  ;rpath = phases[ip] + '/probe/eesae/'

  rpath = 'phase/probe/eesae/'
  IF ~undefined(ip) THEN rpath = rpath.replace('phase', phases[ip])
  IF undefined(product) THEN prod = 'f3d' ELSE prod = product ; Default is currently Full 3D (apid0x140)
  IF ~undefined(ipath) THEN yyyymm = ''
  
  FOR i=0, N_ELEMENTS(probes)-1 DO FOR j=0, N_ELEMENTS(prod)-1 DO BEGIN
     prefix = fname.replace('esc-p', 'esc-' + (probes[i]).substring(0, 0))
     prefix = yyyymm + prefix.replace('lvl', lvl)
     prefix = prefix.replace('prod', prod[j])
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

     cdfi = cdf_load_vars(files[w], /all)

     prefix = (probes[i]).substring(0, 0) + '_eesae_'
     vname = cdfi.vars.name
     
     ndat  = N_ELEMENTS(*cdfi.vars[0].dataptr)
     undefine, data
     data = REPLICATE(esc_eesa_struct(prod[j], probe=probes[i]), ndat)
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

     FOR k=1L, cdfi.nv-1 DO BEGIN
        it = WHERE(prefix + tags.tolower() EQ vname[k], nt)
        IF nt EQ 0 THEN CONTINUE
        
        IF (*(cdfi.vars[k].attrptr)).var_type EQ 'metadata' THEN BEGIN
           IF ndimen(*(cdfi.vars[k].dataptr)) LE 1 THEN data.(it) = REPLICATE(*(cdfi.vars[k].dataptr), ndat) $
           ELSE data.(it) = REBIN(*(cdfi.vars[k].dataptr), [(SIZE(*(cdfi.vars[k].dataptr)))[1:-3], ndat], /sample)
        ENDIF ELSE data.(it) = TRANSPOSE(*(cdfi.vars[k].dataptr), SHIFT([0:ndimen(*(cdfi.vars[k].dataptr))-1], -1))
     ENDFOR
     data.end_time = data.time + data.num_accum * 8.d0
     data.cnts     = data.data

     CASE (prod[j]).toupper() OF
        'SPEC': BEGIN           ; Spectra
           COMMON esc_eesa_spec_com, escb_eesa_spec, escg_eesa_spec
           IF probes[i] EQ 'blue' THEN escb_eesa_spec = data ELSE escg_eesa_spec = data
        END
        'PAD': BEGIN            ; Pitch Angle Distributions (PADs)
           COMMON esc_eesa_pad_com, escb_eesa_pad, escg_eesa_pad
           IF probes[i] EQ 'blue' THEN escb_eesa_pad = data ELSE escg_eesa_pad = data
        END
        'F3D': BEGIN            ; Full 3D
           COMMON esc_eesa_f3d_com, escb_eesa_f3d, escg_eesa_f3d
           IF probes[i] EQ 'blue' THEN escb_eesa_f3d = data ELSE escg_eesa_f3d = data
        END
        'POT': BEGIN            ; Spacecraft Potential 
           COMMON esc_eesa_pot_com, escb_eesa_pot, escg_eesa_pot
           IF probes[i] EQ 'blue' THEN escb_eesa_pot = data ELSE escg_eesa_pot = data
        END
        ELSE: dprint, dlevel=2, verbose=verbose, 'No EESA-e science products matched.'
     ENDCASE  
  ENDFOR

  RETURN
END 
