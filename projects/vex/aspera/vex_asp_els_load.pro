;+
;
;PROCEDURE:       VEX_ASP_ELS_LOAD
;
;PURPOSE:         
;                 Loads VEX/ASPERA-4 (ELS) data from ESA/PSA.
;
;INPUTS:          Time range to be loaded.
;
;KEYWORDS:
;
;      SAVE:      If set, makes the IDL save file.
;
; NO_SERVER:      If set, prevents any contact with the remote server.
;
;CREATED BY:      Takuya Hara on 2017-04-15 -> 2018-04-16.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2020-10-15 14:28:20 -0700 (Thu, 15 Oct 2020) $
; $LastChangedRevision: 29257 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/vex/aspera/vex_asp_els_load.pro $
;
;-
PRO vex_asp_els_list, trange, verbose=verbose, save=save, file=file, time=modify_time
  oneday = 86400.d0
  ldir = root_data_dir() + 'vex/aspera/els/tab/'
  file_mkdir2, ldir

  mtime = ['2005-11', '2007-10-03', '2009-06', '2010-09', '2013']
  mtime = time_double(mtime)

  date = time_double(time_intervals(trange=trange + [-1., 1.]*oneday, /daily_res, tformat='YYYY-MM-DD'))
  phase = FIX(INTERP(FINDGEN(N_ELEMENTS(mtime)), mtime, time_double(date))) < (N_ELEMENTS(mtime)-1)
  phase = STRING(phase, '(I0)')

  w = WHERE(phase EQ '0', nw, complement=v, ncomplement=nv)
  IF nw GT 0 THEN phase[w] = ''
  IF nv GT 0 THEN phase[v] = '-EXT' + phase[v]
  pdir = 'VEX-V-SW-ASPERA-2' + phase + '-ELS-V1.0/' ; pdir stands for "phase dir".

  dprint, dlevel=2, verbose=verbose, 'Starts connecting ESA/PSA FTP server...'

  rpath = 'ftp://psa.esac.esa.int/pub/mirror/VENUS-EXPRESS/ASPERA4/'
  ndat = N_ELEMENTS(date)

  FOR i=0, ndat-1 DO BEGIN
     rdir = rpath + pdir[i] + 'DATA/'
     
     rflg = 0
     IF SIZE(rdir_old, /type) EQ 0 THEN rflg = 1 $
     ELSE IF rdir NE rdir_old THEN rflg = 1
     IF (rflg) THEN BEGIN
        list_dir = spd_download(remote_path=rdir, remote_file='*', local_path=ldir, local_file='vex_asp_els_lists.txt', ftp_connection_mode=0)
        rdir_old = rdir

        OPENR, unit, list_dir, /get_lun
        text = STRARR(FILE_LINES(list_dir))
        READF, unit, text
        FREE_LUN, unit

        text = STRSPLIT(text, ' ', /extract)
        text = text.toarray()
        subdir = REFORM(TEMPORARY(text[*, -1]))
        dir_time = STRSPLIT(REFORM(subdir), '_', /extract)
        dir_time = dir_time.toarray()
        dir_time = time_double(REFORM(dir_time[*, 0]), tformat='YYYYMMDD')
     ENDIF 

     w = FIX(INTERP(FINDGEN(N_ELEMENTS(dir_time)), dir_time, time_double(date[i]))) < (N_ELEMENTS(dir_time)-1)

     dflg = 0
     IF SIZE(subdir_old, /type) EQ 0 THEN dflg = 1 $
     ELSE IF subdir[w] NE subdir_old THEN dflg = 1
     IF (dflg) THEN list_file = spd_download(remote_path=rdir + subdir[w] + '/', remote_file='*', local_path=ldir, local_file='vex_asp_els_lists.txt', ftp_connection_mode=0)
     subdir_old = subdir[w]
  
     OPENR, unit, list_file, /get_lun
     text = STRARR(FILE_LINES(list_file))
     READF, unit, text
     FREE_LUN, unit

     text = STRSPLIT(text, ' ', /extract)
     text = text.toarray()
     text[*, 6] = STRING(LONG(text[*, 6]), '(I2.2)')
     mod_time = time_double(text[*, 5] + text[*, 6] + text[*, 7], tformat='MTHDDYYYY')
     
     w = WHERE(STRMATCH(text[*, -1], 'ELS_E*_' + time_string(date[i], tformat='yyMMDD') + '*.TAB') EQ 1, nw)
     
     IF nw GT 0 THEN afile = rdir + subdir_old + '/' + text[w, -1]

     IF SIZE(afile, /type) NE 0 THEN BEGIN
        append_array, file, afile
        append_array, modify_time, mod_time[w]
     ENDIF 
     undefine, w, nw, text, afile
  ENDFOR 
  IF SIZE(list_file, /type) EQ 7 THEN FILE_DELETE, list_file
  RETURN
END

PRO vex_asp_els_save, time, counts, file=file, mode=mode, verbose=verbose
  prefix = 'vex_asp_els_'
  
  name  = (STRSPLIT(file[0], '_', /extract))[2]
  ftime = time_double(name, tformat='yyMMDDhhmmss')
 
  path  = root_data_dir() + 'vex/aspera/els/sav/' + time_string(ftime, tformat='YYYY/MM/')
  fname = prefix + time_string(ftime, tformat='YYYYMMDD_hhmmss') + '.sav'
  
  asp_els_stime = REFORM(time[*, 0])
  asp_els_cnts  = counts
  asp_els_mode  = mode

  file_mkdir2, path, dlevel=2, verbose=verbose
  dprint, dlevel=2, verbose=verbose, 'Saving ' + path + fname + '.'
  asp_els_file = file
  SAVE, filename=path + fname, asp_els_stime, asp_els_cnts, asp_els_mode, asp_els_file

  RETURN
END

PRO vex_asp_els_com, time, counts, energy, mode=mode, verbose=verbose, $
                     data=asp_els_dat, trange=trange, nenergy=nenergy, nsweep=nsweep

  COMMON vex_asp_dat, vex_asp_ima, vex_asp_els
  units = 'counts'

  stime = REFORM(time[*, 0])
  etime = REFORM(time[*, 1])
  
  dformat = {units_name: units, time: 0.d0, end_time: 0.d0, energy: DBLARR(128, 16), $
             nenergy: 0, data: FLTARR(128, 16), mode: 0, nsweep: 0} ;, gf: DBLARR(128, 16)}

  ndat = N_ELEMENTS(stime)
  asp_els_dat = REPLICATE(dformat, ndat)

  asp_els_dat.time     = stime
  asp_els_dat.end_time = etime
  asp_els_dat.energy = TRANSPOSE(energy, [2, 1, 0])
  asp_els_dat.data   = TRANSPOSE(counts, [2, 1, 0])

  asp_els_dat.nenergy = nenergy
  asp_els_dat.mode = mode
  asp_els_dat.nsweep = nsweep
  IF SIZE(trange, /type) NE 0 THEN BEGIN
     mtime = MEAN(time, dim=2)
     w = WHERE(mtime GE trange[0] AND mtime LE trange[1], nw)
     asp_els_dat = asp_els_dat[w]
  ENDIF 

  vex_asp_els = asp_els_dat
  ;vex_asp_els_gf, gf, verbose=verbose
  ;asp_els_dat.gf = gf
  vex_asp_els = asp_els_dat
  RETURN
END

PRO vex_asp_els_read, trange, verbose=verbose, time=stime, counts=counts, mode=mode, nsweep=nsweep, $
                      save=save, file=remote_file, mtime=modify_time, status=status, no_server=no_server
  oneday = 86400.d0
  nan = !values.f_nan
  status = 1
  IF KEYWORD_SET(no_server) THEN nflg = 0 ELSE nflg = 1
  
  date = time_double(time_intervals(trange=trange + [-1., 1.]*oneday, /daily_res, tformat='YYYY-MM-DD'))

  ldir = root_data_dir() + 'vex/aspera/els/tab/' 
  spath = ldir + time_string(date, tformat='YYYY/MM/')

  FOR i=0, N_ELEMENTS(date)-1 DO BEGIN
     afile = FILE_SEARCH(spath[i], 'ELS_E*' + time_string(date[i], tformat='yyMMDD') + '*.TAB', count=nfile)
     IF nfile GT 0 THEN append_array, file, afile
     undefine, afile, nfile
  ENDFOR 
  
  IF SIZE(file, /type) EQ 0 THEN rflg = 1 $
  ELSE BEGIN
     IF (nflg) THEN $
        IF (N_ELEMENTS(file) EQ N_ELEMENTS(remote_file)) AND $
        (compare_struct(FILE_BASENAME(file[SORT(file)]), FILE_BASENAME(remote_file[SORT(remote_file)])) EQ 1) THEN $
           rflg = 0 ELSE rflg = 1 ELSE rflg = 0
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
           suffix = time_string(time_double(suffix[2], tformat='yyMMDDhhmmss'), tformat='YYYY/MM/')
           append_array, fname, spd_download(remote_file=remote_file[i], local_path=ldir+suffix, ftp_connection_mode=0)
           file_touch, fname[-1], modify_time[i] - DOUBLE(time_zone_offset()) * 3600.d0, /mtime
        ENDIF ELSE append_array, fname, file[w]
     ENDFOR
  ENDIF ELSE fname = file
  
  IF N_ELEMENTS(fname) EQ 0 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No data found.'
     status = 0
     RETURN
  ENDIF ELSE undefine, file

  w = WHERE(STRMATCH(FILE_BASENAME(fname), 'ELS_ENG*') EQ 0, nw, complement=v, ncomplement=nv)
  IF nw GT 0 THEN file  = fname[w]
  IF nv GT 0 THEN efile = fname[v]
  nfile = nw
  undefine, w, v, nw, nv, fname
  
  IF N_ELEMENTS(file) NE N_ELEMENTS(efile) THEN BEGIN
     dprint, dlevel=2, verbose=verbose, ''
     status = 0
     RETURN
  ENDIF

  file = file[SORT(file)]
  efile = efile[SORT(efile)]
  
  counts = list()
  stime  = list()
  etime  = list()
  mode   = list()
  fname  = list()
  nsweep = list()
  FOR i=0, nfile-1 DO BEGIN
     dprint, dlevel=2, verbose=verbose, 'Reading ' + file[i] + '.'
     
     OPENR, unit, file[i], /get_lun
     data = STRARR(FILE_LINES(file[i]))
     READF, unit, data
     FREE_LUN, unit
     
     data = STRSPLIT(data, ' ', /extract)
     data = data.toarray()

     stime.add, time_double(REFORM(data[*, 0]), tformat='YYYY-MM-DDThh:mm:ss.fff')
     ndat = N_ELEMENTS(data[*, 0])
     nsweep.add, FIX(REFORM(data[*, 4]))
     counts.add, FLOAT(REFORM(data[*, 12:*], ndat, 16, 128))
     undefine, data

     dprint, dlevel=2, verbose=verbose, 'Reading ' + efile[i] + '.'
     OPENR, unit, efile[i], /get_lun
     data = STRARR(FILE_LINES(efile[i]))
     READF, unit, data
     FREE_LUN, unit

     data = STRSPLIT(data, ' ', /extract)
     data = data.toarray()

     etime.add, time_double(REFORM(data[*, 0]), tformat='YYYY-MM-DDThh:mm:ss.fff')
     append_array, mnpot, MIN(LONG(REFORM(data[*, 18:*])), dim=2)
     undefine, data

     fname.add, [file[i], efile[i]]

     mnpot = mnpot[nn(etime[-1], stime[-1])]
     w = WHERE(mnpot LE 50, nw, complement=v, ncomplement=nv)
     amode = INTARR(N_ELEMENTS(mnpot))
     IF nw GT 0 THEN amode[w] = 0
     IF nv GT 0 THEN amode[v] = 1

     IF MEDIAN(amode) EQ 1 THEN BEGIN
        cnts = TRANSPOSE(counts[-1], [2, 1, 0])
        cnts = REFORM(cnts, 32, 4, 16, ndat)
        cnts = REFORM(TRANSPOSE(cnts, [0, 2, 1, 3]), 32, 16, ndat*4)
        counts[-1] = TRANSPOSE(TEMPORARY(cnts), [2, 1, 0])

        time = stime[-1]
        time = REFORM(TRANSPOSE([ [time], [time+1.d0], [time+2.d0], [time+3.d0] ]), ndat*4)
        stime[-1] = TEMPORARY(time)

        nsw = nsweep[-1]
        nsw = REFORM(TRANSPOSE(REBIN(nsweep[-1], ndat, 4)), ndat*4)
        nsweep[-1] = TEMPORARY(nsw)

        amode = REPLICATE(1, ndat*4)
     ENDIF 

     mode.add, amode
     undefine, mnpot, amode
     undefine, w, v, nw, nv
  ENDFOR

  IF KEYWORD_SET(save) THEN $
     FOR i=0, N_ELEMENTS(fname)-1 DO $
        vex_asp_els_save, stime[i], counts[i], file=fname[i], mode=mode[i], verbose=verbose

  RETURN
END

PRO vex_asp_els_fill_nan, stime, counts, energy, mode=mode, nenergy=nenergy
  nan = !values.f_nan
  nene = [128, 32]

  nlist = N_ELEMENTS(mode)
  nenergy = list()
  energy = list()

  FOR i=0, nlist-1 DO BEGIN
     IF N_ELEMENTS(spd_uniq(mode[i])) GT 1 THEN BEGIN
        w = WHERE(mode[i] EQ 0, nw, complement=v, ncomplement=nv)
        IF nw GT nv THEN BEGIN
           stime[i] = (stime[i])[w]
           counts[i] = (counts[i])[w, *, *]
           mode[i] = (mode[i])[w]
        ENDIF ELSE BEGIN
           stime[i] = (stime[i])[v]
           counts[i] = (counts[i])[v, *, *]
           mode[i] = (mode[i])[v]
        ENDELSE 
        undefine, w, v, nw, nv
     ENDIF 
     ndat = N_ELEMENTS((counts[i])[*, 0, 0])
     nenergy.add, nene[mode[i]]
     
     vex_asp_els_energy, engy
     engy = engy[mode[i]]  
     engy = engy.toarray()
     IF (nene[mode[i]])[0] NE 128 THEN BEGIN
        engy2 = TEMPORARY(engy)
        engy = DBLARR(ndat, 16, 128)
        engy[*] = nan
        engy[*, *, 0:31] = TEMPORARY(engy2)

        cnts = FLTARR(ndat, 16, 128)
        cnts[*] = nan
        cnts[*, *, 0:31] = counts[i]
        counts[i] = TEMPORARY(cnts)
     ENDIF 
     energy.add, TEMPORARY(engy)
  ENDFOR 
  RETURN
END

PRO vex_asp_els_load, itime, verbose=verbose, save=save, no_server=no_server, nsweep=isweep
  COMMON vex_asp_dat, vex_asp_ima, vex_asp_els
  undefine, vex_asp_els
  t0 = SYSTIME(/sec)
  IF SIZE(itime, /type) EQ 0 THEN get_timespan, trange $
  ELSE BEGIN
     trange = itime
     IF SIZE(trange, /type) EQ 7 THEN trange = time_double(trange)
  ENDELSE 
  IF KEYWORD_SET(no_server) THEN nflg = 0 ELSE nflg = 1

  IF (nflg) THEN BEGIN
     vex_asp_els_list, trange, verbose=verbose, file=remote_file, time=mtime
     IF N_ELEMENTS(remote_file) EQ 0 THEN BEGIN
        dprint, 'No data found.', dlevel=2, verbose=verbose
        RETURN
     ENDIF 
  ENDIF 

  date = time_double(time_intervals(trange=trange, /daily_res, tformat='YYYY-MM-DD'))
  path = root_data_dir() + 'vex/aspera/els/sav/' + time_string(date, tformat='YYYY/MM/') + $
         'vex_asp_els_*' + time_string(date, tformat='YYYYMMDD') + '*.sav'

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
        IF (compare_struct(rfile, lfile) EQ 1) THEN sflg = 0 ELSE sflg = 1
     ENDIF ELSE sflg = 0
  ENDIF ELSE sflg = 1

  IF (sflg) THEN BEGIN
     vex_asp_els_read, trange, time=stime, counts=counts, mode=mode, nsweep=nsweep, $
                       verbose=verbose, save=save, file=remote_file, mtime=mtime, status=status, no_server=no_server
     IF (status EQ 0) THEN RETURN
  ENDIF ELSE BEGIN
     stime = list()
     counts = list()
     mode = list()
     FOR i=0, N_ELEMENTS(file)-1 DO BEGIN
        dprint, dlevel=2, verbose=verbose, 'Restoring ' + file[i] + '.'
        obj = OBJ_NEW('IDL_Savefile', file[i])
        vname = obj -> Names()
        v = WHERE(STRMATCH(vname, '*FILE') EQ 0)
        obj -> Restore, vname[v]
        stime.add,  TEMPORARY(asp_els_stime)
        counts.add, TEMPORARY(asp_els_cnts)
        mode,add, TEMPORARY(asp_els_mode)
        undefine, obj, vname, v
     ENDFOR 
  ENDELSE 

  vex_asp_els_fill_nan, stime, counts, energy, mode=mode, nenergy=nenergy

  counts = counts.toarray(dim=1)
  stime = stime.toarray(dim=1)
  mode = mode.toarray(dim=1)
  nsweep = nsweep.toarray(dim=1)
  energy = energy.toarray(dim=1)
  nenergy = nenergy.toarray(dim=1)

  etime = nsweep * 4.d0^(1 - mode) + stime

  time = [ [stime], [etime] ]
  time = MEAN(time, dim=2)
  w = WHERE(time GE trange[0] AND time LE trange[1], nw)
  IF nw EQ 0 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No data found.'
     RETURN
  ENDIF ELSE BEGIN
     vex_asp_els_com, [ [stime], [etime] ], counts, energy, mode=mode, nenergy=nenergy, data=els, trange=trange, nsweep=nsweep
     time = time[w]
     cnt = els.data
     ene = els.energy
     nsw = els.nsweep
  ENDELSE 
  
  store_data, 'vex_asp_els_espec', data={x: time, y: TRANSPOSE(TOTAL(cnt, 2)), v: TRANSPOSE(MEAN(ene, dim=2))}, $
              dlim={spec: 1, datagap: 60.d0, ysubtitle: 'Energy [eV]', ytitle: 'VEX/ASPERA-4 (ELS)', $
                    ytickunits: 'scientific', ztickunits: 'scientific'}

  ylim, 'vex_asp_els_espec', 1., 20.e3, 1, /def
  zlim, 'vex_asp_els_espec', 1., 1.e3, 1, /def
  options, 'vex_asp_els_espec', ztitle='Counts [#]', /def

  IF KEYWORD_SET(isweep) THEN $
     store_data, 'vex_asp_els_nsweep', data={x: time, y: ALOG2(nsw)}, $
                 dlim={ytitle: 'VEX/ASPERA-4 (ELS)', ysubtitle: '2^N', psym: 10, yrange: [-.5, 5.5], ystyle: 1, yminor: 1, panel_size: .5, datagap: 60.d0}

  dprint, dlevel=2, verbose=verbose, 'Ellapsed time: ' + time_string(SYSTIME(/sec)-t0, tformat='mm:ss.fff')
  RETURN
END
