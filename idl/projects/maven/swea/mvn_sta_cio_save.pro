;+
;PROCEDURE:   mvn_sta_cio_save
;PURPOSE:
;  Saves STATIC cold ion outflow results in save/restore files.
;  See mvn_sta_coldion.pro for details.
;
;USAGE:
;  mvn_sta_cio_save, trange [, ndays]
;
;INPUTS:
;       trange:        Start time or time range for making save files, in any 
;                      format accepted by time_double().  If only one time is 
;                      specified, it is taken as the start time and NDAYS is 
;                      used to get the end time.  If two or more times are 
;                      specified, then the earliest and latest times are used.
;                      Fractional days (hh:mm:ss) are ignored.
;
;       ndays:         Number of dates to process.  Only used if TRANGE has
;                      only one element.  Default = 1.
;
;KEYWORDS:
;       DODEN:         Calculate densities.  Default = 1 (yes).
;
;       DOTEMP:        Calculate temperatures.  Default = 1 (yes).
;
;       DOVEL:         Calculate temperatures.  Default = 1 (yes).
;
;       L3:            Use STATIC L3 data for densities and temperatures.
;
;       MAILTO:        Send email to this address on job start and finish.
;                      Default = 'calif_dave@icloud.com'
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2026-02-24 18:35:02 -0800 (Tue, 24 Feb 2026) $
; $LastChangedRevision: 34192 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_sta_cio_save.pro $
;
;CREATED BY:    David L. Mitchell
;FILE: mvn_sta_cio_save.pro
;-
pro mvn_sta_cio_save, trange, ndays, doden=doden, dotemp=dotemp, dovel=dovel, L3=L3, mailto=mailto

  common coldion, cio_h, cio_o1, cio_o2

  if (size(mailto,/type) ne 7) then mailto = 'calif_dave@icloud.com'
  if (size(doden,/type) eq 0) then doden = 1 else doden = keyword_set(doden)
  if (size(dotemp,/type) eq 0) then dotemp = 1 else dotemp = keyword_set(dotemp)
  if (size(dovel,/type) eq 0) then dovel = 1 else dovel = keyword_set(dovel)
  dovel = replicate(dovel,3)
  useL3 = keyword_set(L3)

  dpath = root_data_dir() + 'maven/data/sci/sta/l3/cio/'
  froot = 'mvn_sta_cio_'
  version = '_v03'  ; iv4 background removal, L3 densities, and latest proxies
  oneday = 86400D  ; process one day at a time

  case n_elements(trange) of
     0  :  begin
             print,'You must specify a start time or time range.'
             return
           end
     1  :  begin
             tstart = time_double(time_string(trange,prec=-3))
             if (size(ndays,/type) eq 0) then ndays = 1
           end
    else : begin
             tmin = min(time_double(trange), max=tmax)
             tstart = time_double(time_string(tmin,prec=-3))
             tstop = time_double(time_string((tmax + oneday - 1D),prec=-3))
             ndays = (tstop - tstart)/oneday
           end
  endcase

; Send email that process is starting

  uinfo = get_login_info()
  ff_ext = strcompress(/remove_all, string(long(100000.0*randomu(seed))))
  tpath = getenv('CDF_TMP')
  ofile0 = tpath + '/sta_cio_msg0.txt' + ff_ext
  openw, tunit, ofile0, /get_lun
    printf, tunit, 'Processing: '
    for i=0L,(ndays-1L) do printf, tunit, time_string(tstart + double(i)*oneday, prec=-3)
  free_lun, tunit
  file_chmod, ofile0, '664'o
  subj = 'STATIC CIO process start on ' + uinfo.machine_name
  cmd0 = 'mailx -s "' + subj + '" ' + mailto + ' < ' + ofile0
  spawn, cmd0
  file_delete, ofile0

; Process the data one calendar day at a time

  for i=0L,(ndays - 1L) do begin
    timer_start = systime(/sec)

    time = tstart + double(i)*oneday
    timespan, time, 1

    tstring = time_string(time)
    yyyy = strmid(tstring,0,4)
    mm = strmid(tstring,5,2)
    dd = strmid(tstring,8,2)
    opath = dpath + yyyy + '/' + mm + '/'
    file_mkdir2, opath, mode='0755'o  ; create directory structure, if needed
    file_chgrp, opath, 'maven', errcode=err
    ofile = opath + froot + yyyy + mm + dd + version + '.sav'

; If the file already exists, then just update it

    finfo = file_info(ofile)
    if (0) then begin
      print,'CIO save file already exists.  Updating.'
      mvn_sta_cio_update, time  ; no need for this anymore
    endif else begin
      mvn_swe_spice_init, /force, /list
      mvn_swe_load_l0
      mvn_swe_stat, npkt=npkt, /silent
      if (npkt[2] gt 0L) then begin
        maven_orbit_tplot, /shadow, /loadonly
        mvn_swe_sciplot, padsmo=16, /loadonly
        mvn_sundir, frame='swe', /polar

        mvn_sta_coldion, L3=useL3, density=doden, temperature=dotemp, velocity=dovel, $
              /reset, tavg=16, frame='mso', /doplot, pans=pans, success=ok

        if (ok) then begin
          save, cio_h, cio_o1, cio_o2, file=ofile
          file_chgrp, ofile, 'maven', errcode=err
        endif else print,'CIO pipeline failed: ',tstring

        elapsed_min = (systime(/sec) - timer_start)/60D
        print,elapsed_min,format='("Time to process (min): ",f6.2)'

      endif else print,'No SWEA data: ',tstring
    endelse
  endfor

; Send email that process has completed

  ff_ext = strcompress(/remove_all, string(long(100000.0*randomu(seed))))
  ofile0 = tpath + '/sta_cio_msg0.txt' + ff_ext
  openw, tunit, ofile0, /get_lun
    printf, tunit, 'Process completed: '
    for i=0L,(ndays-1L) do printf, tunit, time_string(tstart + double(i)*oneday, prec=-3)
  free_lun, tunit
  file_chmod, ofile0, '664'o
  subj = 'STATIC CIO process completed on ' + uinfo.machine_name
  cmd0 = 'mailx -s "' + subj + '" ' + mailto + ' < ' + ofile0
  spawn, cmd0
  file_delete, ofile0

  return

end

