;+
;
;PROCEDURE:       VEX_MAG_LOAD
;
;PURPOSE:         
;                 Loads the VEX/MAG data from ESA/PSA.
;                 Results are returned as tplot variables.
;                 The directory structure was modified from those of ESA/PSA. 
;
;INPUTS:          Time interval used in analyses.
;
;KEYWORDS:
;
;   POS:          If set, the spacecraft position data is also restored.
;
;   RESULT:       Returned the restored data as a structure.
;
;   L4:           If set, the 4 sec smoothed data will be restored.
;
;   DOUBLE:       Returned the data as a double style.
;
;   REMOVE_NAN:   If set, removing NANs. 
;
;   NO_SERVER:    If set, prevents any contact with the remote server.
;
;CREATED BY:      Takuya Hara on 2016-07-12.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2024-01-31 15:55:56 -0800 (Wed, 31 Jan 2024) $
; $LastChangedRevision: 32430 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/vex/mag/vex_mag_load.pro $
;
;-
PRO vex_mag_list, trange, verbose=verbose, l4=l4, file=file, time=modify_time, level=level, resolution=res
  CASE level OF
     'l2': BEGIN
        lvl = '2'
        CASE res OF 
           '1hz'  : suffix = '_D001'
           '32hz' : suffix = '_D032'
           '128hz': suffix = '_D128'
        ENDCASE 
     END 
     'l3': BEGIN
        lvl = '3'
        suffix = '_D001'
     END 
     'l4': BEGIN
        lvl =  '4'
        suffix = '_S004'
     END 
  ENDCASE 
  IF lvl EQ '2' THEN prefix = 'BIO_' ELSE prefix = 'MAG_'

  ;rpath = 'ftp://psa.esac.esa.int/pub/mirror/VENUS-EXPRESS/MAG/'
  rpath = 'https://archives.esac.esa.int/psa/ftp/VENUS-EXPRESS/MAG/'
  
  mtime = ['2005-11', '2007-10-03', '2009-10-06', '2010-09-01', '2013']
  mtime = time_double(mtime)

  date = time_double(time_intervals(trange=trange, /daily_res, tformat='YYYY-MM-DD'))
  phase = FIX(INTERP(FINDGEN(N_ELEMENTS(mtime)), mtime, date)) < (N_ELEMENTS(mtime)-1)
  phase = STRING(phase, '(I0)')

  w = WHERE(phase EQ '0', nw, complement=v, ncomplement=nv)
  IF nw GT 0 THEN phase[w] = ''
  IF nv GT 0 THEN phase[v] = 'EXT' + phase[v] + '-'
  undefine, w, nw

  pdir = 'VEX-V-Y-MAG-' + lvl + '-' + phase + 'V1.0/DATA/'
  ndat = N_ELEMENTS(date)

  ;cmd = 'wget --spider -N -r -nd -A "MAG_'
  ldir = root_data_dir() + 'vex/mag/'
  file_mkdir2, ldir, dlevel=2, verbose=verbose

  FOR i=0, ndat-1 DO BEGIN
     IF date[i] GE time_double('2006-05-14') THEN subdir = 'ORB' + time_string(date[i], tformat='YYYYMM') $
     ELSE subdir = 'CAPTORBIT'
     ;SPAWN, cmd + time_string(date[i], tformat='YYYYMMDD') + '*.TAB" ' + rpath + pdir[i] +  subdir + suffix + '/ -o ' + ldir + 'vex_mag_lists.txt'
     cmd = rpath + pdir[i] + subdir + suffix + '/'

     dflg = 0
     IF SIZE(cmd_old, /type) EQ 0 THEN dflg = 1 $
     ELSE IF cmd NE cmd_old THEN dflg = 1
     IF (dflg) THEN list_file = spd_download(remote_path=cmd, local_path=ldir, local_file='vex_mag_lists.txt')

     OPENR, unit, list_file, /get_lun
     text = STRARR(FILE_LINES(list_file))
     READF, unit, text
     FREE_LUN, unit

     idx = WHERE(text.matches('.TAB') EQ 1, nidx)
     IF nidx GT 0 THEN BEGIN
        text = text[idx]

        afile = text.extract('<a href[^>]+>')
        afile = afile.extract('"[^"]+"')
        afile = afile.substring(1, -2)
        
        mod_time = text.extract('>[^>]+</td>')
        mod_time = mod_time.extract('>[^>]+<')
        mod_time = time_double(mod_time.substring(1, -4), tformat='YYYY-MM-DD hh:mm')

        w = WHERE(STRMATCH(afile, prefix + time_string(date[i], tformat='YYYYMMDD_') + '*.TAB') EQ 1, nw)

        IF nw GT 0 THEN BEGIN
           append_array, file, cmd + afile[w]
           append_array, modify_time, mod_time[w]
        ENDIF 
     ENDIF
     undefine, idx, nidx
     undefine, w, nw, text, afile
     cmd_old = cmd
  ENDFOR 
  FILE_DELETE, list_file
  RETURN
END

PRO vex_mag_load, trange, verbose=verbose, pos=pos, result=result, l2=l2, l3=l3, l4=l4, hz=hz, vso=vso, $
                  double=double, remove_nan=remove_nan, no_server=no_server, no_download=no_download
  rv = 6052. ; Venus radius
  IF SIZE(pos, /type) EQ 0 THEN pflg = 0 ELSE pflg = FIX(pos)
  IF KEYWORD_SET(remove_nan) THEN rflg = 1 ELSE rflg = 0
  IF KEYWORD_SET(no_server) THEN nflg = 0 ELSE nflg = 1
  IF KEYWORD_SET(no_download) THEN nflg = 0 ELSE nflg = 1
  IF KEYWORD_SET(vso) THEN vflg = 1 ELSE vflg = 0

  IF KEYWORD_SET(l3) THEN BEGIN
     level3:
     lvl = 'l3'
     res = '1sec'
     dt = 1.d0
  ENDIF 
  IF KEYWORD_SET(l4) THEN BEGIN
     lvl = 'l4'
     res = '4sec'
     dt = 4.d0
  ENDIF 
  IF KEYWORD_SET(l2) THEN BEGIN
     lvl = 'l2'
     IF SIZE(hz, /type) EQ 0 THEN BEGIN
        dprint, dlevel=2, verbose=verbose, 'The MAG 32 Hz data will be loaded.'
        hz = 32
     ENDIF 
     CASE FIX(hz) OF
        1: BEGIN
           res = '1hz'
           dt = 1.d0
        END 
        32: BEGIN
           res = '32hz'
           dt = 1.d0 / 32.d0
        END
        128: BEGIN
           res = '128hz'
           dt = 1.d0 / 128.d0
        END 
        ELSE: BEGIN
           dprint, dlevel=2, verbose=verbose, STRING(hz, '(I0)') + ' Hz data is not available.'
           RETURN
        END 
     ENDCASE 
  ENDIF 
  IF SIZE(lvl, /type) EQ 0 THEN GOTO, level3

  IF SIZE(trange, /type) EQ 0 THEN get_timespan, trange

  IF lvl EQ 'l2' THEN BEGIN
     path = 'vex/mag/' + lvl + '/' + res + '/YYYY/MM/'
     fname = 'BIO_YYYYMMDD_*.TAB'
  ENDIF ELSE BEGIN
     path = 'vex/mag/' + lvl + '/YYYY/MM/'
     fname = 'MAG_YYYYMMDD_*.TAB'
  ENDELSE 
  files = file_retrieve(path + fname, local_data_dir=root_data_dir(), /no_server, trange=trange, /daily_res, /valid_only, /last)

  IF (nflg) THEN BEGIN
     vex_mag_list, trange, verbose=verbose, l4=l4, file=rfile, time=rtime, level=lvl, resolution=res

     IF SIZE(rfile, /type) EQ 0 THEN BEGIN
        dprint, 'No data found.', dlevel=2, verbose=verbose
        RETURN
     ENDIF

     nfile = N_ELEMENTS(rfile)
     FOR i=0, nfile-1 DO BEGIN
        IF SIZE(files, /type) EQ 0 THEN dflg = 1 $
        ELSE BEGIN
           w = WHERE(STRMATCH(FILE_BASENAME(files), FILE_BASENAME(rfile[i])) EQ 1, nw)
           IF nw EQ 0 THEN dflg = 1 ELSE dflg = 0
        ENDELSE
        IF (dflg) THEN BEGIN
           suffix = FILE_BASENAME(rfile[i])
           suffix = STRSPLIT(suffix, '_', /extract)
           suffix = time_string(time_double(suffix[1], tformat='YYYYMMDD'), tformat='/YYYY/MM/')
           IF lvl EQ 'l2' THEN ldir = root_data_dir() + 'vex/mag/' + lvl + '/' + res + suffix $
           ELSE ldir = root_data_dir() + 'vex/mag/' + lvl + suffix

           append_array, file, spd_download(remote_file=rfile[i], local_path=ldir)
           file_touch, file[-1], rtime[i] - DOUBLE(time_zone_offset()) * 3600.d0, /mtime
        ENDIF ELSE append_array, file, files[w]
     ENDFOR
  ENDIF ELSE file = files

  w = WHERE(file NE '', nfile)
  IF nfile EQ 0 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No file found.'
     RETURN
  ENDIF ELSE file = file[w]

  result = list()
  FOR i=0, nfile-1 DO BEGIN
     OPENR, unit, file[i], /get_lun
     adata = STRARR(FILE_LINES(file[i]))
     READF, unit, adata
     FREE_LUN, unit
     w = WHERE(STRMID(adata, 0, 4) EQ 'END ', nw)
     IF nw EQ 1 THEN BEGIN
        adata = adata[w+2:*]
        aresult = STRSPLIT(adata, ' ', /extract)
        aresult = aresult.toarray()

        result.add, aresult
        undefine, aresult
     ENDIF 
     undefine, w, nw, adata
  ENDFOR 
  
  data = TEMPORARY(result.toarray(dim=1))
  time = time_double(REFORM(data[*, 0]), tformat='YYYY-MM-DDThh:mm:ss.fff')
  undefine, result

  w = WHERE(time GE trange[0] AND time LE trange[1], nw)
  IF nw EQ 0 THEN BEGIN
     dprint, 'Data not found in the specified time range.', dlevel=2, verbose=verbose
     RETURN
  ENDIF 
  data = data[w, *]
  time = time[w]

  IF lvl EQ 'l2' THEN BEGIN
     bis = FLOAT(data[*, 1:3])
     bis_t = FLOAT(REFORM(data[*, 4]))
     bos = FLOAT(data[*, 5:7])
     bos_t = FLOAT(REFORM(data[*, 8]))

     IF KEYWORD_SET(double) THEN BEGIN
        bis = DOUBLE(bis)
        bis_t = DOUBLE(bis_t)
        bos = DOUBLE(bos)
        bos_t = DOUBLE(bos_t)
     ENDIF 

     store_data, 'vex_mag_' + lvl + '_bsc_is_' + res, $
                 data={x: time, y: bis}, dlim={ytitle: 'VEX MAG (IS)', ysubtitle: 'Bsc [nT]', colors: 'bgr', datagap: dt*1.5, $
                                               labels: ['X', 'Y', 'Z'], labflag: -1, constant: 0, level: STRUPCASE(lvl), spice_frame: 'VEX_SPACECRAFT'}
     store_data, 'vex_mag_' + lvl + '_btot_is_' + res, data={x: time, y: bis_t}, dlim={ytitle: 'VEX MAG (IS)', ysubtitle: '|B| [nT]', level: STRUPCASE(lvl), datagap: dt*1.5}

     store_data, 'vex_mag_' + lvl + '_bsc_os_' + res, $
                 data={x: time, y: bos}, dlim={ytitle: 'VEX MAG (OS)', ysubtitle: 'Bsc [nT]', colors: 'bgr', datagap: dt*1.5, $
                                               labels: ['X', 'Y', 'Z'], labflag: -1, constant: 0, level: STRUPCASE(lvl), spice_frame: 'VEX_SPACECRAFT'}
     store_data, 'vex_mag_' + lvl + '_btot_os_' + res, data={x: time, y: bos_t}, dlim={ytitle: 'VEX MAG (OS)', ysubtitle: '|B| [nT]', level: STRUPCASE(lvl), datagap: dt*1.5}

     tclip, 'vex_mag_' + lvl + '_bsc_is_' + res, -9999., +9999., /over
     tclip, 'vex_mag_' + lvl + '_btot_is_' + res, -9999., +9999., /over
     tclip, 'vex_mag_' + lvl + '_bsc_os_' + res, -9999., +9999., /over
     tclip, 'vex_mag_' + lvl + '_btot_os_' + res, -9999., +9999., /over

     IF (vflg) THEN BEGIN
        vex_spice_load, verbose=verbose, /download_only
        vso_is = TRANSPOSE(spice_vector_rotate(TRANSPOSE(bis), time, 'VEX_SPACECRAFT', 'VSO', verbose=verbose))
        vso_os = TRANSPOSE(spice_vector_rotate(TRANSPOSE(bos), time, 'VEX_SPACECRAFT', 'VSO', verbose=verbose))
        
        store_data, 'vex_mag_' + lvl + '_bvso_is_' + res, $
                    data={x: time, y: vso_is}, dlim={ytitle: 'VEX MAG (IS)', ysubtitle: 'Bvso [nT]', colors: 'bgr', datagap: dt*1.5, $
                                                  labels: ['X', 'Y', 'Z'], labflag: -1, constant: 0, level: STRUPCASE(lvl), spice_frame: 'VSO'}
        store_data, 'vex_mag_' + lvl + '_bvso_os_' + res, $
                    data={x: time, y: vso_os}, dlim={ytitle: 'VEX MAG (OS)', ysubtitle: 'Bvso [nT]', colors: 'bgr', datagap: dt*1.5, $
                                                  labels: ['X', 'Y', 'Z'], labflag: -1, constant: 0, level: STRUPCASE(lvl), spice_frame: 'VSO'}

        tclip, 'vex_mag_' + lvl + '_bvso_is_' + res, -9999., +9999., /over
        tclip, 'vex_mag_' + lvl + '_bvso_os_' + res, -9999., +9999., /over
     ENDIF 
  ENDIF ELSE BEGIN
     bx = FLOAT(REFORM(data[*, 1]))
     by = FLOAT(REFORM(data[*, 2]))
     bz = FLOAT(REFORM(data[*, 3]))
     btot = FLOAT(REFORM(data[*, 4]))
     
     IF KEYWORD_SET(double) THEN BEGIN
        bx = DOUBLE(bx)
        by = DOUBLE(by)
        bz = DOUBLE(bz)
        btot = DOUBLE(btot)
     ENDIF 
     
     store_data, 'vex_mag_' + lvl + '_bvso_' + res, $
                 data={x: time, y: [ [bx], [by], [bz] ]}, dlim={ytitle: 'VEX MAG', ysubtitle: 'Bvso [nT]', colors: 'bgr', datagap: dt*1.5, $
                                                                labels: ['X', 'Y', 'Z'], labflag: -1, constant: 0, level: STRUPCASE(lvl)}
     store_data, 'vex_mag_' + lvl + '_btot_' + res, data={x: time, y: btot}, dlim={ytitle: 'VEX MAG', ysubtitle: '|B| [nT]', level: STRUPCASE(lvl), datagap: dt*1.5}
     
     tclip, 'vex_mag_' + lvl + '_bvso_' + res, -9999., +9999., /over
     tclip, 'vex_mag_' + lvl + '_btot_' + res, -9999., +9999., /over
     
     IF (rflg) THEN BEGIN
        get_data, 'vex_mag_' + lvl + '_btot_' + res, data=d, dl=dl, lim=lim
        w = WHERE(FINITE(d.y))
        store_data, 'vex_mag_' + lvl + '_btot_' + res, data={x: d.x[w], y: d.y[w]}, dl=dl, lim=lim
        
        get_data, 'vex_mag_' + lvl + '_bvso_' + res, data=d, dl=dl, lim=lim
        store_data, 'vex_mag_' + lvl + '_bvso_' + res, data={x: d.x[w], y: d.y[w, *]}, dl=dl, lim=lim
     ENDIF 
     result = {time: time, mag: [ [bx], [by], [bz] ]}
     IF (pflg) THEN BEGIN
        px = FLOAT(REFORM(data[*, 5]))
        py = FLOAT(REFORM(data[*, 6]))
        pz = FLOAT(REFORM(data[*, 7]))
        alt = FLOAT(REFORM(data[*, 8]))
        
        store_data, 'vex_eph_vso_' + res, data={x: time, y: ([ [px], [py], [pz] ])/rv}, $
                    dlim={ytitle: 'VEX POS', ysubtitle: 'VSO [Rv]', colors: 'bgr', $
                          labels: ['X', 'Y', 'Z'], labflag: -1, constant: 0, format: '(f0.2)'}
        store_data, 'vex_eph_alt_' + res, data={x: time, y: (alt-rv)}, dlim={ytitle: 'VEX', ysubtitle: 'Alt. [km]', ylog: 1}
        
        extract_tags, result, {pos: [ [px], [py], [pz] ], alt: alt}
     ENDIF 
  ENDELSE 
  RETURN
END
