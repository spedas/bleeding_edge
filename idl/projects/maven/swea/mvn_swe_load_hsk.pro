;+
;PROCEDURE:   mvn_swe_load_hsk
;PURPOSE:
;  Reads in MAVEN Level 0 telemetry files (PFDPU packets wrapped in 
;  spacecraft packets).  SWEA normal housekeeping (APID 28) is decomuted
;  and stored in a common block (mvn_swe_com).
;
;USAGE:
;  mvn_swe_load_hsk, trange
;
;INPUTS:
;       trange:        Load SWEA packets from L0 data spanning this time range.
;                      (Reads multiple L0 files, if necessary.  Use MAXBYTES to
;                      protect against brobdingnagian loads.)
;                      OPTIONAL - recommended method is to run timespan before
;                      calling this routine.
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
;                      LATEST days where data exist.  (Routine checks the database
;                      to find latest L0 file.)
;
;       CDRIFT:        Correct for spacecraft clock drift using SPICE.
;                      Default = 1 (yes).
;
;       MAXBYTES:      Maximum number of bytes to process.  Default is all data
;                      within specified time range.
;
;       BADPKT:        An array of structures providing details of bad packets.
;
;       STATUS:        Report statistics of data actually loaded.
;
;       SUMPLOT:       Create a summary plot of the loaded data.
;
;       LOADONLY:      Download data but do not process.
;
;       SPICEINIT:     Force a re-initialization of SPICE.  Use with caution!
;
;       NOSPICE:       Do not initialize SPICE.
;
;       NODUPE:        Filter out identical packets.  Default = 1 (yes).
;
;       SURVEY:        If no merged file(s) exist over requested time range, then 
;                      look for survey-only files.  This is slow, because the
;                      survey files are all located in a single directory.
;
;       REALTIME:      Use realtime file naming convention: YYYYMMDD_HHMMSS_*_l0.dat
;
;       VERBOSE:       Level of diagnostic message suppression.  Default = 0.  Set
;                      to a higher number to see more diagnostic messages.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2019-11-18 14:25:54 -0800 (Mon, 18 Nov 2019) $
; $LastChangedRevision: 28030 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_load_hsk.pro $
;
;CREATED BY:    David L. Mitchell
;FILE: mvn_swe_load_hsk.pro
;-
pro mvn_swe_load_hsk, trange, filename=filename, latest=latest, maxbytes=maxbytes, badpkt=badpkt, $
                              cdrift=cdrift, sumplot=sumplot, status=status, orbit=orbit, $
                              loadonly=loadonly, spiceinit=spiceinit, nodupe=nodupe, $
                              realtime=realtime, nospice=nospice, verbose=verbose, survey=survey

  @mvn_swe_com

; Define decompression, telemetry conversion factors, and data structures

  mvn_swe_init

; Process keywords

  if (size(verbose,/type) eq 0) then mvn_swe_verbose, get=verbose
  dosurvey = keyword_set(survey)

  if not keyword_set(maxbytes) then maxbytes = 0
  if (size(nodupe,/type) eq 0) then nodupe = 1
  oneday = 86400D
  
  if (size(status,/type) eq 0) then status = 1
  if keyword_set(status) then silent = 0 else silent = 1
  
  if keyword_set(orbit) then begin
    imin = min(orbit, max=imax)
    trange = mvn_orbit_num(orbnum=[imin-0.5,imax+0.5])
    latest = 0
  endif
  
  if keyword_set(latest) then begin
    tmax = double(ceil(systime(/sec,/utc)/oneday))*oneday
    tmin = tmax - (14D*oneday)
    file = mvn_pfp_file_retrieve(trange=[tmin,tmax],/l0,/daily,/valid,no_download=2,verbose=verbose)
    fndx = where(file ne '', nfiles)
    if (nfiles eq 0) then begin
      print,"No L0 data in the last two weeks."
      return
    endif
    filename = file[((nfiles - latest) > 0L):*]
    yyyy = strmid(filename,16,4,/rev)
    mm = strmid(filename,12,2,/rev)
    dd = strmid(filename,10,2,/rev)
    dates = time_double(yyyy + '-' + mm + '-' + dd)
    tmax = max(dates, min=tmin) + oneday
    trange = [tmin, tmax]
    filename = 0
    print, "Lastest L0 data: ", time_string(max(dates),prec=-3)
  endif

  tplot_options, get_opt=topt
  tspan_exists = (max(topt.trange_full) gt time_double('2013-11-18'))
  if ((size(trange,/type) eq 0) and tspan_exists) then trange = topt.trange_full
  
  if (size(cdrift, /type) eq 0) then dflg = 1 else dflg = keyword_set(cdrift)
  
  if keyword_set(realtime) then rflg = 1 else rflg = 0

; Get file names associated with trange or from one or more named
; file(s).  If you specify a time range and are working off-site, 
; then the files are downloaded to your local machine, which might
; take a while.

  if (size(filename,/type) eq 7) then begin
    file = filename
    nfiles = n_elements(file)
  endif else begin
    if (size(trange,/type) eq 0) then begin
      print,"You must specify a file name or time range."
      return
    endif
    tmin = min(time_double(trange), max=tmax)
    file = mvn_pfp_file_retrieve(trange=[tmin,tmax],/l0,verbose=(verbose > 1),/daily,/valid)
    fndx = where(file ne '', nfiles)

    if (dosurvey and (nfiles eq 0)) then begin
      print,"No merged files found.  Looking for survey only ... "
      pathname = 'maven/data/sci/pfp/l0/mvn_pfp_svy_l0_YYYYMMDD_v???.dat'
      file = mvn_pfp_file_retrieve(pathname,trange=[tmin,tmax],verbose=(verbose > 1),/daily,/valid)
      fndx = where(file ne '', nfiles)
    endif

    if (nfiles eq 0) then begin
      print,"No files found: ",time_string(tmin)," to ",time_string(tmax)
      return
    endif
  endelse
  
  finfo = file_info(file)
  indx = where(finfo.exists, nfiles, comp=jndx, ncomp=n)
  for j=0,(n-1) do print,"File not found: ",file[jndx[j]]  
  if (nfiles eq 0) then return
  file = file[indx]

  if keyword_set(loadonly) then begin
    print,''
    print,'Files found:'
    for i=0,(nfiles-1) do print,file[i],format='("  ",a)'
    print,''
    return
  endif

; If time range is undefined, get it from the file name(s)

  if (size(trange,/type) eq 0) then begin
    trange = [0D]
    if (rflg) then begin
      for i=0,(nfiles-1) do begin
        fbase = file_basename(file[i])
        yyyy = strmid(fbase,0,4)
        mm = strmid(fbase,4,2)
        dd = strmid(fbase,6,2)
        t0 = time_double(yyyy + '-' + mm + '-' + dd)
        trange = [trange, t0, (t0 + oneday)]
      endfor
    endif else begin
      for i=0,(nfiles-1) do begin
        fbase = file_basename(file[i])
        yyyy = strmid(fbase,16,4,/reverse)
        mm = strmid(fbase,12,2,/reverse)
        dd = strmid(fbase,10,2,/reverse)
        t0 = time_double(yyyy + '-' + mm + '-' + dd)
        trange = [trange, t0, (t0 + oneday)]
      endfor
    endelse
    trange = minmax(trange[1:*])
  endif
  
  if (~tspan_exists) then timespan, trange

; Initialize SPICE if not already done
;   This is needed for MET -> UNIX time conversion.

  if (not keyword_set(nospice)) then begin
    mk = spice_test('*', verbose=-1)
    indx = where(mk ne '', count)
    if (keyword_set(spiceinit) or (count eq 0)) then mvn_swe_spice_init,/force
  endif

; Read in the telemetry file and store the packets in a byte array

  for i=0,(nfiles-1) do begin
    print,"Processing file: ",file_basename(file[i])

    if (i eq 0) then begin
      mvn_swe_clear
      badpkt = 0
      mvn_swe_read_hsk, file[i], trange=trange, maxbytes=maxbytes, badpkt=badpkt, cdrift=dflg
    endif else begin
      mvn_swe_read_hsk, file[i], trange=trange, maxbytes=maxbytes, badpkt=badpkt, cdrift=dflg, /append
    endelse

  endfor

; Check to see if data were actually loaded

  mvn_swe_stat, npkt=npkt, /silent
  
  if (npkt[7] eq 0L) then begin
    print,"No SWEA housekeeping!"
    return
  endif

; Filter out duplicate packets

  if keyword_set(nodupe) then begin

    if (size(pfp_hsk,/type) eq 8) then begin
      indx = uniq(pfp_hsk.met,sort(pfp_hsk.met))
      pfp_hsk = temporary(pfp_hsk[indx])
    endif

    if (size(swe_hsk,/type) eq 8) then begin
      indx = uniq(swe_hsk.met,sort(swe_hsk.met))
      swe_hsk = temporary(swe_hsk[indx])
    endif

  endif

; Initialize calibration factors
; (uses housekeeping to determine first sweep table)

  mvn_swe_calib

; Insert SWEA current monitor from PFP housekeeping

  swe28i = float(interpol(pfp_hsk.swe28i, pfp_hsk.time, swe_hsk.time))
  str_element, swe_hsk, 'swe28i', swe28i, /add

; Report status of data loaded

  mvn_swe_stat, npkt=npkt, silent=silent

; Create a summary plot

  if keyword_set(sumplot) then mvn_swe_sumplot

  return

end
