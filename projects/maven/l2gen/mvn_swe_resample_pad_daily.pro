;+
;PROCEDURE:   mvn_swe_resample_pad_daily
;PURPOSE:
;  Resamples SWEA pitch angle distributions for one or more UT days and saves
;  the results in a tplot save/restore file(s).  These can then be loaded with
;  mvn_swe_pad_restore.  This pre-calculation saves time.
;
;USAGE:
;  mvn_swe_resample_pad, trange
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
;       L2ONLY:       Use L2 MAG data only.  Skip any date(s) where L2 data are
;                     incomplete or not available.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-04-05 10:03:02 -0700 (Wed, 05 Apr 2017) $
; $LastChangedRevision: 23109 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/l2gen/mvn_swe_resample_pad_daily.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_swe_resample_pad_daily, trange, l2only=l2only

  @mvn_swe_com

  t0 = min(time_double(time_string(trange,/date_only)), max=t1)
  oneday = 86400D
  ndays = (t1 - t0)/oneday + 1L

  opath = root_data_dir() + 'maven/data/sci/swe/l1/pad_resample/'
  froot = 'mvn_swe_pad_'

  for i=0L,(ndays - 1L) do begin
    tstart = t0 + double(i)*oneday
    timespan,tstart,1

    tstring = time_string(tstart)
    yyyy = strmid(tstring,0,4)
    mm = strmid(tstring,5,2)
    dd = strmid(tstring,8,2)
    ofile = opath + yyyy + '/' + mm + '/' + froot + yyyy + mm + dd

    mvn_swe_clear
    mvn_swe_load_l0,/spice
    mvn_swe_stat,npkt=npkt,/silent
    ok = npkt[2] gt 0L

    if (ok) then begin
      mvn_swe_addmag
      str_element, swe_mag1, 'level', maglev, success=ok
      if (ok) then begin
        if (keyword_set(l2only) and (min(maglev) lt 2B)) then begin
          print,"Insufficient mag L2 data!"
          ok = 0
        endif
      endif else print,"No mag data!"
    endif else print,"No pad data!"

    if (ok) then begin
      mvn_swe_pad_resample,nbins=128,erange=[100.,150.],/norm,/mask,/silent
      options,'mvn_swe_pad_resample','maglev',maglev
      tplot_save,'mvn_swe_pad_resample',file=ofile
      if (file_test(ofile+'.tplot',/user)) then file_chmod, ofile+'.tplot', '664'o $
                                           else print,"Can't chmod - I'm not the owner!"
    endif

  endfor

  return

end

