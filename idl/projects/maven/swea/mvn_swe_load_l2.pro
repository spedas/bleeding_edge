;+
;PROCEDURE:   mvn_swe_load_l2
;PURPOSE:
;  Reads in MAVEN SWEA Level 2 telemetry files (CDF format).  Data are stored in 
;  a common block (mvn_swe_com).
;
;  This routine can load Versions 4 and 5 of the L2 files.
;
;  SWEA data products are:
;
;    APID       Product Name		Product Description*
;  --------------------------------------------------------------------------------
;     a0          svy3d             3D distributions (64E x 16A x 6D), survey
;     a1          arc3d             3D distributions (64E x 16A x 6D), archive
;     a2          svypad            PAD distributions (64E x 16P), survey
;     a3          arcpad            PAD distributions (64E x 16P), archive
;     a4          svyspec           SPEC distributions (64E), survey
;  --------------------------------------------------------------------------------
;    * Array dimensions are those of the data product, which are fixed.  Data can
;      be averaged in groups of 1, 2, or 4 adjacent energy channels, depending on
;      SWEA's telemetry allocation.  Archive (burst) data have the least averaging.
;      Averaged channels are duplicated so that there's always 64 energy channels,
;      while normalization is maintained so that integrals (summations) over energy
;      come out correct.
;
;      The 3D and PAD data are never averaged over angle.  PAD data are great-circle
;      cuts through the 3D data, designed to maximize pitch angle coverage.  SPEC
;      data are weighted sums over the field of view, with angular weighting factors
;      that mimic a moment calculation.
;
;USAGE:
;  mvn_swe_load_l2, trange
;
;EXAMPLES:
;  mvn_swe_load_l2, status=stat  ;  Load data based on the value of TRANGE_FULL in
;                      the tplot common block.  Load all available APID's: a0, a1,
;                      a2, a3, a4.  Return the status of all data types via keyword.
;
;  mvn_swe_load_l2, apid=['a2']  ;  Load only PAD survey data.
;
;  mvn_swe_load_l2, prod=['svypad','svyspec']  ;  Load PAD and SPEC survey data.
;
;  mvn_swe_load_l2, trange, apid=['a0','a1']  ;  Load 3D survey and burst data for
;                      the specified time range.
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
;       LATEST:        Ignore trange (if present), and load all data within the
;                      LATEST days leading up to the current date.
;
;       APID:          String array specifying which APID's to load.  Default is to
;                      load all APID's: ['a0','a1','a2','a3','a4'].  Loading APID a4
;                      (svyspec) is required, so you will always get it, even if you
;                      don't request it.
;
;       PROD:          Alternate method for specifying which data types to load.
;                      String array specifying which data products to load.
;                      Default is to load all products:
;                          ['svy3d','arc3d','svypad','arcpad','svyspec'].
;
;                      The svyspec product is required (see above).
;
;       STATUS:        Return the status of what was actually loaded: APIDs,
;                      product names, numbers of packets, and time coverages.
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
;                      Best practice is to initialize and manage SPICE outside
;                      of this routine.
;
;       NOSPICE:       Disable SPICEINIT and do not initialize SPICE.
;
;       NOERASE:       If set, do not clear the SWEA common block.  Allows
;                      sequential loading.
;
;       SILENT:        Shhhh.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-04-29 16:43:27 -0700 (Mon, 29 Apr 2024) $
; $LastChangedRevision: 32540 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_load_l2.pro $
;
;CREATED BY:    David L. Mitchell  02-02-15
;FILE: mvn_swe_load_l2.pro
;-
pro mvn_swe_load_l2, trange, filename=filename, latest=latest, apid=apid, prod=prod, $
                     sumplot=sumplot, status=status, orbit=orbit, loadonly=loadonly, $
                     noerase=noerase, spiceinit=spiceinit, nospice=nospice, silent=silent, $
                     spec=spec, pad=pad, ddd=ddd, burst=burst, archive=archive  ; this line obsolete

  @mvn_swe_com

  oneday = 86400D
  silent = keyword_set(silent)
  l2_begins = time_double('2014-03-19')

; 2014-03-19 to 2014-07-16  --> cruise, boom stowed
; 2014-10-07 to 2014-10-10  --> transition, boom stowed
; 2014-10-11 to present     --> boom deployed

  status = {apid   :  ''               , $   ; SWEA APID
            prod   :  ''               , $   ; SWEA data product name
            nspec  :  0L               , $   ; number of spectra
            trange :  replicate(0D, 2)    }  ; time range for each APID

  status = replicate(status,5)
  status.apid = ['a0','a1','a2','a3','a4']
  status.prod = ['svy3d','arc3d','svypad','arcpad','svyspec']

  spiceinit = (n_elements(spiceinit) gt 0) ? fix(spiceinit[0]) : 0

; Check for obsolete keywords

  bail = 0

  if (n_elements(spec) gt 0) then begin
    print,"Keyword SPEC is obsolete.  Use APID or PROD instead."
    bail = 1
  endif

  if (n_elements(pad) gt 0) then begin
    print,"Keyword PAD is obsolete.  Use APID or PROD instead."
    bail = 1
  endif

  if (n_elements(ddd) gt 0) then begin
    print,"Keyword DDD is obsolete.  Use APID or PROD instead."
    bail = 1
  endif

  if (n_elements(burst) gt 0) then begin
    print,"Keyword BURST is obsolete.  Use APID or PROD instead."
    bail = 1
  endif

  if (n_elements(archive) gt 0) then begin
    print,"Keyword ARCHIVE is obsolete.  Use APID or PROD instead."
    bail = 1
  endif

  if (bail) then return

; Get the time range

  tplot_options, get_opt=topt
  tspan_valid = max(topt.trange_full) gt l2_begins

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

  if (n_elements(trange) lt 2) then begin
    if (~tspan_valid) then begin
      print, "You must specify a valid time range."
      return
    endif else trange = topt.trange_full
  endif else trange = minmax(time_double(trange))

; Determine which data products to load.  The default is to load all
; available data types: svy3d (a0), arc3d (a1), svypad (a2), arcpad (a3), 
; svyspec (a4) for the requested time range.

  doprod = replicate(1,5)  ; default

  if (size(apid,/type) eq 7) then begin
    doprod = replicate(0,5)
    for i=0,(n_elements(apid)-1) do begin
      case apid[i] of
        'a0' : doprod[0] = 1
        'a1' : doprod[1] = 1
        'a2' : doprod[2] = 1
        'a3' : doprod[3] = 1
        'a4' : doprod[4] = 1
        else : print, "Unrecognized APID: ", apid[i]
      endcase
    endfor
    doprod[4] = 1  ; Loading APID a4 is required.
  endif

  if (size(prod,/type) eq 7) then begin
    doprod = replicate(0,5)
    for i=0,(n_elements(prod)-1) do begin
      case prod[i] of
        'svy3d'   : doprod[0] = 1
        'arc3d'   : doprod[1] = 1
        'svypad'  : doprod[2] = 1
        'arcpad'  : doprod[3] = 1
        'svyspec' : doprod[4] = 1
        else : print, "Unrecognized product: ", prod[i]
      endcase
    endfor
    doprod[4] = 1  ; Loading APID a4 is required.
  endif

; Get file names associated with trange or from one or more named
; file(s).  If you specify a time range and are working off-site, 
; then the files are downloaded to your local machine, which might
; take a while.

  path = 'maven/data/sci/swe/l2/YYYY/MM/'

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
    dddsvy = ''
    dddarc = ''
    padsvy = ''
    padarc = ''
    specsvy = ''

    for i=0,4 do begin
      if (doprod[i]) then begin
        fname = 'mvn_swe_l2_' + status[i].prod + '_YYYYMMDD_v??_r??.cdf'
        file = mvn_pfp_file_retrieve(path+fname,trange=[tmin,tmax],/daily_names,/valid)
        indx = where(file ne '', nfiles)
  
        if (nfiles gt 0) then begin
          finfo = file_info(file)
          indx = where(finfo.exists, nfiles, comp=jndx, ncomp=n)
          for j=0,(n-1) do print,"File not found: ",file[jndx[j]]  
          if (nfiles gt 0) then file = file[indx] else file = ''
          case i of
            0 : dddsvy = file
            1 : dddarc = file
            2 : padsvy = file
            3 : padarc = file
            4 : specsvy = file
          endcase
        endif else begin
          print,"No L2 " + status[i].prod + " files found: ",time_string(tmin)," to ",time_string(tmax)
        endelse
      endif
    endfor
  endelse

  indx = where(dddsvy ne '', ndddsvy)
  if (ndddsvy gt 0) then dddsvy = dddsvy[indx]
  indx = where(dddarc ne '', ndddarc)
  if (ndddarc gt 0) then dddarc = dddarc[indx]
  indx = where(padsvy ne '', npadsvy)
  if (npadsvy gt 0) then padsvy = padsvy[indx]
  indx = where(padarc ne '', npadarc)
  if (npadarc gt 0) then padarc = padarc[indx]
  indx = where(specsvy ne '', nspecsvy)
  if (nspecsvy gt 0) then specsvy = specsvy[indx]

  if ((ndddsvy + ndddarc + npadsvy + npadarc + nspecsvy) eq 0) then return

  if keyword_set(loadonly) then begin
    print,''
    print,'Files found:'
    for i=0,(ndddsvy-1) do print,file_basename(dddsvy[i]),format='("  ",a)'
    for i=0,(ndddarc-1) do print,file_basename(dddarc[i]),format='("  ",a)'
    for i=0,(npadsvy-1) do print,file_basename(padsvy[i]),format='("  ",a)'
    for i=0,(npadarc-1) do print,file_basename(padarc[i]),format='("  ",a)'
    for i=0,(nspecsvy-1) do print,file_basename(specsvy[i]),format='("  ",a)'
    print,''
    return
  endif

; Clear the SWEA data arrays

  if not keyword_set(noerase) then mvn_swe_clear

; Set the time range for tplot (and other routines that access this)
  
  if (~tspan_valid) then timespan, trange

; Initialize SPICE if not already done
;   The following also checks whether sufficient information exists
;   to determine spacecraft position and orientation.

  mvn_spice_stat, summary=sinfo, /silent
  if (~sinfo.time_exists) then spiceinit = 1
  if (~keyword_set(nospice)) then begin
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

; Define decompression, telemetry conversion factors, and data structures

  mvn_swe_init

; Define times of configuration changes

  mvn_swe_config

; Read in the L2 data, one product at a time.  The sweep table is
; determined from the first data product loaded, which allows a
; determination of the calibration factors.

; Read 3D data.

  for i=0,(ndddsvy-1) do begin
    print,"Processing file: ",file_basename(dddsvy[i])

    if (i eq 0) then begin
      mvn_swe_readcdf_3d, dddsvy[i], ddd
    endif else begin
      mvn_swe_readcdf_3d, dddsvy[i], more_ddd
      ddd = [temporary(ddd), more_ddd]
    endelse

  endfor

  for i=0,(ndddarc-1) do begin
    print,"Processing file: ",file_basename(dddarc[i])

    if (i eq 0) then begin
      mvn_swe_readcdf_3d, dddarc[i], dddburst
    endif else begin
      mvn_swe_readcdf_3d, dddarc[i], more_ddd
      dddburst = [temporary(dddburst), more_ddd]
    endelse

  endfor

; Read PAD data - defer the calculation of pitch angle map and solid
; angle mapping into 3D structure, since this is time consuming.

  for i=0,(npadsvy-1) do begin
    print,"Processing file: ",file_basename(padsvy[i])

    if (i eq 0) then begin
      mvn_swe_readcdf_pad, padsvy[i], pad
    endif else begin
      mvn_swe_readcdf_pad, padsvy[i], more_pad
      pad = [temporary(pad), temporary(more_pad)]
    endelse

  endfor

  for i=0,(npadarc-1) do begin
    print,"Processing file: ",file_basename(padarc[i])

    if (i eq 0) then begin
      mvn_swe_readcdf_pad, padarc[i], padburst
    endif else begin
      mvn_swe_readcdf_pad, padarc[i], more_pad
      padburst = [temporary(padburst), temporary(more_pad)]
    endelse

  endfor

; Read SPEC data.

  for i=0,(nspecsvy-1) do begin
    print,"Processing file: ",file_basename(specsvy[i])

    if (i eq 0) then begin
      mvn_swe_readcdf_spec, specsvy[i], spec
    endif else begin
      mvn_swe_readcdf_spec, specsvy[i], more_spec
      spec = [temporary(spec), temporary(more_spec)]
    endelse

  endfor

; Trim the data to the desired time range

  tmin = min(time_double(trange), max=tmax)

  if ((ndddsvy gt 0L) and (size(ddd,/type) eq 8)) then begin
    indx = where((ddd.time ge tmin) and (ddd.time le tmax), ndddsvy)
    if (ndddsvy eq 0L) then begin
      print,"No L2 3D svy data within time range."
      ddd = 0
    endif else ddd = temporary(ddd[indx])
  endif

  if ((ndddarc gt 0L) and (size(dddburst,/type) eq 8)) then begin
    indx = where((dddburst.time ge tmin) and (dddburst.time le tmax), ndddarc)
    if (ndddarc eq 0L) then begin
      print,"No L2 3D arc data within time range."
      dddburst = 0
    endif else dddburst = temporary(dddburst[indx])
  endif

  if ((npadsvy gt 0L) and (size(pad,/type) eq 8)) then begin
    indx = where((pad.time ge tmin) and (pad.time le tmax), npadsvy)
    if (npadsvy eq 0L) then begin
      print,"No L2 PAD svy data within time range."
      pad = 0
    endif else pad = temporary(pad[indx])
  endif

  if ((npadarc gt 0L) and (size(padburst,/type) eq 8)) then begin
    indx = where((padburst.time ge tmin) and (padburst.time le tmax), npadarc)
    if (npadarc eq 0L) then begin
      print,"No L2 PAD arc data within time range."
      padburst = 0
    endif else padburst = temporary(padburst[indx])
  endif

  if ((nspecsvy gt 0L) and (size(spec,/type) eq 8)) then begin
    indx = where((spec.time ge tmin) and (spec.time le tmax), nspecsvy)
    if (nspecsvy eq 0L) then begin
      print,"No L2 SPEC svy data within time range."
      spec = 0
    endif else spec = temporary(spec[indx])
  endif

; Store the data in common block

  if (size(ddd,/type) eq 8) then begin
    mvn_swe_3d = temporary(ddd)
    status[0].nspec = n_elements(mvn_swe_3d)
    status[0].trange = minmax(mvn_swe_3d.time)
  endif
  if (size(dddburst,/type) eq 8) then begin
    mvn_swe_3d_arc = temporary(dddburst)
    status[1].nspec = n_elements(mvn_swe_3d_arc)
    status[1].trange = minmax(mvn_swe_3d_arc.time)
  endif
  if (size(pad,/type) eq 8) then begin
    mvn_swe_pad = temporary(pad)
    status[2].nspec = n_elements(mvn_swe_pad)
    status[2].trange = minmax(mvn_swe_pad.time)
  endif
  if (size(padburst,/type) eq 8) then begin
    mvn_swe_pad_arc = temporary(padburst)
    status[3].nspec = n_elements(mvn_swe_pad_arc)
    status[3].trange = minmax(mvn_swe_pad_arc.time)
  endif
  if (size(spec,/type) eq 8) then begin
    mvn_swe_engy = temporary(spec)
    status[4].nspec = n_elements(mvn_swe_engy)
    status[4].trange = minmax(mvn_swe_engy.time)
  endif

; Check to see if data were actually loaded

  mvn_swe_stat, npkt=npkt, silent=silent

; Create a summary plot

  if keyword_set(sumplot) then mvn_swe_sumplot

  return

end
