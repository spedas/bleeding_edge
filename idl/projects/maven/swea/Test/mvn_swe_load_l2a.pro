;+
;PROCEDURE:   mvn_swe_load_l2a
;PURPOSE:
;  Reads in MAVEN Level 2 telemetry files (CDF format).  Data are stored in 
;  a common block (mvn_swe_com).
;
;   WARNING: This routine is for use by the SWEA instrument team only.
;
;  SWEA data structures are:
;
;    3D Distributions:  mvn_swe_3d
;
;    PAD Distributions: mvn_swe_pad
;
;    ENGY Spectra:      mvn_swe_engy
;
;USAGE:
;  mvn_swe_load_l2, trange
;
;INPUTS:
;       trange:        Load SWEA packets from L2 data spanning this time range.
;                      (Reads multiple L2 files, if necessary.)  This input is 
;                      not needed if you first call timespan.
;
;KEYWORDS:
;       FILENAME:      Full path and file name for loading data.  Can be multiple
;                      files.  Takes precedence over trange, ORBIT, and LATEST.
;
;       ORBIT:         Load SWEA data by orbit number or range of orbit numbers 
;                      (trange and LATEST are ignored).  Orbits are numbered using 
;                      the NAIF convention, where the orbit number increments at 
;                      periapsis.  Data are loaded from the apoapsis preceding the
;                      first orbit (periapsis) number to the apoapsis following the
;                      last orbit number.
;
;       LATEST:        Ignore trange (if present), and load all data within the
;                      LATEST days leading up to the current date.
;
;       SPEC:          Load SPEC data.
;
;       PAD:           Load PAD data.
;
;       DDD:           Load 3D data.
;
;       ALL:           Load SPEC, PAD, and 3D data.
;
;       BURST:         Load burst data.  (Default is to load survey data.)
;
;       ARCHIVE:       Synonym for BURST.  (For backward compatibility.)
;
;       STATUS:        Report statistics of data actually loaded.
;
;       SUMPLOT:       Create a summary plot of the loaded data.
;
;       LOADONLY:      Download data but do not process.
;
;       NOERASE:       Do not clear the common block before loading.  This
;                      allows multiple calls to load subsets of the data.
;
;       SPICEINIT:     Force an initialization of SPICE.  Use with caution!
;                      Best practice is to initialize SPICE before calling
;                      this routine (or any other data loader).
;
;       NOSPICE:       Do not initialize SPICE.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-08-21 10:46:02 -0700 (Mon, 21 Aug 2023) $
; $LastChangedRevision: 32045 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/Test/mvn_swe_load_l2a.pro $
;
;CREATED BY:    David L. Mitchell  02-02-15
;FILE: mvn_swe_load_l2a.pro
;-
pro mvn_swe_load_l2a, trange, filename=filename, latest=latest, spec=spec, pad=pad, ddd=ddd, $
                     sumplot=sumplot, status=status, orbit=orbit, loadonly=loadonly, $
                     burst=burst, archive=archive, all=all, noerase=noerase, spiceinit=spiceinit, $
                     nospice=nospice

  @mvn_swe_com

  uinfo = get_login_info()
  if ((uinfo.user_name ne 'mitchell') and (uinfo.user_name ne 'shaosui.xu')) then begin
    print,'This routine is for development only.  It is not intended for public use.'
    return
  endif

; Process keywords

  oneday = 86400D

  if (size(status,/type) eq 0) then status = 1
  if keyword_set(status) then silent = 0 else silent = 1
  if (size(burst,/type) eq 0) then if keyword_set(archive) then burst = 1
  if keyword_set(burst) then burst = 1 else burst = 0
  
  if keyword_set(orbit) then begin
    imin = min(orbit, max=imax)
    trange = mvn_orbit_num(orbnum=[imin-0.5,imax+0.5])
    latest = 0
  endif
  
  if keyword_set(latest) then begin
    tmax = double(ceil(systime(/sec,/utc)/oneday))*oneday
    tmin = tmax - (double(latest[0])*oneday)
    trange = [tmin, tmax]
  endif

  tplot_options, get_opt=topt
  tspan_exists = (max(topt.trange_full) gt time_double('2013-11-18'))
  if ((size(trange,/type) eq 0) and tspan_exists) then trange = topt.trange_full

; Default is to load all data types

  ok = 0
  if (size(spec,/type) ne 0) then ok = 1
  if (size(pad,/type) ne 0) then ok = 1
  if (size(ddd,/type) ne 0) then ok = 1
  if (size(all,/type) ne 0) then ok = 1
  if (not ok) then all = 1

; Otherwise, pick and choose data types

  if keyword_set(spec) then dospec = 1 else dospec = 0
  if keyword_set(pad) then dopad = 1 else dopad = 0
  if keyword_set(ddd) then do3d = 1 else do3d = 0
  if keyword_set(all) then begin
    dospec = 1
    dopad = 1
    do3d = 1
  endif

; Get file names associated with trange or from one or more named
; file(s).  If you specify a time range and are working off-site, 
; then the files are downloaded to your local machine, which might
; take a while.

  path = 'maven/data/sci/swe/l2/YYYY/MM/'
  if (burst) then begin
    stream = 'arc'
    bmsg = 'burst'
  endif else begin
    stream = 'svy'
    bmsg = 'survey'
  endelse

  if (size(filename,/type) eq 7) then begin
    file = filename
    indx = where(file ne '', nfiles)
  
    finfo = file_info(file)
    indx = where(finfo.exists, nfiles, comp=jndx, ncomp=n)
    for j=0,(n-1) do print,"File not found: ",file[jndx[j]]  
    if (nfiles eq 0) then return
    file = file[indx]

    indx = where(strmatch(file,"*spec*") eq 1, nspecfiles)
    if (nspecfiles gt 0) then begin
      specfile = file[indx]
      dospec = 1
    endif else dospec = 0
    
    indx = where(strmatch(file,"*pad*") eq 1, npadfiles)
    if (npadfiles gt 0) then begin
      padfile = file[indx]
      dopad = 1
    endif else dopad = 0
    
    indx = where(strmatch(file,"*3d*") eq 1, ndddfiles)
    if (ndddfiles gt 0) then begin
      dddfile = file[indx]
      do3d = 1
    endif else do3d = 0
    
    if ((nspecfiles + npadfiles + ndddfiles) eq 0) then return

    trange = [0D]
    for i=0,(nfiles-1) do begin
      fbase = file_basename(file[i])
      yyyy = strmid(fbase,19,4,/reverse)
      mm = strmid(fbase,15,2,/reverse)
      dd = strmid(fbase,13,2,/reverse)
      t0 = time_double(yyyy + '-' + mm + '-' + dd)
      trange = [trange, t0, (t0 + oneday)]
    endfor
    trange = minmax(trange[1:*])

  endif else begin
    if (size(trange,/type) eq 0) then begin
      print,"You must specify a file name or time range."
      return
    endif
    tmin = min(time_double(trange), max=tmax)
    if (dospec) then begin
      fname = 'mvn_swe_l2_' + stream + 'spec_YYYYMMDD_v??_r??.cdf'
      specfile = mvn_pfp_file_retrieve(path+fname,trange=[tmin,tmax],/daily_names,/valid)
      indx = where(specfile ne '', nspecfiles)
  
      if (nspecfiles gt 0) then begin
        finfo = file_info(specfile)
        indx = where(finfo.exists, nspecfiles, comp=jndx, ncomp=n)
        for j=0,(n-1) do print,"File not found: ",specfile[jndx[j]]  
        if (nspecfiles gt 0) then specfile = specfile[indx] else specfile = ''
      endif else begin
        print,"No L2 SPEC ",bmsg," files found: ",time_string(tmin)," to ",time_string(tmax)
      endelse
    endif else nspecfiles = 0
    if (dopad) then begin
      fname = 'mvn_swe_l2_' + stream + 'pad_YYYYMMDD_v??_r??.cdf'
      padfile = mvn_pfp_file_retrieve(path+fname,trange=[tmin,tmax],/daily_names,/valid)
      indx = where(padfile ne '', npadfiles)
  
      if (npadfiles gt 0) then begin
        finfo = file_info(padfile)
        indx = where(finfo.exists, npadfiles, comp=jndx, ncomp=n)
        for j=0,(n-1) do print,"File not found: ",padfile[jndx[j]]  
        if (npadfiles gt 0) then padfile = padfile[indx] else padfile = ''
      endif else begin
        print,"No L2 PAD ",bmsg," files found: ",time_string(tmin)," to ",time_string(tmax)
      endelse
    endif else npadfiles = 0
    if (do3d) then begin
      fname = 'mvn_swe_l2_' + stream + '3d_YYYYMMDD_v??_r??.cdf'
      dddfile = mvn_pfp_file_retrieve(path+fname,trange=[tmin,tmax],/daily_names,/valid)
      indx = where(dddfile ne '', ndddfiles)
  
      if (ndddfiles gt 0) then begin
        finfo = file_info(dddfile)
        indx = where(finfo.exists, ndddfiles, comp=jndx, ncomp=n)
        for j=0,(n-1) do print,"File not found: ",dddfile[jndx[j]]  
        if (ndddfiles gt 0) then dddfile = dddfile[indx] else dddfile = ''
      endif else begin
        print,"No L2 3D ",bmsg," files found: ",time_string(tmin)," to ",time_string(tmax)
      endelse
    endif else ndddfiles = 0
  endelse

  if ((nspecfiles + npadfiles + ndddfiles) eq 0) then return

  if keyword_set(loadonly) then begin
    print,''
    print,'Files found:'
    for i=0,(nspecfiles-1) do print,file_basename(specfile[i]),format='("  ",a)'
    for i=0,(npadfiles-1) do print,file_basename(padfile[i]),format='("  ",a)'
    for i=0,(ndddfiles-1) do print,file_basename(dddfile[i]),format='("  ",a)'
    print,''
    return
  endif

; Clear the SWEA data arrays

  if not keyword_set(noerase) then mvn_swe_clear

; Set the time range for tplot (and other routines that access this)
  
  if (~tspan_exists) then timespan, trange

; Initialize SPICE if not already done or if asked
;   Best practice is to initialize SPICE before calling this routine.

  if (not keyword_set(nospice)) then begin
    mk = spice_test('*', verbose=-1)
    indx = where(mk ne '', count)
    if (keyword_set(spiceinit) or (count eq 0)) then mvn_swe_spice_init,/force
  endif

; Define decompression, telemetry conversion factors, and data structures

  mvn_swe_init

; Define times of configuration changes

  mvn_swe_config

; Read in the L2 data, one product at a time.  The sweep table is
; determined from the first data product loaded, which allows a
; determination of the calibration factors.

; Read SPEC data.

  for i=0,(nspecfiles-1) do begin
    print,"Processing file: ",file_basename(specfile[i])

    if (i eq 0) then begin
      mvn_swe_readcdf_spec5, specfile[i], spec
    endif else begin
      mvn_swe_readcdf_spec5, specfile[i], more_spec
      spec = [temporary(spec), temporary(more_spec)]
    endelse

  endfor

; Read PAD data - defer the calculation of pitch angle map and solid
; angle mapping into 3D structure, since this is time consuming.

  for i=0,(npadfiles-1) do begin
    print,"Processing file: ",file_basename(padfile[i])

    if (i eq 0) then begin
      mvn_swe_readcdf_pad5, padfile[i], pad
    endif else begin
      mvn_swe_readcdf_pad5, padfile[i], more_pad
      pad = [temporary(pad), temporary(more_pad)]
    endelse

  endfor

; Read 3D data.

  for i=0,(ndddfiles-1) do begin
    print,"Processing file: ",file_basename(dddfile[i])

    if (i eq 0) then begin
      mvn_swe_readcdf_3d5, dddfile[i], ddd
    endif else begin
      mvn_swe_readcdf_3d5, dddfile[i], more_ddd
      ddd = [temporary(ddd), more_ddd]
    endelse

  endfor

; Trim the data to the desired time range

  tmin = min(time_double(trange), max=tmax)

  if ((nspecfiles gt 0L) and (size(spec,/type) eq 8)) then begin
    indx = where((spec.time ge tmin) and (spec.time le tmax), count)
    if (count eq 0L) then begin
      print,"No L2 SPEC ",bmsg," data within time range."
      spec = 0
    endif else spec = temporary(spec[indx])
  endif

  if ((npadfiles gt 0L) and (size(pad,/type) eq 8)) then begin
    indx = where((pad.time ge tmin) and (pad.time le tmax), count)
    if (count eq 0L) then begin
      print,"No L2 PAD ",bmsg," data within time range."
      pad = 0
    endif else pad = temporary(pad[indx])
  endif

  if ((ndddfiles gt 0L) and (size(ddd,/type) eq 8)) then begin
    indx = where((ddd.time ge tmin) and (ddd.time le tmax), count)
    if (count eq 0L) then begin
      print,"No L2 3D ",bmsg," data within time range."
      ddd = 0
    endif else ddd = temporary(ddd[indx])
  endif

; Store the data in common block

  if (size(spec,/type) eq 8) then begin
    if (burst) then mvn_swe_engy_arc = temporary(spec) $
               else mvn_swe_engy = temporary(spec)
  endif

  if (size(pad,/type) eq 8) then begin
    if (burst) then mvn_swe_pad_arc = temporary(pad) $
               else mvn_swe_pad = temporary(pad)
  endif

  if (size(ddd,/type) eq 8) then begin
    if (burst) then mvn_swe_3d_arc = temporary(ddd) $
               else mvn_swe_3d = temporary(ddd)
  endif

; Check to see if data were actually loaded

  mvn_swe_stat, npkt=npkt, silent=silent

; Create a summary plot

  if keyword_set(sumplot) then mvn_swe_sumplot

  return

end
