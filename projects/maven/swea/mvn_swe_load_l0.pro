;+
;PROCEDURE:   mvn_swe_load_l0
;PURPOSE:
;  Reads in MAVEN Level 0 telemetry files (PFDPU packets wrapped in 
;  spacecraft packets).  SWEA packets are identified, decompressed if
;  necessary, and decomuted.  SWEA housekeeping and data are stored in 
;  a common block (mvn_swe_com).
;
;  The packets can be any combination of:
;
;    Housekeeping:      normal rate  (APID 28)
;                       fast rate    (APID A6)
;
;    3D Distributions:  survey mode  (APID A0)
;                       archive mode (APID A1)
;
;    PAD Distributions: survey mode  (APID A2)
;                       archive mode (APID A3)
;
;    ENGY Spectra:      survey mode  (APID A4)
;                       archive mode (APID A5)
;
;  Sampling and averaging of 3D, PAD, and ENGY data are controlled by group
;  and cycle parameters.  The group parameter (G = 0,1,2) sets the summing of
;  adjacent energy bins.  The cycle parameter (N = 0,1,2,3,4,5) sets sampling 
;  of 2-second measurement cycles.  Data products are sampled every 2^N cycles.
;
;  3D distributions are stored in 1, 2 or 4 packets, depending on the group 
;  parameter.  Multiple packets must be stitched together (see swe_plot_dpu).
;
;  PAD packets have one of 3 possible lengths, depending on the group parameter.
;  The PAD data array is sized to accomodate the largest packet (G = 0).  When
;  energies are summed, only 1/2 or 1/4 of this data array is used.
;
;  ENGY spectra always have 64 energy channels (G = 0).
;
;USAGE:
;  mvn_swe_load_l0, trange
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
;                         0 : ask what to do if there's a problem (default)
;                         1 : reinitialize to the new time range
;                         2 : extend coverage to include the new time range
;
;       NOSPICE:       Do not initialize SPICE.  This only applies if you at
;                      least have the spacecraft clock and leap seconds kernels
;                      already loaded.
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
; $LastChangedDate: 2022-01-03 09:58:07 -0800 (Mon, 03 Jan 2022) $
; $LastChangedRevision: 30482 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_load_l0.pro $
;
;CREATED BY:    David L. Mitchell  04-25-13
;FILE: mvn_swe_load_l0.pro
;-
pro mvn_swe_load_l0, trange, filename=filename, latest=latest, maxbytes=maxbytes, badpkt=badpkt, $
                             cdrift=cdrift, sumplot=sumplot, status=status, orbit=orbit, $
                             loadonly=loadonly, spiceinit=spiceinit, nodupe=nodupe, $
                             survey=survey, realtime=realtime, nospice=nospice, verbose=verbose

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

  if (size(spiceinit,/type) eq 0) then spiceinit = 0 else spiceinit = fix(spiceinit[0])

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
;   To convert MET to UTC, the spacecraft clock and leap seconds kernels 
;   are required and loaded even if NOSPICE is set.  If CDRIFT = 0, then
;   a nominal conversion is performed that ignores spacecraft clock drift,
;   which can be significantly in error.  The following also checks whether
;   sufficient information exists to determine spacecraft position and 
;   orientation.

  mvn_spice_stat, summary=sinfo, /silent
  if (~sinfo.time_exists and dflg) then begin
    nospice = 0
    spiceinit = 1
  endif
  if (not keyword_set(nospice)) then begin
    if ((spiceinit eq 1) or (~sinfo.ck_sc_exists)) then begin
      mvn_swe_spice_init, /force
    endif else begin
      tmin = min(sinfo.ck_sc_trange, max=tmax)
      tsp = minmax([trange, tmin, tmax])
      if ((trange[0] lt tmin) or (trange[1] gt tmax)) then begin
        if (spiceinit ne 2) then begin
          print,"Requested time range extends beyond currently loaded SPICE kernels."
          print,"What do you want to do?"
          print,"  r = reinitialize to the time range of the new data"
          print,"  e = extend the time range to include the new data"
          print,"  a = abort - do not load the new data (default)"
          print,"  i = ignore - load the new data without reinitializing SPICE"
          yn = 'a'
          read, yn, prompt='Your choice (r|e|a|i): '
          case strupcase(yn) of
             'R' : mvn_swe_spice_init, trange=trange, /force
             'E' : mvn_swe_spice_init, trange=tsp, /force
             'I' : print,"Warning: SPICE coverage is incomplete or missing."
            else : return
          endcase
        endif else mvn_swe_spice_init, trange=tsp, /force
      endif
    endelse
  endif

; Read in the telemetry file and store the packets in a byte array

  for i=0,(nfiles-1) do begin
    print,"Processing file: ",file_basename(file[i])

    if (i eq 0) then begin
      mvn_swe_clear
      badpkt = 0
      mvn_swe_read_l0, file[i], trange=trange, maxbytes=maxbytes, badpkt=badpkt, cdrift=dflg
    endif else begin
      mvn_swe_read_l0, file[i], trange=trange, maxbytes=maxbytes, badpkt=badpkt, cdrift=dflg, /append
    endelse

  endfor

; Check to see if data were actually loaded

  mvn_swe_stat, npkt=npkt, /silent
  
  if (npkt[7] eq 0L) then begin
    print,"No SWEA housekeeping!"
    return
  endif

; Stitch together 3D packets
  
  swe_3d_stitch

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

    if (size(swe_3d,/type) eq 8) then begin
      if (n_elements(swe_3d) gt 0L) then begin
        indx = uniq(swe_3d.met,sort(swe_3d.met))
        swe_3d = temporary(swe_3d[indx])
      endif
    endif

    if (size(swe_3d_arc,/type) eq 8) then begin
      if (n_elements(swe_3d_arc) gt 0L) then begin
        indx = uniq(swe_3d_arc.met,sort(swe_3d_arc.met))
        swe_3d_arc = temporary(swe_3d_arc[indx])
      endif
    endif

    if (size(a2,/type) eq 8) then begin
      indx = uniq(a2.met,sort(a2.met))
      a2 = temporary(a2[indx])
    endif

    if (size(a3,/type) eq 8) then begin
      indx = uniq(a3.met,sort(a3.met))
      a3 = temporary(a3[indx])
    endif

    if (size(a4,/type) eq 8) then begin
      indx = uniq(a4.met,sort(a4.met))
      a4 = temporary(a4[indx])
    endif

    if (size(a5,/type) eq 8) then begin
      indx = uniq(a5.met,sort(a5.met))
      a5 = temporary(a5[indx])
    endif

    if (size(a6,/type) eq 8) then begin
      indx = uniq(a6.met,sort(a6.met))
      a6 = temporary(a6[indx])
    endif

  endif

; Initialize calibration factors
; (uses housekeeping to determine first sweep table)

  mvn_swe_calib

; Determine sweep table for each measurement

  mvn_swe_getlut

; Make energy spectra

  mvn_swe_makespec

; Report status of data loaded

  mvn_swe_stat, npkt=npkt, silent=silent

; Create a summary plot

  if keyword_set(sumplot) then mvn_swe_sumplot

  return

end
