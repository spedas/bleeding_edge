;+
;
;PROCEDURE:       VEX_ASP_ELS_BKG
;
;PURPOSE:         Loads the VEX/ASPERA-4/ELS background data from NASA/PDS.
;
;INPUTS:          Time range to be loaded.
;
;KEYWORDS:
;
;NOTE:            See, https://pds-ppi.igpp.ucla.edu/data/vex-aspera4-els/
;
;CREATED BY:      Takuya Hara on 2023-07-02.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2023-07-03 23:22:46 -0700 (Mon, 03 Jul 2023) $
; $LastChangedRevision: 31932 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/vex/aspera/vex_asp_els_bkg.pro $
;
;-
PRO vex_asp_els_bkg_list, lists, verbose=verbose, update=update
  tnow = SYSTIME(/sec)
  rpath = 'https://pds-ppi.igpp.ucla.edu/data/vex-aspera4-els'
  ldir  = root_data_dir() + 'vex/aspera/els/bkg/'
  file_mkdir2, ldir
  fname = 'vex_asp_els_bkg_lists'

  IF KEYWORD_SET(update) THEN GOTO, making
  
  IF FILE_TEST(ldir + fname + '.sav') THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'Restoring: ' + ldir + fname + '.sav.'
     RESTORE, ldir + fname + '.sav'
     RETURN
  ENDIF

  making:
  dprint, dlevel=2, verbose=verbose, 'Making the full file lists of the ELS background data...'
  subdir = 'data_' + ['derived', 'eng', 'raw'] 
  phases = ['nominal', 'ext' + ['1', '2', '3', '4']]

  months = ORDEREDHASH()
  FOR i=0, N_ELEMENTS(phases)-1 DO BEGIN
     cmd = ([rpath, subdir[0], phases[i]]).join('/')
     lfile = spd_download(remote_path=cmd, local_path=ldir, local_file=fname + '.txt')
     
     OPENR, unit, lfile, /get_lun
     info = STRARR(FILE_LINES(lfile))
     READF, unit, info
     FREE_LUN, unit

     info = info[8:-3]
     idx  = info.indexof('href="') + 6
     months[phases[i]] = info.substring(idx, idx + 16)
     undefine, info, idx
  ENDFOR

  data = ORDEREDHASH()
  FOR i=0, N_ELEMENTS(subdir)-1 DO BEGIN
     data2 = ORDEREDHASH()
     ;IF i EQ 0 THEN suffix = '.TAB' ELSE suffix = '.CSV'
     FOR j=0, N_ELEMENTS(phases)-1 DO BEGIN
        ndir = N_ELEMENTS(months[phases[j]])        
        data3 = ORDEREDHASH()
        FOR k=0, ndir-1 DO BEGIN
           data4 = ORDEREDHASH()
           cmd = ([rpath, subdir[i], phases[j], months[phases[j], k]]).join('/')
           lfile = spd_download(remote_path=cmd, local_path=ldir, local_file=fname + '.txt')
           
           OPENR, unit, lfile, /get_lun
           info = STRARR(FILE_LINES(lfile))
           READF, unit, info
           FREE_LUN, unit

           w = WHERE(info.matches('.TAB|.CSV') EQ 1, nw)
           IF nw GT 0 THEN BEGIN
              info = info[w]

              files = info.extract('<a href[^>]+>')
              files = files.extract('"(.*)+"')
              files = files.substring(1, -2)
              
              ;is = info.indexof('href="') + 6
              ;ie = info.indexof(suffix) + 3
              ;files = info.substring(is, ie)

              idx = info.lastindexof('</a>')
              info = info.substring(idx)
              info = STRSPLIT(info, ' ', /extract)
              info = info.toarray()
              mtime = time_double(info[*, -3] + '/ ' + info[*, -2])
              
              data4['file'] = TEMPORARY(files)
              data4['time'] = TEMPORARY(mtime)              
              data3[months[phases[j], k]] = TEMPORARY(data4)
           ENDIF
           undefine, info, w, nw
        ENDFOR
        data2[phases[j]] = TEMPORARY(data3)
     ENDFOR
     data[subdir[i]] = TEMPORARY(data2)
  ENDFOR 

  lists = TEMPORARY(data)
  dprint, dlevel=2, verbose=verbose, 'Saving the full file lists of the ELS background data: ' + time_string(SYSTIME(/sec)-tnow, tformat='(hh:mm:ss.fff)')
  SAVE, lists, filename=ldir + fname + '.sav', /compress
  FILE_DELETE, lfile
  RETURN
END 
  
PRO vex_asp_els_bkg_load, trange, lists=lists, files=files, verbose=verbose
  tnow = SYSTIME(/sec)
  oneday = 86400.d0

  rpath = 'https://pds-ppi.igpp.ucla.edu/data/vex-aspera4-els/'
  ldir  = root_data_dir() + 'vex/aspera/els/bkg/'
  file_mkdir2, ldir
  
  phases = ((lists['data_derived']).keys()).toarray()
  
  mtime = ['2005-11', '2007-10-03', '2009-06', '2010-09', '2013']
  mtime = time_double(mtime)
  date = time_double(time_intervals(trange=trange + [-1., 1.]*oneday, /daily_res, tformat='YYYY-MM-DD'))
  ip = FIX(INTERP(FINDGEN(N_ELEMENTS(mtime)), mtime, time_double(date))) < (N_ELEMENTS(mtime)-1)

  pdirs = phases[ip]
  FOR i=0, N_ELEMENTS(date)-1 DO BEGIN
     months = (lists['data_derived', pdirs[i]]).keys()
     months = months.toarray()
     smonth = time_double(months.substring(0, 8))
     
     im = FIX(INTERP(FINDGEN(N_ELEMENTS(smonth)), smonth, time_double(date[i]))) < (N_ELEMENTS(smonth)-1)
     append_array, mdirs, months[im]
  ENDFOR 

  sdirs  = 'data_' + ['derived', 'raw', 'eng']
  prefix = 'ELS' + ['05BK', '*RBCNF', '*RTHR', '*RCNTS', '*RSTPS']
  ldirs = ['bcnf', 'thrs', 'cnts', 'engy']

  efile = ORDEREDHASH('remote', LIST(), 'local', LIST(), 'n', 0)
  cfile = ORDEREDHASH('remote', LIST(), 'local', LIST(), 'n', 0)
  tfile = ORDEREDHASH('remote', LIST(), 'local', LIST(), 'n', 0)
  dfile = ORDEREDHASH('remote', LIST(), 'local', LIST(), 'n', 0)
  FOR i=0, N_ELEMENTS(date)-1 DO BEGIN
     w = WHERE( STRMATCH(lists['data_eng', pdirs[i], mdirs[i], 'file'], prefix[-1] + time_string(date[i], tformat='_YYYYDOY') + '*') EQ 1, nw)
     IF nw GT 0 THEN BEGIN
        ;efile['time'].add, lists['data_eng', pdirs[i], mdirs[i], 'time', w], /extract
        efile['remote'].add, sdirs[-1] + '/' + pdirs[i] + '/' + mdirs[i] + '/' + lists['data_eng', pdirs[i], mdirs[i], 'file', w], /extract
        efile['local'].add, ldir + ldirs[-1] + time_string(date[i], tformat='/YYYY/MM/') + lists['data_eng', pdirs[i], mdirs[i], 'file', w], /extract
     ENDIF
     efile['n'] += nw

     w = WHERE( STRMATCH(lists['data_raw', pdirs[i], mdirs[i], 'file'], prefix[-2] + time_string(date[i], tformat='_YYYYDOY') + '*') EQ 1, nw)
     IF nw GT 0 THEN BEGIN
        ;cfile['time'].add, lists['data_raw', pdirs[i], mdirs[i], 'time', w], /extract
        cfile['remote'].add, sdirs[-2] + '/' + pdirs[i] + '/' + mdirs[i] + '/' + lists['data_raw', pdirs[i], mdirs[i], 'file', w], /extract
        cfile['local'].add, ldir + ldirs[-2] + time_string(date[i], tformat='/YYYY/MM/') + lists['data_raw', pdirs[i], mdirs[i], 'file', w], /extract
     ENDIF 
     cfile['n'] += nw
     
     w = WHERE( STRMATCH(lists['data_derived', pdirs[i], mdirs[i], 'file'], prefix[-3] + time_string(date[i], tformat='_YYYYDOY') + '*') EQ 1, nw)
     IF nw GT 0 THEN BEGIN
        ;tfile['time'].add, lists['data_derived', pdirs[i], mdirs[i], 'time', w], /extract
        tfile['remote'].add, sdirs[-3] + '/' + pdirs[i] + '/' + mdirs[i] + '/' + lists['data_derived', pdirs[i], mdirs[i], 'file', w], /extract
        tfile['local'].add, ldir + ldirs[-3] + time_string(date[i], tformat='/YYYY/MM/') + lists['data_derived', pdirs[i], mdirs[i], 'file', w], /extract
     ENDIF 
     tfile['n'] += nw
     
     w = WHERE( STRMATCH(lists['data_derived', pdirs[i], mdirs[i], 'file'], prefix[-4] + time_string(date[i], tformat='_YYYYDOY') + '*') EQ 1, nw)
     IF nw GT 0 THEN BEGIN
        ;dfile['time'].add, lists['data_derived', pdirs[i], mdirs[i], 'time', w], /extract
        dfile['remote'].add, sdirs[-3] + '/' + pdirs[i] + '/' + mdirs[i] + '/' + lists['data_derived', pdirs[i], mdirs[i], 'file', w], /extract
        dfile['local'].add, ldir + ldirs[-4] + time_string(date[i], tformat='/YYYY/MM/') + lists['data_derived', pdirs[i], mdirs[i], 'file', w], /extract
     ENDIF
     dfile['n'] += nw
  ENDFOR 

  IF efile['n'] GT 0 THEN energy = spd_download(remote_file=rpath + efile['remote'].toarray(), local_file=efile['local'].toarray())
  IF cfile['n'] GT 0 THEN counts = spd_download(remote_file=rpath + cfile['remote'].toarray(), local_file=cfile['local'].toarray())
  IF tfile['n'] GT 0 THEN thres  = spd_download(remote_file=rpath + tfile['remote'].toarray(), local_file=tfile['local'].toarray())
  IF dfile['n'] GT 0 THEN dflux  = spd_download(remote_file=rpath + dfile['remote'].toarray(), local_file=dfile['local'].toarray())

  nfile = MAX([ efile['n'], cfile['n'], tfile['n'], dfile['n'] ])
  IF nfile GT 0 THEN files = ORDEREDHASH('energy', energy, 'counts', counts, 'thres', thres, 'dflux', dflux, 'nfile', nfile) ELSE files = ORDEREDHASH('nfile', nfile)
  RETURN
END

PRO vex_asp_els_bkg, itime, verbose=verbose, no_server=no_server, update=update, $
                     stime=stime, etime=etime, energy=energy, counts=counts, gfactor=gfactor, bkg=bkg, $
                     nenergy=nenergy, mode=mode, dflux=dflux, thres=thres, fill_nan=fill_nan, status=success

  tnow = SYSTIME(/sec)
  oneday = 86400.d0
  success = 1
  
  IF undefined(itime) THEN get_timespan, trange $
  ELSE BEGIN
     trange = itime
     IF is_string(trange) THEN trange = time_double(trange)
  ENDELSE

  IF N_ELEMENTS(trange) EQ 1 THEN append_array, trange, trange + oneday
  IF KEYWORD_SET(no_server) THEN nflg = 0 ELSE nflg = 1

  vex_asp_els_bkg_list, lists, verbose=verbose, update=update
  vex_asp_els_bkg_load, trange, lists=lists, files=files, verbose=verbose

  IF files['nfile'] EQ 0 THEN BEGIN
     dprint, 'No file found.', dlevel=2, verbose=verbose
     success = 0
     RETURN
  ENDIF 
  
  param = ['counts', 'thres', 'dflux', 'energy']
  FOR p=0, N_ELEMENTS(param)-1 DO BEGIN
     file = files[param[p]]
     file = file.sort()
     ftime = FILE_BASENAME(file)
     ftime = time_double(ftime.extract('[[:digit:]]{11}'), tformat='YYYYDOYhhmm')
  
     w = WHERE(file.matches('LR') EQ 1)  
     utime = ftime[w]
     
     data  = LIST()
     IF param[p] EQ 'counts' THEN BEGIN
        stime = LIST()
        etime = LIST()
     ENDIF 
     FOR i=0, N_ELEMENTS(utime)-1 DO BEGIN
        w = WHERE(ftime GE utime[i]-60.d0 AND ftime LE utime[i]+60.d0, nw)
        IF nw EQ 0 THEN CONTINUE

        dat = LIST()
        time = DICTIONARY('stime', LIST(), 'etime', LIST())
        FOR j=0, nw-1 DO BEGIN
           d = LIST()
           dprint, dlevel=2, verbose=verbose, 'Reading ' + file[w[j]]
           OPENR, unit, file[w[j]], /get_lun
           info = STRARR(FILE_LINES(file[w[j]]))
           READF, unit, info
           FREE_LUN, unit
           
           p0 = WHERE(info.matches('ELS-00') EQ 1, nscan)
           info = STRSPLIT(info, ',', /extract)

           nbin = info.map('n_elements')
           nbin = nbin.toarray()
           IF N_ELEMENTS(spd_uniq(nbin)) GT 1 THEN BEGIN
              dprint, dlevel=2, verbose=verbose, 'Warning: Number of data array is different in a single file.'
              v = WHERE(nbin LT MAX(nbin), nv)
              FOR iv=0L, nv-1 DO BEGIN
                 tmp = REPLICATE('nan', MAX(nbin))
                 tmp[0:nbin[v[iv]]-1] = info[v[iv]]
                 info[v[iv]] = TEMPORARY(tmp)
              ENDFOR 
           ENDIF 
           undefine, nbin
           
           info = info.toarray()
           FOR s=0, nscan-1 DO d.add, DOUBLE(info[p0[s]:p0[s]+15, 5:*])

           time.stime.add, time_double(info[p0, 0], tformat='YYYY-DOYThh:mm:ss.fff')
           time.etime.add, time_double(info[p0, 1], tformat='YYYY-DOYThh:mm:ss.fff')

           dat.add, d.toarray()
           undefine, d, info
        ENDFOR

        IF nw EQ 2 THEN BEGIN
           nh = N_ELEMENTS(time['etime', 0])
           nl = N_ELEMENTS(time['stime', 1])
           IF nh NE nl THEN BEGIN
              IF param[p] EQ 'counts' THEN dprint, dlevel=2, verbose=verbose, 'Warning: Total number of elements is different between HR and LR data.'
              IF nh GT nl THEN BEGIN
                 tmp = DBLARR(nh, 16, dimen1(TRANSPOSE(dat[1])))
                 tmp[*] = !values.d_nan
                 
                 n = nn2(time['etime', 0], time['stime', 1])
                 tmp[n, *, *] = dat[1]
                 dat[1] = TEMPORARY(tmp)

                 tmp = time['etime', 1]
                 time['etime', 1] = time['etime', 0]
                 time['etime', 1, n] = TEMPORARY(tmp)
              ENDIF ELSE BEGIN
                 ; nl > nh
                 tmp = DBLARR(nl, 16, dimen1(TRANSPOSE(dat[0])))
                 tmp[*] = !values.d_nan

                 n = nn2(time['stime', 1], time['etime', 0])
                 tmp[n, *, *] = dat[0]
                 dat[0] = TEMPORARY(tmp)

                 tmp = time['stime', 0]
                 time['stime', 0] = time['stime', 1]
                 time['stime', 0, n] = TEMPORARY(tmp)
              ENDELSE 
           ENDIF
           undefine, nh, nl
        ENDIF 

        IF param[p] EQ 'counts' THEN BEGIN
           IF nw EQ 1 THEN BEGIN
              stime.add, time['stime', 0]
              etime.add, time['etime', 0]
           ENDIF ELSE BEGIN
              stime.add, time['stime', 0]
              etime.add, time['etime', 1]
           ENDELSE 
        ENDIF 
                
        data.add, dat.toarray(dim=3)
        undefine, dat, time
     ENDFOR

     IF param[p] NE 'energy' THEN BEGIN
        cmd = param[p] + ' = TEMPORARY(data)'
        status = EXECUTE(cmd)
        undefine, cmd, status
     ENDIF 
  ENDFOR 

  ; Energy
  energy = counts[*]
  nenergy = LIST()
  mode    = LIST()
  FOR i=0, N_ELEMENTS(energy)-1 DO BEGIN
     ene = REFORM(data[i])
     IF ndimen(ene) EQ 3 THEN ene = MEAN(ene, /dim, /nan)
     energy[i] = TRANSPOSE(REBIN(ene, dimen1(ene), dimen2(ene), dimen1(energy[i]), /sample), [2, 0, 1])
     nenergy.add, REPLICATE(dimen2(ene), dimen1(energy[i]))
     IF dimen1(TRANSPOSE(ene)) GT 100 THEN mode.add, REPLICATE(0, dimen1(energy[i])) ELSE mode.add, REPLICATE(1, dimen1(energy[i]))
     undefine, ene
  ENDFOR 

  IF KEYWORD_SET(fill_nan) THEN BEGIN
     nan = !values.d_nan
     md = spd_uniq(mode.toarray(/dim))
     IF N_ELEMENTS(md) GT 1 THEN BEGIN
        FOR i=0, N_ELEMENTS(energy)-1 DO BEGIN
           IF MEAN(mode[i]) EQ 1 THEN BEGIN
              ndat = N_ELEMENTS(mode[i])
              nene = nenergy[i, 0]
              FOR p=0, N_ELEMENTS(param)-1 DO BEGIN
                 tmp = DBLARR(ndat, 16, 127)
                 tmp[*] = nan

                 cmd = 'tmp[*, *, 0:nene-1] = ' + param[p] + '[i]'
                 status = EXECUTE(TEMPORARY(cmd))
                 cmd = param[p] + '[i] = TEMPORARY(tmp)'
                 status = EXECUTE(TEMPORARY(cmd))
              ENDFOR
              undefine, ndat, nene
           ENDIF 
        ENDFOR 
     ENDIF 
  ENDIF 

  ; G-factor
  gfactor = thres[*]
  aa = 0.87d0
  dt = 3.6d0 / 128.d0
  FOR i=0, N_ELEMENTS(gfactor)-1 DO gfactor[i] = 1.d0 / (thres[i] * aa * energy[i] * dt)
     
  ; Background counts
  bkg = counts[*]
  FOR i=0, N_ELEMENTS(bkg)-1 DO bkg[i] = counts[i] - ( (dflux[i] / thres[i]) > 0.d0 )

  dprint, dlevel=2, verbose=verbose, 'All processing is completed: ' + time_string(SYSTIME(/sec)-tnow, tformat='hh:mm:ss.fff')
  RETURN
END 
