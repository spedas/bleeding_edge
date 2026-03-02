;+
;PROCEDURE:   mvn_sta_cio_restore
;PURPOSE:
;  Restores STATIC cold ion outflow results.
;  See mvn_sta_coldion.pro for details.
;
;USAGE:
;  mvn_sta_cio_restore, trange
;
;INPUTS:
;       trange:        Restore data over this time range.  If not specified, then
;                      uses the current tplot range.
;
;KEYWORDS:
;       LOADONLY:      Download but do not restore any cio data.
;
;       RESULT_H:      CIO result structure for H+.
;
;       RESULT_O1:     CIO result structure for O+.
;
;       RESULT_O2:     CIO result structure for O2+.
;
;       DOPLOT:        Make tplot variables.
;
;       PANS:          Tplot panel names created when DOPLOT is set.
;
;       SUCCESS:       Success flag.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2026-02-24 18:34:27 -0800 (Tue, 24 Feb 2026) $
; $LastChangedRevision: 34191 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_sta_cio_restore.pro $
;
;CREATED BY:    David L. Mitchell
;FILE: mvn_sta_cio_restore.pro
;-
pro mvn_sta_cio_restore, trange, loadonly=loadonly, result_h=result_h, $
                         result_o1=result_o1, result_o2=result_o2, doplot=doplot, $
                         pans=pans, success=success

  common coldion, cio_h, cio_o1, cio_o2

  cio_h = 0
  cio_o1 = 0
  cio_o2 = 0
  success = 0

  rootdir = 'maven/data/sci/sta/l3/cio/YYYY/MM/'
  fname = 'mvn_sta_cio_YYYYMMDD_v03.sav'

  tplot_options, get_opt=topt
  tspan_exists = (max(topt.trange_full) gt time_double('2013-11-18'))
  if ((size(trange,/type) eq 0) and tspan_exists) then trange = topt.trange_full

; Get file names associated with trange or from one or more named
; file(s).  If you specify a time range and are working off-site, 
; then the files are downloaded to your local machine, which might
; take a while.

  if (size(trange,/type) eq 0) then begin
    print,"You must specify a time or orbit range."
    return
  endif
  tmin = min(time_double(trange), max=tmax)
  file = mvn_pfp_file_retrieve(rootdir+fname,trange=[tmin,tmax],/daily_names)
  nfiles = n_elements(file)

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

; Restore the save file(s)

  first = 1
  docat = 0
  
  for i=0,(nfiles-1) do begin
    print,"Processing file: ",file_basename(file[i])
    
    if (first) then begin
      restore, filename=file[i]
      if (size(cio_h,/type) eq 8) then begin
        result_h  = temporary(cio_h)
        result_o1 = temporary(cio_o1)
        result_o2 = temporary(cio_o2)
        first = 0
      endif else print,"No data were restored."
    endif else begin
      restore, filename=file[i]
      if (size(cio_h,/type) eq 8) then begin
        result_h  = [temporary(result_h),  temporary(cio_h)]
        result_o1 = [temporary(result_o1), temporary(cio_o1)]
        result_o2 = [temporary(result_o2), temporary(cio_o2)]
      endif else print,"No data were restored."
    endelse
  endfor

  npts = n_elements(result_h.time)

; Trim to the requested time range

  indx = where((result_h.time ge tmin) and (result_h.time le tmax), mpts)

  if (mpts eq 0L) then begin
    print,"No data within specified time range!"
    result_h = 0
    result_o1 = 0
    result_o2 = 0
    success = 0
    return
  endif

  if (mpts lt npts) then begin
    cio_h  = temporary(result_h[indx])
    cio_o1 = temporary(result_o1[indx])
    cio_o2 = temporary(result_o2[indx])
    npts = mpts
  endif

; Store results in common block

  cio_h = result_h
  cio_o1 = result_o1
  cio_o2 = result_o2
  success = 1

; Make tplot variables

  if keyword_set(doplot) then mvn_sta_cio_tplot, pans=pans

  return

end
