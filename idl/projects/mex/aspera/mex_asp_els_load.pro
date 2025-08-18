;+
;
;PROCEDURE:       MEX_ASP_ELS_LOAD
;
;PURPOSE:         
;                 Loads MEX/ASPERA-3 (ELS) data from ESA/PSA.
;
;INPUTS:          Time range to be loaded.
;
;KEYWORDS:
;
;      SAVE:      If set, makes the IDL save file.
;
;        L2:      If set, L2 data is to be loaded.
;
;      WGET:      If set, wget command is used to download rather than spd_download(). 
;
; NO_SERVER:      If set, prevents any contact with the remote server.
;
;       PSA:      Downloads the ELS data from ESA/PSA. Default = 1.
;                 If set psa = 0, downloads from wustl instead.
;
;CREATED BY:      Takuya Hara on 2018-01-18.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2020-12-01 20:24:47 -0800 (Tue, 01 Dec 2020) $
; $LastChangedRevision: 29419 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mex/aspera/mex_asp_els_load.pro $
;
;-
PRO mex_asp_els_list, trange, verbose=verbose, save=save, l2=l2, wget=wflg, $
                      file=file, time=modify_time, psa=psa
  oneday = 86400.d0
  IF KEYWORD_SET(l2) THEN lflg = 0 ELSE lflg = 1

  ldir = root_data_dir() + 'mex/aspera/els/'
  IF (lflg) THEN ldir += 'l1b/' ELSE ldir += 'l2/'
  ldir += 'csv/'
  file_mkdir2, ldir

  mtime = ['2003-06-02', '2006-01', '2007-10', '2010', '2013', '2015', '2017', '2019']
  mtime = time_double(mtime)

  date = time_double(time_intervals(trange=trange + [-1., 1.]*oneday, /daily_res, tformat='YYYY-MM-DD'))
  phase = FIX(INTERP(FINDGEN(N_ELEMENTS(mtime)), mtime, time_double(date))) < (N_ELEMENTS(mtime)-1)
  phase = STRING(phase, '(I0)')

  w = WHERE(phase EQ '0', nw, complement=v, ncomplement=nv)
  IF nw GT 0 THEN phase[w] = ''
  IF nv GT 0 THEN phase[v] = '-EXT' + phase[v]

  pdir = 'MEX-M-ASPERA3-'       ; pdir stands for "phase dir".
  IF (lflg) THEN pdir += '2-EDR-' ELSE pdir += '3-RDR-'
  pdir += 'ELS'

  IF (psa) THEN BEGIN
     pdir += phase + '-V1.0/'
     dprint, dlevel=2, verbose=verbose, 'Starts connecting ESA/PSA FTP server...'
     rpath = 'ftp://psa.esac.esa.int/pub/mirror/MARS-EXPRESS/ASPERA-3/' 
  ENDIF ELSE BEGIN
     pdir += phase + '-v1/'
     pdir = STRLOWCASE(pdir)
     rpath = 'https://pds-geosciences.wustl.edu/mex/'
  ENDELSE 
  ndat = N_ELEMENTS(date)

  FOR i=0, ndat-1 DO BEGIN
     IF (wflg) THEN $
        cmd = 'wget --spider -N -r -nd -A "ELSSCI*' + $
              time_string(date[i], tformat='YYYYDOY') + '*.CSV" ' + rpath + pdir[i] + 'DATA/ELS_' $
     ELSE BEGIN
        IF (psa) THEN cmd = rpath + pdir[i] + 'DATA/ELS_' $
        ELSE BEGIN
           cmd = rpath + pdir[i] + 'mexasp_1'
           IF (lflg) THEN cmd += '1' ELSE cmd += '2'
           cmd += STRING(LONG(STRMID(phase[i], 0, 1, /reverse)), '(I2.2)') + '/data/els_'
        ENDELSE 
     ENDELSE 

     IF (lflg) THEN BEGIN 
        cmd += 'EDR_L1B_'
        IF (phase[i] NE '') THEN cmd += time_string(date[i], tformat='YYYY_MM/') $
        ELSE BEGIN
           IF (date[i] GE time_double('2004')) THEN cmd += STRUPCASE(time_string(date[i], tformat='MTHYYYY/')) $
           ELSE IF LONG(time_string(date[i], tformat='DOY')) GT 250 THEN cmd += 'IC/' ELSE cmd += 'NEV/'
        ENDELSE 
     ENDIF ELSE BEGIN
        cmd += 'RDR_L2_' + time_string(date[i], tformat='YYYY_')
        IF (date[i] GE time_double('2004')) THEN cmd += time_string(date[i], tformat='MM/') $
        ELSE IF LONG(time_string(date[i], tformat='DOY')) GT 250 THEN cmd += 'IC/' ELSE cmd += 'EV/'
     ENDELSE 
     IF (wflg) THEN BEGIN
        cmd += ' -o ' + ldir + 'mex_asp_els_lists.txt'
        SPAWN, cmd
        list_file = ldir + 'mex_asp_els_lists.txt'
     ENDIF ELSE BEGIN
        IF (psa EQ 0) THEN cmd = STRLOWCASE(cmd)
        dflg = 0
        IF SIZE(cmd_old, /type) EQ 0 THEN dflg = 1 $
        ELSE IF cmd NE cmd_old THEN dflg = 1
        IF (dflg) THEN BEGIN
           IF (psa) THEN list_file = spd_download(remote_path=cmd, remote_file='*', local_path=ldir, local_file='mex_asp_els_lists.txt', ftp_connection_mode=0) $
           ELSE list_file = spd_download(remote_path=cmd, local_path=ldir, local_file='mex_asp_els_lists.txt')
        ENDIF 
     ENDELSE 

     OPENR, unit, list_file, /get_lun
     text = STRARR(FILE_LINES(list_file))
     READF, unit, text
     FREE_LUN, unit

     IF (wflg) THEN w = WHERE(STRMATCH(STRMID(text, 0, 2), '--') EQ 1 AND STRMATCH(text, '*.CSV') EQ 1, nw) $
     ELSE BEGIN
        IF (psa) THEN BEGIN
           text = STRSPLIT(text, ' ', /extract)
           text = text.toarray()
           text[*, 6] = STRING(LONG(text[*, 6]), '(I2.2)')
           mod_time = time_double(text[*, 5] + text[*, 6] + text[*, 7], tformat='MTHDDYYYY')
           w = WHERE(STRMATCH(text[*, -1], 'ELSSCI*' + time_string(date[i], tformat='YYYYDOY') + '*.CSV') EQ 1, nw)
        ENDIF ELSE BEGIN
           otext = STRSPLIT(text[-1], '<', escape='>', /extract)
           otext = otext[1:-2]
           undefine, text
           FOR j=0, (0.5 * N_ELEMENTS(otext))-1 DO BEGIN
              mt = STRSPLIT(otext[2*j], ' ', /extract)
              mt_d = STRSPLIT(mt[-4], '/', /extract, escape='<')
              mt_d[-3] = STRSPLIT(mt_d[-3], '[A-za-z]', /regex, /extract)
              mt_d = time_double(STRING(LONG(mt_d[-3]), '(I2.2)') + STRING(LONG(mt_d[-2]), '(I2.2)') + mt_d[-1], tformat='MMDDYYYY')
              mt_t = STRSPLIT(mt[-3], ':', /extract)
              mt_t = LONG(mt_t[0]) * 3600.d0 + LONG(mt_t[1]) * 60.d0
              IF mt[3] EQ 'PM' THEN mt_t += 0.5 * oneday
              append_array, mod_time, mt_d + mt_t
              undefine, mt, mt_d, mt_t
              append_array, text, (STRSPLIT(otext[2*j+1], '"', /extract))[-1]
           ENDFOR 
           w = WHERE(STRMATCH(text, 'elssci*' + time_string(date[i], tformat='YYYYDOY') + '*.csv') EQ 1, nw)
        ENDELSE  
     ENDELSE

     IF nw GT 0 THEN BEGIN
        IF (wflg) THEN BEGIN
           afile = text[w]
           afile = STRSPLIT(afile, /extract)
           IF SIZE(afile, /type) EQ 7 THEN afile = afile[-1] $
           ELSE BEGIN
              afile = afile.toarray()
              afile = afile[*, -1]
           ENDELSE 
        ENDIF ELSE IF (psa) THEN afile = cmd + text[w, -1] ELSE afile = cmd + text[w]
     ENDIF 
     IF SIZE(afile, /type) NE 0 THEN BEGIN
        append_array, file, afile
        IF ~(wflg) THEN append_array, modify_time, mod_time[w]
     ENDIF 
     undefine, w, nw, text, afile
     cmd_old = cmd
  ENDFOR 
  RETURN
END

PRO mex_asp_els_save, time, counts, energy, l2=l2, file=file, mode=mode, nenergy=nenergy, verbose=verbose
  prefix = 'mex_asp_els_'
  IF KEYWORD_SET(l2) THEN lvl = 'l2' ELSE lvl = 'l1b'
  
  name  = (STRSPLIT(file[0], '_', /extract))[0]
  ftime = time_double(name, tformat='ELSSCI*YYYYDOYhhmmC')
  
  path  = root_data_dir() + 'mex/aspera/els/' + lvl + '/sav/' + time_string(ftime, tformat='YYYY/MM/')
  fname = prefix + lvl + '_' + time_string(ftime, tformat='YYYYMMDD_hhmm') + '.sav'
  
  asp_els_stime = REFORM(time[*, 0])
  asp_els_etime = REFORM(time[*, 1])

  asp_els_cnts  = counts
  asp_els_engy  = energy

  asp_els_mode  = mode
  asp_els_nene  = nenergy

  file_mkdir2, path, dlevel=2, verbose=verbose
  dprint, dlevel=2, verbose=verbose, 'Saving ' + path + fname + '.'
  asp_els_file = file
  SAVE, filename=path + fname, asp_els_stime, asp_els_etime, asp_els_file, $
        asp_els_cnts, asp_els_engy, asp_els_mode, asp_els_nene, /compress

  RETURN
END

PRO mex_asp_els_com, time, counts, energy, l2=l2, mode=mode, verbose=verbose, $
                     data=asp_els_dat, trange=trange, nenergy=nenergy

  COMMON mex_asp_dat, mex_asp_ima, mex_asp_els
  IF KEYWORD_SET(l2) THEN units = 'flux' ELSE units = 'counts'

  stime = REFORM(time[*, 0])
  etime = REFORM(time[*, 1])
  
  dformat = {units_name: units, time: 0.d0, end_time: 0.d0, energy: DBLARR(127, 16), $
             nenergy: 0, gf: DBLARR(127, 16), data: FLTARR(127, 16), mode: 0}

  ndat = N_ELEMENTS(stime)
  asp_els_dat = REPLICATE(dformat, ndat)

  asp_els_dat.time     = stime
  asp_els_dat.end_time = etime
  asp_els_dat.energy = TRANSPOSE(energy, [2, 1, 0])
  asp_els_dat.data   = TRANSPOSE(counts, [2, 1, 0])

  asp_els_dat.nenergy = nenergy
  asp_els_dat.mode = mode

  IF SIZE(trange, /type) NE 0 THEN BEGIN
     mtime = MEAN(time, dim=2)
     w = WHERE(mtime GE trange[0] AND mtime LE trange[1], nw)
     asp_els_dat = asp_els_dat[w]
  ENDIF 

  mex_asp_els = asp_els_dat
  mex_asp_els_gf, gf, verbose=verbose
  asp_els_dat.gf = gf
  mex_asp_els = asp_els_dat
  RETURN
END

PRO mex_asp_els_read, trange, verbose=verbose, time=stime, end_time=etime, counts=counts, energy=energy, nenergy=nenergy, $
                      mode=mode, l2=l2, save=save, wget=wget, file=remote_file, mtime=modify_time, status=status, no_server=no_server
  oneday = 86400.d0
  nan = !values.f_nan
  status = 1
  IF KEYWORD_SET(wget) THEN wflg = 1 ELSE wflg = 0
  IF KEYWORD_SET(no_server) THEN nflg = 0 ELSE nflg = 1

  ;;; K-factor is the eV/volt for each ELS anode (sector) found in COLUMN 1 of the calibration table.
  kf = [ 7.167, 7.152, 7.141, 7.165, 7.188, 7.625, 7.262, 7.266, $
         7.275, 7.254, 7.262, 7.255, 7.255, 7.271, 7.253, 7.188  ]
  kf = DOUBLE(kf)

  IF KEYWORD_SET(l2) THEN lflg = 0 ELSE lflg = 1
  
  date = time_double(time_intervals(trange=trange + [-1., 1.]*oneday , /daily_res, tformat='YYYY-MM-DD'))

  ldir = root_data_dir() + 'mex/aspera/els/' 
  IF (lflg) THEN ldir += 'l1b/' ELSE ldir += 'l2/'
  ldir += 'csv/'
  spath = ldir + time_string(date, tformat='YYYY/MM/')

  FOR i=0, N_ELEMENTS(date)-1 DO BEGIN
     afile = FILE_SEARCH(spath[i], 'ELSSCIH*' + time_string(date[i], tformat='YYYYDOY') + '*.CSV', count=nfile)
     IF nfile GT 0 THEN append_array, hfile, afile
     undefine, afile, nfile
     afile = FILE_SEARCH(spath[i], 'ELSSCIL*' + time_string(date[i], tformat='YYYYDOY') + '*.CSV', count=nfile)
     IF nfile GT 0 THEN append_array, lfile, afile
     undefine, afile, nfile
  ENDFOR 
  
  IF SIZE(hfile, /type) NE 0 THEN append_array, file, hfile
  IF SIZE(lfile, /type) NE 0 THEN append_array, file, lfile

  IF (nflg) THEN mex_asp_els_timestamp, remote_file, rtime, verbose=verbose, /csv, /uniq
  IF SIZE(file, /type) EQ 0 THEN rflg = 1 $
  ELSE BEGIN
     mex_asp_els_timestamp, file, ltime, verbose=verbose, /csv, /uniq
     IF (nflg) THEN IF (N_ELEMENTS(rtime) EQ N_ELEMENTS(ltime)) AND (compare_struct(rtime, ltime) EQ 1) THEN rflg = 0 ELSE rflg = 1 ELSE rflg = 0
  ENDELSE 
  IF (rflg) THEN BEGIN
     nfile = N_ELEMENTS(remote_file)
     FOR i=0, nfile-1 DO BEGIN
        IF SIZE(file, /type) EQ 0 THEN dflg = 1 $
        ELSE BEGIN
           w = WHERE(STRMATCH(FILE_BASENAME(file), FILE_BASENAME(remote_file[i])) EQ 1, nw)
           IF nw EQ 0 THEN dflg = 1 ELSE dflg = 0
        ENDELSE 
        IF (dflg) THEN BEGIN
           suffix = FILE_BASENAME(remote_file[i])
           suffix = STRSPLIT(suffix, '_', /extract)
           suffix = time_string(time_double(suffix[0], tformat='ELSSCI*YYYYDOYhhmmC'), tformat='YYYY/MM/')
           IF (wflg) THEN BEGIN
              dprint, dlevel=2, verbose=verbose, 'Downloading ' + remote_file[i] + '.'
              SPAWN, 'wget -N -q ' + remote_file[i] + ' -P ' + ldir + suffix
              append_array, fname, ldir + suffix + FILE_BASENAME(remote_file[i])
           ENDIF ELSE BEGIN
              append_array, fname, spd_download(remote_file=remote_file[i], local_path=ldir+suffix, ftp_connection_mode=0)
              file_touch, fname[-1], modify_time[i] - DOUBLE(time_zone_offset()) * 3600.d0, /mtime
           ENDELSE
        ENDIF ELSE append_array, fname, file[w]
     ENDFOR
     w = WHERE(STRMATCH(FILE_BASENAME(fname), 'ELSSCIH*') EQ 1, nw, complement=v, ncomplement=nv)
     IF nw GT 0 THEN hfile = fname[w] ELSE undefine, hfile
     IF nv GT 0 THEN lfile = fname[v] ELSE undefine, lfile
     undefine, w, v, nw, nv
  ENDIF ELSE fname = file

  IF N_ELEMENTS(fname) EQ 0 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No data found.'
     RETURN
  ENDIF 

  mex_asp_els_timestamp, fname, ftime, /csv
  fname = fname[SORT(ftime)]
  ftime = ftime[SORT(ftime)]

  nfile = N_ELEMENTS(ftime)
  counts = list()
  energy = list()
  stime = list()
  etime = list()
  FOR i=0, nfile-1 DO BEGIN
     dprint, dlevel=2, verbose=verbose, 'Reading ' + fname[i] + '.'

     OPENR, unit, fname[i], /get_lun
     data = STRARR(FILE_LINES(fname[i]))
     READF, unit, data
     FREE_LUN, unit
        
     v = WHERE(STRMATCH(data, '*SCAN*') EQ 1, nv)
     IF nv GT 0 THEN BEGIN
        scan = STRSPLIT(data[v], ',', /extract)
        scan = scan.toarray()
        stime.add, time_double(scan[*, 0], tformat='YYYY-DOYThh:mm:ss.fff')
        etime.add, time_double(scan[*, 1], tformat='YYYY-DOYThh:mm:ss.fff')
     ENDIF 

     w = WHERE(STRMATCH(data, '*SENSOR*') EQ 1, nw)
     IF nw GT 0 THEN BEGIN
        sensor = STRSPLIT(data[w], ',', /extract)
        sensor = sensor.toarray()
        sensor = sensor[*, 6:-2]
        scan = scan[*, 6:*]
        nene = N_ELEMENTS(sensor[0, *])
        cnts = list()
        ene = list()
        FOR k=0L, nv-1L DO BEGIN
           cnts.add, FLOAT(sensor[16L*k:16L*k+15L, *])
           ene.add, kf # DOUBLE(scan[k, *])
        ENDFOR 
        counts.add, cnts.toarray()
        energy.add, ene.toarray()
     ENDIF 
     undefine, w, nw, v, nv
     undefine, scan, sensor, data
  ENDFOR 

  mex_asp_els_merge, stime, etime, counts, energy, file=fname, verbose=verbose, mode=mode, nenergy=nenergy
  IF KEYWORD_SET(save) THEN $
     FOR i=0, N_ELEMENTS(fname)-1 DO $
        mex_asp_els_save, [ [stime[i]], [etime[i]] ], counts[i], energy[i], $
                          file=fname[i], mode=mode[i], nenergy=nenergy[i], l2=l2, verbose=verbose

  RETURN
END

PRO mex_asp_els_merge, st, et, cnt, ene, file=file, mode=mode, verbose=verbose, nenergy=nenergy
  nan = !values.f_nan
  nfile = N_ELEMENTS(file)
  
  stime  = list()
  etime  = list()
  counts = list()
  energy = list()
  fname = list()
  
  tmin = MIN(st[0])
  tmax = MAX(et[0])
  i = 0
  WHILE i LE nfile-1 DO BEGIN
     IF (i NE nfile-1) THEN BEGIN
        IF MIN(st[i+1]) GT tmax OR MAX(et[i+1]) LT tmin THEN mflg = 0 ELSE mflg = 1
     ENDIF ELSE mflg = 0
 
     IF (mflg) THEN BEGIN
        IF STRMATCH(FILE_BASENAME(file[i]), 'ELSSCIH*', /fold_case) EQ 1 THEN BEGIN
           stime0 = st[i]
           etime0 = et[i]
           hcnts = cnt[i]
           hene  = ene[i]
           stime1 = st[i+1]
           etime1 = et[i+1]
           lcnts = cnt[i+1]
           lene  = ene[i+1]
        ENDIF ELSE BEGIN
           stime0 = st[i+1]
           etime0 = et[i+1]
           hcnts = cnt[i+1]
           hene  = ene[i+1]
           stime1 = st[i]
           etime1 = et[i]
           lcnts = cnt[i]
           lene  = ene[i]
        ENDELSE
 
        mtime0 = .5 * (stime0 + etime0)
        mtime1 = .5 * (stime1 + etime1)
        nene0 = N_ELEMENTS(hene[0, 0, *])
        nene1 = N_ELEMENTS(lene[0, 0, *])

        IF N_ELEMENTS(stime0) EQ N_ELEMENTS(stime1) THEN BEGIN
           stime.add, stime0
           etime.add, etime1
        ENDIF ELSE BEGIN
           IF N_ELEMENTS(stime0) GT N_ELEMENTS(stime1) THEN BEGIN
              n = nn(mtime0, mtime1)
              cnts = FLTARR(N_ELEMENTS(stime0), 16, nene1)
              cnts[*] = nan
              ener = cnts
              cnts[n, *, *] = lcnts
              ener[n, *, *] = lene
              lcnts = cnts
              lene = ener
              stime.add, stime0
              etime0[n] = etime1
              etime.add, etime0
           ENDIF ELSE BEGIN
              n = nn(mtime1, mtime0)
              cnts = FLTARR(N_ELEMENTS(stime1), 16, nene0)
              cnts[*] = nan
              ener = cnts
              cnts[n, *, *] = hcnts
              ener[n, *, *] = hene
              hcnts = cnts
              hene = ener
              etime.add, etime1
              stime1[n] = stime0
              stime.add, stime1
           ENDELSE
        ENDELSE
        cnts = [ [[hcnts]], [[lcnts]] ]
        engy = [ [[hene]],  [[lene]]  ]
        
        undefine, lcnts, hcnts, hene, lene, ener
        fname.add, FILE_BASENAME(file[i:i+1])
        i += 2
     ENDIF ELSE BEGIN
        stime.add, st[i]
        etime.add, et[i]
        cnts = cnt[i]
        engy = ene[i]
        fname.add, FILE_BASENAME(file[i])
        i += 1
     ENDELSE 

     IF i LE nfile-1 THEN BEGIN
        tmin = MIN(st[i])
        tmax = MAX(et[i])   
     ENDIF 
     
     ndat = N_ELEMENTS(cnts[*, 0, 0])
     nene = N_ELEMENTS(cnts[0, 0, *])
     append_array, nenergy, nene
     IF nene GT 31 THEN append_array, mode, 0 ELSE append_array, mode, 1
     counts.add, TEMPORARY(cnts)
     energy.add, TEMPORARY(engy)
  ENDWHILE

  undefine, st, et, cnt, ene
  ;;; Updating the loaded data
  st   = TEMPORARY(stime)
  et   = TEMPORARY(etime)
  cnt  = TEMPORARY(counts)
  ene  = TEMPORARY(energy)
  file = fname
  RETURN
END

PRO mex_asp_els_timestamp, files, time, verbose=verbose, csv=csv, sav=sav, unique=unique
  file = FILE_BASENAME(files)
  time = STRSPLIT(file, '_', /extract)
  IF SIZE(time, /type) NE 7 THEN lflg = 1 ELSE lflg = 0
  IF KEYWORD_SET(unique) THEN uflg = 1 ELSE uflg = 0
  IF (lflg) THEN time = time.toarray()

  IF KEYWORD_SET(csv) THEN BEGIN
     IF (lflg) THEN time = time[*, 0] ELSE time = time[0]
     time = time_double(time, tformat='ELSSCI*YYYYDOYhhmmC')
  ENDIF 

  IF KEYWORD_SET(sav) THEN BEGIN
     IF (lflg) THEN time = time[*, 4] + time[*, 5] ELSE time = time[4] + time[5]
     time = time_double(time, tformat='YYYYMMDDhhmm.sav')
  ENDIF 
  
  IF (uflg) THEN time = time[UNIQ(time, sort(time))]
  RETURN
END

PRO mex_asp_els_fill_nan, counts, energy, nenergy=nenergy, mode=mode
  nan = !values.f_nan
  nlist = N_ELEMENTS(nenergy)

  e = nenergy
  m = mode
  undefine, nenergy, mode
  nenergy = list()
  mode    = list()

  FOR i=0, nlist-1 DO BEGIN
     ndat = N_ELEMENTS((counts[i])[*, 0, 0])
     nenergy.add, REPLICATE(e[i], ndat)
     mode.add, REPLICATE(m[i], ndat)

     IF e[i] NE 127 THEN BEGIN
        cnts = FLTARR(ndat, 16, 127)
        cnts[*] = nan
        cnts[*, *, 0:e[i]-1] = counts[i]
        counts[i] = TEMPORARY(cnts)

        engy = DBLARR(ndat, 16, 127)
        engy[*] = nan
        engy[*, *, 0:e[i]-1] = energy[i]
        energy[i] = TEMPORARY(engy)
     ENDIF 
  ENDFOR 

  RETURN
END

PRO mex_asp_els_load, itime, verbose=verbose, l2=l2, save=save, wget=wget, no_server=no_server, psa=psa
  COMMON mex_asp_dat, mex_asp_ima, mex_asp_els
  undefine, mex_asp_els

  oneday = 86400.d0
  t0 = SYSTIME(/sec)
  IF SIZE(itime, /type) EQ 0 THEN get_timespan, trange $
  ELSE BEGIN
     trange = itime
     IF SIZE(trange, /type) EQ 7 THEN trange = time_double(trange)
  ENDELSE 
  IF KEYWORD_SET(l2) THEN lflg = 0 ELSE lflg = 1
  IF KEYWORD_SET(wget) THEN wflg = 1 ELSE wflg = 0
  IF KEYWORD_SET(no_server) THEN nflg = 0 ELSE nflg = 1
  IF (lflg) THEN lvl = 'l1b' ELSE lvl = 'l2'
  IF SIZE(psa, /type) EQ 0 THEN pflg = 1 ELSE pflg = FIX(psa)

  IF (nflg) THEN BEGIN
     mex_asp_els_list, trange, verbose=verbose, l2=l2, wget=wflg, file=remote_file, time=mtime, psa=pflg
     IF N_ELEMENTS(remote_file) EQ 0 THEN BEGIN
        dprint, 'No data found.', dlevel=2, verbose=verbose
        RETURN
     ENDIF 
  ENDIF 

  date = time_double(time_intervals(trange=trange + [-1., 1.]*oneday, /daily_res, tformat='YYYY-MM-DD'))
  path = root_data_dir() + 'mex/aspera/els/' + lvl + '/sav/' + time_string(date, tformat='YYYY/MM/') + $
         'mex_asp_els_*' + time_string(date, tformat='YYYYMMDD') + '*.sav'

  FOR i=0, N_ELEMENTS(date)-1 DO BEGIN
     afile = FILE_SEARCH(path[i], count=nfile)
     IF nfile GT 0 THEN append_array, file, afile
     undefine, afile, nfile
  ENDFOR

  IF SIZE(file, /type) NE 0 THEN BEGIN
     IF (nflg) THEN BEGIN
        FOR i=0, N_ELEMENTS(file)-1 DO BEGIN
           obj = OBJ_NEW('IDL_Savefile', file[i])
           obj -> RESTORE, 'asp_els_file'
           append_array, lfile, TEMPORARY(asp_els_file)
           OBJ_DESTROY, obj
        ENDFOR 
        lfile = lfile[SORT(lfile)]
        rfile = FILE_BASENAME(remote_file)
        rfile = rfile[SORT(rfile)]
        IF (compare_struct(STRUPCASE(rfile), STRUPCASE(lfile)) EQ 1) THEN sflg = 0 ELSE sflg = 1
     ENDIF ELSE sflg = 0
  ENDIF ELSE sflg = 1

  IF (sflg) THEN BEGIN
     mex_asp_els_read, trange, time=stime, end_time=etime, counts=counts, energy=energy, nenergy=nenergy, mode=mode, l2=l2,  $
                       verbose=verbose, save=save, wget=wflg, file=remote_file, mtime=mtime, status=status, no_server=no_server
     IF (status EQ 0) THEN RETURN
  ENDIF ELSE BEGIN
     stime = list()
     etime = list()
     energy = list()
     counts = list()
     FOR i=0, N_ELEMENTS(file)-1 DO BEGIN
        dprint, dlevel=2, verbose=verbose, 'Restoring ' + file[i] + '.'
        obj = OBJ_NEW('IDL_Savefile', file[i])
        vname = obj -> Names()
        v = WHERE(STRMATCH(vname, '*FILE') EQ 0)
        obj -> Restore, vname[v]
        stime.add,  TEMPORARY(asp_els_stime)
        etime.add,  TEMPORARY(asp_els_etime)
        energy.add, TEMPORARY(asp_els_engy)
        counts.add, TEMPORARY(asp_els_cnts)
        append_array, mode, TEMPORARY(asp_els_mode)
        append_array, nenergy, TEMPORARY(asp_els_nene)
        undefine, obj, vname, v
     ENDFOR 
  ENDELSE 

  mex_asp_els_fill_nan, counts, energy, nenergy=nenergy, mode=mode

  counts = counts.toarray(dim=1)
  energy = energy.toarray(dim=1)
  stime = stime.toarray(dim=1)
  etime = etime.toarray(dim=1)
  nenergy = nenergy.toarray(dim=1)
  mode = mode.toarray(dim=1)

  time = [ [stime], [etime] ]
  time = MEAN(time, dim=2)
  w = WHERE(time GE trange[0] AND time LE trange[1], nw)
  IF nw EQ 0 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No data found.'
     RETURN
  ENDIF ELSE BEGIN
     mex_asp_els_com, [ [stime], [etime] ], counts, energy, mode=mode, nenergy=nenergy, l2=l2, data=els, trange=trange
     time = time[w]
     cnt = els.data
     ene = els.energy
  ENDELSE 
      
  store_data, 'mex_asp_els_espec', data={x: time, y: TRANSPOSE(TOTAL(cnt, 2)), v: TRANSPOSE(MEAN(ene, dim=2))}, $
              dlim={spec: 1, datagap: 30.d0, ysubtitle: 'Energy [eV]', ytitle: 'MEX/ASPERA-3 (ELS)'} ;, $
                    ;ytickformat: 'exponent', ztickformat: 'exponent}
  ylim, 'mex_asp_els_espec', 1., 20.e3, 1, /def

  IF (lflg) THEN BEGIN
     zlim, 'mex_asp_els_espec', 1., 1.e3, 1, /def
     options, 'mex_asp_els_espec', ztitle='Counts [#]', /def
  ENDIF ELSE BEGIN
     zlim, 'mex_asp_els_espec', 1.e3, 1.e8, 1, /def
     options, 'mex_asp_els_espec', ztitle='FLUX!C[#/cm!E2!N s str eV]', /def
  ENDELSE 

  dprint, dlevel=2, verbose=verbose, 'Ellapsed time: ' + time_string(SYSTIME(/sec)-t0, tformat='mm:ss.fff')
  RETURN
END
