;+
;PROCEDURE:   mvn_swe_lpw_scpot_restore
;PURPOSE:
;  Reads in scpot data precalculated by mvn_swe_lpw_scpot
;  and stored in a tplot save/restore file. 
;
;       For more information, see
;       http://research.ssl.berkeley.edu/~haraday/tools/mvn_swe_lpw_scpot.pdf
;
;USAGE:
;  timespan,'2016-01-01',2
;  mvn_swe_lpw_scpot_restore
;
; NOTES:
;       1) The data quality are not good before 2015-01-24.
;       2) The peak fitting algorithm sometimes breaks down
;          when multiple peaks are present in dI/dV curves.
;          Check the quality flag: mvn_lpw_swp1_IV_vinfl_qflag
;                                  1 = good, 0 = bad
;          As a rule of thumb, the data quality is generally good if flag > 0.8
;          You may need caution if 0.5 < flag < 0.8 (check the consistency with SWEA spectra)
;       3) Short time scale variations will be smoothed out by default
;       4) Potential values between 0 and +3 V are interpolated
;          - they cannot be verified by SWEA measurements
;
;INPUTS:
;       trange:        Restore data over this time range.  If not specified, then
;                      uses the current tplot range or timerange() will be called
;
;KEYWORDS:
;       ORBIT:         Restore pad data by orbit number.
;
;       LOADONLY:      Download but do not restore any pad data.
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2017-07-28 07:16:06 -0700 (Fri, 28 Jul 2017) $
; $LastChangedRevision: 23717 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_lpw_scpot_restore.pro $
;
;CREATED BY:    Yuki Harada  03-24-16
;FILE: mvn_swe_lpw_scpot_restore.pro
;-
pro mvn_swe_lpw_scpot_restore, trange, orbit=orbit, loadonly=loadonly, suffix=suffix

; Process keywords
  if ~keyword_set(suffix) then suffix = '_v??_r??'

  rootdir = 'maven/data/sci/swe/l3/swe_lpw_scpot/YYYY/MM/'
  fname = 'mvn_swe_lpw_scpot_YYYYMMDD'+suffix+'.tplot'

  
  if keyword_set(orbit) then begin
    imin = min(orbit, max=imax)
    trange = mvn_orbit_num(orbnum=[imin-0.5,imax+0.5])
  endif

  tplot_options, get_opt=topt
  tspan_exists = (max(topt.trange_full) gt time_double('2013-11-18'))
  if ((size(trange,/type) eq 0) and tspan_exists) then trange = topt.trange_full

; Get file names associated with trange or from one or more named
; file(s).  If you specify a time range and are working off-site, 
; then the files are downloaded to your local machine, which might
; take a while.

  if (size(trange,/type) eq 0) then begin
     trange = timerange()
  endif
  tmin = min(time_double(trange), max=tmax)
  file = mvn_pfp_file_retrieve(rootdir+fname,trange=[tmin,tmax],/daily_names,/last_version)
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

; Restore tplot save file(s)

  tplot_restore,filename=file,/append

  if suffix eq '' then begin
  dprint,'***********************************************'
  dprint,'*** mvn_swe_lpw_scpot is still experimental ***'
  dprint,'***********************************************'
  endif

  return

end
