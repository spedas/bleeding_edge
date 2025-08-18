;+
;PROCEDURE:   mvn_swe_catalog
;PURPOSE:
;  Looks in the SWEA L2 data directories and builds a catalog of files
;  organized by type, year and month.
;
;USAGE:
;  mvn_swe_catalog
;
;INPUTS:
;       None.
;
;KEYWORDS:
;       VERSION:       Look for L2 files with this version number.
;                      Default is to use the current release version.
;
;       REVISION:      Look for L2 files with this revision number.
;                      Default is to look for the latest revision.
;
;       MTIME:         Look for L2 files modified after this time.
;                      Default is to look for all files regardless of
;                      modification time.
;
;       RESULT:        Named variable to hold the result structure
;                      containing all valid file names organized by
;                      type, year and month.
;
;       VERBOSE:       Print out number of files of each type by
;                      year and month.  This is the main point, so 
;                      the default is 1 (yes).
;
;       TOUCH:         Change the access and modification times of 
;                      all files collected in RESULT to the current
;                      time.  This can be used to "encourage" file
;                      transfers to the SDC.  Works only in unix-like
;                      environments.  Use with caution!
;
;       TRANGE:        Search for files only within this time range.
;                      Only year, month, day are used.
;
;       DATES:         Search only for specific dates.  Can be an array
;                      in any format accepted by time_double.
;
;       PDS:           Search for files only in this PDS release
;                      number or range.
;
;       DROPBOX:       Place copies of the files into the dropbox.
;                      This will force immediate delivery to the SDC.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-05-12 16:29:11 -0700 (Sun, 12 May 2024) $
; $LastChangedRevision: 32577 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_catalog.pro $
;
;CREATED BY:    David L. Mitchell  04-25-13
;FILE: mvn_swe_catalog.pro
;-
pro mvn_swe_catalog, version=version, revision=revision, mtime=mtime, result=dat, $
                     verbose=verbose, touch=touch, trange=trange, dates=dates, pds=pds, $
                     dropbox=dropbox

; Process keywords

  if (size(version,/type) eq 0) then ver = '??' else ver = string(version, format='(i2.2)')
  if (size(revision,/type) eq 0) then rev = '??' else rev = string(revision, format='(i2.2)')
  if (size(verbose,/type) eq 0) then blab = 1 else blab = keyword_set(verbose)
  if (size(mtime,/type) eq 0) then mtime = 0D else mtime = time_double(mtime)
  tflg = keyword_set(touch)
  dflg = keyword_set(dropbox)
  pflg = keyword_set(pds)
  
  if (tflg or dflg) then begin
    if (~pflg and (mtime eq 0D)) then begin
      print,'TOUCH or DROPBOX is set, but MTIME or PDS is not set!'
      print,'This could trigger a massive file transfer to the SDC!'
    endif else begin
      if (pflg) then begin
        pmsg = ''
        for i=min(pds),max(pds) do pmsg += string(i)
        print,'Transfer all SWEA L2 files for PDS release(s): ',strcompress(pmsg)
      endif
      if (mtime gt 0D) then print,'Transfer SWEA L2 files if created after ',time_string(mtime[0])
    endelse
    yn = 'N'
    read, yn, prompt='Are you sure (y|n)? ', format='(a1)'
    if (strupcase(yn) ne 'Y') then tflg = 0
  endif

  if (rev eq '??') then last = 1 else last = 0

; Shush dprint

  dprint,' ', getdebug=bug, dlevel=4
  dprint,' ', setdebug=-1, dlevel=4

; Initialize

  oneday = 86400D

  drop_dir = root_data_dir() + 'maven/data/dropbox'
  if (dflg) then begin
    finfo = file_info(drop_dir)
    if (~finfo.exists) then begin
      print,'Dropbox directory not found: ',drop_dir
      return
    endif
  endif

  data_dir = 'maven/data/sci/swe/l2/'
  froot = 'mvn_swe_l2_'
  
  ftypes = ['svy3d','svypad','svyspec','arc3d','arcpad']
  ntypes = n_elements(ftypes)

; Process a list of dates

  ndates = n_elements(dates)
  if (ndates gt 0L) then begin
    dates = time_string(dates,prec=-3)
    yyyy = strmid(dates,0,4)
    mm = strmid(dates,5,2)
    dd = strmid(dates,8,2)
    print,"Number of dates: " + strtrim(string(ndates),2)
    dat = replicate('',ndates*ntypes)

    for i=0L,(ndates-1L) do begin
      path = data_dir + yyyy[i] + '/' + mm[i] + '/'
      for k=0L,(ntypes-1L) do begin
        fname = path + froot + ftypes[k] + '_' + yyyy[i] + mm[i] + dd[i] + '_v' + ver + '_r' + rev + '.cdf'
        file = file_retrieve(fname,/no_server,last_version=last)
        chksum = file_dirname(file) + '/' + file_basename(file,'.cdf') + '.md5'
        finfo = file_info(file)
        valid = finfo.exists and (finfo.mtime ge mtime)

        if (valid) then begin
          j = i*5L + k
          dat[j] = file_basename(file)
          print, dat[j]
          if (tflg) then begin
            spawn, 'touch ' + file
            spawn, 'touch ' + chksum
          endif
          if (dflg) then begin
            file_copy, file, drop_dir, /overwrite, /verbose
            file_copy, chksum, drop_dir, /overwrite, /verbose
          endif
        endif
      endfor
    endfor
    return
  endif

; Process a time range

  tmin = time_double('2014-03-01')
  tmax = double(ceil(systime(/sec,/utc)/oneday))*oneday

  if (n_elements(trange) gt 1) then trange = minmax(time_double(trange)) $
                               else trange = [tmin,tmax]

  if (pflg) then begin
    trange = replicate(time_struct('2014-11-15'), 2)
    trange.month += 3*fix([min(pds)-1, max(pds)])
    trange = time_double(trange)
    trange[1] -= oneday
  endif

  tstr = time_struct(tmin)
  year0 = tstr.year
  tstr = time_struct(tmax)
  year1 = tstr.year
  nyear = year1 - year0 + 1

  cat = {date   : 0D               , $
         year   : 0                , $
         month  : 0                , $
         files  : replicate('',31) , $
         nfiles : 0                   }

  cat = replicate(cat,nyear,12)
  cat.year = (year0 + indgen(nyear)) # replicate(1,12)
  cat.month = replicate(1,nyear) # (indgen(12) + 1)
  tstr = replicate(time_struct(0D),nyear,12)
  tstr.year = cat.year
  tstr.month = cat.month
  cat.date = time_double(tstr)
  
  dat = replicate({ftype : '', years : cat[*,0].year, cat : cat}, ntypes)
  dat.ftype = ftypes

; Look for data

  print, ' '
  print, 'Total number of files:'
  ntotal = 0
  for k=0,(ntypes-1) do begin
    ftype = dat[k].ftype
    print, ftype ,format='(a7,": ",$)'
    nfound = 0

    for i=0,(nyear-1) do begin
      for j=0,11 do begin
        yyyy = string(dat[k].cat[i,j].year,format='(i4.4)')
        mm = string(dat[k].cat[i,j].month,format='(i2.2)')
        nm = string(dat[k].cat[i,j].month+1,format='(i2.2)')
        path = data_dir + yyyy + '/' + mm + '/'
        fname = path + froot + ftype + '_' + yyyy + mm + 'DD_v' + ver + '_r' + rev + '.cdf'
        t1 = time_double(yyyy + '-' + mm)
        t2 = time_double(yyyy + '-' + nm)
        files = file_retrieve(fname,/no_server,last_version=last,trange=[t1,t2])
        chksum = file_dirname(files) + '/' + file_basename(files,'.cdf') + '.md5'
        finfo = file_info(files)
        valid = where((finfo.exists and (finfo.mtime ge mtime)), nvalid)
        if (nvalid gt 0) then begin
          yyyy = strmid(files[valid],19,4,/reverse)
          mm = strmid(files[valid],15,2,/reverse)
          dd = strmid(files[valid],13,2,/reverse)
          times = time_double(yyyy + '-' + mm + '-' + dd)
          indx = where((times ge trange[0]) and (times le trange[1]), nvalid)
          if (nvalid gt 0) then begin
            valid = valid[indx]
            dat[k].cat[i,j].files[0:(nvalid-1)] = files[valid]
            dat[k].cat[i,j].nfiles = nvalid
            nfound += nvalid
            if (tflg) then begin
              for m=0,(nvalid-1) do begin
                spawn, 'touch ' + files[valid[m]]
                spawn, 'touch ' + chksum[valid[m]]
              endfor
            endif
            if (dflg) then begin
              for m=0,(nvalid-1) do begin
                file_copy, files[valid[m]], drop_dir, /overwrite, /verbose
                file_copy, chksum[valid[m]], drop_dir, /overwrite, /verbose
              endfor
            endif
          endif
        endif
      endfor
    endfor
    
    print, string(nfound,format='(i5)')
    ntotal += nfound
  endfor
  print,'--------------'
  print,'total',ntotal,format='(a7,": ",i5)'
  print, ' '

; Report the result

  if (blab) then begin
    for i=0,(nyear-1) do begin
      for j=0,11 do begin
        n = total(dat.cat[i,j].nfiles)
        if (n gt 0) then begin
          print, time_string(dat[0].cat[i,j].date,prec=-4)
          for k=0,(ntypes-1) do print,dat[k].ftype,dat[k].cat[i,j].nfiles,format='(2x,a7,2x,i3)'
          print,'--------------'
          print,'total',n,format='(2x,a7,2x,i3)'
          print,' '
        endif
      endfor
    endfor
  endif

; Repackage into more convenient form

  k = 0
  svy3d = {year:dat[k].cat[0,0].year, cat:reform(dat[k].cat[0,*])}
  svy3d = replicate(svy3d, nyear)
  for i=1,(nyear-1) do begin
    svy3d[i].year = dat[k].cat[i,0].year
    svy3d[i].cat  = reform(dat[k].cat[i,*])
  endfor

  k = 1
  svypad = {year:dat[k].cat[0,0].year, cat:reform(dat[k].cat[0,*])}
  svypad = replicate(svypad, nyear)
  for i=1,(nyear-1) do begin
    svypad[i].year = dat[k].cat[i,0].year
    svypad[i].cat  = reform(dat[k].cat[i,*])
  endfor

  k = 2
  svyspec = {year:dat[k].cat[0,0].year, cat:reform(dat[k].cat[0,*])}
  svyspec = replicate(svyspec, nyear)
  for i=1,(nyear-1) do begin
    svyspec[i].year = dat[k].cat[i,0].year
    svyspec[i].cat  = reform(dat[k].cat[i,*])
  endfor

  k = 3
  arc3d = {year:dat[k].cat[0,0].year, cat:reform(dat[k].cat[0,*])}
  arc3d = replicate(arc3d, nyear)
  for i=1,(nyear-1) do begin
    arc3d[i].year = dat[k].cat[i,0].year
    arc3d[i].cat  = reform(dat[k].cat[i,*])
  endfor

  k = 4
  arcpad = {year:dat[k].cat[0,0].year, cat:reform(dat[k].cat[0,*])}
  arcpad = replicate(arcpad, nyear)
  for i=1,(nyear-1) do begin
    arcpad[i].year = dat[k].cat[i,0].year
    arcpad[i].cat  = reform(dat[k].cat[i,*])
  endfor

  cat = {years:dat[0].cat[*,0].year, svy3d:svy3d, svypad:svypad, svyspec:svyspec, $
         arc3d:arc3d, arcpad:arcpad}

; Restore debug state

  dprint,' ', setdebug=bug, dlevel=4

  return

end
