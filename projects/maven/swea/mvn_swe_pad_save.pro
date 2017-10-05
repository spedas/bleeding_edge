;+
;PROCEDURE:   mvn_swe_pad_save
;PURPOSE:
;  Calculates resampled pad data (100-150 eV) using mvn_swe_pad_resample and
;  saves in a tplot save/restore file.  Command line used to create the tplot
;  variables is:
;
;    mvn_swe_pad_resample, nbins=128, erange=[100.,150.], /norm, /mask
;
;USAGE:
;  mvn_swe_pad_save, start_day, interval, ndays
;
;INPUTS:
;       None:          Default is to process data currently loaded into memory.
;
;KEYWORDS:
;       start_day:     Restore data over this time range.  If not specified, then
;                      use the currently loaded data.
;
;       interval:      If start_day is defined and ndays > 1, then this is the number 
;                      of days to skip before loading the next date.  (Only useful
;                      for poor-man's parallel processing.)  Default = 1
;
;       ndays:         Number of dates to process, each separated by interval.
;                      Default = 1
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-06-07 13:35:34 -0700 (Sun, 07 Jun 2015) $
; $LastChangedRevision: 17820 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_pad_save.pro $
;
;CREATED BY:    David L. Mitchell  04-25-13
;FILE: mvn_swe_pad_save.pro
;-
pro mvn_swe_pad_save, start_day=start_day, interval=interval, ndays=ndays

  dpath = root_data_dir() + 'maven/data/sci/swe/l1/pad_resample/'
  froot = 'mvn_swe_pad_'
  tname = 'mvn_swe_pad_resample'
  oneday = 86400D
  
  if (size(interval,/type) eq 0) then interval = 1
  if (size(ndays,/type) eq 0) then ndays = 1
  dt = double(interval)*oneday

; First try to process data already loaded.

  if (size(start_day,/type) eq 0) then begin
    mvn_swe_stat,npkt=npkt,/silent
    if (npkt[2] eq 0L) then begin
      print,"No time range to load; no pad data to resample!"
      return
    endif
    
    get_data,'mvn_B_1sec',index=k
    if (k eq 0L) then begin
      mvn_swe_addmag
      get_data,'mvn_B_1sec',index=k
      if (k eq 0L) then begin
        print,"No mag data to map pitch angle!"
        return
      endif
    endif

    mvn_swe_pad_resample,nbins=128,erange=[100.,150.],/norm,/mask,/silent
    get_data,tname,data=pad,index=k,dl=dl
    if (k eq 0L) then begin
      print,"Could not resample pad data!"
      return
    endif

; Split up data into daily files.

    tmin = min(pad.x, max=tmax)
    start_day = time_double(time_string(tmin,prec=-3))
    ndays = floor((tmax - start_day)/oneday) + 1L
    nf = dl.nfactor

    for i=0L,(ndays-1L) do begin
      tstart = start_day + double(i)*oneday
      indx = where((pad.x ge tstart) and (pad.x lt (tstart + oneday)), npts)
      str_element, dl, 'nfactor', nf[indx], /add_replace

      if (npts gt 0L) then begin
        store_data,tname,data={x:pad.x[indx]  , x_ind:[npts], $
                               y:pad.y[indx,*], y_ind:[npts], $
                               v:pad.v[indx,*], v_ind:[npts]   }, dl=dl

        tstring = time_string(tstart)
        yyyy = strmid(tstring,0,4)
        mm = strmid(tstring,5,2)
        dd = strmid(tstring,8,2)
        opath = dpath + yyyy + '/' + mm + '/'
        file_mkdir2, opath, mode='0774'o  ; create directory structure, if needed
        ofile = opath + froot + yyyy + mm + dd
        tplot_save,tname,file=ofile
      endif
    endfor

    return
  endif

; Load the data one calendar day at a time

  start_day = time_double(time_string(start_day,prec=-3))

  for i=0L,(ndays - 1L) do begin
    tstart = start_day + double(i)*dt
    timespan,tstart,1

    tstring = time_string(tstart)
    yyyy = strmid(tstring,0,4)
    mm = strmid(tstring,5,2)
    dd = strmid(tstring,8,2)
    opath = dpath + yyyy + '/' + mm + '/'
    file_mkdir2, opath, mode='0774'o  ; create directory structure, if needed
    ofile = opath + froot + yyyy + mm + dd

    mvn_swe_load_l0,/spiceinit
    mvn_swe_stat,npkt=npkt,/silent
    if (npkt[2] gt 0L) then begin
      store_data,'mvn_B_1sec',/delete
      mvn_swe_addmag
      get_data,'mvn_B_1sec',index=k
      if (k gt 0L) then begin
        mvn_swe_pad_resample,nbins=128,erange=[100.,150.],/norm,/mask,/silent
        tplot_save,tname,file=ofile
      endif else print,"No mag data to map pitch angle!"
    endif else print,"No pad data to resample!"

  endfor

  return

end

