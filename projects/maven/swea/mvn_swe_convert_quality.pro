;+
;PROCEDURE:   mvn_swe_convert_quality
;PURPOSE:
;  Converts olde format quality database into new format.
;
;USAGE:
;  mvn_swe_convert_quality, trange
;
;INPUTS:
;       trange:       One or more dates, in any format accepted by time_double.
;                     Only full UT days are processed; any fractional part of
;                     the day is ignored.  When trange has more than one element,
;                     all days between the earliest and the latest (inclusive) 
;                     are processed.
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-08-15 12:19:33 -0700 (Tue, 15 Aug 2023) $
; $LastChangedRevision: 32004 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_convert_quality.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_swe_convert_quality, trange

  @mvn_swe_com
  common swe_lowe_com, anom

; Filler values for structure elements that are not relevant to the olde database

  width = -1L
  npts = -1
  lambda = 0D
  frac = 0.
  buff = [-1,-1]
  minpts = -1L
  mindelta = 0.
  maxratio = 0.
  minsup = 0.
  maxbad = 0.
  mobetah = 0

; Restore olde quality database

  if (size(anom,/type) ne 8) then begin
    pathname = 'maven/data/sci/swe/anc/swe_lowe_anom.sav'
    file = mvn_pfp_file_retrieve(pathname,verbose=1,/valid)
    fndx = where(file ne '', nfiles)
    if (nfiles eq 0) then begin
      print, '% MVN_SWE_CONVERT_QUALITY: Olde anomaly database not found.'
      return
    endif else restore, file[fndx[0]]
  endif

; Create daily files with the new format from the olde database

  t0 = min(time_double(time_string(trange,/date_only)), max=t1)
  oneday = 86400D
  ndays = round((t1 - t0)/oneday) + 1L

  timespan,[t0 - oneday, t1 + oneday]
  mvn_swe_spice_init, /nock, /force  ; no need for any CK kernels

  proot = root_data_dir() + 'maven/data/sci/swe/anc/quality/'
  froot = 'mvn_swe_quality_'

  for i=0L,(ndays - 1L) do begin
    tstart = t0 + double(i)*oneday
    timespan, [tstart - oneday, tstart + oneday]

    tstring = time_string(tstart)
    yyyy = strmid(tstring,0,4)
    mm = strmid(tstring,5,2)
    dd = strmid(tstring,8,2)
    opath = proot + yyyy + '/' + mm
    if (file_search(opath) eq '') then file_mkdir2, opath, mode = '0775'o

    ofile = opath + '/' + froot + yyyy + mm + dd + '.sav'

    mvn_swe_clear
    mvn_swe_load_l0, /nospice
    mvn_swe_stat, npkt=npkt, /silent

    if (npkt[4] gt 0L) then begin
      indx = where((mvn_swe_engy.time ge tstart) and (mvn_swe_engy.time lt (tstart+oneday)), count)
      if (count gt 0L) then begin
        ut = mvn_swe_engy[indx].time
        flag = replicate(2B, count)          ; data presumed to be innocent
        k = nn2(anom.x, ut, maxdt=0.25D, /valid, vindex=j)
        if (max(j) ge 0L) then flag[j] = 0B  ; data convicted as anomalous

        quality = {time:ut, flag:flag, width:width, npts:npts, lambda:lambda, frac:frac, buffer:buff, $
                   minpts:minpts, mindelta:mindelta, maxratio:maxratio, minsup:minsup, maxbad:maxbad, $
                   mobetah:mobetah, date_processed:systime(/utc,/sec)}

        save, quality, file=ofile
        if (file_test(ofile,/user)) then file_chmod, ofile, '664'o $
                                    else print,"Can't chmod - I'm not the owner!"
      endif
    endif else print,"No spec data!"

  endfor

  return

end

