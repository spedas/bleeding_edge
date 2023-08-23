;+
;PROCEDURE:   mvn_swe_quality_daily
;PURPOSE:
;  Calculates the quality flag for the low-energy suppression anomaly.
;  Quality flag data are stored in daily IDL save/restore files.
;
;USAGE:
;  mvn_swe_quality_daily, trange
;
;INPUTS:
;       trange:       One or more dates, in any format accepted by time_double.
;                     Only full UT days are processed; any fractional part of
;                     the day is ignored.  When trange has more than one element,
;                     all days between the earliest and the latest (inclusive) 
;                     are processed.
;
;KEYWORDS:
;       NOLOAD:       Do not initialize SPICE and do not load data.  Assumes that
;                     these steps are performed before calling this routine.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-08-22 13:25:48 -0700 (Tue, 22 Aug 2023) $
; $LastChangedRevision: 32052 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/l2gen/mvn_swe_quality_daily.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_swe_quality_daily, trange, noload=noload

  @mvn_swe_com

  load = ~keyword_set(noload)
  proot = root_data_dir() + 'maven/data/sci/swe/anc/quality/'
  froot = 'mvn_swe_quality_'

  t0 = min(time_double(time_string(trange,/date_only)), max=t1) > time_double('2019-12-01')
  if (t0 ge t1) then begin
    print,'This routine is intended for dates after 2019-12-01.'
    return
  endif

  oneday = 86400D
  ndays = round((t1 - t0)/oneday) + 1L

  timespan,[t0 - oneday, t1 + oneday]
  if (load) then mvn_swe_spice_init, /nock, /force  ; no need for any CK kernels

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

    if (load) then begin
      mvn_swe_clear
      mvn_swe_load_l0, /nospice
    endif
    mvn_swe_stat, npkt=npkt, /silent

    if (npkt[4] gt 0L) then begin
      trange = [tstart, tstart + oneday]
      swe_lowe_cluster, trange=trange, width=75, npts=6, lambda=1.0, frac=0.30, outlier=3, $
                        buffer=[8D,16D], mindelta=0.5, minsup=0.3, maxbad=0.55, quality=quality, $
                        /quiet
      if (size(quality,/type) eq 8) then begin
        save, quality, file=ofile
        if (file_test(ofile,/user)) then file_chmod, ofile, '664'o $
                                    else print,"Can't chmod - I'm not the owner!"
        file_chgrp, ofile, 'maven'
      endif
    endif else print,"No spec data!"

  endfor

  return

end

