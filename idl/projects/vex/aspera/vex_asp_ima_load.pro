;+
;
;PROCEDURE:       VEX_ASP_IMA_LOAD
;
;PURPOSE:         
;                 Loads VEX/ASPERA-4 (IMA) data from ESA/PSA.
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
; $LastChangedDate: 2024-01-26 11:48:56 -0800 (Fri, 26 Jan 2024) $
; $LastChangedRevision: 32416 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/vex/aspera/vex_asp_ima_load.pro $
;
;-
PRO vex_asp_ima_list, trange, verbose=verbose, file=file, time=modify_time
  oneday = 86400.d0

  IF FILE_TEST(root_data_dir() + 'vex/aspera/ima/tab/vex_asp_ima_lists.sav') THEN $
     RESTORE, root_data_dir() + 'vex/aspera/ima/tab/vex_asp_ima_lists.sav' ELSE vex_asp_ima_lists = HASH()

  ldir = root_data_dir() + 'vex/aspera/ima/tab/'
  file_mkdir2, ldir

  mtime = ['2005-11', '2007-10-03', '2009-06', '2010-09', '2013']
  mtime = time_double(mtime)

  date = time_double(time_intervals(trange=trange + [-1.d0, 1.d0]*oneday, /daily_res, tformat='YYYY-MM-DD'))
  phase = FIX(INTERP(FINDGEN(N_ELEMENTS(mtime)), mtime, time_double(date))) < (N_ELEMENTS(mtime)-1)

  pdir = STRING(phase, '(I0)')
  w = WHERE(pdir EQ '0', nw, complement=v, ncomplement=nv)
  IF nw GT 0 THEN pdir[w] = ''
  IF nv GT 0 THEN pdir[v] = 'EXT' + pdir[v] + '-'
  pdir = 'VEX-V-SW-ASPERA-2-' + pdir + 'IMA-V1.0/' ; pdir stands for "phase dir".

  ;dprint, dlevel=2, verbose=verbose, 'Starts connecting ESA/PSA FTP server...'

  rpath = 'https://archives.esac.esa.int/psa/ftp/VENUS-EXPRESS/ASPERA4/'
  ndat = N_ELEMENTS(date)

  FOR i=0, ndat-1 DO BEGIN
     rdir = rpath + pdir[i] + 'DATA/'
     
     rflg = 0
     IF SIZE(rdir_old, /type) EQ 0 THEN rflg = 1 $
     ELSE IF rdir NE rdir_old THEN rflg = 1
     IF (rflg) THEN BEGIN
        IF vex_asp_ima_lists.haskey(phase[i]) THEN BEGIN
           subdir = (vex_asp_ima_lists[phase[i]]).keys()
           IF TYPENAME(subdir) EQ 'LIST' THEN subdir = subdir.toarray()
        ENDIF ELSE BEGIN
           list_dir = spd_download(remote_path=rdir, local_path=ldir, local_file='vex_asp_ima_lists.txt');, ftp_connection_mode=0)
           rdir_old = rdir

           OPENR, unit, list_dir, /get_lun
           text = STRARR(FILE_LINES(list_dir))
           READF, unit, text
           FREE_LUN, unit

           idx = WHERE(text.matches('<a href[^>]+>') EQ 1, nidx)
           IF nidx GT 0 THEN BEGIN
              text = (text.extract('<a href[^>]+>'))[idx]
              text = text[2:*]
              text = text.extract('"(.*)+"')
              subdir = text.substring(1, -3)

              FOR j=0, N_ELEMENTS(subdir)-1 DO BEGIN
                 IF (j EQ 0) THEN vex_asp_ima_lists += HASH(phase[i], HASH(subdir[j])) $
                 ELSE vex_asp_ima_lists[phase[i]] += HASH(subdir[j])
              ENDFOR
           ENDIF 
        ENDELSE 
        dir_time = STRSPLIT(REFORM(subdir), '_', /extract)
        dir_time = dir_time.toarray()
        dir_time = time_double(REFORM(dir_time[*, 0]), tformat='YYYYMMDD')
     ENDIF 

     subdir = subdir[SORT(dir_time)]
     dir_time = dir_time[SORT(dir_time)]
     w = FIX(INTERP(FINDGEN(N_ELEMENTS(dir_time)), dir_time, time_double(date[i]))) < (N_ELEMENTS(dir_time)-1)

     dflg = 0
     IF SIZE(subdir_old, /type) EQ 0 THEN dflg = 1 $
     ELSE IF subdir[w] NE subdir_old THEN dflg = 1
     IF (dflg) THEN BEGIN
        IF SIZE(vex_asp_ima_lists[phase[i], subdir[w]], /type) EQ 0 THEN BEGIN
           list_file = spd_download(remote_path=rdir + subdir[w] + '/', local_path=ldir, local_file='vex_asp_ima_lists.txt');, ftp_connection_mode=0)
           
           OPENR, unit, list_file, /get_lun
           text = STRARR(FILE_LINES(list_file))
           READF, unit, text
           FREE_LUN, unit
           
           idx = WHERE(text.matches('.LBL|.TAB') EQ 1, nidx)
           IF nidx GT 0 THEN BEGIN
              text = text[idx]

              mod_time = text.substring(text.indexof('align="right"') + 14, text.indexof('align="right"') + 29)
              mod_time = time_double(mod_time, tformat='YYYY-MM-DD hh:mm')
              
              text = text.extract('<a href[^>]+>')
              text = text.extract('"(.*)+"')
              text = text.substring(1, -2)
              
              vex_asp_ima_lists[phase[i], subdir[w]] = HASH('name', text, 'mtime', mod_time)
              SAVE, vex_asp_ima_lists, filename=root_data_dir() + 'vex/aspera/ima/tab/vex_asp_ima_lists.sav', /compress
           ENDIF 
        ENDIF ELSE BEGIN
           text     = vex_asp_ima_lists[phase[i], subdir[w], 'name']
           mod_time = vex_asp_ima_lists[phase[i], subdir[w], 'mtime']
        ENDELSE 
        subdir_old = subdir[w]
     ENDIF 

     w = WHERE(STRMATCH(text, 'IMA_M*_' + time_string(date[i], tformat='yyMMDD') + '*') EQ 1, nw)
     IF nw GT 0 THEN afile = rdir + subdir_old + '/' + text[w]

     IF SIZE(afile, /type) NE 0 THEN BEGIN
        append_array, file, afile
        append_array, modify_time, mod_time[w]
     ENDIF 
     undefine, w, nw, afile;, text
  ENDFOR 
  IF SIZE(list_file, /type) EQ 7 THEN FILE_DELETE, list_file
  RETURN
END

PRO vex_asp_ima_save, time, counts, polar, pacc, eprom, file=file, verbose=verbose, mtime=mtime
  prefix = 'vex_asp_ima_'
  
  name  = (STRSPLIT(file[0], '_', /extract))[2]
  ftime = time_double(name, tformat='yyMMDDhhmmss')
 
  path  = root_data_dir() + 'vex/aspera/ima/sav/' + time_string(ftime, tformat='YYYY/MM/')
  fname = prefix + time_string(ftime, tformat='YYYYMMDD_hhmmss') + '.sav'

  IF FILE_TEST(path + fname) THEN RETURN

  asp_ima_stime = time
  asp_ima_polar = polar
  asp_ima_pacc  = pacc
  asp_ima_cnts  = counts
  asp_ima_eprom = eprom
  asp_ima_file  = FILE_BASENAME(file)

  file_mkdir2, path, dlevel=2, verbose=verbose
  dprint, dlevel=2, verbose=verbose, 'Saving ' + path + fname + '.'
  SAVE, filename=path + fname, asp_ima_stime, asp_ima_polar, asp_ima_pacc, asp_ima_cnts, asp_ima_eprom, asp_ima_file, /compress

  IF ~undefined(mtime) THEN $
     file_touch, path + fname, mtime - DOUBLE(time_zone_offset()) * 3600.d0, /mtime

  RETURN
END

PRO vex_asp_ima_com, time, counts, polar, pacc, eprom, verbose=verbose, $
                     data=asp_ima_dat, trange=trange

  COMMON vex_asp_dat, vex_asp_ima, vex_asp_els
  units = 'counts'
  dt = 12.d0
  nenergy = 96
  nmass = 32
  nbins = 16

  stime = REFORM(time[*, 0])
  etime = REFORM(time[*, 1])

  dformat = {units_name: units, time: 0.d0, end_time: 0.d0, $
             energy: DBLARR(nenergy, nbins, nmass), $
             data: FLTARR(nenergy, nbins, nmass), polar: 0, pacc: 0, eprom: 0} ;, $
             ;theta: FLTARR(nenergy, nbins, nmass), bkg: FLTARR(nenergy, nbins, nmass)}

  ndat = N_ELEMENTS(stime)
  vex_asp_ima = REPLICATE(dformat, ndat)

  vex_asp_ima.time     = stime
  vex_asp_ima.end_time = etime
  vex_asp_ima.polar    = polar
  vex_asp_ima.pacc     = pacc
  vex_asp_ima.eprom    = eprom
  vex_asp_ima.data     = TRANSPOSE(counts, [1, 2, 3, 0])

  time = MEAN(time, dim=2)
  vex_asp_ima_ene_theta, time, verbose=verbose, energy=energy, eprom=eprom
  vex_asp_ima.energy = TRANSPOSE(TEMPORARY(energy), [1, 2, 3, 0])

  IF SIZE(trange, /type) NE 0 THEN BEGIN
     w = WHERE(time GE trange[0] AND time LE trange[1], nw)
     vex_asp_ima = vex_asp_ima[w]
  ENDIF

  asp_ima_dat = vex_asp_ima
  RETURN
END

PRO vex_asp_ima_read, trange, verbose=verbose, time=stime, counts=counts, polar=polar, pacc=pacc, eprom=eprom, $
                      save=save, file=remote_file, mtime=modify_time, status=status, no_server=no_server
  oneday = 86400.d0
  nan = !values.f_nan
  status = 1
  IF KEYWORD_SET(no_server) THEN nflg = 0 ELSE nflg = 1
  
  date = time_double(time_intervals(trange=trange + [-1., 1.]*oneday, /daily_res, tformat='YYYY-MM-DD'))

  ldir = root_data_dir() + 'vex/aspera/ima/tab/' 
  spath = ldir + time_string(date, tformat='YYYY/MM/')

  FOR i=0, N_ELEMENTS(date)-1 DO BEGIN
     afile = FILE_SEARCH(spath[i], 'IMA_M*' + time_string(date[i], tformat='yyMMDD') + '*', count=nfile)
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

  IF (rflg) THEN fname = FILE_BASENAME(remote_file) ELSE fname = file
  undefine, file

  w = WHERE(REFORM(((STRSPLIT(fname, '.', /extract)).toarray())[*, 1]) EQ 'TAB', nw, complement=v, ncomplement=nv)
  IF nw GT 0 THEN tfile = fname[w]
  IF nv GT 0 THEN lfile = fname[v]
  nfile = nw

  IF nw NE nv THEN BEGIN
     dprint, dlevel=2, verbose=verbose, ''
     status = 0
     RETURN
  ENDIF; ELSE undefine, w, v, nw, fname

  FOR i=0, nv-1 DO BEGIN
     IF (rflg) THEN BEGIN
        suffix = (STRSPLIT(lfile[i], '_', /extract))[2]
        suffix = time_string(time_double(suffix, tformat='yyMM'), tformat='YYYY/MM/')
        IF FILE_TEST(ldir + suffix + lfile[i]) EQ 0 THEN BEGIN
           lfile_download_again:
           lfile[i] = spd_download(remote_file=remote_file[v[i]], local_path=ldir+suffix);, ftp_connection_mode=0)
           IF (FILE_INFO(lfile[i])).size EQ 0 THEN GOTO, lfile_download_again
           file_touch, lfile[i], modify_time[v[i]] - DOUBLE(time_zone_offset()) * 3600.d0, /mtime
        ENDIF ELSE lfile[i] = ldir + suffix + lfile[i]
     ENDIF 

     OPENR, unit, lfile[i], /get_lun
     data = STRARR(FILE_LINES(lfile[i]))
     READF, unit, data
     FREE_LUN, unit

     iv = WHERE(STRMID(data, 0, 10) EQ 'START_TIME')
     data = (STRSPLIT(data[iv:iv+1], ' ', /extract)).toarray()
     tdata = time_double(data[*, 2], tformat='YYYY-MM-DDThh:mm:ss.fff')

     idx = INTERP([0., 1.], trange, tdata)
     iv = WHERE(MAX(idx) LT 0. OR MIN(idx) GT 1., niv)
     IF (niv EQ 0) OR (KEYWORD_SET(save)) THEN BEGIN
        IF (rflg) THEN BEGIN
           IF FILE_TEST(ldir + suffix + tfile[i]) EQ 0 THEN BEGIN
              tfile_download_again:
              tfile[i] = spd_download(remote_file=remote_file[w[i]], local_path=ldir+suffix);, ftp_connection_mode=0)
              IF (FILE_INFO(tfile[i])).size EQ 0 THEN GOTO, tfile_download_again
              file_touch, tfile[i], modify_time[w[i]] - DOUBLE(time_zone_offset()) * 3600.d0, /mtime
           ENDIF ELSE tfile[i] = ldir + suffix + tfile[i]
        ENDIF 
        append_array, file, tfile[i]
     ENDIF 
     undefine, data, tdata, idx, iv, niv
  ENDFOR

  IF SIZE(file, /type) EQ 0 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No data found.'
     status = 0
     RETURN
  ENDIF ELSE undefine, nv

  counts = list()
  stime  = list()
  polar  = list()
  pacc   = list()
  fname  = list()
  eprom  = list()
  FOR i=0, N_ELEMENTS(file)-1 DO BEGIN
     mode = STRMID((STRSPLIT(FILE_BASENAME(file[i]), '_', /extract))[1], 1, 2)
     CASE mode OF               ; phi, mass, energy, polar(=time)
        '24': nbins = LONG([16, 32, 96, 16])
        '25': nbins = LONG([16, 32, 96,  8])
        ELSE: BEGIN
           dprint, 'Unexpected error.', dlevel=2, verbose=verbose
           status = 0 
           RETURN
        END 
     ENDCASE

     dprint, dlevel=2, verbose=verbose, 'Reading ' + file[i] + '.'
     OPENR, unit, file[i], /get_lun
     data = STRARR(FILE_LINES(file[i]))
     READF, unit, data
     FREE_LUN, unit

     data = STRSPLIT(data, ' ', /extract)
     IF SIZE(data, /type) EQ 11 THEN ndat = N_ELEMENTS(data) ELSE ndat = 1
     fname.add, file[i]
     cnts = list()
     FOR j=0, ndat-1 DO BEGIN
        IF SIZE(data, /type) EQ 11 THEN onescan = data[j] ELSE onescan = data
        IF N_ELEMENTS(onescan[31:*]) EQ PRODUCT(nbins) THEN BEGIN
           t1scan = time_double(onescan[0], tformat='YYYY-MM-DDThh:mm:ss.fff')
           append_array, pac, REPLICATE(FLOAT(onescan[16]), nbins[-1])
           append_array, prm, REPLICATE(FIX(onescan[20]), nbins[-1])
           onescan = FLOAT(REFORM(onescan[31:*], nbins))
           onescan = TRANSPOSE(onescan, [3, 2, 0, 1]) ; polar(=time), energy, phi, mass
           cnts.add, TEMPORARY(onescan)
           
           IF (nbins[-1] EQ 8) THEN BEGIN
              append_array, time, t1scan + 2.d0 + dgen(range=[0.d0, 192.d0-24.d0], nbins[-1]) ; Based on IRF-Kiruna IDL save files.
              append_array, pol, INDGEN(nbins[-1])*2
           ENDIF
           IF (nbins[-1] EQ 16) THEN BEGIN
              append_array, time, t1scan + dgen(range=[12.d0, 192.d0], nbins[-1])
              append_array, pol, INDGEN(nbins[-1])
           ENDIF
        ENDIF 
     ENDFOR
     counts.add, cnts.toarray(/dim)
     pacc.add,  TEMPORARY(pac)
     stime.add, TEMPORARY(time)
     polar.add, TEMPORARY(pol)
     eprom.add, TEMPORARY(prm)
     undefine, data, cnts
  ENDFOR

  IF KEYWORD_SET(save) THEN BEGIN
     mtime = HASH(FILE_BASENAME(remote_file[0]), modify_time[0])
     FOR i=1, N_ELEMENTS(remote_file)-1 DO mtime += HASH(FILE_BASENAME(remote_file[i]), modify_time[i])

     FOR i=0, N_ELEMENTS(fname)-1 DO $
        vex_asp_ima_save, stime[i], counts[i], polar[i], pacc[i], eprom[i], file=fname[i], verbose=verbose, mtime=mtime[FILE_BASENAME(fname[i])]
     
     undefine, mtime
  ENDIF

  RETURN
END

PRO vex_asp_ima_load, itime, verbose=verbose, save=save, no_server=no_server
  COMMON vex_asp_dat, vex_asp_ima, vex_asp_els
  undefine, vex_asp_ima

  oneday = 86400.d0
  t0 = SYSTIME(/sec)
  IF SIZE(itime, /type) EQ 0 THEN get_timespan, trange $
  ELSE BEGIN
     trange = itime
     IF SIZE(trange, /type) EQ 7 THEN trange = time_double(trange)
  ENDELSE 
  IF KEYWORD_SET(no_server) THEN nflg = 0 ELSE nflg = 1

  IF (nflg) THEN BEGIN
     vex_asp_ima_list, trange, verbose=verbose, file=remote_file, time=mtime
     IF N_ELEMENTS(remote_file) EQ 0 THEN BEGIN
        dprint, 'No data found.', dlevel=2, verbose=verbose
        RETURN
     ENDIF 
  ENDIF 

  date = time_double(time_intervals(trange=trange + [-1.d0, 1.d0]*oneday, /daily_res, tformat='YYYY-MM-DD'))
  path = root_data_dir() + 'vex/aspera/ima/sav/' + time_string(date, tformat='YYYY/MM/') + $
         'vex_asp_ima_*' + time_string(date, tformat='YYYYMMDD') + '*.sav'

  FOR i=0, N_ELEMENTS(date)-1 DO BEGIN
     afile = FILE_SEARCH(path[i], count=nfile)
     IF nfile GT 0 THEN append_array, file, afile
     undefine, afile, nfile
  ENDFOR

  IF SIZE(file, /type) NE 0 THEN BEGIN
     IF (nflg) THEN BEGIN
        FOR i=0, N_ELEMENTS(file)-1 DO BEGIN
           obj = OBJ_NEW('IDL_Savefile', file[i])
           obj -> RESTORE, 'asp_ima_file'
           append_array, lfile, TEMPORARY(asp_ima_file)
           OBJ_DESTROY, obj
        ENDFOR 
        lfile = lfile[SORT(lfile)]
        rfile = FILE_BASENAME(remote_file)
        rfile = rfile[SORT(rfile)]
        
        lfile = FILE_BASENAME(lfile, '.TAB')
        rfile = spd_uniq(((STRSPLIT(rfile, '.', /extract)).toarray())[*, 0])
        IF compare_struct(rfile, lfile) AND (N_ELEMENTS(lfile) EQ N_ELEMENTS(rfile)) THEN sflg = 0 ELSE sflg = 1
     ENDIF ELSE sflg = 0
  ENDIF ELSE sflg = 1

  IF (sflg) THEN BEGIN
     vex_asp_ima_read, trange, time=stime, counts=counts, polar=polar, pacc=pacc, eprom=eprom, $
                       verbose=verbose, save=save, file=remote_file, mtime=mtime, status=status, no_server=no_server
     IF (status EQ 0) THEN RETURN
  ENDIF ELSE BEGIN
     stime  = list()
     counts = list()
     polar  = list()
     pacc   = list()
     eprom  = list()
     FOR i=0, N_ELEMENTS(file)-1 DO BEGIN
        dprint, dlevel=2, verbose=verbose, 'Restoring ' + file[i] + '.'
        obj = OBJ_NEW('IDL_Savefile', file[i])
        vname = obj -> Names()
        v = WHERE(STRMATCH(vname, '*FILE') EQ 0)
        obj -> Restore, vname[v]
        stime.add,  TEMPORARY(asp_ima_stime)
        counts.add, TEMPORARY(asp_ima_cnts)
        polar.add,  TEMPORARY(asp_ima_polar)
        pacc.add,   TEMPORARY(asp_ima_pacc)
        eprom.add,  TEMPORARY(asp_ima_eprom)
        undefine, obj, vname, v
     ENDFOR 
  ENDELSE 
 
  counts = counts.toarray(dim=1)
  stime  = stime.toarray(dim=1)
  polar  = polar.toarray(dim=1)
  pacc   = pacc.toarray(dim=1)
  eprom  = eprom.toarray(dim=1)
  etime = stime + 12.d0

  time = [ [stime], [etime] ]
  time = MEAN(time, dim=2)
  w = WHERE(time GE trange[0] AND time LE trange[1], nw)
  IF nw EQ 0 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No data found.'
     RETURN
  ENDIF ELSE BEGIN
     vex_asp_ima_com, [ [stime], [etime] ], counts, polar, pacc, data=ima, trange=trange, eprom
     time = time[w]
  ENDELSE 

  cnt = ima.data
  ene = ima.energy

  store_data, 'vex_asp_ima_espec', data={x: time, y: TRANSPOSE(TOTAL(TOTAL(cnt, 2), 2)), v: TRANSPOSE(MEAN(MEAN(ene, dim=2, /nan), dim=2, /nan))}, $
              dlim={spec: 1, datagap: 30.d0, ysubtitle: 'Energy [eV]', ytitle: 'VEX/ASPERA-4 (IMA)'}, limits={minzlog: 1}

  ylim, 'vex_asp_ima_espec', 10., 30.e3, 1, /def
  zlim, 'vex_asp_ima_espec', 1., 1.e4, 1, /def
  options, 'vex_asp_ima_espec', ztitle='Counts [#]', /def

  store_data, 'vex_asp_ima_polar', data={x: time, y: polar}, dlim={psym: 10, ytitle: 'VEX/ASPERA-4 (IMA)', ysubtitle: 'Polar'}, lim={datagap: 60.}

  dprint, dlevel=2, verbose=verbose, 'Ellapsed time: ' + time_string(SYSTIME(/sec)-t0, tformat='mm:ss.fff')
  RETURN
END
