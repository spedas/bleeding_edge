;+
;PROCEDURE:   mvn_mag_load_ql
;PURPOSE:
;  Loads MAG-1 data based on a time range.  The source data are sts files
;  produced by the MAG team at GSFC.  These ascii files are first converted
;  to cdf and sav files by mag_sts_to_cdf.  This routine downloads (if 
;  necessary) the sav file, restores it, and loads it into a tplot variable.
;
;  These data are in payload coordinates (spice_frame = MAVEN_SPACECRAFT).
;  Appropriate tags are added to the tplot structure for rotation to 
;  other frames.
;
;  OBSOLETE as of 2014-12-11.
;
;USAGE:
;  mvn_mag_load_ql
;
;INPUTS:
;       trange:        Time range for loading data.
;
;KEYWORDS:
;       FILENAME:      Full path and file name containing MAG QL data.
;                      Can be an array of file names.
;
;       VAR:           Name of TPLOT variable created.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-12-11 13:12:52 -0800 (Thu, 11 Dec 2014) $
; $LastChangedRevision: 16463 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/mag/mvn_mag_load_ql.pro $
;
;CREATED BY:    David L. Mitchell  2014/10/09
;-
pro mvn_mag_load_ql, trange, filename=filename, var=var

  print,"This routine is now obsolete.  Use mvn_mag_load instead."
;  return

; Get file names associated with trange or from one or more named
; file(s).  If you specify a time range and are working off-site, 
; then the files are downloaded to your local machine, which might
; take a while.

  if (size(filename,/type) eq 7) then begin
    file = filename
    nfiles = n_elements(file)
    trange = 0
  endif else begin
    if (size(trange,/type) eq 0) then begin
      print,"You must specify a file name or time range."
      return
    endif
    tmin = min(time_double(trange), max=tmax)
    path = 'maven/data/sci/mag/l1_sav/YYYY/MM/mvn_mag_ql_*_YYYYMMDD_v??_r??.sav'
    file = mvn_pfp_file_retrieve(path,/daily_names,trange=[tmin,tmax])
    nfiles = n_elements(file)
  endelse
  
  finfo = file_info(file)
  indx = where(finfo.exists, nfiles, comp=jndx, ncomp=n)
  for j=0,(n-1) do print,"File not found: ",file[jndx[j]]  
  if (nfiles eq 0) then return
  file = file[indx]

; Load MAG data

  restore, file[0]

  npts = n_elements(data.time.year)
  tstr = replicate(time_struct(0D), npts)

  doy_to_month_date, data.time.year, data.time.doy, month, date

  tstr.year = data.time.year
  tstr.month = month
  tstr.date = date
  tstr.hour = data.time.hour
  tstr.min = data.time.min
  tstr.sec = data.time.sec
  tstr.fsec = double(data.time.msec)/1000D
  tstr.doy = data.time.doy
  time = time_double(tstr)

  magf = fltarr(npts,3)
  magf[*,0] = data.ob_bpl.x
  magf[*,1] = data.ob_bpl.y
  magf[*,2] = data.ob_bpl.z

  for i=1,(nfiles-1) do begin
    restore, file[i]

    npts = n_elements(data.time.year)
    tstr = replicate(time_struct(0D), npts)

    doy_to_month_date, data.time.year, data.time.doy, month, date

    tstr.year = data.time.year
    tstr.month = month
    tstr.date = date
    tstr.hour = data.time.hour
    tstr.min = data.time.min
    tstr.sec = data.time.sec
    tstr.fsec = data.time.msec/1000D
    tstr.doy = data.time.doy
    time = [temporary(time), time_double(tstr)]

    magfs = magf
    mpts = n_elements(magfs[*,0])

    magf = fltarr(mpts+npts,3)
    magf[0L:(mpts-1L),*] = temporary(magfs)
    magf[mpts:*,0] = data.ob_bpl.x
    magf[mpts:*,1] = data.ob_bpl.y
    magf[mpts:*,2] = data.ob_bpl.z

  endfor

; Trim data to requested time range
  
  if (size(tmin,/type) eq 5) then begin
    indx = where((time ge tmin) and (time le tmax), count)
    if (count gt 0L) then begin
      time = time[indx]
      magf = magf[indx,*]
    endif else begin
      print,"No MAG data within requested time range."
      return
    endelse
  endif

; Store the result as a TPLOT variable
  
  var = 'mvn_mag1_pl_ql'
  store_data,var,data={x:time, y:magf, v:[0,1,2], labels:['X','Y','Z'], $
                       labflag:1}, limits = {SPICE_FRAME:'MAVEN_SPACECRAFT', $
                       SPICE_MASTER_FRAME:'MAVEN_SPACECRAFT'}

  return

end
